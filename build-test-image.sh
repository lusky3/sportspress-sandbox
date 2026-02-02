#!/bin/bash
# Build and test the SportsPress test environment image

set -e

IMAGE_NAME="sportspress-test-env:latest"

echo "🏗️ Building SportsPress test environment image..."

# Build the image
echo "🔨 Building Docker image: ${IMAGE_NAME}"
docker build -t ${IMAGE_NAME} .

# Test the image locally
echo "🧪 Testing image locally..."
docker run -d --name test-container -p 8082:80 ${IMAGE_NAME}

# Check if WordPress responds
for i in {1..30}; do
    if curl -f http://localhost:8082 > /dev/null 2>&1; then
        echo "✅ Image test successful"
        break
    fi
    echo "⏳ Waiting for WordPress... ($i/30)"
    sleep 2
done

if ! curl -f http://localhost:8082 > /dev/null 2>&1; then
    echo "❌ Image test failed"
    docker logs test-container
    docker stop test-container
    docker rm test-container
    exit 1
fi

echo "🧹 Cleaning up test container..."
docker stop test-container
docker rm test-container

echo "✅ Test environment image built: ${IMAGE_NAME}"
echo "📋 Usage: docker run -p 8082:80 ${IMAGE_NAME}"