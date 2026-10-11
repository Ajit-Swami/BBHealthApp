# BBHealthApp - Docker Local Setup Guide

This guide will help you run the BBHealthApp project on your local machine using Docker, without any AWS or cloud dependencies.

---

## Prerequisites

Before you begin, ensure you have the following installed on your machine:

### 1. Docker Desktop
- **Download:** https://www.docker.com/products/docker-desktop
- **Install:** Follow the installation instructions for your OS (Windows/Mac/Linux)
- **Verify:** Open terminal and run:
  ```bash
  docker --version
  docker-compose --version
  ```

### 2. Git (Optional - for cloning the repository)
- **Download:** https://git-scm.com/downloads
- **Install:** Follow the installation instructions

---

## Quick Start

### Step 1: Get the Project Code

**Option A: Clone from Git (if available)**
```bash
git clone <repository-url>
cd windsurf-project-3
```

**Option B: Download and Extract**
- Download the project ZIP file
- Extract it to a folder
- Navigate to the project directory in your terminal

### Step 2: Start All Services

Run the following command in the project root directory:

```bash
docker-compose up -d --build
```

This will:
- Build all Docker images (frontend, master-service, register-service, document-service)
- Start all services in the background
- Set up the network and volumes

**Note:** The first build may take 5-10 minutes as it downloads dependencies and builds images.

### Step 3: Verify Services are Running

```bash
docker-compose ps
```

You should see all 4 services running:
- frontend
- master-service
- register-service
- document-service

### Step 4: Access the Application

Open your browser and navigate to:

**Frontend Application:** http://localhost

---

## Service Endpoints

Once running, you can access individual services at:

| Service | URL | Description |
|---------|-----|-------------|
| Frontend | http://localhost | React UI application |
| Master Service | http://localhost:8081 | Authentication & user management |
| Register Service | http://localhost:8082 | User registration |
| Document Service | http://localhost:8083 | File upload/download |
| H2 Console | http://localhost:8081/h2-console | Database console |

---

## Default Login Credentials

The application comes with pre-configured test users:

| Username | Password | Role |
|----------|----------|------|
| user | password | Patient |
| doctor | password | Doctor |
| tester | password | Tester |
| authority | password | Government Authority |

---

## Common Commands

### View Logs
```bash
# View all service logs
docker-compose logs -f

# View specific service logs
docker-compose logs -f master-service
docker-compose logs -f register-service
docker-compose logs -f document-service
docker-compose logs -f frontend
```

### Stop All Services
```bash
docker-compose down
```

### Stop and Remove All Data (including database)
```bash
docker-compose down -v
```

### Restart a Specific Service
```bash
docker-compose restart master-service
```

### Rebuild a Specific Service
```bash
docker-compose up -d --build master-service
```

### Execute Commands Inside a Container
```bash
# Access master-service container
docker-compose exec master-service bash

# Access frontend container
docker-compose exec frontend sh
```

---

## Troubleshooting

### Port Already in Use

If you see an error like "port 8080 is already in use":

**Windows:**
```powershell
netstat -ano | findstr :8080
taskkill /PID <PID> /F
```

**Mac/Linux:**
```bash
lsof -ti:8080 | xargs kill -9
```

### Services Not Starting

Check the logs to see what's wrong:
```bash
docker-compose logs
```

### Docker Build Taking Too Long

- First build always takes longer as it downloads base images and dependencies
- Subsequent builds will be faster due to layer caching
- Ensure you have a stable internet connection

### Frontend Not Loading

1. Check if frontend container is running:
   ```bash
   docker-compose ps frontend
   ```

2. Check frontend logs:
   ```bash
   docker-compose logs frontend
   ```

3. Try a hard refresh in your browser (Ctrl+Shift+R or Cmd+Shift+R)

### Database Connection Issues

The H2 database is embedded in the master-service container. If you have issues:

1. Restart master-service:
   ```bash
   docker-compose restart master-service
   ```

2. Access H2 console at http://localhost:8081/h2-console with:
   - JDBC URL: `jdbc:h2:file:~/binarybrainscovid`
   - User Name: `sa`
   - Password: `sa`

### Docker Desktop Not Running

Ensure Docker Desktop is running:
- **Windows/Mac:** Check Docker Desktop icon in system tray/menu bar
- **Linux:** Check Docker service status:
  ```bash
  sudo systemctl status docker
  ```

### Permission Denied Errors

**Linux:** If you get permission denied errors, add your user to docker group:
```bash
sudo usermod -aG docker $USER
# Log out and log back in for changes to take effect
```

**Windows/Mac:** Run Docker Desktop as administrator if needed.

---

## Project Structure

