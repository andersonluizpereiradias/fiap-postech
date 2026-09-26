# Contexto do Projeto

> Gerado pela skill `project-code-context`. Mantenha este arquivo atualizado
> sempre que a arquitetura, os padroes, os contratos ou as restricoes do
> repositorio mudarem.

## Resumo do Projeto

FIAP Cloud Games (FCG) — Tech Challenge Fase 3. Este repositorio e um
**workspace agregador** (nao e ele mesmo um repositorio git — nao ha `.git`
na raiz) que reune, como pastas irmas, os repositorios git independentes de
cada microsservico e do repositorio de orquestracao do sistema FCG.

Objetivo da Fase 3: profissionalizar a arquitetura de microsservicos criada
nas Fases 1/2, adicionando:

- API Gateway como ponto unico de entrada (Kong, ou alternativa gerenciada).
- Migracao da `NotificationsAPI` para arquitetura serverless (AWS Lambda via
  SAM), acionada por SQS/SNS em vez de container 24/7.
- Observabilidade (Prometheus+Grafana OU APM gerenciado — o repositorio usa
  **New Relic** para a Lambda de notificacoes).
- Persistencia poliglota: NoSQL obrigatorio (este projeto usa **DynamoDB**
  na `NotificationsAPI`) e cache distribuido (Redis) previsto na
  orquestracao.

O desafio completo (requisitos obrigatorios, entregaveis, criterios) esta
documentado em `documentos/TC NETT - Fase 3.md`.

## Arquivos Fonte de Verdade

- `documentos/TC NETT - Fase 3.md` — enunciado oficial do desafio (requisitos
  obrigatorios e entregaveis da fase).
- `documentos/TC NETT - Fase 3 - Divisao de Atividades.md` — divisao de
  responsabilidades entre os integrantes do grupo.
- `FIAPCloudGames-fase3-Orchestration/README.md` — guia central de como
  clonar, subir via Docker Compose e via Kubernetes (Minikube) todos os
  servicos juntos. **Atencao**: este arquivo tem marcadores de conflito de
  merge nao resolvidos (`<<<<<<< Updated upstream` / `=======` /
  `>>>>>>> Stashed changes`) — precisa ser resolvido manualmente antes de
  confiar 100% no conteudo.
- `FIAPCloudGames-fase3-NotificationsAPI/SDD.md` e
  `FIAPCloudGames-fase3-NotificationsAPI/README.md` — decisao de design da
  migracao para Lambda (API HTTP removida, host novo e a funcao Lambda).
- `.cursor/skills/retomar-fase-3-fiap/STATUS.md` — checklist e estado atual
  (passo a passo) da migracao serverless da `NotificationsAPI` para AWS,
  incluindo ARNs de SNS ja criados e armadilhas conhecidas. Consultar antes
  de retomar trabalho nessa migracao.
- README.md de cada microsservico (`FIAPCloudGames-fase3-<Servico>/README.md`)
  — stack, estrutura de camadas, endpoints e eventos publicados/consumidos
  daquele servico especificamente.

## Stack Tecnologica

- **.NET 10** em todos os microsservicos (Minimal APIs; `CatalogAPI` tambem
  usa Controllers/MediatR).
- **PostgreSQL** (via Npgsql/EF Core) como banco relacional de
  `UsersAPI`, `CatalogAPI` e `PaymentsAPI`.
- **DynamoDB** (AWS SDK v4) como NoSQL obrigatorio da Fase 3, usado pela
  `NotificationsAPI` para persistir notificacoes.
- **RabbitMQ** (pacote NuGet compartilhado `FiapCloudGames.RabbitMq`) como
  mensageria entre os servicos on-premise/Docker/K8s (fluxo original da
  Fase 2, ainda em uso).
- **AWS SNS/SQS + Lambda (via AWS SAM)** como novo caminho de mensageria da
  `NotificationsAPI`, que roda em paralelo ao RabbitMQ (migracao incremental
  — ver Passo 15 em `STATUS.md`: `UsersAPI`/`PaymentsAPI` ainda precisam
  publicar tambem no SNS).
