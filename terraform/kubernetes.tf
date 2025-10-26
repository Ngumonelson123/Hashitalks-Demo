# Deploy Kubernetes manifests via Terraform
resource "null_resource" "deploy_k8s" {
  provisioner "local-exec" {
    command = <<EOF
set -e
aws eks update-kubeconfig --region ${var.region} --name ${module.eks.cluster_name}
kubectl wait --for=condition=ready node --all --timeout=300s
kubectl apply -f ../k8s/ --validate=false
EOF
  }

  depends_on = [
    module.eks,
    helm_release.external_secrets,
    aws_db_instance.rds
  ]
}