```
windsurf-project-3/
├── bbhealthapp-frontend/          # React frontend application
├── bbhealthapp-backend/          # Backend microservices
│   ├── bbhealthapp-api-master/   # Master service (auth, user mgmt)
│   ├── bbhealthapp-api-register/ # Register service (registration)
│   └── bbhealthapp-api-document/ # Document service (file mgmt)
├── docker-compose.yml            # Docker orchestration file
└── DOCKER_SETUP.md               # This file
```

---

## Technology Stack

**Frontend:**
- React.js
- Material-UI
- Axios (HTTP client)

**Backend:**
- Spring Boot (Java)
- Spring Security (JWT authentication)
- H2 Database (embedded, file-based)
- Maven (build tool)

**Infrastructure:**
- Docker (containerization)
- Docker Compose (orchestration)

---

## Understanding Docker Compose

### What is Docker Compose?

Docker Compose is a tool for defining and running multi-container Docker applications. With Compose, you use a YAML file to configure your application's services.

### Key Concepts

**Services:**
- Each service runs in its own container
- Services can communicate with each other over the network
- Services are defined in `docker-compose.yml`

**Networks:**
- Docker Compose creates a bridge network for services
- Services can reach each other by service name
- External access is through published ports

**Volumes:**
- Volumes persist data even when containers are removed
- Used for database files and uploaded documents

### docker-compose.yml Structure

```yaml
services:
  frontend:        # React UI
    ports: "80:80"
    depends_on:
      - master-service
      - register-service
      - document-service
  
  master-service:  # Authentication & user management
    ports: "8081:8080"
    volumes:
      - master-uploads:/app/useruploads
  
  register-service: # User registration
    ports: "8082:8082"
    depends_on:
      - master-service
  
  document-service: # File management
    ports: "8083:8080"
```

---

## Development Tips

### Running Services Individually

If you want to run a specific service:

```bash
docker-compose up master-service
```

### Rebuilding After Code Changes

After making code changes, rebuild the affected service:

```bash
docker-compose up -d --build <service-name>
```

### Viewing Container Details

```bash
# List all containers
docker-compose ps

# View detailed container info
docker inspect <container-id>

# View container resource usage
docker stats
```

### Accessing Container Shell

```bash
# Access master-service container
docker-compose exec master-service bash

# Access frontend container (uses sh instead of bash)
docker-compose exec frontend sh
```

### Cleaning Up

Remove all containers, networks, and volumes:
```bash
docker-compose down -v
```

Remove all Docker images (use with caution):
```bash
docker system prune -a
```

---

## Docker vs Non-Docker Setup

### Advantages of Docker Setup

1. **Consistent Environment:** Same setup across all machines
2. **Isolation:** Services run in isolated containers
3. **Easy Cleanup:** Remove everything with one command
4. **No Dependency Management:** Docker handles all dependencies
5. **Reproducible:** Same setup every time

### When to Use Docker

- When you want consistent environments across teams
- When you don't want to install Java, Maven, Node.js locally
- When you want easy cleanup and reset
- When deploying to production

### When to Use Non-Docker Setup

- When you want to debug code directly
- When you need to make frequent code changes
- When you want to understand the underlying technology
- When Docker is not available or permitted

---

## Report Requirements for Docker Setup

### 1. Docker Installation
- Docker Desktop version installed
- Screenshots of `docker --version` and `docker-compose --version`
- Any issues during installation

### 2. Container Execution
- Screenshots of `docker-compose up -d --build` output
- Screenshot of `docker-compose ps` showing all services running
- Time taken for first build vs subsequent builds

### 3. Service Verification
- Screenshots of each service endpoint working
- Browser screenshots of the application
- H2 console access screenshot

### 4. Docker Concepts
- Explain what Docker containers are
- How Docker Compose orchestrates multiple services
- What are Docker volumes and why are they used
- Difference between Docker images and containers

### 5. Comparison
- Compare Docker setup vs non-Docker setup experience
- Which was easier and why
- Pros and cons of each approach

### 6. Troubleshooting
- Any Docker-specific issues faced
- How you resolved them
- Docker commands used for debugging

---

## Support

If you encounter any issues not covered in this guide:

1. Check the logs: `docker-compose logs`
2. Ensure Docker Desktop is running
3. Try stopping and restarting: `docker-compose down && docker-compose up -d`
4. Check that no other applications are using ports 80, 8081, 8082, 8083
5. Verify Docker has enough resources (memory, disk space)

---

## Next Steps

Once the application is running:

1. Open http://localhost in your browser
2. Log in with one of the default credentials (see above)
3. Explore the different dashboards based on user roles
4. Try registering a new user
5. Submit test requests and consultations
6. Upload and download documents

---

**Happy Learning! 🚀**
