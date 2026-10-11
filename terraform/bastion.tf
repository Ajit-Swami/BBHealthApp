# =================================================================================================
# Bastion Host Configuration
# Optional jump host deployed in public subnet for troubleshooting and private resource access
# Disabled by default (enable_bastion = false) to prevent unnecessary charges
# =================================================================================================

# -------------------------------------------------------------------------------------------------
# Bastion Security Group
# -------------------------------------------------------------------------------------------------
resource "aws_security_group" "bastion" {
  count       = var.enable_bastion ? 1 : 0
  name        = "${var.project_name}-${var.environment}-bastion-sg"
  description = "Security group for Bastion jump host"
  vpc_id      = aws_vpc.main.id

  # Ingress SSH: Restrict to your IP or administrative CIDR block
  ingress {
    description = "SSH from allowed administrative networks"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Best practice: restrict to your specific public IP
  }

  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-bastion-sg"
  }
}

# -------------------------------------------------------------------------------------------------
# Bastion IAM Role (Enables AWS Systems Manager Session Manager access without open SSH ports)
# -------------------------------------------------------------------------------------------------
resource "aws_iam_role" "bastion" {
  count = var.enable_bastion ? 1 : 0
  name  = "${var.project_name}-${var.environment}-bastion-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect    = "Allow"
        Principal = { Service = "ec2.amazonaws.com" }
        Action    = "sts:AssumeRole"
      }
    ]
  })

  tags = {
    Name = "${var.project_name}-${var.environment}-bastion-role"
  }
}

resource "aws_iam_role_policy_attachment" "bastion_ssm" {
  count      = var.enable_bastion ? 1 : 0
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  role       = aws_iam_role.bastion[0].name
}

resource "aws_iam_instance_profile" "bastion" {
  count = var.enable_bastion ? 1 : 0
  name  = "${var.project_name}-${var.environment}-bastion-instance-profile"
  role  = aws_iam_role.bastion[0].name
}

# -------------------------------------------------------------------------------------------------
# Latest Amazon Linux 2 AMI
# -------------------------------------------------------------------------------------------------
data "aws_ami" "amazon_linux_2" {
  count       = var.enable_bastion ? 1 : 0
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

# -------------------------------------------------------------------------------------------------
# Bastion EC2 Instance (t3.micro Free Tier)
# -------------------------------------------------------------------------------------------------
resource "aws_instance" "bastion" {
  count                  = var.enable_bastion ? 1 : 0
  ami                    = data.aws_ami.amazon_linux_2[0].id
  instance_type          = "t3.micro"
  subnet_id              = aws_subnet.public[0].id
  vpc_security_group_ids = [aws_security_group.bastion[0].id]
  iam_instance_profile   = aws_iam_instance_profile.bastion[0].name

  tags = {
    Name = "${var.project_name}-${var.environment}-bastion"
  }
}
