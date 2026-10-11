# Task 2: Terraform AWS Infrastructure - BBHealthApp

This directory contains the production-grade Infrastructure as Code (IaC) implementation for **Task 2: Terraform AWS Infrastructure** for the BBHealthApp COVID-19 health management system.

---

## Architecture Overview

```
                      +---------------------------------------+
                      |         AWS Region: us-west-2         |
                      |                                       |
                      |  VPC: 10.0.0.0/16                     |
                      |                                       |
                      |  +---------------------------------+  |
                      |  |     Internet Gateway (IGW)      |  |
                      |  +----------------+----------------+  |
                      |                   |                   |
                      |  +----------------v----------------+  |
                      |  |   Public Subnets (us-west-2a/b) |  |
                      |  |   10.0.1.0/24, 10.0.2.0/24      |  |
                      |  |   - Application Load Balancer   |  |
                      |  |   - NAT Gateway (Elastic IP)    |  |
                      |  |   - Public Node Group (t3.med)  |  |
                      |  +----------------+----------------+  |
                      |                   | (NAT)             |
                      |  +----------------v----------------+  |
                      |  |   Private Subnets (us-west-2a/b)|  |
                      |  |   10.0.10.0/24, 10.0.20.0/24    |  |
                      |  |   - EKS Managed Private Nodes   |  |
                      |  |     (t3.medium, BBHealthApp)    |  |
                      |  |   - Master, Register, Document  |  |
                      |  +---------------------------------+  |
                      |                                       |
                      |  EKS Control Plane (Kubernetes v1.29) |
                      |  OIDC Provider (IRSA)                 |
                      |  4x ECR Repositories                  |
                      +---------------------------------------+
```

---

## File Structure

| File | Purpose | Subtask Mapping |
|------|---------|-----------------|
| `provider.tf` | AWS & TLS providers, remote S3 state backend configuration | Subtask 1 |
| `variables.tf` | Parameterized variables for region, CIDRs, node types, names | Subtask 1 |
| `terraform.tfvars` | Concrete values customized for `us-west-2` and `bbhealthapp` | Subtask 1 |
| `vpc.tf` | VPC, IGW, NAT Gateway, Public/Private subnets with EKS tags, Route Tables | Subtask 2 |
| `eks.tf` | EKS Cluster, CloudWatch logging, Public & Private Node Groups (`t3.medium`) | Subtask 3 |
| `iam.tf` | Cluster Role, Node Role, OIDC Provider, IRSA for Autoscaler & EBS CSI | Subtasks 3 & 4 |
| `ecr.tf` | ECR Repositories for 4 microservices with scanning & lifecycle policies | Subtask 4 |
| `security-groups.tf` | Granular Security Groups for Control Plane, Worker Nodes, and ALB | Bonus Subtask |
| `outputs.tf` | Exposes VPC IDs, Subnet IDs, Cluster Endpoints, ECR URLs, IAM ARNs | Subtasks 2, 3, 4 |
| `bootstrap-backend.ps1` | Windows PowerShell helper to create S3 bucket & DynamoDB lock table | Subtask 1 |
| `bootstrap-backend.sh` | Bash helper to create S3 bucket & DynamoDB lock table | Subtask 1 |

---

## Subtask 1: AWS CLI and Terraform Initialization

### Guidelines Checklist:
- [x] Choose region as `us-west-2`
- [x] Create a unique bucket name for Terraform state
- [x] Configure the S3 backend in `provider.tf`
- [x] Review all variables in `variables.tf`
- [x] Create a `terraform.tfvars` file with specific values

### 1. Configure AWS CLI
Ensure your AWS credentials are valid and active:
```bash
aws configure
# AWS Access Key ID: <YOUR_KEY>
# AWS Secret Access Key: <YOUR_SECRET>
# Default region name: us-west-2
# Default output format: json

aws sts get-caller-identity
```

### 2. Create the S3 State Bucket & DynamoDB Lock Table
An automated script is provided in both PowerShell and Bash:

