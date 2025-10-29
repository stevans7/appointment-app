output "cluster_name" {
  value = module.eks.cluster_name
}

output "cluster_endpoint" {
  value = module.eks.cluster_endpoint
}

output "ecr_url" {
  value = aws_ecr_repository.appointment_app.repository_url
}
