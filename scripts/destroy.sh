#!/bin/bash

# Script de Destruição - SRE Desafio
# Este script remove toda a infraestrutura de forma limpa

set -e

# Configurações
PROJECT_NAME="sre-desafio"
AWS_REGION="us-east-1"
CLUSTER_NAME="${PROJECT_NAME}-cluster"

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Função para log
log() {
    echo -e "${BLUE}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# Confirmar destruição
confirm_destruction() {
    echo ""
    warning "ATENÇÃO: Este script irá DESTRUIR toda a infraestrutura do projeto!"
    echo ""
    echo "Isso inclui:"
    echo "  - Cluster EKS"
    echo "  - VPC e subnets"
    echo "  - Load Balancers"
    echo "  - Volumes EBS"
    echo "  - Security Groups"
    echo "  - Todos os recursos AWS criados"
    echo ""
    read -p "Tem certeza que deseja continuar? (digite 'DESTROY' para confirmar): " confirmation
    
    if [ "$confirmation" != "DESTROY" ]; then
        log "Operação cancelada pelo usuário"
        exit 0
    fi
    
    echo ""
    log "Confirmado. Iniciando destruição..."
}

# Verificar se o cluster existe
check_cluster_exists() {
    log "Verificando se o cluster existe..."
    
    if aws eks describe-cluster --name "$CLUSTER_NAME" --region "$AWS_REGION" &> /dev/null; then
        success "Cluster encontrado"
        return 0
    else
        warning "Cluster não encontrado. A infraestrutura pode já ter sido destruída."
        return 1
    fi
}

# Configurar kubectl se o cluster existir
configure_kubectl() {
    if check_cluster_exists; then
        log "Configurando kubectl para acessar o cluster..."
        aws eks update-kubeconfig --name "$CLUSTER_NAME" --region "$AWS_REGION"
        success "kubectl configurado"
    fi
}

# Remover aplicações Kubernetes
remove_k8s_applications() {
    log "Removendo aplicações Kubernetes..."
    
    # Remover WhoAmI
    if helm list -n default | grep -q whoami; then
        log "Removendo WhoAmI..."
        helm uninstall whoami -n default
        success "WhoAmI removido"
    fi
    
    # Remover ingress-nginx
    if helm list -n ingress-nginx | grep -q ingress-nginx; then
        log "Removendo ingress-nginx..."
        helm uninstall ingress-nginx -n ingress-nginx
        success "ingress-nginx removido"
    fi
    
    # Remover cert-manager
    if helm list -n cert-manager | grep -q cert-manager; then
        log "Removendo cert-manager..."
        helm uninstall cert-manager -n cert-manager
        success "cert-manager removido"
    fi
    
    # Remover namespaces
    log "Removendo namespaces..."
    kubectl delete namespace ingress-nginx --ignore-not-found=true
    kubectl delete namespace cert-manager --ignore-not-found=true
    
    success "Aplicações Kubernetes removidas"
}

# Aguardar recursos serem removidos
wait_for_cleanup() {
    log "Aguardando recursos serem removidos..."
    
    # Aguardar Load Balancers serem removidos
    log "Aguardando Load Balancers..."
    sleep 30
    
    # Aguardar volumes EBS serem desanexados
    log "Aguardando volumes EBS..."
    sleep 30
    
    success "Tempo de espera concluído"
}

# Remover infraestrutura Terraform
remove_infrastructure() {
    log "Removendo infraestrutura Terraform..."
    
    cd terraform
    
    # Verificar se o Terraform está inicializado
    if [ ! -d ".terraform" ]; then
        log "Inicializando Terraform..."
        terraform init
    fi
    
    # Destruir infraestrutura
    log "Destruindo infraestrutura..."
    terraform destroy -auto-approve
    
    cd ..
    
    success "Infraestrutura Terraform removida"
}

# Verificar se tudo foi removido
verify_cleanup() {
    log "Verificando se tudo foi removido..."
    
    # Verificar se o cluster ainda existe
    if aws eks describe-cluster --name "$CLUSTER_NAME" --region "$AWS_REGION" &> /dev/null; then
        warning "Cluster ainda existe. Pode ser necessário aguardar mais tempo."
        return 1
    else
        success "Cluster removido com sucesso"
    fi
    
    return 0
}

# Função principal
main() {
    log "Iniciando destruição completa do SRE Desafio"
    
    # Confirmar destruição
    confirm_destruction
    
    # Configurar kubectl se possível
    configure_kubectl
    
    # Remover aplicações Kubernetes
    remove_k8s_applications
    
    # Aguardar limpeza
    wait_for_cleanup
    
    # Remover infraestrutura Terraform
    remove_infrastructure
    
    # Verificar limpeza
    if verify_cleanup; then
        success "Destruição completa realizada com sucesso!"
        log "Todos os recursos foram removidos."
    else
        warning "Alguns recursos podem ainda existir. Verifique manualmente."
    fi
}

# Executar função principal
main "$@"