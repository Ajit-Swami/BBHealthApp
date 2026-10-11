# BBHealthApp - AWS Infrastructure Setup with Terraform

This guide will help you create AWS infrastructure using Terraform. You will learn Infrastructure as Code (IaC) by provisioning real AWS resources.

---

## Prerequisites

Before you begin, ensure you have the following:

### 1. AWS Account
- **Sign up:** https://aws.amazon.com/free/
- **Note:** AWS Free Tier includes 750 hours/month of EC2, 1000 GB/month of EBS storage
- **Important:** You will need a credit card for verification, but you can stay within free tier limits
- **Student Benefit:** AWS Educate provides free credits for students (if available through your institution)

### 2. AWS CLI
- **Download:** https://aws.amazon.com/cli/
- **Install:** Follow installation instructions for your OS
- **Configure:**
  ```bash
  aws configure
  ```
  You'll need:
  - AWS Access Key ID (from IAM console)
  - AWS Secret Access Key (from IAM console)
  - Default region (`us-west-2`)
  - Default output format (`json`)

- **Verify:**
  ```bash
  aws --version
  aws sts get-caller-identity
  ```

### 3. Terraform
- **Download:** https://www.terraform.io/downloads
- **Install:** Extract and add to PATH
- **Verify:**
  ```bash
  terraform --version
  ```

---

## Quick Start

### Step 1: Navigate to Terraform Directory

```bash
cd terraform
```

### Step 2: Configure Variables

Create or edit `terraform.tfvars`:

```hcl
aws_region                = "us-west-2"
environment               = "dev"
cluster_name              = "bbhealthapp-dev"
node_instance_type        = "t3.medium"
public_node_desired_size  = 2
public_node_min_size      = 1
public_node_max_size      = 3
private_node_desired_size = 2
private_node_min_size     = 1
private_node_max_size     = 4
enable_spot_instances     = false
enable_cluster_autoscaler = true
enable_cloudwatch_logging = true
enable_rds                = false
enable_bastion            = false
```

### Step 3: Initialize Terraform

```bash
terraform init
```

This downloads required providers (AWS, TLS, Kubernetes) and initializes the state backend.

### Step 4: Review the Plan

```bash
terraform plan -var-file="terraform.tfvars"
```

Review the resources that will be created. This shows:
- VPC and networking (Public/Private Subnets, IGW, NAT Gateway)
- EKS cluster & 2 Node Groups (Public & Private)
- IAM roles & OIDC provider
- Security groups (Control plane, Worker nodes, ALB)
- ECR repositories
- Other AWS resources

### Step 5: Apply the Configuration

```bash
terraform apply -var-file="terraform.tfvars"
```

Type `yes` when prompted to confirm.

> [!NOTE]
> This will take approximately 15-20 minutes to complete as AWS provisions the EKS control plane and worker EC2 instances.

### Step 6: Verify Infrastructure

After `terraform apply` completes, verify the created resources:

```bash
# View Terraform outputs
terraform output

# Check VPC
aws ec2 describe-vpcs --region us-west-2

# Check EKS cluster
aws eks describe-cluster --name bbhealthapp-dev --region us-west-2

# Check EC2 instances
aws ec2 describe-instances --region us-west-2

# Check ECR repositories
aws ecr describe-repositories --region us-west-2
```

### Step 7: Access AWS Console

1. Log in to AWS Console: https://console.aws.amazon.com/
2. Navigate to the region you used (`us-west-2`)
3. View the created resources:
   - **VPC** -> Your VPCs (`bbhealthapp-dev-vpc`)
   - **EC2** -> Instances (Worker nodes)
   - **EKS** -> Clusters (`bbhealthapp-dev`)
   - **ECR** -> Repositories (`bbhealthapp-*`)
   - **IAM** -> Roles (`bbhealthapp-dev-*`)

---

## Understanding Terraform

### What is Terraform?

Terraform is an Infrastructure as Code (IaC) tool that allows you to define and provision infrastructure using declarative configuration files.

### Key Concepts

