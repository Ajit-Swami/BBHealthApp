# BBHealthApp Kubernetes Deployment (Pure Manifests - No Helm)

This directory contains production-ready Kubernetes manifests in [`k8s/`](file:///d:/BBHealthApp/bb-Healthapp-sourcecode/k8s/) for deploying the BBHealth application to a Kubernetes cluster without relying on Helm.

## Prerequisites

- Kubernetes cluster (minikube, kind, EKS, K3s, GKE, AKS, or bare metal)
- `kubectl` configured to access your cluster
- Docker registry (Docker Hub, AWS ECR, GCR, or local docker engine)
- Docker installed locally

## Architecture

The deployment includes the following components:

- **Frontend**: React application served by Nginx ([`k8s/frontend-deployment.yaml`](file:///d:/BBHealthApp/bb-Healthapp-sourcecode/k8s/frontend-deployment.yaml))
- **Master Service**: Spring Boot service for authentication and user management ([`k8s/master-service-deployment.yaml`](file:///d:/BBHealthApp/bb-Healthapp-sourcecode/k8s/master-service-deployment.yaml))
- **Register Service**: Spring Boot service for user registration ([`k8s/register-service-deployment.yaml`](file:///d:/BBHealthApp/bb-Healthapp-sourcecode/k8s/register-service-deployment.yaml))
- **Document Service**: Spring Boot service for document management ([`k8s/document-service-deployment.yaml`](file:///d:/BBHealthApp/bb-Healthapp-sourcecode/k8s/document-service-deployment.yaml))
- **Configuration & Storage**: ConfigMaps ([`k8s/configmap.yaml`](file:///d:/BBHealthApp/bb-Healthapp-sourcecode/k8s/configmap.yaml)), Secrets ([`k8s/secret.yaml`](file:///d:/BBHealthApp/bb-Healthapp-sourcecode/k8s/secret.yaml)), and PersistentVolumeClaims ([`k8s/pvc.yaml`](file:///d:/BBHealthApp/bb-Healthapp-sourcecode/k8s/pvc.yaml))
- **Routing**: Ingress Controller routing ([`k8s/ingress.yaml`](file:///d:/BBHealthApp/bb-Healthapp-sourcecode/k8s/ingress.yaml))

## Manifest Files (Inside `k8s/` Folder)

| File | Description |
|------|-------------|
| [`k8s/namespace.yaml`](file:///d:/BBHealthApp/bb-Healthapp-sourcecode/k8s/namespace.yaml) | Creates the `bbhealthapp` namespace |
| [`k8s/configmap.yaml`](file:///d:/BBHealthApp/bb-Healthapp-sourcecode/k8s/configmap.yaml) | Configuration for environment variables across services |
| [`k8s/secret.yaml`](file:///d:/BBHealthApp/bb-Healthapp-sourcecode/k8s/secret.yaml) | Secrets for sensitive data (tokens, passwords) |
| [`k8s/pvc.yaml`](file:///d:/BBHealthApp/bb-Healthapp-sourcecode/k8s/pvc.yaml) | Persistent volume claims for user uploads and database persistence |
| [`k8s/master-service-deployment.yaml`](file:///d:/BBHealthApp/bb-Healthapp-sourcecode/k8s/master-service-deployment.yaml) | Master service deployment and ClusterIP service |
| [`k8s/register-service-deployment.yaml`](file:///d:/BBHealthApp/bb-Healthapp-sourcecode/k8s/register-service-deployment.yaml) | Register service deployment and ClusterIP service |
| [`k8s/document-service-deployment.yaml`](file:///d:/BBHealthApp/bb-Healthapp-sourcecode/k8s/document-service-deployment.yaml) | Document service deployment and ClusterIP service |
| [`k8s/frontend-deployment.yaml`](file:///d:/BBHealthApp/bb-Healthapp-sourcecode/k8s/frontend-deployment.yaml) | Frontend React deployment with LoadBalancer service |
| [`k8s/ingress.yaml`](file:///d:/BBHealthApp/bb-Healthapp-sourcecode/k8s/ingress.yaml) | NGINX Ingress resource for host-based / path routing |
| [`k8s/kustomization.yaml`](file:///d:/BBHealthApp/bb-Healthapp-sourcecode/k8s/kustomization.yaml) | Kustomize manifest for single command deploy (`kubectl apply -k k8s/`) |
| [`build-images.sh`](file:///d:/BBHealthApp/bb-Healthapp-sourcecode/build-images.sh) | Script to build and tag all Docker images |
| [`deploy.sh`](file:///d:/BBHealthApp/bb-Healthapp-sourcecode/deploy.sh) | Script to deploy all manifests in sequence and await readiness |

## Quick Start Deployment

### 1. Build Docker Images

```bash
chmod +x build-images.sh
./build-images.sh
```

### 2. Deploy Manifests to Kubernetes

```bash
chmod +x deploy.sh
./deploy.sh
```

*(Or deploy directly with kubectl:* `kubectl apply -f k8s/`*)*

### 3. Verify Pods and Services

```bash
kubectl get pods,svc,pvc,ingress -n bbhealthapp
```

### 4. Access the Application

- **Via LoadBalancer / Node IP:** `http://<LOADBALANCER_OR_NODE_IP>`
- **Via Local DNS:** Add `<NODE_IP> bbhealthapp.local` to `/etc/hosts` and access:
  - **Frontend**: http://bbhealthapp.local
  - **Master API**: http://bbhealthapp.local/api/master
  - **Register API**: http://bbhealthapp.local/api/register
  - **Document API**: http://bbhealthapp.local/api/document
