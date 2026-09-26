# Tutorial — Migração do NotificationsAPI para AWS Lambda (Serverless)

> **Sua frente na Fase 3:** migrar o `NotificationsAPI` (hoje um container sempre ligado) para uma
> função AWS Lambda acionada diretamente por mensagens de fila, eliminando o desperdício de
> recurso ocioso que o enunciado aponta como problema.
>
> Este documento é o seu roteiro completo, do zero ao vídeo de entrega. Ele foi escrito depois de:
> ler o enunciado (`TC NETT - Fase 3.md`), a divisão de atividades, os 5 resumos das aulas da fase,
> todo o código já existente no repositório `FIAPCloudGames-fase3-NotificationsAPI` (incluindo o
> `SDD.md` de lá) e a conversa real do grupo no WhatsApp. Onde a conversa do grupo contradisse uma
> suposição minha de uma conversa anterior, a conversa do grupo venceu — isso está registrado na
> seção 1.

---

## 0. Como usar este documento

Cada "Passo" é uma unidade fechada: o que fazer, por quê, e como confirmar que deu certo antes de
ir para o próximo. Siga na ordem — a ordem importa, porque cada passo assume que o anterior
funcionou.

Convenções usadas:

- Comandos de terminal aparecem em blocos de código. Quando o comando é específico do Windows
  PowerShell (o seu ambiente), está marcado como `powershell`. Comandos do AWS SAM CLI e do
  `dotnet` funcionam iguais em qualquer sistema operacional.
- `<algo-entre-colchetes>` é um valor que você substitui (ex.: `<sua-license-key>`).
- Blocos marcados **"Ponto de verificação"** dizem exatamente o que você deve ver na tela se o
  passo funcionou. Se não bater, pare e resolva antes de continuar — os passos seguintes vão
  falhar de formas confusas se um anterior estiver quebrado.

---

## 1. Contexto e decisões (leia antes de começar a digitar)

### 1.1 O que a Fase 3 exige da sua frente, literalmente

Do enunciado (`documentos/TC NETT - Fase 3.md`):

> "Refatore o microsserviço NotificationsAPI para uma Função Serverless (AWS Lambda, Azure Function
> ou Google Cloud Function). A função deve ser configurada para ser acionada (triggered) diretamente
> por novas mensagens na fila/tópico do seu sistema de mensageria, substituindo o container que
> rodava continuamente."

E no requisito técnico: "o código da função e sua configuração de infraestrutura como código (ex.:
SAM, Serverless Framework, Terraform, ou equivalente) devem estar em seu próprio repositório."

Três obrigações concretas saem daí, e vão guiar cada decisão deste tutorial:

1. É Lambda (o grupo já escolheu, descartando Azure Function/Cloud Function).
2. O gatilho é uma mensagem de fila/tópico — não pode ser um endpoint HTTP chamado manualmente.
3. Existe infraestrutura como código versionada (você vai usar AWS SAM).

### 1.2 O que o grupo decidiu de verdade (revisão feita a partir da conversa do WhatsApp)

Uma conversa anterior deste chat assumiu que o grupo tinha fechado a **Opção A** de observabilidade
(Prometheus + Grafana), baseado no documento `TC NETT - Fase 3 - Divisao de Atividades.md`. Lendo a
conversa real do grupo (`documentos/Grupo 1 - FIAP.zip`), isso está desatualizado. Essa suposição
era minha, não do grupo — e a mensagem de 28/08 é explícita:

> **João Pedro (19:11):** "Fechado! Eu to desenvolvendo algumas coisas já pra conseguir gerar as
> métricas, mas bom saber que usaremos o New Relic, assim já adapto como estou fazendo"
>
> **Pedro (19:50):** "Ta então, as tarefas se alinharam, definimos que usaremos dynamo e AWS. E
> também pra métricas usaremos o New Relic"

**Decisão real do grupo: Opção B (New Relic), não Opção A.** Isso muda o escopo da sua frente, porque
o enunciado, na Opção B, é explícito sobre incluir a função serverless:

> "Configure os agentes de APM nos seus microsserviços (UsersAPI, CatalogAPI, PaymentsAPI) **e na
> sua Função Serverless**."

Ou seja: instrumentar a Lambda com New Relic deixou de ser opcional (como seria na Opção A, coberta
pelo CloudWatch sozinho) e passou a ser um requisito obrigatório desta frente. Este documento já
está desenhado em cima disso — é por isso que o `SDD.md` que já existe no repositório da
`NotificationsAPI` (que também assume New Relic) está certo, e é a base que seguimos aqui.

Outras decisões confirmadas na conversa, relevantes para você:

| Decisão | Onde na conversa | Impacto na sua frente |
|---|---|---|
| NoSQL da Notifications = **DynamoDB** (não MongoDB) | 28/08, 19:49 | Nenhum trabalho seu — já implementado (seção 1.3) |
| Observabilidade = **New Relic** (Opção B) | 28/08, 19:11 e 19:50 | Lambda precisa de métricas, logs **e traces** |
| Conta AWS: o grupo teve dificuldade com o free tier em várias tentativas e vai usar uma conta pessoal do Pedro para o deploy final | 24/08 e 28/08 | Seção 4 traz as causas prováveis do problema e como evitá-las |
| Meta informal do grupo: ~80% pronto até uma sexta-feira, ajustes e vídeo na semana seguinte | 28/08, 19:53 | Priorize o que é obrigatório (seções 21–22) antes de polir extras |

### 1.3 O que já está pronto no repositório (trabalho do Pedro — não refaça)

