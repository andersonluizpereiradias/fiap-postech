# Monólito FIAP Cloud Games (FCG) — Fase 1

> Resumo do repositório `fiap_cloud-games` (MVP da Fase 1), usado como base de referência para a decomposição em microsserviços da Fase 2 (`UsersAPI`, `CatalogAPI`, `PaymentsAPI`, `NotificationsAPI`).

## Visão Geral

- **Produto:** plataforma de venda de jogos digitais e gestão de biblioteca de jogos adquiridos.
- **Escopo da Fase 1:** API REST monolítica com autenticação, cadastro/gestão de usuários, CRUD de jogos, promoções, biblioteca de jogos do usuário (`UserOwnedGame`), fluxos administrativos, persistência e testes.
- **Estilo arquitetural:** monolito em camadas (Clean Architecture / DDD leve), sem mensageria — toda comunicação é síncrona via chamadas internas (in-process).

## Stack Tecnológica

- **Runtime:** C# / .NET 10, `Nullable` e `ImplicitUsings` habilitados.
- **Framework web:** ASP.NET Core **Minimal APIs**.
- **Persistência:** Entity Framework Core + **PostgreSQL 16** (`Npgsql`).
- **Autenticação/Autorização:** JWT Bearer (claims customizadas, `RoleClaimType = ClaimTypes.Role`), política `AdminOnly` (`RequireRole("Administrator")`).
- **Hash de senha:** BCrypt.
- **Logs:** Serilog (console, com request logging).
- **Documentação:** Swagger / OpenAPI (Swashbuckle), habilitado apenas em `Development`.
- **Testes:** xUnit + Moq + FluentAssertions (unitários/API) e Reqnroll/Gherkin (BDD, em `TestsReqnroll`).
- **Containerização:** Docker multi-stage (`mcr.microsoft.com/dotnet/sdk:10.0-preview` → `aspnet:10.0-preview`), Docker Compose com serviços `db` (Postgres) e `api`.

## Arquitetura em Camadas

Direção de dependências: `FCG.Domain` ← `FCG.Application` ← `FCG.Infrastructure`; `FCG.API` referencia `FCG.Application` e `FCG.Infrastructure`.

```
src/
  FCG.Domain/          → Entidades, Value Objects, Enums, Eventos de domínio, Exceções, Políticas, contratos de repositório
  FCG.Application/     → Casos de uso (I*UseCase / *UseCase), DTOs, Mappers, Interfaces
  FCG.Infrastructure/  → DbContext (EF Core), Repositórios, Migrations, Seed, JWT, BCrypt, DI (AddInfrastructure)
  FCG.API/             → Endpoints Minimal API, Middlewares, Swagger, Program.cs (bootstrap)
  FCG.Tests/           → Testes unitários e de API (xUnit/Moq/FluentAssertions)
TestsReqnroll/          → Cenários BDD (Gherkin)
```

- **Entrypoint:** `src/FCG.API/Program.cs`. No startup: aplica `db.Database.Migrate()` (com retry de 10x/3s caso o banco ainda não esteja pronto) e executa `DatabaseSeeder.SeedAsync()`.
- **Tratamento de erros:** middleware central `ErrorHandlingMiddleware`.
- **Convenções de nomenclatura:** casos de uso seguem `I*UseCase`/`*UseCase`; repositórios têm interface no `Domain` e implementação na `Infrastructure`; grupos de endpoints via métodos de extensão `Map*Endpoints()`.
- **Organização por feature:** fatias `Auth`, `Users`, `Games` espelhadas entre `Domain`/`Application`/`Infrastructure` quando aplicável.

## Modelo de Domínio (Linguagem Ubíqua)

### Entidades / Agregados

| Termo | Definição | Código |
|-------|-----------|--------|
| Usuário | Indivíduo apto a consumir ou administrar jogos na plataforma | `User` |
| Jogo | Conteúdo interativo digital disponível para aquisição | `Game` |
| Biblioteca | Acervo de jogos adquiridos pelo jogador | `UserOwnedGame` |
| Papel | Define o nível de autoridade de um usuário | `Role` |
| Promoção | Desconto temporário aplicado a um jogo | `GamePromotion` |

### Value Objects

| Código | Definição |
|--------|-----------|
| `Name` | Nome do usuário |
| `Email` | Endereço de e-mail (normalizado para lowercase) |
| `Password` | Validador de complexidade de senha |
| `GameTitle` | Título do jogo |
| `Price` | Valor monetário do jogo (nunca negativo) |

### Enums

