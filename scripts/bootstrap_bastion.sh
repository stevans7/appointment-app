#!/usr/bin/env bash
set -euo pipefail

echo "Update system"
sudo apt update && sudo apt upgrade -y

echo "Install basic packages"
sudo apt install -y unzip curl git docker.io apt-transport-https ca-certificates gnupg lsb-release
sudo systemctl enable --now docker

echo "Add current user to docker group"
sudo usermod -aG docker $USER || true
echo "Note: You may need to log out and log back in for docker group changes to take effect."

echo "Install Terraform"
wget -O- https://apt.releases.hashicorp.com/gpg | gpg --dearmor | sudo tee /usr/share/keyrings/hashicorp.gpg >/dev/null
echo "deb [signed-by=/usr/share/keyrings/hashicorp.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
sudo apt update && sudo apt install -y terraform

echo "Install AWS CLI v2"
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "/tmp/awscliv2.zip"
cd /tmp
unzip awscliv2.zip
sudo ./aws/install || true
rm -rf /tmp/awscliv2.zip /tmp/aws

echo "Install kubectl"
sudo curl -o /usr/local/bin/kubectl https://amazon-eks.s3.eu-central-1.amazonaws.com/1.27.3/2023-07-05/bin/linux/amd64/kubectl
sudo chmod +x /usr/local/bin/kubectl

echo "Install Helm"
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

echo "Bootstrap complete"
