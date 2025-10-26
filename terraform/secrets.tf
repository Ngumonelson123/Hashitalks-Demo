# Vault Secret Store for External Secrets Operator
resource "kubernetes_manifest" "vault_secret_store" {
  manifest = {
    apiVersion = "external-secrets.io/v1beta1"
    kind       = "SecretStore"
    metadata = {
      name      = "vault-backend"
      namespace = "default"
    }
    spec = {
      provider = {
        vault = {
          server = "http://vault.vault.svc.cluster.local:8200"
          path   = "secret"
          version = "v2"
          auth = {
            tokenSecretRef = {
              name = "vault-token"
              key  = "token"
            }
          }
        }
      }
    }
  }
  depends_on = [helm_release.external_secrets, helm_release.vault]
}

# Vault token secret for External Secrets
resource "kubernetes_secret" "vault_token" {
  metadata {
    name      = "vault-token"
    namespace = "default"
  }
  data = {
    token = "root"
  }
  depends_on = [module.eks]
}

# IAM role for External Secrets Operator
resource "aws_iam_role" "external_secrets" {
  name = "external-secrets-role"
  
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRoleWithWebIdentity"
        Effect = "Allow"
        Principal = {
          Federated = module.eks.oidc_provider_arn
        }
        Condition = {
          StringEquals = {
            "${replace(module.eks.cluster_oidc_issuer_url, "https://", "")}:sub" = "system:serviceaccount:external-secrets:external-secrets"
            "${replace(module.eks.cluster_oidc_issuer_url, "https://", "")}:aud" = "sts.amazonaws.com"
          }
        }
      }
    ]
  })
}

resource "aws_iam_role_policy" "external_secrets" {
  name = "external-secrets-policy"
  role = aws_iam_role.external_secrets.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret"
        ]
        Resource = "*"
      }
    ]
  })
}

# External Secrets Operator installation
resource "helm_release" "external_secrets" {
  name       = "external-secrets"
  repository = "https://charts.external-secrets.io"
  chart      = "external-secrets"
  namespace  = "external-secrets"
  create_namespace = true

  set {
    name  = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
    value = aws_iam_role.external_secrets.arn
  }

  depends_on = [module.eks]
}