- **RoleType**: `User`, `Administrator`
- **GameGenre**: `Action`, `RPG`, `Strategy`, `Sports`, `Puzzle`, `Other`
- **GameStatus**: `Active`, `Inactive`, `ComingSoon`
- **DiscountType**: `Percentage`, `FixedValue`

### Detalhes das principais entidades

- **`User`** (`FCG.Domain.Users.Entities`): `Name`, `Email`, `PasswordHash`, `RoleId`, `IsActive`, `DeletedAt`, navegação `Role` e `OwnedGames`. Métodos: `Create`, `UpdateName`, `UpdateEmail`, `UpdatePassword`, `ChangeRole`, `Activate`/`Deactivate`, `SoftDelete`, `CreateRootAdmin` (admin seed com `Id` fixo `33333333-3333-3333-3333-333333333333`).
- **`Game`** (`FCG.Domain.Games.Entities`): `Title`, `Description` (≤ 2000 chars), `Price`, `Genre`, `Status`, `ReleaseDate` (não pode ser no passado na criação). Possui **eventos de domínio** internos (`_domainEvents`, lista `object`, ainda não publicados externamente):
  - `GameCreatedEvent(Guid GameId, string Title, DateTime OccurredAt)` — disparado no construtor.
  - `GameUpdatedEvent(Guid GameId, string Title, DateTime OccurredAt)` — disparado em `Update()` e `Deactivate()`.
  - `Deactivate()` faz soft delete (status `Inactive`).
- **`GamePromotion`** (`FCG.Domain.Games.Entities`): `GameId`, `DiscountType`, `DiscountValue`, `StartDate`, `EndDate`, `IsActive`. Validações: valor > 0; desconto percentual ≤ 100%; `StartDate < EndDate`; sem sobreposição de datas para o mesmo jogo (`OverlappingPromotionException`). `IsCurrentlyValid()` checa janela de tempo + `IsActive`.
- **`UserOwnedGame`** (`FCG.Domain.Users.Entities`): `UserId`, `GameId`, `PricePaid`, `AcquiredAt` (snapshot do preço no momento da compra). Navegações `User` e `Game`.

### Exceções de domínio (principais)

- Games: `DomainException`, `DomainValidationException`, `GameNotFoundException`, `InvalidGameTitleException`, `InvalidPriceException`, `InvalidReleaseDateException`, `OverlappingPromotionException`, `PromotionNotFoundException`, `InsufficientGameManagementPermissionException`.
- Users: `UserDomainException`, `InvalidCredentialsException`, `UserAlreadyExistsException`, `UserAlreadyOwnsGameException`, `UserNotFoundException`, `RootAdminOperationForbiddenException`.

## Fluxo de Compra (relevante para a Fase 2)

Hoje, a "compra" de um jogo é **síncrona e local** — não existe pagamento real, mensageria nem eventos publicados externamente:

1. Usuário autenticado chama `POST /api/users/owned-games` (`UserEndpoints.PurchaseOwnedGame`), extraindo `userId` do claim `ClaimTypes.NameIdentifier` do JWT.
2. `PurchaseOwnedGameUseCase`:
   - Verifica se o usuário existe e está ativo.
   - Verifica se o jogo existe e está com `Status == Active`.
   - Verifica se o usuário já possui o jogo (`UserAlreadyOwnsGameException` se sim).
   - Cria `UserOwnedGame` com `PricePaid = game.Price.Amount` (preço travado no momento da compra) e persiste via `IUserUnitOfWork` + `CommitAsync`.
3. Retorna `PurchaseOwnedGameResponse` (201 Created).

> Na Fase 2, este fluxo será decomposto: `CatalogAPI` recebe a requisição e publica `OrderPlacedEvent` (`UserId`, `GameId`, `Price`); `PaymentsAPI` processa e publica `PaymentProcessedEvent` (`Approved`/`Rejected`); `CatalogAPI` adiciona o jogo à biblioteca se aprovado; `NotificationsAPI` envia e-mail de confirmação se aprovado. O `GameCreatedEvent`/`GameUpdatedEvent` já existentes no domínio podem inspirar (mas não correspondem a) o `UserCreatedEvent` exigido para o fluxo de cadastro.

## Persistência (EF Core / PostgreSQL)

