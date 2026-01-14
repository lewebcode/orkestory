#!/bin/bash

set -e

echo "=== Deploying to Kubernetes ==="

# Apply Kubernetes manifests
kubectl apply -f k8s/deployment.yaml
kubectl apply -f k8s/service.yaml
kubectl apply -f k8s/ingress.yaml
kubectl apply -f k8s/hpa.yaml

# Wait for deployment to be ready
echo "Waiting for deployment to be ready..."
kubectl wait --for=condition=available --timeout=300s deployment/sentiment-analyzer

# Show status
echo ""
echo "=== Deployment Status ==="
kubectl get pods -l app=sentiment-analyzer
kubectl get services
kubectl get ingress
kubectl get hpa

echo ""
echo "=== Deployment completed successfully ==="
echo "To access the service, use:"
echo "  minikube service sentiment-analyzer-service"
