# PRD — Orquestracao FCG Fase 2 (Compose + Kubernetes)

> **Fonte:** `Documentos/INSUMO-ORQUESTRACAO.md` (conferido contra o codigo real dos repositorios) e `Documentos/TC NETT - Fase 2.md` (enunciado oficial).
> **Objetivo deste PRD:** especificar, em fases executaveis, a entrega de **Orquestracao Local (Docker Compose)** e **Orquestracao com Kubernetes**, incluindo o 5o repositorio (`fcg-orchestration`), os ajustes por repositorio e o que e responsabilidade final do usuario.

| | |
|---|---|
| **Gerado em** | 07/07/2026 |
| **Escopo** | Orquestracao (Compose + Kubernetes) + 5o repositorio |
| **Referencia de contratos** | `FiapCloudGames.Contracts v6.0.0` |
| **Convencao de branch** | `feature/orchestration` em cada repo ajustado |
| **Continuidade (documento vivo)** | [`specs/continuidade.md`](continuidade.md) — onde parou, proximos passos, PRs |

---

## 1. Visao geral

O FCG foi quebrado em **4 microsservicos independentes** (`users`, `catalog`, `payments`, `notifications`) que conversam de forma **assincrona via RabbitMQ**, mais um pacote de contratos (`fcg-contracts`). O que **falta** e quase tudo da area de orquestracao:

- Dockerfile do `payments-api` (unico servico sem imagem).
- `docker-compose.yml` unificado (subir os 4 servicos + infra com um comando).
- 100% do Kubernetes (`/k8s` por repo: Deployment, Service, ConfigMap, Secret).
- README principal de orquestracao.

Os servicos e a mensageria **ja funcionam** — nao serao reescritos.

### Repositorios e destinos

| Repo (pasta) | Remote (owner) | Ajuste desta entrega |
|---|---|---|
| `fcg-users-api` | `joao-malvetoni-alta-horizon/FIAPCloudGames-fase2-UsersAPI` | `/k8s` (+ ajustes fora de escopo) |
| `fcg-catalog-api` | `joao-malvetoni-alta-horizon/FIAPCloudGames-fase2-CatalogAPI` | `/k8s` (+ ajustes fora de escopo) |
| `fcg-payments-api` | `joao-malvetoni-alta-horizon/FIAPCloudGames-fase2-PaymentsAPI` | **Dockerfile** + `/k8s` |
| `fcg-notifications-api` | `joao-malvetoni-alta-horizon/FIAPCloudGames-fase2-NotificationsAPI` | `/k8s` (+ README) |
| `fcg-contracts` | `pdelfino0/fcg-contracts` | **Fora de escopo** (owner externo) |
| `fcg-orchestration` | **NOVO** `joao-malvetoni-alta-horizon/FIAPCloudGames-fase2-Orchestration` | Repo novo (compose + k8s + README) |

---

## 2. Escopo e nao-escopo

**No escopo (orquestracao):**
- Dockerfile multi-stage do `payments-api`.
- `docker-compose.yml` unificado + `db/init.sql` + `.env.example`.
- Manifestos Kubernetes (Deployment, Service, ConfigMap, Secret, PVC) para infra e 4 servicos.
- `/k8s` na raiz de cada repo de servico (Deployment + Service).
- Templates (`Dockerfile.template`, `k8s-service.template.yaml`).
- README principal de orquestracao.

**Fora do escopo de orquestracao (documentados na secao 7; "parte final" do usuario):**
- Correcao de migration do `catalog-api` no startup.
- Endpoint `/health` em `users-api` e `catalog-api`.
- Alinhamento de contratos v4 -> v6 no `users-api`.
- Completar README do `notifications-api`.
- Validacao/execucao final (compose e Minikube).

**Nao entra (nao exigido pela Fase 2):** AKS, HPA, Ingress, CI/CD, StatefulSet.

---

## 3. Convencoes de execucao

- **Branch por repo ajustado:** `feature/orchestration` (criada a partir de `main`).
- **PRs curtos e coerentes** (titulo e descricao objetivos). Tabela na secao 6.
- **Um assunto por PR:** cada PR contem o ajuste de orquestracao daquele repo (e, quando aplicavel, o ajuste fora de escopo daquele mesmo repo, sinalizado na descricao).
- **Secrets nunca com valores reais no Git:** usar `stringData` de exemplo / `.env.example`.
- **Porta interna dos containers:** sempre `8080`.

