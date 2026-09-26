# Entrega — Orquestração FCG Fase 2

> Resumo do que foi feito, PRs abertos e mensagem para o time.  
> **Última atualização:** 07/07/2026 (UTC-3)

---

## Tabela de entregas

| Aplicação | Branch | PR | O que foi feito | Observação |
|---|---|---|---|---|
| **fcg-orchestration** | `main` | — (push inicial) | `docker-compose.yml`, `db/init.sql`, `.env.example`, manifestos k8s agregados (`Namespace`, `ConfigMap`, `Secret`, RabbitMQ, Postgres, 4 APIs), templates e README | Repo em `andersonluizpereiradias`. Convites enviados ao time (pendentes de aceite). Compose validado e2e localmente |
| **fcg-users-api** | `feature/orchestration` | [#16](https://github.com/joao-malvetoni-alta-horizon/FIAPCloudGames-fase2-UsersAPI/pull/16) | `/k8s` (`Deployment` + `Service`, sonda TCP) | Correção local **não publicada**: Dockerfile atualizado para `.NET 10.0` estável. PR ainda precisa merge |
| **fcg-catalog-api** | `feature/orchestration` | [#8](https://github.com/joao-malvetoni-alta-horizon/FIAPCloudGames-fase2-CatalogAPI/pull/8) | `/k8s` (`Deployment` + `Service`, sonda TCP) | Correções locais **não publicadas**: `MigrateAsync()` no startup + retry do consumer RabbitMQ. Essencial para demo Compose/k8s |
| **fcg-payments-api** | `feature/orchestration` | [#5](https://github.com/joao-malvetoni-alta-horizon/FIAPCloudGames-fase2-PaymentsAPI/pull/5) | Dockerfile multi-stage + `/k8s` (sonda HTTP `/health`) | Correções locais **não publicadas**: Dockerfile `.NET 10.0` + ajuste de DI para build Docker. PR ainda precisa merge |
| **fcg-notifications-api** | `feature/orchestration` | [#29](https://github.com/joao-malvetoni-alta-horizon/FIAPCloudGames-fase2-NotificationsAPI/pull/29) | `/k8s` (`Deployment` + `Service`, sonda HTTP `/health`) | Correção local **não publicada**: caminho correto do Dockerfile (`NotificationsAPI/src/...`) + `.NET 10.0`. PR ainda precisa merge |
| **fcg-contracts** | `main` | — | Fora do escopo de orquestração | Sem alterações nesta entrega |
| **Documentação** | — | — | `specs/prd.md`, `specs/continuidade.md`, `.claude/CLAUDE.md` (bootstrap pela continuidade) | Referência operacional do projeto |

### Validações locais

- **Docker Compose:** build + `up` OK; fluxo cadastro → compra → biblioteca → notificações OK
- **Kubernetes:** Minikube instalado, cluster `minikube` criado, 4 imagens buildadas/carregadas, `kubectl apply -f k8s/` executado
- **Pendente:** merge dos PRs, push das correções locais, `gh auth login`, estabilizar todos os pods após Postgres subir, vídeo e relatório

---

## Mensagem para WhatsApp

Copiar e colar no grupo:

```
Pessoal, concluí a parte de orquestração (Docker Compose + Kubernetes) da Fase 2.

✅ O que ficou pronto:
• Repo fcg-orchestration: compose unificado + manifestos k8s (ConfigMap, Secret, RabbitMQ, Postgres e 4 APIs)
• Cada API com /k8s (Deployment + Service); payments também ganhou Dockerfile
• Compose testado ponta a ponta (cadastro, compra, biblioteca e notificações)
• Minikube instalado e manifestos aplicados no cluster local (namespace fcg)

📌 PRs abertos (precisam review/merge):
• Payments #5 | Users #16 | Catalog #8 | Notifications #29
Branch: feature/orchestration

⚠️ Atenções:
• ConfigMap/Secret ficam centralizados no repo de orquestração (não duplicados em cada API)
• Há correções locais ainda não commitadas (catalog migration, Dockerfiles .NET 10, etc.) — vou publicar em seguida
• Aceitem o convite do repo FIAPCloudGames-fase2-Orchestration se ainda não aceitaram

🚀 Como rodar (repos irmãos na mesma pasta):
cd fcg-orchestration
docker compose up --build
(users 8081 | catalog 8082 | payments 8083 | notifications 8084)

Para k8s: ver README do orchestration (minikube start → build/load imagens → kubectl apply -f k8s/)

Links e detalhes: specs/continuidade.md no workspace.
Qualquer dúvida, me chamem.
```
