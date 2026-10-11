#!/bin/bash

# Script to build and tag Docker images for BBHealthApp
set -e

REGISTRY="${REGISTRY:-bbhealthapp}"
TAG="${TAG:-latest}"

echo "=================================================="
echo "Building BBHealthApp Docker Images"
echo "Registry: $REGISTRY"
echo "Tag:      $TAG"
echo "=================================================="
echo ""

# Build Master Service
echo "[1/4] Building Master Service..."
docker build -t ${REGISTRY}-master-service:${TAG} ./bbhealthapp-backend/bbhealthapp-api-master

# Build Register Service
echo "[2/4] Building Register Service..."
docker build -t ${REGISTRY}-register-service:${TAG} ./bbhealthapp-backend/bbhealthapp-api-register

# Build Document Service
echo "[3/4] Building Document Service..."
docker build -t ${REGISTRY}-document-service:${TAG} ./bbhealthapp-backend/bbhealthapp-api-document

# Build Frontend
echo "[4/4] Building Frontend..."
docker build -t ${REGISTRY}-frontend:${TAG} ./bbhealthapp-frontend

echo ""
echo "=================================================="
echo "All Docker images built successfully!"
echo "=================================================="
echo ""
echo "Built images:"
echo " - ${REGISTRY}-master-service:${TAG}"
echo " - ${REGISTRY}-register-service:${TAG}"
echo " - ${REGISTRY}-document-service:${TAG}"
echo " - ${REGISTRY}-frontend:${TAG}"
echo ""
echo "To push to a remote registry:"
echo "  docker push ${REGISTRY}-master-service:${TAG}"
echo "  docker push ${REGISTRY}-register-service:${TAG}"
echo "  docker push ${REGISTRY}-document-service:${TAG}"
echo "  docker push ${REGISTRY}-frontend:${TAG}"
