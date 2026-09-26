# Insumo para a Orquestração — FIAP Cloud Games (Fase 2)

> **Para quem é este documento:** para o desenvolvedor responsável pela parte de **Orquestração Local (Docker Compose)** e **Orquestração com Kubernetes**. Assume experiência forte em client-server (PowerBuilder) e **pouca** experiência em .NET/Docker/Kubernetes. Por isso, além do "o que fazer", ele explica **os conceitos** e **o porquê** de cada decisão.
>
> **Fonte da verdade:** requisitos em `Documentos/TC NETT - Fase 2.md`; parecer técnico em `Documentos/arquitetura-fase-2.md`; padrões didáticos em `Resumos Fase 2/` (principalmente `02-Kubernetes.md` e `01-Docker.md`). Tudo aqui foi conferido contra o **código real** dos repositórios — nada foi inventado. Onde a realidade diverge do parecer de arquitetura, isso está **sinalizado explicitamente**.
>
> | | |
> |---|---|
> | **Gerado em** | 06/07/2026 |
> | **Escopo do leitor** | Orquestração (Compose + Kubernetes) + 5º repositório |
> | **Referência de contratos** | `FiapCloudGames.Contracts v6.0.0` |

---

## Como ler este documento

1. **Parte 1 — Contexto** (5 min): o que é o sistema e como as peças conversam. Leia se você ainda não domina o desenho.
2. **Parte 2 — Diagnóstico**: o que já está pronto e o que **falta** nos requisitos obrigatórios.
3. **Parte 3 — Realidade técnica**: os fatos do código que a orquestração **precisa** respeitar (portas, variáveis, mensageria, bancos). É a parte mais importante para não errar a configuração.
4. **Parte 4 — O 5º repositório**: a decisão de criar o `fcg-orchestration` e o que vai dentro.
5. **Parte 5 — Kubernetes do zero**: os conceitos que você vai usar, explicados com analogias.
6. **Parte 6 — O que você vai construir**: passo a passo, com exemplos concretos e comentados.
7. **Parte 7 — Pendências dos times** que bloqueiam a orquestração.
8. **Parte 8 — Checklist de aderência** aos requisitos (conferido duas vezes).
9. **Glossário**.

---

## Parte 1 — Contexto do projeto (o mínimo para orquestrar bem)

O FIAP Cloud Games (FCG) era um **monólito** (uma aplicação .NET única sobre um PostgreSQL). Na Fase 2 ele foi quebrado em **4 microsserviços independentes**, cada um em seu próprio repositório Git, que conversam **por mensagens assíncronas** (um message broker, o **RabbitMQ**) em vez de chamadas diretas.

> 🏛️ **Analogia com o seu mundo:** no monólito, era como um único `.exe` PowerBuilder falando direto com um banco central. Agora são quatro aplicações separadas que **não se chamam diretamente** — elas soltam "recados" numa fila (RabbitMQ) e quem tem interesse reage. Isso desacopla: se a de pagamentos cair, a de usuários continua funcionando; o recado espera na fila.

### Os quatro serviços + o pacote de contratos

| Serviço (pasta) | Nome no k8s | O que faz | Tem banco? | Expõe REST? |
|---|---|---|:---:|:---:|
| `fcg-users-api` | `users-api` | Cadastro, login (gera JWT), autorização | ✅ PostgreSQL | ✅ Sim |
| `fcg-catalog-api` | `catalog-api` | CRUD de jogos, inicia a compra, biblioteca | ✅ PostgreSQL | ✅ Sim |
| `fcg-payments-api` | `payments-api` | Simula o pagamento (só reage a eventos) | ❌ **Não** | Só `/health` |
| `fcg-notifications-api` | `notifications-api` | "Envia" e-mails (log no console) | ✅ PostgreSQL | Só `/health` |
| `fcg-contracts` | — | Pacote NuGet com as **classes dos eventos** (compartilhado) | — | — |

> ⚠️ **Fato que muda a orquestração:** o `payments-api` **não tem banco de dados** (confirmei no código — ele só referencia o pacote de RabbitMQ, sem Entity Framework). Portanto, **não provisione um banco para pagamentos** no Compose nem no Kubernetes. Só três serviços precisam de PostgreSQL: users, catalog e notifications.

### Como as peças conversam (a "coreografia")

Não há chamada HTTP de um serviço para o outro. Tudo passa pelo **RabbitMQ**. São dois fluxos:

**Fluxo 1 — Cadastro de usuário:**

```
Cliente → (REST) → users-api → grava usuário → publica "UserRegisteredEvent" no RabbitMQ
                                                          │
                                                          ▼
                                             notifications-api consome → "envia" e-mail de boas-vindas (log)
```

**Fluxo 2 — Compra de jogo:**

```
Cliente → (REST) → catalog-api → publica "OrderPlacedEvent"
                                        │
                                        ▼
                                  payments-api consome → simula pagamento → publica "PaymentProcessedEvent"
                                        │
                        ┌───────────────┴───────────────┐
                        ▼                                ▼
                  catalog-api consome              notifications-api consome
                  se Approved → põe o               se Approved → "envia" e-mail
                  jogo na biblioteca                de confirmação (log)
```

> 🏛️ **Por que isso importa para você:** o RabbitMQ é uma **peça de infraestrutura** que a orquestração precisa subir e manter no ar — igual ao banco. Se ele não estiver de pé e acessível pelo nome `rabbitmq`, **nenhum fluxo funciona** e o vídeo de demonstração não sai. RabbitMQ e PostgreSQL são as duas fundações que a sua parte entrega.

---

## Parte 2 — Diagnóstico: o que já está atendido e o que falta

O desafio (`TC NETT - Fase 2.md`) tem quatro blocos de requisitos obrigatórios. Abaixo, o estado real conferido no código.

### 2.1 Placar geral dos requisitos obrigatórios

