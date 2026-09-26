# 1. Arquitetura de Software & API Gateway

> Categoria 1 de 5 — Classificação dos resumos em PDF da pasta `resumos-fase-3`.
> Disciplinas de origem: **Arquitetura de Sistemas .NET** (módulo de Arquitetura de Software) e **API Gateway**, ambas da Fase 3 do PósTech FIAP.

## Visão geral da fase (contexto)

O documento "11NETT - Capitulo de Projeto - Fase 3" (capítulo de boas-vindas da fase) resume o objetivo geral: depois de colocar microsserviços para rodar em containers/orquestradores (fase anterior), a Fase 3 foca em **como a aplicação lida com dados e execução internamente** — arquitetura hexagonal, Serverless, API Gateway (Kong), NoSQL e Observabilidade (Zabbix/Prometheus/Grafana, Datadog, New Relic). O projeto da fase pede uma solução que combine bancos NoSQL, padrões arquiteturais robustos e monitoramento completo.

---

## Aulas de Arquitetura de Software

### Aula 1 — Introdução à Arquitetura de Software
- **Objetivo:** apresentar o papel do(a) arquiteto(a) de software e a importância de planejar antes de construir.
- **Conceitos-chave:** Clean Architecture (Robert C. Martin), separação de preocupações, responsabilidade única, abstração, simplicidade; Design Patterns (criação, estruturais, comportamentais — Factory, Builder, Singleton, Adapter, Composite, Strategy, Observer etc.); arquitetura em camadas (apresentação, aplicação, persistência).
- **Aplicação prática:** base teórica para justificar decisões de design nas próximas aulas (ex.: por que separar camadas, por que usar padrões conhecidos em vez de soluções ad-hoc).

### Aula 2 — Processo e Modularização
- **Objetivo:** entender o processo de levantamento de requisitos até a modularização de um sistema real (case do sistema "REC" de uma emissora de TV).
- **Conceitos-chave:** modelagem tática e linguagem ubíqua (DDD), entrevista com stakeholders, quebra do sistema em módulos independentes (usuários, canais, redes sociais) com interfaces bem definidas.
- **Aplicação prática:** ajuda a decompor um domínio em módulos coesos antes de codificar, reduzindo acoplamento e facilitando trabalho paralelo de equipes.

### Aula 3 — Documentação, Testabilidade e Modificabilidade
- **Objetivo:** três pilares de qualidade de software: documentar, testar e manter fácil de alterar.
- **Conceitos-chave:** tipos de documentação (uso, desenvolvimento, infraestrutura, arquitetura); Swagger/Redoc para documentar APIs; testabilidade (design modular, instrumentação, dados/ferramentas de teste); modificabilidade (design modular, qualidade de código, documentação atualizada, testes automatizados).
- **Aplicação prática:** checklist para avaliar se um serviço está "pronto para produção" — documentado, testável e fácil de evoluir sem reescrever tudo.

### Aula 4 — Escalabilidade, Disponibilidade e Desempenho
- **Objetivo:** introduzir monitoramento como parte do ciclo de vida da arquitetura e as bases de escalabilidade.
- **Conceitos-chave:** health checks; Zabbix (alertas); Prometheus + Grafana (métricas e dashboards); escalabilidade horizontal com Azure Container Apps (PaaS para Kubernetes); disponibilidade vs. observabilidade; estratégias de cache (página inteira, banco de dados, objeto, sessão, CDN).
- **Aplicação prática:** primeira ponte entre arquitetura e operação — mostra por que observabilidade (aula 5 da categoria de Monitoramento) é indissociável de uma boa arquitetura.

### Aula 5 — Arquitetura Hexagonal
- **Objetivo:** apresentar a Arquitetura Hexagonal (Ports & Adapters), de Alistair Cockburn, como forma de isolar a lógica de negócio de tecnologias externas.
- **Conceitos-chave:** Separation of Concerns (SoC); centro do hexágono (domínio/casos de uso, agnóstico de tecnologia); **portas** (interfaces de entrada e saída) e **adaptadores** (implementações concretas — ex.: Redis vs. cache em memória); **atores condutores** (testes, API, mobile, web) e **atores conduzidos** (repositórios, destinatários); Inversão de Controle (IoC) para resolver a dependência do domínio sobre a infraestrutura.
- **Aplicação prática:** modelo de referência para desenhar a camada de domínio de um serviço de forma testável e independente de banco de dados/framework — essencial se o projeto migrar entre bancos SQL/NoSQL sem reescrever regras de negócio.

