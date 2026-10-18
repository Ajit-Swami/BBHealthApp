# BBHealthApp - Register Service

The user registration and onboarding microservice for **BBHealthApp**.

---

## Features
- **User Registration**: Public registration workflow for new patients, testers, and doctors.
- **Account Validation**: Validates user identity and role assignment with Master Service.
- **Input Verification**: Form validation for contact info, government IDs, and credentials.
- **Health Checks**: Actuator liveness and readiness probes on port 8082.

---

## Tech Stack
- **Framework**: Spring Boot 2.3.2.RELEASE
- **Language**: Java 11
- **Security**: Spring Security + JWT Validation
- **Port**: `8082`

---

## Local Development Setup

### Prerequisites
- JDK 11 installed (`java -version`)
- Maven 3.8+ (or use included `./mvnw`)

### Build and Run
```bash
# Navigate to directory
cd bbhealthapp-backend/bbhealthapp-api-register

# Package the application
./mvnw clean package -DskipTests

# Run Spring Boot application
./mvnw spring-boot:run
```
Service starts on `http://localhost:8082`.

---

## Docker Build & Run

### 1. Build Docker Image
```bash
docker build -t bbhealthapp-register-service:latest .
```

### 2. Run Container Locally
```bash
docker run -d -p 8082:8082 \
  -e SPRING_PROFILES_ACTIVE=dev \
  -e TOKEN_SECRET=10d73c0906053a33e5b96500d7c5eeaf717f199a54c5baff4d7da9d0b0 \
  --name bbhealthapp-register-service bbhealthapp-register-service:latest
```

---

## Key Endpoints
- `POST /api/register` - Register a new user
- `POST /api/register/doctor` - Register a medical professional
