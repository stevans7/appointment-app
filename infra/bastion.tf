# Génération dynamique de la clé SSH bastion (4096 bits RSA)
resource "tls_private_key" "bastion_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

# Création de la paire de clés AWS avec la clé publique générée
resource "aws_key_pair" "bastion_key_pair" {
  key_name   = "bastion_key"
  public_key = tls_private_key.bastion_key.public_key_openssh
  tags = {
    Name        = "bastion-key-pair"
    Environment = "dev"
  }
}

# Groupe de sécurité dédié au bastion : 
# - autorise uniquement SSH (port 22) en entrée depuis ton IP locale (modifie selon besoin)
# - autorise uniquement l’egress vers ton VPC ou plage IP spécifique pour limiter l’exposition
resource "aws_security_group" "bastion_sg" {
  name        = "bastion-sg"
  description = "Allow SSH from trusted IP(s) only"
  vpc_id      = aws_vpc.main.id

  ingress {
    description      = "SSH from trusted IP"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["x.x.x.x/32"]  # <-- Remplace ici par ton IP publique / bloc CIDR de confiance
  }

  egress {
    description = "Allow egress only to VPC"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["10.0.0.0/16"]  # <-- Remplace par ta plage VPC interne / sous-réseau sécurisé
  }

  tags = {
    Name        = "bastion-sg"
    Environment = "dev"
  }
}

# Instance EC2 bastion dans un subnet public (mais sans IP publique auto)
resource "aws_instance" "bastion" {
  ami                    = var.bastion_ami_id  # Définir dans variables.tf la bonne AMI Amazon Linux 2 ou autre
  instance_type          = "t3.micro"
  subnet_id              = aws_subnet.public[0].id
  key_name               = aws_key_pair.bastion_key_pair.key_name
  vpc_security_group_ids = [aws_security_group.bastion_sg.id]

  # Important : associer une IP publique car map_public_ip_on_launch = false dans subnet
  associate_public_ip_address = true

  # Sécurité : forcer IMDS token
  metadata_options {
    http_tokens = "required"
  }

  # Chiffrement du volume racine
  root_block_device {
    encrypted = true
  }

  tags = {
    Name        = "bastion"
    Environment = "dev"
  }
}

# Output sensible contenant la clé privée SSH (ne pas versionner ce fichier, la récupérer avec terraform output)
output "bastion_private_key_pem" {
  description = "Private key for bastion SSH access"
  value       = tls_private_key.bastion_key.private_key_pem
  sensitive   = true
}

# Output IP publique pour se connecter facilement
output "bastion_public_ip" {
  description = "Public IP of the bastion host"
  value       = aws_instance.bastion.public_ip
}
