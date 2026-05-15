#!/usr/bin/env python3
"""
Custom Vision Manifest Export Script

Exports current Custom Vision training images back to JSONL format for backup/disaster recovery.
Downloads all tagged images from Custom Vision and creates MLTable-compatible JSONL manifest.
"""

import json
import logging
import os
import sys
from pathlib import Path
from typing import List, Dict

from azure.cognitiveservices.vision.customvision.training import CustomVisionTrainingClient
from msrest.authentication import ApiKeyCredentials


# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(message)s",
    datefmt="%Y-%m-%d %H:%M:%S",
)
logger = logging.getLogger(__name__)


def load_config() -> Dict[str, str]:
    """Load configuration from environment variables."""
    required_vars = [
        "CUSTOM_VISION_TRAINING_ENDPOINT",
        "CUSTOM_VISION_TRAINING_KEY",
        "CUSTOM_VISION_PROJECT_ID",
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
    
    return config


def convert_cv_region_to_bbox(region: any) -> Dict[str, float]:
    """Convert Custom Vision Region to normalized bbox format."""
    # Custom Vision Region has: left, top, width, height (normalized)
    # Convert to: xmin, ymin, xmax, ymax
    return {
        "label": region.tag_name,
        "xmin": region.left,
        "ymin": region.top,
        "xmax": region.left + region.width,
        "ymax": region.top + region.height,
        "isCrowd": False,
    }


def export_manifest(training_client: CustomVisionTrainingClient, project_id: str, output_dir: Path) -> int:
    """Export all tagged images to JSONL manifest."""
    output_dir.mkdir(parents=True, exist_ok=True)
    
    # Create images subdirectory
    images_dir = output_dir / "images"
    images_dir.mkdir(exist_ok=True)
    
    # Prepare JSONL file
    jsonl_path = output_dir / "manifest.jsonl"
    
    total_images = 0
    skip_count = 0
    take_count = 256  # Custom Vision API limit
    
    logger.info("Exporting tagged images from Custom Vision...")
    
    with open(jsonl_path, "w") as f:
        while True:
            # Get batch of images
            images = training_client.get_tagged_images(
                project_id,
                take=take_count,
                skip=skip_count,
            )
            
            if not images:
                break
            
            logger.info(f"Processing batch: {skip_count + 1}-{skip_count + len(images)}")
            
            for image in images:
                try:
                    # Download image
                    image_filename = f"{image.id}.jpg"
                    image_path = images_dir / image_filename
                    
                    # Get image data (Custom Vision stores the original)
                    import urllib.request
                    urllib.request.urlretrieve(image.original_image_uri, str(image_path))
                    
                    # Get image dimensions from regions (or use defaults)
                    width = image.width if hasattr(image, "width") else 768
                    height = image.height if hasattr(image, "height") else 1024
                    
                    # Convert regions to bbox format
                    labels = []
                    for region in image.regions:
                        bbox = convert_cv_region_to_bbox(region)
                        labels.append(bbox)
                    
                    # Create JSONL entry
                    entry = {
                        "image_url": f"azureml://datastores/image_store/paths/{image_filename}",
                        "image_details": {
                            "format": "jpg",
                            "width": width,
                            "height": height,
                        },
                        "label": labels,
                    }
                    
                    f.write(json.dumps(entry) + "\n")
                    total_images += 1
                    
                except Exception as e:
                    logger.warning(f"Failed to export image {image.id}: {e}")
            
            # Check if we got fewer images than requested (end of list)
            if len(images) < take_count:
                break
            
            skip_count += take_count
    
    logger.info(f"Exported {total_images} images to {jsonl_path}")
    return total_images


def main() -> int:
    """Main entry point."""
    print("Custom Vision Manifest Export")
    print("=" * 50)
    
    # Load configuration
    config = load_config()
    
    # Initialize client
    logger.info("Initializing Custom Vision client...")
    
    credentials = ApiKeyCredentials(in_headers={"Training-key": config["CUSTOM_VISION_TRAINING_KEY"]})
    training_client = CustomVisionTrainingClient(
        config["CUSTOM_VISION_TRAINING_ENDPOINT"],
        credentials,
    )
    
    project_id = config["CUSTOM_VISION_PROJECT_ID"]
    
    # Export to ./export directory
    output_dir = Path("./export")
    
    try:
        total = export_manifest(training_client, project_id, output_dir)
        
        print("\n" + "=" * 50)
        print(f"EXPORT COMPLETED: {total} images")
        print(f"Output directory: {output_dir.absolute()}")
        print("=" * 50)
        
        return 0
        
    except Exception as e:
        logger.exception(f"Export failed: {e}")
        return 1


if __name__ == "__main__":
    sys.exit(main())
