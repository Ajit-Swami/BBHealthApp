# PowerShell script to build Docker images for BBHealthApp
$ErrorActionPreference = "Stop"

$Registry = if ($env:REGISTRY) { $env:REGISTRY } else { "bbhealthapp" }
$Tag = if ($env:TAG) { $env:TAG } else { "latest" }

Write-Host "=================================================="
Write-Host "Building BBHealthApp Docker Images"
Write-Host "Registry: $Registry"
Write-Host "Tag:      $Tag"
Write-Host "=================================================="
Write-Host ""

Write-Host "[1/4] Building Master Service..."
docker build -t "$($Registry)-master-service:$Tag" ./bbhealthapp-backend/bbhealthapp-api-master

Write-Host "[2/4] Building Register Service..."
docker build -t "$($Registry)-register-service:$Tag" ./bbhealthapp-backend/bbhealthapp-api-register

Write-Host "[3/4] Building Document Service..."
docker build -t "$($Registry)-document-service:$Tag" ./bbhealthapp-backend/bbhealthapp-api-document

Write-Host "[4/4] Building Frontend..."
docker build -t "$($Registry)-frontend:$Tag" ./bbhealthapp-frontend

Write-Host ""
Write-Host "=================================================="
Write-Host "All Docker images built successfully!"
Write-Host "=================================================="
