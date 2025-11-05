# --- Security Group pour le Control Plane ---
resource "aws_security_group" "eks_control_plane" {
  name        = "eks-control-plane-sg"
  description = "Security group for EKS control plane"
  vpc_id      = aws_vpc.main.id

  # ✅ Autoriser la communication sortante vers Internet
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "eks-control-plane-sg"
  }
}

# --- Security Group pour les Nodes EKS ---
resource "aws_security_group" "eks_nodes" {
  name        = "eks-nodes-sg"
  description = "Security group for EKS worker nodes"
  vpc_id      = aws_vpc.main.id

  # ✅ Autoriser les nœuds à sortir sur Internet
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # ✅ Autoriser les connexions entrantes depuis le control plane
  ingress {
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    security_groups = [aws_security_group.eks_control_plane.id]
    description     = "Allow control plane to reach nodes"
  }

  # ✅ Communication interne entre nœuds
  ingress {
    description = "Allow node-to-node communication"
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    self        = true
  }

  tags = {
    Name = "eks-nodes-sg"
  }
}

# --- IAM Role pour les nœuds EKS ---
resource "aws_iam_role" "eks_node_group_role" {
  name = "eks_node_group_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })
}

# --- Attache les 3 policies nécessaires ---
resource "aws_iam_role_policy_attachment" "eks_worker_node_policy" {
  role       = aws_iam_role.eks_node_group_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
}

resource "aws_iam_role_policy_attachment" "eks_cni_policy" {
  role       = aws_iam_role.eks_node_group_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
}

resource "aws_iam_role_policy_attachment" "eks_registry_policy" {
  role       = aws_iam_role.eks_node_group_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

# --- Module EKS ---
module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "20.24.3"

  cluster_name    = "devops-project-eks"
  # ✅ Utiliser une version stable
  cluster_version = "1.30"

  vpc_id     = aws_vpc.main.id
  subnet_ids = aws_subnet.public[*].id  # ✅ Public subnets = accès Internet OK

  cluster_enabled_log_types = [
    "api",
    "audit",
    "authenticator",
    "controllerManager",
    "scheduler"
  ]

  # ✅ Autoriser communication entre nœuds et control plane
  cluster_security_group_additional_rules = {
    ingress_nodes_443 = {
      description                = "Allow worker nodes to communicate with control plane"
      protocol                   = "tcp"
      from_port                  = 443
      to_port                    = 443
      type                       = "ingress"
      source_node_security_group = true
    }
  }

  create_node_security_group = false
  node_security_group_id     = aws_security_group.eks_nodes.id

  eks_managed_node_groups = {
    default = {
      desired_size   = 2
      max_size       = 3
      min_size       = 1
      instance_types = ["t3.medium"]
      iam_role_arn   = aws_iam_role.eks_node_group_role.arn
    }
  }

  tags = {
    Environment = "dev"
    Project     = "appointment-app"
  }
}
