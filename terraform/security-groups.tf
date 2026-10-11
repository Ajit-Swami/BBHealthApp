# =================================================================================================
# Subtask 2, 3 & Bonus: Security Groups Configuration
# This file provisions granular security groups controlling traffic across:
#   1. EKS Control Plane
#   2. EKS Worker Nodes (Public & Private)
#   3. External Application Load Balancer (ALB)
# Standalone aws_security_group_rule resources are used to eliminate cyclic dependencies.
# =================================================================================================

# -------------------------------------------------------------------------------------------------
# 1. EKS Control Plane Security Group
# Protects the Kubernetes API Server and control plane components
# -------------------------------------------------------------------------------------------------
resource "aws_security_group" "cluster" {
  name        = "${var.project_name}-${var.environment}-cluster-sg"
  description = "Security group for EKS Control Plane (Kubernetes API server)"
  vpc_id      = aws_vpc.main.id

  tags = {
    Name                                        = "${var.project_name}-${var.environment}-cluster-sg"
    "kubernetes.io/cluster/${var.cluster_name}" = "owned"
  }
}

# Ingress: Allow Worker Nodes to communicate with Kubernetes API Server (HTTPS 443)
resource "aws_security_group_rule" "cluster_ingress_nodes" {
  description              = "Allow worker nodes to talk to API server on HTTPS 443"
  type                     = "ingress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.nodes.id
  security_group_id        = aws_security_group.cluster.id
}

# Egress: Allow Control plane to communicate with Worker Kubelets (Port 10250)
resource "aws_security_group_rule" "cluster_egress_kubelet" {
  description              = "Allow control plane to communicate with worker node kubelets"
  type                     = "egress"
  from_port                = 10250
  to_port                  = 10250
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.nodes.id
  security_group_id        = aws_security_group.cluster.id
}

# Egress: Allow Control plane to invoke admission webhooks on worker pods (Port 443)
resource "aws_security_group_rule" "cluster_egress_webhooks" {
  description              = "Allow control plane to invoke webhooks on worker nodes"
  type                     = "egress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.nodes.id
  security_group_id        = aws_security_group.cluster.id
}

# -------------------------------------------------------------------------------------------------
# 2. Worker Nodes Security Group
# Attached to both Public and Private EKS Node Groups
# -------------------------------------------------------------------------------------------------
resource "aws_security_group" "nodes" {
  name        = "${var.project_name}-${var.environment}-nodes-sg"
  description = "Security group for all worker nodes in the cluster"
  vpc_id      = aws_vpc.main.id

  tags = {
    Name                                        = "${var.project_name}-${var.environment}-nodes-sg"
    "kubernetes.io/cluster/${var.cluster_name}" = "owned"
  }
}

# Ingress: Intra-cluster node-to-node (Pod-to-Pod traffic across nodes, CoreDNS, CNI)
resource "aws_security_group_rule" "nodes_ingress_self" {
  description       = "Allow all inter-node and inter-pod communications within this security group"
  type              = "ingress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  self              = true
  security_group_id = aws_security_group.nodes.id
}

# Ingress: Control plane to Kubelet API
resource "aws_security_group_rule" "nodes_ingress_cluster_kubelet" {
  description              = "Allow control plane API to reach kubelet on port 10250"
  type                     = "ingress"
  from_port                = 10250
  to_port                  = 10250
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.cluster.id
  security_group_id        = aws_security_group.nodes.id
}

# Ingress: Control plane to admission controllers / webhooks
resource "aws_security_group_rule" "nodes_ingress_cluster_webhooks" {
  description              = "Allow control plane API to reach admission webhooks on port 443"
  type                     = "ingress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.cluster.id
  security_group_id        = aws_security_group.nodes.id
}

# Ingress: Allow traffic from Application Load Balancer to NodePort range (30000-32767)
resource "aws_security_group_rule" "nodes_ingress_alb_nodeports" {
  description              = "Allow ALB to forward HTTP/HTTPS traffic to NodePort range"
  type                     = "ingress"
  from_port                = 30000
  to_port                  = 32767
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.alb.id
  security_group_id        = aws_security_group.nodes.id
}

# Ingress: Allow traffic from ALB directly to microservice Pod ports (80-8083) for target-type ip
resource "aws_security_group_rule" "nodes_ingress_alb_pods" {
  description              = "Allow ALB to route traffic directly to pod ports"
  type                     = "ingress"
  from_port                = 80
  to_port                  = 8083
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.alb.id
  security_group_id        = aws_security_group.nodes.id
}

# Egress: Allow all outbound connectivity (ECR pulls, AWS APIs, SSM, internet via NAT)
resource "aws_security_group_rule" "nodes_egress_all" {
  description       = "Allow all outbound traffic from worker nodes"
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.nodes.id
}

# -------------------------------------------------------------------------------------------------
# 3. Application Load Balancer (ALB) Security Group
# Handles incoming public web traffic for BBHealthApp
# -------------------------------------------------------------------------------------------------
resource "aws_security_group" "alb" {
  name        = "${var.project_name}-${var.environment}-alb-sg"
  description = "Security group for external Application Load Balancer"
  vpc_id      = aws_vpc.main.id

  # Ingress: Public HTTP
  ingress {
    description = "Allow HTTP inbound from anywhere"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Ingress: Public HTTPS
  ingress {
    description = "Allow HTTPS inbound from anywhere"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-alb-sg"
  }
}

# ALB Egress: Forward to worker nodes NodePorts
resource "aws_security_group_rule" "alb_egress_nodes_nodeports" {
  description              = "Allow ALB traffic to worker nodes on NodePort range"
  type                     = "egress"
  from_port                = 30000
  to_port                  = 32767
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.nodes.id
  security_group_id        = aws_security_group.alb.id
}

# ALB Egress: Forward to worker nodes pod ports
resource "aws_security_group_rule" "alb_egress_nodes_pods" {
  description              = "Allow ALB traffic to worker node pod ports"
  type                     = "egress"
  from_port                = 80
  to_port                  = 8083
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.nodes.id
  security_group_id        = aws_security_group.alb.id
}
