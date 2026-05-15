#!/usr/bin/env python3
"""
Custom Vision Retraining Automation Script

Implements a 6-stage pipeline to retrain Custom Vision object detection models:
1. Load and validate manifest from local JSONL files
2. Upload images with bounding boxes to Custom Vision
3. Train new iteration
4. Validate quality thresholds (precision >= 85%, recall >= 80%)
5. Publish iteration with versioned name
6. Smoke test published model

Data is read entirely from a local directory (DATA_DIR). No Azure Storage access
is required — download your training data locally before running this script.

Expected local directory layout:
    <DATA_DIR>/
        annotations/    ← MLTable JSONL files (*.jsonl)
        images/         ← Image files referenced by the annotations

Exit codes:
0 = Success
1 = Training failed
2 = Quality thresholds not met
3 = Smoke test failed (publish completed but validation failed)
"""

import json
import logging
import os
import sys
import time
from dataclasses import dataclass
from datetime import datetime
from pathlib import Path
from typing import List, Dict, Tuple

from azure.cognitiveservices.vision.customvision.training import CustomVisionTrainingClient
from azure.cognitiveservices.vision.customvision.training.models import (
    ImageFileCreateEntry,
    Region,
)
from azure.cognitiveservices.vision.customvision.prediction import CustomVisionPredictionClient
from msrest.authentication import ApiKeyCredentials


# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(message)s",
    datefmt="%Y-%m-%d %H:%M:%S",
)
logger = logging.getLogger(__name__)


@dataclass
class AnnotationEntry:
    """Parsed annotation entry from MLTable JSONL format."""
    image_url: str
    image_format: str
    image_width: int
    image_height: int
    labels: List[Dict[str, any]]


def load_config() -> Dict[str, str]:
    """Load configuration from environment variables."""
    required_vars = [
        "DATA_DIR",
        "CUSTOM_VISION_TRAINING_ENDPOINT",
        "CUSTOM_VISION_TRAINING_KEY",
        "CUSTOM_VISION_PROJECT_ID",
        "CUSTOM_VISION_PREDICTION_ENDPOINT",
        "CUSTOM_VISION_PREDICTION_KEY",
        "CUSTOM_VISION_PREDICTION_RESOURCE_ID",
    ]
    
    config = {}
    missing = []
    
    for var in required_vars:
        value = os.environ.get(var)
        if not value:
            missing.append(var)
        else:
            config[var] = value
    
    if missing:
        logger.error(f"Missing required environment variables: {', '.join(missing)}")
        sys.exit(1)
    
    data_dir = Path(config["DATA_DIR"])
    if not data_dir.is_dir():
        logger.error(f"DATA_DIR does not exist or is not a directory: {data_dir}")
        sys.exit(1)
    
    return config


def parse_annotation_line(line: str) -> AnnotationEntry | None:
    """Parse a single JSONL line into an AnnotationEntry."""
    try:
        data = json.loads(line)
        
        # Validate required fields
        if not all(key in data for key in ["image_url", "image_details", "label"]):
            logger.warning(f"Skipping malformed entry: missing required fields")
            return None
        
        return AnnotationEntry(
            image_url=data["image_url"],
            image_format=data["image_details"]["format"],
            image_width=data["image_details"]["width"],
            image_height=data["image_details"]["height"],
            labels=data["label"],
        )
    except (json.JSONDecodeError, KeyError) as e:
        logger.warning(f"Failed to parse line: {e}")
        return None


def stage1_load_and_validate_manifest(data_dir: Path) -> List[AnnotationEntry]:
    """Stage 1: Load and validate manifest from local JSONL files."""
    print("\n=== STAGE 1: Load and Validate Manifest ===")
    
    annotations_dir = data_dir / "annotations"
    if not annotations_dir.is_dir():
        logger.error(f"Annotations directory not found: {annotations_dir}")
        sys.exit(1)
    
    annotations = []
    label_counts: Dict[str, int] = {}
    
    jsonl_files = list(annotations_dir.glob("*.jsonl"))
    if not jsonl_files:
        logger.error(f"No .jsonl files found in {annotations_dir}")
        sys.exit(1)
    
    logger.info(f"Found {len(jsonl_files)} annotation file(s) in {annotations_dir}")
    
    for jsonl_path in jsonl_files:
        logger.info(f"Processing {jsonl_path.name}...")
        for line in jsonl_path.read_text(encoding="utf-8").splitlines():
            if not line.strip():
                continue
            entry = parse_annotation_line(line)
            if entry:
                annotations.append(entry)
                for label in entry.labels:
                    tag = label["label"]
                    label_counts[tag] = label_counts.get(tag, 0) + 1
    
    print(f"Total images: {len(annotations)}")
    print(f"Label distribution: {label_counts}")
    
    return annotations


