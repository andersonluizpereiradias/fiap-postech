# Como testar e demonstrar a frente Serverless (Lambda) — roteiro para o vídeo

> **Para quem é este documento:** Anderson (frente 2 — Serverless / AWS Lambda).
> É um passo a passo para você **testar a sua parte funcionando** e **gravar o
> trecho do vídeo**, mostrando a função Lambda sendo acionada por mensagem e
> gerando logs (que é exatamente o que o enunciado exige provar).
>
> Tudo aqui usa os recursos **reais já publicados na AWS** (conta
> `450753703903`, região `us-east-1` / N. Virginia) pela stack
> `fcg-notifications-serverless`. Você não precisa criar nada — só **acionar e
> observar**.

---

## 0. Panorama — o que você vai mostrar (e por quê)

O que a sua frente entregou: o antigo `NotificationsAPI`, que era um **container
sempre ligado (24/7) consumindo RabbitMQ**, virou uma **função Lambda que só
executa quando chega uma mensagem**. O caminho de uma notificação hoje é:

```
UsersAPI / PaymentsAPI  →  Tópico SNS  →  Fila SQS  →  Lambda  →  DynamoDB
   (produtor)              (fan-out)      (buffer)    (processa)   (persiste)
                                                          │
                                                          └─→ CloudWatch Logs (logs)
                                                          └─→ New Relic (APM: traces + métricas)
```

São **duas** funções (uma para cada tipo de evento):

| Função Lambda | Acionada por (fila SQS) | Que evento trata |
|---|---|---|
| `fcg-notifications-user-registered` | `fcg-notifications-user-registered` | Cadastro de usuário → e-mail de boas-vindas |
| `fcg-notifications-payment-processed` | `fcg-notifications-payment-processed` | Pagamento aprovado → confirmação de compra |

**A frase-chave que você vai provar no vídeo:** *"não existe mais nenhum
container de notificação rodando o tempo todo; a função só ‘acorda’ quando
chega um evento, processa e volta a custar zero"*.

---

## 1. Pré-requisitos (checar 5 min antes de gravar)

Abra o **PowerShell** e rode, um por vez:

```powershell
# 1) Confirma que o AWS CLI está apontando para a conta certa (deve retornar Account = 450753703903)
aws sts get-caller-identity

# 2) Confirma que a stack serverless está de pé (deve retornar CREATE_COMPLETE ou UPDATE_COMPLETE)
aws cloudformation describe-stacks --stack-name fcg-notifications-serverless --region us-east-1 --query "Stacks[0].StackStatus"

# 3) Confirma os ARNs/nomes reais (útil para copiar na hora da demo)
aws cloudformation describe-stacks --stack-name fcg-notifications-serverless --region us-east-1 --query "Stacks[0].Outputs"
```

O passo 3 deve devolver algo assim (guarde à mão):

- `UserEventsTopicArn` = `arn:aws:sns:us-east-1:450753703903:fcg-user-events`
- `PaymentEventsTopicArn` = `arn:aws:sns:us-east-1:450753703903:fcg-payment-events`
- `NotificationsTableName` = `fcg-notifications`

**Login no Console AWS (para a parte visual do vídeo):** acesse
<https://console.aws.amazon.com/>, entre com o usuário IAM `fcg-fiap-aws` da
conta `450753703903`, e **no canto superior direito troque a região para
`N. Virginia (us-east-1)`**. ⚠️ Se a região estiver errada, os recursos "somem"
da tela — é o erro nº 1 em demo.

---

## 2. Onde ver cada recurso no Console AWS (para mostrar na tela)

Faça este tour **antes** de acionar nada, para o espectador entender a
arquitetura. Depois você aciona e volta nessas telas para ver os números
mudarem.

### 2.1. A função Lambda (a estrela do vídeo)

