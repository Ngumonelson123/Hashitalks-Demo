# Import existing resources to avoid recreation
# Run these commands if resources already exist:

# terraform import module.vpc.aws_vpc.this vpc-xxxxxxxxx
# terraform import module.eks.aws_eks_cluster.this finops-eks
# terraform import aws_db_instance.rds finops-postgres

# Fix duplicate security group rule error:
# terraform import 'module.eks.aws_security_group_rule.node["ingress_cluster_api"]' sg-09743df2d502a6abb_ingress_tcp_443_443_sg-0303c62a8e8d61731

# Alternative: Remove the rule from AWS Console and let Terraform recreate it
# Or use terraform state rm to remove from state:
# terraform state rm 'module.eks.aws_security_group_rule.node["ingress_cluster_api"]'

# Lifecycle rules to prevent accidental deletion
resource "null_resource" "import_helper" {
  lifecycle {
    create_before_destroy = true
  }
}