- `AppDbContext` (`FCG.Infrastructure.Persistence.Context`) com mapeamentos via `IEntityTypeConfiguration`: `UserConfiguration`, `RoleConfiguration`, `UserOwnedGameConfiguration`, `GameMapping`, `GamePromotionConfiguration`.
- Repositórios: `UserRepository`, `RoleRepository`, `UserOwnedGameRepository`, `GameRepository`, `GamePromotionRepository`, todos sobre `RepositoryBase`.
- `UnitOfWork` implementa `IUnitOfWork` e `IUserUnitOfWork`.
- `DatabaseSeeder` cria o **admin root** (`admin@fcg.com` / `Admin@123`) e roles na subida.
- Migrations relevantes (em ordem): `InitialCreate`, `AddUserIdentitySchema`, `FixGameCascadeDeleteToRestrict` (FK de `UserOwnedGame`/`GamePromotion` → `Game` é `Restrict`, não `Cascade`), `AddUserSoftDelete`, `AddGamePromotion`.

## Autenticação e Autorização

- JWT Bearer configurado em `AddInfrastructure` (`InfrastructureServiceExtensions`):
  - `JwtSettings` (de `appsettings.json`: `SecretKey`, `ExpirationHours = 4`) registrado como singleton.
  - `MapInboundClaims = false`, `RoleClaimType = ClaimTypes.Role`.
  - `ValidateIssuer = false`, `ValidateAudience = false`, `ValidateLifetime = true`, `ValidateIssuerSigningKey = true`.
- Política de autorização **`AdminOnly`** = `RequireRole("Administrator")`.
- `JwtTokenService` (Infrastructure) gera o token; `LoginUseCase` (Application/Auth) faz o login via `POST /api/auth/login`.
- Senha validada via VO `Password`: mínimo 8 caracteres, ≥1 maiúscula, ≥1 minúscula, ≥1 dígito, ≥1 caractere especial (`!@#$%^&*()-_+=`).
- Hash de senha: BCrypt (`BcryptPasswordHasher` implementa `IPasswordHasher`).

## Endpoints REST (mapa completo)

> 🔒 = requer JWT | 🔑 = requer papel `Administrator`

### Autenticação (`AuthEndpoints`)
| Método | Rota | Descrição | Auth |
|---|---|---|---|
| POST | `/api/auth/login` | Gera token JWT | — |

### Usuários (`UserEndpoints`, grupo `/api/users`)
| Método | Rota | Descrição | Auth |
|---|---|---|---|
| POST | `/api/users/owned-games` | Comprar/adquirir jogo (usuário do JWT) | 🔒 |
| GET | `/api/users/{userId}/owned-games` | Listar jogos da biblioteca do usuário | 🔒 |

### Cadastro de usuário (`UsersEndpoint` / `UsersEndpoints`)
| Método | Rota | Descrição | Auth |
|---|---|---|---|
| POST | `/api/users/register` | Cadastrar novo usuário | — |

### Jogos (`GameEndpoints`)
| Método | Rota | Descrição | Auth |
|---|---|---|---|
| POST | `/api/games` | Cadastrar jogo | 🔑 |
| GET | `/api/games` | Listar jogos (paginado, filtro por gênero) | 🔒 |
| GET | `/api/games/{id}` | Buscar jogo por ID | 🔒 |
| PUT | `/api/games/{id}` | Atualizar jogo | 🔑 |
| DELETE | `/api/games/{id}` | Desativar jogo (soft delete) | 🔑 |

### Promoções (`PromotionEndpoints`)
| Método | Rota | Descrição | Auth |
|---|---|---|---|
| GET | `/api/games/{gameId}/promotions` | Listar promoções do jogo | 🔒 |
| GET | `/api/games/{gameId}/promotions/{id}` | Buscar promoção | 🔒 |
| POST | `/api/admin/games/{gameId}/promotions` | Criar promoção | 🔑 |
| PUT | `/api/admin/games/{gameId}/promotions/{id}` | Atualizar promoção | 🔑 |
| DELETE | `/api/admin/games/{gameId}/promotions/{id}` | Remover promoção | 🔑 |

### Admin — Usuários (`AdminUserEndpoints`)
| Método | Rota | Descrição | Auth |
|---|---|---|---|
| POST | `/api/admin/users` | Criar usuário | 🔑 |
| GET | `/api/admin/users` | Listar usuários (paginado) | 🔑 |
| GET | `/api/admin/users/{id}` | Buscar usuário | 🔑 |
| PUT | `/api/admin/users/{id}` | Atualizar usuário | 🔑 |
| DELETE | `/api/admin/users/{id}` | Remover usuário (soft delete) | 🔑 |

### Parâmetros de listagem comuns

| Parâmetro | Tipo | Padrão | Descrição |
|-----------|------|--------|-----------|
| `page` | int | 1 | Página |
| `pageSize` | int | 10 | Itens por página (máx. 50) |
| `genre` | string | — | Filtro por gênero |

