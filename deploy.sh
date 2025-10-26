#!/bin/bash
set -e

echo "🚀 Deploying HashiTalks Demo Infrastructure..."

# Check prerequisites
command -v terraform >/dev/null 2>&1 || { echo "❌ Terraform not found. Please install Terraform."; exit 1; }
command -v aws >/dev/null 2>&1 || { echo "❌ AWS CLI not found. Please install AWS CLI."; exit 1; }
command -v kubectl >/dev/null 2>&1 || { echo "❌ kubectl not found. Please install kubectl."; exit 1; }

# Check if terraform.tfvars exists
if [ ! -f "terraform/terraform.tfvars" ]; then
    echo "📝 Creating terraform.tfvars from example..."
    cp terraform/terraform.tfvars.example terraform/terraform.tfvars
    echo "⚠️  Please edit terraform/terraform.tfvars with your values before continuing."
    echo "Press Enter when ready..."
    read
fi

cd terraform

echo "🔧 Initializing Terraform..."
terraform init

echo "📋 Planning deployment..."
terraform plan

echo "🚀 Applying Terraform configuration..."
terraform apply -auto-approve

echo "✅ Deployment complete!"
echo ""
echo "📊 Access Information:"
echo "- EKS Cluster: $(terraform output -raw cluster_name)"
echo "- Vault UI: $(terraform output -raw vault_ui_command)"
echo "- ArgoCD: kubectl get svc -n argocd argo-cd-argocd-server"
echo ""
echo "🔐 Vault Login Token: root"