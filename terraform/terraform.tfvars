# -------------------------------------------------------------------------------------------------
# Task 2: Subtask 1 - Specific Configuration Values
# -------------------------------------------------------------------------------------------------

aws_region   = "us-west-2"
environment  = "dev"
project_name = "bbhealthapp"

# Network Configuration
vpc_cidr             = "10.0.0.0/16"
availability_zones   = ["us-west-2a", "us-west-2b"]
public_subnet_cidrs  = ["10.0.1.0/24", "10.0.2.0/24"]
private_subnet_cidrs = ["10.0.10.0/24", "10.0.20.0/24"]

# EKS Cluster Configuration
cluster_name              = "bbhealthapp-dev"
cluster_version           = "1.29"
enable_cloudwatch_logging = true

# Node Configuration (t3.medium instance type as required by Subtask 3 & guide)
node_instance_type  = "t3.medium"
node_instance_types = ["t3.medium"]

# Sizing Defaults
node_desired_size = 2
node_min_size     = 1
node_max_size     = 3

# Public Node Group sizing
public_node_desired_size = 2
public_node_min_size     = 1
public_node_max_size     = 3

# Private Node Group sizing
private_node_desired_size = 2
private_node_min_size     = 1
private_node_max_size     = 4

# Features & Optimization
enable_spot_instances     = false
enable_cluster_autoscaler = true

# Optional Infrastructure (set true if dedicated RDS or Bastion is needed)
enable_rds     = false
enable_bastion = false

# ECR Repositories for Docker Images (Subtask 4)
ecr_repositories = [
  "bbhealthapp-frontend",
  "bbhealthapp-master-service",
  "bbhealthapp-register-service",
  "bbhealthapp-document-service"
]
