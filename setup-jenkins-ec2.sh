#!/usr/bin/env bash
# ==============================================================================
# BBHealthApp - Automated Jenkins Server & Agent Setup on AWS EC2 (Ubuntu)
# Installs: Java 17, Jenkins, Docker, AWS CLI v2, kubectl, and Git
# Configures permissions for the jenkins user without Helm dependency
# ==============================================================================

set -euo pipefail

echo "=================================================================="
echo " Starting BBHealthApp Jenkins Setup on EC2"
echo "=================================================================="

# 1. Update OS packages
echo "[1/6] Updating package lists..."
sudo apt-get update -y
sudo apt-get install -y ca-certificates curl gnupg lsb-release unzip git fontconfig

# 2. Install OpenJDK 17 (Required by Jenkins 2.400+)
echo "[2/6] Installing OpenJDK 17..."
sudo apt-get install -y openjdk-17-jdk openjdk-17-jre
java -version

# 3. Install Jenkins (Official Debian/Ubuntu repo)
echo "[3/6] Installing Jenkins..."
sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key | sudo tee \
  /etc/apt/keyrings/jenkins-keyring.asc > /dev/null

echo deb [signed-by=/etc/apt/keyrings/jenkins-keyring.asc] \
  https://pkg.jenkins.io/debian-stable binary/ | sudo tee \
  /etc/apt/sources.list.d/jenkins.list > /dev/null

sudo apt-get update -y
sudo apt-get install -y jenkins

# 4. Install Docker
echo "[4/6] Installing Docker Engine..."
sudo apt-get install -y docker.io
sudo systemctl start docker
sudo systemctl enable docker

# Add ubuntu and jenkins users to docker group
sudo usermod -aG docker jenkins || true
sudo usermod -aG docker ubuntu || true

# 5. Install AWS CLI v2
echo "[5/6] Installing AWS CLI v2..."
if ! command -v aws &> /dev/null; then
    curl -s "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
    unzip -q awscliv2.zip
    sudo ./aws/install --update
    rm -rf awscliv2.zip aws
fi
aws --version

# 6. Install kubectl
echo "[6/6] Installing kubectl..."
if ! command -v kubectl &> /dev/null; then
    KUBECTL_VERSION=$(curl -L -s https://dl.k8s.io/release/stable.txt)
    curl -LO "https://dl.k8s.io/release/${KUBECTL_VERSION}/bin/linux/amd64/kubectl"
    sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
    rm -f kubectl
fi
kubectl version --client

# 7. Start and Enable Jenkins
echo "Configuring Jenkins service..."
sudo systemctl enable jenkins
sudo systemctl restart jenkins

echo ""
echo "=================================================================="
echo " Jenkins Setup Complete!"
echo "=================================================================="
echo ""
echo "Jenkins is now running on port 8080."
echo "Make sure your EC2 Security Group allows Inbound TCP on port 8080."
echo ""
echo "Initial Jenkins Administrator Password:"
sudo cat /var/lib/jenkins/secrets/initialAdminPassword || echo "Password file will be generated shortly once Jenkins completes first startup."
echo ""
echo "Access Jenkins at: http://<EC2-PUBLIC-IP>:8080"
echo "=================================================================="