---

## 4. Realidade tecnica que a orquestracao respeita

| Fato | users | catalog | payments | notifications |
|---|:---:|:---:|:---:|:---:|
| Porta do container | 8080 | 8080 | 8080 | 8080 |
| Banco PostgreSQL | Sim (`fcgdb`) | Sim (`catalogdb`) | **Nao** | Sim (`notificationsdb`) |
| `/health` | Nao | Nao | Sim | Sim |
| Migration no startup | Sim | **Nao** | — | Sim |
| Dockerfile | `src/FCG.API/Dockerfile` | `src/CatalogAPI.API/Dockerfile` | **falta** | `NotificationsAPI/src/Notifications.API/Dockerfile` |

**Variaveis de ambiente (chave exata que cada servico le):**

| Variavel | users | catalog | payments | notifications | Vai em |
|---|:---:|:---:|:---:|:---:|---|
| `ConnectionStrings__DefaultConnection` | Sim | Sim | — | Sim | Secret |
| `ConnectionStrings__RabbitMqConnection` (URI `amqp://`) | — | Sim | — | — | Secret |
| `RabbitMq__Host` | Sim | — | Sim | Sim | ConfigMap |
| `RabbitMq__Port` | Sim | — | Sim | (5672) | ConfigMap |
| `RabbitMq__Username` | Sim | — | Sim | Sim | ConfigMap |
| `RabbitMq__Password` | Sim | — | Sim | Sim | Secret |
| `RabbitMq__VirtualHost` | Sim | — | Sim | (`/`) | ConfigMap |
| `JwtSettings__SecretKey` | Sim (emite) | Sim (valida) | — | — | Secret |
| `JwtSettings__ExpirationHours` | Sim | — | — | — | ConfigMap |
| `ASPNETCORE_ENVIRONMENT` | Sim | Sim | Sim | Sim | ConfigMap |

> **Pontos que mais causam erro:** (1) o `catalog-api` usa `ConnectionStrings__RabbitMqConnection` (URI), nao `RabbitMq__Host`. (2) `catalog` e `users` compartilham a **mesma** `JwtSettings__SecretKey`. (3) `payments` nao recebe banco nem JWT.

---

## 5. Desenvolvimento em fases

### Fase 0 — Pre-requisitos
- Autenticar o GitHub CLI: `gh auth login` (necessario para push/PR e para criar o repo novo).
- Confirmar contrato de plataforma com cada time: porta (8080), variaveis lidas e chave JWT exata do catalog.
- Criar a branch `feature/orchestration` em cada repo a ser ajustado.

**Aceite:** `gh auth status` OK; branches criadas.

### Fase 1 — `fcg-payments-api`: Dockerfile + /k8s
- Criar `src/FCG.API/Dockerfile` (multi-stage SDK -> runtime; copia `.csproj` de `FCG.Domain`, `FCG.Application`, `FCG.Infrastructure`, `FCG.API`; `EXPOSE 8080`; `ENTRYPOINT ["dotnet","FCG.API.dll"]`).
- Criar `/k8s/deployment.yaml` e `/k8s/service.yaml` (probe HTTP `GET /health`; sem banco; so vars `RabbitMq__*`).

**Aceite:** `docker build` gera a imagem; manifestos validos.

### Fase 2 — `fcg-orchestration` (repo NOVO)
Estrutura:
```
fcg-orchestration/
├── docker-compose.yml            # RabbitMQ + Postgres(3 bancos) + 4 servicos
├── .env.example                  # senhas/chave JWT (sem valores reais)
├── db/
│   └── init.sql                  # CREATE DATABASE catalogdb; notificationsdb;
├── k8s/
│   ├── 00-namespace.yaml
│   ├── 01-configmap.yaml
│   ├── 02-secret.yaml
│   ├── 10-rabbitmq.yaml
│   ├── 11-postgres.yaml
│   ├── 20-users-api.yaml
│   ├── 21-catalog-api.yaml
│   ├── 22-payments-api.yaml
│   └── 23-notifications-api.yaml
├── templates/
│   ├── Dockerfile.template
│   └── k8s-service.template.yaml
└── README.md
```
- `docker-compose.yml`: infra (rabbitmq `3-management`, postgres `16-alpine` com healthchecks) + 4 servicos com `depends_on: service_healthy`. Portas host `8081..8084 -> 8080`. `catalog` recebe `ConnectionStrings__RabbitMqConnection`; os demais recebem `RabbitMq__*`. `payments` **sem** postgres.
- `k8s/`: namespace `fcg`; ConfigMap (`RabbitMq__Host`, `ASPNETCORE_ENVIRONMENT`, nomes de exchange por aderencia); Secret (`stringData` de exemplo); RabbitMQ e Postgres (com PVC + ConfigMap do `init.sql`); 4 Deployments+Services (2 replicas nos apps; probe TCP em users/catalog, HTTP em payments/notifications).
- README principal com "Como rodar com Docker" e "Como fazer deploy no k8s".

