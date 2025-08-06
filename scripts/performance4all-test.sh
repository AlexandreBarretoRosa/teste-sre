#!/bin/bash

# Script de Stress Test usando Performance4All - SRE Desafio
# Este script utiliza Performance4All para testes de performance avançados

set -e

# Configurações
PROJECT_NAME="sre-desafio"
AWS_REGION="us-east-1"
CLUSTER_NAME="${PROJECT_NAME}-cluster"
APP_URL="https://sre-test.duckdns.org"

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
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

# Verificar se Performance4All está instalado
check_performance4all() {
    log "Verificando se Performance4All está instalado..."
    
    if ! command -v p4a &> /dev/null; then
        warning "Performance4All não está instalado."
        info "Instalando Performance4All..."
        
        # Instalar Performance4All
        install_performance4all
    else
        success "Performance4All está instalado"
    fi
}

# Instalar Performance4All
install_performance4all() {
    log "Instalando Performance4All..."
    
    # Verificar se Docker está instalado
    if ! command -v docker &> /dev/null; then
        error "Docker não está instalado. Instale o Docker primeiro."
        echo "Instruções: https://docs.docker.com/get-docker/"
        exit 1
    fi
    
    # Baixar e executar Performance4All via Docker
    docker pull performance4all/p4a:latest
    
    # Criar alias para facilitar o uso
    echo 'alias p4a="docker run --rm -it -v $(pwd):/workspace performance4all/p4a:latest"' >> ~/.bashrc
    source ~/.bashrc
    
    success "Performance4All instalado via Docker"
}

# Criar arquivo de configuração do Performance4All
create_p4a_config() {
    log "Criando configuração do Performance4All..."
    
    local config_file="p4a-config.yaml"
    
    cat > "$config_file" << EOF
# Configuração Performance4All para SRE Desafio
version: "1.0"
project:
  name: "sre-desafio-whoami"
  description: "Testes de performance para aplicação WhoAmI"

targets:
  - name: "whoami-app"
    url: "$APP_URL"
    method: "GET"
    headers:
      User-Agent: "Performance4All/1.0"
    timeout: 30

scenarios:
  - name: "carga-baixa"
    description: "Teste de carga baixa"
    target: "whoami-app"
    load:
      users: 10
      duration: 60
      ramp_up: 10
    thresholds:
      response_time_p95: 1000
      error_rate: 1.0

  - name: "carga-media"
    description: "Teste de carga média"
    target: "whoami-app"
    load:
      users: 50
      duration: 120
      ramp_up: 30
    thresholds:
      response_time_p95: 2000
      error_rate: 2.0

  - name: "carga-alta"
    description: "Teste de carga alta"
    target: "whoami-app"
    load:
      users: 100
      duration: 180
      ramp_up: 60
    thresholds:
      response_time_p95: 5000
      error_rate: 5.0

  - name: "stress-test"
    description: "Teste de stress"
    target: "whoami-app"
    load:
      users: 200
      duration: 300
      ramp_up: 120
    thresholds:
      response_time_p95: 10000
      error_rate: 10.0

  - name: "spike-test"
    description: "Teste de pico de carga"
    target: "whoami-app"
    load:
      users: 500
      duration: 60
      ramp_up: 10
    thresholds:
      response_time_p95: 15000
      error_rate: 15.0

  - name: "endurance-test"
    description: "Teste de endurance"
    target: "whoami-app"
    load:
      users: 50
      duration: 1800
      ramp_up: 300
    thresholds:
      response_time_p95: 3000
      error_rate: 3.0

monitoring:
  enabled: true
  metrics:
    - response_time
    - throughput
    - error_rate
    - cpu_usage
    - memory_usage

reporting:
  format: ["html", "json", "csv"]
  output_dir: "./p4a-reports"
EOF

    success "Configuração criada: $config_file"
}

# Executar teste com Performance4All
run_p4a_test() {
    local scenario_name=$1
    local config_file=$2
    
    log "Executando teste Performance4All: $scenario_name"
    
    local output_dir="p4a-reports-$(date +%Y%m%d_%H%M%S)"
    mkdir -p "$output_dir"
    
    # Executar teste via Docker
    docker run --rm -it \
        -v "$(pwd):/workspace" \
        -v "$(pwd)/$output_dir:/reports" \
        performance4all/p4a:latest \
        run --config "$config_file" --scenario "$scenario_name" --output "/reports"
    
    success "Teste $scenario_name concluído"
    info "Relatórios salvos em: $output_dir"
}

# Executar todos os cenários
run_all_scenarios() {
    log "Executando todos os cenários de teste..."
    
    local config_file="p4a-config.yaml"
    local scenarios=("carga-baixa" "carga-media" "carga-alta" "stress-test" "spike-test")
    
    for scenario in "${scenarios[@]}"; do
        log "Executando cenário: $scenario"
        run_p4a_test "$scenario" "$config_file"
        echo ""
        
        # Aguardar entre testes
        sleep 30
    done
    
    success "Todos os cenários foram executados"
}

