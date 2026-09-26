# Continuidade — Orquestração FCG Fase 2

> **Documento vivo:** registra onde o trabalho parou, o que falta e os links atuais.  
> **Spec completa:** [`specs/prd.md`](prd.md) · **Insumo técnico:** [`Documentos/INSUMO-ORQUESTRACAO.md`](../Documentos/INSUMO-ORQUESTRACAO.md)

| | |
|---|---|
| **Última atualização** | 07/07/2026 01:10 (UTC-3) |
| **Fase atual** | Compose validado ponta a ponta → publicar correções locais, validar Kubernetes e preparar entregáveis acadêmicos |
| **Responsável da continuidade** | Você (Anderson) — ajustes de domínio, testes, vídeo e relatório |

---

## Onde paramos (snapshot)

A **orquestração foi implementada, corrigida localmente e validada via Docker Compose**. O `docker compose build` passou para as 4 imagens, a stack subiu com Postgres + RabbitMQ + 4 serviços e o fluxo e2e foi confirmado: cadastro → e-mail de boas-vindas → login → criação de jogo → compra → pagamento aprovado → jogo na biblioteca → e-mail de confirmação.

**Confirmado agora:** os 4 serviços têm pasta `k8s/` com `deployment.yaml` + `service.yaml`; o `fcg-orchestration/k8s/` tem `Namespace`, `ConfigMap`, `Secret`, RabbitMQ, Postgres e manifestos agregados dos 4 serviços; os 4 serviços têm Dockerfile; `payments` e `notifications` respondem `/health`; Compose está operacional em `users:8081`, `catalog:8082`, `payments:8083`, `notifications:8084`, RabbitMQ UI em `15672`.

**Correções locais feitas e ainda não publicadas:** `catalog-api` aplica migrations no startup e faz retry do consumer até RabbitMQ ficar pronto; Dockerfiles de `users`, `payments` e `notifications` usam `.NET 10.0` estável; Dockerfile do `notifications-api` aponta para o layout real `NotificationsAPI/src/...`; `payments-api` deixou de depender da sintaxe de extension blocks no registro de DI.

**Ainda não foi feito:** commitar/pushar essas correções locais, atualizar/abrir PRs correspondentes, confirmar/mergear os PRs no GitHub, deploy no Minikube, gravação do vídeo e relatório final.

**Ponto de atenção:** nos repos individuais dos serviços há apenas `Deployment` + `Service`; `ConfigMap` e `Secret` ficam centralizados no `fcg-orchestration`. Isso funciona para a demo agregada, mas pode ser questionado numa leitura literal do enunciado.

---

## Entregue (concluído)

- [x] [`specs/prd.md`](prd.md) — PRD em fases
- [x] [`specs/continuidade.md`](continuidade.md) — este arquivo
- [x] **fcg-payments-api** — `Dockerfile` multi-stage + `/k8s` (branch `feature/orchestration`, force-push)
- [x] **fcg-users-api** — `/k8s` (branch `feature/orchestration`)
- [x] **fcg-catalog-api** — `/k8s` (branch `feature/orchestration`)
- [x] **fcg-notifications-api** — `/k8s` (branch `feature/orchestration`)
- [x] **Repo de orquestração** — compose, `db/init.sql`, `k8s/` agregado, templates, README
- [x] Pull dos 6 repos locais — branches atuais sincronizadas com seus remotes
- [x] Verificação de `/k8s` — 4 serviços com `Deployment` + `Service`; orquestração com `ConfigMap` + `Secret`
- [x] `docker compose config` — sintaxe validada (OK)
- [x] Commits reescritos em PT-BR, **sem** `Co-authored-by: Cursor`
- [x] PRs com título/corpo em PT-BR, **sem** "Made with Cursor"
- [x] Convites enviados ao repo de orquestração (4 pendentes de aceite)
- [x] `dotnet restore` + `dotnet build` dos 4 serviços — OK
- [x] `dotnet build -c Release` dos 4 serviços — OK (apenas 2 avisos de estilo no `notifications-api`)
- [x] `docker compose build` — 4 imagens geradas com sucesso
- [x] `docker compose up -d` — Postgres, RabbitMQ e 4 serviços sobem localmente
- [x] `catalog-api` — migration no startup implementada localmente
- [x] `catalog-api` — retry no consumer de `PaymentProcessedEvent` para não cair se RabbitMQ ainda estiver aquecendo
- [x] Fluxo e2e Compose validado — cadastro, compra, biblioteca e notificações funcionando

---

## Pendente (sua sequência)

### Prioridade alta (bloqueia demo)

