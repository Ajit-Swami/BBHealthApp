variable "aws_region" {
  description = "The AWS region where resources will be created"
  type        = string
  default     = "us-west-2"
}

variable "project_name" {
  description = "Project identifier used in naming resources"
  type        = string
  default     = "bbhealthapp"
}

variable "environment" {
  description = "Deployment environment (e.g. dev, staging, prod)"
  type        = string
  default     = "dev"
}

# -------------------------------------------------------------------------------------------------
# Networking Variables (Subtask 2)
# -------------------------------------------------------------------------------------------------
variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "availability_zones" {
  description = "List of Availability Zones to use in the chosen AWS region"
  type        = list(string)
  default     = ["us-west-2a", "us-west-2b"]
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for public subnets"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks for private subnets"
  type        = list(string)
  default     = ["10.0.10.0/24", "10.0.20.0/24"]
}

# -------------------------------------------------------------------------------------------------
# EKS Cluster & Node Groups Variables (Subtask 3)
# -------------------------------------------------------------------------------------------------
variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
  default     = "bbhealthapp-dev"
}

variable "cluster_version" {
  description = "Kubernetes control plane version"
  type        = string
  default     = "1.29"
}

variable "node_instance_type" {
  description = "Primary instance type for EKS worker nodes (t3.medium as per guide)"
  type        = string
  default     = "t3.medium"
}

variable "node_instance_types" {
  description = "List of instance types for EKS worker nodes"
  type        = list(string)
  default     = ["t3.medium"]
}

variable "node_desired_size" {
  description = "Default desired number of worker nodes"
  type        = number
  default     = 2
}

variable "node_min_size" {
  description = "Default minimum number of worker nodes"
  type        = number
  default     = 1
}

variable "node_max_size" {
  description = "Default maximum number of worker nodes"
  type        = number
  default     = 3
}

variable "public_node_desired_size" {
  description = "Desired number of worker nodes in the public node group"
  type        = number
  default     = 2
}

variable "public_node_min_size" {
  description = "Minimum number of worker nodes in the public node group"
  type        = number
  default     = 1
}

variable "public_node_max_size" {
  description = "Maximum number of worker nodes in the public node group"
  type        = number
  default     = 3
}

variable "private_node_desired_size" {
  description = "Desired number of worker nodes in the private node group"
  type        = number
  default     = 2
}

variable "private_node_min_size" {
  description = "Minimum number of worker nodes in the private node group"
  type        = number
  default     = 1
}

variable "private_node_max_size" {
  description = "Maximum number of worker nodes in the private node group"
  type        = number
  default     = 4
}

variable "enable_spot_instances" {
  description = "Whether to use Spot instances instead of On-Demand to optimize costs"
  type        = bool
  default     = false
}

variable "enable_cluster_autoscaler" {
  description = "Enable Cluster Autoscaler tags and IAM configuration"
  type        = bool
  default     = true
}

variable "enable_cloudwatch_logging" {
  description = "Enable CloudWatch control plane logging for EKS"
  type        = bool
  default     = true
}

# -------------------------------------------------------------------------------------------------
# Optional Infrastructure Components (RDS & Bastion)
# -------------------------------------------------------------------------------------------------
variable "enable_rds" {
  description = "Whether to provision an AWS RDS PostgreSQL database instance"
  type        = bool
  default     = false
}

variable "enable_bastion" {
  description = "Whether to provision a Bastion jump host for secure private network access"
  type        = bool
  default     = false
}

# -------------------------------------------------------------------------------------------------
# ECR Variables (Subtask 4)
# -------------------------------------------------------------------------------------------------
variable "ecr_repositories" {
  description = "List of ECR repository names to create for BBHealthApp microservices"
  type        = list(string)
  default = [
    "bbhealthapp-frontend",
    "bbhealthapp-master-service",
    "bbhealthapp-register-service",
    "bbhealthapp-document-service"
  ]
}