**PowerShell (Windows):**
```powershell
.\bootstrap-backend.ps1
```

**Bash (Linux / macOS):**
```bash
chmod +x bootstrap-backend.sh
./bootstrap-backend.sh
```

This creates:
- S3 Bucket: `bbhealthapp-terraform-state-<ACCOUNT_ID>-us-west-2` (with AES256 encryption, versioning, and public access blocked)
- DynamoDB Table: `bbhealthapp-terraform-locks` (primary key `LockID` for state locking)

### 3. Enable S3 Backend in `provider.tf`
Uncomment the `backend "s3"` block in `provider.tf` and fill in your bucket name:
```hcl
backend "s3" {
  bucket         = "bbhealthapp-terraform-state-<ACCOUNT_ID>-us-west-2"
  key            = "eks/terraform.tfstate"
  region         = "us-west-2"
  dynamodb_table = "bbhealthapp-terraform-locks"
  encrypt        = true
}
```

### 4. Initialize Terraform
```bash
terraform init
```

---

## Subtask 2: VPC and Networking Setup

### Guidelines Checklist:
- [x] Note the VPC ID and subnet IDs after creation
- [x] Verify subnets are tagged according to EKS requirements
- [x] Ensure public subnets have internet access via IGW
- [x] Ensure private subnets route internet traffic via NAT-GW
- [x] Take screenshots of VPC in AWS Console

### EKS Subnet Tagging Rules Implemented
| Subnet Type | Required Tag | Purpose |
|-------------|--------------|---------|
| **Public Subnets** | `kubernetes.io/role/elb = 1` | Informs AWS Load Balancer Controller to place Internet-Facing ALBs here |
| **Public Subnets** | `kubernetes.io/cluster/bbhealthapp-dev = shared` | Cluster resource discovery |
| **Private Subnets** | `kubernetes.io/role/internal-elb = 1` | Informs AWS Load Balancer Controller to place Internal ALBs here |
| **Private Subnets** | `kubernetes.io/cluster/bbhealthapp-dev = shared` | Cluster resource discovery |

### Routing Topology
- **Public Route Table:** Destination `0.0.0.0/0` -> Internet Gateway (`aws_internet_gateway.igw`)
- **Private Route Table:** Destination `0.0.0.0/0` -> NAT Gateway (`aws_nat_gateway.nat`) with dedicated Elastic IP

### Verification Commands
```bash
# Display VPC and Subnet IDs from Terraform Output
terraform output vpc_id
terraform output public_subnet_ids
terraform output private_subnet_ids

# Query VPC details via AWS CLI
aws ec2 describe-vpcs --vpc-ids $(terraform output -raw vpc_id) --region us-west-2

# Verify Subnet Tags
aws ec2 describe-subnets \
  --filters "Name=vpc-id,Values=$(terraform output -raw vpc_id)" \
  --query "Subnets[*].[SubnetId,CidrBlock,Tags[?Key=='kubernetes.io/role/elb'||Key=='kubernetes.io/role/internal-elb'].Value]" \
  --output table --region us-west-2
```

### Screenshots for Report (AWS Console)
1. **VPC Dashboard:** Navigate to `VPC > Your VPCs`, filter by region `us-west-2`, select `bbhealthapp-dev-vpc`.
2. **Subnets:** Navigate to `VPC > Subnets`, show the 2 public and 2 private subnets and their `Tags` tab displaying `kubernetes.io/role/elb` and `kubernetes.io/role/internal-elb`.
3. **Route Tables:** Navigate to `VPC > Route Tables`, select `public-rt` (showing IGW target) and `private-rt` (showing NAT Gateway target).
4. **NAT Gateway:** Navigate to `VPC > NAT Gateways`, select `bbhealthapp-dev-nat-gw` showing the associated Elastic IP.

---

## Subtask 3: EKS Cluster Setup

### Guidelines Checklist:
- [x] Use `t3.medium` or similar instance type for nodes
- [x] Create at least 2 node groups (public and private)
- [x] Enable OIDC for IAM roles for service accounts (IRSA)
- [x] Enable cluster autoscaler (tags & least-privilege IAM policy)
- [x] Take screenshots of EKS cluster in AWS Console
- [x] Take screenshots of node groups