| # | Requisito obrigatório | Status | Observação |
|---|---|:---:|---|
| 1 | 4 microsserviços, cada um em repositório Git próprio | ✅ | Os 4 repos existem e são independentes |
| 1 | UsersAPI: cadastro + JWT + autorização | ✅ | Funcional; publica evento de cadastro |
| 1 | CatalogAPI: CRUD de jogos + inicia compra | ✅ | Funcional; publica `OrderPlacedEvent` |
| 1 | PaymentsAPI: simula pagamento | ✅ | Funcional; consome pedido, publica resultado |
| 1 | NotificationsAPI: simula e-mail (log) | ✅ | Funcional; consome os dois eventos |
| 2 | Fluxo de cadastro por evento | ✅ | `UserRegisteredEvent` (ver nota abaixo) |
| 2 | Fluxo de compra por eventos | ✅ | Consumer do catalog **corrigido** (bind OK) |
| 2 | Mensageria (RabbitMQ ou Kafka) | ✅ | RabbitMQ (via `RabbitMQ.Client` + pacote próprio) |
| 3 | **Dockerfile em cada repo** | ⚠️ **3 de 4** | **Falta o Dockerfile do `payments-api`** |
| 3 | `docker-compose up` sobe a aplicação completa | ❌ | **Não existe** um compose que suba os 4 serviços juntos |
| 4 | Pasta `/k8s` na raiz de cada repo | ❌ | **Nenhum** repo tem `/k8s` |
| 4 | **Deployments** (sem Pod isolado) | ❌ | Nada de Kubernetes ainda |
| 4 | **ConfigMaps** (config não sensível) | ❌ | Idem |
| 4 | **Secrets** (dados sensíveis) | ❌ | Idem |
| Téc. | .NET 8+ | ✅ | Todos em **.NET 10** |
| Téc. | Dockerfile multi-stage | ✅ (nos 3 que existem) | Padrão SDK→runtime correto |
| Téc. | Comunicação por nome de Service no k8s | ⏳ | Depende dos manifestos (sua parte) |
| Téc. | Deploy testado em cluster local | ❌ | Depende dos manifestos (sua parte) |
| Entr. | README por repo (finalidade + env) | ⚠️ | Bom em payments/users/catalog; **fraco no notifications** |
| Entr. | README principal de orquestração | ❌ | Não existe (vem no 5º repo) |

**Resumo em uma frase:** os **serviços e a mensageria estão prontos e funcionando**; o que falta é **quase tudo da sua área** — o Dockerfile de pagamentos, o compose unificado e **100% do Kubernetes**.

### 2.2 O que já está bom (não precisa refazer)

- **Os 4 serviços compilam, rodam e cumprem seu papel de negócio.** O fluxo de compra ponta a ponta funciona (o bug antigo do consumer do catalog, que impedia a compra de concluir, **já foi corrigido** — a fila agora é vinculada à exchange corretamente).
- **3 Dockerfiles multi-stage** prontos: `users-api`, `catalog-api`, `notifications-api`.
- **Composes locais de desenvolvimento** existem em `users-api` (sobe Postgres + RabbitMQ) e `catalog-api` (sobe Postgres + RabbitMQ + a própria API). Eles servem de **referência**, mas são de dev de cada time — **não** substituem o compose unificado da orquestração.
- **O pacote `fcg-contracts` está publicado (v6.0.0)** e é a fonte única das classes de evento.

### 2.3 O que NÃO está atendido (e de quem é a responsabilidade)

| Pendência | Bloqueia o quê? | De quem é | Entra neste documento? |
|---|---|---|---|
| Dockerfile do `payments-api` | Compose e k8s de pagamentos | Time de pagamentos (ou você entrega o template) | ✅ Parte 6 |
| `docker-compose.yml` unificado | Requisito 3 + demo do vídeo | **Você (orquestração)** | ✅ Parte 6 |
| Pasta `/k8s` em cada repo | Requisito 4 | **Você** (template) + cada time (aplica) | ✅ Parte 6 |
| Deployment/Service/ConfigMap/Secret | Requisito 4 | **Você** | ✅ Partes 5 e 6 |
| README principal de orquestração | Entregável | **Você** | ✅ Parte 6 |
| `users-api` usa Contracts **v4** (resto v6) | Risco de divergência de evento | Time de usuários | ⚠️ Parte 7 |
| README do `notifications-api` fraco | Entregável (README por repo) | Time de notificações | ⚠️ Parte 7 |

> **Nota sobre o nome do evento de cadastro:** o enunciado cita `UserCreatedEvent`, mas o código real (e o pacote de contratos v6) usa **`UserRegisteredEvent`**. Isso é uma decisão dos times de serviço e **não afeta a orquestração** — você não mexe em nomes de evento. Fica só registrado para o relatório final não gerar confusão.

---

## Parte 3 — Realidade técnica que a orquestração precisa respeitar

Esta é a parte que **evita erro de configuração**. Aqui estão os fatos do código — não do parecer teórico. Onde o parecer (`arquitetura-fase-2.md`) diverge da realidade, eu aviso.

### 3.1 Divergência importante: mensageria NÃO usa MassTransit

O parecer de arquitetura recomendava **MassTransit** (uma biblioteca que roteia mensagens pelo tipo da classe). **O código real não usa MassTransit.** Ele usa a biblioteca oficial `RabbitMQ.Client` mais um pacote próprio do grupo (`FiapCloudGames.RabbitMq`), com **exchanges e routing keys nomeados à mão**.

> **Isso é permitido pelo enunciado?** Sim. O requisito diz textualmente: *"Utilize uma biblioteca .NET robusta... como MassTransit **ou** a biblioteca oficial do RabbitMQ.Client"*. Então a implementação está **aderente ao requisito**, apenas divergente do parecer interno. **Não tente "consertar" isso** — para a orquestração, a consequência prática é boa: você não precisa injetar nomes de fila via ConfigMap (os serviços já os definem no código). Você só precisa garantir que o RabbitMQ exista e seja alcançável.

**Topologia real (os serviços criam isso sozinhos ao subir):**

| Exchange (tipo `topic`) | Routing key | Evento | Publicado por | Consumido por |
|---|---|---|---|---|
| `users.exchange` | `user.registered` | `UserRegisteredEvent` | users-api | notifications-api |
| `catalog.exchange` | `order.placed` | `OrderPlacedEvent` | catalog-api | payments-api |
| `payments.exchange` | `payment.status` | `PaymentProcessedEvent` | payments-api | catalog-api + notifications-api |

> **Conclusão para você:** os nomes de exchange/fila são responsabilidade dos serviços (estão fixos no pacote de contratos). A orquestração **não precisa** declará-los. Mesmo assim, o requisito pede que o ConfigMap guarde "nomes de filas/tópicos" — então vamos **documentá-los no ConfigMap** por aderência (ver Parte 6), mesmo que os serviços não os leiam de lá.

### 3.2 Variáveis de ambiente REAIS por serviço

Este é o ponto onde os serviços **divergem entre si** — cada time nomeou as coisas de um jeito. A orquestração precisa injetar **a chave exata que cada serviço lê**. A tabela abaixo veio da leitura dos `appsettings.json` e do código de cada serviço.

> 💡 **Regra de ouro do .NET aqui:** variáveis de ambiente com **dois sublinhados** (`__`) viram seções aninhadas na configuração. Ex.: `ConnectionStrings__DefaultConnection` sobrescreve `ConnectionStrings:DefaultConnection` do `appsettings.json`. E os nomes são **case-insensitive** (`RabbitMq` e `RabbitMQ` são a mesma coisa). É assim que a orquestração controla tudo **sem recompilar** os serviços.

