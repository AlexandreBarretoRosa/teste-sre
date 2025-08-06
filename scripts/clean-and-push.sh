#!/bin/bash

# Script para limpar arquivos grandes e fazer push - SRE Desafio
# Este script remove arquivos grandes do tracking e faz push

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

# Verificar se estamos no diretório correto
check_directory() {
    if [ ! -f ".git/config" ]; then
        error "Não estamos em um repositório Git. Execute este script no diretório raiz do projeto."
        exit 1
    fi
}

# Remover arquivos grandes do tracking
remove_large_files() {
    log "Removendo arquivos grandes do tracking..."
    
    # Lista de arquivos grandes para remover
    local large_files=(
        "bfg.jar"
        "*.jar"
        "*.war"
        "*.ear"
        "*.zip"
        "*.tar.gz"
        "*.tar.bz2"
        "*.rar"
        "*.7z"
    )
    
    for pattern in "${large_files[@]}"; do
        if git ls-files | grep -q "$pattern"; then
            info "Removendo arquivos que correspondem ao padrão: $pattern"
            git rm --cached "$pattern" 2>/dev/null || true
        fi
    done
    
    # Remover arquivos específicos
    if git ls-files | grep -q "bfg.jar"; then
        info "Removendo bfg.jar do tracking"
        git rm --cached bfg.jar
    fi
    
    success "Arquivos grandes removidos do tracking"
}

# Limpar arquivos de relatório de testes
clean_test_reports() {
    log "Limpando arquivos de relatório de testes..."
    
    # Remover arquivos de relatório se existirem
    local test_files=(
        "stress_test_*.txt"
        "stress_test_*.csv"
        "p4a-reports-*"
        "cluster_monitoring_*.txt"
        "quick_*_test_*.txt"
    )
    
    for pattern in "${test_files[@]}"; do
        if ls $pattern 2>/dev/null; then
            info "Removendo arquivos de teste: $pattern"
            git rm --cached $pattern 2>/dev/null || true
            rm -f $pattern
        fi
    done
    
    success "Arquivos de teste limpos"
}

# Verificar tamanho dos arquivos
check_file_sizes() {
    log "Verificando tamanho dos arquivos..."
    
    # Listar arquivos maiores que 1MB
    local large_files=$(find . -type f -size +1M -not -path "./.git/*" | head -10)
    
    if [ -n "$large_files" ]; then
        warning "Arquivos grandes encontrados:"
        echo "$large_files" | while read -r file; do
            local size=$(du -h "$file" | cut -f1)
            echo "  - $file ($size)"
        done
    else
        success "Nenhum arquivo grande encontrado"
    fi
}

# Fazer commit das mudanças
commit_changes() {
    log "Fazendo commit das mudanças..."
    
    # Verificar se há mudanças
    if git status --porcelain | grep -q .; then
        git add .
        git commit -m "chore: remove large files and update .gitignore
        
        - Remove bfg.jar and other large files from tracking
        - Update .gitignore to exclude large files and test reports
        - Clean up test report files"
        success "Commit realizado"
    else
        info "Nenhuma mudança para commitar"
    fi
}

# Fazer push com retry
push_with_retry() {
    log "Fazendo push para o repositório remoto..."
    
    local max_retries=3
    local retry_count=0
    
    while [ $retry_count -lt $max_retries ]; do
        if git push origin teste; then
            success "Push realizado com sucesso!"
            return 0
        else
            retry_count=$((retry_count + 1))
            warning "Tentativa $retry_count/$max_retries falhou. Aguardando 30 segundos..."
            sleep 30
        fi
    done
    
    error "Push falhou após $max_retries tentativas"
    return 1
}

# Configurar Git para arquivos grandes
configure_git_lfs() {
    log "Configurando Git LFS para arquivos grandes (se necessário)..."
    
    # Verificar se Git LFS está instalado
    if command -v git-lfs &> /dev/null; then
        info "Git LFS está instalado"
        
        # Configurar LFS para arquivos grandes
        git lfs track "*.jar"
        git lfs track "*.war"
        git lfs track "*.ear"
        git lfs track "*.zip"
        git lfs track "*.tar.gz"
        git lfs track "*.tar.bz2"
        
        # Adicionar .gitattributes
        if [ ! -f ".gitattributes" ]; then
            git add .gitattributes
            git commit -m "chore: add Git LFS tracking for large files"
        fi
        
        success "Git LFS configurado"
    else
        warning "Git LFS não está instalado. Instale com: git lfs install"
    fi
}

# Função principal
main() {
    log "Iniciando limpeza e push do repositório..."
    
    # Verificar diretório
    check_directory
    
    # Remover arquivos grandes
    remove_large_files
    
    # Limpar arquivos de teste
    clean_test_reports
    
    # Verificar tamanhos
    check_file_sizes
    
    # Configurar Git LFS (opcional)
    configure_git_lfs
    
    # Fazer commit
    commit_changes
    
    # Fazer push
    push_with_retry
    
    success "Processo concluído com sucesso!"
}

# Tratamento de interrupção
trap 'log "Interrompendo processo..."; exit 1' INT TERM

# Executar função principal
main "$@" 