# AWS Secrets Manager secret
resource "aws_secretsmanager_secret" "finops_database" {
  name = "finops/database"
}

resource "aws_secretsmanager_secret_version" "finops_database" {
  secret_id = aws_secretsmanager_secret.finops_database.id
  secret_string = jsonencode({
    host     = aws_db_instance.rds.endpoint
    username = var.db_user
    password = var.db_password
  })
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
        Resource = aws_secretsmanager_secret.finops_database.arn
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