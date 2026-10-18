# BBHealthApp - Master Service

The core authentication, authority management, and user orchestration microservice for **BBHealthApp**.

---

## Features
- **Authentication & Authorization**: JWT token issuance and validation.
- **User Management**: Role-based access control (Admin, Doctor, Tester, User, Government Authority).
- **H2 In-Memory/Persistent Database**: Manages application state, master records, and test thresholds.
- **Health Checks**: Actuator liveness and readiness probes on port 8081.

---

## Tech Stack
- **Framework**: Spring Boot 2.3.2.RELEASE
- **Language**: Java 11
- **Database**: H2 (sa/sa)
- **Security**: Spring Security + JWT
- **Port**: `8081`

---

## Local Development Setup

### Prerequisites
- JDK 11 installed (`java -version`)
- Maven 3.8+ (or use included `./mvnw`)

### Build and Run
```bash
# Navigate to directory
cd bbhealthapp-backend/bbhealthapp-api-master

# Package the application
./mvnw clean package -DskipTests

# Run Spring Boot application
./mvnw spring-boot:run
```
Service starts on `http://localhost:8081`.

---

## Docker Build & Run

### 1. Build Docker Image
```bash
docker build -t bbhealthapp-master-service:latest .
```

### 2. Run Container Locally
```bash
docker run -d -p 8081:8081 \
  -e SPRING_PROFILES_ACTIVE=dev \
  -e TOKEN_SECRET=10d73c0906053a33e5b96500d7c5eeaf717f199a54c5baff4d7da9d0b0 \
  --name bbhealthapp-master-service bbhealthapp-master-service:latest
```

---

## Key Endpoints
- `POST /auth/login` - User login & JWT issuance
- `GET /api/master/users` - User directory
- `GET /api/master/thresholds` - Diagnostic thresholds
