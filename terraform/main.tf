# SRE Desafio - Infraestrutura como Código
# Configuração robusta para alta disponibilidade

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.44.0"
    }
  }

  required_version = ">= 1.3.0"

  # Backend S3 comentado para desenvolvimento local
  # backend "s3" {
  #   bucket = "sre-desafio-terraform-state"
  #   key    = "terraform.tfstate"
  #   region = "us-east-1"
  # }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = "sre-desafio"
      Environment = "production"
      ManagedBy   = "terraform"
    }
  }
}

# VPC com alta disponibilidade
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.1.1"

  name = "${var.project_name}-vpc"
  cidr = var.vpc_cidr

  azs             = ["${var.aws_region}a", "${var.aws_region}b", "${var.aws_region}c"]
  public_subnets  = [for i, az in ["${var.aws_region}a", "${var.aws_region}b", "${var.aws_region}c"] : cidrsubnet(var.vpc_cidr, 8, i)]
  private_subnets = [for i, az in ["${var.aws_region}a", "${var.aws_region}b", "${var.aws_region}c"] : cidrsubnet(var.vpc_cidr, 8, i + 3)]

  enable_nat_gateway = true
  single_nat_gateway = true # Usar apenas 1 NAT Gateway para economizar EIPs

  enable_dns_hostnames = true
  enable_dns_support   = true

  # Security Groups
  enable_flow_log                      = var.enable_flow_logs
  create_flow_log_cloudwatch_log_group = var.enable_flow_logs
  create_flow_log_cloudwatch_iam_role  = var.enable_flow_logs

  tags = {
    Name = "${var.project_name}-vpc"
  }
}

# EKS Cluster com alta disponibilidade
module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "19.21.0"

  cluster_name    = "${var.project_name}-cluster"
  cluster_version = var.cluster_version

  subnet_ids = module.vpc.private_subnets
  vpc_id     = module.vpc.vpc_id

  # Alta disponibilidade
  cluster_endpoint_public_access       = true
  cluster_endpoint_public_access_cidrs = ["0.0.0.0/0"] # Para testes - em produção seria restrito

  enable_irsa = true

  # Node Groups com alta disponibilidade
  eks_managed_node_groups = {
    general = {
      desired_size = var.node_desired_size
      min_size     = var.node_min_size
      max_size     = var.node_max_size

      instance_types = var.node_instance_types
      capacity_type  = "ON_DEMAND"

      # Distribuição em múltiplas AZs
      subnet_ids = module.vpc.private_subnets

      # Configurações de segurança - removido enable_bootstrap_user_data para evitar conflito MIME
      bootstrap_extra_args = "--container-runtime containerd"

      # Tags para monitoramento
      labels = {
        Environment = var.environment
        NodeGroup   = "general"
      }

      # Configurações de auto-scaling
      update_config = {
        max_unavailable_percentage = 33
      }

      # Configurações de taints e tolerations (opcional)
      taints = []
    }
  }

  # Configurações de segurança
  cluster_security_group_additional_rules = {
    ingress_nodes_443 = {
      description                = "Node groups to cluster API"
      protocol                   = "tcp"
      from_port                  = 443
      to_port                    = 443
      type                       = "ingress"
      source_node_security_group = true
    }
  }

  tags = {
    Name = "${var.project_name}-cluster"
  }
}

# IAM Role para o cluster
resource "aws_iam_role_policy_attachment" "eks_cluster_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = module.eks.cluster_iam_role_name
}

# Outputs
output "cluster_name" {
  description = "Nome do cluster EKS"
  value       = module.eks.cluster_name
}

output "cluster_endpoint" {
  description = "Endpoint do cluster EKS"
  value       = module.eks.cluster_endpoint
}

output "cluster_certificate_authority_data" {
  description = "Certificate authority data do cluster"
  value       = module.eks.cluster_certificate_authority_data
}

output "vpc_id" {
  description = "ID da VPC"
  value       = module.vpc.vpc_id
}

output "private_subnets" {
  description = "IDs das subnets privadas"
  value       = module.vpc.private_subnets
}

output "public_subnets" {
  description = "IDs das subnets públicas"
  value       = module.vpc.public_subnets
}