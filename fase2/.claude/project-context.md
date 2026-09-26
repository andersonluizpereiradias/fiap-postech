# Contexto do Projeto — FCG Fase 2 (resumo)

> Snapshot enxuto para bootstrap de sessão. **Não substitui** a documentação completa — consulte sob demanda.

## O que é

**FIAP Cloud Games (FCG):** plataforma de venda de jogos digitais e gestão de biblioteca pessoal.

**Fase 2 (Tech Challenge NETT):** refatorar o monólito da Fase 1 em arquitetura de **microsserviços orientada a eventos**, containerizada (Docker) e orquestrada (Kubernetes). Projeto acadêmico em grupo; entrega obrigatória (90% da nota da fase).

**Evolução:** Fase 1 = monólito .NET em camadas, REST síncrono, um PostgreSQL. Fase 2 = 4 serviços autônomos + mensageria assíncrona + um banco por serviço.

## Problema de negócio

O MVP cadastra usuários e gerencia jogos. Agora a FCG precisa de **fluxo de compra** e **notificações** (e-mail simulado). Pagamentos e e-mails no monólito aumentariam acoplamento e impediriam escala independente.

## Escopo obrigatório (enunciado)

| Área | O que entregar |
|---|---|
| **Microsserviços** | Users, Catalog, Payments, Notifications — cada um em repo Git próprio |
| **UsersAPI** | Cadastro, login JWT, autorização |
| **CatalogAPI** | CRUD de jogos, iniciar compra, biblioteca do usuário |
| **PaymentsAPI** | Simular pagamento (consumidor de eventos) |
| **NotificationsAPI** | Simular e-mails (log no console), somente consumidor |
| **Mensageria** | Fluxos assíncronos via RabbitMQ (decisão do parecer; MassTransit) |
| **Docker** | Dockerfile multi-stage por serviço; `docker-compose up` sobe a stack |
| **Kubernetes** | `/k8s` em cada repo: Deployment, Service, ConfigMap, Secret |
| **Orquestração** | 5º repo opcional/recomendado (`fcg-orchestration`) para infra compartilhada |

## Fluxos de eventos (coreografia)

**Cadastro:** `users-api` cria usuário → publica `UserCreatedEvent` → `notifications-api` envia e-mail de boas-vindas.

**Compra:**
1. `catalog-api` recebe pedido → publica `OrderPlacedEvent` (`UserId`, `GameId`, `Price`, `OrderId`)
2. `payments-api` consome → simula pagamento → publica `PaymentProcessedEvent` (`Approved` | `Rejected`)
3. `catalog-api` consome → se `Approved`, adiciona jogo à biblioteca
4. `notifications-api` consome → se `Approved`, envia e-mail de confirmação

Pagamento rejeitado = **ausência de efeito** (sem Saga/compensação neste escopo).

## Workspace local (este repositório)

```
fcg-users-api/         → cadastro, login JWT, autorização
fcg-catalog-api/       → CRUD de jogos, compra, biblioteca
fcg-payments-api/      → simulação de pagamento (consumidor)
fcg-notifications-api/ → e-mails simulados (consumidor)
fcg-contracts/         → contratos de evento (pacote compartilhado)
fcg-orchestration/     → Docker Compose + k8s base (a consolidar)
Documentos/            → arquitetura, enunciado, diagnóstico, persona
Resumos Fase 2/        → trilha didática (Docker, K8s, microsserviços, messageria)
```

Cada pasta acima é um repositório Git independente (convenção `fcg-*`).

## Stack e convenções (decisões do parecer)

- .NET 10+, Minimal APIs, EF Core, PostgreSQL 16 (1 DB/serviço), JWT HS256
- RabbitMQ + MassTransit; contratos em `FCG.Contracts.Events` (namespace fixo — roteamento MassTransit)
- Porta padrão dos serviços: **8080**; comunicação in-cluster via nome de Service k8s
- Idempotência obrigatória nos consumers (*at-least-once*)

## Kubernetes — ambiente local

- **Runtime:** Minikube (cluster local para desenvolvimento e validação dos manifestos)
- Manifestos em `/k8s` em cada repositório de serviço
- Usar `minikube image load` ou registry interno do Minikube para as imagens Docker locais
- `kubectl` apontado para o contexto `minikube`

## Entregáveis acadêmicos

- Vídeo ≤ 20 min (fluxos completos, docker-compose, manifestos k8s, deploy local)
- Código nos repos + README por serviço (finalidade e variáveis de ambiente)
- Relatório PDF/TXT (grupo, participantes, links de docs/repos/vídeo)

## Documentação completa (ler quando necessário)

| Arquivo | Conteúdo |
|---|---|
| `Documentos/arquitetura-fase-2.md` | Parecer de arquitetura — **fonte da verdade técnica** |
| `Documentos/TC NETT - Fase 2.md` | Enunciado oficial do Tech Challenge |
| `Documentos/monolito-fiap-fase-1.md` | Baseline do monólito (domínio, stack, endpoints) |
| `Documentos/DIAGNOSTICO.md` | Diagnóstico de aderência dos serviços e contratos |
| `Documentos/persona.md` | Persona do arquiteto/backend sênior para sessões de IA |
| `Resumos Fase 2/` | Referência rápida: Docker, K8s, microsserviços, messageria |
