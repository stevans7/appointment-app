# Permet d'obtenir l'account ID pour la policy KMS
data "aws_caller_identity" "current" {}

# --- KMS key pour ECR ---
resource "aws_kms_key" "ecr_key" {
  description             = "KMS key for encrypting ECR repository images"
  enable_key_rotation     = true
  deletion_window_in_days = 10

  tags = {
    Name        = "ecr-kms-key"
    Environment = "dev"
  }
}

resource "aws_kms_alias" "ecr_key_alias" {
  name          = "alias/ecr-kms-key"
  target_key_id = aws_kms_key.ecr_key.id
}

# --- KMS key pour CloudWatch Logs ---
resource "aws_kms_key" "cloudwatch_logs_key_root" {
  description             = "KMS key for encrypting CloudWatch Log Groups (VPC Flow Logs)"
  enable_key_rotation     = true
  deletion_window_in_days = 10

  tags = {
    Name        = "cloudwatch-logs-kms-key"
    Environment = "dev"
  }
}

resource "aws_kms_alias" "cloudwatch_logs_key_alias" {
  name          = "alias/cloudwatch-logs-kms-key"
  target_key_id = aws_kms_key.cloudwatch_logs_key_root.id
}

# --- KMS key policy ---
resource "aws_kms_key_policy" "cloudwatch_logs_key_policy" {
  key_id = aws_kms_key.cloudwatch_logs_key_root.id

  policy = jsonencode({
    Version = "2012-10-17"
    Id      = "cloudwatch-logs-key-policy"
    Statement = [
      {
        Sid    = "AllowRootAccountFullControl"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }
        Action   = "kms:*"
        Resource = "*"
      },
      {
        Sid    = "AllowCloudWatchLogsToUseKey"
        Effect = "Allow"
        Principal = {
          Service = "logs.${var.region}.amazonaws.com"
        }
        Action = [
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:ReEncrypt*",
          "kms:GenerateDataKey*",
          "kms:DescribeKey"
        ]
        Resource = "*"
      }
    ]
  })
}