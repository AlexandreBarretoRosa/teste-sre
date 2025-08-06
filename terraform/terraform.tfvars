# Configuração de Produção - SRE Desafio
# Este arquivo contém as configurações específicas do ambiente

# Configurações da AWS
aws_region   = "us-east-1"
project_name = "sre-desafio"
environment  = "production"

# Configurações de Rede
vpc_cidr = "10.0.0.0/16"

# Configurações do Cluster EKS
cluster_version = "1.29"

# Configurações dos Node Groups
node_instance_types = ["t3.medium"]
node_desired_size   = 2
node_min_size       = 2
node_max_size       = 6

# Configurações de Alta Disponibilidade
enable_multi_az     = true
enable_auto_scaling = true

# Configurações de Segurança
enable_flow_logs     = true
enable_vpc_endpoints = false # Para reduzir custos em desenvolvimento