| Variável (chave exata) | users-api | catalog-api | payments-api | notifications-api | Vai em |
|---|:---:|:---:|:---:|:---:|---|
| `ConnectionStrings__DefaultConnection` | ✅ | ✅ | — | ✅ | **Secret** |
| `ConnectionStrings__RabbitMqConnection` (URI `amqp://`) | — | ✅ | — | — | **Secret** |
| `RabbitMq__Host` | ✅ | — | ✅ | ✅ | ConfigMap |
| `RabbitMq__Port` | ✅ | — | ✅ | (default 5672) | ConfigMap |
| `RabbitMq__Username` | ✅ | — | ✅ | ✅ | ConfigMap* |
| `RabbitMq__Password` | ✅ | — | ✅ | ✅ | **Secret** |
| `RabbitMq__VirtualHost` | ✅ | — | ✅ | (default `/`) | ConfigMap |
| `JwtSettings__SecretKey` | ✅ (emite) | ✅ (valida) | — | — | **Secret** |
| `JwtSettings__ExpirationHours` | ✅ | — | — | — | ConfigMap |
| `ASPNETCORE_ENVIRONMENT` | ✅ | ✅ | ✅ | ✅ | ConfigMap |

\* *Usuário do RabbitMQ é pouco sensível; pode ir no ConfigMap. A senha vai no Secret.*

**Os três pontos que mais causam erro (preste atenção):**

1. **O `catalog-api` é a exceção do RabbitMQ.** Ele **não** usa `RabbitMq__Host`. Ele lê **uma connection string única** em `ConnectionStrings__RabbitMqConnection`, no formato `amqp://usuario:senha@rabbitmq:5672`. Os outros três usam `RabbitMq__Host` + `__Username` + `__Password` separados. **Configure cada um do seu jeito.**
2. **O `catalog-api` valida JWT** (ele tem endpoints REST protegidos). Ele precisa da **mesma** `JwtSettings__SecretKey` que o `users-api` usa para assinar. Confirme com o time de catálogo a chave exata que o código lê (o `appsettings.json` dele não traz a seção — provavelmente vem de env). Sem a chave igual, os endpoints protegidos do catálogo recusam o token.
3. **O `payments-api` não tem banco nem JWT.** Só precisa das variáveis de RabbitMQ. Não injete `ConnectionStrings__DefaultConnection` nele.

### 3.3 Portas, health checks e migrations

| Fato | users-api | catalog-api | payments-api | notifications-api |
|---|:---:|:---:|:---:|:---:|
| Porta do container | 8080 | 8080 | 8080 | 8080 |
| Endpoint `/health` | ❌ não tem | ❌ não tem | ✅ tem | ✅ tem |
| Roda migration no startup | ✅ sim | ❌ **não** | — (sem banco) | ✅ sim |
| Dockerfile existe | ✅ | ✅ | ❌ **falta** | ✅ |

**Impacto direto no seu Kubernetes:**

- **Probes (sondas de saúde):** o jeito canônico do k8s checar a saúde é um `GET /health`. Só **payments e notifications** têm esse endpoint. Para **users e catalog**, você tem duas opções: (a) pedir aos times que adicionem um `/health` simples (ideal), ou (b) usar uma **probe TCP** (só checa se a porta 8080 está aberta) enquanto o endpoint não existe. A Parte 6 mostra as duas.
- **Migration do catalog:** o `catalog-api` **não** cria as tabelas sozinho ao subir (os outros criam). No cluster, o Pod vai subir mas quebrar ao acessar o banco. **Sinalize ao time de catálogo** que falta chamar o `MigrateAsync()` no startup — senão o banco dele fica vazio e a compra falha. (É item da Parte 7.)
- **Dockerfile de pagamentos:** sem ele, `payments-api` não vira imagem — logo não sobe no Compose nem no k8s. A Parte 6 traz um template pronto baseado nos Dockerfiles que já funcionam nos outros repos.

### 3.4 Bancos de dados — quem tem o quê

| Serviço | Precisa de Postgres? | Nome de banco no dev | Chave da connection string |
|---|:---:|---|---|
| users-api | ✅ | `fcgdb` | `ConnectionStrings__DefaultConnection` |
| catalog-api | ✅ | `catalogdb` | `ConnectionStrings__DefaultConnection` |
| payments-api | ❌ | — | — |
| notifications-api | ✅ | (a confirmar) | `ConnectionStrings__DefaultConnection` |

**Decisão recomendada (alinhada ao parecer §8):** para o escopo da Fase 2, use **uma única instância PostgreSQL** hospedando **3 bancos separados** (um por serviço). Isso mantém o princípio "um banco por serviço" (bancos logicamente separados, sem compartilhar tabelas) e é **muito mais leve** que subir 3 servidores Postgres. Cada serviço recebe uma connection string apontando para o **seu** banco dentro dessa instância.

---

## Parte 4 — O 5º repositório (`fcg-orchestration`)

### 4.1 A decisão: criar ou não?

O enunciado diz que o 5º repositório é **opcional** ("(Opcional) Se achar melhor, você pode criar um quinto repositório específico para orquestração"). Mas repare no que os **entregáveis** exigem:

- *"Demonstrar a execução dos serviços com docker-compose **a partir do repositório de orquestração**."*
- *"Mostrar os arquivos de manifesto **no repositório de orquestração** (Deployment, Service, ConfigMap, Secret)."*
- *"O link para o repositório de orquestração (só válido para quem criou o quinto repositório)."*

**Decisão: criar o `fcg-orchestration`.** Justificativa (trade-offs explícitos):

| Se criar o 5º repo (recomendado) | Se NÃO criar |
|---|---|
| Um `docker-compose.yml` único enxerga os 4 serviços e a infra — atende o requisito com naturalidade | O compose teria que morar dentro de um dos repos de serviço, "poluindo" um serviço com a responsabilidade dos outros |
| Um lugar só para a base de infra (RabbitMQ, Postgres, ConfigMap, Secret) e o README principal | Manifestos e infra espalhados; difícil demonstrar "kubectl apply -f ." de um ponto único |
| Não fere a autonomia dos serviços | Acopla um serviço a decisões de infra de todos |

> 🏛️ **Analogia:** o `fcg-orchestration` é a "sala de máquinas" do prédio. Cada serviço é um apartamento independente; a sala de máquinas concentra água, luz e elevador (RabbitMQ, banco, configuração) e o manual do prédio (README). Ninguém quer o quadro de energia do prédio dentro de um apartamento específico.

### 4.2 Estrutura proposta do `fcg-orchestration`

Baseada no parecer (§11), ajustada à realidade do código:

