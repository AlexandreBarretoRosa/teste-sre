# Variáveis para o projeto SRE Desafio

variable "aws_region" {
  description = "Região AWS para deploy"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Nome do projeto"
  type        = string
  default     = "sre-desafio"
}

variable "vpc_cidr" {
  description = "CIDR da VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "environment" {
  description = "Ambiente de deploy"
  type        = string
  default     = "production"
}

variable "cluster_version" {
  description = "Versão do Kubernetes"
  type        = string
  default     = "1.29"
}

variable "node_instance_types" {
  description = "Tipos de instância para os nodes"
  type        = list(string)
  default     = ["t3.medium"]
}

variable "node_desired_size" {
  description = "Número desejado de nodes"
  type        = number
  default     = 2
}

variable "node_min_size" {
  description = "Número mínimo de nodes"
  type        = number
  default     = 2
}

variable "node_max_size" {
  description = "Número máximo de nodes"
  type        = number
  default     = 6
}

variable "enable_multi_az" {
  description = "Habilitar múltiplas zonas de disponibilidade"
  type        = bool
  default     = true
}

variable "enable_auto_scaling" {
  description = "Habilitar auto-scaling dos node groups"
  type        = bool
  default     = true
}

variable "enable_flow_logs" {
  description = "Habilitar flow logs da VPC"
  type        = bool
  default     = true
}

variable "enable_vpc_endpoints" {
  description = "Habilitar VPC endpoints para serviços AWS"
  type        = bool
  default     = false
}