# Diagnóstico FCG Fase 2 — Revisão com Contracts
> Gerado em 06/07/2026 · Referência: [`fcg-contracts v6.0.0`](https://github.com/pdelfino0/fcg-contracts)

---

## 1. Mapa dos contratos (`FiapCloudGames.Contracts`)

| Tipo | Namespace | Campos | Exchange / Routing Key |
|---|---|---|---|
| `UserRegisteredEvent` | `FiapCloudGames.Contracts.Users` | `UserId, Name, Email` | `users.exchange` / `user.registered` |
| `OrderPlacedEvent` | `FiapCloudGames.Contracts.Catalog` | `UserId, GameId, Price` | `catalog.exchange` / `order.placed` |
| `PaymentProcessedEvent` | `FiapCloudGames.Contracts.Payments` | `UserId, GameId, Status` | `payments.exchange` / `payment.status` |
| `PaymentStatus` (enum) | `FiapCloudGames.Contracts.Payments` | `Approved=1, Rejected=2` | — |

> **Nota histórica:** `UserCreatedEvent` foi removido (commit `bc717ee`). O evento canônico para cadastro de usuário é `UserRegisteredEvent`.

---

## 2. Versões do pacote referenciadas por serviço

| Serviço | Versão usada | Versão atual no NuGet |
|---|---|---|
| UsersAPI | **4.0.0** | 6.0.0 |
| CatalogAPI | **5.0.0** | 6.0.0 |
| PaymentsAPI | **6.0.0** | 6.0.0 ✅ |
| NotificationsAPI | **6.0.0** | 6.0.0 ✅ |

**v4 → v5 → v6 foram aditivos** (cada versão apenas adicionou novos tipos). Os campos de `UserRegisteredEvent` e `OrderPlacedEvent` não mudaram entre v4 e v6. O risco de quebra silenciosa (namespace/tipo divergente) **não se materializa** neste caso — mas desalinhar versões é dívida técnica que deve ser resolvida antes da entrega.

---

## 3. Auditoria de fluxo de eventos

### 3.1 Fluxo de Cadastro

```
UsersAPI → [UserRegisteredEvent] → notifications.exchange (user.registered) → NotificationsAPI
```

| Passo | Serviço | Implementação | Status |
|---|---|---|---|
| Publica `UserRegisteredEvent` após `Register` | UsersAPI | `RegisterUserUseCase` → `IIntegrationEventPublisher` → `RabbitMqIntegrationEventPublisher` | ✅ |
| Usa `UserMessaging.Exchange` + `UserMessaging.RoutingKeys.Registered` | UsersAPI | Correto | ✅ |
| Consome `UserRegisteredEvent` | NotificationsAPI | `UserRegisteredEventMessageProcessor` via `FiapCloudGames.RabbitMq` | ✅ |
| Queue: `notifications.user-registered` vinculada a `users.exchange/user.registered` | NotificationsAPI | `RabbitMqConsumerDefinition` no DI | ✅ |
| Idempotência (constraint única no `EventId`) | NotificationsAPI | `UniqueViolation → PoisonMessage` | ✅ |
| Admin cria usuário também publica o evento? | UsersAPI | `AdminCreateUserUseCase` — **não verificado** | ⚠️ |

### 3.2 Fluxo de Compra

```
CatalogAPI → [OrderPlacedEvent] → catalog.exchange (order.placed) → PaymentsAPI
PaymentsAPI → [PaymentProcessedEvent] → payments.exchange (payment.status) → CatalogAPI + NotificationsAPI
```

#### CatalogAPI → Publica `OrderPlacedEvent`

| Passo | Implementação | Status |
|---|---|---|
| `InitiateGamePurchase/Handler.cs` publica `OrderPlacedEvent` | Usa `IMessageBus.PublishAsync` com tipo do Contracts | ✅ |
| `RabbitMqMessageBus` declara exchange + publica com routing key correta | `CatalogMessaging.Exchange` + `CatalogMessaging.RoutingKeys.OrderPlaced` | ✅ |
| Verifica se jogo existe e não está na biblioteca antes de publicar | `GetGameAndCheckOwnership` → `409` se já possui | ✅ |

#### PaymentsAPI → Consome `OrderPlacedEvent`, publica `PaymentProcessedEvent`

| Passo | Implementação | Status |
|---|---|---|
| Consumer `OrderPlacedMessageProcessor` registrado via `RabbitMqConsumerDefinition` | Queue `payments.order-placed` vinculada a `catalog.exchange/order.placed` | ✅ |
| Desserializa `OrderPlacedEvent` do Contracts | ✅ | ✅ |
| `ProcessOrderPlacedUseCase` aplica `AlwaysApprovePaymentPolicy` | Sempre aprova (simulação) | ✅ |
| Publica `PaymentProcessedEvent(UserId, GameId, Status)` via `PaymentsMessaging.Exchange` | ✅ | ✅ |

#### CatalogAPI → Consome `PaymentProcessedEvent` — **CRÍTICO ❌**

| Problema | Detalhe |
|---|---|
| **Usa tipo local, não o do Contracts** | `CatalogAPI.Application.Contexts.Libraries.Events.PaymentProcessedEvent` tem campo `Price` extra que **não existe** no `FiapCloudGames.Contracts.Payments.PaymentProcessedEvent`. Ao desserializar, `Price` virá sempre `0`. |
| **Queue não vinculada à exchange** | `PaymentConfirmedConsumer` apenas faz `QueueDeclareAsync("PaymentProcessedEvent")` e `BasicConsumeAsync` — **nunca chama `QueueBindAsync`**. A queue `"PaymentProcessedEvent"` não está vinculada a `payments.exchange/payment.status`. Resultado: mensagens publicadas pelo PaymentsAPI **nunca chegam** ao CatalogAPI. |
| **Usa RabbitMQ.Client raw** | Os outros 3 serviços usam o pacote `FiapCloudGames.RabbitMq` (que encapsula o bind). O CatalogAPI é o único que usa o client raw e implementou incompleto. |

#### NotificationsAPI → Consome `PaymentProcessedEvent`

| Passo | Implementação | Status |
|---|---|---|
| Consumer `PaymentProcessedEventMessageProcessor` via `RabbitMqConsumerDefinition` | Queue `notifications.payment-processed` vinculada a `payments.exchange/payment.status` | ✅ |
| Usa `PaymentProcessedEvent` do Contracts (namespace correto) | ✅ | ✅ |
| Idempotência | `UniqueViolation → PoisonMessage` | ✅ |
| Handler envia email de confirmação simulado | `PaymentProcessedEventHandler` → `EmailService` (log) | ✅ |

---

## 4. Inconsistências de configuração

| Serviço | Variável | Valor em `appsettings.json` | Esperado para Docker/K8s |
|---|---|---|---|
| UsersAPI | `RabbitMq__Host` | `"rabbitmq"` | `rabbitmq` ✅ |
| CatalogAPI | `RabbitMqConnection` | `"amqp://guest:pass@rabbitmq:5672"` | formato connection string (diferente dos outros) ⚠️ |
| PaymentsAPI | `RabbitMq__Host` | `"rabbitmq"` | `rabbitmq` ✅ |
| **NotificationsAPI** | `RabbitMQ__Host` | **`"localhost"`** | `rabbitmq` ❌ |
| NotificationsAPI | `RabbitMQ__Username` | `"guest"` | deve ser `fcg` para consistência ⚠️ |
| CatalogAPI | `ConnectionStrings__DefaultConnection` | `Host=localhost` | `Host=catalog-db` para Docker ❌ |

---

## 5. Infraestrutura de containerização e orquestração

| Artefato | UsersAPI | CatalogAPI | PaymentsAPI | NotificationsAPI |
|---|---|---|---|---|
| `Dockerfile` | ✅ | ✅ | **❌ ausente** | ✅ |
| `docker-compose` (infra local dev) | ✅ (DB + MQ) | ✅ (DB + MQ) | ❌ | ❌ |
| `docker-compose` sobe a própria API | ❌ (comentado — problema de contexto) | ❌ | ❌ | ❌ |
| `k8s/` manifests | ❌ | ❌ | ❌ | ❌ |
| GitHub Actions CI | ✅ | **❌ ausente** | ✅ | ✅ |

### 5º repositório `fcg-orchestration` — **não existe**

Obrigatório pelo enunciado. Deve conter:
- `docker-compose.yml` unificado (4 APIs + 4 bancos + RabbitMQ)
- Manifestos K8s base (`Namespace`, `ConfigMap`, `Secret`)
- README principal do projeto

---

## 6. Outros achados

| Item | Serviço | Situação |
|---|---|---|
| `Class1.cs` placeholder em `Notifications.Application` | NotificationsAPI | ⚠️ arquivo vazio gerado pelo scaffold, deve ser removido |
| `AdminCreateUserUseCase` publica evento? | UsersAPI | ⚠️ não verificado — se admin cria usuário, o evento de boas-vindas deve ser publicado também |
| `CatalogAPI` não faz migration automática no startup | CatalogAPI | ⚠️ UsersAPI e NotificationsAPI chamam `MigrateAsync()`, CatalogAPI não. Banco não evolui sozinho. |
| `JwtSecretKey` hardcoded no `appsettings.json` | UsersAPI | ⚠️ deve vir de Secret K8s / env var em produção |
| README NotificationsAPI | NotificationsAPI | ❌ apenas "Segunda fase da pos tech FIAP" — sem finalidade, endpoints ou variáveis de ambiente |

---

## 7. Priorização de correções

### 🔴 Bloqueadores (quebram o fluxo em runtime)

1. **`PaymentConfirmedConsumer` no CatalogAPI:** adicionar `QueueBindAsync` para vincular a queue à exchange `payments.exchange` com routing key `payment.status`, e trocar o tipo local `PaymentProcessedEvent` pelo do Contracts.
2. **`NotificationsAPI` appsettings.json:** trocar `Host: "localhost"` por `Host: "rabbitmq"`.
3. **`CatalogAPI` `appsettings.json`:** ajustar `ConnectionStrings__DefaultConnection` para apontar para o host do banco no Docker/K8s.

### 🟠 Entregáveis obrigatórios ausentes

4. **Dockerfile do PaymentsAPI** — sem isso o serviço não pode ser containerizado.
5. **`k8s/`** em todos os 4 repositórios (Deployment, Service, ConfigMap, Secret).
6. **Repositório `fcg-orchestration`** com `docker-compose.yml` unificado + manifestos K8s base.

### 🟡 Qualidade e consistência

7. **Alinhar todos os serviços para `FiapCloudGames.Contracts v6.0.0`** (atualizar UsersAPI v4 e CatalogAPI v5).
8. **GitHub Actions CI para CatalogAPI.**
9. **`docker-compose` local para NotificationsAPI e PaymentsAPI** (infra de desenvolvimento).
10. **`CatalogAPI` startup migration** — chamar `MigrateAsync()` ou equivalente.
11. **Remover `Class1.cs`** de `Notifications.Application`.
12. **README do NotificationsAPI** — completar com finalidade, variáveis de ambiente e endpoints.

### 🟢 Entregáveis acadêmicos finais

13. **Vídeo ≤ 20 min** demonstrando os fluxos completos, `docker-compose up`, manifestos K8s e deploy local.
14. **Relatório PDF/TXT** com grupo, participantes, links dos repos e vídeo.

---

## 8. Resumo de risco por serviço

| Serviço | Estado funcional | Risco principal |
|---|---|---|
| **UsersAPI** | ✅ Funcional | Versão desatualizada do Contracts (v4), sem K8s |
| **CatalogAPI** | 🔴 Consumer quebrado em runtime | Queue não vinculada, tipo errado, sem CI, sem K8s |
| **PaymentsAPI** | 🟠 Sem Dockerfile | Não containerizável, sem K8s |
| **NotificationsAPI** | 🟠 Config de RabbitMQ errada | Não conecta ao broker no Docker/K8s |
| **fcg-orchestration** | ❌ Não existe | Entregável obrigatório ausente |
| **fcg-contracts** | ✅ v6.0.0 publicado | Apenas desalinhamento de versão nos consumidores |
