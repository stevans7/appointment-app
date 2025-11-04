resource "aws_ecr_repository" "appointment_app" {
  name                 = "appointment-app"
  image_tag_mutability = "IMMUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  encryption_configuration {
    encryption_type = "KMS"
    kms_key         = aws_kms_key.ecr_key.arn
  }

  tags = {
    Name        = "appointment-app-ecr"
    Environment = "dev"
  }
}