```
fcg-orchestration/
├── docker-compose.yml           # sobe RabbitMQ + Postgres(3 bancos) + os 4 serviços
├── .env.example                 # variáveis do Compose (senhas, chave JWT) — SEM valores reais no Git
├── db/
│   └── init.sql                 # cria os 3 bancos (users, catalog, notifications) na 1ª subida
├── k8s/
│   ├── 00-namespace.yaml        # namespace "fcg"
│   ├── 01-configmap.yaml        # config não sensível (hosts, env, nomes de fila)
│   ├── 02-secret.yaml           # senhas, connection strings, chave JWT (exemplo; não commitar real)
│   ├── 10-rabbitmq.yaml         # Deployment + Service do broker
│   ├── 11-postgres.yaml         # Deployment + Service + PVC do banco
│   ├── 20-users-api.yaml        # Deployment + Service
│   ├── 21-catalog-api.yaml      # Deployment + Service
│   ├── 22-payments-api.yaml     # Deployment + Service (sem banco)
│   └── 23-notifications-api.yaml# Deployment + Service
├── templates/
│   ├── Dockerfile.template      # modelo multi-stage entregue aos times
│   └── k8s-service.template.yaml# modelo da pasta /k8s de cada serviço
└── README.md                    # como rodar com Docker e como fazer deploy no k8s
```

> **Sobre o requisito "pasta `/k8s` em cada repo":** o enunciado é explícito que **cada repositório de serviço** tem sua `/k8s` na raiz. Então o fluxo é: você cria os **templates** e o **Deployment/Service de cada serviço**, e cada time coloca a `/k8s` no seu repo. A orquestração mantém uma **cópia agregada** desses manifestos (a pasta `k8s/` acima) para permitir o `kubectl apply -f .` único da demonstração. Assim você atende **os dois**: "/k8s por repo" (requisito literal) e "aplicar tudo de um lugar" (demo do vídeo).

---

## Parte 5 — Kubernetes do zero (só o que você vai usar)

Antes do passo a passo, os conceitos. Se algo aqui ficar raso, o `Resumos Fase 2/02-Kubernetes.md` aprofunda cada tópico.

### 5.1 A virada de chave: declarativo, não imperativo

No mundo PowerBuilder/scripts, você descreve **os passos**: "suba o servidor, configure o balanceador, copie os arquivos". No Kubernetes, você descreve **o resultado desejado** num arquivo YAML — *"quero 2 réplicas desta imagem, na porta 8080, com estas variáveis"* — e o cluster **trabalha sozinho** para a realidade bater com essa declaração. Se um contêiner morre, o cluster sobe outro **sem você pedir**. Isso se chama **loop de reconciliação** e é a origem da "autocura".

> 🏛️ É a diferença entre "rodar um INSERT na mão" e "ter o script versionado no Git": o YAML é reproduzível, revisável e descreve o estado completo. Todo o seu trabalho será escrever esses YAMLs e aplicá-los com `kubectl apply`.

### 5.2 Os 5 objetos que você precisa dominar (e só esses)

O enunciado exige **Deployment, ConfigMap e Secret**, e o **Service** é o que viabiliza a comunicação. São 5 peças no total:

| Objeto | O que é | Analogia | Você usa para |
|---|---|---|---|
| **Pod** | A menor unidade; "roda" 1 contêiner (sua API) | Um processo rodando | Você quase não mexe direto — quem cria é o Deployment |
| **Deployment** | Garante que N réplicas do Pod estejam vivas; faz update sem downtime | O "cluster com failover automático" que você montava na mão | Rodar cada serviço (**obrigatório** pelo enunciado) |
| **Service** | Dá um **nome/IP fixo** para um grupo de Pods e balanceia carga | O "VIP do balanceador" | Um serviço achar o outro pelo nome (ex.: `rabbitmq`, `postgres`) |
| **ConfigMap** | Guarda configuração **não sensível** (chave-valor) | O `.ini`/tabela de parâmetros, mas central e desacoplado da imagem | Host do RabbitMQ, ambiente, nomes de fila |
| **Secret** | Igual ao ConfigMap, mas para **dados sensíveis** (senhas, chave JWT) | Um cofre (com ressalvas — ver abaixo) | Connection strings, senha do banco/broker, chave JWT |

> ⚠️ **Secret não é criptografia.** Por padrão o Secret é só **base64** (codificação, não segredo). Serve para o requisito e para separar sensível de não sensível, mas **nunca** faça commit de um Secret com valores reais no Git. Em produção real, usa-se cofre externo (Key Vault) — fora do escopo da Fase 2.

### 5.3 Como um serviço acha o outro: DNS interno

Dentro do cluster, **todo Service vira um nome DNS**. Se você criar um Service chamado `rabbitmq`, qualquer Pod pode conectar em `rabbitmq:5672` — o cluster resolve o nome para o Pod certo, mesmo que o Pod morra e renasça com outro IP. É por isso que as variáveis apontam para `Host=rabbitmq` e `Host=postgres`: **esses são os nomes dos Services que você vai criar**, não endereços fixos.

> Isto atende diretamente o requisito técnico: *"os serviços devem se comunicar dentro do cluster utilizando seus nomes de Service"*. No FCG, a comunicação entre serviços é via **RabbitMQ** (não HTTP direto), mas o mesmo mecanismo de DNS é o que faz cada serviço achar o **broker** e o **banco** pelo nome.

### 5.4 Probes (sondas de saúde) — o par do Deployment

O cluster precisa saber se seu Pod está **vivo** e **pronto**:

- **livenessProbe** — "está vivo?" Se falhar, o k8s **reinicia** o Pod. Cuidado: **não** cheque banco/broker aqui, senão uma piscada do banco reinicia tudo em cascata.
- **readinessProbe** — "está pronto para receber tráfego?" Se falhar, o Pod sai do balanceador **sem** ser morto (útil enquanto sobe).

Como só payments/notifications têm `/health`, para users/catalog você começa com **probe TCP** (checa se a porta 8080 responde) — mostrada na Parte 6. É suficiente para a entrega; refine depois.

### 5.5 O que fica FORA do seu escopo (não caia na tentação)

O `Resumos 02-Kubernetes.md` ensina AKS (Azure), HPA (autoescala), Ingress, CI/CD, StatefulSet. **Nada disso é exigido pela Fase 2.** O requisito é **cluster local** (Minikube/Kind/k3d/Docker Desktop) com Deployment + Service + ConfigMap + Secret. Faça o exigido primeiro; o resto é enriquecimento opcional para o vídeo.

---

## Parte 6 — O que você vai construir (passo a passo)

A ordem faz sentido: primeiro fechar as imagens (Docker), depois o Compose (mais simples, valida tudo localmente), e por fim o Kubernetes (que reaproveita as mesmas imagens e variáveis).

### Passo 0 — Coletar o "contrato de plataforma" dos times

Antes de escrever YAML, confirme com cada time (Parte 7 tem o checklist do que cobrar). O essencial: nome do serviço, porta (8080 para todos), variáveis que lê e eventos que publica/consome. **Sem isso, você configura errado.**

### Passo 1 — Fechar o Dockerfile que falta (`payments-api`)

