# Arquitetura do Projeto SRE Desafio

## Visão Geral

Este documento descreve a arquitetura completa do projeto SRE Desafio, incluindo decisões técnicas, componentes e fluxos de dados.

## Arquitetura de Alto Nível

┌─────────────────────────────────────────────────────────────────┐
│ AWS Cloud │
├─────────────────────────────────────────────────────────────────┤
│ ┌─────────────────┐ ┌─────────────────┐ ┌─────────────────┐ │
│ │ VPC │ │ EKS Cluster │ │ Load Balancer │ │
│ │ │ │ │ │ │ │
│ │ ┌─────────────┐ │ │ ┌─────────────┐ │ │ ┌─────────────┐ │ │
│ │ │ Public │ │ │ │ Master │ │ │ │ ALB/NLB │ │ │
│ │ │ Subnets │ │ │ │ Nodes │ │ │ │ │ │ │
│ │ └─────────────┘ │ │ └─────────────┘ │ │ └─────────────┘ │ │
│ │ │ │ │ │ │ │
│ │ ┌─────────────┐ │ │ ┌─────────────┐ │ │ │ │
│ │ │ Private │ │ │ │ Worker │ │ │ │ │
│ │ │ Subnets │ │ │ │ Nodes │ │ │ │ │
│ │ └─────────────┘ │ │ └─────────────┘ │ │ │ │
│ └─────────────────┘ └─────────────────┘ └─────────────────┘ │
└─────────────────────────────────────────────────────────────────┘
│
▼
┌─────────────────────────────────────────────────────────────────┐
│ Kubernetes Layer │
├─────────────────────────────────────────────────────────────────┤
│ ┌─────────────────┐ ┌─────────────────┐ ┌─────────────────┐ │
│ │ Ingress │ │ Application │ │ Monitoring │ │
│ │ Controller │ │ Layer │ │ Stack │ │
│ │ │ │ │ │ │ │
│ │ ┌─────────────┐ │ │ ┌─────────────┐ │ │ ┌─────────────┐ │ │
│ │ │ NGINX │ │ │ │ WhoAmI │ │ │ │ Prometheus │ │ │
│ │ │ Ingress │ │ │ │ Application │ │ │ │ │ │ │
│ │ └─────────────┘ │ │ └─────────────┘ │ │ └─────────────┘ │ │
│ │ │ │ │ │ │ │
│ │ ┌─────────────┐ │ │ ┌─────────────┐ │ │ ┌─────────────┐ │ │
│ │ │ Cert- │ │ │ │ Auto- │ │ │ │ Grafana │ │ │
│ │ │ Manager │ │ │ │ Scaling │ │ │ │ │ │ │
│ │ └─────────────┘ │ │ └─────────────┘ │ │ └─────────────┘ │ │
│ └─────────────────┘ └─────────────────┘ │ │ │
│ │ ┌─────────────┐ │ │
│ │ │ Loki │ │ │
│ │ │ │ │ │
│ │ └─────────────┘ │ │
│ └─────────────────┘ │
└─────────────────────────────────────────────────────────────────┘
Apply to arquitetura....
Internet → ALB → Ingress Controller → WhoAmI Pods
Apply to arquitetura....
WhoAmI Pods → Prometheus → Grafana
Apply to arquitetura....
WhoAmI Pods → Promtail → Loki → Grafana
Apply to arquitetura....
Prometheus → AlertManager → Notificações
Apply to arquitetura....


## Componentes Principais

### 1. Infraestrutura AWS

#### VPC (Virtual Private Cloud)
- **CIDR**: 10.0.0.0/16
- **Subnets Públicas**: 3 subnets em diferentes AZs
- **Subnets Privadas**: 3 subnets em diferentes AZs
- **NAT Gateways**: 1 por AZ para alta disponibilidade
- **Internet Gateway**: Para acesso à internet

#### EKS Cluster
- **Versão**: Kubernetes 1.29
- **Node Groups**: 2-6 nodes t3.medium
- **Multi-AZ**: Distribuição automática em 3 AZs
- **Auto-scaling**: HPA configurado
- **IRSA**: IAM Roles for Service Accounts habilitado

### 2. Aplicação

#### WhoAmI Application
- **Imagem**: jwilder/whoami:latest
- **Replicas**: 3 (mínimo 2, máximo 10)
- **Recursos**: CPU 100m-200m, Memória 128Mi-256Mi
- **Probes**: Liveness e Readiness configurados
- **Auto-scaling**: Baseado em CPU (70%) e memória (80%)