O Pedro começou a trabalhar no `NotificationsAPI` antes de vocês alinharem a divisão de tarefas (ele
mesmo reconheceu isso: *"Vish. Não sabia que tinha ficado p vocÊ [...] eu já fiz algumas coisas mas
paro por aqui. Tem codigo já la no repositorio"*). O que ele deixou pronto é bom trabalho e você deve
**reaproveitar, não reescrever**:

**Removido (e não precisa voltar):**
- A API HTTP (`Notifications.API`, os 7 endpoints de `/notifications`, o `/health`).
- EF Core, `AppDbContext`, migrations, PostgreSQL.
- `IUnitOfWork` (DynamoDB grava direto, não tem transação a confirmar depois).

**Já implementado, funcionando e testado (`Notifications.Infrastructure/Persistence/DynamoDb/`):**

```csharp
// DynamoDbNotificationRepository.cs — grava com condição de idempotência
public async Task AddAsync(Notification entity, CancellationToken cancellationToken = default)
{
    var request = new PutItemRequest
    {
        TableName = options.TableName,
        Item = NotificationItem.ToItem(entity),
        ConditionExpression = $"attribute_not_exists({NotificationItem.PartitionKeyAttribute})"
    };

    try
    {
        await client.PutItemAsync(request, cancellationToken);
    }
    catch (ConditionalCheckFailedException ex)
    {
        throw new DuplicateEventException(
            "O evento de integração já havia sido processado (chave de partição já existe).", ex);
    }
}
```

A chave de partição é `EVENT#{EventId}` — é isso que garante que reentregas duplicadas da fila (que
vão acontecer, porque SQS é *at-least-once*) não gravem a notificação duas vezes nem mandem dois
e-mails duplicados. Você não precisa mexer nisso. Os detalhes técnicos completos de por que a chave
é derivada do `EventId` (e não do `Id` da notificação) estão documentados nos comentários do próprio
`NotificationItem.cs` e no `SDD.md`, seção DD-04.

**Estrutura da tabela já assumida pelo código** (você só vai declarar isso no `template.yaml`, não
inventar):

| Atributo | Papel |
|---|---|
| Nome da tabela | `fcg-notifications` (default em `DynamoDbOptions.TableName`) |
| `PK` (string) | Partition key — `EVENT#{EventId}` |
| Índice `GSI1-UserId` | Partition key `UserId`, sort key `CreatedAt` — usado para buscar notificações de um usuário |

**O que ainda falta (é isso que este tutorial cobre):**
- O projeto `Notifications.Functions` com os handlers Lambda (não existe ainda).
- Remover a dependência do RabbitMQ (`FiapCloudGames.RabbitMq`), que **ainda está** registrada em
  `InfrastructureServiceExtensions.cs` — o Pedro trocou a persistência, mas a mensageria continua
  apontando para o RabbitMQ.
- O `template.yaml` (infraestrutura como código) — não existe ainda.
- A instrumentação New Relic — não existe ainda.
- Um ajuste pequeno, mas importante, no `PaymentProcessedEventHandler` (seção 7 explica o porquê).

### 1.4 Decisões de arquitetura desta frente

A divisão de atividades já autoriza você a decidir os detalhes técnicos da sua frente sem precisar
de aprovação do grupo todo, desde que alinhe os pontos de integração. Aqui estão as decisões, com a
justificativa curta (a discussão completa, com todas as alternativas comparadas, está registrada
neste mesmo chat, nas mensagens anteriores a este documento):

**Mensageria: SNS + SQS (não Amazon MQ, não uma ponte manual).** O Lambda não pode ser acionado pelo
RabbitMQ self-hosted que vocês já têm — event source mapping só aceita SQS, Kinesis, DynamoDB
Streams, Kafka/MSK, DocumentDB e Amazon MQ (broker RabbitMQ *gerenciado*, um serviço à parte). Amazon
MQ ficaria ligado 24/7 (o problema que a fase pede para resolver), limita a Lambda a 1 execução
concorrente por fila, e não está no Always Free. SNS + SQS é 100% gratuito dentro do uso de um
projeto acadêmico, escala, tem DLQ e retry nativos, e é o vocabulário ensinado na Aula 1–3 de
Serverless Apps. Consequência prática: `UsersAPI` e `PaymentsAPI` precisam ganhar um publisher SNS
(seção 18) — coordenar com quem mantém esses repositórios.

**Observabilidade: New Relic via OpenTelemetry/OTLP**, conforme o grupo decidiu. Cobre os três
pilares (métricas, logs, traces) exigidos pela Opção B.

**Persistência: DynamoDB**, já implementado pelo Pedro. Nenhuma mudança de esquema necessária.

**Runtime: `dotnet10` gerenciado, pacote ZIP** (não imagem de container). Isso é uma mudança
importante em relação ao que o `SDD.md` do repositório previa: em janeiro de 2026 a AWS lançou o
runtime `dotnet10` gerenciado no Lambda, com suporte oficial via SAM (`Runtime: dotnet10`). O risco
"R-03" do `SDD.md` ("disponibilidade do runtime .NET 10 no Lambda") está resolvido — o fallback de
imagem de container que o `SDD.md` cogitava não é mais necessário.

---

## 2. Arquitetura alvo

```
UsersAPI ──publica──► SNS fcg-user-events ──assina──► SQS fcg-notifications-user-registered ──aciona──► Lambda UserRegisteredFunction ──► DynamoDB fcg-notifications
                                                              └── (após 5 falhas) DLQ                            └── New Relic (métricas + logs + traces)

PaymentsAPI ──publica──► SNS fcg-payment-events ──assina──► SQS fcg-notifications-payment-processed ──aciona──► Lambda PaymentProcessedFunction ──► DynamoDB
             └─ continua publicando no RabbitMQ também, porque o catalog-api      └── (após 5 falhas) DLQ                └── New Relic
                depende do PaymentProcessedEvent para liberar o jogo na biblioteca
```

Pontos que valem grifar antes de começar a implementar:

- O `PaymentsAPI` vai publicar em **dois lugares**: RabbitMQ (para o `catalog-api`, que continua
  existindo) e SNS (para a sua Lambda). Isso não é retrabalho duplicado — é uma migração
  incremental, exatamente o padrão recomendado para não quebrar o fluxo de compra no meio do
  caminho.
- O contrato do evento (`UserRegisteredEvent`, `PaymentProcessedEvent` do pacote
  `FiapCloudGames.Contracts`) **não muda**. O que muda é o transporte. Isso significa que
  provavelmente **não é preciso** publicar uma nova versão do `FiapCloudGames.Contracts` — o ARN do
  tópico SNS é configuração (variável de ambiente no publisher), não parte do contrato.

---

## 3. Pré-requisitos: ferramentas a instalar

Rode estes comandos no PowerShell para conferir o que você já tem:

```powershell
dotnet --version
git --version
docker --version
```

Você precisa de:

| Ferramenta | Versão mínima | Por quê |
|---|---|---|
| .NET SDK | 10.0.x | Já confirmado instalado na sua máquina |
| Git | qualquer recente | Já instalado |
| Docker Desktop | qualquer recente | Já instalado — necessário para o SAM CLI empacotar/testar localmente |
| AWS CLI v2 | — | Não instalado ainda — Passo 5 |
| AWS SAM CLI | 1.100+ (com suporte a `dotnet10`) | Não instalado ainda — Passo 7 |

---

## 4. Passo 1 — Criar (ou obter acesso a) uma conta AWS

### 4.1 O que aconteceu com o grupo, e como evitar

Pelo histórico do WhatsApp, pelo menos duas pessoas do grupo tentaram criar uma conta AWS gratuita
e não conseguiram — Leonardo tentou duas vezes "do zero" e desistiu, e o Pedro teve o cadastro
travado porque **o e-mail de recuperação da conta nova já estava associado a uma conta AWS
existente**. O grupo decidiu contornar usando uma conta pessoal do Pedro, aceitando um custo
residual pequeno.

O erro mais provável, considerando o texto oficial da AWS, é este: a AWS não aceita mais um e-mail
(nem como titular, nem como e-mail de recuperação) que já tenha qualquer vínculo com outra conta
AWS. Se você usar um Gmail que você já usou para testar AWS em qualquer fase anterior do curso, o
cadastro trava sem mensagem de erro clara.

**Como evitar isso:** crie um e-mail novo, exclusivo para esta conta AWS, que nunca tenha sido usado
como e-mail de recuperação em nenhuma outra conta AWS (nem sua, nem de colegas). Um Gmail novo, sem
histórico, resolve isso na maioria dos casos.

### 4.2 O que mudou no Free Tier da AWS (importante, isso não é o que os professores ensinaram em fases anteriores)

A partir de 15 de julho de 2025 a AWS trocou o modelo antigo (12 meses grátis em vários serviços)
por um modelo de créditos. É por isso que o "jeito" que os professores ensinaram em fases anteriores
pode não funcionar mais exatamente igual. O modelo atual:

- Toda conta nova ganha **US$ 100 em créditos** no cadastro, podendo chegar a **US$ 200** completando
  algumas atividades de "explorar a AWS" (uma delas é literalmente publicar uma função Lambda).
- Você escolhe entre **Free plan** (fecha sozinho em 6 meses ou quando o crédito acabar) e **Paid
  plan** (cobrança normal além do crédito).
- Cartão de crédito ou débito é obrigatório em ambos os planos.
- Separado dos créditos, existe o **Always Free**: mais de 30 serviços com limite mensal permanente,
  que nunca expira e não consome os créditos de cadastro. Os que interessam ao seu projeto:

| Serviço | Limite sempre grátis por mês |
|---|---|
| AWS Lambda | 1.000.000 requisições + 400.000 GB-s de computação |
| Amazon DynamoDB | 25 GB de armazenamento + 25 unidades de leitura/escrita |
| Amazon SQS | 1.000.000 requisições |
| Amazon SNS | 1.000.000 publicações |
| Amazon CloudWatch | 10 métricas customizadas, 10 alarmes, 1.000.000 chamadas de API |

Como a arquitetura que você vai construir usa exatamente essa lista (Lambda, DynamoDB, SQS, SNS,
CloudWatch), o volume de um projeto acadêmico não deve gerar cobrança nenhuma além do que já está no
Always Free — você não deveria precisar tocar nos créditos de cadastro.

### 4.3 Passo a passo do cadastro

1. Acesse **https://aws.amazon.com/free/** num navegador anônimo/privado (evita a AWS puxar
   sessão de outra conta sua já logada).
2. Clique em **"Create an AWS Account"** (ou "Criar uma conta da AWS").
3. Informe o e-mail novo (seção 4.1) e um nome para a conta, por exemplo `fcg-notifications-lambda`.
4. Confirme o e-mail (chega um código de verificação — cole-o na tela).
5. Defina uma senha forte para a conta root.
6. Preencha os dados de contato (nome, endereço, telefone). Pode ser seu endereço real.
7. Escolha **"Free plan"** quando a tela perguntar (garante que você não é cobrado além dos créditos
   sem querer mudar para o plano pago).
8. Cadastre um cartão de crédito ou débito válido. **Isso é obrigatório mesmo no plano gratuito** —
   diferente do Azure for Students, a AWS não tem via sem cartão.
9. Verifique o telefone (SMS ou ligação automática com código).
10. Escolha o **"Basic support plan — Free"** na tela de suporte.
11. Aguarde a confirmação de ativação da conta (geralmente instantânea, às vezes leva alguns
    minutos).

**Ponto de verificação:** você consegue fazer login em **https://console.aws.amazon.com/** com o
e-mail e senha cadastrados, e vê o AWS Management Console (a tela inicial com a busca de serviços no
topo).

### 4.4 Se o cadastro travar de novo

Se mesmo com um e-mail novo o cadastro falhar sem mensagem clara, use a conta que o Pedro já
disponibilizou para o grupo — peça a ele um usuário IAM com permissões de `AdministratorAccess`
(seção 5 explica por que criar um usuário IAM, não usar a conta root diretamente) para a região
`us-east-1`. É uma solução válida e é o que o grupo já decidiu como plano de contingência. O
importante é que o **deploy final que aparece no vídeo** funcione — não importa em qual das duas
contas ele rodou.

---

## 5. Passo 2 — Criar um usuário IAM e configurar o AWS CLI

Você nunca deve usar as credenciais da conta **root** no dia a dia (é a conta "dona" de tudo, sem
limite nenhum — se vazar, é o pior cenário possível). Vamos criar um usuário separado, com permissão
de administrador, só para o trabalho deste projeto.

### 5.1 Criar o usuário IAM

1. No AWS Management Console, busque por **"IAM"** na barra de busca do topo e entre no serviço.
2. No menu lateral, clique em **"Users"** (Usuários) → **"Create user"** (Criar usuário).
3. Nome do usuário: `anderson-notifications-lambda`.
4. **Não** marque a opção de acesso ao console (você só vai usar isso pela linha de comando).
5. Avance até **"Set permissions"** (Definir permissões) → escolha **"Attach policies directly"**
   (Anexar políticas diretamente).
