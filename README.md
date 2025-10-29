# 🚀 Projet DevOps — Appointment App (Prise de rendez-vous)

## 🎯 Objectif
Projet complet DevOps pour la soutenance : une application web permettant de **prendre un rendez-vous** (Nom, Prénom, Motif, Date) puis d'**envoyer un email** contenant les informations au destinataire configuré. 
Le projet inclut :
- Infrastructure as Code (Terraform) pour AWS (EKS, ECR)
- Application conteneurisée (Docker)
- Déploiement Kubernetes via Helm
- CI/CD via GitHub Actions (build, push, deploy)
- Scripts d'installation pour bastion et création backend Terraform
- READMEs pour reproduction et soutenance

⚠️ Remplace les placeholders (`<...>`) dans les fichiers par tes valeurs réelles (AWS_ACCOUNT_ID, TF_STATE_BUCKET, etc.) avant d'exécuter infra.

## Structure
```
devops-project-appointment/
├── README.md
├── README-soutenance.md
├── infra/
│   ├── provider.tf
│   ├── variables.tf
│   ├── vpc.tf
│   ├── eks.tf
│   ├── ecr.tf
│   ├── outputs.tf
│
├── app/
│   ├── Dockerfile
│   ├── index.js
│   ├── package.json
│   └── public/
│       └── index.html
│
├── charts/
│   └── appointment-app/
│       ├── Chart.yaml
│       ├── values.yaml
│       └── templates/
│           ├── deployment.yaml
│           ├── service.yaml
│           ├── ingress.yaml
│           └── secret.yaml
│
├── .github/workflows/ci-cd.yml
├── scripts/bootstrap_bastion.sh
└── scripts/create_tf_backend.sh
```

## Installation rapide (résumé)
1. Lancer une VM bastion Ubuntu 22.04 et SSH.
2. Copier le repo sur le bastion.
3. `sudo bash scripts/bootstrap_bastion.sh`
4. `aws configure` (ou set env vars)
5. `bash scripts/create_tf_backend.sh <bucket-name> eu-central-1 <dynamo-table>`
6. Editer `infra/provider.tf` backend placeholders si besoin.
7. `cd infra && terraform init && terraform plan -out plan.out && terraform apply plan.out`
8. `aws eks update-kubeconfig --region eu-central-1 --name devops-project-eks`
9. Build & push image (or use GitHub Actions). Set GitHub secrets: `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`, `AWS_ACCOUNT_ID`, `AWS_REGION`, `EKS_CLUSTER_NAME`, `MAIL_USER`, `MAIL_PASS`, `MAIL_TO`.
10. Deploy with Helm (Helm will create k8s secret from values.mail.*):
   `helm upgrade --install appointment-app charts/appointment-app --namespace production --create-namespace --set image.repository=<AWS_ACCOUNT_ID>.dkr.ecr.<AWS_REGION>.amazonaws.com/appointment-app --set image.tag=<TAG> --set mail.user=<email> --set mail.pass=<app_password> --set mail.to=<your_email>`
11. Port-forward or check LoadBalancer IP and test the form.

## Tests rapides (commande à exécuter devant jury)
```bash
kubectl get nodes -o wide
kubectl get pods -n production
kubectl port-forward svc/appointment-app 3000:80 -n production &
curl http://localhost:3000/            # should return index html content
curl http://localhost:3000/health      # {"status":"UP"}
curl -X POST http://localhost:3000/api/appointment -H "Content-Type: application/json" -d '{"nom":"Dupont","prenom":"Marie","motif":"Admission","date":"2025-10-02"}'
```