| # | Tarefa | Repo | Notas |
|---|--------|------|-------|
| 1 | **Commitar e publicar correções locais** | users, catalog, payments, notifications | Há mudanças não commitadas nos 4 repos de serviço; ver seção "Correções locais" no snapshot |
| 2 | **Atualizar/abrir PRs e mergear** | todos os serviços | `gh` local não está autenticado; confirmar pelo GitHub logado |
| 3 | **Validar Compose após clone limpo ou `docker compose down -v`** | orchestration | A validação passou nesta máquina; ideal repetir em ambiente limpo antes do vídeo |
| 4 | Registrar evidências para vídeo | — | Usar logs de notifications + RabbitMQ UI + biblioteca no catalog |

### Prioridade média

| # | Tarefa | Repo | Notas |
|---|--------|------|-------|
| 5 | Instalar/subir **Minikube** e `kubectl apply -f k8s/` | orchestration | `kubectl` existe, mas Minikube não está instalado; dry-run tentou `localhost:8080` e falhou |
| 6 | Build + `minikube image load` das 4 imagens | cada serviço | Ver README do orchestration |
| 7 | Confirmar **`JwtSettings__SecretKey`** igual em users e catalog nos manifestos finais | catalog + users | Compose validado com a mesma chave; revisar antes do vídeo/k8s |
| 8 | Alinhar **Contracts v4 → v6** | users-api | Fetch indicou remoção da branch remota antiga `chore/upgrade-contracts-6`; verificar se `main` já recebeu ou se precisa novo ajuste |

### Prioridade baixa / entregáveis

| # | Tarefa | Notas |
|---|--------|-------|
| 9 | Endpoint `/health` em users e catalog | Melhora sondas k8s (hoje TCP) |
| 10 | Completar README do notifications | Entregável "README por repo" |
| 11 | Aceitar convites pendentes no repo de orquestração | Carlos, pdelfino0, joao-malvetoni, leoInacioo |
| 12 | Transferir repo de orquestração (opcional) | Para `joao-malvetoni-alta-horizon` se exigido |
| 13 | **Vídeo ≤ 20 min** | Compose, fluxos, manifestos, k8s |
| 14 | **Relatório PDF/TXT** | Grupo, participantes, links |

---

## PRs informados anteriormente (confirmar no GitHub)

> O `gh` local não está autenticado (`gh auth login` pendente). Consulta via API pública retornou 404 para os PRs abaixo, provavelmente por repositórios privados/sem permissão anônima. Confirmar estado no GitHub logado antes de considerar merge pendente ou concluído.

