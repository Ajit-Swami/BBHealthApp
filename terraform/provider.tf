terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.25"
    }
  }

  # -------------------------------------------------------------------------------------------------
  # Remote Backend Configuration (Subtask 1)
  #
  # Guidelines:
  # 1. Choose region as 'us-west-2'
  # 2. Create a unique bucket name for Terraform state (e.g. bbhealthapp-tfstate-<your-account-id>)
  # 3. Create a DynamoDB table for state locking (e.g. bbhealthapp-tf-locks)
  # 4. Once your S3 bucket and DynamoDB table are created (you can use bootstrap-backend script),
  #    uncomment the block below with your bucket name, and run:
  #      terraform init -migrate-state
  # -------------------------------------------------------------------------------------------------
  # backend "s3" {
  #   bucket         = "bbhealthapp-terraform-state-uswest2-unique"
  #   key            = "eks/terraform.tfstate"
  #   region         = "us-west-2"
  #   dynamodb_table = "bbhealthapp-terraform-locks"
  #   encrypt        = true
  # }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = local.common_tags
  }
}

# -------------------------------------------------------------------------------------------------
# Kubernetes Provider Configuration
# Connects directly to the provisioned EKS cluster endpoint using AWS IAM authentication
# -------------------------------------------------------------------------------------------------
provider "kubernetes" {
  host                   = aws_eks_cluster.main.endpoint
  cluster_ca_certificate = base64decode(aws_eks_cluster.main.certificate_authority[0].data)
  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    args        = ["eks", "get-token", "--cluster-name", aws_eks_cluster.main.name]
    command     = "aws"
  }
}