O `payments-api` não tem Dockerfile. Use este template (espelhado no Dockerfile que já funciona no `users-api`, multi-stage como o requisito exige). Ele vai na **raiz** do repo `fcg-payments-api`:

```dockerfile
# ETAPA 1 — build: usa o SDK (pesado, tem compilador) para compilar e publicar
FROM mcr.microsoft.com/dotnet/sdk:10.0 AS build
WORKDIR /src

# Copia só os .csproj primeiro para aproveitar cache de camadas no restore
COPY src/FCG.Domain/FCG.Domain.csproj src/FCG.Domain/
COPY src/FCG.Application/FCG.Application.csproj src/FCG.Application/
COPY src/FCG.Infrastructure/FCG.Infrastructure.csproj src/FCG.Infrastructure/
COPY src/FCG.API/FCG.API.csproj src/FCG.API/
RUN dotnet restore src/FCG.API/FCG.API.csproj

# Agora copia o resto do código e publica em Release
COPY src/ src/
RUN dotnet publish src/FCG.API/FCG.API.csproj -c Release -o /app/publish

# ETAPA 2 — runtime: imagem enxuta, só o necessário para RODAR (sem compilador)
FROM mcr.microsoft.com/dotnet/aspnet:10.0 AS runtime
WORKDIR /app
COPY --from=build /app/publish .
EXPOSE 8080
ENTRYPOINT ["dotnet", "FCG.API.dll"]
```

> **Por que multi-stage?** A etapa `build` usa o SDK (grande, ~800 MB, com compilador). A etapa `runtime` usa só o `aspnet` (enxuto). O `COPY --from=build` traz **apenas o resultado compilado** para a imagem final — que fica pequena e segura (sem o compilador nem o código-fonte). Isso é exatamente o "otimizado para produção" que o requisito pede.

> ⚠️ **Confirme com o time de pagamentos** o nome exato dos projetos (`FCG.API.dll` etc.) — a estrutura de pastas do repo confirma `src/FCG.API`, mas valide antes de commitar.

### Passo 2 — O `docker-compose.yml` unificado

Este arquivo é o coração do requisito 3: **`docker-compose up` sobe tudo**. Ele vai na raiz do `fcg-orchestration`. Sobe, na ordem: RabbitMQ e Postgres (infra) → e só depois os 4 serviços (com `depends_on` + healthcheck, para não subir uma API antes do banco/broker estarem prontos).

```yaml
services:
  # ---------- INFRAESTRUTURA ----------
  rabbitmq:
    image: rabbitmq:3-management
    environment:
      RABBITMQ_DEFAULT_USER: fcg
      RABBITMQ_DEFAULT_PASS: fcg123
    ports:
      - "5672:5672"     # AMQP (os serviços conectam aqui)
      - "15672:15672"   # painel web http://localhost:15672 (fcg/fcg123)
    healthcheck:
      test: ["CMD", "rabbitmq-diagnostics", "-q", "ping"]
      interval: 10s
      timeout: 5s
      retries: 10

  postgres:
    image: postgres:16-alpine
    environment:
      POSTGRES_USER: fcg
      POSTGRES_PASSWORD: fcg123
      POSTGRES_DB: fcgdb            # banco do users; os outros vêm do init.sql
    ports:
      - "5432:5432"
    volumes:
      - pgdata:/var/lib/postgresql/data
      - ./db/init.sql:/docker-entrypoint-initdb.d/init.sql:ro
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U fcg"]
      interval: 5s
      timeout: 5s
      retries: 10

  # ---------- SERVIÇOS ----------
  users-api:
    build:
      context: ../fcg-users-api        # ajuste o caminho conforme seu checkout
      dockerfile: src/FCG.API/Dockerfile
    environment:
      ASPNETCORE_ENVIRONMENT: Production
      ConnectionStrings__DefaultConnection: "Host=postgres;Port=5432;Database=fcgdb;Username=fcg;Password=fcg123"
      RabbitMq__Host: rabbitmq
      RabbitMq__Port: "5672"
      RabbitMq__Username: fcg
      RabbitMq__Password: fcg123
      RabbitMq__VirtualHost: "/"
      JwtSettings__SecretKey: "6a8a56f4d31a272d6e2f048f710c9cce45b51aa343fd6f73d8b69f1218eaac56"
      JwtSettings__ExpirationHours: "4"
    ports:
      - "8081:8080"
    depends_on:
      postgres: { condition: service_healthy }
      rabbitmq: { condition: service_healthy }

  catalog-api:
    build:
      context: ../fcg-catalog-api
      dockerfile: src/CatalogAPI.API/Dockerfile
    environment:
      ASPNETCORE_ENVIRONMENT: Production
      ConnectionStrings__DefaultConnection: "Host=postgres;Database=catalogdb;Username=fcg;Password=fcg123"
      ConnectionStrings__RabbitMqConnection: "amqp://fcg:fcg123@rabbitmq:5672"
      JwtSettings__SecretKey: "6a8a56f4d31a272d6e2f048f710c9cce45b51aa343fd6f73d8b69f1218eaac56"
    ports:
      - "8082:8080"
    depends_on:
      postgres: { condition: service_healthy }
      rabbitmq: { condition: service_healthy }

  payments-api:
    build:
      context: ../fcg-payments-api
      dockerfile: src/FCG.API/Dockerfile   # criado no Passo 1
    environment:
      ASPNETCORE_ENVIRONMENT: Production
      RabbitMq__Host: rabbitmq
      RabbitMq__Port: "5672"
      RabbitMq__Username: fcg
      RabbitMq__Password: fcg123
      RabbitMq__VirtualHost: "/"
    ports:
      - "8083:8080"
    depends_on:
      rabbitmq: { condition: service_healthy }   # SEM postgres — pagamentos não tem banco

  notifications-api:
    build:
      context: ../fcg-notifications-api
      dockerfile: NotificationsAPI/src/Notifications.API/Dockerfile
    environment:
      ASPNETCORE_ENVIRONMENT: Production
      ConnectionStrings__DefaultConnection: "Host=postgres;Database=notificationsdb;Username=fcg;Password=fcg123"
      RabbitMq__Host: rabbitmq
      RabbitMq__Username: fcg
      RabbitMq__Password: fcg123
    ports:
      - "8084:8080"
    depends_on:
      postgres: { condition: service_healthy }
      rabbitmq: { condition: service_healthy }

volumes:
  pgdata:
```

Arquivo `db/init.sql` (cria os bancos de catalog e notifications; o `fcgdb` já nasce pelo `POSTGRES_DB`):

```sql
CREATE DATABASE catalogdb;
CREATE DATABASE notificationsdb;
```