def extract_blob_path_from_url(image_url: str) -> str:
    """Extract blob path from azureml:// URL format."""
    # Format: azureml://datastores/image_store/paths/<path>
    prefix = "azureml://datastores/image_store/paths/"
    if not image_url.startswith(prefix):
        raise ValueError(f"Unexpected image URL format: {image_url}")
    
    return image_url[len(prefix):]


def convert_bbox_to_cv_region(label: Dict[str, any], tag_id: str) -> Region:
    """Convert normalized bbox from [xmin, ymin, xmax, ymax] to Custom Vision Region."""
    xmin = label["xmin"]
    ymin = label["ymin"]
    xmax = label["xmax"]
    ymax = label["ymax"]
    
    # Convert to left, top, width, height
    left = xmin
    top = ymin
    width = xmax - xmin
    height = ymax - ymin
    
    return Region(tag_id=tag_id, left=left, top=top, width=width, height=height)


def stage2_upload_images(
    data_dir: Path,
    training_client: CustomVisionTrainingClient,
    project_id: str,
    annotations: List[AnnotationEntry],
) -> Tuple[int, int]:
    """Stage 2: Upload images with bounding boxes to Custom Vision."""
    print("\n=== STAGE 2: Upload Images with Bounding Boxes ===")
    
    images_dir = data_dir / "images"
    if not images_dir.is_dir():
        logger.error(f"Images directory not found: {images_dir}")
        sys.exit(1)
    
    # Get or create tags
    existing_tags = training_client.get_tags(project_id)
    tag_map = {tag.name: tag.id for tag in existing_tags}
    
    unique_labels = {label["label"] for entry in annotations for label in entry.labels}
    for label_name in unique_labels:
        if label_name not in tag_map:
            logger.info(f"Creating tag: {label_name}")
            tag = training_client.create_tag(project_id, label_name)
            tag_map[label_name] = tag.id
    
    BATCH_SIZE = 64
    successful = 0
    failed = 0
    
    for i in range(0, len(annotations), BATCH_SIZE):
        batch = annotations[i:i + BATCH_SIZE]
        logger.info(f"Processing batch {i // BATCH_SIZE + 1} ({i + 1}-{min(i + BATCH_SIZE, len(annotations))} of {len(annotations)})")
        
        image_entries = []
        
        for entry in batch:
            try:
                blob_path = extract_blob_path_from_url(entry.image_url)
                image_file = images_dir / Path(blob_path).name
                
                if not image_file.exists():
                    logger.warning(f"Image file not found locally: {image_file}")
                    failed += 1
                    continue
                
                image_data = image_file.read_bytes()
                
                regions = []
                for label in entry.labels:
                    tag_id = tag_map[label["label"]]
                    region = convert_bbox_to_cv_region(label, tag_id)
                    regions.append(region)
                
                image_entries.append(ImageFileCreateEntry(
                    name=image_file.name,
                    contents=image_data,
                    regions=regions,
                ))
                
            except Exception as e:
                logger.error(f"Failed to prepare image {entry.image_url}: {e}")
                failed += 1
        
        if image_entries:
            try:
                result = training_client.create_images_from_files(project_id, images=image_entries)
                
                if result.is_batch_successful:
                    successful += len(image_entries)
                    logger.info(f"Batch uploaded successfully: {len(image_entries)} images")
                else:
                    for img in result.images:
                        if img.status == "OK":
                            successful += 1
                        else:
                            failed += 1
                            logger.warning(f"Failed to upload {img.source_url}: {img.status}")
                
            except Exception as e:
                logger.error(f"Batch upload failed: {e}")
                failed += len(image_entries)
    
    print(f"Successfully uploaded: {successful}")
    print(f"Failed: {failed}")
    
    return successful, failed


def stage3_train(training_client: CustomVisionTrainingClient, project_id: str) -> str:
    """Stage 3: Train new iteration."""
    print("\n=== STAGE 3: Train ===")
    
    logger.info("Starting training...")
    iteration = training_client.train_project(project_id)
    
    logger.info(f"Training iteration {iteration.id} started")
    
    # Poll until complete
    while iteration.status not in ["Completed", "Failed"]:
        time.sleep(10)
        iteration = training_client.get_iteration(project_id, iteration.id)
        logger.info(f"Training status: {iteration.status}")
    
    if iteration.status == "Failed":
        logger.error("Training failed!")
        sys.exit(1)
    
    print(f"Training completed: iteration {iteration.id}")
    return iteration.id


def stage4_validate_quality(
    training_client: CustomVisionTrainingClient,
    project_id: str,
    iteration_id: str,
) -> Tuple[float, float]:
    """Stage 4: Validate quality thresholds."""
    print("\n=== STAGE 4: Validate Quality Thresholds ===")
    
    performance = training_client.get_iteration_performance(
        project_id,
        iteration_id,
        threshold=0.5,
    )
    
    precision = performance.precision
    recall = performance.recall
    
    print(f"Precision: {precision:.2%}")
    print(f"Recall: {recall:.2%}")
    
    # Check thresholds
    if precision < 0.85 or recall < 0.80:
        logger.warning(f"Quality thresholds not met (precision: {precision:.2%}, recall: {recall:.2%})")
        logger.warning(f"Deleting iteration {iteration_id}...")
        training_client.delete_iteration(project_id, iteration_id)
        sys.exit(2)
    
    logger.info("Quality thresholds met!")
    return precision, recall


