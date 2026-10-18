# BBHealthApp - Document Service

The document management and medical report upload microservice for **BBHealthApp**.

---

## Features
- **Medical Report Uploads**: Upload COVID-19 lab results, doctor prescriptions, and patient diagnostic files.
- **File Retrieval & Streaming**: Secure download and viewing of stored medical files.
- **Persistent Storage**: Saves uploaded documents to persistent volume storage `/app/useruploads`.
- **Health Checks**: Actuator liveness and readiness probes on port 8083.

---

## Tech Stack
- **Framework**: Spring Boot 2.3.2.RELEASE
- **Language**: Java 11
- **File Storage**: Local filesystem mount / Kubernetes PVC
- **Port**: `8083`

---

## Local Development Setup

### Prerequisites
- JDK 11 installed (`java -version`)
- Maven 3.8+ (or use included `./mvnw`)

### Build and Run
```bash
# Navigate to directory
cd bbhealthapp-backend/bbhealthapp-api-document

# Package the application
./mvnw clean package -DskipTests

# Run Spring Boot application
./mvnw spring-boot:run
```
Service starts on `http://localhost:8083`.

---

## Docker Build & Run

### 1. Build Docker Image
```bash
docker build -t bbhealthapp-document-service:latest .
```

### 2. Run Container Locally
```bash
docker run -d -p 8083:8083 \
  -e SPRING_PROFILES_ACTIVE=dev \
  -e TOKEN_SECRET=10d73c0906053a33e5b96500d7c5eeaf717f199a54c5baff4d7da9d0b0 \
  -v $(pwd)/uploads:/app/useruploads \
  --name bbhealthapp-document-service bbhealthapp-document-service:latest
```

---

## Key Endpoints
- `POST /documents/upload` - Upload a diagnostic report / prescription
- `GET /documents/{id}` - Fetch document by ID
- `GET /documents/user/{userId}` - Fetch all documents for a patient