## Validações de Negócio

- **E-mail**: formato RFC 5322, único no sistema, normalizado para lowercase.
- **Senha**: mínimo 8 caracteres, 1 maiúscula, 1 minúscula, 1 dígito, 1 caractere especial.
- **Preço do jogo**: deve ser positivo (`Price` VO).
- **Data de lançamento**: não pode ser no passado na criação do jogo.
- **Descrição do jogo**: máximo 2000 caracteres.
- **Promoções**: sem sobreposição de datas para o mesmo jogo; desconto percentual ≤ 100%; valor de desconto > 0; `StartDate < EndDate`.
- **Compra de jogo**: usuário ativo, jogo ativo, sem duplicidade de posse.

## Configuração / Variáveis de Ambiente

- `ConnectionStrings:DefaultConnection` — string de conexão Postgres (ex.: `Host=db;Port=5432;Database=fcgdb;Username=fcg;Password=fcg123`).
- `JwtSettings:SecretKey` — chave simétrica para assinatura JWT.
- `JwtSettings:ExpirationHours` — validade do token (atualmente `4`).
- `ASPNETCORE_ENVIRONMENT` — controla habilitação do Swagger (`Development`).
- Serilog configurado via seção `Serilog` do `appsettings.json` (nível `Information`, com overrides `Warning` para `Microsoft.AspNetCore` e `Microsoft.EntityFrameworkCore`).

## Docker / Execução Local

- **Dockerfile** (`src/FCG.API/Dockerfile`): multi-stage, `dotnet/sdk:10.0-preview` (build/restore/publish) → `dotnet/aspnet:10.0-preview` (runtime), expõe porta `8080`.
- **docker-compose.yml** (raiz): serviços `db` (Postgres 16, porta `5432`, com healthcheck `pg_isready`) e `api` (build do Dockerfile, porta `8080`, depende de `db` saudável).
- Subida completa: `docker-compose up --build` → API em `http://localhost:8080`, Swagger em `http://localhost:8080/swagger`.
- Execução local sem container da API: `docker-compose up db -d` + `dotnet run` em `src/FCG.API`.
- Credenciais de admin seed: `admin@fcg.com` / `Admin@123`.

## Testes

- Unitários/API: `src/FCG.Tests` (xUnit, Moq, FluentAssertions) — cobre use cases de Auth, Games, Promotions, Users, entidades de domínio, value objects, políticas, JWT e seeder.
- BDD: `TestsReqnroll` (Gherkin), espelhando domínio/aplicação/API/infraestrutura.
- Comando: `cd src && dotnet test`.

## Pontos de Atenção para a Decomposição (Fase 2)

- **Sem mensageria hoje**: todo o fluxo de compra e cadastro é síncrono/in-process; será necessário introduzir RabbitMQ/Kafka e publicar/consumir os eventos `UserCreatedEvent`, `OrderPlacedEvent`, `PaymentProcessedEvent`.
- **Sem pagamento real**: a Fase 1 não tem conceito de pagamento — será criado do zero no `PaymentsAPI` (simulado).
- **Sem notificações**: não há envio de e-mails — será criado do zero no `NotificationsAPI` (simulado via log).
- **Eventos de domínio existentes** (`GameCreatedEvent`, `GameUpdatedEvent`) são apenas objetos in-memory acumulados na entidade `Game`, nunca publicados/dispatachados — não correspondem aos eventos de integração exigidos pela Fase 2, mas mostram que o domínio já modela "algo aconteceu".
- **Separação de responsabilidades sugerida**:
  - `UsersAPI` ⟵ `FCG.Domain.Users` + `Auth` (cadastro, login/JWT, papéis).
  - `CatalogAPI` ⟵ `FCG.Domain.Games` (CRUD de jogos, promoções) + biblioteca do usuário (`UserOwnedGame`) e orquestração do fluxo de compra.
  - `PaymentsAPI` ⟵ novo serviço, sem equivalente direto na Fase 1.
  - `NotificationsAPI` ⟵ novo serviço, sem equivalente direto na Fase 1.
- **Banco de dados**: hoje único Postgres compartilhado (`fcgdb`); na Fase 2 cada microsserviço deve ter seu próprio armazenamento/contexto, exigindo divisão do schema atual (`Users`, `Roles`, `UserOwnedGames`, `Games`, `GamePromotions`).
- **Autenticação**: o `JwtSettings.SecretKey` precisa ser compartilhado/replicado entre serviços (ou validado via chave pública) para que `CatalogAPI`, `PaymentsAPI` etc. consigam validar tokens emitidos pelo `UsersAPI`.
