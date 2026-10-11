# =================================================================================================
# Main Terraform Configuration
# Defines common locals, data sources, and global project metadata
# =================================================================================================

data "aws_caller_identity" "current" {}

data "aws_availability_zones" "available" {
  state = "available"
}

locals {
  name       = "${var.project_name}-${var.environment}"
  account_id = data.aws_caller_identity.current.account_id

  common_tags = {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "Terraform"
    ClusterName = var.cluster_name
  }
}