1. No campo de busca do topo do Console, digite **Lambda** e abra o serviço.
   (Link direto: <https://us-east-1.console.aws.amazon.com/lambda/home?region=us-east-1#/functions>)
2. No campo "Functions", filtre por `fcg-notifications`. Vão aparecer as **duas
   funções**.
3. Clique em **`fcg-notifications-user-registered`**. Mostre, nesta ordem:
   - **Aba "Code" → "Runtime settings"**: mostre **Runtime = `.NET 10`** e o
     **Handler** (`Notifications.Functions::Notifications.Functions.Functions::UserRegisteredHandler`).
     ⚠️ **O editor de código embutido vai aparecer desabilitado com a mensagem
     "O editor de código não é compatível com o runtime .NET 10" — isto é
     normal.** O console só edita runtimes interpretados (Node/Python/Ruby); .NET
     é compilado e sobe como pacote pronto, então não dá para ver/editar o fonte
     ali. **Não é erro.** Para mostrar o código-fonte no vídeo, use o seu
     **editor (Cursor/VS Code)** ou o **GitHub** do repositório
     (projeto `Notifications.Functions`) — fale que é o mesmo domínio da Fase 2,
     só reempacotado como Lambda.
   - **Aba "Configuration" → "Triggers"**: aqui aparece o **gatilho SQS**
     (`fcg-notifications-user-registered`). **Este é o ponto mais importante da
     sua entrega** — prove que a função é disparada por mensagem de fila, não
     por um servidor ligado. Fale a frase: *"o trigger é a fila; sem mensagem,
     a função não roda"*.
   - **Aba "Configuration" → "Environment variables"**: mostre
     `DynamoDb__TableName = fcg-notifications` e que a `NEW_RELIC_LICENSE_KEY`
     vem do Secrets Manager (não está em texto puro — bom para citar boa
     prática de segurança).
   - **Aba "Aliases"**: existe o alias `prod` (publicação versionada).
4. **Aba "Monitor"**: os gráficos de **Invocations, Duration, Error count,
   Throttles**. Antes de acionar estará zerado/baixo; depois você volta aqui
   para mostrar o pico. Botão **"View CloudWatch logs"** leva direto aos logs
   (próxima seção).

### 2.2. CloudWatch Logs (a prova dos logs — obrigatório no enunciado)

1. Busque **CloudWatch** no topo → menu esquerdo **"Log groups"**.
   (Link: <https://us-east-1.console.aws.amazon.com/cloudwatch/home?region=us-east-1#logsV2:log-groups>)
2. Filtre por `fcg-notifications`. Vão aparecer dois grupos:
   - `/aws/lambda/fcg-notifications-user-registered`
   - `/aws/lambda/fcg-notifications-payment-processed`
3. Clique no primeiro → abra o **"Log stream"** mais recente. É aqui que, depois
   de acionar, vai aparecer a linha:
   > `Notificação de boas-vindas criada com sucesso para usuário ...`

### 2.3. DynamoDB (onde a notificação fica gravada — cobre o NoSQL)

1. Busque **DynamoDB** → menu esquerdo **"Tables"** → clique em
   **`fcg-notifications`**.
   (Link: <https://us-east-1.console.aws.amazon.com/dynamodbv2/home?region=us-east-1#tables>)
2. Botão **"Explore table items"** → **"Run"**. Depois de acionar as funções,
   vão aparecer os itens (`PK = EVENT#...`, `Type = WelcomeEmail` /
   `PurchaseConfirmation`, `Status = Pending`).

### 2.4. SNS e SQS (o "encanamento" que substituiu o RabbitMQ)

- **SNS** (tópicos): busque **SNS** → **"Topics"** → verá `fcg-user-events` e
  `fcg-payment-events`. Em cada tópico, aba **"Subscriptions"** mostra a fila SQS
  inscrita — prove que o tópico entrega na fila.
- **SQS** (filas): busque **SQS** → verá as filas
  `fcg-notifications-user-registered` e `-payment-processed`, cada uma com a sua
  **DLQ** (`-dlq`). Cite que a DLQ segura mensagens que falharem 5 vezes (isso
  é resiliência — bom ponto para o vídeo).

### 2.5. (Opcional, mas impressiona) New Relic — APM, traces e métricas

1. Acesse <https://one.newrelic.com/> e entre na conta **`8469551`**.
2. **Traces / APM:** menu **"APM & Services"** (ou "All entities") → busque
   `fcg-notifications`. Abra a entidade → **"Distributed tracing"** para mostrar
   um trace da execução da Lambda (isso cobre o requisito de *trace* + *agente
   de APM*).
3. **Métricas nativas da Lambda (via integração AWS↔New Relic):** menu
   **"Query your data"** (query builder NRQL) e cole:
   ```sql
   SELECT sum(provider.invocations.Sum), average(provider.duration.Average), sum(provider.errors.Sum)
   FROM ServerlessSample
   WHERE entityName LIKE 'fcg-notifications%'
   SINCE 60 minutes ago
   ```
   Mostra invocações, duração média e erros vindos do CloudWatch para o New
   Relic, **sem nenhum agente instalado na função** (só polling da integração).

---

## 3. Acionando a função — a demonstração em si

Você tem 3 formas. **Para o vídeo, use a Forma A** (é a mais simples, rápida e
que nunca falha ao vivo). A Forma B é o "prato cheio" se sobrar tempo. A Forma C
é plano B caso a internet/AWS falhe na hora.

> ⚠️ **Ordem importa:** acione **primeiro** o `user-registered` e **depois** o
> `payment-processed`. A função de pagamento busca o e-mail do destinatário na
> notificação de boas-vindas que já existe — os dois arquivos de teste usam o
> **mesmo `UserId`** (`66666666-...`) de propósito para isso funcionar. Se rodar
> o pagamento sem ter rodado o cadastro antes, a função lança
> `RecipientNotReadyException` (comportamento correto, mas não é o que você quer
> mostrar).

### Forma A — Publicar direto no tópico SNS (recomendada para o vídeo)

Isso simula exatamente o que o `UsersAPI`/`PaymentsAPI` fazem: jogam uma
mensagem no tópico SNS. O SNS entrega na SQS, que aciona a Lambda.

No PowerShell, vá para a pasta do repositório (onde estão os arquivos de teste):

```powershell
cd "$HOME\OneDrive\Projetos\projetos-fiap\fiap_cloud-games_3\FIAPCloudGames-fase3-NotificationsAPI"
```

**1) Deixe os logs rolando na tela** (abra uma segunda janela do PowerShell só
para isto — fica lindo no vídeo, os logs aparecem "ao vivo"):

```powershell
aws logs tail /aws/lambda/fcg-notifications-user-registered --follow --since 1m --region us-east-1
```

**2) Na primeira janela, dispare o evento de cadastro:**

```powershell
aws sns publish `
  --topic-arn arn:aws:sns:us-east-1:450753703903:fcg-user-events `
  --message file://local/test-user-registered-message.json `
  --region us-east-1
```

> 🔴 **Nunca** passe o JSON inline (`--message '{...}'`) no PowerShell — ele
> corrompe as aspas e a Lambda quebra com erro de JSON. **Sempre** use
> `--message file://caminho.json`, como acima. Os arquivos de teste já estão
> prontos e no formato correto (PascalCase) em `local/`.

Em 5–10 segundos, na janela dos logs vai aparecer:
> `Notificação de boas-vindas criada com sucesso para usuário 66666666-6666-6666-6666-666666666666`

**3) Agora o evento de pagamento** (troque o tail para a outra função, ou abra
mais uma janela):