### Node Groups Specification
1. **Public Node Group (`bbhealthapp-dev-public-ng`):**
   - Subnets: Public subnets (`10.0.1.0/24`, `10.0.2.0/24`)
   - Instance Type: `t3.medium`
   - Capacity Type: `ON_DEMAND`
   - Sizing: Desired = 2, Min = 1, Max = 3
   - Node Labels: `role=public-worker`, `nodegroup-type=public`
   - Autoscaler Tags: `k8s.io/cluster-autoscaler/enabled=true`, `k8s.io/cluster-autoscaler/bbhealthapp-dev=owned`

2. **Private Node Group (`bbhealthapp-dev-private-ng`):**
   - Subnets: Private subnets (`10.0.10.0/24`, `10.0.20.0/24`)
   - Instance Type: `t3.medium`
   - Capacity Type: `ON_DEMAND`
   - Sizing: Desired = 2, Min = 1, Max = 4
   - Node Labels: `role=application-worker`, `nodegroup-type=private`
   - Autoscaler Tags: `k8s.io/cluster-autoscaler/enabled=true`, `k8s.io/cluster-autoscaler/bbhealthapp-dev=owned`

### OIDC & Cluster Autoscaler
- `aws_iam_openid_connect_provider.eks` establishes federation between AWS STS and EKS service accounts.
- `cluster_autoscaler_role` binds `system:serviceaccount:kube-system:cluster-autoscaler` to a scoped IAM policy allowing EC2 and AutoScaling describe/resize actions.

### Verification Commands
```bash
# Check EKS Cluster status
aws eks describe-cluster --name bbhealthapp-dev --region us-west-2 --query "cluster.status"

# List Node Groups
aws eks list-nodegroups --cluster-name bbhealthapp-dev --region us-west-2

# Connect kubectl to cluster
aws eks update-kubeconfig --name bbhealthapp-dev --region us-west-2

# Verify Kubernetes Nodes
kubectl get nodes -o wide --show-labels
```

### Screenshots for Report (AWS Console)
1. **EKS Cluster:** Navigate to `Elastic Kubernetes Service > Clusters > bbhealthapp-dev`, capture the Overview tab showing Status: `Active`, Kubernetes version `1.29`, and Endpoint.
2. **Compute Tab (Node Groups):** Click `Compute` tab showing both `bbhealthapp-dev-public-ng` and `bbhealthapp-dev-private-ng` in `Active` status.
3. **EC2 Instances:** Navigate to `EC2 > Instances`, filter by tag `kubernetes.io/cluster/bbhealthapp-dev` to show all running `t3.medium` worker instances.

---

## Subtask 4: IAM Roles and ECR Setup

### Guidelines Checklist:
- [x] ECR repositories for storing Docker images
- [x] IAM roles following least privilege principle
- [x] Verify IAM roles are correctly attached
- [x] Take screenshots of IAM roles in AWS Console
- [x] Take screenshots of ECR repositories

### ECR Repositories Provisioned
1. `bbhealthapp-frontend`
2. `bbhealthapp-master-service`
3. `bbhealthapp-register-service`
4. `bbhealthapp-document-service`

Each repository includes:
- **Scan on Push:** Automatically runs vulnerability scans on newly pushed Docker images.
- **AES-256 Encryption:** Server-side encryption at rest.
- **Lifecycle Policy:** Automatically prunes untagged or old images beyond the last 10 builds to minimize storage costs.

### IAM Roles (Least Privilege Principle)
1. **EKS Cluster Role (`bbhealthapp-dev-eks-cluster-role`):**
   - Assumed by: `eks.amazonaws.com`
   - Policies: `AmazonEKSClusterPolicy`, `AmazonEKSVPCResourceController`