> **Pontos que evitam dor de cabeça no Compose:**
> - **`depends_on` com `condition: service_healthy`**: garante que a API só sobe depois que banco/broker passam no healthcheck. Sem isso, a API sobe primeiro, não conecta e entra em loop de erro.
> - **Nomes de host = nomes de serviço**: dentro do Compose, `rabbitmq` e `postgres` são resolvidos automaticamente. É o mesmo conceito de DNS interno do k8s.
> - **Portas `808x:8080`**: à esquerda a porta na sua máquina (para você testar via `localhost:8081`), à direita a porta interna do contêiner (sempre 8080). Entre si, os serviços usam a rede interna.
> - **Catalog é diferente**: repare que ele recebe `ConnectionStrings__RabbitMqConnection` (URI), enquanto os outros recebem `RabbitMq__Host`. Não é erro — é a realidade do código (Parte 3.2).
> - **`.env.example`**: numa entrega caprichada, mova senhas/chave JWT para um `.env` e referencie com `${VAR}`. Deixe um `.env.example` sem valores reais no Git.

Validação do Passo 2:

```bash
docker-compose up --build         # sobe tudo
docker-compose ps                 # todos "healthy"/"running"?
# painel do RabbitMQ: http://localhost:15672  (fcg/fcg123) — veja exchanges/filas surgindo
```

### Passo 3 — Os manifestos do Kubernetes

Agora os YAMLs. Todos entram na pasta `k8s/` do `fcg-orchestration` (cópia agregada) e o Deployment/Service de cada serviço também vira a `/k8s` do repo do serviço. Ordem numerada = ordem de aplicação.

**3.1 — Namespace** (`00-namespace.yaml`). Um namespace isola tudo do projeto (em vez de sujar o `default`):

```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: fcg
```

**3.2 — ConfigMap** (`01-configmap.yaml`) — configuração **não sensível**. Atende o requisito de ConfigMap com "hosts, ambiente e nomes de fila/tópico":

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: fcg-config
  namespace: fcg
data:
  ASPNETCORE_ENVIRONMENT: "Production"
  RabbitMq__Host: "rabbitmq"
  RabbitMq__Port: "5672"
  RabbitMq__Username: "fcg"
  RabbitMq__VirtualHost: "/"
  JwtSettings__ExpirationHours: "4"
  # Nomes de exchange/routing key (documentados por aderência ao requisito;
  # na prática os serviços já os definem no código via fcg-contracts):
  Messaging__UsersExchange: "users.exchange"
  Messaging__CatalogExchange: "catalog.exchange"
  Messaging__PaymentsExchange: "payments.exchange"
```

**3.3 — Secret** (`02-secret.yaml`) — dados **sensíveis**. Use `stringData` (texto puro; o k8s codifica). **Não commite valores reais**:

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: fcg-secrets
  namespace: fcg
type: Opaque
stringData:
  RabbitMq__Password: "fcg123"
  JwtSettings__SecretKey: "6a8a56f4d31a272d6e2f048f710c9cce45b51aa343fd6f73d8b69f1218eaac56"
  # connection strings completas (cada serviço aponta para o SEU banco):
  Users__ConnectionString: "Host=postgres;Port=5432;Database=fcgdb;Username=fcg;Password=fcg123"
  Catalog__ConnectionString: "Host=postgres;Database=catalogdb;Username=fcg;Password=fcg123"
  Catalog__RabbitMqConnection: "amqp://fcg:fcg123@rabbitmq:5672"
  Notifications__ConnectionString: "Host=postgres;Database=notificationsdb;Username=fcg;Password=fcg123"
```

**3.4 — RabbitMQ** (`10-rabbitmq.yaml`) — Deployment + Service. O Service chamado `rabbitmq` é o que dá o DNS interno:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: rabbitmq
  namespace: fcg
spec:
  replicas: 1
  selector:
    matchLabels: { app: rabbitmq }
  template:
    metadata:
      labels: { app: rabbitmq }
    spec:
      containers:
        - name: rabbitmq
          image: rabbitmq:3-management
          env:
            - name: RABBITMQ_DEFAULT_USER
              value: "fcg"
            - name: RABBITMQ_DEFAULT_PASS
              value: "fcg123"
          ports:
            - containerPort: 5672
            - containerPort: 15672
---
apiVersion: v1
kind: Service
metadata:
  name: rabbitmq
  namespace: fcg
spec:
  selector: { app: rabbitmq }
  ports:
    - name: amqp
      port: 5672
      targetPort: 5672
    - name: management
      port: 15672
      targetPort: 15672
```

**3.5 — PostgreSQL** (`11-postgres.yaml`) — Deployment + Service + PVC (para os dados não sumirem quando o Pod reiniciar). O `init.sql` vira um ConfigMap montado:

```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: postgres-pvc
  namespace: fcg
spec:
  accessModes: ["ReadWriteOnce"]
  resources:
    requests:
      storage: 1Gi
---
apiVersion: v1
kind: ConfigMap
metadata:
  name: postgres-init
  namespace: fcg
data:
  init.sql: |
    CREATE DATABASE catalogdb;
    CREATE DATABASE notificationsdb;
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: postgres
  namespace: fcg
spec:
  replicas: 1
  selector:
    matchLabels: { app: postgres }
  template:
    metadata:
      labels: { app: postgres }
    spec:
      containers:
        - name: postgres
          image: postgres:16-alpine
          env:
            - name: POSTGRES_USER
              value: "fcg"
            - name: POSTGRES_PASSWORD
              value: "fcg123"
            - name: POSTGRES_DB
              value: "fcgdb"
          ports:
            - containerPort: 5432
          volumeMounts:
            - name: data
              mountPath: /var/lib/postgresql/data
            - name: init
              mountPath: /docker-entrypoint-initdb.d
      volumes:
        - name: data
          persistentVolumeClaim:
            claimName: postgres-pvc
        - name: init
          configMap:
            name: postgres-init
---
apiVersion: v1
kind: Service
metadata:
  name: postgres
  namespace: fcg
spec:
  selector: { app: postgres }
  ports:
    - port: 5432
      targetPort: 5432