```powershell
# opcional: seguir os logs da função de pagamento
aws logs tail /aws/lambda/fcg-notifications-payment-processed --follow --since 1m --region us-east-1
```

```powershell
aws sns publish `
  --topic-arn arn:aws:sns:us-east-1:450753703903:fcg-payment-events `
  --message file://local/test-payment-processed-message.json `
  --region us-east-1
```

Log esperado:
> `Processando evento PaymentProcessedEvent para usuário 66666666-... (status Approved)`

**4) Mostre a persistência** — volte ao Console do DynamoDB (seção 2.3),
"Explore table items" → "Run", e aponte os dois itens novos:
- `PK = EVENT#55555555-5555-5555-5555-555555555555`, `Type = WelcomeEmail`
- `PK = EVENT#88888888-8888-8888-8888-888888888888`, `Type = PurchaseConfirmation`

Ou, por linha de comando, para conferir rápido:

```powershell
aws dynamodb scan --table-name fcg-notifications --max-items 10 --region us-east-1
```

**5) Feche o ciclo** voltando na aba **"Monitor"** da Lambda (seção 2.1) e mostre
o gráfico de **Invocations** subindo — prova visual de que a função executou por
demanda.

### Forma B — Fluxo real ponta a ponta (opcional, "prato cheio")

