#!/usr/bin/env python3
"""
Inspect the existing mx01 Custom Vision project:
- List projects, iterations, and performance metrics
- Count tagged images per project
- List published iterations with names
"""
import os, sys
from azure.cognitiveservices.vision.customvision.training import CustomVisionTrainingClient
from msrest.authentication import ApiKeyCredentials

endpoint = os.environ["CV_ENDPOINT"]
key = os.environ["CV_KEY"]

creds = ApiKeyCredentials(in_headers={"Training-key": key})
client = CustomVisionTrainingClient(endpoint, creds)

projects = client.get_projects()
print(f"Projects: {len(projects)}")
for p in projects:
    print(f"\n  [{p.id}] {p.name}")
    
    images = client.get_tagged_images(p.id, take=256)
    print(f"  Tagged images: {len(images)}")
    
    tags = client.get_tags(p.id)
    print(f"  Tags: {[t.name + '=' + str(t.image_count) for t in tags]}")
    
    iterations = client.get_iterations(p.id)
    print(f"  Iterations: {len(iterations)}")
    for it in iterations:
        perf = None
        try:
            perf = client.get_iteration_performance(p.id, it.id, threshold=0.5)
        except:
            pass
        perf_str = f"P={perf.precision:.2%} R={perf.recall:.2%} mAP={perf.average_precision:.2%}" if perf else "no perf data"
        print(f"    {it.name} | published_as={it.publish_name} | status={it.status} | {perf_str}")
