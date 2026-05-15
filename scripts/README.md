# Custom Vision Retraining Scripts

This directory contains automation scripts for the PSEG Pole Check Custom Vision retraining pipeline.

## Scripts

### `retrain-custom-vision.py`
Main retraining automation script that implements a 6-stage pipeline to retrain the Custom Vision object detection model for pole images.

**Stages:**
1. **Load and Validate Manifest** - Downloads and parses JSONL annotation files from Azure Blob Storage
2. **Upload Images** - Uploads images with bounding boxes to Custom Vision (batches of 64)
3. **Train** - Starts training iteration and polls until completion
4. **Validate Quality** - Checks precision >= 85% and recall >= 80% thresholds
5. **Publish** - Publishes iteration with versioned name (polecheck-YYYYMMDD-seq)
6. **Smoke Test** - Tests published model with sample image

**Exit Codes:**
- `0` - Success
- `1` - Training failed or no images uploaded
- `2` - Quality thresholds not met (iteration deleted, rollback required)
- `3` - Smoke test failed (publish completed but validation failed)

### `export-cv-manifest.py`
Backup/DR script that exports current Custom Vision training images back to JSONL format.

**Purpose:**
- Backup current training data
- Disaster recovery
- Migration to new Custom Vision project

## Required Environment Variables

Both scripts require authentication and configuration via environment variables:

