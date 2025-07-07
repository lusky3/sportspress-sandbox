#!/bin/bash
# Build and test the SportsPress test environment image

set -e

IMAGE_NAME="sportspress-test-env:latest"

echo "🏗️ Building SportsPress test environment image..."

# Download SportsPress plugin if not exists
mkdir -p plugins
cd plugins
if [ ! -d "sportspress" ]; then
    echo "📦 Downloading SportsPress plugin..."
    wget https://downloads.wordpress.org/plugin/sportspress.2.7.24.zip
    unzip sportspress.2.7.24.zip
    rm sportspress.2.7.24.zip
fi
cd ..

# Build the image
echo "🔨 Building Docker image: ${IMAGE_NAME}"
docker build -f Dockerfile.testenv -t ${IMAGE_NAME} .

# Test the image locally
echo "🧪 Testing image locally..."
docker run -d --name test-container -p 8082:80 ${IMAGE_NAME}
sleep 30

# Check if WordPress responds
if curl -f http://localhost:8082 > /dev/null 2>&1; then
    echo "✅ Image test successful"
    docker stop test-container
    docker rm test-container
else
    echo "❌ Image test failed"
    docker stop test-container
    docker rm test-container
    exit 1
fi

echo "✅ Test environment image built: ${IMAGE_NAME}"
echo "📋 Usage: docker run -p 8081:80 ${IMAGE_NAME}"