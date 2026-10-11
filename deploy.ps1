# PowerShell script to deploy BBHealthApp to Kubernetes
$ErrorActionPreference = "Stop"
$Namespace = "bbhealthapp"

Write-Host "Deploying BBHealthApp to Kubernetes from k8s/ manifests..." -ForegroundColor Cyan

Write-Host "Creating namespace..."
kubectl apply -f k8s/namespace.yaml

Write-Host "Applying ConfigMap and Secret..."
kubectl apply -f k8s/configmap.yaml
kubectl apply -f k8s/secret.yaml

Write-Host "Applying PersistentVolumeClaims..."
kubectl apply -f k8s/pvc.yaml

Write-Host "Deploying Backend Services..."
kubectl apply -f k8s/master-service-deployment.yaml
kubectl apply -f k8s/register-service-deployment.yaml
kubectl apply -f k8s/document-service-deployment.yaml

Write-Host "Deploying Frontend..."
kubectl apply -f k8s/frontend-deployment.yaml

Write-Host "Applying Ingress..."
kubectl apply -f k8s/ingress.yaml

Write-Host "`nDeployment completed successfully!" -ForegroundColor Green
Write-Host "Waiting for pods to be ready..." -ForegroundColor Yellow
kubectl wait --for=condition=ready pod -l app=master-service -n $Namespace --timeout=300s
kubectl wait --for=condition=ready pod -l app=register-service -n $Namespace --timeout=300s
kubectl wait --for=condition=ready pod -l app=document-service -n $Namespace --timeout=300s
kubectl wait --for=condition=ready pod -l app=frontend -n $Namespace --timeout=300s

Write-Host "`nAll pods are ready!" -ForegroundColor Green
Write-Host "Services:"
kubectl get pods,svc,ingress -n $Namespace