Em vez de publicar no SNS "na mão", faça um **cadastro de usuário / compra de
verdade** na aplicação e mostre a notificação nascendo daí. Isso prova a
integração completa (produtor real → SNS → Lambda).

1. Suba as APIs com credenciais AWS válidas (elas precisam publicar no SNS real).
   No repositório `FIAPCloudGames-fase3-Orchestration` há o `docker-compose.yml`
   com as variáveis `Sns__TopicArn`, `AWS_REGION` e credenciais — preencha o
   `.env` local (não versionado) e suba com `docker compose up`.
2. Faça um **POST de cadastro** no `UsersAPI` (ou uma compra no `PaymentsAPI`,
   passando pelo Kong se quiser mostrar o gateway junto).
3. Volte ao CloudWatch Logs e ao DynamoDB e mostre a notificação gerada.

> ⚠️ Esta forma ainda **não foi validada ao vivo** (só por testes automatizados
> com LocalStack). **Teste antes de gravar**, não deixe para descobrir na hora.
> Se não der tempo de validar, use a Forma A com tranquilidade — ela prova o
> mesmo requisito (função acionada por mensagem + logs).

### Forma C — 100% local, sem AWS (plano B de emergência)

Se a AWS/internet falhar na hora, dá para invocar a função localmente com o
evento de exemplo (precisa de Docker Desktop aberto e `sam build` feito):

```powershell
cd "$HOME\OneDrive\Projetos\projetos-fiap\fiap_cloud-games_3\FIAPCloudGames-fase3-NotificationsAPI"
sam build
sam local invoke UserRegisteredFunction --event events/user-registered.json --env-vars env.local.json
```

Mostra a função executando e logando no seu terminal. É menos impressionante que
a nuvem real, mas serve de prova de funcionamento.

---

## 4. Roteiro sugerido do seu trecho de vídeo (~3–4 min)

Grave a tela (OBS, Zoom ou o gravador do Windows) narrando:

| # | Cena | O que falar / mostrar |
|---|---|---|
| 1 | Slide/fala de abertura | "Minha parte foi migrar o NotificationsAPI de um container 24/7 para funções Lambda acionadas por mensageria." Mostre o diagrama da seção 0. |
| 2 | Console → Lambda | Abra as 2 funções. Foque na aba **Triggers** (SQS) e diga: "sem servidor ligado; o gatilho é a fila". Em "Runtime settings" mostre Runtime `.NET 10` + Handler. **Não** tente mostrar o fonte na aba Code (fica desabilitado por ser .NET — mostre o código no editor/GitHub à parte). |
| 3 | Console → SNS/SQS | Mostre o tópico e a fila inscrita — "isto substituiu o RabbitMQ da Fase 2". |
| 4 | PowerShell (logs `tail` rodando) + `aws sns publish` | **Dispare o evento ao vivo** e mostre o log aparecendo em segundos. Este é o clímax e o requisito obrigatório. |
| 5 | Console → CloudWatch Logs | Mostre a linha de log de sucesso (logs centralizados). |
| 6 | Console → DynamoDB | "Explore items": a notificação persistida (cobre o NoSQL). |
| 7 | Console → Lambda → Monitor | Gráfico de Invocations subindo (executou sob demanda). |
| 8 | (Opcional) New Relic | Trace da execução + NRQL com as métricas (APM/observabilidade da função). |
| 9 | Fecho | "A função só custa quando é chamada; fora isso, custo zero. Código e infraestrutura (SAM) estão versionados no repositório." Mostre rápido o `template.yaml`. |

