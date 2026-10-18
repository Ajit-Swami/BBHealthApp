# BBHealthApp - Frontend Web Application

The frontend user interface for **BBHealthApp**, a COVID-19 health and healthcare management portal. Built with React.js, Redux, and Material-UI, and containerized with Nginx.

---

## Features
- **Role-Based Portals**: Interfaces for Patients, Doctors, Lab Testers, and Government Authorities.
- **State Management**: Redux Toolkit and Redux Persist for session authentication and routing.
- **Visual Analytics**: Interactive health statistics and test charts using Chart.js.
- **Responsive Layout**: Material-UI components with responsive mobile and desktop designs.

---

## Tech Stack
- **Framework**: React 16.14
- **State**: Redux, Redux Thunk
- **UI Components**: Material-UI (v4)
- **Routing**: React Router v5
- **Web Server (Production)**: Nginx (Alpine)

---

## Local Development Setup

### Prerequisites
- Node.js 16+ or Node.js 18+
- npm or yarn

### Installation & Run
```bash
# Navigate to frontend directory
cd bbhealthapp-frontend

# Install dependencies
npm install

# Start development server (runs on http://localhost:3000)
npm start
```

---

## Docker Build & Run

### 1. Build the Docker Image
```bash
docker build -t bbhealthapp-frontend:latest .
```

### 2. Run Container Locally
```bash
docker run -d -p 80:80 --name bbhealthapp-frontend bbhealthapp-frontend:latest
```
Access the application at `http://localhost`.

---

## Environment Variables
Configured in `.env`:
- `REACT_APP_API_BASE_URL`: Base URL for backend microservices (proxied via Nginx or Ingress).