def generate_publish_name(training_client: CustomVisionTrainingClient, project_id: str) -> str:
    """Generate versioned iteration name: polecheck-YYYYMMDD-seq."""
    today = datetime.now().strftime("%Y%m%d")
    base_name = f"polecheck-{today}"
    
    # Get existing iterations
    iterations = training_client.get_iterations(project_id)
    existing_names = {iter.publish_name for iter in iterations if iter.publish_name}
    
    # Find next available sequence number
    seq = 1
    while True:
        name = f"{base_name}-{seq:02d}"
        if name not in existing_names:
            return name
        seq += 1


def stage5_publish(
    training_client: CustomVisionTrainingClient,
    project_id: str,
    iteration_id: str,
    prediction_resource_id: str,
) -> str:
    """Stage 5: Publish iteration."""
    print("\n=== STAGE 5: Publish Iteration ===")
    
    publish_name = generate_publish_name(training_client, project_id)
    
    logger.info(f"Publishing iteration as: {publish_name}")
    training_client.publish_iteration(
        project_id,
        iteration_id,
        publish_name,
        prediction_resource_id,
    )
    
    print(f"Published iteration: {publish_name}")
    return publish_name


def stage6_smoke_test(
    data_dir: Path,
    prediction_client: CustomVisionPredictionClient,
    project_id: str,
    publish_name: str,
) -> bool:
    """Stage 6: Smoke test published model using a local image."""
    print("\n=== STAGE 6: Smoke Test ===")
    
    images_dir = data_dir / "images"
    image_files = sorted(images_dir.glob("*.jpg")) + sorted(images_dir.glob("*.jpeg")) + sorted(images_dir.glob("*.png"))
    
    if not image_files:
        logger.warning(f"No test images found in {images_dir}")
        return False
    
    test_image = image_files[0]
    logger.info(f"Testing with image: {test_image.name}")
    
    results = prediction_client.detect_image(
        project_id,
        publish_name,
        test_image.read_bytes(),
    )
    
    stencil_found = False
    for prediction in results.predictions:
        logger.info(f"Prediction: {prediction.tag_name} ({prediction.probability:.2%})")
        if prediction.tag_name == "stencil" and prediction.probability >= 0.5:
            stencil_found = True
    
    if not stencil_found:
        logger.warning("Smoke test failed: no stencil prediction >= 0.5")
        print("Smoke test FAILED (publish completed)")
        return False
    
    print("Smoke test PASSED")
    return True


def main() -> int:
    """Main entry point."""
    print("Custom Vision Retraining Pipeline")
    print("=" * 50)
    
    config = load_config()
    data_dir = Path(config["DATA_DIR"])
    
    logger.info("Initializing Custom Vision clients...")
    
    training_credentials = ApiKeyCredentials(in_headers={"Training-key": config["CUSTOM_VISION_TRAINING_KEY"]})
    training_client = CustomVisionTrainingClient(config["CUSTOM_VISION_TRAINING_ENDPOINT"], training_credentials)
    
    prediction_credentials = ApiKeyCredentials(in_headers={"Prediction-key": config["CUSTOM_VISION_PREDICTION_KEY"]})
    prediction_client = CustomVisionPredictionClient(config["CUSTOM_VISION_PREDICTION_ENDPOINT"], prediction_credentials)
    
    project_id = config["CUSTOM_VISION_PROJECT_ID"]
    prediction_resource_id = config["CUSTOM_VISION_PREDICTION_RESOURCE_ID"]
    
    try:
        annotations = stage1_load_and_validate_manifest(data_dir)
        
        if not annotations:
            logger.error("No valid annotations found!")
            return 1
        
        successful, failed = stage2_upload_images(data_dir, training_client, project_id, annotations)
        
        if successful == 0:
            logger.error("No images uploaded successfully!")
            return 1
        
        iteration_id = stage3_train(training_client, project_id)
        
        precision, recall = stage4_validate_quality(training_client, project_id, iteration_id)
        
        publish_name = stage5_publish(training_client, project_id, iteration_id, prediction_resource_id)
        
        smoke_test_passed = stage6_smoke_test(data_dir, prediction_client, project_id, publish_name)
        
        if not smoke_test_passed:
            return 3
        
        print("\n" + "=" * 50)
        print("RETRAINING PIPELINE COMPLETED SUCCESSFULLY")
        print("=" * 50)
        
        return 0
        
    except Exception as e:
        logger.exception(f"Pipeline failed with error: {e}")
        return 1


if __name__ == "__main__":
    sys.exit(main())
