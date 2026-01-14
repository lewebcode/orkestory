#!/bin/bash

set -e

echo "=== Setting up Minikube ==="

# Check if Minikube is installed
if ! command -v minikube &> /dev/null; then
    echo "Minikube is not installed. Please install it first."
    echo "Visit: https://minikube.sigs.k8s.io/docs/start/"
    exit 1
fi

# Start Minikube cluster
echo "Starting Minikube cluster..."
minikube start --cpus=4 --memory=8192mb --nodes=2

# Enable addons
echo "Enabling Minikube addons..."
minikube addons enable ingress
minikube addons enable metrics-server

# Verify cluster status
echo ""
echo "=== Cluster Status ==="
minikube status
kubectl get nodes

echo ""
echo "=== Minikube setup completed successfully ==="