2. **Worker Node Role (`bbhealthapp-dev-eks-node-role`):**
   - Assumed by: `ec2.amazonaws.com`
   - Policies: `AmazonEKSWorkerNodePolicy`, `AmazonEKS_CNI_Policy`, `AmazonEC2ContainerRegistryReadOnly`, `AmazonSSMManagedInstanceCore`
3. **Cluster Autoscaler Role (`bbhealthapp-dev-cluster-autoscaler-role`):**
   - Assumed by: OIDC Federated token for `kube-system:cluster-autoscaler`
   - Policies: Custom least-privilege policy restricted to cluster AutoScaling groups
4. **EBS CSI Driver Role (`bbhealthapp-dev-ebs-csi-driver-role`):**
   - Assumed by: OIDC Federated token for `kube-system:ebs-csi-controller-sa`
   - Policies: `AmazonEBSCSIDriverPolicy` (manages EBS volume lifecycle for `pvc.yaml`)

### Verification Commands
```bash
# List created ECR repositories
aws ecr describe-repositories --region us-west-2 --query "repositories[*].[repositoryName,repositoryUri]" --output table

# Verify IAM Role attachments
aws iam list-attached-role-policies --role-name bbhealthapp-dev-eks-cluster-role
aws iam list-attached-role-policies --role-name bbhealthapp-dev-eks-node-role
aws iam list-attached-role-policies --role-name bbhealthapp-dev-cluster-autoscaler-role
aws iam list-attached-role-policies --role-name bbhealthapp-dev-ebs-csi-driver-role
```

### Screenshots for Report (AWS Console)
1. **ECR Repositories:** Navigate to `Amazon ECR > Repositories` in `us-west-2`, capture the list showing all 4 repositories.
2. **IAM Roles:** Navigate to `IAM > Roles`, search `bbhealthapp-dev`, show the cluster and node roles with their attached policies.

---

## Subtask Bonus: Comprehensive Security Groups Analysis (With Data)

### 1. Overview of Security Groups Created

```
+-----------------------------------------------------------------------------------------+
|                                     AWS Internet                                        |
+--------------------------------------------+--------------------------------------------+
                                             | Ports 80, 443 (HTTP/HTTPS)
                                             v
               +-------------------------------------------------------------+
               | Application Load Balancer Security Group (alb-sg)           |
               +-----------------------------+-------------------------------+
                                             | NodePort 30000-32767
                                             | Container Ports 80, 8081-8083
                                             v
               +-------------------------------------------------------------+
               | Worker Nodes Security Group (nodes-sg)                      |
               | - Intra-Node / Pod-to-Pod Traffic (All Protocols/Ports)     |
               +-----------------------------^-------------------------------+
                        | Port 443           | Port 10250 (Kubelet API)
                        | (API Server)       | Port 443 (Admission Webhook)
                        v                    |
               +-----------------------------+-------------------------------+
               | EKS Control Plane Security Group (cluster-sg)               |
               +-------------------------------------------------------------+
```

### 2. Complete Data Specification of Security Group Rules

#### A. Control Plane Security Group (`bbhealthapp-dev-cluster-sg`)
| Direction | Protocol | Port Range | Source / Destination | Purpose / Rationale |
|-----------|----------|------------|----------------------|---------------------|
| **Ingress** | TCP | 443 | `bbhealthapp-dev-nodes-sg` | Allows Kubelet, kube-proxy, and AWS VPC CNI running on worker nodes to reach Kubernetes API server. |
| **Egress** | TCP | 10250 | `bbhealthapp-dev-nodes-sg` | Allows API server to talk to Kubelet on nodes for `kubectl logs`, `kubectl exec`, and metrics scraping. |
| **Egress** | TCP | 443 | `bbhealthapp-dev-nodes-sg` | Allows API server to communicate with Admission Webhooks and extension API services hosted in worker pods. |

