#!/bin/bash

set -e

echo "=== Building Docker Image ==="

# Build Docker image
docker build -t sentiment-analyzer:latest .

# Check image size
echo ""
echo "=== Docker Image Information ==="
docker images sentiment-analyzer:latest

IMAGE_SIZE=$(docker images sentiment-analyzer:latest --format "{{.Size}}" | sed 's/[^0-9.]//g' | head -1)
echo ""
echo "Image size: $IMAGE_SIZE"

# Load image into Minikube
echo ""
echo "=== Loading image into Minikube ==="
minikube image load sentiment-analyzer:latest

echo "=== Docker build completed successfully ==="
