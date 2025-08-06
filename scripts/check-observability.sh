#!/bin/bash

# Script para verificar status da observabilidade - SRE Desafio
# Este script verifica rapidamente se todos os componentes estão funcionando

set -e

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
    if ! kubectl get nodes &> /dev/null; then
        error "kubectl não está configurado"
        return 1
    fi
    return 0
}

# Verificar status dos pods
check_pods_status() {
    log "Verificando status dos pods de monitoramento..."
    
    local all_running=true
    
    # Verificar pods no namespace monitoring
    if kubectl get pods -n monitoring &> /dev/null; then
        local pods=$(kubectl get pods -n monitoring --no-headers | awk '{print $1 " " $3}')
        
        while IFS= read -r pod_info; do
            if [ -n "$pod_info" ]; then
                local pod_name=$(echo "$pod_info" | awk '{print $1}')
                local pod_status=$(echo "$pod_info" | awk '{print $2}')
                
                if [ "$pod_status" = "Running" ]; then
                    success "✅ $pod_name: $pod_status"
                else
                    warning "⚠️  $pod_name: $pod_status"
                    all_running=false
                fi
            fi
        done <<< "$pods"
    else
        error "Namespace monitoring não existe ou não há pods"
        all_running=false
    fi
    
    return $([ "$all_running" = true ] && echo 0 || echo 1)
}

# Verificar serviços
check_services() {
    log "Verificando serviços de monitoramento..."
    
    local services=("prometheus" "grafana" "loki" "alertmanager")
    
    for service in "${services[@]}"; do
        if kubectl get svc -n monitoring "$service" &> /dev/null; then
            success "✅ Serviço $service existe"
        else
            warning "⚠️  Serviço $service não existe"
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
            success "✅ Ingress para $host existe"
        else
            warning "⚠️  Ingress para $host não existe"
        fi
    done
}

# Verificar conectividade
check_connectivity() {
    log "Verificando conectividade dos serviços..."
    
    local services=(
        "prometheus:9090"
        "grafana:3000"
        "loki:3100"
        "alertmanager:9093"
    )
    
    for service in "${services[@]}"; do
        local name=$(echo "$service" | cut -d: -f1)
        local port=$(echo "$service" | cut -d: -f2)
        
        if kubectl run test-connectivity --image=busybox --rm -it --restart=Never -n monitoring -- \
            wget -qO- --timeout=5 "http://$name:$port" &> /dev/null; then
            success "✅ $name está acessível internamente"
        else
            warning "⚠️  $name não está acessível internamente"
        fi
    done
}

# Verificar métricas
check_metrics() {
    log "Verificando coleta de métricas..."
    
    # Verificar kube-state-metrics
    if kubectl get pods -n kube-system | grep -q "kube-state-metrics.*Running"; then
        success "✅ kube-state-metrics está rodando"
    else
        warning "⚠️  kube-state-metrics não está rodando"
    fi
    
    # Verificar se Prometheus está coletando
    if kubectl run test-metrics --image=busybox --rm -it --restart=Never -n monitoring -- \
        wget -qO- --timeout=5 "http://prometheus:9090/api/v1/targets" | grep -q "up"; then
        success "✅ Prometheus está coletando métricas"
    else
        warning "⚠️  Prometheus pode não estar coletando métricas"
    fi
}

# Verificar logs
check_logs() {
    log "Verificando coleta de logs..."
    
    # Verificar Promtail
    if kubectl get pods -n monitoring | grep -q "promtail.*Running"; then
        success "✅ Promtail está rodando"
    else
        warning "⚠️  Promtail não está rodando"
    fi
    
    # Verificar Loki
    if kubectl run test-loki --image=busybox --rm -it --restart=Never -n monitoring -- \
        wget -qO- --timeout=5 "http://loki:3100/ready" | grep -q "ready"; then
        success "✅ Loki está funcionando"
    else
        warning "⚠️  Loki pode não estar funcionando"
    fi
}

# Mostrar URLs de acesso
show_urls() {
    log "URLs de acesso para monitoramento:"
    echo ""
    echo "🔍 **Acesso Local (Port-Forward):**"
    echo "  - Grafana: http://localhost:3000 (admin/admin123)"
    echo "  - Prometheus: http://localhost:9090 (admin/prometheus123)"
    echo "  - Alertmanager: http://localhost:9093 (admin/alertmanager123)"
    echo "  - Loki: http://localhost:3100"
    echo ""
    echo "🌐 **Acesso Externo (Ingress):**"
    echo "  - Grafana: https://grafana.sre-test.duckdns.org"
    echo "  - Prometheus: https://prometheus.sre-test.duckdns.org"
    echo "  - Alertmanager: https://alertmanager.sre-test.duckdns.org"
    echo ""
}

# Função principal
main() {
    log "Verificando status da observabilidade..."
    
    # Verificar kubectl
    if ! check_kubectl; then
        error "kubectl não está configurado. Execute: aws eks update-kubeconfig --name sre-desafio-cluster --region us-east-1"
        exit 1
    fi
    
    echo ""
    
    # Verificar componentes
    check_pods_status
    echo ""
    
    check_services
    echo ""
    
    check_ingress
    echo ""
    
    check_connectivity
    echo ""
    
    check_metrics
    echo ""
    
    check_logs
    echo ""
    
    # Mostrar URLs
    show_urls
    
    success "Verificação concluída!"
}

# Executar função principal
main "$@" 