# Executar teste de endurance (opcional)
run_endurance_test() {
    log "Executando teste de endurance (30 minutos)..."
    
    local config_file="p4a-config.yaml"
    run_p4a_test "endurance-test" "$config_file"
}

# Gerar relatório consolidado
generate_consolidated_report() {
    log "Gerando relatório consolidado..."
    
    local report_file="p4a-consolidated-report-$(date +%Y%m%d_%H%M%S).md"
    
    cat > "$report_file" << EOF
# Relatório Consolidado - Performance4All Tests

**Data:** $(date)
**Aplicação:** WhoAmI
**URL:** $APP_URL

## Resumo dos Testes

### Cenários Executados
EOF
    
    # Adicionar resultados dos testes
    for report_dir in p4a-reports-*; do
        if [ -d "$report_dir" ]; then
            echo "" >> "$report_file"
            echo "### $report_dir" >> "$report_file"
            echo "" >> "$report_file"
            
            # Procurar por arquivos de relatório
            for report in "$report_dir"/*.json; do
                if [ -f "$report" ]; then
                    echo "- $(basename "$report")" >> "$report_file"
                fi
            done
        fi
    done
    
    echo "" >> "$report_file"
    echo "### Análise de Performance" >> "$report_file"
    echo "" >> "$report_file"
    echo "Os relatórios detalhados estão disponíveis nos diretórios p4a-reports-*" >> "$report_file"
    
    success "Relatório consolidado gerado: $report_file"
}

# Monitorar recursos do cluster durante os testes
monitor_cluster_resources() {
    log "Iniciando monitoramento de recursos do cluster..."
    
    local output_file="p4a-cluster-monitoring-$(date +%Y%m%d_%H%M%S).txt"
    
    # Verificar se kubectl está configurado
    if ! kubectl get nodes &> /dev/null; then
        warning "kubectl não configurado. Pulando monitoramento do cluster."
        return 0
    fi
    
    # Monitorar por 30 minutos
    for i in {1..180}; do
        echo "=== $(date) ===" >> "$output_file"
        kubectl top nodes >> "$output_file" 2>&1 || true
        kubectl top pods -n whoami >> "$output_file" 2>&1 || true
        echo "" >> "$output_file"
        sleep 10
    done &
    
    local monitor_pid=$!
    echo $monitor_pid > /tmp/p4a_cluster_monitor.pid
    
    info "Monitoramento iniciado (PID: $monitor_pid)"
}

# Parar monitoramento
stop_monitoring() {
    if [ -f /tmp/p4a_cluster_monitor.pid ]; then
        local monitor_pid=$(cat /tmp/p4a_cluster_monitor.pid)
        if kill -0 $monitor_pid 2>/dev/null; then
            log "Parando monitoramento do cluster..."
            kill $monitor_pid
            rm -f /tmp/p4a_cluster_monitor.pid
        fi
    fi
}

# Verificar se a aplicação está acessível
check_app_availability() {
    log "Verificando se a aplicação está acessível..."
    
    local max_retries=30
    local retry_count=0
    
    while [ $retry_count -lt $max_retries ]; do
        if curl -s -f --max-time 10 "$APP_URL" > /dev/null; then
            success "Aplicação está acessível em $APP_URL"
            return 0
        else
            retry_count=$((retry_count + 1))
            warning "Tentativa $retry_count/$max_retries - Aplicação não está acessível ainda..."
            sleep 10
        fi
    done
    
    error "Aplicação não está acessível após $max_retries tentativas"
    return 1
}

# Função principal
main() {
    log "Iniciando Stress Test com Performance4All para aplicação WhoAmI"
    
    # Verificar se a aplicação está acessível
    if ! check_app_availability; then
        error "Não foi possível acessar a aplicação. Verifique se está rodando."
        exit 1
    fi
    
    # Verificar e instalar Performance4All
    check_performance4all
    
    # Criar configuração
    create_p4a_config
    
    # Iniciar monitoramento
    monitor_cluster_resources
    
    # Executar todos os cenários
    run_all_scenarios
    
    # Executar teste de endurance (opcional - comentado para não demorar muito)
    # run_endurance_test
    
    # Parar monitoramento
    stop_monitoring
    
    # Gerar relatório consolidado
    generate_consolidated_report
    
    success "Stress test com Performance4All concluído com sucesso!"
    log "Verifique os relatórios gerados para análise detalhada."
}

# Tratamento de interrupção
trap 'log "Interrompendo stress test..."; stop_monitoring; exit 1' INT TERM

# Executar função principal
main "$@" 