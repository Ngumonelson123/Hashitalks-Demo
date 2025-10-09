###################################
# ArgoCD Installation via Helm
###################################
resource "helm_release" "argocd" {
  name       = "argo-cd"
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argo-cd"
  namespace  = "argocd"
  create_namespace = true
  version    = "7.6.7"  # Specify a recent chart version compatible with Kubernetes 1.31

  values = [<<EOF
configs:
  params:
    server.insecure: true
server:
  service:
    type: LoadBalancer
EOF
  ]

  depends_on = [
    module.eks,
    data.aws_eks_cluster.eks,
    data.aws_eks_cluster_auth.eks
  ]
}

###################################
# Wait for EKS cluster to be ready
###################################
resource "null_resource" "wait_for_cluster" {
  depends_on = [
    module.eks,
    data.aws_eks_cluster.eks,
    data.aws_eks_cluster_auth.eks
  ]
}

###################################
# ArgoCD Application Definition
###################################
resource "kubernetes_manifest" "finops_app" {
  manifest = {
    apiVersion = "argoproj.io/v1alpha1"
    kind       = "Application"
    metadata = {
      name      = "finops-app"
      namespace = "argocd"
    }
    spec = {
      project = "default"
      source = {
        repoURL        = "https://github.com/Ngumonelson123/finops-kit.git"
        targetRevision = "main"
        path           = "k8s"
      }
      destination = {
        server    = "https://kubernetes.default.svc"
        namespace = "default"
      }
      syncPolicy = {
        automated = {
          prune    = true
          selfHeal = true
        }
      }
    }
  }

  depends_on = [
    helm_release.argocd,
    null_resource.wait_for_cluster
  ]
}