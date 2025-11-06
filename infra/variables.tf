variable "region" {
  description = "AWS region"
  type        = string
  default     = "eu-central-1"
}

variable "bastion_ami" {
  description = "AMI ID pour l'instance bastion (Ubuntu 22.04 LTS ou Amazon Linux 2)"
  type        = string
  default     = "ami-0a0ad6b70e61be944"  # Exemple pour eu-central-1 Amazon Linux 2, vérifie l'AMI actuelle
}

variable "my_ip_cidr" {
  description = "Ton IP publique en CIDR pour autoriser l'accès SSH (ex: 1.2.3.4/32)"
  type        = string
  default     = "1.2.3.4/32"  # Remplace par ton IP réelle ou configure via terraform.tfvars
}
