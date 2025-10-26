# HashiCorp Vault deployment
resource "helm_release" "vault" {
  name       = "vault"
  repository = "https://helm.releases.hashicorp.com"
  chart      = "vault"
  namespace  = "vault"
  create_namespace = true
  version    = "0.28.1"

  values = [<<EOF
server:
  dev:
    enabled: true
    devRootToken: "root"
  dataStorage:
    enabled: false
  ha:
    enabled: false
  service:
    enabled: true
ui:
  enabled: true
  serviceType: "LoadBalancer"
injector:
  enabled: true
EOF
  ]

  depends_on = [module.eks]
}

# Vault configuration via Kubernetes manifests (more reliable)
resource "kubernetes_config_map" "vault_config" {
  metadata {
    name      = "vault-init-script"
    namespace = "vault"
  }
  
  data = {
    "init.sh" = <<EOF
#!/bin/sh
export VAULT_ADDR=http://vault:8200
export VAULT_TOKEN=root

# Wait for Vault to be ready
until vault status; do
  echo "Waiting for Vault..."
  sleep 5
done

# Enable KV secrets engine
vault secrets enable -path=secret kv-v2 || true

# Store database credentials
vault kv put secret/database \
  username="${var.db_user}" \
  password="${var.db_password}" \
  host="${aws_db_instance.rds.endpoint}" \
  database="${var.db_name}"

echo "Vault initialization complete"
EOF
  }
  
  depends_on = [helm_release.vault]
}

# Job to initialize Vault with secrets
resource "kubernetes_job_v1" "vault_init" {
  metadata {
    name      = "vault-init"
    namespace = "vault"
  }
  
  spec {
    template {
      metadata {}
      spec {
        restart_policy = "OnFailure"
        container {
          name  = "vault-init"
          image = "hashicorp/vault:1.15.2"
          command = ["/bin/sh", "/scripts/init.sh"]
          
          volume_mount {
            name       = "init-script"
            mount_path = "/scripts"
          }
        }
        
        volume {
          name = "init-script"
          config_map {
            name         = kubernetes_config_map.vault_config.metadata[0].name
            default_mode = "0755"
          }
        }
      }
    }
  }
  
  depends_on = [kubernetes_config_map.vault_config, aws_db_instance.rds]
  
  wait_for_completion = true
  timeouts {
    create = "5m"
    update = "5m"
  }
}