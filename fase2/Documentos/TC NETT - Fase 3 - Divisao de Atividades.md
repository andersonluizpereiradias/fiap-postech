# TC NETT - Fase 3 — Divisão de Atividades

> Este documento organiza a execução do Tech Challenge da Fase 3 (ver `TC NETT - Fase 3.md`) em frentes de trabalho, esclarecendo o que é **obrigatório** e o que é **opcional/alternativo** no enunciado, e atribuindo responsáveis.

## 1. Introdução — o que é obrigatório e o que não é

O desafio pede 5 capacidades novas na arquitetura. Todas as 5 são **obrigatórias como funcionalidade**; a única flexibilidade que o enunciado dá é **qual ferramenta/variante usar** dentro de cada uma. Este grupo já fechou a escolha de ferramenta em cada frente (ver seção 2), então o que resta "em aberto" é só o detalhe de implementação dentro de cada escolha.

### Obrigatório (não pode faltar na entrega)

| # | Funcionalidade | Onde está no enunciado |
|---|---|---|
| 1 | **API Gateway** único, validando JWT e roteando para `UsersAPI` e `CatalogAPI` | Seção "Funcionalidades Obrigatórias > 1" |
| 2 | **Migração do `NotificationsAPI` para Serverless**, disparado por mensagem da fila | Seção "Funcionalidades Obrigatórias > 2" |
| 3 | **Observabilidade** de `UsersAPI` e `CatalogAPI` — métricas de latência, contagem de requisições/status HTTP e taxa de erro, com dashboard | Seção "Funcionalidades Obrigatórias > 3" |
| 4 | **Persistência NoSQL** (dado flexível/alta volumetria) com driver oficial .NET | Seção "Funcionalidades Obrigatórias > 4", marcado explicitamente como **"(Obrigatório)"** |
| 5 | **Cache distribuído** (reduzir round-trip ao banco principal) | Seção "Funcionalidades Obrigatórias > 4", marcado explicitamente como **"(Obrigatório)"** |
| — | Vídeo (≤20 min), repositórios atualizados, `README.md` central de orquestração, relatório de entrega (PDF/TXT) | Seção "Entregáveis da Fase 3" |

### Opcional / alternativas descartadas (não fazer, para não gastar tempo à toa)

| Alternativa não escolhida | Por que descartar |
|---|---|
| Azure API Management / AWS API Gateway | O enunciado marca como "(Opcional) ... para quem desejar explorar". O grupo já optou por **Kong**. |
| Azure Function / Google Cloud Function | Alternativas de Serverless. O grupo já optou por **AWS Lambda**. |
| Datadog / New Relic (Opção B de Observabilidade) | O enunciado pede escolher **uma** das duas opções. O grupo optou pela **Opção A (Prometheus + Grafana)**. Isso também **dispensa** os requisitos exclusivos da Opção B: instrumentar `PaymentsAPI`, enviar logs centralizados e capturar *trace distribuído* do fluxo de compra — nada disso é obrigatório na Opção A. |
| DynamoDB | Alternativa de NoSQL. O grupo já optou por **MongoDB**. |

> **Resumo prático:** ninguém precisa se preocupar com Datadog, DynamoDB, Azure Function/Cloud Function ou gateways gerenciados de nuvem. Foco total nas 4 tecnologias já definidas: Kong, AWS Lambda, Prometheus/Grafana, MongoDB + Redis.

---

## 2. Estrutura da equipe

| Frente | Responsável(is) | Tecnologia definida |
|---|---|---|
| 1. API Gateway | **Carlos Teofilo** | Kong |
| 2. Serverless | **Anderson Dias** | AWS Lambda |
| 3. Observabilidade | **Pedro Delfino / João Pedro** | Prometheus + Grafana |
| 4. Persistência Poliglota (NoSQL + Cache) | **Leonardo** | MongoDB + Redis |

> A tecnologia principal de cada frente já está definida pelo grupo (tabela acima). **Cada responsável decide os detalhes de implementação dentro da sua tecnologia** (ex.: qual plugin do Kong usar, qual biblioteca de instrumentação Prometheus, em qual serviço aplicar o Mongo/Redis) — essas escolhas não precisam de validação prévia do grupo todo, só de alinhamento nos pontos de integração listados na seção 5.

---

## 3. Detalhamento das frentes

### Frente 1 — API Gateway (Kong) · Carlos Teofilo

**Escopo obrigatório que essa frente cobre:**
- Kong como único ponto de entrada externo do sistema.
- Roteamento de requisições para `UsersAPI` e `CatalogAPI`.
- Validação de token JWT no próprio Gateway (antes de chegar aos serviços).
- Manifestos `.yaml` de configuração versionados no repositório `Orchestration`.