- **`FiapCloudGames.Contracts`** (pacote NuGet externo, repositorio
  `pdelfino0/fcg-contracts`) — classes de evento de integracao
  compartilhadas entre todos os servicos (`UserRegisteredEvent`,
  `OrderPlacedEvent`, `PaymentProcessedEvent`). Serializado em **PascalCase**
  (nao camelCase) pelo `System.Text.Json` padrao — ver armadilha 0 em
  `STATUS.md`.
- **JWT** (`Microsoft.AspNetCore.Authentication.JwtBearer`) para
  autenticacao/autorizacao; emitido pela `UsersAPI` e validado offline
  (chave HMAC compartilhada) pela `CatalogAPI`.
- **BCrypt** para hash de senha (`UsersAPI`).
- **Serilog** para logging estruturado em todos os servicos .NET.
- **Testes**: xUnit + Shouldly + NSubstitute (unitarios); Testcontainers
  (integracao, exige Docker).
- **Observabilidade da Lambda**: OpenTelemetry
  (`OpenTelemetry.Instrumentation.AWSLambda`) exportando para **New Relic**
  (license key gerenciada via AWS Secrets Manager).
- **Kubernetes** (manifestos em `k8s/` de cada repo + agregados em
  `FIAPCloudGames-fase3-Orchestration/k8s/`) e **Docker Compose** como formas
  de orquestracao local/deploy.
- Raiz do workspace agregador tem um `package.json` Node.js so com
  `playwright` como dependencia (usado por scripts auxiliares em
  `scripts/*.mjs`, nao pelos microsservicos).

## Forma da Arquitetura

Microsservicos independentes, cada um em seu proprio repositorio git,
seguindo **Clean Architecture em camadas** (Domain / Application /
Infrastructure / API ou Functions):

| Servico | Papel | Persistencia | Interface |
|---|---|---|---|
| `UsersAPI` | Cadastro, login (JWT), autorizacao | PostgreSQL | REST |
| `CatalogAPI` | CRUD de jogos, compra, biblioteca (CQRS com MediatR, bounded contexts `Games`/`Libraries`) | PostgreSQL | REST |
| `PaymentsAPI` | Simula aprovacao de pagamento (consumidor de eventos + REST auxiliar) | PostgreSQL | REST minima + eventos |
| `NotificationsAPI` | "Envia" e-mails (log estruturado) — **migrando de container para AWS Lambda acionada por SQS/SNS** | DynamoDB | Sem API HTTP (so eventos) |

Comunicacao assincrona entre servicos via eventos de integracao
(RabbitMQ, contratos em `FiapCloudGames.Contracts`), com a `NotificationsAPI`
recebendo tambem um segundo caminho via SNS/SQS/Lambda (AWS) em paralelo,
enquanto a migracao nao e concluida (ver `STATUS.md`).

O repositorio `FIAPCloudGames-fase3-Orchestration` concentra o que e
transversal aos servicos: `docker-compose.yml` agregado, manifestos `k8s/`
agregados, banco `db/init.sql`, e (planejado) API Gateway/observabilidade
open-source/Redis.

## Mapa de Diretorios

```
fiap_cloud-games_3/                          # workspace agregador (SEM .git na raiz)
├── documentos/                               # enunciado do desafio e docs de apoio
├── scripts/                                  # scripts Node (.mjs) auxiliares, nao fazem parte dos servicos
├── .cursor/
│   ├── project-context.md                    # este arquivo
│   └── skills/retomar-fase-3-fiap/           # skill + STATUS.md da migracao serverless
├── FIAPCloudGames-fase3-Orchestration/       # repo git proprio — compose/k8s/db agregados
│   ├── db/ k8s/ observability/ templates/ scripts/
│   └── README.md                             # guia central (tem conflito de merge nao resolvido)
├── FIAPCloudGames-fase3-UsersAPI/            # repo git proprio
│   └── src/{FCG.Domain,FCG.Application,FCG.Infrastructure,FCG.API}
├── FIAPCloudGames-fase3-CatalogAPI/          # repo git proprio
│   └── src/{CatalogAPI.Domain,CatalogAPI.Application,CatalogAPI.Infrastructure,CatalogAPI.API}
├── FIAPCloudGames-fase3-PaymentsAPI/         # repo git proprio
│   └── src/{FCG.Domain,FCG.Application,FCG.Infrastructure,FCG.API}
└── FIAPCloudGames-fase3-NotificationsAPI/    # repo git proprio (raiz = infra serverless: template.yaml, samconfig.toml, events/, local/)
    └── NotificationsAPI/
        └── src/{Notifications.Domain,Notifications.Application,Notifications.Infrastructure,Notifications.Functions}
```

