#!/bin/bash

# Script para configurar e verificar a observabilidade - SRE Desafio
# Este script garante que todos os componentes de monitoramento estejam funcionando

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
CYAN='\033[0;36m'
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

info() {
    echo -e "${CYAN}[INFO]${NC} $1"
}

# Verificar se kubectl está configurado
check_kubectl() {
    log "Verificando configuração do kubectl..."
    
    if ! kubectl get nodes &> /dev/null; then
        error "kubectl não está configurado ou não consegue acessar o cluster"
        info "Configurando kubectl para o cluster EKS..."
        
        aws eks update-kubeconfig --name "$CLUSTER_NAME" --region "$AWS_REGION"
        
        if ! kubectl get nodes &> /dev/null; then
            error "Não foi possível configurar o kubectl. Verifique se o cluster existe."
            exit 1
        fi
    fi
    
    success "kubectl configurado e funcionando"
}

# Verificar se o namespace monitoring existe
check_monitoring_namespace() {
    log "Verificando namespace monitoring..."
    
    if ! kubectl get namespace monitoring &> /dev/null; then
        warning "Namespace monitoring não existe. Criando..."
        kubectl create namespace monitoring
        success "Namespace monitoring criado"
    else
        success "Namespace monitoring existe"
    fi
}

# Instalar/atualizar o chart de monitoramento
install_monitoring() {
    log "Instalando/atualizando chart de monitoramento..."
    
    cd helm/monitoring
    
    # Verificar se o Helm está instalado
    if ! command -v helm &> /dev/null; then
        error "Helm não está instalado. Instale o Helm primeiro."
        exit 1
    fi
    
    # Instalar/atualizar o chart
    helm upgrade --install monitoring . \
        --namespace monitoring \
        --create-namespace \
        --wait \
        --timeout=10m
    
    cd ../..
    
    success "Chart de monitoramento instalado/atualizado"
}

# Verificar se os pods estão rodando
check_pods() {
    log "Verificando status dos pods de monitoramento..."
    
    local pods=(
        "prometheus"
        "grafana"
        "loki"
        "promtail"
        "alertmanager"
    )
    
    for pod in "${pods[@]}"; do
        if kubectl get pods -n monitoring | grep -q "$pod.*Running"; then
            success "Pod $pod está rodando"
        else
            warning "Pod $pod não está rodando ou não foi encontrado"
        fi
    done
}

# Verificar se os serviços estão acessíveis
check_services() {
    log "Verificando serviços de monitoramento..."
    
    local services=(
        "prometheus:9090"
        "grafana:3000"
        "loki:3100"
        "alertmanager:9093"
    )
    
    for service in "${services[@]}"; do
        local name=$(echo "$service" | cut -d: -f1)
        local port=$(echo "$service" | cut -d: -f2)
        
        if kubectl get svc -n monitoring | grep -q "$name"; then
            success "Serviço $name existe"
            
            # Testar conectividade interna
            if kubectl run test-connection --image=busybox --rm -it --restart=Never -n monitoring -- \
                wget -qO- --timeout=5 "http://$name:$port" &> /dev/null; then
                success "Serviço $name está acessível internamente"
            else
                warning "Serviço $name não está acessível internamente"
            fi
        else
            warning "Serviço $name não existe"
        fi
    done
}

# Verificar ingress
check_ingress() {
    log "Verificando ingress de monitoramento..."
    
    local ingress_hosts=(
        "grafana.sre-test.duckdns.org"
        "prometheus.sre-test.duckdns.org"
        "alertmanager.sre-test.duckdns.org"
    )
    
    for host in "${ingress_hosts[@]}"; do
        if kubectl get ingress -n monitoring | grep -q "$host"; then
            success "Ingress para $host existe"
        else
            warning "Ingress para $host não existe"
        fi
    done
}

# Configurar port-forward para acesso local
setup_port_forward() {
    log "Configurando port-forward para acesso local..."
    
    # Parar port-forwards existentes
    pkill -f "kubectl port-forward" || true
    
    # Iniciar novos port-forwards
    kubectl port-forward -n monitoring svc/grafana 3000:3000 &
    kubectl port-forward -n monitoring svc/prometheus 9090:9090 &
    kubectl port-forward -n monitoring svc/loki 3100:3100 &
    kubectl port-forward -n monitoring svc/alertmanager 9093:9093 &
    
    sleep 5
    
    success "Port-forward configurado:"
    info "  - Grafana: http://localhost:3000 (admin/admin123)"
    info "  - Prometheus: http://localhost:9090 (admin/prometheus123)"
    info "  - Loki: http://localhost:3100"
    info "  - Alertmanager: http://localhost:9093 (admin/alertmanager123)"
}

