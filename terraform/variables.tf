variable "region" {
  description = "AWS region to deploy resources in"
  type        = string
  default     = "us-east-1"
}



variable "db_password" {
  description = "Database password for RDS"
  type        = string
  sensitive   = true
}

variable "db_name" {
  description = "Database name for the financial system"
  type        = string
  default     = "finopsdb"
}

variable "db_user" {
  description = "Database user for RDS"
  type        = string
  default     = "finadmin"
}