#### Ingress Controller
- **NGINX Ingress**: Para roteamento de tráfego
- **SSL/TLS**: Cert-manager + Let's Encrypt
- **Annotations**: Configurações de segurança e performance

### 3. Monitoramento

#### Prometheus
- **Retenção**: 15 dias
- **Storage**: 10Gi PVC
- **ServiceMonitors**: Para coleta de métricas da aplicação
- **AlertManager**: Para gerenciamento de alertas

#### Grafana
- **Dashboards**: Pré-configurados para WhoAmI
- **Datasources**: Prometheus e Loki
- **Persistence**: 5Gi PVC

#### Loki
- **Log Aggregation**: Para logs da aplicação
- **Promtail**: Para coleta de logs dos pods
- **Persistence**: 5Gi PVC

### 4. Segurança

#### Network Policies
- **Ingress**: Apenas tráfego do ingress controller
- **Egress**: Restrições de saída configuradas

#### Security Groups
- **Cluster**: Apenas tráfego necessário
- **Nodes**: Regras restritivas de entrada/saída

#### RBAC
- **Service Accounts**: Configuradas para cada componente
- **Roles**: Permissões mínimas necessárias

## Fluxos de Dados

### 1. Tráfego de Usuário

Internet → ALB → Ingress Controller → WhoAmI Pods

### 2. Métricas

WhoAmI Pods → Prometheus → Grafana

### 3. Logs

WhoAmI Pods → Promtail → Loki → Grafana

### 4. Alertas

Prometheus → AlertManager → Notificações


## Decisões Técnicas

### Alta Disponibilidade

1. **Multi-AZ Deployment**
   - VPC com 3 AZs
   - Nodes distribuídos automaticamente
   - NAT Gateways redundantes

2. **Auto-scaling**
   - HPA baseado em CPU e memória
   - Cluster autoscaler para nodes
   - Pod disruption budgets

3. **Load Balancing**
   - Ingress controller com múltiplas réplicas
   - Service type ClusterIP com endpoints

### Segurança

1. **Network Segmentation**
   - Subnets públicas e privadas
   - Security groups restritivos
   - Network policies no Kubernetes

2. **SSL/TLS**
   - Cert-manager para gerenciamento automático
   - Let's Encrypt para certificados gratuitos
   - HSTS e outras headers de segurança

3. **Access Control**
   - RBAC habilitado
   - Service accounts com permissões mínimas
   - IRSA para integração com IAM

### Monitoramento

1. **Métricas**
   - Prometheus para coleta
   - ServiceMonitors para descoberta
   - Dashboards customizados

2. **Logs**
   - Loki para agregação
   - Promtail para coleta
   - Labels estruturados

3. **Alertas**
   - AlertManager para gerenciamento
   - Regras baseadas em thresholds
   - Notificações configuráveis

## Escalabilidade

### Horizontal Scaling
- **Pods**: Auto-scaling baseado em métricas
- **Nodes**: Cluster autoscaler
- **Services**: Load balancing automático

### Vertical Scaling
- **Resources**: Requests e limits configurados
- **Storage**: PVCs com provisioners adequados
- **Network**: Bandwidth otimizada

## Resiliência

### Fault Tolerance
- **Multi-AZ**: Distribuição geográfica
- **Replicas**: Múltiplas instâncias
- **Health Checks**: Probes configurados

### Disaster Recovery
- **Backup**: Configurações em Git
- **State**: Terraform state em S3
- **Documentation**: Procedimentos documentados

## Performance

### Otimizações
- **Resource Limits**: Evita resource starvation
- **Affinity Rules**: Distribuição de pods
- **Network Policies**: Reduz overhead de rede

### Monitoring
- **Metrics**: Coleta em tempo real
- **Dashboards**: Visualização de performance
- **Alerting**: Detecção de problemas

## Manutenibilidade

### Infrastructure as Code
- **Terraform**: Para infraestrutura AWS
- **Helm**: Para aplicações Kubernetes
- **GitOps**: Para versionamento

### CI/CD
- **GitHub Actions**: Pipeline automatizado
- **Testing**: Validação em cada commit
- **Deployment**: Rollout automático

## Custos

### Otimizações
- **Instance Types**: t3.medium para desenvolvimento
- **Storage**: EBS gp3 para melhor performance/custo
- **Auto-scaling**: Reduz custos em baixa utilização

### Monitoring
- **CloudWatch**: Métricas básicas
- **Cost Explorer**: Análise de custos
- **Tags**: Organização de recursos


