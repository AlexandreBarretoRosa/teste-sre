# Decisões Técnicas - SRE Desafio

Este documento detalha as principais decisões técnicas tomadas durante o desenvolvimento do projeto, incluindo justificativas e alternativas consideradas.

## 1. Plataforma de Nuvem

### Decisão: AWS
**Justificativa:**
- EKS (Elastic Kubernetes Service) oferece alta disponibilidade nativa
- Integração robusta com outros serviços AWS
- Suporte oficial para Kubernetes
- Ferramentas maduras de monitoramento e segurança

**Alternativas Consideradas:**
- **GCP GKE**: Boa opção, mas menos familiaridade da equipe
- **Azure AKS**: Similar ao EKS, mas ecossistema menos maduro
- **On-premise**: Maior complexidade de manutenção

## 2. Orquestração de Containers

### Decisão: Kubernetes (EKS)
**Justificativa:**
- Padrão da indústria para orquestração
- Auto-scaling nativo
- Alta disponibilidade com múltiplos nodes
- Ecossistema rico de ferramentas

**Alternativas Consideradas:**
- **Docker Swarm**: Mais simples, mas menos recursos
- **Nomad**: Boa performance, mas ecossistema menor
- **ECS**: Limitado à AWS, menos flexível

## 3. Infraestrutura como Código

### Decisão: Terraform
**Justificativa:**
- Padrão da indústria
- Suporte nativo para AWS
- Estado versionado
- Módulos reutilizáveis

**Alternativas Consideradas:**
- **CloudFormation**: Limitado à AWS
- **Pulumi**: Mais moderno, mas menos maduro
- **Ansible**: Focado em configuração, não infraestrutura

## 4. Gerenciamento de Aplicações

### Decisão: Helm
**Justificativa:**
- Padrão para Kubernetes
- Templates reutilizáveis
- Versionamento de releases
- Rollback fácil

**Alternativas Consideradas:**
- **Kustomize**: Mais simples, mas menos recursos
- **Operator Pattern**: Mais complexo para este caso
- **Manifests diretos**: Menos manutenível

## 5. Aplicação de Demonstração

### Decisão: WhoAmI
**Justificativa:**
- Simples e leve
- Mostra informações do pod/node
- Perfeita para demonstrar load balancing
- Imagem oficial e estável

**Alternativas Consideradas:**
- **Echo server**: Similar, mas menos informativo
- **Nginx**: Mais pesado, menos demonstrativo
- **Aplicação customizada**: Mais trabalho, menos foco no objetivo

## 6. Ingress Controller

### Decisão: NGINX Ingress
**Justificativa:**
- Mais popular e maduro
- Boa documentação
- Suporte robusto para SSL/TLS
- Performance otimizada

**Alternativas Consideradas:**
- **Traefik**: Mais moderno, mas menos maduro
- **HAProxy**: Mais complexo de configurar
- **Istio**: Overkill para este projeto

## 7. Gerenciamento de Certificados

### Decisão: Cert-manager + Let's Encrypt
**Justificativa:**
- Certificados gratuitos
- Renovação automática
- Integração nativa com Kubernetes
- Padrão da indústria

**Alternativas Consideradas:**
- **Certificados auto-assinados**: Não adequado para produção
- **Certificados pagos**: Custo desnecessário
- **AWS Certificate Manager**: Limitado à AWS

## 8. Stack de Monitoramento

### Decisão: Prometheus + Grafana + Loki
**Justificativa:**
- **Prometheus**: Padrão para métricas em Kubernetes
- **Grafana**: Melhor ferramenta de visualização
- **Loki**: Integração nativa com Grafana
- **AlertManager**: Sistema robusto de alertas

**Alternativas Consideradas:**
- **Datadog**: Mais completo, mas pago
- **New Relic**: Boa integração, mas custo
- **ELK Stack**: Mais complexo de manter

## 9. Auto-scaling

### Decisão: HPA (Horizontal Pod Autoscaler)
**Justificativa:**
- Nativo do Kubernetes
- Baseado em métricas reais
- Configuração simples
- Integração com Prometheus

**Alternativas Consideradas:**
- **VPA**: Mais complexo, pode causar restarts
- **Custom metrics**: Mais trabalho de implementar
- **Manual scaling**: Não adequado para produção

## 10. Segurança de Rede

### Decisão: Network Policies + Security Groups
**Justificativa:**
- **Network Policies**: Controle granular no Kubernetes
- **Security Groups**: Segurança na camada AWS
- **Defesa em profundidade**: Múltiplas camadas

**Alternativas Consideradas:**
- **Service Mesh**: Overkill para este projeto
- **Apenas Security Groups**: Menos granular
- **Sem restrições**: Não adequado para produção

## 11. CI/CD

### Decisão: GitHub Actions
**Justificativa:**
- Integração nativa com Git
- Suporte para múltiplas plataformas
- Marketplace rico
- Gratuito para projetos open source

**Alternativas Consideradas:**
- **Jenkins**: Mais complexo de manter
- **GitLab CI**: Limitado ao GitLab
- **AWS CodePipeline**: Limitado à AWS

## 12. Testes de Estresse

### Decisão: Múltiplas ferramentas (ab, wrk, hey)
**Justificativa:**
- **Apache Bench**: Simples e confiável
- **wrk**: Performance superior
- **hey**: Mais moderno e flexível
- **Cobertura completa**: Diferentes tipos de teste

**Alternativas Consideradas:**
- **JMeter**: Mais complexo de configurar
- **Locust**: Requer Python
- **Artillery**: Focado em APIs

## Conclusão

As decisões técnicas tomadas priorizaram:
1. **Simplicidade**: Ferramentas maduras e bem documentadas
2. **Padrões da indústria**: Soluções amplamente adotadas
3. **Custo-benefício**: Balanceamento entre funcionalidade e custo
4. **Manutenibilidade**: Fácil operação e troubleshooting
5. **Escalabilidade**: Preparado para crescimento futuro

Todas as decisões foram baseadas em requisitos específicos do desafio e considerando o contexto de um projeto de demonstração com potencial para produção.