---
name: retomar-fase-3-fiap
description: >-
  Retoma o trabalho de migração serverless do NotificationsAPI (Tech Challenge
  Fase 3 - FIAP Cloud Games) de onde parou, lendo o estado salvo em STATUS.md
  e continuando os passos pendentes do tutorial. Use quando o usuário invocar
  /retomar-fase-3-fiap ou pedir para continuar/retomar a migração da Lambda de
  notificações, o deploy serverless, ou o trabalho da Fase 3 da FIAP.
disable-model-invocation: true
---

# Retomar Fase 3 FIAP — Migração NotificationsAPI para Lambda

## O que fazer ao ser acionada

1. Leia `STATUS.md` (mesma pasta desta skill) — é a fonte da verdade sobre o
   que já foi feito, o que falta e as armadilhas já descobertas.
2. Leia `documentos/tutorial-frete-serveless.md` na raiz do workspace — é o
   roteiro completo dos 22 passos que este trabalho segue.
3. Confirme que o estado real bate com o `STATUS.md` (drift check rápido,
   seção "Como verificar o estado real" abaixo) antes de continuar — não
   assuma que nada mudou desde a última sessão.
4. Continue autonomamente a partir do primeiro item pendente do checklist,
   na ordem do tutorial, avisando o usuário apenas quando precisar de algo
   que só ele pode fornecer (ver "Bloqueios que exigem o usuário").
5. **Atualize `STATUS.md`** a cada passo concluído, incluindo novas
   armadilhas descobertas — esta skill só é útil se o arquivo continuar
   fiel à realidade.

## Contexto do projeto

- **Repositório de trabalho**: `FIAPCloudGames-fase3-NotificationsAPI/` (dentro
  deste workspace) — subpasta `NotificationsAPI/` tem a solução .NET.
- **Objetivo**: migrar o `NotificationsAPI` de container RabbitMQ 24/7 para
  Lambda acionada por SNS+SQS, com New Relic (OpenTelemetry/OTLP) para
  métricas, logs e traces.
- **Conta AWS**: `450753703903`, região `us-east-1`. Usuário IAM de trabalho:
  `fcg-fiap-aws` (AdministratorAccess — trade-off consciente de escopo
  acadêmico, ver seção 5.1 do tutorial). Credenciais já configuradas
  localmente via `aws configure` — não peça de novo, apenas rode
  `aws sts get-caller-identity` para confirmar que ainda funcionam.
- **New Relic**: license key já guardada no Secrets Manager como
  `fcg/notifications/new-relic-license-key`. Nunca peça a key de novo nem a
  exiba em texto puro — se precisar recriá-la, peça só isso ao usuário.

## Como verificar o estado real (drift check)

Rode em paralelo antes de continuar:

```powershell
aws sts get-caller-identity
aws cloudformation describe-stacks --stack-name fcg-notifications-serverless --query "Stacks[0].StackStatus" --region us-east-1
aws secretsmanager describe-secret --secret-id fcg/notifications/new-relic-license-key --region us-east-1 --query "Name"
```

Se a stack não existir ou os comandos falharem, o ambiente AWS foi resetado
(ex.: conta trocada) — trate como se estivesse recomeçando do Passo 13 do
tutorial, não do zero.

Para o código, `dotnet build` e `dotnet test` na pasta
`FIAPCloudGames-fase3-NotificationsAPI/NotificationsAPI` confirmam que o
estado do repositório ainda compila e passa nos testes (`dotnet test`
precisa do Docker Desktop rodando, por causa dos testes de integração com
Testcontainers).

**Também rode, no repositório `FIAPCloudGames-fase3-NotificationsAPI`:**

```powershell
git status
git log origin/main..HEAD --oneline
```

Se aparecer qualquer coisa como "not staged"/"untracked" ou commits à frente
de `origin/main`, **trate como prioridade imediata** — já aconteceu (ver
`STATUS.md`, armadilha 8) de uma sessão inteira de trabalho ter ficado só
local, sem nunca ser enviada ao repositório remoto, o que quebra o requisito
da fase de ter "código + IaC no repositório".

## Bloqueios que exigem o usuário

Não tente contornar sozinho:

- **Conta New Relic / license key nova**: cadastro exige e-mail e escolha de
  conta/região humana.
- **New Relic User API Key + ID numérico da conta New Relic** (necessários
  para o Passo 17, integração nativa AWS↔New Relic para métricas): a key
  só é gerada dentro da UI da New Relic (`one.newrelic.com/api-keys`), ação
  humana. O ID da conta não é secreto, pode ser só informado. Ver
  `STATUS.md`, seção "Investigação do Passo 17". **Já resolvido** (Passo
  17 100% concluído) — mantido aqui como referência caso a integração
  precise ser refeita (ex.: conta New Relic nova).
- **Gravação do vídeo** (Passo 20): ação humana, **único bloqueio real
  restante** no momento.
- Qualquer coisa que exija decidir entre a conta AWS pessoal do Pedro vs.
  outra conta — pergunte, não assuma.

## Armadilhas já descobertas (não repita)

Ver `STATUS.md`, seção "Armadilhas conhecidas" — inclui, por exemplo, o bug
de `aws sns publish --message '{...}'` corrompendo aspas no PowerShell (usar
`--message file://caminho.json`) e o `AddLogging()` sem provider não emitir
nada no CloudWatch.
