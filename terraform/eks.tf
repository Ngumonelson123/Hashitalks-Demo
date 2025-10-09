##########################################
# VPC Module
##########################################
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

##########################################
# EKS Cluster Module (v22+ syntax)
##########################################
module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = ">=22.0.0"

  cluster_name = "finops-eks" # legacy alias (optional)
  
  cluster = {
    name                   = "finops-eks"
    version                = "1.30"
    endpoint_public_access = true
  }

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

  enable_cluster_creator_admin_permissions = true
  enable_irsa                              = true

  eks_managed_node_groups = {
    default = {
      instance_types = ["t3.medium"]
      min_size       = 1
      desired_size   = 2
      max_size       = 3
    }
  }

  tags = {
    Environment = "demo"
    Project     = "FinOps-Kit"
  }
}

##########################################
# EKS Cluster Authentication
##########################################
data "aws_eks_cluster" "eks" {
  name = module.eks.cluster.cluster_name
}

data "aws_eks_cluster_auth" "eks" {
  name = module.eks.cluster.cluster_name
}

##########################################
# Kubernetes & Helm Providers
##########################################
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
