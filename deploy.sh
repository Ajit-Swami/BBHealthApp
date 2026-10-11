#!/bin/bash

# Script to deploy BBHealthApp to Kubernetes from k8s/ directory
set -e

NAMESPACE="bbhealthapp"

echo "Deploying BBHealthApp to Kubernetes from k8s/ manifests..."
echo ""

# Create namespace
echo "Creating namespace..."
kubectl apply -f k8s/namespace.yaml

# Apply ConfigMap and Secret
echo "Applying ConfigMap and Secret..."
kubectl apply -f k8s/configmap.yaml
kubectl apply -f k8s/secret.yaml

# Apply PersistentVolumeClaims
echo "Applying PersistentVolumeClaims..."
kubectl apply -f k8s/pvc.yaml

# Deploy backend services
echo "Deploying Master Service..."
kubectl apply -f k8s/master-service-deployment.yaml

echo "Deploying Register Service..."
kubectl apply -f k8s/register-service-deployment.yaml

echo "Deploying Document Service..."
kubectl apply -f k8s/document-service-deployment.yaml

# Deploy frontend
echo "Deploying Frontend..."
kubectl apply -f k8s/frontend-deployment.yaml

# Apply Ingress
echo "Applying Ingress..."
kubectl apply -f k8s/ingress.yaml

echo ""
echo "Deployment completed successfully!"
echo ""
echo "Waiting for pods to be ready..."
kubectl wait --for=condition=ready pod -l app=master-service -n $NAMESPACE --timeout=300s
kubectl wait --for=condition=ready pod -l app=register-service -n $NAMESPACE --timeout=300s
kubectl wait --for=condition=ready pod -l app=document-service -n $NAMESPACE --timeout=300s
kubectl wait --for=condition=ready pod -l app=frontend -n $NAMESPACE --timeout=300s

echo ""
echo "All pods are ready!"
echo ""
echo "Check pods and services:"
echo "  kubectl get pods,svc,ingress -n $NAMESPACE"