**Onde se apoia no que já existe:** o repositório `Orchestration` já tem um `Ingress` (`k8s/30-ingress.yaml`) roteando por hostname para cada serviço. O Kong substitui/absorve esse papel, então dá pra reaproveitar a mesma lógica de hostnames e o padrão de manifestos numerados (`k8s/`).

**Decisões que ficam com essa frente:**
- Kong Ingress Controller vs. Kong DB-less (gateway declarativo) — decisão puramente técnica de implantação.
- Qual plugin de JWT usar (o `kong-plugin-jwt` nativo é o caminho mais direto, já que `UsersAPI` já emite os tokens).

**Ponto de atenção:** o segredo (`JwtSettings__SecretKey`) usado para validar o JWT no Kong precisa ser o **mesmo** já configurado como `Secret` do Kubernetes para `users-api`/`catalog-api` — não é um valor novo a inventar.

---

### Frente 2 — Serverless (AWS Lambda) · Anderson Dias

**Escopo obrigatório que essa frente cobre:**
- Migrar o `NotificationsAPI` (hoje um container sempre ativo) para uma função Lambda.
- Configurar o trigger da função diretamente pela fila/tópico de mensageria (hoje RabbitMQ), eliminando o container 24/7.
- Repositório próprio com o código da função **e** infraestrutura como código (Terraform, SAM ou equivalente).

**Pontos de atenção específicos (levantados nesta conversa):**
- **Cadastro AWS exige cartão de crédito/débito**, mesmo no plano gratuito — diferente do Azure, a AWS não tem uma via "sem cartão" para estudantes. O Lambda tem tier gratuito permanente (1 milhão de requisições + 400.000 GB-s/mês), então o uso do projeto não deve gerar cobrança, mas o cartão precisa estar cadastrado.
- **RabbitMQ como trigger:** o Lambda suporta RabbitMQ self-managed como *event source* (via *Event Source Mapping*), mas isso exige que o broker esteja acessível pela AWS (rede/credenciais configuradas) — vale mapear isso cedo, é o ponto mais arriscado tecnicamente desta frente.
- **Desenvolvimento local recomendado via LocalStack** (emula Lambda + filas localmente, sem custo e sem depender da conta AWS o tempo todo). O deploy real na AWS fica reservado para a demonstração final em vídeo, evitando qualquer custo residual durante o desenvolvimento.
- **O que fazer com o `notificationsdb`:** hoje o `notifications-api` grava em um banco PostgreSQL próprio (`ConnectionStrings__DefaultConnection` no `docker-compose.yml`). Uma Lambda acessando esse Postgres dentro do cluster local é complexo (exigiria expor o banco). Duas saídas simples: (a) a função só registra log, sem persistir, ou (b) o histórico de notificações passa a ser persistido no NoSQL da Frente 4 — combinar essa decisão com o Leonardo.

---

### Frente 3 — Observabilidade (Prometheus + Grafana) · Pedro Delfino / João Pedro

**Escopo obrigatório que essa frente cobre:**
- Instrumentar `UsersAPI` e `CatalogAPI` para expor métricas no formato Prometheus.
- Dashboard no Grafana mostrando: latência de requisições, contagem de requisições (total e por status HTTP) e taxa de erros.
- Deploy da stack (Prometheus + Grafana) via manifestos Kubernetes no repositório `Orchestration`.
- Documentar a stack escolhida no `README.md` de orquestração.

**Sugestão de divisão entre os dois responsáveis** (a definir entre eles):
- Uma pessoa instrumenta os serviços (adicionar `prometheus-net` ou equivalente em `UsersAPI` e `CatalogAPI`, expor `/metrics`).
- A outra sobe a stack (manifestos do Prometheus/Grafana) e monta o dashboard.
- Ambos revisam juntos o resultado final antes da gravação do vídeo.

**Não é necessário para esta frente** (por ter escolhido Opção A, não B): instrumentar `PaymentsAPI`, capturar logs centralizados de aplicação, ou montar trace distribuído do fluxo de compra.

---

### Frente 4 — Persistência Poliglota: NoSQL (MongoDB) + Cache (Redis) · Leonardo

**Escopo obrigatório que essa frente cobre:**
- **NoSQL:** implementar MongoDB para um dado flexível ou de alta volumetria (ex.: catálogo expandido, avaliações de jogos, logs de eventos ou perfis de usuário), usando o driver oficial `MongoDB.Driver`.
- **Cache:** implementar Redis via `StackExchange.Redis` ou `IDistributedCache`, para reduzir round-trip ao banco principal (sessões, consultas onerosas ou configurações globais).