**Aceite:** `docker-compose config` valido; `kubectl apply --dry-run` OK; push inicial no repo novo.

### Fase 3 — `/k8s` nos demais servicos
- `fcg-users-api`, `fcg-catalog-api`, `fcg-notifications-api`: adicionar `/k8s/deployment.yaml` e `/k8s/service.yaml` (copia do modelo agregado, ajustando env por servico). Probe TCP em users/catalog; HTTP em notifications.

**Aceite:** manifestos por repo consistentes com a copia agregada do `fcg-orchestration`.

### Fase 4 — Ajustes fora do escopo de orquestracao
Ver secao 7. Documentados no PRD; implementacao e a **parte final do usuario** (salvo pedido explicito para eu implementar nas branches).

### Fase 5 — Validacao local (parte final do usuario)
```bash
# Docker
docker-compose up --build
docker-compose ps            # todos healthy/running

# Kubernetes (Minikube)
minikube start
# build + load das 4 imagens (fcg/<svc>:1.0) via 'minikube image load'
kubectl apply -f k8s/
kubectl get pods -n fcg      # todos Running
```
Rodar os dois fluxos (cadastro e compra) e gravar o video (<= 20 min).

**Aceite:** fluxos ponta a ponta OK no Compose e no cluster local.

---

## 6. Branches e PRs por repositorio

| Repo | Branch | Titulo do PR | Descricao curta |
|---|---|---|---|
| `fcg-payments-api` | `feature/orchestration` | `chore(orquestracao): adicionar Dockerfile e manifestos k8s` | Dockerfile multi-stage e pasta /k8s (Deployment+Service). |
| `fcg-users-api` | `feature/orchestration` | `chore(orquestracao): adicionar manifestos k8s` | Pasta /k8s (Deployment+Service, sonda TCP). |
| `fcg-catalog-api` | `feature/orchestration` | `chore(orquestracao): adicionar manifestos k8s` | Pasta /k8s (Deployment+Service, sonda TCP). |
| `fcg-notifications-api` | `feature/orchestration` | `chore(orquestracao): adicionar manifestos k8s` | Pasta /k8s (Deployment+Service, sonda HTTP /health). |
| `fcg-orchestration` | `main` (repo novo) | (push inicial) | Compose + k8s agregado + templates + README. |

> PRs mantidos curtos e coerentes. Ajustes fora de escopo entram no mesmo PR do repo correspondente **apenas se o usuario optar por implementa-los**; caso contrario ficam como TODO na secao 7.

---

## 7. Ajustes fora do contexto de orquestracao (e por que)

Esta secao atende o pedido de "explicacao do que foi ajustado fora do contexto da orquestracao e porque". Por padrao, sao a **parte final do usuario** (corrigir o que esta errado/inadequado e implementar o que falta).

| # | Repo | Ajuste | Por que (fora de orquestracao) | Prioridade |
|---|---|---|---|:---:|
| 1 | `catalog-api` | Rodar `MigrateAsync()` no startup | O banco do catalogo sobe **sem tabelas**; a compra falha ao gravar na biblioteca. E bug de dominio, nao de infra, mas **bloqueia a demo**. | Alta |
| 2 | `users-api` + `catalog-api` | Endpoint `/health` | Hoje so ha probe **TCP** no k8s. Adicionar `/health` habilita probe **HTTP** (readiness/liveness reais). Melhoria de aplicacao. | Baixa |
| 3 | `users-api` | Alinhar Contracts v4 -> v6 | `users` usa contratos **v4**; o resto usa **v6**. Divergencia de contrato de evento (dominio), nao de orquestracao. Ja existe branch remota `chore/upgrade-contracts-6`. | Media |
| 4 | `notifications-api` | Completar `README.md` | Entregavel obrigatorio "README por repo (finalidade + variaveis)". Documentacao, nao orquestracao. | Baixa |
| 5 | `catalog-api` | Confirmar/expor `JwtSettings__SecretKey` | Precisa da **mesma** chave do `users` para validar o token nos endpoints protegidos. Config de aplicacao. | Media |

