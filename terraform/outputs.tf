# =================================================================================================
# Outputs for Task 2: Terraform AWS Infrastructure
# Provides all resource IDs, ARNs, and connection endpoints needed for verification & deployment
# =================================================================================================

# -------------------------------------------------------------------------------------------------
# Subtask 2 Outputs: VPC and Networking
# -------------------------------------------------------------------------------------------------
output "vpc_id" {
  description = "The ID of the VPC (Subtask 2 requirement)"
  value       = aws_vpc.main.id
}

output "public_subnet_ids" {
  description = "List of IDs for the public subnets (Subtask 2 requirement)"
  value       = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  description = "List of IDs for the private subnets (Subtask 2 requirement)"
  value       = aws_subnet.private[*].id
}

output "internet_gateway_id" {
  description = "ID of the Internet Gateway attached to the VPC"
  value       = aws_internet_gateway.igw.id
}

output "nat_gateway_ip" {
  description = "Public Elastic IP assigned to the NAT Gateway for private subnets"
  value       = aws_nat_gateway.nat.public_ip
}

# -------------------------------------------------------------------------------------------------
# Subtask 3 Outputs: EKS Cluster and Node Groups
# -------------------------------------------------------------------------------------------------
output "cluster_name" {
  description = "The name of the EKS cluster (Subtask 3 requirement)"
  value       = aws_eks_cluster.main.name
}

output "cluster_endpoint" {
  description = "Endpoint URL for your EKS Kubernetes API server"
  value       = aws_eks_cluster.main.endpoint
}

output "cluster_certificate_authority_data" {
  description = "Base64 encoded certificate data required to communicate with your cluster"
  value       = aws_eks_cluster.main.certificate_authority[0].data
  sensitive   = true
}

output "public_node_group_arn" {
  description = "ARN of the public worker node group (Subtask 3 requirement)"
  value       = aws_eks_node_group.public_nodes.arn
}

output "private_node_group_arn" {
  description = "ARN of the private worker node group (Subtask 3 requirement)"
  value       = aws_eks_node_group.private_nodes.arn
}

output "oidc_provider_arn" {
  description = "ARN of the OIDC Provider for IAM Roles for Service Accounts (IRSA)"
  value       = aws_iam_openid_connect_provider.eks.arn
}

output "oidc_provider_url" {
  description = "Issuer URL of the OIDC Provider"
  value       = aws_iam_openid_connect_provider.eks.url
}

# -------------------------------------------------------------------------------------------------
# Subtask 4 Outputs: IAM Roles and ECR Repositories
# -------------------------------------------------------------------------------------------------
output "eks_cluster_role_arn" {
  description = "ARN of the EKS Cluster IAM Role"
  value       = aws_iam_role.cluster.arn
}

output "eks_node_role_arn" {
  description = "ARN of the EKS Node Group IAM Role"
  value       = aws_iam_role.nodes.arn
}

output "cluster_autoscaler_role_arn" {
  description = "ARN of the Cluster Autoscaler IAM Role (IRSA)"
  value       = try(aws_iam_role.cluster_autoscaler[0].arn, null)
}

output "ebs_csi_driver_role_arn" {
  description = "ARN of the EBS CSI Driver IAM Role (IRSA)"
  value       = aws_iam_role.ebs_csi.arn
}

output "ecr_repository_urls" {
  description = "Map of microservice names to ECR repository URLs (Subtask 4 requirement)"
  value = {
    for k, v in aws_ecr_repository.services : k => v.repository_url
  }
}

# -------------------------------------------------------------------------------------------------
# Subtask Bonus Outputs: Security Groups
# -------------------------------------------------------------------------------------------------
output "cluster_security_group_id" {
  description = "Security Group ID of the EKS Control Plane"
  value       = aws_security_group.cluster.id
}

output "node_security_group_id" {
  description = "Security Group ID of the EKS Worker Nodes"
  value       = aws_security_group.nodes.id
}

output "alb_security_group_id" {
  description = "Security Group ID of the Application Load Balancer"
  value       = aws_security_group.alb.id
}

# -------------------------------------------------------------------------------------------------
# Optional Components Outputs (RDS & Bastion)
# -------------------------------------------------------------------------------------------------
output "rds_endpoint" {
  description = "Connection endpoint for the RDS database"
  value       = try(aws_db_instance.postgres[0].endpoint, null)
}

output "bastion_public_ip" {
  description = "Public IP of the Bastion jump host"
  value       = try(aws_instance.bastion[0].public_ip, null)
}