**Providers:**
- Plugins that interact with cloud providers
- AWS provider interacts with AWS services
- Kubernetes provider interacts with Kubernetes clusters

**Resources:**
- Infrastructure components (VPC, EC2, EKS, etc.)
- Defined in Terraform configuration files

**State:**
- Terraform maintains state of deployed infrastructure
- Stored in S3 for real AWS (configured in `provider.tf`)
- Stored locally for local development

**Modules:**
- Reusable Terraform configurations
- Can be shared and versioned

### Terraform Files in This Project

| File | Purpose |
|------|---------|
| `provider.tf` | AWS and Kubernetes provider configuration |
| `variables.tf` | Variable definitions |
| `main.tf` | Main Terraform configuration and common locals |
| `vpc.tf` | VPC and networking (IGW, NAT-GW, Subnets with EKS tags) |
| `eks.tf` | EKS cluster and 2 node groups (public & private) |
| `iam.tf` | IAM roles, OIDC provider, and IRSA policies |
| `rds.tf` | Database configuration (optional managed RDS) |
| `ecr.tf` | ECR repositories with scanning and lifecycle policies |
| `bastion.tf` | Optional Bastion host configuration |
| `security-groups.tf` | Security groups for control plane, nodes, and ALB |
| `outputs.tf` | Output values |

---

## Cost Management

### AWS Free Tier Limits

- **EKS:** EKS control plane is ~$0.10/hour (~$72/month)
- **EC2:** 750 hours/month of t2.micro/t3.micro under Free Tier
- **EBS:** 30 GB/month of General Purpose SSD (gp2/gp3) storage under Free Tier
- **Data Transfer:** 100 GB/month free outbound

### Cost Optimization Tips

1. **Use t3.medium or smaller instances**
2. **Enable spot instances** for non-critical workloads
3. **Set up auto-scaling** to scale down when not in use
4. **Delete resources immediately after completion** to avoid ongoing costs
5. **Monitor costs** using AWS Cost Explorer

### Estimated Costs

With the default configuration:
- **EKS Cluster:** ~$0.10/hour = ~$72/month
- **EC2 Nodes (2x t3.medium):** ~$0.04/hour = ~$58/month
- **Load Balancer (ALB):** ~$0.0225/hour = ~$16/month
- **NAT Gateway:** ~$0.045/hour = ~$32/month
- **EBS Storage:** ~$0.08/GB/month
- **Total:** ~$150-200/month (outside free tier)

**Important:** Delete infrastructure immediately after completing the assignment or test to avoid charges.

---

## Security Considerations

### IAM Best Practices

1. **Use least privilege** - Only grant necessary permissions
2. **Use IAM roles** instead of access keys when possible
3. **Rotate credentials** regularly
4. **Enable MFA** on root account and IAM users
5. **Use AWS Organizations** for multi-account setup

### Network Security

1. **Use private subnets** for databases and internal microservices
2. **Use security groups** to restrict traffic between components
3. **Enable VPC Flow Logs** for monitoring
4. **Use Network ACLs** for additional security

### Data Security

1. **Enable encryption** for EBS volumes
2. **Use AWS Secrets Manager / K8s Secrets** for sensitive data
3. **Enable encryption in transit** (TLS/SSL)
4. **Regular backups** with automated snapshots

---

## Troubleshooting

### Terraform State Lock

If Terraform state is locked:

```bash
terraform force-unlock <LOCK_ID>
```

### AWS Credentials Issues

```bash
# Verify credentials
aws sts get-caller-identity

# Reconfigure
aws configure
```

### EKS Cluster Not Ready

```bash
# Check cluster status
aws eks describe-cluster --name bbhealthapp-dev --region us-west-2
```

### Node Issues

```bash
# Check node instances
aws ec2 describe-instances --region us-west-2 --filters "Name=tag:kubernetes.io/cluster/bbhealthapp-dev,Values=owned"
```

### IAM Role Issues