6. Busque e marque a política **`AdministratorAccess`**.

   > Em produção real isso seria um erro grave de segurança — o correto seria uma política
   > específica só com as ações de Lambda, SQS, SNS, DynamoDB, CloudWatch e Secrets Manager que
   > você vai usar. Para o escopo acadêmico deste projeto, com prazo curto, `AdministratorAccess`
   > evita que você perca tempo depurando erros de permissão em vez de implementar a função. Fica
   > registrado aqui como trade-off consciente, não como recomendação de produção.

7. Finalize a criação do usuário.
8. Clique no usuário recém-criado → aba **"Security credentials"** (Credenciais de segurança) →
   seção **"Access keys"** → **"Create access key"**.
9. Escolha o caso de uso **"Command Line Interface (CLI)"**, confirme o aviso, e clique em criar.
10. **Copie a Access Key ID e a Secret Access Key nesse momento** — a chave secreta só é mostrada
    uma vez. Salve num lugar seguro temporariamente (você vai colar no próximo passo).

### 5.2 Instalar o AWS CLI

```powershell
winget install -e --id Amazon.AWSCLI
```

Feche e reabra o PowerShell depois da instalação, para o `PATH` ser atualizado. Confirme:

```powershell
aws --version
```

**Ponto de verificação:** deve imprimir algo como `aws-cli/2.x.x Python/3.x.x Windows/...`.

### 5.3 Configurar as credenciais

```powershell
aws configure
```

Responda:

```
AWS Access Key ID [None]: <cole a access key id>
AWS Secret Access Key [None]: <cole a secret access key>
Default region name [None]: us-east-1
Default output format [None]: json
```

**Ponto de verificação:**

```powershell
aws sts get-caller-identity
```

Deve retornar um JSON com `"UserId"`, `"Account"` e `"Arn"` terminando em
`user/anderson-notifications-lambda`. Se der erro de credenciais inválidas, repita o `aws configure`
conferindo se copiou as chaves certas.

---

## 6. Passo 3 — Criar a conta New Relic e obter a license key

O New Relic tem um plano gratuito permanente (100 GB de dados por mês, sem cartão de crédito
exigido no cadastro) — mais simples que o cadastro da AWS.

1. Acesse **https://newrelic.com/signup**.
2. Cadastre-se com e-mail (pode ser o mesmo e-mail do grupo, ou o e-mail que o João Pedro já está
   usando para instrumentar `UsersAPI`/`CatalogAPI` — **pergunte ao grupo antes de criar uma conta
   nova**, porque idealmente todos os serviços da FCG devem aparecer na **mesma conta** New Relic,
   para o vídeo mostrar um dashboard único com tudo junto).
3. Confirme o e-mail.
4. No onboarding, se perguntar qual tipo de dado você vai enviar, escolha a opção de **"Report data
   via OpenTelemetry"** ou pule o onboarding guiado — vamos configurar manualmente.
