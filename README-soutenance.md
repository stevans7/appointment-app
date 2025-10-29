# 🎤 Script Soutenance — Appointment App

## Plan (10-12 minutes)
1. Intro (30s): objectif du projet (prise de RDV + envoi d'email) et compétences démontrées (IaC, CI/CD, K8s, secrets, monitoring).
2. Infra (2 min): montrer `infra/` Terraform, backend S3 + dynamodb, expliquer décisions (remote state, locking).
3. Déploiement (2 min): montrer Helm chart, secrets pour SMTP, configmap/values, déployer release.
4. CI/CD (1.5 min): montrer workflow GitHub Actions (build, push, deploy) et logs d'une exécution réussie.
5. App (2 min): démonstration live: port-forward & ouvrir la page, remplir formulaire, envoyer → montrer mail reçu.
6. Monitoring & health (1 min): `/health`, `/metrics`.
7. Sécurité (1 min): tfsec, Trivy (scan d'image), usage de secrets k8s.
8. Conclusion (30s): points forts et évolutions possibles.

## Commandes clefs à exécuter pendant la soutenance
- `terraform init && terraform apply`
- `kubectl get nodes -A`
- `helm upgrade --install appointment-app charts/appointment-app -n production`
- `kubectl port-forward svc/appointment-app 3000:80 -n production &`
- `curl http://localhost:3000/health`
- `curl -X POST http://localhost:3000/api/appointment -H "Content-Type: application/json" -d '{"nom":"X","prenom":"Y","motif":"Z","date":"2025-10-02"}'`