Cada `FIAPCloudGames-fase3-*` e um **repositorio git independente** (tem
`.git` proprio). Mudancas dentro de cada um devem ser commitadas naquele
repo, nao a partir da raiz do workspace agregador.

## Padroes de Implementacao

- Camadas seguem sempre a mesma direcao de dependencia: `Domain` (sem
  dependencias externas) ← `Application` (casos de uso/handlers, DTOs) ←
  `Infrastructure` (EF Core, RabbitMQ, DynamoDB, servicos externos) ←
  `API`/`Functions` (composição, DI, endpoints ou handler Lambda).
- Regras de negocio e invariantes vivem no `Domain`, expostas via exceptions
  especificas (`DomainException` e derivadas) — nao via retorno silencioso
  de erro.
- Erros HTTP sao centralizados num `IExceptionHandler` global (ver
  `CatalogAPI`) que mapeia exceptions de dominio para `ProblemDetails`
  (RFC 7807); handlers de Application nao capturam exceptions para montar
  resposta de erro, apenas lancam.
- Eventos de integracao seguem o padrao publisher/consumer com o pacote
  `FiapCloudGames.RabbitMq`: um `IMessageProcessor`/processor fino na
  Infrastructure delega para um `IEventDispatcher` que resolve o
  `IEventHandler<TEvent>` certo (Application) em um escopo de DI por
  mensagem. Logica de negocio fica sempre no handler de Application, nunca
  no processor.
- Serializacao de eventos deve ser explicita sobre convencao de nomes: os
  contratos de `FiapCloudGames.Contracts` sao PascalCase por padrao; ao
  desserializar manualmente (ex.: `CatalogAPI` consumindo
  `PaymentProcessedEvent`), usar `JsonSerializerDefaults.Web` +
  `JsonStringEnumConverter` para aceitar variacoes de casing/enum.
- Idempotencia em consumidores de evento e tratada explicitamente (ex.:
  `PaymentsAPI` guarda `EventId` unico antes de reprocessar; `CatalogAPI`
  usa unicidade `(UserId, GameId)` para nao duplicar posse de jogo).
- Configuracao por variaveis de ambiente com `__` como separador de secao
  (`ConnectionStrings__DefaultConnection`, `RabbitMq__Host`,
  `JwtSettings__SecretKey`, `DynamoDb__TableName`), sobrepondo
  `appsettings.json`.
- JWT: chave HMAC compartilhada entre `UsersAPI` (emissor) e `CatalogAPI`
  (validador offline); obrigatoria — a aplicacao lanca excecao no startup se
  ausente.
- Testes organizados por camada em pastas dedicadas (`*.Domain.Tests`,
  `*.Application.Tests`, `*.Infrastructure.Tests`, `*.API.Tests` ou
  `*.UnitTests`/`*.IntegrationTests`), com Testcontainers para
  integracao contra Postgres/DynamoDB real.
- Ao adicionar um evento de teste novo para a Lambda de notificacoes, usar
  sempre PascalCase no JSON e publicar via `aws sns publish --message
  file://...` (nunca inline no PowerShell — corrompe aspas).

## Como Estender Features

- Para alterar um microsservico especifico, entrar no seu repositorio
  (`FIAPCloudGames-fase3-<Servico>/`) e seguir a estrutura de camadas
  daquele servico (ver README de cada um para endpoints/eventos atuais).
- Novo caso de uso: adicionar Command/Query ou handler na camada
  `Application` do servico correspondente, reutilizando `IEventHandler`,
  `IEventDispatcher` ou os endpoints Minimal API existentes como modelo.
- Novo evento de integracao: definir o contrato em
  `FiapCloudGames.Contracts` (repositorio externo, versionado via NuGet) —
  nao criar contratos de evento duplicados dentro de um servico.
