terraform {
  cloud {
    organization = "Hashitalks-Africa-Demo"         # Your Terraform Cloud organization
    workspaces {
      name = "Hashitalks-Demo"          # Your TFC workspace name
    }
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.15.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.23"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.11"
    }
  }
}

provider "aws" {
  region = var.region
}
