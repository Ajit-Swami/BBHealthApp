# =================================================================================================
# Subtask 4: AWS Elastic Container Registry (ECR) Setup
# Provides private container image registries for each BBHealthApp microservice
# =================================================================================================

resource "aws_ecr_repository" "services" {
  for_each             = toset(var.ecr_repositories)
  name                 = each.key
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  encryption_configuration {
    encryption_type = "AES256"
  }

  tags = {
    Name        = each.key
    Environment = var.environment
  }
}

# -------------------------------------------------------------------------------------------------
# Lifecycle Policy
# Retains only the last 10 images to optimize AWS storage costs
# -------------------------------------------------------------------------------------------------
resource "aws_ecr_lifecycle_policy" "services_policy" {
  for_each   = aws_ecr_repository.services
  repository = each.value.name

  policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Keep only the last 10 images"
        selection = {
          tagStatus   = "any"
          countType   = "imageCountMoreThan"
          countNumber = 10
        }
        action = {
          type = "expire"
        }
      }
    ]
  })
}