```

> 🏛️ **Sobre banco no k8s:** rodar Postgres no cluster (como aqui) é aceitável para uma **entrega acadêmica local**. Em produção real, o padrão é banco **gerenciado** (fora do cluster) — o `Resumos 02-Kubernetes.md` explica o porquê (backup, replicação, failover). Para a Fase 2, este Deployment + PVC é suficiente e demonstrável.

**3.6 — Um serviço de aplicação** (`20-users-api.yaml`) — o modelo que se repete para os 4. Repare como ele **puxa** as variáveis do ConfigMap e do Secret:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: users-api
  namespace: fcg
spec:
  replicas: 2                       # 2 réplicas = alta disponibilidade + demonstra escala
  selector:
    matchLabels: { app: users-api }
  template:
    metadata:
      labels: { app: users-api }
    spec:
      containers:
        - name: users-api
          image: fcg/users-api:1.0    # imagem que você buildou (ver nota sobre Minikube)
          ports:
            - containerPort: 8080
          env:
            # não sensível, vindo do ConfigMap:
            - name: ASPNETCORE_ENVIRONMENT
              valueFrom: { configMapKeyRef: { name: fcg-config, key: ASPNETCORE_ENVIRONMENT } }
            - name: RabbitMq__Host
              valueFrom: { configMapKeyRef: { name: fcg-config, key: RabbitMq__Host } }
            - name: RabbitMq__Username
              valueFrom: { configMapKeyRef: { name: fcg-config, key: RabbitMq__Username } }
            - name: JwtSettings__ExpirationHours
              valueFrom: { configMapKeyRef: { name: fcg-config, key: JwtSettings__ExpirationHours } }
            # sensível, vindo do Secret:
            - name: RabbitMq__Password
              valueFrom: { secretKeyRef: { name: fcg-secrets, key: RabbitMq__Password } }
            - name: JwtSettings__SecretKey
              valueFrom: { secretKeyRef: { name: fcg-secrets, key: JwtSettings__SecretKey } }
            - name: ConnectionStrings__DefaultConnection
              valueFrom: { secretKeyRef: { name: fcg-secrets, key: Users__ConnectionString } }
          # PROBES — users-api NÃO tem /health, então usamos probe TCP (porta abre?):
          livenessProbe:
            tcpSocket: { port: 8080 }
            initialDelaySeconds: 20
            periodSeconds: 15
          readinessProbe:
            tcpSocket: { port: 8080 }
            initialDelaySeconds: 10
            periodSeconds: 10
---
apiVersion: v1
kind: Service
metadata:
  name: users-api
  namespace: fcg
spec:
  type: ClusterIP                  # interno ao cluster (padrão). Ver nota de acesso externo.
  selector: { app: users-api }
  ports:
    - port: 8080
      targetPort: 8080
```

**Diferenças ao clonar esse modelo para os outros 3 serviços:**

| Serviço | Muda em relação ao modelo acima |
|---|---|
| `catalog-api` | Troca `ConnectionStrings__DefaultConnection` (key `Catalog__ConnectionString`); **adiciona** `ConnectionStrings__RabbitMqConnection` (key `Catalog__RabbitMqConnection`, do Secret); **remove** as vars `RabbitMq__*` (catalog não as usa); mantém `JwtSettings__SecretKey`. Probe TCP (não tem `/health`). |
| `payments-api` | **Remove** connection string e JWT (não tem banco nem valida token). Mantém só `RabbitMq__*`. Probe pode ser **HTTP `GET /health`** (ele tem esse endpoint). |
| `notifications-api` | Connection string com key `Notifications__ConnectionString`; `RabbitMq__*`; **sem** JWT. Probe **HTTP `GET /health`** (tem o endpoint). |

Exemplo de probe HTTP (para payments e notifications, que têm `/health`):

```yaml
          livenessProbe:
            httpGet: { path: /health, port: 8080 }
            initialDelaySeconds: 20
            periodSeconds: 15
          readinessProbe:
            httpGet: { path: /health, port: 8080 }
            initialDelaySeconds: 10
            periodSeconds: 10
```

> **Onde as imagens ficam?** Num cluster local você não tem registro (Docker Hub/ACR). Duas saídas comuns:
> - **Minikube:** `minikube image load fcg/users-api:1.0` carrega a imagem que você buildou localmente para dentro do cluster. Combine com `imagePullPolicy: IfNotPresent` no container.
> - **Kind:** `kind load docker-image fcg/users-api:1.0`.
> - **Docker Desktop K8s:** usa o mesmo daemon Docker, então a imagem local já é visível.

### Passo 4 — Subir e validar no cluster local

```bash
# (Minikube) inicia o cluster local de 1 nó
minikube start

# build das 4 imagens (a partir de cada repo) e carga no cluster
docker build -t fcg/users-api:1.0 ../fcg-users-api -f ../fcg-users-api/src/FCG.API/Dockerfile
minikube image load fcg/users-api:1.0
# ... repita para catalog, payments, notifications ...

# aplica TODOS os manifestos de uma vez (a numeração garante a ordem)
kubectl apply -f k8s/

# confere: todos os Pods devem ficar "Running"
kubectl get pods -n fcg
kubectl get deployments,services,configmaps,secrets -n fcg

# se algo não sobe, o melhor amigo:
kubectl describe pod <nome-do-pod> -n fcg     # olhe a seção Events
kubectl logs <nome-do-pod> -n fcg
```

Para acessar uma API de fora do cluster e testar os fluxos, use `port-forward`:

```bash
kubectl port-forward service/users-api 8081:8080 -n fcg    # depois: http://localhost:8081
```

### Passo 5 — README principal + roteiro do vídeo

O `README.md` do `fcg-orchestration` (entregável obrigatório) precisa de:

1. Visão geral do sistema e links dos 4 repos + `fcg-contracts`.
2. **Como rodar com Docker:** `docker-compose up --build` e como testar os fluxos (endpoints, painel do RabbitMQ).
3. **Como fazer deploy no Kubernetes:** pré-requisitos (Minikube), build/carga das imagens, `kubectl apply -f k8s/`, como verificar Pods.
4. Tabela de variáveis de ambiente por serviço (reaproveite a Parte 3.2).

**Roteiro sugerido para o vídeo (≤ 20 min):**

1. Mostrar a estrutura dos repositórios (4 serviços + contracts + orchestration).
2. `docker-compose up` a partir do `fcg-orchestration`; mostrar tudo de pé.
3. Executar o **fluxo de cadastro** (criar usuário → ver o log do e-mail de boas-vindas no notifications).
4. Executar o **fluxo de compra** (iniciar compra → ver pagamento aprovado → jogo na biblioteca → log do e-mail de confirmação).
5. Abrir os manifestos `k8s/` (Deployment, Service, ConfigMap, Secret).
6. `kubectl apply -f k8s/` no cluster local e `kubectl get pods` mostrando tudo `Running`.

---

## Parte 7 — Pendências dos times que bloqueiam você

Estas ações **não são suas**, mas travam a orquestração se não forem feitas. Cobre cada time:

| # | Pendência | Time | Por que bloqueia a orquestração | Prioridade |
|---|---|---|---|:---:|
| 1 | Criar o **Dockerfile** na raiz | pagamentos | Sem imagem, `payments-api` não sobe no Compose nem no k8s (template no Passo 1) | 🔴 Alta |
| 2 | Rodar **migration no startup** (`MigrateAsync()`) | catálogo | O banco do catálogo fica sem tabelas; a compra falha ao gravar na biblioteca | 🔴 Alta |
| 3 | Confirmar a **chave que lê o JWT** (`JwtSettings__SecretKey`?) | catálogo | Você precisa saber o nome exato para injetar o mesmo segredo do users | 🟠 Média |
| 4 | Adicionar endpoint **`/health`** | users e catálogo | Permite probe HTTP no k8s (sem isso, fica só probe TCP) | 🟡 Baixa |
| 5 | Atualizar **Contracts v4 → v6** | usuários | Alinha o contrato de evento com os demais (evita divergência futura) | 🟠 Média |
| 6 | Completar o **README** (finalidade + env) | notificações | Entregável obrigatório "README por repo" | 🟡 Baixa |
| 7 | Confirmar **nome do banco** que o notifications espera | notificações | Para acertar a connection string / `init.sql` | 🟠 Média |