```bash
# Verify IAM roles
aws iam get-role --role-name bbhealthapp-dev-eks-cluster-role
aws iam get-role --role-name bbhealthapp-dev-eks-node-role
aws iam get-role --role-name bbhealthapp-dev-cluster-autoscaler-role
aws iam get-role --role-name bbhealthapp-dev-ebs-csi-driver-role
```

---

## Cleanup

**IMPORTANT:** Delete infrastructure immediately after completing the assignment to avoid ongoing AWS charges.

### Step 1: Destroy Terraform Resources

```bash
cd terraform
terraform destroy -var-file="terraform.tfvars"
```

Type `yes` when prompted to confirm.

### Step 2: Verify Cleanup

```bash
# Check if resources are deleted
aws ec2 describe-vpcs --region us-west-2
aws eks list-clusters --region us-west-2
aws ecr describe-repositories --region us-west-2
```

### Step 3: Delete ECR Repositories (if images remain)

```bash
aws ecr delete-repository --repository-name bbhealthapp-master-service --force --region us-west-2
aws ecr delete-repository --repository-name bbhealthapp-register-service --force --region us-west-2
aws ecr delete-repository --repository-name bbhealthapp-document-service --force --region us-west-2
aws ecr delete-repository --repository-name bbhealthapp-frontend --force --region us-west-2
```

---

## Report Requirements

### 1. AWS Account Setup
- Screenshots of AWS console login
- AWS CLI configuration verification (`aws configure` and `aws sts get-caller-identity`)
- IAM user creation (if applicable)
- Screenshot of AWS Free Tier status

### 2. Terraform Execution
- Screenshots of `terraform init` output
- Screenshots of `terraform plan` output (showing resources to be created)
- Screenshots of `terraform apply` execution
- Time taken for infrastructure provisioning
- Any warnings or errors encountered

### 3. Infrastructure Verification
- Screenshots of AWS console showing created resources:
  - VPC (Virtual Private Cloud)
  - Subnets (public and private)
  - EKS Cluster
  - EC2 Instances (node groups)
  - ECR Repositories
  - IAM Roles
  - Security Groups
- Screenshots of Terraform outputs (`terraform output`)

### 4. Terraform Configuration Understanding
- Explanation of each Terraform file:
  - `provider.tf` - What does it configure?
  - `variables.tf` - What variables are defined?
  - `main.tf` - What is the main configuration?
  - `vpc.tf` - What network resources are created?
  - `eks.tf` - What Kubernetes resources are provisioned?
  - `iam.tf` - What IAM roles and policies are created?
  - `rds.tf` - What database configuration is included?
  - `ecr.tf` - What container registries are created?
  - `bastion.tf` - What troubleshooting host is provided?
  - `security-groups.tf` - What ingress/egress rules control traffic?
- Explanation of `terraform.tfvars` and how you customized it

### 5. AWS Services Understanding
- Brief explanation of each AWS service used:
  - VPC (Virtual Private Cloud)
  - EKS (Elastic Kubernetes Service)
  - EC2 (Elastic Compute Cloud)
  - IAM (Identity and Access Management)
  - ECR (Elastic Container Registry)
  - RDS (Relational Database Service)
- Why each service is needed for this architecture

### 6. Cost Analysis
- Estimated costs for deployed infrastructure
- Breakdown of costs by service
- Cost optimization measures you implemented
- Comparison with AWS Free Tier limits
- Actual cost incurred (if any)

### 7. Security Implementation
- IAM roles and policies created
- Security groups configuration (what ports are open/closed)
- Network security measures (public vs private subnets)
- Any additional security best practices you implemented

### 8. Challenges & Solutions
- Any errors encountered during Terraform execution
- How you resolved each error
- Any AWS service limitations you encountered
- Workarounds or solutions implemented

### 9. Infrastructure as Code (IaC) Concepts
- What is Infrastructure as Code?
- Benefits of using Terraform over manual AWS console setup
- How Terraform state management works
- What happens when you run `terraform destroy`?

### 10. Learning Outcomes
- Top 3 things you learned from this exercise
- Understanding of cloud infrastructure provisioning
- Experience with Terraform and HCL language
- How this compares to traditional infrastructure setup