---

## Aulas de API Gateway

### Aula 1 — Introdução ao API Gateway
- **Objetivo:** apresentar o conceito de API Gateway (GW) como ponto único de entrada para múltiplas APIs.
- **Conceitos-chave:** consolidação/simplificação de acesso, segurança centralizada, monitoramento, transformação de dados, cache. Exemplo real: gateway centralizado permitiu escalar PODs no Kubernetes durante pico de acesso de um debate presidencial sem impactar o app mobile.
- **Hands-on:** API Gateway simples em .NET Core 7 encaminhando requisições para duas Web APIs fictícias.

### Aula 2 — Introdução ao Azure API Management (APIM)
- **Objetivo:** primeiros passos com o Azure APIM como gateway gerenciado.
- **Conceitos-chave:** Portal do Desenvolvedor, gateways distribuídos globalmente, políticas e transformações, versionamento, segurança, analytics, cache, integração com Azure Functions/Logic Apps/AD.
- **Hands-on:** criação de um recurso APIM no portal Azure e publicação de uma API de exemplo.

### Aula 3 — API Management na Prática
- **Objetivo:** aprofundar o uso prático do APIM.
- **Conceitos-chave:** criação manual de API, políticas de segurança (chave de assinatura), políticas de entrada, monitoramento e alertas, cache de respostas, Portal do Desenvolvedor.
- **Aplicação prática:** roteiro completo (passo a passo no portal Azure) para colocar uma API em produção com segurança básica e observabilidade mínima.

### Aula 4 — Conhecendo o Kong (Konga)
- **Objetivo:** apresentar o Kong API Gateway (open source) e sua interface gráfica alternativa **Konga**.
- **Conceitos-chave:** Kong Manager vs. Konga vs. King (interfaces gráficas para o Kong Admin API); Konga é server-side (login, permissões granulares, snapshots) enquanto King é client-side (sem login).
- **Aplicação prática:** subir a stack Kong + Konga via Docker Compose e gerenciar serviços/rotas/consumers pela UI.

### Aula 5 — Criando Serviços e Rotas (King for Kong)
- **Objetivo:** explorar o King como visualizador de arquitetura baseado em Consumers.
- **Conceitos-chave:** build/run do King via Dockerfile, conexão com o Kong Admin API, geração automática de mapa de dependências entre serviços cadastrados no Kong.
- **Aplicação prática:** útil para visualizar rapidamente como os consumers/serviços de um ecossistema de APIs Kong se relacionam.

### Aula 6 — Consumers e Recursos Enterprise do Kong
- **Objetivo:** conhecer serviços adicionais do Kong e diferenças entre a versão Open Source e Enterprise.
- **Conceitos-chave:** Konnect (plataforma de gerenciamento de ciclo de vida de API na nuvem), Dev Portal, Gateway Manager, Mesh Manager; recursos exclusivos Enterprise (GraphQL→REST, LDAP, RBAC).
- **Aplicação prática:** ajuda a decidir quando a versão Open Source do Kong é suficiente e quando vale migrar para Enterprise/Konnect.

---

## Resumo funcional da categoria

Esta trilha entrega a **fundação arquitetural** de um sistema .NET moderno: como estruturar o código (camadas, hexagonal, DDD tático), como garantir qualidade (documentação, testes, modificabilidade), como escalar e observar a aplicação, e como expor/proteger os serviços por meio de um API Gateway (Azure APIM ou Kong). Combinadas, essas aulas respondem à pergunta "como organizar e expor um conjunto de microsserviços de forma escalável, segura e fácil de manter?" — pré-requisito para as camadas de Serverless, NoSQL e Observabilidade tratadas nos demais documentos.
