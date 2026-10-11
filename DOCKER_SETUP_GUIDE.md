# BBHealthApp - Docker Setup & Deployment Guide

This guide covers building, testing, and pushing Docker images for BBHealthApp locally, to **Docker Hub**, and to **AWS Elastic Container Registry (ECR)**.

---

## 1. Building Docker Images Locally

### Master Service
```bash
cd bbhealthapp-backend/bbhealthapp-api-master
docker build -t bbhealthapp-master-service:latest .
```

### Register Service
```bash
cd bbhealthapp-backend/bbhealthapp-api-register
docker build -t bbhealthapp-register-service:latest .
```

### Document Service
```bash
cd bbhealthapp-backend/bbhealthapp-api-document
docker build -t bbhealthapp-document-service:latest .
```

### Frontend
```bash
cd bbhealthapp-frontend
docker build -t bbhealthapp-frontend:latest .
```

---

## 2. Testing Docker Images Locally

### Option A: Using Docker Compose (Recommended)
From the project root:
```bash
# Build and start all services in background
docker-compose up -d --build

# View live logs
docker-compose logs -f

# Stop all services
docker-compose down
```

### Option B: Running Containers Individually

```bash
# 1. Master Service
docker run -d -p 8081:8081 --name master-service bbhealthapp-master-service:latest

# 2. Register Service
docker run -d -p 8082:8082 --name register-service bbhealthapp-register-service:latest

# 3. Document Service
docker run -d -p 8083:8083 --name document-service bbhealthapp-document-service:latest

# 4. Frontend
docker run -d -p 80:80 --name frontend bbhealthapp-frontend:latest
```

#### Stop & Remove Containers
```bash
docker stop document-service master-service register-service frontend
docker rm document-service master-service register-service frontend
```

---

## 3. Pushing Images to Docker Hub

### Step 1: Login to Docker Hub
Open your terminal / PowerShell and log in with your Docker Hub credentials:
```bash
docker login -u <YOUR_DOCKERHUB_USERNAME>
```
*(Enter your password or Personal Access Token when prompted)*

### Step 2: Tag Images for Docker Hub
Replace `<YOUR_DOCKERHUB_USERNAME>` with your actual Docker Hub username:

```bash
docker tag bbhealthapp-master-service:latest <YOUR_DOCKERHUB_USERNAME>/bbhealthapp-master-service:latest
docker tag bbhealthapp-register-service:latest <YOUR_DOCKERHUB_USERNAME>/bbhealthapp-register-service:latest
docker tag bbhealthapp-document-service:latest <YOUR_DOCKERHUB_USERNAME>/bbhealthapp-document-service:latest
docker tag bbhealthapp-frontend:latest <YOUR_DOCKERHUB_USERNAME>/bbhealthapp-frontend:latest
```

*(Optional: Tag with version numbers like `:v1.0` in addition to `:latest`)*

### Step 3: Push Images to Docker Hub
```bash
docker push <YOUR_DOCKERHUB_USERNAME>/bbhealthapp-master-service:latest
docker push <YOUR_DOCKERHUB_USERNAME>/bbhealthapp-register-service:latest
docker push <YOUR_DOCKERHUB_USERNAME>/bbhealthapp-document-service:latest
docker push <YOUR_DOCKERHUB_USERNAME>/bbhealthapp-frontend:latest
```

---

## 4. AWS ECR Setup & Image Push

### Step 1: Login to ECR
```bash
aws ecr get-login-password --region ap-south-1 | docker login --username AWS --password-stdin <YOUR_ACCOUNT_ID>.dkr.ecr.ap-south-1.amazonaws.com
```

### Step 2: ECR Repository URLs
The Terraform configuration provisions the following ECR repositories:
- `bbhealthapp-dev-master-service`
- `bbhealthapp-dev-register-service`
- `bbhealthapp-dev-document-service`
- `bbhealthapp-dev-frontend`

Your ECR registry URL format: `<YOUR_ACCOUNT_ID>.dkr.ecr.ap-south-1.amazonaws.com`

### Step 3: Tag Images for ECR
```bash
docker tag bbhealthapp-master-service:latest <YOUR_ACCOUNT_ID>.dkr.ecr.ap-south-1.amazonaws.com/bbhealthapp-dev-master-service:latest
docker tag bbhealthapp-register-service:latest <YOUR_ACCOUNT_ID>.dkr.ecr.ap-south-1.amazonaws.com/bbhealthapp-dev-register-service:latest
docker tag bbhealthapp-document-service:latest <YOUR_ACCOUNT_ID>.dkr.ecr.ap-south-1.amazonaws.com/bbhealthapp-dev-document-service:latest
docker tag bbhealthapp-frontend:latest <YOUR_ACCOUNT_ID>.dkr.ecr.ap-south-1.amazonaws.com/bbhealthapp-dev-frontend:latest
```

### Step 4: Push Images to ECR
```bash
docker push <YOUR_ACCOUNT_ID>.dkr.ecr.ap-south-1.amazonaws.com/bbhealthapp-dev-master-service:latest
docker push <YOUR_ACCOUNT_ID>.dkr.ecr.ap-south-1.amazonaws.com/bbhealthapp-dev-register-service:latest
docker push <YOUR_ACCOUNT_ID>.dkr.ecr.ap-south-1.amazonaws.com/bbhealthapp-dev-document-service:latest
docker push <YOUR_ACCOUNT_ID>.dkr.ecr.ap-south-1.amazonaws.com/bbhealthapp-dev-frontend:latest
```

---

## 5. Verification & Service URLs

| Service | Local URL | Port |
|---|---|---|
| **Frontend UI** | [http://localhost](http://localhost) | `80` |
| **Master Service** | [http://localhost:8081](http://localhost:8081) | `8081` |
| **Register Service** | [http://localhost:8082](http://localhost:8082) | `8082` |
| **Document Service** | [http://localhost:8083](http://localhost:8083) | `8083` |
| **H2 Database Console** | [http://localhost:8081/h2-console](http://localhost:8081/h2-console) | `8081` |