**Dica de gravação:** deixe as janelas já abertas e logadas antes de começar a
gravar (Console na região us-east-1, PowerShell na pasta certa, `aws logs tail`
pronto). Grave um "ensaio" mudo primeiro para pegar o tempo.

---

## 5. Checklist do que o enunciado exige provar (não pule)

- [ ] Função **serverless** existe e substituiu o container 24/7 → cenas 1, 2.
- [ ] Função **acionada diretamente por fila/tópico** (não por HTTP/servidor) →
      cena 2 (trigger SQS) + cena 4 (disparo real).
- [ ] **Logs** da função → cena 5 (CloudWatch).
- [ ] Código **+ infraestrutura como código** no repositório → cena 9
      (`template.yaml` + `samconfig.toml`, já commitados e no `origin/main`).
- [ ] (Diferencial) Traces/métricas de APM → cena 8 (New Relic).

---

## 6. Solução de problemas (armadilhas já conhecidas)

| Sintoma | Causa / solução |
|---|---|
| Recursos "não aparecem" no Console | Região errada. Confirme **N. Virginia (us-east-1)** no canto superior direito. |
| `aws sns publish` gera erro de JSON ("invalid start of a property name") | Você passou o JSON inline. Use **`--message file://local/arquivo.json`**. |
| A função de pagamento loga `RecipientNotReadyException` | Você não rodou o `user-registered` antes (com o mesmo `UserId`). Rode o cadastro primeiro. |
| Log não aparece no CloudWatch mesmo a função "rodando" | Espere ~10s (SQS tem janela de batching de 5s). Se persistir, veja a DLQ (`-dlq`) — pode ter falhado 5x. |
| `sts get-caller-identity` retorna outra conta / erro | Credenciais expiradas ou perfil errado. Reconfigure com `aws configure` (a chave da conta `450753703903`, usuário `fcg-fiap-aws`). |
| Evento novo criado por você não desserializa | Use **PascalCase** nas chaves (`UserId`, `Email`, `EventId`, `OccurredAt`, `GameId`, `Status`), como nos arquivos em `local/`. camelCase é ignorado silenciosamente. |
| `sam local invoke` falha | Docker Desktop precisa estar aberto; rode `sam build` antes. |
| Aba "Code" da Lambda diz "editor não é compatível com o runtime .NET 10" | **Normal, não é erro.** O editor inline só serve para runtimes interpretados (Node/Python/Ruby); .NET é compilado. Mostre o Runtime/Handler em "Runtime settings" e o código-fonte no editor/GitHub. |

---

## 7. Referências rápidas (copiar/colar)

```
Conta AWS ........ 450753703903    Região ...... us-east-1 (N. Virginia)
Usuário IAM ...... fcg-fiap-aws    Stack ....... fcg-notifications-serverless

Lambdas .......... fcg-notifications-user-registered
                   fcg-notifications-payment-processed
Tópicos SNS ...... arn:aws:sns:us-east-1:450753703903:fcg-user-events
                   arn:aws:sns:us-east-1:450753703903:fcg-payment-events
Filas SQS ........ fcg-notifications-user-registered (+ -dlq)
                   fcg-notifications-payment-processed (+ -dlq)
Tabela DynamoDB .. fcg-notifications
Log groups ....... /aws/lambda/fcg-notifications-user-registered
                   /aws/lambda/fcg-notifications-payment-processed
Secret (NR key) .. fcg/notifications/new-relic-license-key
New Relic ........ conta 8469551 — one.newrelic.com

Arquivos de teste (na raiz do repo NotificationsAPI):
  local/test-user-registered-message.json     → publicar em fcg-user-events
  local/test-payment-processed-message.json   → publicar em fcg-payment-events
  events/user-registered.json                 → para 'sam local invoke'
  events/payment-processed.json               → para 'sam local invoke'
```
