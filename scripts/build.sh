#!/bin/bash

set -e

echo "=== Building Sentiment Analyzer Application ==="

# Build Java application
echo "Building Java application with Maven..."
./mvnw clean package -DskipTests

echo "=== Build completed successfully ==="