**Por que as duas coisas ficam com a mesma pessoa:** o próprio enunciado agrupa NoSQL e Cache num único item ("Persistência Poliglota e Alta Performance"), e ambos são mudanças de código dentro dos microsserviços (não do Gateway nem da infraestrutura de observabilidade) — ver a resposta anterior desta conversa sobre "onde o Redis deve ficar", que mostra que a implementação é sempre a nível de serviço, nunca no Gateway.

**Decisões que ficam com essa frente:**
- Qual serviço recebe o MongoDB e para qual entidade (ex.: `CatalogAPI` para avaliações/catálogo expandido).
- Qual serviço e qual dado recebe o cache (pode ou não ser o mesmo serviço do Mongo).

**Sinergia com a Frente 2:** o enunciado cita "logs de eventos" como cenário válido de NoSQL. Como a Frente 2 vai precisar decidir o destino do banco atual do `NotificationsAPI`, o histórico de notificações é um candidato natural para o MongoDB — resolveria os dois problemas de uma vez. Vale conversar com o Anderson antes de fechar a escolha da entidade.

**Ponto de atenção:** como é a única frente que mexe diretamente no código de domínio dos microsserviços existentes, vale alinhar com quem mantém `UsersAPI`/`CatalogAPI` hoje para não gerar conflito de merge com as mudanças de instrumentação da Frente 3 (ambas tocam nos mesmos repositórios).

---

## 4. Entregáveis compartilhados (não pertencem a uma frente só)

| Entregável | Observação |
|---|---|
| Vídeo (≤20 min) | Precisa de um trecho de cada frente: requisição via Kong, Lambda disparando + logs, dashboard do Grafana, explicação do Mongo/Redis. Sugestão: cada responsável grava/roteiriza a própria parte, e alguém consolida a edição final. |
| `README.md` do repositório `Orchestration` | Vira o "guia central" — cada frente documenta a própria parte (como o próprio enunciado pede: "a escolha da stack de observabilidade deve ser documentada no `README.md`"). Como o repositório de orquestração hoje já é mantido junto com o Gateway e o Kubernetes, faz sentido que **Carlos** (Frente 1) ou **Anderson** (que hoje mantém o repo `Orchestration`, conforme o `README.md` atual) centralize a revisão final, mas o conteúdo de cada seção vem de quem implementou. |
| Relatório de entrega (PDF/TXT) | Nome do grupo, participantes + usernames do Discord, link da documentação, link dos repositórios, link do vídeo. Tarefa rápida, pode ficar com quem consolidar o vídeo. |

---

## 5. Pontos de sincronização entre frentes

Estes são os únicos pontos onde uma frente depende de decisão/trabalho de outra — vale alinhar cedo para não travar no fim do prazo:

1. **Kong (Frente 1) precisa da `JwtSettings__SecretKey`** já usada por `UsersAPI`/`CatalogAPI` — não é uma dependência de código, só de configuração/segredo compartilhado.
2. **Lambda (Frente 2) precisa saber como o RabbitMQ está exposto** hoje no cluster (host, credenciais) para configurar o *event source mapping* — informação que já existe no `README.md`/`ConfigMap` do repositório de orquestração.
3. **Observabilidade (Frente 3) e Persistência (Frente 4) tocam nos mesmos arquivos** de `UsersAPI`/`CatalogAPI` (um adiciona métricas, o outro adiciona Mongo/Redis) — recomenda-se combinar quem sobe o Pull Request primeiro em cada serviço para evitar conflitos de merge.
4. **Frentes 2 e 4 precisam decidir juntas** o destino dos dados de notificação (descartar a persistência ou migrar o histórico para o MongoDB).
5. **Todas as frentes alimentam o mesmo vídeo e o mesmo `README.md`** — definir com antecedência a ordem/tempo de cada parte no vídeo evita estourar os 20 minutos.

---

## 6. Checklist final de cobertura

- [x] API Gateway (Kong) com JWT e roteamento — Frente 1
- [x] Migração do `NotificationsAPI` para Serverless com trigger de fila — Frente 2
- [x] Métricas + dashboard de `UsersAPI`/`CatalogAPI` — Frente 3
- [x] NoSQL obrigatório (MongoDB) — Frente 4
- [x] Cache distribuído obrigatório (Redis) — Frente 4
- [x] Vídeo, repositórios, `README.md` central e relatório de entrega — responsabilidade compartilhada (seção 4)
- [x] Itens opcionais do enunciado explicitamente descartados (seção 1) para não desperdiçar esforço da equipe
