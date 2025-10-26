
# VPC Module
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


# EKS Cluster Module (v21.3.2)
module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "21.3.2"
  name    = "finops-eks"
  vpc_id  = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets
  kubernetes_version = "1.30"  # Use stable supported version
  enable_irsa = true
  enable_cluster_creator_admin_permissions = true
  
  # Attach additional security group to nodes
  node_security_group_additional_rules = {
    ingress_self_all = {
      description = "Node to node all ports/protocols"
      protocol    = "-1"
      from_port   = 0
      to_port     = 0
      type        = "ingress"
      self        = true
    }
  }
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

# Security Group for RDS access from EKS
resource "aws_security_group" "rds_sg" {
  name_prefix = "finops-rds-"
  vpc_id      = module.vpc.vpc_id

  ingress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [module.eks.node_security_group_id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "finops-rds-sg"
  }
}

# Security Group for LoadBalancer services
resource "aws_security_group" "app_lb_sg" {
  name_prefix = "finops-app-lb-"
  vpc_id      = module.vpc.vpc_id

  # HTTP access for API Gateway
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # HTTPS access for API Gateway
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Vault UI access
  ingress {
    from_port   = 8200
    to_port     = 8200
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # ArgoCD UI access
  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "finops-app-lb-sg"
  }
}

