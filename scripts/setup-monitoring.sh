#!/bin/bash

set -e

echo "=== Setting up Prometheus and Grafana ==="

# Add Prometheus Helm repository
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update

# Install kube-prometheus-stack
echo "Installing kube-prometheus-stack..."
helm install prometheus prometheus-community/kube-prometheus-stack \
  --namespace monitoring \
  --create-namespace \
  --wait

# Apply ServiceMonitor for our application
kubectl apply -f k8s/service-monitor.yaml

# Wait for Grafana to be ready
echo "Waiting for Grafana to be ready..."
kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=grafana -n monitoring --timeout=300s

# Get Grafana admin password
echo ""
echo "=== Grafana Access Information ==="
GRAFANA_PASSWORD=$(kubectl get secret prometheus-grafana -n monitoring -o jsonpath="{.data.admin-password}" | base64 --decode)
echo "Grafana Username: admin"
echo "Grafana Password: $GRAFANA_PASSWORD"
echo ""
echo "To access Grafana, run:"
echo "  kubectl port-forward -n monitoring svc/prometheus-grafana 3000:80"
echo "Then open http://localhost:3000 in your browser"

echo ""
echo "=== Monitoring setup completed successfully ==="
