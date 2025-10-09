# -----------------------------
# VPC Module
# -----------------------------
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.1.1"

  name = "finops-vpc"
  cidr = "10.0.0.0/16"

  azs             = ["us-east-1a", "us-east-1b"]
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24"]
  public_subnets  = ["10.0.3.0/24", "10.0.4.0/24"]

  enable_nat_gateway = true
  single_nat_gateway = true

  tags = {
    Name = "finops-vpc"
  }
}

# -----------------------------
# EKS Cluster Module (Updated)
# -----------------------------
module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "21.3.2"

  cluster_name    = "finops-eks"
  cluster_version = "1.30"
  vpc_id          = module.vpc.vpc_id
  subnet_ids      = module.vpc.private_subnets

  enable_cluster_creator_admin_permissions = true
  cluster_endpoint_public_access           = true
  enable_irsa                              = true

  eks_managed_node_groups = {
    default = {
      desired_size = 2
      max_size     = 3
      min_size     = 1
      instance_types = ["t3.medium"]
    }
  }

  tags = {
    Environment = "demo"
    Project     = "FinOps-Kit"
  }
}

# -----------------------------
# EKS Cluster Authentication
# -----------------------------
data "aws_eks_cluster" "eks" {
  name = module.eks.cluster_name
}

data "aws_eks_cluster_auth" "eks" {
  name = module.eks.cluster_name
}

# -----------------------------
# Kubernetes & Helm Providers
# -----------------------------
provider "kubernetes" {
  host                   = data.aws_eks_cluster.eks.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.eks.certificate_authority[0].data)
  token                  = data.aws_eks_cluster_auth.eks.token
}

provider "helm" {
  kubernetes {
    host                   = data.aws_eks_cluster.eks.endpoint
    cluster_ca_certificate = base64decode(data.aws_eks_cluster.eks.certificate_authority[0].data)
    token                  = data.aws_eks_cluster_auth.eks.token
  }
}
