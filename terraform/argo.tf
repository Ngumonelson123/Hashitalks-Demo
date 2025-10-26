# ArgoCD Installation via Helm
resource "helm_release" "argocd" {
  name       = "argo-cd"
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argo-cd"
  namespace  = "argocd"
  create_namespace = true
  version    = "7.6.7"  # Specify a recent chart version compatible with Kubernetes 1.31

  values = [<<EOF
server:
  service:
    type: LoadBalancer
  config:
    url: "https://argocd.${var.region}.elb.amazonaws.com"
EOF
  ]

  depends_on = [
    module.eks,
    data.aws_eks_cluster.eks,
    data.aws_eks_cluster_auth.eks
  ]
}

# Wait for EKS cluster to be ready
resource "null_resource" "wait_for_cluster" {
  depends_on = [
    module.eks,
    data.aws_eks_cluster.eks,
    data.aws_eks_cluster_auth.eks
  ]
}


# ArgoCD Application Definition
resource "null_resource" "finops_app" {
  provisioner "local-exec" {
    command = <<EOF
set -e
aws eks update-kubeconfig --region ${var.region} --name ${module.eks.cluster_name}
kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=argocd-server -n argocd --timeout=300s
kubectl apply -f - <<YAML
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: finops-app
  namespace: argocd
spec:
  project: default
  source:
    repoURL: https://github.com/your-username/Hashitalks-Demo.git
    targetRevision: main
    path: k8s
  destination:
    server: https://kubernetes.default.svc
    namespace: default
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
YAML
EOF
  }

  depends_on = [
    helm_release.argocd,
    null_resource.wait_for_cluster
  ]
}