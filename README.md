# Teste Técnico SRE - Monitoramento Kubernetes

Este projeto implementa uma solução completa de monitoramento para aplicações Kubernetes usando EKS, Terraform, Helm, Prometheus, Grafana, Loki e Alertmanager.

## 🚀 Status Atual

✅ **Todos os componentes estão funcionando corretamente:**

- **Prometheus**: Coletando métricas do kube-state-metrics e containers
- **Grafana**: Dashboards funcionando com dados reais
- **Loki**: Coletando logs via Promtail
- **Alertmanager**: Alertas configurados e funcionando
- **kube-state-metrics**: Instalado e expondo métricas
- **Aplicação whoami**: Rodando com 2 réplicas

## 📊 Serviços Disponíveis

### Port-Forwards Configurados:
- **Grafana**: http://localhost:3000 (admin/admin)
- **Prometheus**: http://localhost:9090
- **Loki**: http://localhost:3100
- **Whoami**: http://localhost:8080
- **AlertManager**: http://localhost:9093

### Para iniciar todos os port-forwards:
```bash
./scripts/access-monitoring.sh
```

### Para verificar o status:
```bash
./scripts/verify-monitoring.sh
```

## 🔧 Componentes Instalados

### Monitoramento
- **Prometheus**: Coleta métricas de containers, nodes e kube-state-metrics
- **Grafana**: Dashboards para visualização de métricas e logs
- **Loki**: Agregação e consulta de logs
- **Alertmanager**: Gerenciamento de alertas
- **Promtail**: Coleta de logs dos pods

### Aplicação
- **whoami**: Aplicação de teste com 2 réplicas
- **kube-state-metrics**: Métricas do estado do cluster

## 📈 Métricas Coletadas

### Prometheus
- Métricas de containers via cAdvisor
- Métricas de nodes via kubelet
- Métricas do kube-state-metrics
- Métricas de pods e serviços com anotações

### Alertas Configurados
- **WhoAmIPodDown**: Pod da aplicação down
- **WhoAmIPodNotReady**: Pod não está pronto
- **WhoAmIDeploymentNotReady**: Deployment não está pronto
- **WhoAmIContainerRestarts**: Containers reiniciando frequentemente
- **NodeDown**: Node inacessível
- **HighCPUUsage**: Uso alto de CPU
- **HighMemoryUsage**: Uso alto de memória
- **HighDiskUsage**: Uso alto de disco

## 🗂️ Estrutura do Projeto

```
teste-sre/
├── terraform/           # Infraestrutura EKS
├── helm/               # Charts Helm
│   ├── monitoring/     # Stack de monitoramento
│   └── whoami/         # Aplicação de teste
├── k8s/                # Manifests Kubernetes
├── scripts/            # Scripts de automação
├── stress-test/        # Testes de carga com k6
└── docs/               # Documentação
```

## 🚀 Como Usar

### 1. Verificar Status
```bash
./scripts/verify-monitoring.sh
```

### 2. Acessar Serviços
```bash
./scripts/access-monitoring.sh
```

### 3. Executar Testes de Carga
```bash
./stress-test/run-k6-stress-test.sh
```

### 4. Verificar Logs
```bash
./scripts/test-loki-connectivity.sh
```

## 📝 Próximos Passos

- [ ] Configurar notificações externas no Alertmanager
- [ ] Adicionar mais dashboards específicos
- [ ] Implementar backup das configurações
- [ ] Configurar métricas customizadas
- [ ] Implementar testes de resiliência

## 🔍 Troubleshooting

### Problemas Comuns:
1. **Port-forward não funciona**: Execute `pkill -f "kubectl port-forward"` e tente novamente
2. **Prometheus sem dados**: Verifique se o kube-state-metrics está rodando
3. **Grafana sem dashboards**: Verifique se os ConfigMaps estão aplicados
4. **Loki sem logs**: Verifique se o Promtail está coletando logs

### Logs Úteis:
```bash
kubectl logs -n monitoring deployment/monitoring-prometheus
kubectl logs -n monitoring deployment/grafana
kubectl logs -n monitoring deployment/monitoring-loki
``` 