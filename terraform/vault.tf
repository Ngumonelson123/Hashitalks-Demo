# ---------------------------------------
# Vault EC2 Server (Simple Demo)
# ---------------------------------------
resource "aws_security_group" "vault_sg" {
  name_prefix = "vault-sg"
  vpc_id      = module.vpc.vpc_id

  ingress {
    from_port   = 8200
    to_port     = 8200
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
    Name = "vault-sg"
  }
}

resource "aws_instance" "vault" {
  ami           = "ami-0c55b159cbfafe1f0" # Amazon Linux 2
  instance_type = "t3.small"
  subnet_id     = module.vpc.public_subnets[0]
  vpc_security_group_ids = [aws_security_group.vault_sg.id]
  key_name      = "hashitalks-key"

  user_data = <<-EOF
    #!/bin/bash
    yum install -y docker
    systemctl enable --now docker
    docker run --cap-add=IPC_LOCK -d --name vault \
      -e VAULT_DEV_ROOT_TOKEN_ID=root \
      -e VAULT_DEV_LISTEN_ADDRESS=0.0.0.0:8200 \
      -p 8200:8200 hashicorp/vault
  EOF

  tags = {
    Name = "Vault-Server"
  }
}

output "vault_public_ip" {
  value = aws_instance.vault.public_ip
}
