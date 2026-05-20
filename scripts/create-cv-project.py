#!/usr/bin/env python3
"""Create or find the Custom Vision object detection project and print the project ID."""
import os
import sys
from azure.cognitiveservices.vision.customvision.training import CustomVisionTrainingClient
from msrest.authentication import ApiKeyCredentials

endpoint = os.environ["CUSTOM_VISION_TRAINING_ENDPOINT"]
key = os.environ["CUSTOM_VISION_TRAINING_KEY"]

creds = ApiKeyCredentials(in_headers={"Training-key": key})
client = CustomVisionTrainingClient(endpoint, creds)

projects = client.get_projects()
for p in projects:
    print(f"EXISTING project: {p.name} | {p.id}", file=sys.stderr)

if projects:
    print(projects[0].id)
    sys.exit(0)

domains = [d for d in client.get_domains() if d.type == "ObjectDetection"]
od_domain = next(d for d in domains if "General" in d.name and not d.exportable)
print(f"Creating project with domain: {od_domain.name} ({od_domain.id})", file=sys.stderr)

proj = client.create_project("pseg-pole-detector", domain_id=od_domain.id, classification_type="Multiclass")
print(f"Created: {proj.name} | {proj.id}", file=sys.stderr)
print(proj.id)
