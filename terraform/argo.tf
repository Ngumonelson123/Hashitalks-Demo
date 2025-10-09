###################################
# ArgoCD Installation via Helm
###################################

resource "helm_release" "argocd" {
  name       = "argo-cd"
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argo-cd"
  namespace  = "argocd"
  create_namespace = true

  # Make it easy to demo via HTTP (no ingress controller yet)
  values = [<<EOF
configs:
  params:
    server.insecure: true
server:
  service:
    type: LoadBalancer
EOF
  ]

  depends_on = [module.eks]
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

  depends_on = [helm_release.argocd]
}
