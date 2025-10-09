##########################################
# VPC Module
##########################################
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.1.1"
  name    = "finops-vpc"
  cidr    = "10.0.0.0/16"
  azs     = ["us-east-1a", "us-east-1b"]
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24"]
  public_subnets  = ["10.0.3.0/24", "10.0.4.0/24"]
  enable_nat_gateway = true
  single_nat_gateway = true
  tags = {
    Name = "finops-vpc"
  }
}

##########################################
# EKS Cluster Module (v21.3.2)
##########################################
module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "21.3.2"
  name    = "finops-eks"
  vpc_id  = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets
  cluster_version = "1.31"  # Specify an explicit Kubernetes version (e.g., 1.31, check AWS EKS supported versions)
  enable_irsa = true
  enable_cluster_creator_admin_permissions = true
  eks_managed_node_groups = {
    default = {
      desired_size   = 2
      min_size       = 1
      max_size       = 3
      instance_types = ["t3.medium"]
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
  name = module.eks.cluster_name
  depends_on = [module.eks]  # Ensure the cluster is created before fetching
}

data "aws_eks_cluster_auth" "eks" {
  name = module.eks.cluster_name
  depends_on = [module.eks]  # Ensure the cluster is created before fetching
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