#### B. Worker Nodes Security Group (`bbhealthapp-dev-nodes-sg`)
| Direction | Protocol | Port Range | Source / Destination | Purpose / Rationale |
|-----------|----------|------------|----------------------|---------------------|
| **Ingress** | ALL | ALL (0-65535) | `bbhealthapp-dev-nodes-sg` (self) | **Pod-to-Pod inter-node communication**: Microservices (Frontend -> Master/Register/Document), CoreDNS (UDP/TCP 53), and AWS VPC CNI overlay. |
| **Ingress** | TCP | 10250 | `bbhealthapp-dev-cluster-sg` | Enables control plane to invoke node Kubelet API for health checks, exec, and log retrieval. |
| **Ingress** | TCP | 443 | `bbhealthapp-dev-cluster-sg` | Enables control plane to call validating/mutating webhooks running on worker nodes. |
| **Ingress** | TCP | 30000 - 32767 | `bbhealthapp-dev-alb-sg` | **Kubernetes NodePort range**: Allows ALB to distribute external traffic to exposed NodePort Kubernetes services. |
| **Ingress** | TCP | 80, 8081 - 8083 | `bbhealthapp-dev-alb-sg` | **Pod Target Direct Routing**: Allows ALB using IP target mode (`aws-load-balancer-type: ip`) to route directly to pod ENIs. |
| **Egress** | ALL | ALL (0-65535) | `0.0.0.0/0` | Outbound communication to: ECR for pulling container images, AWS STS for IAM token acquisition, and external APIs. |

#### C. Application Load Balancer Security Group (`bbhealthapp-dev-alb-sg`)
| Direction | Protocol | Port Range | Source / Destination | Purpose / Rationale |
|-----------|----------|------------|----------------------|---------------------|
| **Ingress** | TCP | 80 | `0.0.0.0/0` | Public internet access for web browsers to reach BBHealthApp frontend and HTTP endpoints. |
| **Ingress** | TCP | 443 | `0.0.0.0/0` | Public internet access for secure HTTPS traffic. |
| **Egress** | TCP | 30000 - 32767 | `bbhealthapp-dev-nodes-sg` | Forward incoming requests to Kubernetes worker nodes on designated NodePorts. |
| **Egress** | TCP | 80, 8081 - 8083 | `bbhealthapp-dev-nodes-sg` | Forward incoming requests directly to pod container ports (when target-type is `ip`). |

### 3. How Security Groups Control Traffic Between Components

1. **Isolation of the EKS Control Plane:**
   - The Control Plane security group only accepts inbound connections from the worker nodes on port 443.
   - The public internet CANNOT connect directly to node kubelet ports (port 10250 is never exposed to `0.0.0.0/0`), preventing unauthorized code execution or container tampering.

2. **Perimeter Defense with ALB Security Group:**
   - Only the ALB Security Group is permitted to receive inbound connections from `0.0.0.0/0` on standard HTTP/HTTPS ports (80 and 443).
   - Worker nodes are completely shielded from direct public ingress on application ports. All traffic must pass through the ALB first.

3. **Restricted Ingress on Worker Nodes:**
   - Worker nodes only accept application traffic if the origin security group is `bbhealthapp-dev-alb-sg`.
   - Any external client trying to directly access a worker node IP on ports 30000-32767 will be dropped at the AWS Hypervisor layer by the security group.

4. **Zero-Trust Intra-Cluster Networking:**
   - Node-to-node communication is secured by matching the security group identifier (`self = true`). Only EC2 instances provisioned within the cluster node group can participate in pod-to-pod networking and DNS resolution.

---

## Step-by-Step Execution Guide

### 1. Check Formatting & Validate
```bash
cd terraform
terraform fmt
terraform validate
```

### 2. Plan Infrastructure
```bash
terraform plan -var-file="terraform.tfvars"
```

### 3. Provision Infrastructure (15-20 minutes)
```bash
terraform apply -var-file="terraform.tfvars"
# Type 'yes' when prompted
```

### 4. Configure `kubectl`
```bash
aws eks update-kubeconfig --name bbhealthapp-dev --region us-west-2
kubectl get nodes
kubectl get svc -A
```

### 5. Tear Down / Cleanup (Avoid Incurring AWS Costs)
```bash
terraform destroy -var-file="terraform.tfvars"
# Type 'yes' when prompted
```
