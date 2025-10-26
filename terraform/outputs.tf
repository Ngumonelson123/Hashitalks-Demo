output "cluster_name" {
  value = module.eks.cluster_name
}

output "rds_endpoint" {
  value = aws_db_instance.rds.endpoint
  sensitive = true
}

output "vpc_id" {
  value = module.vpc.vpc_id
}

output "eks_console_url" {
  value = "https://${var.region}.console.aws.amazon.com/eks/home?region=${var.region}#/clusters/${module.eks.cluster_name}"
}

output "vault_ui_command" {
  value = "kubectl port-forward -n vault svc/vault-ui 8200:8200"
  description = "Command to access Vault UI at http://localhost:8200 (token: root)"
}

output "argocd_ui_command" {
  value = "kubectl port-forward -n argocd svc/argo-cd-argocd-server 8080:80"
  description = "Command to access ArgoCD UI at http://localhost:8080"
}

output "argocd_admin_password" {
  value = "kubectl get secret -n argocd argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d"
  description = "Command to get ArgoCD admin password"
}
