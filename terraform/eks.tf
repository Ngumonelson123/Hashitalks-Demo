##########################################
# VPC Module
##########################################
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.1.1"
  name    = "finops-vpc"
  cidr    = "10.0.0.0/16"
  azs     = ["${var.region}a", "${var.region}b"]  # Use var.region for consistency
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
  kubernetes_version = "1.31"  # Ensure this is a supported version in the region
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

