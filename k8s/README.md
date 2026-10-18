# BBHealthApp - Kubernetes Manifests & Deployment

This directory contains pure Kubernetes manifests for orchestrating the BBHealthApp microservices stack on AWS EKS or any standard Kubernetes cluster.

---

## Architecture Components

| Manifest File | Type | Description |
|---|---|---|
| `namespace.yaml` | Namespace | Creates isolated `bbhealthapp` namespace |
| `configmap.yaml` | ConfigMap | Global environment variables and Spring profile configs |
| `secret.yaml` | Secret | Sensitive keys including `TOKEN_SECRET` |
| `pvc.yaml` | PVC | Persistent volume claims for uploaded documents & reports |
| `master-service-deployment.yaml` | Deployment & Service | Master Auth API (Port 8081) |
| `register-service-deployment.yaml` | Deployment & Service | Register API (Port 8082) |
| `document-service-deployment.yaml` | Deployment & Service | Document API (Port 8083) |
| `frontend-deployment.yaml` | Deployment & Service | React UI + Nginx (Port 80 / NodePort 30281) |
| `ingress.yaml` | Ingress | Ingress routing rules for host and paths |
| `kustomization.yaml` | Kustomize | Single-command deployment bundle |

---

## Deployment Instructions

### 1. Connect to your Kubernetes Cluster
For AWS EKS:
```bash
aws eks update-kubeconfig --region us-west-2 --name bbhealthapp-dev
```

### 2. Deploy all manifests
Deploy using `kubectl apply`:
```bash
kubectl apply -f k8s/namespace.yaml
kubectl apply -f k8s/configmap.yaml
kubectl apply -f k8s/secret.yaml
kubectl apply -f k8s/pvc.yaml
kubectl apply -f k8s/master-service-deployment.yaml
kubectl apply -f k8s/register-service-deployment.yaml
kubectl apply -f k8s/document-service-deployment.yaml
kubectl apply -f k8s/frontend-deployment.yaml
kubectl apply -f k8s/ingress.yaml
```

*Or deploy everything at once using Kustomize:*
```bash
kubectl apply -k k8s/
```

### 3. Verify Deployment Status
```bash
kubectl get pods -n bbhealthapp
kubectl get svc -n bbhealthapp
kubectl get ingress -n bbhealthapp
```