> **Itens 1 e 5 sao bloqueadores do fluxo de compra na demonstracao** — priorize-os.

---

## 8. Checklist de aderencia ao enunciado

### Requisito 3 — Orquestracao Local
- [ ] Dockerfile em cada repo (payments incluso).
- [ ] Dockerfiles multi-stage.
- [ ] `docker-compose up` sobe a stack completa.
- [ ] 5o repositorio de orquestracao criado.

### Requisito 4 — Kubernetes
- [ ] `/k8s` na raiz de cada repo.
- [ ] Somente **Deployments** (sem Pod isolado).
- [ ] **ConfigMaps** (config nao sensivel).
- [ ] **Secrets** (dados sensiveis).
- [ ] Comunicacao por **nome de Service** (DNS interno).
- [ ] Deploy testado em cluster local (Minikube).

### Entregaveis
- [ ] README por repo (cobrar notifications).
- [ ] README principal de orquestracao.
- [ ] Video <= 20 min.
- [ ] Relatorio (grupo, participantes, links).

---

## 9. Resumo do que sera feito (execucao)

1. Criar este `specs/prd.md`.
2. `feature/orchestration` + PR curto em `fcg-payments-api` (Dockerfile + /k8s).
3. Criar repo novo `FIAPCloudGames-fase2-Orchestration` (compose + k8s agregado + templates + README) e push.
4. `feature/orchestration` + PR curto em `fcg-users-api`, `fcg-catalog-api`, `fcg-notifications-api` (/k8s).
5. Documentar ajustes fora de escopo (secao 7) — implementacao e a parte final do usuario.
6. Parte final do usuario: validar Compose + Minikube e gravar o video.

---

## 10. Status da execucao (07/07/2026)

> **Detalhe operacional e sequencia:** ver [`specs/continuidade.md`](continuidade.md) (atualizar apos cada marco).

| Item | Status | Link / observacao |
|---|:---:|---|
| `specs/prd.md` | Feito | Este documento |
| `fcg-payments-api` — Dockerfile + /k8s | PR aberto | https://github.com/joao-malvetoni-alta-horizon/FIAPCloudGames-fase2-PaymentsAPI/pull/5 |
| `fcg-users-api` — /k8s | PR aberto | https://github.com/joao-malvetoni-alta-horizon/FIAPCloudGames-fase2-UsersAPI/pull/16 |
| `fcg-catalog-api` — /k8s | PR aberto | https://github.com/joao-malvetoni-alta-horizon/FIAPCloudGames-fase2-CatalogAPI/pull/8 |
| `fcg-notifications-api` — /k8s | PR aberto | https://github.com/joao-malvetoni-alta-horizon/FIAPCloudGames-fase2-NotificationsAPI/pull/29 |
| Repo de orquestracao | Criado + push | https://github.com/andersonluizpereiradias/FIAPCloudGames-fase2-Orchestration |
| Ajustes fora de escopo (secao 7) | Documentados | Implementacao = parte final do usuario |
| Validacao do `docker-compose.yml` | Feito | `docker compose config` -> OK (sintaxe valida) |
| Validacao k8s + e2e (Compose up + Minikube) | Pendente | Parte final do usuario (Fase 5); Minikube nao instalado nesta maquina |

> **Desvio registrado:** o repo de orquestracao foi criado sob a conta `andersonluizpereiradias` (nao em `joao-malvetoni-alta-horizon`), pois o token disponivel tem permissao de **push** nos repos da org, mas **nao** de criar repositorios nela. Para mover: `Settings -> Transfer ownership` no GitHub, ou recriar sob a conta do dono e dar push do mesmo conteudo.
>
> **PRs:** todos os PRs foram abertos pela conta `andersonluizpereiradias` (colaboradora), com base `main` e head `feature/orchestration`.
