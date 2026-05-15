# Training Data

Local copy of the Custom Vision object detection training data, sourced from
Azure Blob Storage (`stpoleappdemoeus2mx01`) as of 2026-03-27.

## Structure

```
training-data/
  annotations/
    train_annotations.jsonl   ← bounding box labels in MLTable JSONL format
  images/
    *.jpg                     ← pole photos (17 images)
```

## Annotation Format

Each line in `train_annotations.jsonl` is a JSON object:

```json
{
  "image_url": "azureml://datastores/image_store/paths/<filename>",
  "image_details": { "format": "jpg", "width": 768, "height": 1024 },
  "label": [
    { "label": "stencil",    "xmin": 0.1, "ymin": 0.05, "xmax": 0.9, "ymax": 0.25, "isCrowd": false },
    { "label": "vendor_tag", "xmin": 0.1, "ymin": 0.70, "xmax": 0.4, "ymax": 0.85, "isCrowd": false }
  ]
}
```

Coordinates are **normalized** (0.0–1.0 relative to image dimensions).

## Labels

| Label | Description |
|-------|-------------|
| `stencil` | Identification stencil, upper area of pole |
| `vendor_tag` | Vendor tag(s), lower area of pole, multiple per image |

## Usage with retrain script

```bash
export DATA_DIR=./training-data
python scripts/retrain-custom-vision.py
```

## Refreshing the data

To re-download the latest data from Azure:

```bash
# Annotations (latest version)
az storage blob download \
  --account-name stpoleappdemoeus2mx01 \
  --container-name mltable \
  --name "UI/2026-03-27_132618_UTC/mltable/train_annotations.jsonl" \
  --file training-data/annotations/train_annotations.jsonl \
  --auth-mode login

# Images
az storage blob download-batch \
  --account-name stpoleappdemoeus2mx01 \
  --source images \
  --destination training-data/images \
  --auth-mode login
```