- Mudancas na infraestrutura serverless da `NotificationsAPI` (Lambda/SAM)
  devem ser feitas em `FIAPCloudGames-fase3-NotificationsAPI/template.yaml`
  e `samconfig.toml`, e o STATUS.md da skill `retomar-fase-3-fiap` deve ser
  atualizado a cada passo concluido.
- Mudancas transversais (API Gateway, observabilidade, Redis, manifestos K8s
  agregados) pertencem ao repo `FIAPCloudGames-fase3-Orchestration`.

## Nao Alterar Sem Aprovacao

- Nao trocar RabbitMQ por outro broker nos servicos que ja o usam
  (`UsersAPI`, `CatalogAPI`, `PaymentsAPI`) sem pedido explicito — a
  migracao para SNS/SQS e **incremental e paralela**, RabbitMQ continua
  obrigatorio ate o Passo 15 (coordenacao com o grupo) ser concluido.
- Nao alterar o contrato de eventos (`FiapCloudGames.Contracts`) localmente
  dentro de um microsservico; contratos sao versionados no repositorio
  externo `fcg-contracts` e consumidos via NuGet.
- Nao mudar a convencao de casing (PascalCase) dos eventos de teste da
  `NotificationsAPI`/Lambda sem atualizar tambem `events/*.json` e
  `local/test-*-message.json`.
- Nao remover a chave HMAC compartilhada entre `UsersAPI` e `CatalogAPI`
  nem gerar chaves diferentes por servico — a validacao de JWT depende de
  serem identicas.
- Nao resolver o conflito de merge do
  `FIAPCloudGames-fase3-Orchestration/README.md` de forma automatica/sem
  revisao — as duas versoes (`Updated upstream` e `Stashed changes`) tem
  conteudo tecnico diferente; confirmar com o usuario qual deve prevalecer
  (ou se devem ser mescladas).
- Nao commitar valores reais de secret em `.env`, `appsettings.*.json` ou
  manifestos `k8s/*secret*.yaml` (que hoje usam apenas base64, nao
  criptografia).

## Validacao

- `.NET` (por servico, dentro do repo do servico):
  - `dotnet build`
  - `dotnet test` (roda todas as camadas) ou por camada, ex.:
    `dotnet test test/CatalogAPI.Domain.Tests/`,
    `dotnet test tests/FCG.UnitTests`,
    `dotnet test tests/FCG.IntegrationTests` (exige Docker/Testcontainers).
- `NotificationsAPI` (raiz `NotificationsAPI/` dentro do repo): `dotnet build`
  e `dotnet test` — ultima execucao conhecida: 50 testes passando (23
  Domain, 15 Application, 3 Infrastructure, 9 Integration).
- Infra serverless (SAM): `sam build` e `sam deploy --no-confirm-changeset`
  (a flag evita travar esperando confirmacao interativa) a partir de
  `FIAPCloudGames-fase3-NotificationsAPI/`.
- Ambiente completo local: `docker-compose up --build` a partir de
  `FIAPCloudGames-fase3-Orchestration/` (requer os 4 repos de servico
  clonados como pastas irmas).
- Kubernetes local (Minikube): `make k8s-up` /
  `make k8s-status` / `make k8s-down` a partir de
  `FIAPCloudGames-fase3-Orchestration/` (requer Git Bash/WSL no Windows,
  `make` nao existe no PowerShell puro).

## Manutencao do Contexto

- Atualizar este arquivo sempre que: um novo microsservico ou repo for
  adicionado/removido do workspace; a migracao serverless da
  `NotificationsAPI` avancar de fase (ex.: Passo 15 concluido, RabbitMQ
  removido de algum publisher); o API Gateway ou a stack de observabilidade
  forem efetivamente implementados na Orchestration; ou contratos de evento
  mudarem.
- Para o progresso detalhado, passo a passo, da migracao serverless,
  consultar sempre `.cursor/skills/retomar-fase-3-fiap/STATUS.md` (fonte
  viva, atualizada a cada sessao) em vez de duplicar esse detalhe aqui.
- Se o conflito de merge no `README.md` da Orchestration for resolvido,
  remover a observacao correspondente deste arquivo.