> Itens 1 e 2 são **bloqueadores do fluxo de compra na demonstração**. Persiga-os primeiro.

**O que você precisa que cada time confirme (contrato de plataforma):** nome do serviço, porta (8080), lista de variáveis de ambiente que o serviço lê (com o nome exato da chave) e eventos que publica/consome. Com isso, ConfigMap/Secret/Deployment saem sem retrabalho.

---

## Parte 8 — Checklist de aderência aos requisitos (conferido 2×)

Cada linha foi cruzada com o texto de `TC NETT - Fase 2.md`. "Sua entrega" = o que a orquestração produz.

### Requisito 3 — Orquestração Local e de Implantação

| Exigência literal | Como sua entrega cumpre | ✔ |
|---|---|:---:|
| "Cada repositório deve conter seu próprio Dockerfile" | 3 já têm; você entrega o template do 4º (payments) | ✅ |
| "Dockerfiles otimizados com multi-stage" | Template e os existentes são SDK→runtime | ✅ |
| "`docker-compose.yml`... `docker-compose up`" | Compose unificado no `fcg-orchestration` (Passo 2) | ✅ |
| "(Opcional) quinto repositório de orquestração" | Criado: `fcg-orchestration` (Parte 4) | ✅ |

### Requisito 4 — Orquestração com Kubernetes

| Exigência literal | Como sua entrega cumpre | ✔ |
|---|---|:---:|
| "Manifestos em `/k8s` na raiz de cada repo" | Deployment+Service de cada serviço vão na `/k8s` do repo; cópia agregada no orchestration | ✅ |
| "Obrigatório usar **Deployments** (nada de Pod isolado)" | Todos os serviços e infra são Deployments (Passo 3) | ✅ |
| "Obrigatório **ConfigMaps** (config não sensível)" | `01-configmap.yaml`: hosts, ambiente, nomes de exchange | ✅ |
| "Obrigatório **Secrets** (dados sensíveis)" | `02-secret.yaml`: senhas, connection strings, chave JWT | ✅ |
| "Comunicação por **nome de Service**" | Services `rabbitmq`/`postgres`/`*-api`; DNS interno (Parte 5.3) | ✅ |
| "Deploy testado em cluster local" | Minikube + `kubectl apply -f k8s/` + `get pods` (Passo 4) | ✅ |

### Requisitos Técnicos

| Exigência | Situação | ✔ |
|---|---|:---:|
| ".NET 8 ou superior" | Todos em .NET 10 | ✅ |
| "Biblioteca robusta de mensageria (MassTransit **ou** RabbitMQ.Client)" | RabbitMQ.Client + pacote próprio → **aderente** | ✅ |
| "`http://payments-api:80`... nomes de Service" | Services nomeados; comunicação real é via broker (documentado) | ✅ |
| "Cluster local (Kind/Minikube/k3d/Docker Desktop)" | Instruções para Minikube (Passo 4) | ✅ |

### Entregáveis

| Exigência | Situação | ✔ |
|---|---|:---:|
| "README por repo (finalidade + variáveis)" | OK em 3; cobrar notifications (Parte 7) | ⚠️ |
| "README principal de orquestração (Docker + k8s)" | Você entrega (Passo 5) | ✅ |
| "Vídeo ≤ 20 min demonstrando tudo" | Roteiro no Passo 5 | ✅ |
| "Relatório (grupo, participantes, links)" | Documento à parte do grupo | ⏳ |

> **Segunda conferência (divergências e riscos que NÃO invalidam a aderência):**
> 1. Mensageria usa RabbitMQ.Client, não MassTransit — **permitido** pelo enunciado. ✔
> 2. Evento é `UserRegisteredEvent`, não `UserCreatedEvent` — nome interno; requisito pede o *fluxo*, que existe. ✔
> 3. `payments-api` sem banco — correto para o desenho; não fere requisito. ✔
> 4. Comunicação entre serviços é assíncrona (broker), não HTTP por nome de Service — o requisito de "nome de Service" é atendido pela existência dos Services e pelo DNS interno (usado para achar broker/banco). ✔
> 5. Bloqueadores reais para a **demo** (não para a arquitetura): Dockerfile de pagamentos e migration do catálogo (Parte 7, itens 1 e 2).

---

## Glossário rápido

| Termo | Em uma frase |
|---|---|
| **Imagem Docker** | "Pacote congelado" da aplicação pronto para rodar em qualquer lugar |
| **Multi-stage build** | Dockerfile em 2 etapas: uma compila (SDK), outra só roda (runtime enxuto) |
| **docker-compose** | Sobe vários contêineres juntos com um comando, para dev local |
| **Cluster** | Conjunto de máquinas que o Kubernetes gerencia como uma unidade |
| **Pod** | Menor unidade do k8s; roda seu contêiner |
| **Deployment** | Mantém N réplicas do Pod vivas e faz update sem downtime (obrigatório) |
| **Service** | Nome/IP fixo + balanceamento para um grupo de Pods (DNS interno) |
| **ClusterIP** | Service acessível só dentro do cluster (padrão) |
| **ConfigMap** | Configuração não sensível injetada como variável de ambiente |
| **Secret** | Configuração sensível (base64 — não é cofre; nunca commitar valor real) |
| **Probe** | Sonda de saúde: liveness (viva → reinicia) e readiness (pronta → recebe tráfego) |
| **PVC** | Pedido de disco persistente que sobrevive à morte do Pod (usado no Postgres) |
| **Namespace** | Partição lógica do cluster; isola o projeto do `default` |
| **kubectl** | CLI que fala com o cluster (`apply`, `get`, `describe`, `logs`) |
| **Minikube** | Cluster Kubernetes local de 1 nó, para estudo/entrega |
| **DNS interno** | Cada Service vira um nome resolvível (ex.: `rabbitmq`, `postgres`) |
| **Exchange / routing key** | No RabbitMQ, onde a mensagem é publicada e como é roteada às filas |

---

> **Próximo passo sugerido:** se quiser, posso **scaffoldar o repositório `fcg-orchestration`** com os arquivos deste documento já prontos (compose, `init.sql`, os manifestos `k8s/`, o Dockerfile de pagamentos e o README) para você só ajustar caminhos e testar.