### Common Variables
- `CUSTOM_VISION_TRAINING_ENDPOINT` - Training endpoint URL (e.g., https://eastus.api.cognitive.microsoft.com)
- `CUSTOM_VISION_TRAINING_KEY` - API key for Custom Vision training operations
- `CUSTOM_VISION_PROJECT_ID` - GUID of the Custom Vision project

### Retraining Script Only
- `STORAGE_ACCOUNT_NAME` - Azure Storage account name (e.g., stpoleappdemoeus2mx01)
- `CUSTOM_VISION_PREDICTION_ENDPOINT` - Prediction endpoint URL
- `CUSTOM_VISION_PREDICTION_KEY` - API key for Custom Vision prediction operations
- `CUSTOM_VISION_PREDICTION_RESOURCE_ID` - Full resource ID for prediction resource

**Note:** Storage authentication uses `DefaultAzureCredential` (managed identity in CI/CD, developer credentials locally). No storage key required.

## Dependencies

Install required Python packages:

```bash
pip install -r requirements.txt
```

Packages:
- `azure-cognitiveservices-vision-customvision` >= 3.1.0
- `azure-storage-blob` >= 12.0.0
- `azure-identity` >= 1.7.0
- `msrest` >= 0.7.0

## Usage

### Retraining (Local Development)

Set environment variables:
```bash
export STORAGE_ACCOUNT_NAME="stpoleappdemoeus2mx01"
export CUSTOM_VISION_TRAINING_ENDPOINT="https://eastus.api.cognitive.microsoft.com"
export CUSTOM_VISION_TRAINING_KEY="your-training-key"
export CUSTOM_VISION_PROJECT_ID="your-project-guid"
export CUSTOM_VISION_PREDICTION_ENDPOINT="https://eastus.api.cognitive.microsoft.com"
export CUSTOM_VISION_PREDICTION_KEY="your-prediction-key"
export CUSTOM_VISION_PREDICTION_RESOURCE_ID="/subscriptions/.../resourceGroups/.../providers/Microsoft.CognitiveServices/accounts/..."
```

Authenticate to Azure (for storage access):
```bash
az login
```

Run retraining:
```bash
python scripts/retrain-custom-vision.py
```

**Expected Output:**
```
Custom Vision Retraining Pipeline
==================================================

=== STAGE 1: Load and Validate Manifest ===
Total images: 250
Valid entries: 250
Label distribution: {'stencil': 250, 'vendor_tag': 487}

=== STAGE 2: Upload Images with Bounding Boxes ===
Successfully uploaded: 250
Failed: 0

=== STAGE 3: Train ===
Training completed: iteration abc123...

=== STAGE 4: Validate Quality Thresholds ===
Precision: 87.50%
Recall: 82.30%

=== STAGE 5: Publish Iteration ===
Published iteration: polecheck-20260515-01

=== STAGE 6: Smoke Test ===
Smoke test PASSED

==================================================
RETRAINING PIPELINE COMPLETED SUCCESSFULLY
==================================================
```

### Export Manifest (Backup)

Set environment variables:
```bash
export CUSTOM_VISION_TRAINING_ENDPOINT="https://eastus.api.cognitive.microsoft.com"
export CUSTOM_VISION_TRAINING_KEY="your-training-key"
export CUSTOM_VISION_PROJECT_ID="your-project-guid"
```

Run export:
```bash
python scripts/export-cv-manifest.py
```

**Output:**
- `./export/manifest.jsonl` - JSONL file with all annotations
- `./export/images/` - Downloaded images

### CI/CD Pipeline

In GitHub Actions or Azure DevOps, use managed identity for storage authentication:

```yaml
- name: Run Custom Vision Retraining
  env:
    STORAGE_ACCOUNT_NAME: stpoleappdemoeus2mx01
    CUSTOM_VISION_TRAINING_ENDPOINT: ${{ secrets.CV_TRAINING_ENDPOINT }}
    CUSTOM_VISION_TRAINING_KEY: ${{ secrets.CV_TRAINING_KEY }}
    CUSTOM_VISION_PROJECT_ID: ${{ secrets.CV_PROJECT_ID }}
    CUSTOM_VISION_PREDICTION_ENDPOINT: ${{ secrets.CV_PREDICTION_ENDPOINT }}
    CUSTOM_VISION_PREDICTION_KEY: ${{ secrets.CV_PREDICTION_KEY }}
    CUSTOM_VISION_PREDICTION_RESOURCE_ID: ${{ secrets.CV_PREDICTION_RESOURCE_ID }}
  run: |
    python scripts/retrain-custom-vision.py
```

**CI/CD Exit Code Handling:**
- Exit code `2` (quality thresholds not met) → Fail pipeline, alert team, do NOT promote to production
- Exit code `3` (smoke test failed) → Publish succeeded but validation failed, manual review required
- All other non-zero exit codes → Pipeline failure

## Important Notes

### API Limits
- Custom Vision max **64 images per batch** upload - enforced by script
- Custom Vision max **256 images per page** for get_tagged_images - pagination handled by export script

### Bounding Box Format
- **MLTable JSONL format:** `[xmin, ymin, xmax, ymax]` (normalized 0.0-1.0)
- **Custom Vision Region:** `[left, top, width, height]` (normalized 0.0-1.0)
- **Conversion:** `left=xmin, top=ymin, width=xmax-xmin, height=ymax-ymin`

### Azure Region
- Custom Vision project is in **East US** (not East US 2) - this is an Azure service constraint

### Storage Structure
- **`mltable` container** - JSONL annotation files
- **`images` container** - Actual image files (JPG/PNG)

## Troubleshooting

**"Missing required environment variables"**
- Ensure all environment variables are set before running

**"No valid annotations found"**
- Check that JSONL files exist in the `mltable` container
- Verify JSONL format matches expected schema

**"Quality thresholds not met" (exit code 2)**
- Precision < 85% or Recall < 80%
- The failing iteration is automatically deleted
- Review training data quality and quantity
- May need more labeled images or better annotations

**"Smoke test failed" (exit code 3)**
- Published iteration exists but didn't detect stencil in test image
- Manual review recommended
- Check if test image actually contains a stencil
- May need to retrain with different data

**"Batch upload failed"**
- Check Custom Vision project quota (free tier = 5,000 images)
- Verify image format and size (max 6MB per image)
- Ensure regions are within normalized bounds [0.0, 1.0]
