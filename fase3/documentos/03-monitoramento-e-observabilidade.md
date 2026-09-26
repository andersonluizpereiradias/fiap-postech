# 3. Monitoramento e Observabilidade

> Categoria 3 de 5 — Classificação dos resumos em PDF da pasta `resumos-fase-3`.
> Disciplinas de origem: **Monitoramento e Acesso** (stack open-source: Zabbix, Prometheus, Grafana) e **Monitoramento Avançado** (Datadog, New Relic, Alertas) — Fase 3 do PósTech FIAP.

## Bloco 1 — Stack Open Source (Zabbix, Prometheus, Grafana)

### Aula 1 — Introdução ao Monitoramento e Arquitetura Zabbix
- **Objetivo:** justificar por que monitorar (detecção proativa de problemas, capacity planning, garantia de SLA/SLO) e apresentar o **Zabbix** como solução "tudo-em-um" de monitoramento.
- **Conceitos-chave:** arquitetura Zabbix (Server, banco de dados, interface web, Agent — modos passivo/ativo —, Proxy para ambientes distribuídos); conceitos de **Host**, **Item** (métrica coletada, ex.: `system.cpu.util[]`), **Trigger** (regra que define estado OK/PROBLEMA) e **Template** (conjunto reutilizável de itens/triggers).
- **Hands-on:** stack completa via Docker Compose (Zabbix Server + Web + MySQL + Agent).
- **Mercado:** usado por Dell, T-Mobile e empresas do setor elétrico/governo brasileiro; tende a coexistir com Prometheus/Grafana (infraestrutura vs. aplicação).

### Aula 2 — Monitoramento com Prometheus
- **Objetivo:** apresentar o Prometheus como padrão de mercado para métricas em ambientes cloud-native, com modelo **pull** (scrape) em vez de **push** (Zabbix).
- **Conceitos-chave:** Service Discovery, Scraping Engine, TSDB embutido; **Exporters** (tradutores de métricas de serviços que não falam o protocolo Prometheus nativamente); **Alertmanager**; **PromQL** (ex.: `rate(sampleapp_requests_total[5m])`); instrumentação de uma aplicação .NET com `prometheus-net.AspNetCore`.
- **Complementaridade:** Zabbix responde "o sistema está de pé?" (black-box); Prometheus responde "o sistema está saudável por dentro?" (white-box).
- **Mercado:** projeto graduado da CNCF; usado por Uber, Spotify, Slack, DigitalOcean.

### Aula 3 — Dashboards e Visualizações com Grafana
- **Objetivo:** unificar a visualização de múltiplas fontes de monitoramento em um "Single Pane of Glass".
- **Conceitos-chave:** Data Sources (Prometheus nativo; Zabbix via plugin `alexanderzobnin-zabbix-app`); tipos de painel (Time series, Stat, Gauge, Table, Logs, Node Graph, Zabbix problems); variáveis para dashboards interativos e reutilizáveis.
- **Aplicação prática:** dashboard combinando taxa de requisições .NET (Prometheus) + uso de CPU do host (Zabbix) + lista de problemas ativos (Zabbix) em uma única tela.
- **Tendências:** stack "LGTM" (Loki, Grafana, Tempo, Mimir) para observabilidade completa (métricas + logs + traces); Grafana Cloud; uso do Grafana para BI além de TI.

## Bloco 2 — APMs Corporativos (Datadog e New Relic)

### Aula 4 — Introdução ao APM Datadog
- **Objetivo:** instrumentar aplicações .NET/Node.js com o Agent do Datadog.
- **Conceitos-chave:** modelo **sidecar** (instrumentação desacoplada do host da aplicação, útil em produção); rastreamento distribuído; análise de status codes (2xx/4xx/5xx) e correlação com problemas de negócio.

### Aula 5 — Logs com Datadog
- **Objetivo:** ingestão e troubleshooting de logs no Datadog.
- **Conceitos-chave:** *drop rules*, *log patterns*; níveis de severidade (Debug, Info, Notice, Warning, Error, Critical, Alert, Emergency); 7 tipos de log (sistema, aplicação, segurança, transação, auditoria, evento, erro) e onde cada um é gerado no SO/banco de dados.

### Aula 6 — Infraestrutura com Datadog
- **Objetivo:** monitorar hosts, containers e recursos de nuvem correlacionando com problemas de performance da aplicação.
- **Conceitos-chave:** **Host Maps** (mapa visual colorido por status — cinza/vermelho/laranja/verde); casos de uso de otimização de custo (identificar instâncias AWS subutilizadas); visão de containers (Docker/Kubernetes/ECS/EKS) e integração com clouds (AWS, Azure) via *Resource Catalog*.

### Aula 7 — Introdução ao APM New Relic
- **Objetivo:** conhecer o New Relic e compará-lo ao Datadog.
- **Conceitos-chave:** métrica **Apdex** (satisfação do usuário, de 0 a 1, calculada a partir de solicitações satisfeitas/tolerantes/frustradas com um limiar T configurável); faixas de cor (crítico, laranja, ideal, T alto demais).

### Aula 8 — Logs com New Relic
- **Objetivo:** implementar **Logs in Context** para correlacionar logs com APM, infraestrutura e distributed tracing.
- **Conceitos-chave:** três formas de habilitar logs contextualizados (encaminhamento via agent, decoração via agent de linguagem, ou encaminhador manual); Drop Rules e Log Patterns; caso de uso completo de troubleshooting (do alerta ao runbook).

### Aula 9 — Infraestrutura com New Relic
- **Objetivo:** boas práticas de monitoramento de infraestrutura com New Relic.
- **Conceitos-chave:** instalar o agent em todo o ambiente, integração nativa com EC2 (tags), ativação de integrações prontas (CloudWatch, MySQL, NGINX etc.), visualizações de agrupamento de hosts, condições de alerta baseadas em tags, correlação APM + Infraestrutura, **NRQL** (linguagem de consulta semelhante a SQL).

### Aula 10 — Configurando Alertas (Datadog + New Relic)
- **Objetivo:** boas práticas para alertas confiáveis e acionáveis.
- **Conceitos-chave:** nomenclatura clara de alertas (ex.: `AWS-Instancia01-Prod-SP-CPU-Critical`), categorização e canais de escalonamento (Slack, PagerDuty, Jira), times de primeiro atendimento, **Runbooks**, revisão periódica de alertas, métricas de SRE (**SLI** e **SLO**), automação de alertas via Terraform.

---

## Resumo funcional da categoria

Esta trilha constrói a capacidade de **observar a saúde de um sistema em produção** em duas camadas complementares: (1) a stack open-source **Zabbix + Prometheus + Grafana**, cobrindo infraestrutura (black-box), aplicação (white-box) e visualização unificada; e (2) os **APMs corporativos Datadog e New Relic**, que agregam métricas, logs e infraestrutura em uma única plataforma comercial, incluindo a métrica de satisfação do usuário (**Apdex**) e boas práticas de configuração de **alertas** alinhadas a SLI/SLO. Juntas, essas aulas fundamentam a estratégia de observabilidade exigida no projeto da fase — permitindo detectar, diagnosticar e responder a problemas antes que afetem o usuário final.
