output "cluster_name" {
  value = module.eks.cluster_name
}

output "rds_endpoint" {
  value = aws_db_instance.rds.endpoint
}

output "vpc_id" {
  value = module.vpc.vpc_id
}

output "eks_console_url" {
  value = "https://${var.region}.console.aws.amazon.com/eks/home?region=${var.region}#/clusters/${module.eks.cluster_name}"
}
