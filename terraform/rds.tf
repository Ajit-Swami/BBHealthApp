# =================================================================================================
# Database Configuration (RDS)
# Optional managed PostgreSQL instance for BBHealthApp production database
# Disabled by default (enable_rds = false) to prevent unnecessary charges
# =================================================================================================

# -------------------------------------------------------------------------------------------------
# RDS Subnet Group (Private Subnets Only)
# -------------------------------------------------------------------------------------------------
resource "aws_db_subnet_group" "rds" {
  count       = var.enable_rds ? 1 : 0
  name        = "${var.project_name}-${var.environment}-rds-subnet-group"
  subnet_ids  = aws_subnet.private[*].id
  description = "Subnet group for BBHealthApp RDS database placed in private subnets"

  tags = {
    Name = "${var.project_name}-${var.environment}-rds-subnet-group"
  }
}

# -------------------------------------------------------------------------------------------------
# RDS Security Group
# Restricts database access strictly to EKS worker nodes on PostgreSQL port 5432
# -------------------------------------------------------------------------------------------------
resource "aws_security_group" "rds" {
  count       = var.enable_rds ? 1 : 0
  name        = "${var.project_name}-${var.environment}-rds-sg"
  description = "Security group for BBHealthApp RDS database"
  vpc_id      = aws_vpc.main.id

  ingress {
    description     = "Allow PostgreSQL access from EKS worker nodes"
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.nodes.id]
  }

  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-rds-sg"
  }
}

# -------------------------------------------------------------------------------------------------
# Managed RDS PostgreSQL Instance (Free Tier Eligible db.t3.micro)
# -------------------------------------------------------------------------------------------------
resource "aws_db_instance" "postgres" {
  count                  = var.enable_rds ? 1 : 0
  identifier             = "${var.project_name}-${var.environment}-db"
  allocated_storage      = 20
  max_allocated_storage  = 50
  engine                 = "postgres"
  engine_version         = "15.7"
  instance_class         = "db.t3.micro"
  db_name                = "binarybrainscovid"
  username               = "bbhealth"
  password               = "ChangeMeSecurePassword123!" # Override via TF_VAR_db_password or Secrets Manager
  db_subnet_group_name   = aws_db_subnet_group.rds[0].name
  vpc_security_group_ids = [aws_security_group.rds[0].id]
  skip_final_snapshot    = true
  publicly_accessible    = false
  deletion_protection    = false

  tags = {
    Name = "${var.project_name}-${var.environment}-postgres"
  }
}
