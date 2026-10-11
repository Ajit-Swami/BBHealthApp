# =================================================================================================
# Subtask 3: EKS Cluster and Node Groups Setup
# =================================================================================================

# -------------------------------------------------------------------------------------------------
# CloudWatch Log Group for EKS Control Plane
# -------------------------------------------------------------------------------------------------
resource "aws_cloudwatch_log_group" "cluster" {
  name              = "/aws/eks/${var.cluster_name}/cluster"
  retention_in_days = 7

  tags = {
    Name = "${var.cluster_name}-log-group"
  }
}

# -------------------------------------------------------------------------------------------------
# Amazon EKS Cluster
# -------------------------------------------------------------------------------------------------
resource "aws_eks_cluster" "main" {
  name     = var.cluster_name
  role_arn = aws_iam_role.cluster.arn
  version  = var.cluster_version

  vpc_config {
    subnet_ids              = concat(aws_subnet.public[*].id, aws_subnet.private[*].id)
    security_group_ids      = [aws_security_group.cluster.id]
    endpoint_private_access = true
    endpoint_public_access  = true
  }

  enabled_cluster_log_types = ["api", "audit", "authenticator", "controllerManager", "scheduler"]

  depends_on = [
    aws_iam_role_policy_attachment.cluster_eks_policy,
    aws_iam_role_policy_attachment.cluster_vpc_controller,
    aws_cloudwatch_log_group.cluster
  ]

  tags = {
    Name = var.cluster_name
  }
}

# -------------------------------------------------------------------------------------------------
# Node Group 1: Public Node Group
# Subtask 3 Requirement: At least 2 node groups (public and private), t3.medium instance type
# -------------------------------------------------------------------------------------------------
resource "aws_eks_node_group" "public_nodes" {
  cluster_name    = aws_eks_cluster.main.name
  node_group_name = "${var.project_name}-${var.environment}-public-ng"
  node_role_arn   = aws_iam_role.nodes.arn
  subnet_ids      = aws_subnet.public[*].id

  instance_types = var.node_instance_types
  ami_type       = "AL2_x86_64"
  capacity_type  = "ON_DEMAND"

  scaling_config {
    desired_size = var.public_node_desired_size
    min_size     = var.public_node_min_size
    max_size     = var.public_node_max_size
  }

  update_config {
    max_unavailable = 1
  }

  labels = {
    role           = "public-worker"
    nodegroup-type = "public"
  }

  tags = {
    Name                                            = "${var.project_name}-${var.environment}-public-node"
    "k8s.io/cluster-autoscaler/enabled"             = var.enable_cluster_autoscaler ? "true" : "false"
    "k8s.io/cluster-autoscaler/${var.cluster_name}" = "owned"
    "kubernetes.io/cluster/${var.cluster_name}"     = "owned"
  }

  depends_on = [
    aws_iam_role_policy_attachment.nodes_worker_node_policy,
    aws_iam_role_policy_attachment.nodes_cni_policy,
    aws_iam_role_policy_attachment.nodes_ecr_read_only,
    aws_iam_role_policy_attachment.nodes_ssm_policy
  ]
}

# -------------------------------------------------------------------------------------------------
# Node Group 2: Private Node Group
# Subtask 3 Requirement: At least 2 node groups (public and private), t3.medium instance type
# Secure environment for backend microservices and databases
# -------------------------------------------------------------------------------------------------
resource "aws_eks_node_group" "private_nodes" {
  cluster_name    = aws_eks_cluster.main.name
  node_group_name = "${var.project_name}-${var.environment}-private-ng"
  node_role_arn   = aws_iam_role.nodes.arn
  subnet_ids      = aws_subnet.private[*].id

  instance_types = var.node_instance_types
  ami_type       = "AL2_x86_64"
  capacity_type  = "ON_DEMAND"

  scaling_config {
    desired_size = var.private_node_desired_size
    min_size     = var.private_node_min_size
    max_size     = var.private_node_max_size
  }

  update_config {
    max_unavailable = 1
  }

  labels = {
    role           = "application-worker"
    nodegroup-type = "private"
  }

  tags = {
    Name                                            = "${var.project_name}-${var.environment}-private-node"
    "k8s.io/cluster-autoscaler/enabled"             = var.enable_cluster_autoscaler ? "true" : "false"
    "k8s.io/cluster-autoscaler/${var.cluster_name}" = "owned"
    "kubernetes.io/cluster/${var.cluster_name}"     = "owned"
  }

  depends_on = [
    aws_iam_role_policy_attachment.nodes_worker_node_policy,
    aws_iam_role_policy_attachment.nodes_cni_policy,
    aws_iam_role_policy_attachment.nodes_ecr_read_only,
    aws_iam_role_policy_attachment.nodes_ssm_policy,
    aws_nat_gateway.nat
  ]
}