5. Depois de logado, vá em **"API keys"** (ícone de engrenagem no canto superior direito → "API
   keys", ou acesse diretamente `https://one.newrelic.com/api-keys`).
6. Localize a **"License key"** (não confundir com "User key" — são coisas diferentes; a license
   key é a que serve para *enviar* dados, o formato geralmente termina em algo como `NRAL`).
7. Copie essa license key. Vamos usá-la no Passo 14 (Secrets Manager).

**Ponto de verificação:** você tem uma string de license key copiada, algo como
`eu01xx...NRAL` ou similar (o formato varia por região da conta).

---

## 7. Passo 4 — Instalar o AWS SAM CLI

```powershell
winget install -e --id Amazon.SAM-CLI
```

Feche e reabra o PowerShell. Confirme:

```powershell
sam --version
```

**Ponto de verificação:** deve imprimir `SAM CLI, version 1.1xx.x` ou superior. Se a versão for
antiga (abaixo de 1.100), rode `winget upgrade Amazon.SAM-CLI` — versões antigas podem não reconhecer
o runtime `dotnet10`.

---

## 8. Passo 5 — (Opcional, mas recomendado) Ambiente local com LocalStack

A Aula 2 de Serverless Apps ensina exatamente isso: emular os serviços da AWS localmente, sem custo
e sem depender da conta AWS o tempo todo. Recomendamos fortemente usar isso enquanto você escreve e
depura o código — reserve a AWS real só para a validação final e a gravação do vídeo.

### 8.1 Subir o LocalStack

Crie um arquivo `docker-compose.localstack.yml` numa pasta de sua preferência (ex.: dentro do
próprio repositório `NotificationsAPI`, numa pasta `local/`):

```yaml
services:
  localstack:
    image: localstack/localstack:latest
    ports:
      - "4566:4566"
    environment:
      - SERVICES=sns,sqs,dynamodb,lambda
      - DEBUG=1
    volumes:
      - "./localstack-data:/var/lib/localstack"
```

```powershell
docker compose -f local/docker-compose.localstack.yml up -d
```

**Ponto de verificação:**

```powershell
docker ps
```

Deve listar um container com a imagem `localstack/localstack`, status `Up`.

### 8.2 Criar os recursos localmente

Instale o `awslocal` (um wrapper do AWS CLI que já aponta pro LocalStack):

```powershell
pip install awscli-local
```

Crie a tabela, o tópico e a fila:

```powershell
awslocal dynamodb create-table `
  --table-name fcg-notifications `
  --attribute-definitions AttributeName=PK,AttributeType=S AttributeName=UserId,AttributeType=S AttributeName=CreatedAt,AttributeType=S `
  --key-schema AttributeName=PK,KeyType=HASH `
  --global-secondary-indexes "[{\"IndexName\":\"GSI1-UserId\",\"KeySchema\":[{\"AttributeName\":\"UserId\",\"KeyType\":\"HASH\"},{\"AttributeName\":\"CreatedAt\",\"KeyType\":\"RANGE\"}],\"Projection\":{\"ProjectionType\":\"ALL\"}}]" `
  --billing-mode PAY_PER_REQUEST

awslocal sns create-topic --name fcg-user-events
awslocal sqs create-queue --queue-name fcg-notifications-user-registered
```

Esse ambiente serve para você validar a lógica (desserialização, DynamoDB, idempotência) antes de
gastar tempo com deploy real. A forma mais prática de testar a função em si, porém, é o
`sam local invoke` (Passo 12) — ele não depende do LocalStack estar de pé.

---

## 9. Passo 6 — Preparar o repositório: remover o RabbitMQ

Abra o repositório `FIAPCloudGames-fase3-NotificationsAPI` no seu editor.

### 9.1 Remover a dependência do pacote RabbitMQ

Abra `NotificationsAPI/src/Notifications.Infrastructure/Notifications.Infrastructure.csproj` e
remova a linha:

```xml
<PackageReference Include="FiapCloudGames.RabbitMq" Version="1.0.0"/>
```

### 9.2 Apagar os processadores de mensagem do RabbitMQ

Apague estes dois arquivos (a lógica deles vai ser recriada, de forma mais simples, dentro do novo
projeto `Notifications.Functions` no Passo 11):

- `NotificationsAPI/src/Notifications.Infrastructure/Messaging/UserRegisteredEventMessageProcessor.cs`
- `NotificationsAPI/src/Notifications.Infrastructure/Messaging/PaymentProcessedEventMessageProcessor.cs`

**Não apague** `EventDispatcher.cs` nem `IEventDispatcher.cs` — esses continuam sendo usados, não
têm nada a ver com RabbitMQ especificamente.

### 9.3 Limpar o `InfrastructureServiceExtensions.cs`

Abra `NotificationsAPI/src/Notifications.Infrastructure/DependencyInjection/InfrastructureServiceExtensions.cs`
e remova a parte de registro do RabbitMQ, deixando só DynamoDB, EmailService e EventDispatcher:

```csharp
namespace Notifications.Infrastructure.DependencyInjection;

using Amazon.DynamoDBv2;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using Email;
using Messaging;
using Persistence.DynamoDb;
using Domain.Notifications;
using Application.UseCases.Handlers;

public static class InfrastructureServiceExtensions
{
    public static IServiceCollection AddInfrastructure(
        this IServiceCollection services,
        IConfiguration configuration)
    {
        services.AddSingleton(new DynamoDbOptions
        {
            TableName = configuration["DynamoDb:TableName"] ?? new DynamoDbOptions().TableName
        });

        services.AddSingleton<IAmazonDynamoDB>(_ =>
        {
            string? serviceUrl = configuration["DynamoDb:ServiceUrl"];
            return string.IsNullOrWhiteSpace(serviceUrl)
                ? new AmazonDynamoDBClient()
                : new AmazonDynamoDBClient(new AmazonDynamoDBConfig { ServiceURL = serviceUrl });
        });

        services.AddScoped<INotificationRepository, DynamoDbNotificationRepository>();
        services.AddSingleton<IEmailService, EmailService>();
        services.AddSingleton<IEventDispatcher, EventDispatcher>();

        return services;
    }
}
```

Repare que só sobrou o que já existia antes, sem as três chamadas de `AddRabbitMq*`.

**Ponto de verificação:**

```powershell
cd NotificationsAPI
dotnet build
```

Deve compilar sem erro (os testes de `Notifications.Infrastructure.Tests` e
`Notifications.Tests.Integration` que testavam os processadores de RabbitMQ vão dar erro de
compilação — apague-os também, você vai escrever testes novos para os handlers Lambda depois, se
quiser: `EventDispatcherTests.cs` pode ficar, mas
`PaymentProcessedEventMessageProcessorTests.cs` e `UserRegisteredEventMessageProcessorTests.cs`
apague, junto com `MessagingHostFixture.cs` e `UserRegisteredEventConsumerTests.cs` em
`Notifications.Tests.Integration`, que dependiam do container de teste do RabbitMQ).

---

## 10. Passo 7 — Corrigir a corrida de eventos entre cadastro e compra

Este passo é uma correção de comportamento, não uma tarefa de infraestrutura — mas é importante e é
uma lacuna real que a migração introduz, então trate como obrigatório.

### 10.1 O problema

Hoje (com um único consumidor sequencial no RabbitMQ) já existe uma corrida documentada no
`SDD.md` (risco R-01): o `PaymentProcessedEventHandler` não recebe o e-mail do usuário no evento —
ele busca uma notificação anterior do mesmo usuário (a de boas-vindas) para descobrir o e-mail. Se
não encontrar, ele **desiste silenciosamente**:

```csharp
if (reference is null)
{
    LogRecipientEmailNotFound(integrationEvent.UserId);
    return; // <- o e-mail de confirmação de compra nunca é enviado, e não há nova tentativa
}
```

Com a migração, esse risco piora: `UserRegisteredEvent` e `PaymentProcessedEvent` passam a correr em
**duas filas SQS e duas Lambdas totalmente independentes**, sem ordem garantida entre elas. Se, por
qualquer motivo, o pagamento for processado antes do evento de cadastro (ex.: retry, delay de rede),
a notificação de compra se perde de vez — e isso pode acontecer bem na hora do vídeo, numa demo ao
vivo, se o timing for infeliz.

### 10.2 A correção

Trocar "desistir silenciosamente" por "sinalizar falha temporária", para o SQS reentregar a mensagem
automaticamente (com backoff) até o cadastro já ter sido processado, ou até esgotar as tentativas e
cair na DLQ (o que aí sim é motivo para investigar, não para perder a notificação calada).

Primeiro, adicione uma exceção nova em
`NotificationsAPI/src/Notifications.Domain/Shared/`, no arquivo `RecipientNotReadyException.cs`:

```csharp
namespace Notifications.Domain.Shared;

/// <summary>
/// Sinaliza que ainda não existe notificação anterior do usuário para recuperar o e-mail de
/// destinatário (o UserRegisteredEvent provavelmente ainda não foi processado). Não é uma falha
/// real — é um estado transitório que se resolve com uma nova tentativa de entrega da fila.
/// </summary>
public class RecipientNotReadyException(Guid userId) : DomainException(
    $"Nenhuma notificação anterior encontrada para o usuário {userId}; o e-mail de destinatário " +
    "ainda não é conhecido. Provável corrida com o UserRegisteredEvent.")
{
    public Guid UserId { get; } = userId;
}
```

Agora edite `PaymentProcessedEventHandler.cs`, trocando o `return` silencioso por um `throw`:

```csharp
if (reference is null)
{
    LogRecipientEmailNotFound(integrationEvent.UserId);
    throw new RecipientNotReadyException(integrationEvent.UserId);
}
```

No Passo 11 (handler Lambda), essa exceção vai ser tratada como "falha transitória" — a mensagem
volta para a fila com o *visibility timeout* configurado, e o SQS tenta de novo automaticamente.
Como o `UserRegisteredEvent` normalmente é processado em menos de um segundo, na prática a segunda
ou terceira tentativa já encontra a notificação de boas-vindas e segue o fluxo normal.

**Ponto de verificação:** rode os testes existentes de `PaymentProcessedEventHandlerTests.cs` — o
teste que hoje verifica "quando não há e-mail conhecido, retorna sem enviar" vai precisar ser
ajustado para "quando não há e-mail conhecido, lança `RecipientNotReadyException`". Ajuste a
asserção do teste antes de seguir.

---

## 11. Passo 8 — Criar o projeto `Notifications.Functions`

Este é o coração da migração: o novo "host" da aplicação, no lugar do `Notifications.API` antigo.

### 11.1 Criar a estrutura do projeto

```powershell
cd NotificationsAPI/src
dotnet new classlib -n Notifications.Functions -f net10.0
cd Notifications.Functions
rm Class1.cs
```

Edite `Notifications.Functions.csproj` para ficar assim:

```xml
<Project Sdk="Microsoft.NET.Sdk">

    <PropertyGroup>
        <TargetFramework>net10.0</TargetFramework>
        <ImplicitUsings>enable</ImplicitUsings>
        <Nullable>enable</Nullable>
        <AWSProjectType>Lambda</AWSProjectType>
        <GenerateRuntimeConfigurationFiles>true</GenerateRuntimeConfigurationFiles>
    </PropertyGroup>

    <ItemGroup>
        <ProjectReference Include="..\Notifications.Domain\Notifications.Domain.csproj"/>
        <ProjectReference Include="..\Notifications.Application\Notifications.Application.csproj"/>
        <ProjectReference Include="..\Notifications.Infrastructure\Notifications.Infrastructure.csproj"/>
    </ItemGroup>

    <ItemGroup>
        <PackageReference Include="Amazon.Lambda.Core" Version="2.8.0"/>
        <PackageReference Include="Amazon.Lambda.RuntimeSupport" Version="1.14.1"/>
        <PackageReference Include="Amazon.Lambda.Serialization.SystemTextJson" Version="2.4.4"/>
        <PackageReference Include="Amazon.Lambda.SQSEvents" Version="2.2.0"/>
        <PackageReference Include="Microsoft.Extensions.Configuration.EnvironmentVariables" Version="10.0.0"/>
        <PackageReference Include="OpenTelemetry" Version="1.10.0"/>
        <PackageReference Include="OpenTelemetry.Exporter.OpenTelemetryProtocol" Version="1.10.0"/>
        <PackageReference Include="OpenTelemetry.Extensions.Hosting" Version="1.10.0"/>
        <PackageReference Include="OpenTelemetry.Instrumentation.AWSLambda" Version="1.15.1"/>
        <PackageReference Include="OpenTelemetry.Instrumentation.AWS" Version="1.9.1"/>
        <PackageReference Include="OpenTelemetry.Instrumentation.Http" Version="1.10.0"/>
    </ItemGroup>

</Project>
```

Adicione o projeto novo à solução:

```powershell
cd ../..
dotnet sln NotificationsAPI.slnx add src/Notifications.Functions/Notifications.Functions.csproj
```

### 11.2 O bootstrap de configuração e injeção de dependência

Crie `src/Notifications.Functions/Startup.cs`:

```csharp
namespace Notifications.Functions;

using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using Application.DependencyInjection;
using Infrastructure.DependencyInjection;

/// <summary>
/// Monta o contêiner de injeção de dependência da função. Roda uma vez por "cold start" do
/// ambiente de execução do Lambda — não a cada invocação.
/// </summary>
public static class Startup
{
    public static IServiceProvider BuildServiceProvider()
    {
        IConfigurationRoot configuration = new ConfigurationBuilder()
            .AddEnvironmentVariables()
            .Build();

        var services = new ServiceCollection();
        services.AddApplication();
        services.AddInfrastructure(configuration);

        return services.BuildServiceProvider();
    }
}
```

> **Por que variáveis de ambiente e não `appsettings.json`?** O Lambda não tem um `appsettings.json`
> versionado por ambiente da forma como o ASP.NET Core tem — a configuração de infraestrutura
> (nome da tabela, endpoint, etc.) vem inteiramente do `template.yaml`, que injeta variáveis de
> ambiente na função. Isso também combina com o padrão que o projeto já usa
> (`DynamoDb__TableName`, `DynamoDb__ServiceUrl`) — o `AddEnvironmentVariables()` do
> `Microsoft.Extensions.Configuration` entende `__` como separador de seção, então
> `configuration["DynamoDb:TableName"]` (usado dentro do `InfrastructureServiceExtensions`)
> continua funcionando sem nenhuma mudança lá.

### 11.3 O processador genérico de lote SQS

Para não duplicar a lógica de "percorrer o lote, desserializar, despachar, classificar erro" nas
duas funções, crie um helper único. Crie `src/Notifications.Functions/Processing/SqsBatchProcessor.cs`:

```csharp
namespace Notifications.Functions.Processing;

using System.Text.Json;
using Amazon.Lambda.SQSEvents;
using Microsoft.Extensions.Logging;
using Domain.Shared;

/// <summary>
/// Processa um lote de mensagens SQS, isolando o handler de negócio dos detalhes de
/// desserialização e de como cada tipo de falha deve ser reportado ao SQS.
/// </summary>
/// <remarks>
/// Mapeamento de resultado (equivalente ao <c>MessageProcessingResult</c> da era RabbitMQ):
/// <list type="bullet">
/// <item>Sucesso → mensagem não entra na resposta de falhas; o SQS a remove da fila.</item>
/// <item><see cref="DuplicateEventException"/> ou <see cref="JsonException"/> → mensagem
/// envenenada ou duplicada; logamos e NÃO reportamos como falha, para o SQS não reentregar.</item>
/// <item>Qualquer outra exceção (incluindo <see cref="RecipientNotReadyException"/>) → reportamos
/// o <c>itemIdentifier</c> como falha, o SQS reentrega com backoff, e após esgotar
/// <c>maxReceiveCount</c> a mensagem cai na DLQ.</item>
/// </list>
/// </remarks>
public static class SqsBatchProcessor
{
    public static async Task<SQSBatchResponse> ProcessAsync<TEvent>(
        SQSEvent sqsEvent,
        Func<TEvent, CancellationToken, Task> dispatch,
        ILogger logger,
        CancellationToken cancellationToken)
    {
        var failures = new List<SQSBatchResponse.BatchItemFailure>();

        foreach (SQSEvent.SQSMessage record in sqsEvent.Records)
        {
            try
            {
                TEvent? integrationEvent = JsonSerializer.Deserialize<TEvent>(record.Body);

                if (integrationEvent is null)
                {
                    logger.LogWarning(
                        "Mensagem {MessageId} desserializou para null, descartando", record.MessageId);
                    continue;
                }

                await dispatch(integrationEvent, cancellationToken);
            }
            catch (JsonException ex)
            {
                logger.LogWarning(
                    ex, "Mensagem {MessageId} malformada, descartando", record.MessageId);
            }
            catch (DuplicateEventException ex)
            {
                logger.LogWarning(
                    ex,
                    "Mensagem {MessageId} já processada anteriormente, descartando reentrega",
                    record.MessageId);
            }
            catch (Exception ex)
            {
                logger.LogError(
                    ex,
                    "Falha ao processar mensagem {MessageId}, será reenfileirada",
                    record.MessageId);
                failures.Add(new SQSBatchResponse.BatchItemFailure { ItemIdentifier = record.MessageId });
            }
        }

        return new SQSBatchResponse(failures);
    }
}
```

### 11.4 A instrumentação New Relic (OpenTelemetry)

Crie `src/Notifications.Functions/Telemetry.cs`:

```csharp
namespace Notifications.Functions;

using OpenTelemetry;
using OpenTelemetry.Resources;
using OpenTelemetry.Trace;
using OpenTelemetry.Exporter;

/// <summary>
/// Configura o pipeline de traces do OpenTelemetry, exportando via OTLP para o New Relic.
/// Instanciado uma vez por ambiente de execução (cold start), reaproveitado entre invocações.
/// </summary>
public static class Telemetry
{
    public static TracerProvider BuildTracerProvider(string serviceName)
    {
        string licenseKey = Environment.GetEnvironmentVariable("NEW_RELIC_LICENSE_KEY")
            ?? throw new InvalidOperationException("NEW_RELIC_LICENSE_KEY não configurada.");

        return Sdk.CreateTracerProviderBuilder()
            .ConfigureResource(resource => resource.AddService(serviceName))
            .AddAWSInstrumentation()
            .AddHttpClientInstrumentation()
            .AddAWSLambdaConfigurations(options => options.DisableAwsXRayContextExtraction = true)
            .AddOtlpExporter(otlp =>
            {
                otlp.Endpoint = new Uri("https://otlp.nr-data.net:4318/v1/traces");
                otlp.Protocol = OtlpExportProtocol.HttpProtobuf;
                otlp.Headers = $"api-key={licenseKey}";
            })
            .Build();
    }
}
```

> **Por que só traces aqui, e não métricas/logs também via OTel?** Para manter o primeiro corte
> simples e funcional rápido. Métricas e logs você ganha de forma mais direta: as métricas nativas
> do Lambda (`Duration`, `Errors`, `Throttles`, `ConcurrentExecutions`) chegam ao New Relic pela
> **integração nativa AWS↔New Relic** (você ativa isso uma vez, sem código — seção 17, se quiser
> aprofundar), e os logs do `ILogger`/Serilog já vão para o CloudWatch automaticamente, de onde o
> New Relic também consegue puxá-los via a mesma integração. Isso cobre os três pilares exigidos
> pela Opção B sem multiplicar exportadores OTLP diferentes por sinal. Se sobrar tempo, adicionar
> `WithMetrics`/`WithLogging` com exportador OTLP próprio (mesmo padrão do `AddOtlpExporter` acima,
> trocando o path para `/v1/metrics` e `/v1/logs`) é um refinamento, não um bloqueio.

### 11.5 Os handlers Lambda

Crie `src/Notifications.Functions/Functions.cs`:

```csharp
namespace Notifications.Functions;

using Amazon.Lambda.Core;
using Amazon.Lambda.SQSEvents;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Logging;
using OpenTelemetry.Instrumentation.AWSLambda;
using OpenTelemetry.Trace;
using Application.UseCases.Handlers;
using FiapCloudGames.Contracts.Users;
using FiapCloudGames.Contracts.Payments;
using Processing;

[assembly: LambdaSerializer(typeof(Amazon.Lambda.Serialization.SystemTextJson.DefaultLambdaJsonSerializer))]

namespace Notifications.Functions;

public class Functions
{
    private static readonly IServiceProvider ServiceProvider = Startup.BuildServiceProvider();
    private static readonly TracerProvider TracerProvider = Telemetry.BuildTracerProvider("fcg-notifications-lambda");

    /// <summary>Handler exposto ao Lambda. Configurado no template.yaml como gatilho da fila de cadastro.</summary>
    public Task<SQSBatchResponse> UserRegisteredHandler(SQSEvent sqsEvent, ILambdaContext context)
        => AWSLambdaWrapper.TraceAsync(TracerProvider, UserRegisteredHandlerInternal, sqsEvent, context);

    private async Task<SQSBatchResponse> UserRegisteredHandlerInternal(SQSEvent sqsEvent, ILambdaContext context)
    {
        await using AsyncServiceScope scope = ServiceProvider.CreateAsyncScope();
        var dispatcher = scope.ServiceProvider.GetRequiredService<IEventDispatcher>();
        var logger = scope.ServiceProvider.GetRequiredService<ILogger<Functions>>();

        return await SqsBatchProcessor.ProcessAsync<UserRegisteredEvent>(
            sqsEvent,
            (evt, ct) => dispatcher.DispatchAsync(evt, ct),
            logger,
            context.RemainingTime > TimeSpan.Zero ? default : default);
    }

    /// <summary>Handler exposto ao Lambda. Configurado no template.yaml como gatilho da fila de pagamento.</summary>
    public Task<SQSBatchResponse> PaymentProcessedHandler(SQSEvent sqsEvent, ILambdaContext context)
        => AWSLambdaWrapper.TraceAsync(TracerProvider, PaymentProcessedHandlerInternal, sqsEvent, context);

    private async Task<SQSBatchResponse> PaymentProcessedHandlerInternal(SQSEvent sqsEvent, ILambdaContext context)
    {
        await using AsyncServiceScope scope = ServiceProvider.CreateAsyncScope();
        var dispatcher = scope.ServiceProvider.GetRequiredService<IEventDispatcher>();
        var logger = scope.ServiceProvider.GetRequiredService<ILogger<Functions>>();

        return await SqsBatchProcessor.ProcessAsync<PaymentProcessedEvent>(
            sqsEvent,
            (evt, ct) => dispatcher.DispatchAsync(evt, ct),
            logger,
            CancellationToken.None);
    }
}
```

> Ajuste o parâmetro de `CancellationToken` do `ProcessAsync` na chamada acima para
> `CancellationToken.None` nas duas funções (o Lambda não expõe um `CancellationToken` de
> cancelamento cooperativo por padrão) — deixei a primeira ocorrência com uma expressão só para
> ilustrar; o padrão final e mais limpo é `CancellationToken.None` nos dois handlers.

Repare no que **não** mudou: `IEventDispatcher`, `IEventHandler<T>`, `UserRegisteredEventHandler`,
`PaymentProcessedEventHandler`, `INotificationRepository`, `DynamoDbNotificationRepository`,
`IEmailService` — nenhuma dessas classes foi tocada. É exatamente o benefício da Clean Architecture
que o próprio `SDD.md` do repositório aponta: a migração de transporte (RabbitMQ → SQS) tocou
apenas a camada de composição.

**Ponto de verificação:**

```powershell
dotnet build
```

Deve compilar sem erro.

---

## 12. Passo 9 — Escrever o `template.yaml` (infraestrutura como código)

Crie o arquivo `template.yaml` **na raiz do repositório** `FIAPCloudGames-fase3-NotificationsAPI`
(ao lado do `README.md` e do `SDD.md`, não dentro de `NotificationsAPI/`):

```yaml
AWSTemplateFormatVersion: '2010-09-09'
Transform: AWS::Serverless-2016-10-31
Description: >
  FCG NotificationsAPI - função serverless acionada por SNS+SQS, substituindo o container
  RabbitMQ sempre ativo da Fase 2. Tech Challenge Fase 3.

Parameters:
  NewRelicLicenseKeySecretName:
    Type: String
    Default: fcg/notifications/new-relic-license-key
    Description: Nome do secret no Secrets Manager que guarda a license key do New Relic.

Globals:
  Function:
    Runtime: dotnet10
    Timeout: 30
    MemorySize: 256
    Architectures:
      - x86_64
    Environment:
      Variables:
        DynamoDb__TableName: !Ref NotificationsTable
        NEW_RELIC_LICENSE_KEY: !Sub '{{resolve:secretsmanager:${NewRelicLicenseKeySecretName}}}'

Resources:

  # ---------- Persistência ----------

  NotificationsTable:
    Type: AWS::DynamoDB::Table
    Properties:
      TableName: fcg-notifications
      BillingMode: PAY_PER_REQUEST
      AttributeDefinitions:
        - AttributeName: PK
          AttributeType: S
        - AttributeName: UserId
          AttributeType: S
        - AttributeName: CreatedAt
          AttributeType: S
      KeySchema:
        - AttributeName: PK
          KeyType: HASH
      GlobalSecondaryIndexes:
        - IndexName: GSI1-UserId
          KeySchema:
            - AttributeName: UserId
              KeyType: HASH
            - AttributeName: CreatedAt
              KeyType: RANGE
          Projection:
            ProjectionType: ALL

  # ---------- Mensageria: cadastro de usuário ----------

  UserEventsTopic:
    Type: AWS::SNS::Topic
    Properties:
      TopicName: fcg-user-events

  UserRegisteredDlq:
    Type: AWS::SQS::Queue
    Properties:
      QueueName: fcg-notifications-user-registered-dlq
      MessageRetentionPeriod: 1209600 # 14 dias

  UserRegisteredQueue:
    Type: AWS::SQS::Queue
    Properties:
      QueueName: fcg-notifications-user-registered
      VisibilityTimeout: 180 # 6x o timeout da função (30s), conforme recomendação da AWS
      RedrivePolicy:
        deadLetterTargetArn: !GetAtt UserRegisteredDlq.Arn
        maxReceiveCount: 5

  UserRegisteredQueuePolicy:
    Type: AWS::SQS::QueuePolicy
    Properties:
      Queues:
        - !Ref UserRegisteredQueue
      PolicyDocument:
        Version: '2012-10-17'
        Statement:
          - Effect: Allow
            Principal:
              Service: sns.amazonaws.com
            Action: sqs:SendMessage
            Resource: !GetAtt UserRegisteredQueue.Arn
            Condition:
              ArnEquals:
                aws:SourceArn: !Ref UserEventsTopic

  UserRegisteredSubscription:
    Type: AWS::SNS::Subscription
    Properties:
      TopicArn: !Ref UserEventsTopic
      Protocol: sqs
      Endpoint: !GetAtt UserRegisteredQueue.Arn
      RawMessageDelivery: true

  # ---------- Mensageria: pagamento processado ----------

  PaymentEventsTopic:
    Type: AWS::SNS::Topic
    Properties:
      TopicName: fcg-payment-events

  PaymentProcessedDlq:
    Type: AWS::SQS::Queue
    Properties:
      QueueName: fcg-notifications-payment-processed-dlq
      MessageRetentionPeriod: 1209600

  PaymentProcessedQueue:
    Type: AWS::SQS::Queue
    Properties:
      QueueName: fcg-notifications-payment-processed
      VisibilityTimeout: 180
      RedrivePolicy:
        deadLetterTargetArn: !GetAtt PaymentProcessedDlq.Arn
        maxReceiveCount: 5

  PaymentProcessedQueuePolicy:
    Type: AWS::SQS::QueuePolicy
    Properties:
      Queues:
        - !Ref PaymentProcessedQueue
      PolicyDocument:
        Version: '2012-10-17'
        Statement:
          - Effect: Allow
            Principal:
              Service: sns.amazonaws.com
            Action: sqs:SendMessage
            Resource: !GetAtt PaymentProcessedQueue.Arn
            Condition:
              ArnEquals:
                aws:SourceArn: !Ref PaymentEventsTopic

  PaymentProcessedSubscription:
    Type: AWS::SNS::Subscription
    Properties:
      TopicArn: !Ref PaymentEventsTopic
      Protocol: sqs
      Endpoint: !GetAtt PaymentProcessedQueue.Arn
      RawMessageDelivery: true

  # ---------- Funções Lambda ----------

  UserRegisteredFunction:
    Type: AWS::Serverless::Function
    Properties:
      FunctionName: fcg-notifications-user-registered
      CodeUri: NotificationsAPI/src/Notifications.Functions/
      Handler: 'Notifications.Functions::Notifications.Functions.Functions::UserRegisteredHandler'
      AutoPublishAlias: prod
      Policies:
        - DynamoDBCrudPolicy:
            TableName: !Ref NotificationsTable
        - Statement:
            - Effect: Allow
              Action: secretsmanager:GetSecretValue
              Resource: !Sub 'arn:aws:secretsmanager:${AWS::Region}:${AWS::AccountId}:secret:${NewRelicLicenseKeySecretName}*'
      Events:
        UserRegisteredQueueEvent:
          Type: SQS
          Properties:
            Queue: !GetAtt UserRegisteredQueue.Arn
            BatchSize: 10
            MaximumBatchingWindowInSeconds: 5
            FunctionResponseTypes:
              - ReportBatchItemFailures

  PaymentProcessedFunction:
    Type: AWS::Serverless::Function
    Properties:
      FunctionName: fcg-notifications-payment-processed
      CodeUri: NotificationsAPI/src/Notifications.Functions/
      Handler: 'Notifications.Functions::Notifications.Functions.Functions::PaymentProcessedHandler'
      AutoPublishAlias: prod
      Policies:
        - DynamoDBCrudPolicy:
            TableName: !Ref NotificationsTable
        - Statement:
            - Effect: Allow
              Action: secretsmanager:GetSecretValue
              Resource: !Sub 'arn:aws:secretsmanager:${AWS::Region}:${AWS::AccountId}:secret:${NewRelicLicenseKeySecretName}*'
      Events:
        PaymentProcessedQueueEvent:
          Type: SQS
          Properties:
            Queue: !GetAtt PaymentProcessedQueue.Arn
            BatchSize: 10
            MaximumBatchingWindowInSeconds: 5
            FunctionResponseTypes:
              - ReportBatchItemFailures

Outputs:
  UserEventsTopicArn:
    Description: ARN do tópico SNS para o UsersAPI publicar UserRegisteredEvent
    Value: !Ref UserEventsTopic
  PaymentEventsTopicArn:
    Description: ARN do tópico SNS para o PaymentsAPI publicar PaymentProcessedEvent
    Value: !Ref PaymentEventsTopic
  NotificationsTableName:
    Description: Nome da tabela DynamoDB de notificações
    Value: !Ref NotificationsTable
```

Pontos deste template que merecem atenção especial (perguntas que qualquer revisor vai fazer):

- **`UserRegisteredQueuePolicy` / `PaymentProcessedQueuePolicy`:** sem essas políticas explícitas, o
  SNS não tem permissão para publicar nas filas SQS, e a subscription fica "confirmada" mas nunca
  entrega nada — um erro silencioso muito comum e difícil de depurar. Não pule essas duas
  policies.
- **`RawMessageDelivery: true`:** sem isso, o corpo da mensagem SQS vem embrulhado num envelope JSON
  do SNS, e o `JsonSerializer.Deserialize<UserRegisteredEvent>` do `SqsBatchProcessor` falharia.
- **`VisibilityTimeout: 180`** (6x o timeout de 30s da função): é a recomendação oficial da AWS para
  event source mapping — evita que a mesma mensagem seja entregue de novo a outra invocação antes da
  primeira terminar de processar.
- **`FunctionResponseTypes: [ReportBatchItemFailures]`:** sem isso, uma única mensagem com erro
  faz o SQS reentregar o **lote inteiro**, incluindo mensagens que você já processou com sucesso.

---

## 13. Passo 10 — `samconfig.toml`

Crie, também na raiz do repositório:

```toml
version = 0.1

[default.deploy.parameters]
stack_name = "fcg-notifications-serverless"
region = "us-east-1"
capabilities = "CAPABILITY_IAM"
confirm_changeset = true
resolve_s3 = true
parameter_overrides = "NewRelicLicenseKeySecretName=\"fcg/notifications/new-relic-license-key\""
```

---

## 14. Passo 11 — Guardar a license key do New Relic no Secrets Manager

Antes do primeiro deploy, o segredo precisa existir (o `template.yaml` só *lê* o segredo, não o
cria):

```powershell
aws secretsmanager create-secret `
  --name fcg/notifications/new-relic-license-key `
  --secret-string "<cole-a-sua-license-key-aqui>" `
  --region us-east-1
```

**Ponto de verificação:**

```powershell
aws secretsmanager get-secret-value --secret-id fcg/notifications/new-relic-license-key --region us-east-1
```

Deve retornar um JSON com `"SecretString"` contendo a sua license key.

> **Nota de segurança para o relatório/vídeo:** a referência `{{resolve:secretsmanager:...}}` no
> `template.yaml` faz o CloudFormation resolver o valor **em tempo de deploy** e colocá-lo como
> variável de ambiente da função. Isso significa que o valor fica visível em texto puro no console
> do Lambda (aba "Configuration → Environment variables"), embora não fique gravado no arquivo
> `template.yaml` versionado no Git. Para o escopo acadêmico isso é aceitável e é exatamente o que
> o `SDD.md` do repositório já previa; vale mencionar essa limitação no relatório de entrega como
> "ponto de atenção" consciente, não como algo que passou despercebido.

---

## 15. Passo 12 — Testar localmente antes de publicar

### 15.1 Build

Na raiz do repositório (onde está o `template.yaml`):

```powershell
sam build
```

**Ponto de verificação:** deve terminar com `Build Succeeded` e listar os dois recursos
`UserRegisteredFunction` e `PaymentProcessedFunction`.

### 15.2 Invocar a função localmente com um evento fake

Crie uma pasta `events/` na raiz do repositório e o arquivo `events/user-registered.json`:

```json
{
  "Records": [
    {
      "messageId": "059f36b4-87a3-44ab-83d2-661975830a7d",
      "receiptHandle": "fake-receipt-handle",
      "body": "{\"eventId\":\"3fa85f64-5717-4562-b3fc-2c963f66afa6\",\"occurredAt\":\"2026-09-02T12:00:00Z\",\"userId\":\"3fa85f64-5717-4562-b3fc-2c963f66afa7\",\"name\":\"Ana Teste\",\"email\":\"ana.teste@exemplo.com\"}",
      "attributes": {
        "ApproximateReceiveCount": "1",
        "SentTimestamp": "1545082649183",
        "SenderId": "AIDAIENQZJOLO23YVJ4VO",
        "ApproximateFirstReceiveTimestamp": "1545082649185"
      },
      "messageAttributes": {},
      "md5OfBody": "e4e68fb7bd0e697a0ae8f1bb342846b3",
      "eventSource": "aws:sqs",
      "eventSourceARN": "arn:aws:sqs:us-east-1:123456789012:fcg-notifications-user-registered",
      "awsRegion": "us-east-1"
    }
  ]
}
```

```powershell
sam local invoke UserRegisteredFunction --event events/user-registered.json
```

Isso vai baixar/usar uma imagem Docker que emula o ambiente Lambda, rodar sua função de verdade
(incluindo a chamada real ao DynamoDB — para isso funcionar offline, aponte
`AWS_ENDPOINT_URL_DYNAMODB` para o LocalStack do Passo 8, ou aceite que essa chamada específica vai
para o DynamoDB real da AWS, que também funciona se você já tiver a tabela criada por lá).

**Ponto de verificação:** a saída do comando deve mostrar os logs da função — incluindo a linha de
log `"Processando evento UserRegisteredEvent para usuário ... (Ana Teste)"` vinda do
`UserRegisteredEventHandler` — e terminar retornando `{"BatchItemFailures":[]}` (lote processado sem
falhas).

Repita o mesmo processo criando `events/payment-processed.json` com o corpo de um
`PaymentProcessedEvent` e testando `PaymentProcessedFunction`.

---

## 16. Passo 13 — Deploy real na AWS

```powershell
sam deploy
```

Como o `samconfig.toml` já tem os parâmetros, o SAM não deveria perguntar nada além da confirmação
do changeset (por causa de `confirm_changeset = true`) — revise a lista de recursos que serão
criados e confirme com `y`.

**Ponto de verificação:**

```powershell
aws cloudformation describe-stacks --stack-name fcg-notifications-serverless --query "Stacks[0].StackStatus"
```

Deve retornar `"CREATE_COMPLETE"` (ou `"UPDATE_COMPLETE"` em deploys seguintes).

Confirme visualmente no console: acesse o serviço **Lambda** no AWS Management Console, região
`us-east-1` — devem aparecer as funções `fcg-notifications-user-registered` e
`fcg-notifications-payment-processed`. Acesse o serviço **SQS** — devem existir as 4 filas
(2 principais + 2 DLQ). Acesse **SNS** — devem existir os 2 tópicos, cada um com 1 subscription
confirmada (status `Confirmed`, não `Pending confirmation`).

---

## 17. Passo 14 — Testar ponta a ponta na nuvem

Antes de mexer nos outros repositórios (Passo 18), valide a Lambda sozinha, publicando diretamente
no tópico SNS pela linha de comando:

```powershell
$topicArn = aws cloudformation describe-stacks `
  --stack-name fcg-notifications-serverless `
  --query "Stacks[0].Outputs[?OutputKey=='UserEventsTopicArn'].OutputValue" `
  --output text

aws sns publish --topic-arn $topicArn --message '{"eventId":"11111111-1111-1111-1111-111111111111","occurredAt":"2026-09-02T12:00:00Z","userId":"22222222-2222-2222-2222-222222222222","name":"Teste Ponta a Ponta","email":"teste@exemplo.com"}'
```

**Pontos de verificação, em ordem:**

1. **CloudWatch Logs:** no console, vá em CloudWatch → Log groups →
   `/aws/lambda/fcg-notifications-user-registered`. Deve aparecer um log stream novo, com a
   invocação e a linha `"Notificação de boas-vindas criada com sucesso para usuário ..."`.
2. **DynamoDB:** vá em DynamoDB → Tables → `fcg-notifications` → "Explore table items". Deve
   aparecer um item novo com `PK = EVENT#11111111-...`.
3. **New Relic:** acesse `https://one.newrelic.com`, vá em **APM & Services** ou **Distributed
   tracing** e procure pelo serviço `fcg-notifications-lambda`. Deve aparecer um trace da
   invocação.

Se o passo 1 funcionar mas o passo 3 não, o problema está na instrumentação OTel/New Relic
(confira a license key no Secrets Manager e a política de permissão da função). Se o passo 1 nem
aparece, o problema é anterior — confira se a subscription SNS→SQS está `Confirmed` e se a
`QueuePolicy` foi aplicada.

Repita publicando no tópico de pagamento para validar a segunda função.

---

## 18. Passo 15 — Coordenar os publishers SNS com o grupo

Este é o único passo desta frente que depende de outros repositórios. Envie a informação abaixo para
quem mantém `UsersAPI` e `PaymentsAPI` (com os ARNs reais do seu deploy, pegos no `sam deploy` ou via
`aws cloudformation describe-stacks`):

> "A Lambda de notificações já está no ar. Para ela ser acionada, o `UsersAPI` precisa publicar o
> `UserRegisteredEvent` no tópico SNS `arn:aws:sns:us-east-1:<conta>:fcg-user-events`, e o
> `PaymentsAPI` precisa publicar o `PaymentProcessedEvent` em
> `arn:aws:sns:us-east-1:<conta>:fcg-payment-events` — **além** de continuar publicando no
> RabbitMQ como hoje, porque o `catalog-api` ainda depende do RabbitMQ para liberar o jogo na
> biblioteca. O contrato do evento (classe/propriedades) não muda, só ganha um publisher novo."

Exemplo de código para eles adicionarem (adaptação mínima, mesmo padrão em ambos os serviços):

```csharp
// Program.cs ou Startup, registrar o cliente:
builder.Services.AddSingleton<IAmazonSimpleNotificationService, AmazonSimpleNotificationServiceClient>();
```

```csharp
// No ponto onde hoje publicam no RabbitMQ, adicionar:
public class SnsEventPublisher(IAmazonSimpleNotificationService sns, IConfiguration configuration)
{
    public async Task PublishAsync<TEvent>(TEvent integrationEvent, string topicArnConfigKey, CancellationToken ct)
    {
        string topicArn = configuration[topicArnConfigKey]
            ?? throw new InvalidOperationException($"Configuração '{topicArnConfigKey}' não encontrada.");

        await sns.PublishAsync(new PublishRequest
        {
            TopicArn = topicArn,
            Message = JsonSerializer.Serialize(integrationEvent)
        }, ct);
    }
}
```

Pacote NuGet necessário nos dois repositórios: `AWSSDK.SimpleNotificationService`. Como eles também
vão precisar de uma conta/credenciais AWS para isso funcionar, alinhe com o grupo se vão usar a
mesma conta compartilhada (a do Pedro) ou credenciais próprias — isso é além do escopo desta sua
frente, mas você é quem tem a informação técnica para orientar.

---

## 19. Passo 16 — CI/CD (opcional, se sobrar tempo)

O `ci.yml` que já existe no repositório (build + test) continua válido sem mudanças — ele não sabe
nada sobre Lambda, só compila e testa a solução inteira, o que já cobre o novo
`Notifications.Functions`.

Se quiser automatizar o deploy, crie `.github/workflows/deploy.yml` usando OIDC (sem chave estática
da AWS no GitHub):

```yaml
name: Deploy

on:
  push:
    branches: [main]

permissions:
  id-token: write
  contents: read

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: aws-actions/configure-aws-credentials@v4
        with:
          role-to-assume: arn:aws:iam::<conta>:role/github-actions-deploy
          aws-region: us-east-1
      - uses: aws-actions/setup-sam@v2
      - run: sam build
      - run: sam deploy --no-confirm-changeset --no-fail-on-empty-changeset
```

Isso exige criar uma IAM Role com *trust policy* para o OIDC provider do GitHub — é um passo
avançado, com potencial de consumir tempo desproporcional ao benefício num projeto acadêmico com
prazo curto. **Recomendação:** trate como opcional; priorize os passos 1–15, que cobrem todos os
requisitos obrigatórios. Faça o CI/CD só se sobrar tempo depois de tudo funcionar e o vídeo estar
roteirizado.

---

## 20. Roteiro da sua parte no vídeo (até ~4 minutos dentro dos 20 totais)

O enunciado pede, para o vídeo: *"Demonstrar a Função Serverless sendo acionada e exibir seus logs
na plataforma centralizada."* Sugestão de roteiro:

1. (30s) Mostrar o `template.yaml` no editor, explicando rapidamente: "aqui está a infraestrutura
   como código — dois tópicos SNS, duas filas SQS com DLQ, a tabela DynamoDB e as duas funções
   Lambda."
2. (30s) Mostrar o console da AWS: Lambda com as duas funções, SQS com as filas, SNS com os
   tópicos e as subscriptions confirmadas.
3. (60s) Executar uma ação real no sistema (cadastro de usuário via `UsersAPI`, ou uma compra via
   `PaymentsAPI`) que dispare o evento de verdade — não simular via CLI, para mostrar o fluxo real
   ponta a ponta.
4. (30s) Mostrar o CloudWatch Logs da função sendo populado em tempo real, com a mensagem
   processada.
5. (60s) Mostrar o New Relic: o trace da invocação em "Distributed tracing", e as métricas
   nativas de invocação/duração/erros do Lambda no dashboard de APM.
6. (30s) Mostrar o item gravado no DynamoDB (console → Explore table items), fechando o ciclo:
   "evento publicado → fila → Lambda → gravado no NoSQL, sem nenhum container ligado esperando."

---

## 21. Checklist final dos requisitos obrigatórios (desta frente)

| Requisito do enunciado | Onde este tutorial atende |
|---|---|
| Refatorar `NotificationsAPI` para função serverless | Passos 9–11 (`Notifications.Functions`) |
| Acionada diretamente por mensagem de fila/tópico | Passo 12 (`template.yaml`: SNS → SQS → Lambda via event source mapping) |
| Substituir o container 24/7 | Nenhum componente novo fica ligado continuamente — SNS/SQS/Lambda são 100% sob demanda |
| Código + IaC em repositório próprio | Mesmo repositório `FIAPCloudGames-fase3-NotificationsAPI`, `template.yaml` na raiz |
| Agente de APM configurado na função serverless (Opção B) | Passo 11.4 (OpenTelemetry → New Relic OTLP) |
| Métricas da função (Opção B) | CloudWatch nativo + integração AWS↔New Relic (Passo 17) |
| Logs da função centralizados (Opção B) | Serilog → stdout → CloudWatch Logs (automático) |
| Traces da função (Opção B) | `AWSLambdaWrapper.TraceAsync` + `AddAWSInstrumentation` (Passo 11.4) |
| NoSQL obrigatório | Já implementado pelo Pedro (`DynamoDbNotificationRepository`) — reaproveitado sem mudança |
| Vídeo: função sendo acionada + logs centralizados | Roteiro na seção 20 |

O que **não** é responsabilidade desta frente, mas aparece citado aqui para você não confundir
escopo: trace distribuído completo do fluxo "Compra de Jogo" ponta a ponta (`PaymentsAPI` → SNS →
Lambda) depende de instrumentação em `PaymentsAPI` também — isso é trabalho do dono daquele repo,
mas exige que ele também injete o `traceparent` como atributo de mensagem no `PublishRequest` para o
trace não aparecer quebrado em dois pedaços no New Relic. Vale avisar quem mantém o `PaymentsAPI`
sobre isso, mesmo não sendo sua tarefa direta de implementação.

---

## 22. Recomendação final de como seguir

Nesta ordem, considerando o prazo do grupo (~15/09) e a meta informal de "80% pronto numa sexta"
que vocês combinaram:

1. **Primeiro, o que não depende de ninguém** (Passos 1–14): conta AWS, conta New Relic, remover
   RabbitMQ, criar `Notifications.Functions`, escrever o `template.yaml`, testar localmente e fazer
   o primeiro deploy real. Isso é 100% possível de terminar sozinho, sem esperar o grupo.
2. **Valide sozinho, publicando direto no SNS via CLI** (Passo 17), antes de pedir para alguém mexer
   em outro repositório. Isso separa dois tipos de problema (sua infraestrutura vs. integração
   entre repos) e evita perder tempo depurando o lugar errado.
3. **Só depois**, abra a conversa de coordenação (Passo 18) com quem mantém `UsersAPI` e
   `PaymentsAPI`. Como o `PaymentsAPI` precisa publicar em dois lugares (RabbitMQ e SNS), dê a eles
   o trecho de código pronto — isso reduz o custo de coordenação a uma revisão de PR, não uma
   implementação do zero.
4. **Aplique a correção da corrida de eventos (Passo 7) antes da gravação do vídeo**, não depois.
   É o tipo de bug que só aparece na hora errada — numa demonstração ao vivo, com timing
   imprevisível entre cadastro e compra.
5. **Reserve tempo para o teste ponta a ponta com o fluxo real** (cadastro de verdade via
   `UsersAPI`, compra de verdade via `PaymentsAPI`) pelo menos um dia antes de gravar o vídeo —
   não na hora de gravar. Distributed tracing entre serviços via broker é, segundo o próprio
   `SDD.md` do repositório, "o detalhe mais fácil de errar em toda a Fase 3".
6. **Priorize o obrigatório sobre o refinamento.** Métricas/logs OTLP diretos (em vez de via
   integração nativa AWS↔New Relic) e o pipeline de CI/CD com OIDC (Passo 19) são melhorias, não
   requisitos — só invista tempo neles depois que a checklist da seção 21 estiver 100% verde.

---

## 23. Revisão do documento: lacunas e riscos conhecidos

Revisão final, feita de propósito depois de escrever todo o tutorial, procurando o que ficou de fora
ou pode falhar:

- **Concorrência da conta compartilhada.** O grupo decidiu usar a conta AWS pessoal do Pedro. Se
  você e ele fizerem deploy da mesma stack (`fcg-notifications-serverless`) a partir de máquinas
  diferentes sem coordenar, o segundo `sam deploy` pode sobrescrever configuração do primeiro sem
  aviso — o `samconfig.toml` não impede isso. **Ação:** combine com o Pedro quem faz o deploy
  "oficial" que aparece no vídeo, e trate o `template.yaml` como fonte da verdade versionada no Git,
  não o estado da conta AWS.
- **O secret do New Relic precisa existir antes do primeiro `sam deploy`.** Se alguém rodar
  `sam deploy` numa conta AWS nova (ex.: numa tentativa de recriar do zero) sem antes rodar o
  comando do Passo 14, o deploy falha com um erro de CloudFormation sobre a referência dinâmica não
  resolvida. Isso está documentado no Passo 14, mas é fácil esquecer ao reproduzir o ambiente em
  outra conta — vale adicionar ao `README.md` do repositório como pré-requisito de deploy.
- **A correção da corrida de eventos (Passo 7) muda o comportamento observável do sistema.** Antes,
  um pagamento sem cadastro prévio conhecido falhava silenciosamente (sem e-mail nenhum). Depois da
  correção, a mensagem fica retentando por até `maxReceiveCount × visibility timeout` (até 15
  minutos) antes de cair na DLQ. Isso é uma melhoria de corretude, mas é uma mudança de
  comportamento que vale mencionar no relatório de entrega, para não parecer uma regressão não
  intencional caso alguém teste um cenário artificial de "pagamento sem cadastro" (que, nesse caso,
  vai legitimamente para a DLQ depois de 5 tentativas — comportamento esperado, não um bug).
- **Testes automatizados do projeto `Notifications.Functions` não foram escritos neste tutorial.**
  O repositório já tem a cultura de testar cada camada (`Notifications.Domain.Tests`,
  `Notifications.Application.Tests`, etc.); o ideal seria um `Notifications.Functions.Tests` com um
  `SQSEvent` fake cobrindo os três cenários do `SqsBatchProcessor` (sucesso, evento duplicado,
  falha transitória). Ficou fora do escopo deste tutorial por tempo, mas é a lacuna mais visível
  para quem for revisar o código depois — considere adicionar se sobrar tempo antes da entrega.
- **A propagação de trace através do broker (SNS/SQS) para o fluxo "Compra de Jogo" completo
  depende do `PaymentsAPI`**, como já registrado na seção 21. Isso não é uma lacuna deste tutorial
  — é uma dependência externa genuína — mas fica marcado aqui para não ser esquecido na
  coordenação do Passo 18.
- **Regiões:** todo o tutorial assume `us-east-1`. Se a conta do Pedro (ou a sua) tiver alguma
  restrição regional (ex.: New Relic com data center configurado para "EU" em vez de "US"), o
  endpoint OTLP do Passo 11.4 muda de `otlp.nr-data.net` para `otlp.eu01.nr-data.net`. Confira isso
  ao criar a conta New Relic (Passo 6) antes de copiar o endpoint deste documento sem verificar.