# Verificar métricas
check_metrics() {
    log "Verificando coleta de métricas..."
    
    # Verificar se o kube-state-metrics está rodando
    if kubectl get pods -n kube-system | grep -q "kube-state-metrics.*Running"; then
        success "kube-state-metrics está rodando"
    else
        warning "kube-state-metrics não está rodando"
    fi
    
    # Verificar se o Prometheus está coletando métricas
    if kubectl run test-metrics --image=busybox --rm -it --restart=Never -n monitoring -- \
        wget -qO- --timeout=5 "http://prometheus:9090/api/v1/targets" | grep -q "up"; then
        success "Prometheus está coletando métricas"
    else
        warning "Prometheus pode não estar coletando métricas"
    fi
}

# Verificar logs
check_logs() {
    log "Verificando coleta de logs..."
    
    # Verificar se o Promtail está rodando
    if kubectl get pods -n monitoring | grep -q "promtail.*Running"; then
        success "Promtail está rodando"
    else
        warning "Promtail não está rodando"
    fi
    
    # Verificar se o Loki está acessível
    if kubectl run test-loki --image=busybox --rm -it --restart=Never -n monitoring -- \
        wget -qO- --timeout=5 "http://loki:3100/ready" | grep -q "ready"; then
        success "Loki está funcionando"
    else
        warning "Loki pode não estar funcionando"
    fi
}

# Verificar alertas
check_alerts() {
    log "Verificando configuração de alertas..."
    
    # Verificar se o Alertmanager está rodando
    if kubectl get pods -n monitoring | grep -q "alertmanager.*Running"; then
        success "Alertmanager está rodando"
    else
        warning "Alertmanager não está rodando"
    fi
    
    # Verificar se há regras de alerta configuradas
    if kubectl get configmap -n monitoring | grep -q "prometheus-rules"; then
        success "Regras de alerta configuradas"
    else
        warning "Regras de alerta podem não estar configuradas"
    fi
}

# Mostrar URLs de acesso
show_access_urls() {
    log "URLs de acesso para monitoramento:"
    echo ""
    echo "🔍 **Acesso Local (Port-Forward):**"
    echo "  - Grafana: http://localhost:3000"
    echo "    Usuário: admin"
    echo "    Senha: admin123"
    echo ""
    echo "  - Prometheus: http://localhost:9090"
    echo "    Usuário: admin"
    echo "    Senha: prometheus123"
    echo ""
    echo "  - Alertmanager: http://localhost:9093"
    echo "    Usuário: admin"
    echo "    Senha: alertmanager123"
    echo ""
    echo "  - Loki: http://localhost:3100"
    echo ""
    echo "🌐 **Acesso Externo (Ingress):**"
    echo "  - Grafana: https://grafana.sre-test.duckdns.org"
    echo "  - Prometheus: https://prometheus.sre-test.duckdns.org"
    echo "  - Alertmanager: https://alertmanager.sre-test.duckdns.org"
    echo ""
    echo "📊 **Dashboards Disponíveis:**"
    echo "  - Kubernetes Cluster Overview"
    echo "  - Node Exporter"
    echo "  - WhoAmI Application"
    echo "  - Loki Logs"
    echo ""
}

# Função principal
main() {
    log "Configurando e verificando observabilidade do projeto SRE Desafio"
    
    # Verificar kubectl
    check_kubectl
    
    # Verificar namespace
    check_monitoring_namespace
    
    # Instalar monitoramento
    install_monitoring
    
    # Verificar componentes
    check_pods
    check_services
    check_ingress
    check_metrics
    check_logs
    check_alerts
    
    # Configurar port-forward
    setup_port_forward
    
    # Mostrar URLs
    show_access_urls
    
    success "Observabilidade configurada e verificada com sucesso!"
    log "Todos os componentes de monitoramento estão funcionando."
}

# Tratamento de interrupção
trap 'log "Interrompendo configuração..."; pkill -f "kubectl port-forward" || true; exit 1' INT TERM

# Executar função principal
main "$@" 