| Repo | PR | Branch | Título |
|------|-----|--------|--------|
| Payments | [#5](https://github.com/joao-malvetoni-alta-horizon/FIAPCloudGames-fase2-PaymentsAPI/pull/5) | `feature/orchestration` | `chore(orquestracao): adicionar Dockerfile e manifestos k8s` |
| Users | [#16](https://github.com/joao-malvetoni-alta-horizon/FIAPCloudGames-fase2-UsersAPI/pull/16) | `feature/orchestration` | `chore(orquestracao): adicionar manifestos k8s` |
| Catalog | [#8](https://github.com/joao-malvetoni-alta-horizon/FIAPCloudGames-fase2-CatalogAPI/pull/8) | `feature/orchestration` | `chore(orquestracao): adicionar manifestos k8s` |
| Notifications | [#29](https://github.com/joao-malvetoni-alta-horizon/FIAPCloudGames-fase2-NotificationsAPI/pull/29) | `feature/orchestration` | `chore(orquestracao): adicionar manifestos k8s` |

---

## Repositórios e links

| Repo local | Remote | Estado |
|------------|--------|--------|
| `fcg-payments-api` | [FIAPCloudGames-fase2-PaymentsAPI](https://github.com/joao-malvetoni-alta-horizon/FIAPCloudGames-fase2-PaymentsAPI) | PR #5 informado; confirmar estado |
| `fcg-users-api` | [FIAPCloudGames-fase2-UsersAPI](https://github.com/joao-malvetoni-alta-horizon/FIAPCloudGames-fase2-UsersAPI) | PR #16 informado; confirmar estado |
| `fcg-catalog-api` | [FIAPCloudGames-fase2-CatalogAPI](https://github.com/joao-malvetoni-alta-horizon/FIAPCloudGames-fase2-CatalogAPI) | PR #8 informado; confirmar estado |
| `fcg-notifications-api` | [FIAPCloudGames-fase2-NotificationsAPI](https://github.com/joao-malvetoni-alta-horizon/FIAPCloudGames-fase2-NotificationsAPI) | PR #29 informado; confirmar estado |
| `fcg-orchestration` | [FIAPCloudGames-fase2-Orchestration](https://github.com/andersonluizpereiradias/FIAPCloudGames-fase2-Orchestration) | `main` publicado |
| `fcg-contracts` | [fcg-contracts](https://github.com/pdelfino0/fcg-contracts) | Fora do escopo de PR |

> **Desvio:** orquestração está em `andersonluizpereiradias` (conta sem permissão para criar repo na org). Transferência: GitHub → Settings → Transfer ownership.

---

## Convites ao repo de orquestração

Enviados com permissão **Write** (pendentes de aceite):

| Usuário | Repositórios em que já colabora |
|---------|----------------------------------|
| [Carlos-Teofilo](https://github.com/Carlos-Teofilo) | users, catalog, payments, notifications |
| [pdelfino0](https://github.com/pdelfino0) | users, catalog, payments, notifications |
| [joao-malvetoni-alta-horizon](https://github.com/joao-malvetoni-alta-horizon) | users, catalog, payments, notifications |
| [leoInacioo](https://github.com/leoInacioo) | payments |

Dono (sem convite): `andersonluizpereiradias`.

---

## Próximo passo imediato (copiar e executar)

```powershell
# 1. Layout esperado (repos irmãos)
# fiap_cloud-games_2/
#   fcg-orchestration/
#   fcg-users-api/
#   fcg-catalog-api/
#   fcg-payments-api/
#   fcg-notifications-api/

# 2. Autenticar GitHub CLI e publicar as correções locais
gh auth login

# 3. Commit/push nos repos alterados:
#    fcg-users-api, fcg-catalog-api, fcg-payments-api, fcg-notifications-api

# 4. Atualizar/abrir PRs e mergear no GitHub

# 5. Subir stack completa
cd fcg-orchestration
cp .env.example .env
docker compose up --build

# 6. Testar cadastro (8081), login, criação de jogo e compra (8082)
# 7. Painel RabbitMQ: http://localhost:15672  (fcg/fcg123)
```

Depois: instalar Minikube, build das imagens, `kubectl apply -f k8s/` (instruções no README do orchestration).

---

## Checklist de aderência (enunciado)

| Requisito | Status |
|-----------|:------:|
| Dockerfile em cada repo (4/4) | Confirmado nas branches locais |
| `/k8s` em cada repo | Confirmado nos 4 serviços (`Deployment` + `Service`) |
| `docker compose up` sobe tudo | Validado localmente |
| ConfigMap + Secret + Deployment | Pronto no `fcg-orchestration`; atenção: ConfigMap/Secret não estão duplicados nos repos de serviço |
| Deploy testado em cluster local | Pendente; sem contexto Kubernetes ativo |
| README orquestração | Feito |
| Vídeo + relatório | Pendente |

---

## Histórico de atualizações

| Data | O que mudou |
|------|-------------|
| 07/07/2026 01:10 | Compose validado ponta a ponta: build das 4 imagens OK, stack `up -d` OK, cadastro/login/criação de jogo/compra/biblioteca/notificações OK. Corrigidos localmente: migration startup e retry RabbitMQ no `catalog-api`, Dockerfiles para `.NET 10.0`, caminho do Dockerfile do notifications e DI do payments compatível com build Docker. Pendência principal virou publicar essas correções, atualizar PRs e validar Minikube. |
| 07/07/2026 00:48 | Pull dos 6 repos feito; branches atuais sincronizadas. Confirmado `/k8s` nos 4 serviços, Dockerfiles 4/4 e manifestos agregados no `fcg-orchestration`. Registrado ponto de atenção: ConfigMap/Secret centralizados e validação k8s pendente por falta de cluster ativo. |
| 07/07/2026 | Criação do documento. Scaffold completo, 4 PRs abertos, repo orchestration publicado, limpeza PT-BR/Cursor, convites enviados, compose validado (sintaxe). |

---

## Como manter este arquivo atualizado

Ao concluir uma tarefa:

1. Marque o item em **Entregue** ou remova de **Pendente**.
2. Atualize **Onde paramos** (1–2 frases).
3. Se mergeou PR, marque na tabela de PRs ou mova para "Merged".
4. Registre a data e o resumo em **Histórico de atualizações**.
5. Altere **Última atualização** no topo.

**Gatilhos para atualizar:** merge de PR · compose/k8s testado com sucesso · correção de migration ou `/health` · vídeo publicado · transferência do repo de orquestração.
