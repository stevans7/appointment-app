module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "19.0.0"

  cluster_name    = "devops-project-eks"
  cluster_version = "1.27"

  subnet_ids = [for s in aws_subnet.public[*].id : s]
  vpc_id     = aws_vpc.main.id

  # --- Active les logs du control plane ---
  cluster_enabled_log_types = [
    "api",
    "audit",
    "authenticator",
    "controllerManager",
    "scheduler"
  ]

  # --- Groupe de nœuds ---
  node_groups = {
    default = {
      desired_capacity = 2
      max_capacity     = 3
      min_capacity     = 1
      instance_types   = ["t3.medium"]
    }
  }

  tags = {
    Environment = "dev"
    Project     = "appointment-app"
  }
}