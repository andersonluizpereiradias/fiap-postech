# 5. AWS: CloudWatch, Lambda, RDS e aplicação com SonarQube

> **Origem:** Pós-Tech FIAP — Arquitetura de Sistemas .NET, Fase 4, disciplina **AWS**.
>
> **Aulas cobertas:**
> - Aula 7 — Monitoramento com CloudWatch
> - Aula 8 — Desenvolvendo com Lambda Functions
> - Aula 9 — Explorando o RDS
> - Aula 10 — Criando uma aplicação com a AWS (SonarQube)
>
> **Como ler este material:** o texto fora dos blocos "💡 Complemento" reproduz o conteúdo dos PDFs das aulas. O roteiro prático ("Hands On") de cada aula é feito em vídeo e **não está detalhado nos PDFs** — por isso, os passos práticos, comandos e exemplos de código que aparecem aqui estão sempre dentro de blocos de complemento, para não serem confundidos com o material oficial.

---

## Aula 7 - Monitoramento com CloudWatch

### O que vem por aí?

Nesta aula você aprenderá como funciona o monitoramento da AWS com CloudWatch, a criar dashboards e a avaliar os logs de nossas aplicações e banco de dados.

Você também irá criar alertas para que o monitoramento seja ativo e passe a nos avisar em caso de problemas, tudo isso utilizando o serviço CloudWatch.

### Hands On

Nesta aula criaremos dashboards e alguns alertas sobre certas métricas coletadas de nossas aplicações e banco, a fim de garantir que sejamos avisados em caso de problemas ou caso aconteça algum evento que cadastramos.

> **💡 Complemento — roteiro prático típico (dashboards, logs e alarmes):**
>
> Os blocos que compõem o CloudWatch, e que costumam aparecer no hands-on, são:
>
> - **Metrics:** séries temporais organizadas por *namespace* (ex.: `AWS/EC2`, `AWS/RDS`, `AWS/Lambda`, `AWS/ApplicationELB`) e *dimensions* (ex.: `DBInstanceIdentifier`, `FunctionName`). Os serviços AWS publicam métricas básicas automaticamente; métricas de **memória e disco de EC2 não vêm por padrão** — exigem o **CloudWatch Agent** instalado na instância.
> - **Dashboards:** painéis com widgets (linha, número, gauge, tabela de logs) que agregam métricas de vários serviços e até de várias regiões/contas.
> - **Logs:** organizados em *log groups* (ex.: `/aws/lambda/<nome-da-funcao>`, `/aws/rds/instance/<id>/postgresql`) e *log streams*. O **Logs Insights** permite consultar os logs com uma linguagem própria.
> - **Alarms:** avaliam uma métrica contra um limiar ao longo de N períodos e mudam entre os estados `OK`, `ALARM` e `INSUFFICIENT_DATA`. A ação mais comum é publicar num **tópico SNS** com assinatura de e-mail (é preciso confirmar a assinatura no e-mail recebido, senão a notificação não chega).
>
> Fluxo de console para um alarme de CPU do RDS: *CloudWatch → Alarms → Create alarm → Select metric → RDS → Per-Database Metrics → CPUUtilization → condição "Greater than 80" → ação: notificar tópico SNS → nome do alarme → Create*.
>
> O mesmo via AWS CLI:
>
> ```bash
> aws sns create-topic --name alertas-fcg
> aws sns subscribe --topic-arn arn:aws:sns:us-east-1:123456789012:alertas-fcg \
>   --protocol email --notification-endpoint voce@exemplo.com
>
> aws cloudwatch put-metric-alarm \
>   --alarm-name rds-cpu-alta \
>   --namespace AWS/RDS --metric-name CPUUtilization \
>   --dimensions Name=DBInstanceIdentifier,Value=meu-banco \
>   --statistic Average --period 300 --evaluation-periods 2 \
>   --threshold 80 --comparison-operator GreaterThanThreshold \
>   --alarm-actions arn:aws:sns:us-east-1:123456789012:alertas-fcg
> ```
>
> Exemplo de consulta no **Logs Insights** para achar exceções recentes de uma aplicação:
>
> ```text
> fields @timestamp, @message
> | filter @message like /Exception/
> | sort @timestamp desc
> | limit 20
> ```

> **💡 Complemento — custos e armadilhas:**
>
> - Por padrão, log groups são criados com retenção **"Never expire"**. Defina uma retenção (ex.: 7, 14 ou 30 dias) — armazenamento e ingestão de logs costumam ser a maior parte da conta de CloudWatch.
> - Métricas customizadas, alarmes, dashboards (acima da cota gratuita) e consultas do Logs Insights (cobradas por GB varrido) também geram custo. Consulte a página de preços do CloudWatch e o Free Tier da sua conta.
> - Um alarme com poucos dados pode ficar em `INSUFFICIENT_DATA`; avalie a opção *"Treat missing data as"* (ex.: `notBreaching` para métricas esporádicas).
> - Para evitar alarmes "nervosos", use mais de um período de avaliação (ex.: "2 de 3 datapoints") em vez de disparar no primeiro pico.

### Saiba mais

A AWS oferece uma gama completa de serviços de computação em nuvem que auxilia as empresas a construir e gerenciar suas infraestruturas de maneira eficiente e escalável. Entre esses serviços, temos o Amazon CloudWatch, que desempenha um papel crucial ao fornecer uma solução abrangente para monitoramento e observabilidade dos recursos e aplicações na AWS.

#### O que é Amazon CloudWatch?

Amazon CloudWatch é um serviço de monitoramento e observabilidade que oferece dados e insights sobre recursos da AWS, bem como aplicações em execução na nuvem e on-premises. O CloudWatch coleta e rastreia métricas, coleta e monitora arquivos de log, define alarmes e reage automaticamente a mudanças nos recursos da AWS. Ele permite que pessoas desenvolvedoras, engenheiras de DevOps, engenheiras de sistemas e arquitetas monitorem seus sistemas, identificando e resolvendo problemas rapidamente.

Enquanto o Amazon CloudWatch oferece monitoramento e coleta de métricas e logs, o Amazon EventBridge proporciona uma maneira poderosa de reagir a eventos em tempo real, integrando serviços da AWS com aplicações internas e SaaS.

> **💡 Complemento — os três pilares da observabilidade na AWS:** métricas e logs ficam no CloudWatch; **traces distribuídos** ficam no **AWS X-Ray** (hoje integrado ao console do CloudWatch e com suporte a OpenTelemetry via ADOT — AWS Distro for OpenTelemetry). O **CloudWatch Application Signals** monta painéis de SLO, latência e erros por serviço a partir dessa instrumentação. Já o **CloudTrail** registra chamadas de API (auditoria: "quem fez o quê"), não desempenho.

#### O que é Amazon EventBridge?

Amazon EventBridge é um serviço de barramento de eventos que facilita a conexão de aplicações usando dados de suas próprias aplicações, serviços integrados da AWS e serviços SaaS suportados. O EventBridge permite criar arquiteturas orientadas a eventos, em que as aplicações podem reagir em tempo real a eventos gerados por outros serviços ou sistemas.

> **💡 Complemento — histórico:** o EventBridge nasceu como evolução do antigo **CloudWatch Events**; por isso muitos tutoriais antigos falam em "regra do CloudWatch Events" para agendar uma Lambda. Hoje o caminho é o EventBridge (Rules) ou o **EventBridge Scheduler**, um serviço de agendamento dedicado que suporta milhões de agendamentos, agendamentos únicos (`at(...)`) e **fuso horário** configurável — as regras agendadas clássicas do EventBridge avaliam o cron sempre em **UTC**.

#### Funcionalidades principais do EventBridge

- **Barramento de Eventos:** o EventBridge permite criar barramentos de eventos personalizados que agregam eventos de várias fontes e roteiam para destinos especificados.
- **Regras de Eventos:** as regras do EventBridge definem como os eventos são roteados para diferentes destinos, permitindo uma integração flexível e altamente configurável.
- **Integração com Serviços SaaS:** o EventBridge oferece integração nativa com vários serviços SaaS, facilitando a conexão de suas aplicações com serviços externos.
- **Escalabilidade e Confiabilidade:** projetado para escalabilidade e alta disponibilidade, o EventBridge garante que seus eventos sejam entregues de maneira confiável.

> **💡 Complemento — exemplo de regra por padrão de evento:** uma regra compara o JSON do evento com um *event pattern*. Exemplo que captura mudanças de estado de alarmes do CloudWatch para `ALARM`:
>
> ```json
> {
>   "source": ["aws.cloudwatch"],
>   "detail-type": ["CloudWatch Alarm State Change"],
>   "detail": {
>     "state": { "value": ["ALARM"] }
>   }
> }
> ```
>
> O destino (*target*) pode ser uma Lambda, uma fila SQS, um tópico SNS, uma Step Function, etc.

#### Regras CRON no EventBridge

O EventBridge permite criar uma trigger baseada em CRON. Mas o que é uma regra CRON e como podemos entendê-la para que a criação de triggers com EventBridge fique mais simples?

A trigger baseada em CRON no EventBridge é especialmente útil para cenários em que é necessário realizar operações periódicas, como backups de banco de dados, relatórios diários ou atualizações de sistema. Vamos explorar como criar e configurar regras CRON no EventBridge, detalhando cada passo para garantir que você possa configurar tarefas automatizadas com facilidade, mesmo se não tiver experiência prévia com ele.

O CRON é uma ferramenta de agendamento de tarefas que é amplamente utilizada em sistemas Unix e Linux para executar scripts ou comandos em horários específicos ou intervalos regulares. A sintaxe CRON define o horário e a frequência com que uma tarefa deve ser executada. No Amazon EventBridge, você pode usar uma expressão CRON para definir essas tarefas, permitindo que suas funções Lambda ou outros destinos sejam acionados automaticamente conforme o cronograma definido.

Uma expressão CRON é composta por cinco ou seis campos que representam diferentes unidades de tempo. A sintaxe básica é a seguinte:

```text
minuto hora dia-do-mês mês dia-da-semana ano
```

Cada campo pode conter valores numéricos, caracteres especiais e intervalos, permitindo uma grande flexibilidade no agendamento. Vamos detalhar cada campo:

| Campo | Valores |
|---|---|
| Minuto | 0 a 59 |
| Hora | 0 a 23 |
| Dia do Mês | 1 a 31 |
| Mês | 1 a 12 |
| Dia da Semana | 0 (Domingo) a 6 (Sábado) |
| Ano (opcional) | 1970 a 2199 |

> **💡 Complemento — correções importantes sobre o cron do EventBridge:**
>
> - No **EventBridge os seis campos são obrigatórios** (o ano não é opcional ali; use `*`). A forma de 5 campos é a do cron clássico do Linux (que não tem campo de ano).
> - No EventBridge o **dia da semana vai de 1 a 7, com 1 = domingo** (SUN) e 7 = sábado (SAT), ou nomes `SUN`–`SAT`. A faixa 0–6 citada acima é a do cron do Linux. Prefira usar os nomes (`MON`, `FRI`) para não errar.
> - Os campos *dia do mês* e *dia da semana* não podem ser especificados ao mesmo tempo: **um deles precisa ser `?`**.
> - Caracteres especiais: `*` (todos), `?` (qualquer/não importa), `,` (lista, ex.: `MON,WED,FRI`), `-` (intervalo, ex.: `MON-FRI`), `/` (incremento, ex.: `0/15` = a cada 15 minutos), `L` (último, ex.: último dia do mês), `W` (dia útil mais próximo) e `#` (n-ésimo dia da semana do mês, ex.: `MON#2`).
> - A expressão é escrita como `cron(...)`; também existe `rate(...)` para intervalos simples, ex.: `rate(5 minutes)`.
> - As regras agendadas do EventBridge usam **UTC**: "10h em Brasília" (UTC−3) é `cron(0 13 * * ? *)`.

#### Exemplo de expressão CRON

- `0 12 * * ? *` = executa a tarefa todos os dias às 12h (meio-dia).
- `0 6 ? * MON#2 *` = executa a tarefa na segunda-feira da segunda semana do mês, às 6h (isto é, na **segunda segunda-feira** do mês).

Agora, vamos nos aprofundar nas expressões, para que fique mais claro alguns caracteres utilizados anteriormente.

**Executar diariamente às 10h** — expressão: `0 10 * * ? *`

- `0` = no minuto 0.
- `10` = às 10 horas.
- `*` = todos os dias do mês.
- `*` = todos os meses.
- `?` = não se importa com o dia da semana.
- `*` = todos os anos.

**Executar mensalmente no primeiro dia do mês às 17h** — expressão: `0 17 1 * ? *`

- `0` = no minuto 0.
- `17` = às 17 horas.
- `1` = no primeiro dia do mês.
- `*` = todos os meses.
- `?` = não se importa com o dia da semana.
- `*` = todos os anos.

**Executar todas as segundas-feiras às 2h30** — expressão: `30 2 ? * MON *`

- `30` = no minuto 30.
- `2` = às 2 horas.
- `?` = não se importa com o dia do mês.
- `*` = todos os meses.
- `MON` = somente nas segundas-feiras.
- `*` = todos os anos.

Com esse entendimento sobre CRON, a criação de triggers com EventBridge ficará mais fácil. Isso pode ser aplicado fora da AWS, já que o CRON é bastante utilizado para agendamento de scripts no Linux, por exemplo.

> **💡 Complemento — mais exemplos úteis e criação via CLI:**
>
> | Objetivo | Expressão EventBridge |
> |---|---|
> | A cada 15 minutos | `cron(0/15 * * * ? *)` ou `rate(15 minutes)` |
> | Dias úteis às 8h UTC | `cron(0 8 ? * MON-FRI *)` |
> | Último dia do mês às 23h UTC | `cron(0 23 L * ? *)` |
>
> ```bash
> aws events put-rule --name relatorio-diario \
>   --schedule-expression "cron(0 10 * * ? *)"
>
> aws events put-targets --rule relatorio-diario \
>   --targets "Id"="1","Arn"="arn:aws:lambda:us-east-1:123456789012:function:GerarRelatorio"
>
> # A Lambda precisa permitir ser invocada pelo EventBridge
> aws lambda add-permission --function-name GerarRelatorio \
>   --statement-id eventbridge-relatorio --action lambda:InvokeFunction \
>   --principal events.amazonaws.com \
>   --source-arn arn:aws:events:us-east-1:123456789012:rule/relatorio-diario
> ```
>
> Esquecer o `add-permission` é a causa mais comum de "a regra existe, mas a Lambda nunca roda" quando a configuração é feita fora do console (o console adiciona a permissão automaticamente).

### Casos de uso do Amazon EventBridge

#### Integração de aplicações internas

Uma empresa deseja integrar várias aplicações internas para melhorar a eficiência do fluxo de trabalho. O EventBridge é utilizado para coordenar eventos entre essas aplicações.

- **Criação de Barramento de Eventos:** um barramento de eventos personalizado é criado para agregar eventos de todas as aplicações internas.
- **Definição de Regras:** regras são configuradas para rotear eventos específicos, como pedidos de compra ou atualizações de inventário, para as aplicações apropriadas.
- **Automação de Processos:** funções Lambda são acionadas por eventos do EventBridge para automatizar processos, como a atualização de registros em um banco de dados ou o envio de notificações.

#### Monitoramento e resposta a eventos de segurança

Uma empresa de segurança cibernética utiliza o EventBridge para monitorar eventos de segurança e responder automaticamente a ameaças.

- **Integração com CloudTrail:** eventos de segurança são enviados para o EventBridge através do CloudTrail.
- **Regras de Eventos de Segurança:** regras são configuradas para identificar eventos suspeitos, como tentativas de login fracassadas ou alterações de permissões.
- **Resposta Automática:** funções Lambda são acionadas para executar ações de resposta, como bloquear endereços IP suspeitos ou notificar a equipe de segurança.

> **💡 Complemento — EventBridge x SNS x SQS:** SNS é *pub/sub* com fan-out simples (sem filtragem rica de conteúdo além de *filter policies*); SQS é fila com retenção e consumo por *pull*; EventBridge é um roteador de eventos com regras por conteúdo, integração SaaS, *archive/replay* e *schema registry*. É comum combiná-los (ex.: EventBridge → SQS → Lambda).

### O que você viu nesta aula?

Você viu como funciona o monitoramento da infraestrutura com o serviço da AWS chamado CloudWatch. Também fizemos a criação e a análise de métricas a partir de um dashboard criado e criamos alertas para que o serviço nos avise em caso de problemas.

### Referências da aula

- AWS. *O que é a Amazon EventBridge?* — https://docs.aws.amazon.com/pt_br/eventbridge/latest/userguide/eb-what-is.html
- AWS. *O que é o Amazon CloudWatch?* — https://docs.aws.amazon.com/pt_br/AmazonCloudWatch/latest/monitoring/WhatIsCloudWatch.html
- AWS. *Usar alarmes do Amazon CloudWatch* — https://docs.aws.amazon.com/pt_br/AmazonCloudWatch/latest/monitoring/AlarmThatSendsEmail.html
- PIRES, J. *Cron Job: Guia completo para automatizar tarefas* (2023) — https://www.hostgator.com.br/blog/cron-job-guia-completo-para-automatizar-tarefas/

Palavras-chave: Infraestrutura, CloudWatch, EventBridge, Logs, Alarmes, CRON.

### Pontos-chave

- CloudWatch é o serviço de monitoramento e observabilidade da AWS: coleta **métricas**, **logs**, permite **dashboards** e **alarmes** que reagem a mudanças (geralmente notificando via SNS).
- Alarmes tornam o monitoramento **ativo**: em vez de olhar painéis, você é avisado quando um limiar é ultrapassado.
- EventBridge é um **barramento de eventos** com regras que roteiam eventos (AWS, aplicações próprias e SaaS) para destinos como Lambda.
- EventBridge suporta **gatilhos agendados por CRON**, úteis para backups, relatórios e tarefas periódicas.
- No EventBridge o cron tem **6 campos** (`minuto hora dia-do-mês mês dia-da-semana ano`), roda em **UTC** e exige `?` em dia do mês **ou** dia da semana.
- Casos de uso típicos: integração de aplicações internas e resposta automática a eventos de segurança (CloudTrail → EventBridge → Lambda).
- Configure **retenção de logs** desde o início para controlar custos.

---

## Aula 8 - Desenvolvendo com Lambda Functions

### O que vem por aí?

Nesta aula você aprenderá sobre Serverless. Utilizando o serviço da AWS Lambda Functions, vamos entender como ele funciona e como pode nos ajudar em tarefas repetitivas. Além disso, vamos aprender sobre Layers e criaremos nossa primeira Layer. Por fim, vamos criar nossa primeira função com o serviço em questão.

### Hands On

Nesta aula criaremos nossa função no Lambda e testaremos sua funcionalidade, além de criar nosso próprio layer para utilizar com Lambda, seguindo as boas práticas e configurando o agendamento para que nossa função rode corretamente.

> **💡 Complemento — criando uma função Lambda em C# (.NET):**
>
> Ferramentas oficiais da AWS para .NET:
>
> ```bash
> dotnet new install Amazon.Lambda.Templates
> dotnet tool install -g Amazon.Lambda.Tools
>
> dotnet new lambda.EmptyFunction --name MinhaFuncao
> cd MinhaFuncao/src/MinhaFuncao
> dotnet lambda deploy-function MinhaFuncao
> ```
>
> Um handler mínimo (modelo de biblioteca de classes):
>
> ```csharp
> using Amazon.Lambda.Core;
>
> [assembly: LambdaSerializer(typeof(Amazon.Lambda.Serialization.SystemTextJson.DefaultLambdaJsonSerializer))]
>
> namespace MinhaFuncao;
>
> public class Function
> {
>     public string FunctionHandler(string input, ILambdaContext context)
>     {
>         context.Logger.LogInformation($"Recebido: {input}");
>         return input.ToUpper();
>     }
> }
> ```
>
> O handler é informado no formato `Assembly::Namespace.Classe::Metodo` (ex.: `MinhaFuncao::MinhaFuncao.Function::FunctionHandler`). Também existe o modelo de **executable assembly** (top-level statements com `LambdaBootstrapBuilder`), necessário para Native AOT.
>
> No console: *Lambda → Create function → Author from scratch → Runtime .NET → Create*; depois, na aba **Test**, crie um evento de teste (JSON) e execute. Os logs vão automaticamente para o log group `/aws/lambda/<nome>` no CloudWatch (desde que a role de execução tenha a política `AWSLambdaBasicExecutionRole`).
>
> Para o **agendamento** citado no hands-on, adicione um trigger *EventBridge (CloudWatch Events)* com expressão `cron(...)` ou `rate(...)` — veja a Aula 7.

> **💡 Complemento — atualização sobre runtimes .NET no Lambda:** os runtimes gerenciados acompanham apenas as versões **LTS** do .NET. O `dotnet6` foi descontinuado (fim de suporte em dezembro de 2024); o `dotnet8` é o runtime gerenciado LTS amplamente usado (sobre Amazon Linux 2023), e a AWS publicou o runtime para o **.NET 10** (LTS) após o lançamento dessa versão — confirme na página "Lambda runtimes" da documentação qual está disponível e as datas de *deprecation*. Versões não-LTS (ex.: .NET 9) só rodam via **imagem de container** ou **runtime customizado** (`provided.al2023`), que também é o caminho para **Native AOT**.

> **💡 Complemento — limites e custos que caem em prova e em produção:**
>
> - Timeout máximo: **15 minutos** por invocação. Memória: 128 MB a 10.240 MB (a CPU é proporcional à memória).
> - Pacote .zip: 50 MB compactado (upload direto) / **250 MB descompactado** incluindo layers; imagem de container: até 10 GB.
> - Cobrança por número de requisições + duração (GB-segundo). O Free Tier "always free" do Lambda inclui 1 milhão de requisições e 400.000 GB-s por mês.
> - **Cold start** em .NET pode ser perceptível; mitigações: **SnapStart** (suportado para .NET 8 e posteriores), Native AOT, aumentar memória, ou *provisioned concurrency* (pago).
> - Concorrência padrão por conta/região é limitada (cota ajustável). Use *reserved concurrency* para impedir que uma função consuma toda a cota — ou para limitar o impacto sobre um banco de dados.

### Saiba mais

#### O que é AWS Lambda?

O AWS Lambda é um serviço de computação serverless oferecido pela Amazon Web Services (AWS). Ele permite executar código sem a necessidade de provisionar ou gerenciar servidores. O AWS Lambda executa seu código apenas quando necessário e escala automaticamente, desde algumas requisições por dia até milhares por segundo.

#### Como o AWS Lambda funciona?

Com o AWS Lambda, você carrega seu código (normalmente em uma das linguagens de programação suportadas, como Python, Node.js, Java, C#, Go, entre outras) e define um "trigger" (gatilho) para determinar quando o código deve ser executado. Esses gatilhos podem incluir eventos como alterações em um bucket do Amazon S3, atualizações em um banco de dados DynamoDB ou requisições HTTP através do Amazon API Gateway.

Quando o evento especificado ocorre o Lambda executa seu código, utilizando a quantidade de recursos computacionais necessária para completar a tarefa. Isso elimina a necessidade de gerenciar a infraestrutura subjacente e permite que desenvolvedores(as) se concentrem na lógica de negócios de suas aplicações.

> **💡 Complemento — atualização sobre Go:** o runtime gerenciado `go1.x` foi descontinuado; hoje funções em Go (e Rust) rodam no runtime **OS-only** `provided.al2023`, compilando um binário `bootstrap`.

> **💡 Complemento — modelos de invocação:**
>
> - **Síncrona:** quem chama espera a resposta (API Gateway, Function URL, `Invoke` com `RequestResponse`).
> - **Assíncrona:** o serviço enfileira o evento e o Lambda faz até 2 novas tentativas em caso de erro (S3, SNS, EventBridge). Configure *on-failure destination* ou DLQ.
> - **Event source mapping (poll):** o próprio Lambda lê de SQS, Kinesis, DynamoDB Streams, Kafka. Erros fazem a mensagem voltar à fila — use *partial batch response* (`ReportBatchItemFailures`) para não reprocessar o lote inteiro.
>
> Armadilha comum: a função precisa ser **idempotente**, pois *at-least-once* significa que o mesmo evento pode chegar mais de uma vez.

> **💡 Complemento — Layers (camadas):** uma *layer* é um .zip com bibliotecas, dependências ou binários que é extraído em `/opt` no ambiente de execução e pode ser compartilhado entre várias funções (até **5 layers por função**, contando no limite de 250 MB descompactados). Layers são versionadas e imutáveis: cada publicação gera um novo ARN `...:layer:nome:versao`.
>
> ```bash
> aws lambda publish-layer-version --layer-name minhas-libs \
>   --zip-file fileb://layer.zip \
>   --compatible-runtimes dotnet8
>
> aws lambda update-function-configuration --function-name MinhaFuncao \
>   --layers arn:aws:lambda:us-east-1:123456789012:layer:minhas-libs:1
> ```
>
> Em .NET, o `Amazon.Lambda.Tools` oferece `dotnet lambda publish-layer` (cria um *runtime package store* com os pacotes NuGet do projeto) e `dotnet lambda deploy-function --function-layers <arn>`. Na prática, em .NET as layers são menos usadas que em Python/Node, porque as dependências já vão no pacote publicado; elas fazem mais sentido para binários compartilhados, extensões (ex.: agentes de observabilidade) ou para reduzir o tamanho de deploy de várias funções que usam as mesmas libs. Boa prática: não coloque segredos em layers e mantenha versões compatíveis com o runtime.

Já conhecemos o AWS Lambda, mas e se precisarmos criar várias lambdas para que a execução ordenada seja feita, seguindo a fila de execuções? Para isso, podemos utilizar o AWS Step Functions.

#### O que são AWS Step Functions?

O AWS Step Functions é um serviço que facilita a coordenação de componentes de aplicações distribuídas e microsserviços utilizando fluxos de trabalho visuais. Ele permite definir uma série de tarefas, como funções Lambda, em um fluxo de trabalho e gerenciar a execução dessas tarefas de maneira confiável e escalável.

#### Como funcionam as Step Functions?

Com as AWS Step Functions você cria "máquinas de estado", que são definições visuais de seu fluxo de trabalho. Cada estado na máquina pode ser uma tarefa, uma escolha (if/else), um atraso ou um passo paralelo, entre outros. As Step Functions gerenciam a transição entre esses estados e garantem que cada tarefa seja executada na ordem correta e conforme o esperado.

*Figura 1 – AWS Step Functions (fonte: Villalba, 2021): ilustração do Workflow Studio, editor visual low-code em que se arrastam estados (tarefas, escolhas, paralelos) para montar a máquina de estados.*

Por exemplo: em um fluxo de trabalho de processamento de pedidos, você pode ter estados para validar os detalhes do pedido, processar o pagamento, atualizar o inventário e enviar uma confirmação ao cliente. Cada um desses estados pode invocar uma função Lambda, chamar um serviço da AWS ou executar uma tarefa personalizada.

> **💡 Complemento — como fica a definição (Amazon States Language):** o editor visual gera um JSON em ASL. Um esboço do fluxo de pedidos acima:
>
> ```json
> {
>   "Comment": "Processamento de pedido",
>   "StartAt": "ValidarPedido",
>   "States": {
>     "ValidarPedido": {
>       "Type": "Task",
>       "Resource": "arn:aws:states:::lambda:invoke",
>       "Parameters": { "FunctionName": "ValidarPedido", "Payload.$": "$" },
>       "Next": "PedidoValido?"
>     },
>     "PedidoValido?": {
>       "Type": "Choice",
>       "Choices": [
>         { "Variable": "$.Payload.valido", "BooleanEquals": true, "Next": "ProcessarPagamento" }
>       ],
>       "Default": "PedidoRejeitado"
>     },
>     "ProcessarPagamento": {
>       "Type": "Task",
>       "Resource": "arn:aws:states:::lambda:invoke",
>       "Parameters": { "FunctionName": "ProcessarPagamento", "Payload.$": "$.Payload" },
>       "Retry": [ { "ErrorEquals": ["States.TaskFailed"], "MaxAttempts": 2, "BackoffRate": 2 } ],
>       "End": true
>     },
>     "PedidoRejeitado": { "Type": "Fail", "Cause": "Pedido inválido" }
>   }
> }
> ```
>
> Tipos de estado: `Task`, `Choice`, `Wait`, `Parallel`, `Map`, `Pass`, `Succeed`, `Fail`. Existem dois tipos de workflow: **Standard** (até 1 ano de duração, execução *exactly-once*, cobrado por transição de estado) e **Express** (até 5 minutos, alto volume, *at-least-once*, cobrado por execução/duração). Atualização: as versões recentes também aceitam **JSONata** como linguagem de consulta, além do JSONPath mostrado acima.

#### Benefícios das Step Functions

- **Coordenação simplificada:** gerencia fluxos de trabalho complexos com facilidade.
- **Visualização do fluxo:** permite criar e visualizar fluxos de trabalho com uma interface gráfica.
- **Escalabilidade e confiabilidade:** escala automaticamente e garante a execução de cada tarefa.
- **Monitoramento e logging:** fornece monitoramento detalhado e logging de cada etapa do fluxo de trabalho.

Um dos casos de uso mais comuns para Step Functions é a coordenação de funções Lambda. Em vez de tentar gerenciar fluxos de trabalho complexos dentro do código de uma única função Lambda, você pode dividir a lógica em várias funções menores e orquestrá-las usando Step Functions.

> **💡 Complemento — orquestração x coreografia:** Step Functions é **orquestração** (um coordenador central conhece o fluxo, ideal para sagas com compensação e retries declarativos). EventBridge/SNS é **coreografia** (cada serviço reage a eventos sem um coordenador). Uma Lambda chamando outra Lambda diretamente e esperando a resposta é um antipadrão: você paga pelas duas executando ao mesmo tempo e perde visibilidade.

#### Processamento de vídeos com Step Functions

O processamento de vídeos é um dos casos de uso mais impactantes e práticos para as AWS Step Functions, especialmente quando se trata de tarefas que podem ser massivamente paralelizadas, como a divisão e a transcodificação de vídeos.

O processamento de vídeos envolve várias etapas complexas que vão desde ingestão do vídeo original, divisão em segmentos menores e transcodificação para diferentes resoluções e formatos até combinação e armazenamento dos resultados finais. Cada uma dessas etapas pode ser demorada e intensiva em recursos. Quando tratamos de grandes volumes de vídeos, a necessidade de escalabilidade e eficiência se torna crucial.

#### Solução com AWS Step Functions

As AWS Step Functions fornecem uma maneira eficiente de orquestrar essas etapas de forma escalável e confiável. Utilizando a capacidade de definir máquinas de estado, as Step Functions podem gerenciar o fluxo de trabalho completo de processamento de vídeo, garantindo que cada etapa seja executada na ordem correta e de maneira eficiente.

*Figura 2 – Solução de vídeos em massa com AWS Step Functions (fonte: AWS, 2024): diagrama do fluxo de ingestão → divisão em segmentos → transcodificação paralela → combinação → armazenamento em S3 e notificação.*

- **Recepção e Validação do Vídeo:** as Step Functions podem iniciar o fluxo de trabalho ao receber um vídeo carregado por um usuário, verificando automaticamente se ele está no formato correto e se atende aos critérios de qualidade necessários.
- **Divisão em Segmentos:** uma das etapas iniciais mais importantes é dividir o vídeo em segmentos menores. Isso facilita a paralelização das tarefas subsequentes. As Step Functions podem coordenar essa divisão, assegurando que cada segmento seja processado independentemente e de forma paralela.
- **Transcodificação Paralela:** a transcodificação é a verdadeira vantagem das Step Functions. Cada segmento do vídeo pode ser transcodificado para diferentes resoluções e formatos simultaneamente. Utilizando a funcionalidade de "Map State", elas permitem que cada segmento seja processado em paralelo, otimizando o tempo de processamento total.
- **Combinação de Segmentos:** após a transcodificação, os segmentos devem ser combinados para formar os vídeos finais em cada resolução e formato. As Step Functions gerenciam a sincronização e a combinação desses segmentos, garantindo que o resultado final seja coerente e de alta qualidade.
- **Armazenamento e Notificação:** finalmente, as Step Functions coordenam o armazenamento dos vídeos transcodificados em um bucket do Amazon S3 e podem acionar notificações para informar ao usuário ou ao sistema que o processamento foi concluído.

Este exemplo para divisão e transcodificação de vídeos destaca a flexibilidade e o poder dessa ferramenta para gerenciar fluxos de trabalho complexos e intensivos em recursos.

> **💡 Complemento — Map State:** o `Map` "inline" processa itens de um array do próprio input (concorrência limitada); o **Distributed Map** lê itens diretamente de objetos no S3 e pode disparar milhares de execuções filhas em paralelo — é o modo indicado para processamento em massa como o do exemplo. Cada segmento ainda está sujeito ao limite de 15 minutos se for processado por uma Lambda; transcodificações longas costumam usar AWS Elemental MediaConvert, ECS/Fargate ou AWS Batch como `Task`.

### O que você viu nesta aula?

Você aprendeu sobre o Serverless e como ele pode nos ajudar com pouca configuração em tarefas repetidas. Também criamos nosso Layer para utilizar com Lambda e entendemos mais sobre o AWS Step Functions, que utiliza Workflows para executar tarefas subsequentes de maneira facilitada.

### Referências da aula

- AWS. *Casos de Uso do AWS Step Functions* — https://aws.amazon.com/pt/step-functions/use-cases/
- AWS. *Gerenciar dependências do Lambda com camadas* — https://docs.aws.amazon.com/pt_br/lambda/latest/dg/chapter-layers.html
- AWS. *O que é o AWS Lambda?* — https://docs.aws.amazon.com/pt_br/lambda/latest/dg/welcome.html
- VILLALBA, M. *New – AWS Step Functions Workflow Studio – A Low-Code Visual Tool for Building State Machines* (2021) — https://aws.amazon.com/pt/blogs/aws/new-aws-step-functions-workflow-studio-a-low-code-visual-tool-for-building-state-machines/

Palavras-chave: Serverless, Lambda, Step Functions, Layers.

### Pontos-chave

- Lambda é computação **serverless**: sem servidores para gerenciar, execução sob demanda e escala automática; cobrança por requisição e duração.
- Uma função é disparada por **triggers**: S3, DynamoDB, API Gateway, EventBridge (agendamento cron), SQS, SNS, entre outros.
- **Layers** empacotam dependências compartilhadas entre funções (montadas em `/opt`, até 5 por função, versionadas).
- Lambda tem limites rígidos (15 min, 10 GB de memória, 250 MB descompactado) que definem quando ela **não** é a ferramenta certa.
- **Step Functions** orquestra várias Lambdas/serviços com **máquinas de estado** (Task, Choice, Wait, Parallel, Map...), retries e visualização do fluxo.
- Prefira várias funções pequenas orquestradas a uma única Lambda "faz-tudo".
- O **Map State** permite paralelizar trabalho em massa, como a transcodificação de segmentos de vídeo.
- Em .NET, use o runtime gerenciado LTS vigente e avalie SnapStart/Native AOT para reduzir cold start.

---

## Aula 9 - Explorando o RDS

### O que vem por aí?

Nesta aula você aprenderá sobre o serviço de banco de dados relacional da AWS, o RDS. Vamos aprofundar nosso conhecimento sobre ele, entendendo quais são as engines disponíveis, instance type, parameter groups, option groups e subnet groups, além de aprender sobre as boas práticas que podemos aplicar ao serviço para que ele possa se manter seguro na AWS e acessível somente a nossas aplicações.

Além disso, vamos criar nosso primeiro banco e ver as opções para que seja possível acessar ele localmente. Por fim, entenderemos as diferenças entre o RDS e o DynamoDB, ambos serviços da AWS voltados para banco relacional e não relacional, respectivamente.

### Hands On

Nesta aula vamos criar um banco relacional com RDS para que possamos utilizar em aulas futuras, a fim de que nossa aplicação possa se conectar de forma segura, seguindo as boas práticas.

> **💡 Complemento — os conceitos citados no roteiro da aula:**
>
> | Conceito | O que é |
> |---|---|
> | **Engine** | O SGBD: Aurora (MySQL/PostgreSQL compatível), PostgreSQL, MySQL, MariaDB, Oracle, SQL Server (e Db2, adicionado depois). |
> | **Instance class** | Tamanho da máquina: família `db.t` (burstable, ex.: `db.t4g.micro`, para dev/teste), `db.m` (uso geral), `db.r`/`db.x` (memória otimizada). Sufixo `g` = Graviton (ARM), geralmente mais barato. |
> | **Storage** | `gp3` (padrão recomendado, IOPS/throughput configuráveis), `io1`/`io2` (IOPS provisionado). *Storage autoscaling* aumenta o disco automaticamente. |
> | **Parameter group** | Conjunto de parâmetros de configuração do engine (ex.: `max_connections`, `log_min_duration_statement`, `rds.force_ssl`). O grupo *default* não pode ser editado — crie um customizado. Parâmetros *static* exigem reboot; *dynamic* aplicam na hora. |
> | **Option group** | Recursos opcionais do engine (ex.: TDE no Oracle/SQL Server, backup/restore nativo do SQL Server para S3). PostgreSQL usa *extensions* em vez de option groups. |
> | **DB subnet group** | Conjunto de subnets (de pelo menos **duas AZs**) da VPC onde o RDS pode ser colocado. Para segurança, use **subnets privadas**. |
> | **Security group** | Firewall da instância: libere a porta do engine (5432 PostgreSQL, 3306 MySQL, 1433 SQL Server) **apenas** para o security group da aplicação, não para `0.0.0.0/0`. |
>
> Criação via CLI (PostgreSQL de desenvolvimento, sem acesso público, senha gerenciada pelo Secrets Manager):
>
> ```bash
> aws rds create-db-subnet-group --db-subnet-group-name fcg-db-subnets \
>   --db-subnet-group-description "Subnets privadas do banco" \
>   --subnet-ids subnet-aaaa subnet-bbbb
>
> aws rds create-db-instance \
>   --db-instance-identifier fcg-postgres \
>   --engine postgres \
>   --db-instance-class db.t4g.micro \
>   --allocated-storage 20 --storage-type gp3 \
>   --master-username fcgadmin \
>   --manage-master-user-password \
>   --db-subnet-group-name fcg-db-subnets \
>   --vpc-security-group-ids sg-0123456789abcdef0 \
>   --no-publicly-accessible \
>   --backup-retention-period 7 \
>   --storage-encrypted
> ```

> **💡 Complemento — atualização: senha gerenciada pelo Secrets Manager.** Desde o fim de 2022 o RDS pode **gerenciar a senha master no AWS Secrets Manager** (opção *"Manage master credentials in AWS Secrets Manager"* no console, ou `--manage-master-user-password` na CLI), com rotação automática. A aplicação lê o segredo (ex.: via AWS SDK, External Secrets Operator no Kubernetes ou o *Secrets Store CSI Driver*) em vez de ter a senha em `appsettings.json`. Outra alternativa sem senha é a **IAM database authentication** (token temporário gerado pela role da aplicação).

> **💡 Complemento — acessando o banco localmente sem expô-lo à internet:** marcar o banco como *Publicly accessible* e abrir o security group para o seu IP funciona para laboratório, mas não é boa prática. Alternativas seguras:
>
> - **Bastion host / SSM Session Manager** com *port forwarding* (sem abrir porta SSH):
>
>   ```bash
>   aws ssm start-session --target i-0123456789abcdef0 \
>     --document-name AWS-StartPortForwardingSessionToRemoteHost \
>     --parameters '{"host":["fcg-postgres.xxxxxx.us-east-1.rds.amazonaws.com"],"portNumber":["5432"],"localPortNumber":["5432"]}'
>   ```
>
>   Depois, conecte o DBeaver/pgAdmin/`psql` em `localhost:5432`.
> - **VPN** (Client VPN) até a VPC.
>
> Custos e armadilhas: desde fevereiro de 2024 a AWS cobra por **endereço IPv4 público** (inclusive de RDS público); instâncias Multi-AZ custam aproximadamente o dobro; snapshots manuais ficam cobrando até serem apagados; e uma instância **parada** volta a ligar sozinha após **7 dias**. Atualização: o Free Tier da AWS mudou em julho de 2025 (contas novas passaram a receber créditos em vez do modelo antigo de 750 h/mês por 12 meses) — confira as regras válidas para a sua conta antes de criar recursos.

### Saiba mais

O Amazon Relational Database Service (RDS) é um serviço gerenciado de banco de dados relacional oferecido pela Amazon Web Services (AWS). Ele facilita a configuração, a operação e a escalabilidade de bancos de dados relacionais na nuvem. Com o Amazon RDS, você pode escolher entre vários mecanismos de banco de dados populares, incluindo Amazon Aurora, PostgreSQL, MySQL, MariaDB, Oracle e Microsoft SQL Server.

O RDS simplifica muitas das tarefas tediosas e demoradas associadas ao gerenciamento de bancos de dados, como provisionamento de hardware, configuração de bancos de dados, aplicação de patches e backups. Ele oferece uma solução escalável, de alta disponibilidade e segura para armazenar e gerenciar dados relacionais.

Entre os recursos notáveis do Amazon RDS estão a replicação multi-AZ para alta disponibilidade, backups automáticos, snapshots de banco de dados e escalabilidade de leitura com réplicas de leitura. Além disso, o RDS integra-se facilmente com outros serviços AWS, permitindo a criação de soluções de dados abrangentes.

> **💡 Complemento — Multi-AZ x Read Replica (confusão clássica):**
>
> - **Multi-AZ (instância):** réplica **síncrona** em outra AZ, usada só para **failover** automático (o standby não aceita leituras). O endpoint DNS continua o mesmo após o failover (leva tipicamente de 1 a 2 minutos).
> - **Multi-AZ DB cluster:** variante com **dois standbys legíveis** em AZs diferentes (MySQL e PostgreSQL), com failover mais rápido.
> - **Read Replica:** réplica **assíncrona** (pode ter *lag*), usada para **escalar leitura**; possui endpoint próprio, pode estar em outra região e pode ser promovida manualmente.
> - **Backups automáticos** permitem *point-in-time restore* dentro do período de retenção (até 35 dias); o restore cria **uma nova instância** (novo endpoint).
> - Outros recursos úteis: **RDS Proxy** (pool de conexões — muito útil com Lambda), **Performance Insights / Database Insights** (análise de carga e queries) e **Blue/Green Deployments** (upgrades com troca rápida).

Enquanto o Amazon RDS atende perfeitamente às necessidades de aplicações que dependem de dados relacionais estruturados e transacionais, a AWS também oferece soluções para diferentes tipos de cargas de trabalho de dados. Uma dessas soluções é o Amazon DynamoDB, um serviço de banco de dados NoSQL gerenciado que oferece armazenamento de dados de alta performance e baixa latência.

Desenvolvido pela Amazon Web Services, ele foi projetado para aplicações que exigem escalabilidade, flexibilidade e alta disponibilidade. É particularmente útil para cargas de trabalho que exigem acesso rápido a grandes volumes de dados, como jogos, aplicativos móveis, comércio eletrônico e serviços de streaming.

O DynamoDB suporta tanto modelos de dados de chave-valor quanto modelos de documentos, tornando-o versátil para diversas necessidades de armazenamento de dados. Com recursos como replicação multi-região, backups automáticos e integração com outros serviços AWS, o DynamoDB é uma escolha robusta para empresas que precisam de uma solução de banco de dados escalável e confiável.

### Características e benefícios do DynamoDB

#### Escalabilidade e performance

Uma das principais características do DynamoDB é sua capacidade de escalar automaticamente para atender a demanda de leitura e escrita. Você pode provisionar a capacidade de leitura e escrita necessária para sua aplicação e o DynamoDB se ajustará automaticamente para manter o desempenho. Ele também oferece a opção de auto scaling, em que a capacidade é ajustada dinamicamente com base em políticas de escalabilidade definidas pelo usuário.

A baixa latência é outra vantagem significativa do DynamoDB. Ele é otimizado para oferecer tempos de resposta de milissegundos, independentemente do volume de dados armazenados. Isso o torna ideal para aplicações que exigem respostas rápidas, como sistemas de recomendação em tempo real e plataformas de jogos.

> **💡 Complemento — modos de capacidade:** **Provisioned** (você define RCU/WCU, opcionalmente com auto scaling; mais barato para tráfego previsível) e **On-demand** (paga por requisição, sem planejamento; ideal para tráfego imprevisível ou baixo — a AWS reduziu o preço do on-demand em novembro de 2024, tornando-o o padrão recomendado para a maioria das cargas novas). Para latência de microssegundos existe o cache **DAX**.

#### Modelo de dados flexível

O DynamoDB oferece um modelo de dados flexível que pode suportar diferentes tipos de aplicações. Com suporte para modelos de dados de chave-valor e documentos, ele permite que você armazene e recupere dados de forma eficiente, sem a necessidade de um esquema fixo. Isso significa que você pode adicionar novos atributos a qualquer momento, sem interromper a aplicação ou realizar migrações complexas.

Os itens no DynamoDB são organizados em tabelas e cada um deles é identificado por uma chave primária. Você pode escolher entre uma chave primária simples (uma única chave de partição) ou uma chave composta (chave de partição e chave de classificação). Isso oferece flexibilidade na maneira como os dados são acessados e organizados.

> **💡 Complemento — armadilha de modelagem:** "sem esquema" não significa "sem modelagem". No DynamoDB você modela a partir dos **padrões de acesso** (quais consultas a aplicação fará), porque só é eficiente consultar pela chave (`Query`/`GetItem`); um `Scan` lê a tabela inteira e é caro. Chaves de partição com baixa cardinalidade criam *hot partitions*. Itens têm limite de **400 KB**.

#### Alta disponibilidade e durabilidade

O DynamoDB é projetado para ser altamente disponível e durável. Ele replica automaticamente os dados em três zonas de disponibilidade dentro de uma região AWS, garantindo que seus dados permaneçam disponíveis mesmo em caso de falha de uma zona de disponibilidade. Além disso, o DynamoDB oferece suporte para replicação global, permitindo que você replique seus dados em várias regiões AWS para aumentar a resiliência e a disponibilidade global.

#### Gerenciamento simplificado

Como um serviço gerenciado, o DynamoDB elimina a necessidade de tarefas administrativas complexas, como configuração de hardware, instalação de software, aplicação de patches e backups. A AWS cuida de todo o gerenciamento da infraestrutura, permitindo que você se concentre no desenvolvimento de suas aplicações. Além disso, o DynamoDB integra-se com outros serviços AWS, como AWS Lambda, Amazon S3 e Amazon Redshift, facilitando a criação de soluções completas e integradas.

#### Segurança

A segurança é uma prioridade no DynamoDB. Ele oferece várias camadas de segurança para proteger seus dados, incluindo criptografia em trânsito e em repouso, controle de acesso granular com AWS Identity and Access Management (IAM) e logging detalhado de atividades com AWS CloudTrail. Essas características ajudam a garantir que seus dados estejam seguros e em conformidade com as regulamentações de segurança e privacidade.

### Caso de uso: Amazon RDS (banco de dados relacional)

#### Sistema de gestão de pedidos para restaurante fast food

Uma rede de restaurantes fast food deseja implementar um sistema de gestão de pedidos que possa ser utilizado em todas as suas unidades. O sistema deve gerenciar informações sobre pedidos, clientes, cardápio, inventário de ingredientes e funcionários. A consistência dos dados e a capacidade de realizar consultas complexas são essenciais para garantir a eficiência operacional e a precisão no atendimento aos clientes.

A empresa decide usar o Amazon RDS com MySQL como mecanismo de banco de dados relacional devido a sua confiabilidade, suporte a SQL e capacidade de transações ACID.

**Arquitetura**

1. **Instância RDS**
   - Uma instância RDS MySQL é provisionada com alta disponibilidade, utilizando a configuração Multi-AZ para garantir que o banco de dados permaneça acessível mesmo em caso de falha em uma zona de disponibilidade.
2. **Tabelas e Esquema**
   - Tabela de Clientes: armazena informações dos clientes, como ID do cliente, nome, endereço e detalhes de contato.
   - Tabela de Pedidos: contém registros de pedidos, incluindo ID do pedido, ID do cliente, data do pedido, status do pedido e valor total.
   - Tabela de Itens de Pedido: detalha os itens de cada pedido, incluindo ID do item, ID do pedido, ID do produto, quantidade e preço.
   - Tabela de Produtos: lista os produtos do cardápio, incluindo ID do produto, nome, descrição e preço.
   - Tabela de Ingredientes: armazena os ingredientes disponíveis, incluindo ID do ingrediente, nome, quantidade em estoque e unidade de medida.
   - Tabela de Funcionários: contém informações dos funcionários, incluindo ID do funcionário, nome, função e informações de contato.
3. **Transações e Integridade Referencial**
   - As transações garantem que todas as operações de pedido sejam atômicas. Por exemplo: ao registrar um pedido, a operação insere registros tanto na tabela de pedidos quanto na tabela de itens de pedido de maneira atômica.
   - Chaves estrangeiras são usadas para manter a integridade referencial entre as tabelas, garantindo que cada item de pedido esteja vinculado a um pedido e a um produto válido.
4. **Backups e Recuperação**
   - O Amazon RDS gerencia backups automáticos e snapshots manuais para permitir a recuperação de dados em caso de falhas.

**Benefícios**

- **Consistência de Dados:** a capacidade de realizar transações ACID garante que as operações críticas sejam executadas de forma confiável.
- **Consultas Complexas:** utilizando SQL, a equipe pode executar consultas complexas para gerar relatórios detalhados, como vendas por período, popularidade dos produtos e gestão de estoque.
- **Alta Disponibilidade:** a configuração Multi-AZ fornece resiliência contra falhas de zona de disponibilidade, garantindo que o sistema de pedidos esteja sempre disponível.

> **💡 Complemento — a transação do exemplo em EF Core:** com Entity Framework Core, um único `SaveChangesAsync()` já grava pedido e itens numa transação implícita. Transação explícita só é necessária quando há várias chamadas a `SaveChanges` ou operações fora do EF:
>
> ```csharp
> await using var tx = await db.Database.BeginTransactionAsync();
> db.Pedidos.Add(pedido);          // pedido.Itens também são inseridos
> await db.SaveChangesAsync();
> await estoque.BaixarAsync(pedido.Itens); // outra operação no mesmo banco
> await tx.CommitAsync();
> ```
>
> Com RDS (e principalmente com failover Multi-AZ) habilite retry de falhas transitórias, ex.: `options.UseNpgsql(conn, o => o.EnableRetryOnFailure())`.

### Caso de uso: Amazon DynamoDB (banco de dados não relacional)

#### Sistema de pedidos em tempo real para restaurante fast food

Uma rede de restaurantes fast food quer implementar um sistema de pedidos em tempo real que possa ser utilizado em quiosques de autoatendimento e aplicativos móveis. O sistema deve ser capaz de escalar rapidamente para acomodar picos de tráfego, como durante horários de pico e promoções. A baixa latência e a flexibilidade para adicionar novos atributos são requisitos essenciais.

A rede de restaurantes escolhe usar o Amazon DynamoDB devido a sua escalabilidade horizontal, baixa latência e modelo de dados flexível.

**Arquitetura**

1. **Tabela de Pedidos**
   - Chave Primária: `OrderID` (Chave de Partição).
   - Atributos: `CustomerID`, `OrderStatus`, `OrderTime`, `TotalAmount`, `Items` (Lista de Objetos contendo `ProductID`, `Quantity`, `Price`).
2. **Tabela de Clientes**
   - Chave Primária: `CustomerID` (Chave de Partição).
   - Atributos: Nome, Email, Telefone, Endereço.
3. **Tabela de Produtos**
   - Chave Primária: `ProductID` (Chave de Partição).
   - Atributos: Nome, Descrição, Preço, Categoria.
4. **Tabela de Inventário**
   - Chave Primária: `IngredientID` (Chave de Partição).
   - Atributos: Nome, QuantidadeEmEstoque, UnidadeDeMedida.
5. **Índices Secundários Globais (GSI)**
   - `CustomerOrdersIndex`: permite consultas rápidas para obter todos os pedidos de um cliente específico.
   - `ProductOrdersIndex`: facilita a recuperação de todos os pedidos associados a um produto específico.
6. **Atributos Dinâmicos**
   - Novos atributos podem ser facilmente adicionados a qualquer momento sem a necessidade de migrações de esquema, permitindo que a plataforma evolua rapidamente.
7. **Escalabilidade**
   - O DynamoDB é configurado com capacidade sob demanda para escalar automaticamente conforme o número de pedidos e clientes cresce.
8. **Baixa Latência**
   - A plataforma aproveita a baixa latência do DynamoDB para garantir que os pedidos sejam processados instantaneamente, proporcionando uma experiência de usuário rápida e eficiente.
9. **Health Check e Monitoramento**
   - Health checks são configurados para monitorar o status do serviço, garantindo que a aplicação responda adequadamente a falhas e mantenha a alta disponibilidade.

**Benefícios**

- **Escalabilidade Automática:** o DynamoDB escala automaticamente para lidar com aumentos de tráfego, garantindo uma experiência de usuário consistente.
- **Flexibilidade de Dados:** o modelo de dados sem esquema permite adicionar novos atributos e tipos de dados conforme a plataforma cresce e novas funcionalidades são adicionadas.
- **Desempenho de Baixa Latência:** a arquitetura do DynamoDB garante tempos de resposta rápidos, proporcionando uma experiência de usuário fluida e responsiva.
- **Gestão Simplificada:** como um serviço gerenciado, o DynamoDB elimina a necessidade de tarefas administrativas complexas, permitindo que a equipe de desenvolvimento se concentre na criação de novas funcionalidades.

> **💡 Complemento — GSI na prática e modelagem alternativa:** um GSI como `CustomerOrdersIndex` teria `CustomerID` como chave de partição e `OrderTime` como chave de classificação, permitindo "pedidos do cliente X ordenados por data". GSIs são eventualmente consistentes e consomem capacidade própria. A modelagem acima (uma tabela por entidade) é didática; a recomendação da AWS para DynamoDB costuma ser o **single-table design**, agrupando entidades relacionadas na mesma tabela com chaves como `PK = CUSTOMER#123` / `SK = ORDER#2024-08-16#987`. Note também que "estoque" com decrementos concorrentes exige **escritas condicionais** ou `TransactWriteItems` (o DynamoDB tem transações ACID limitadas, até 100 itens).

Nesta seção aprendemos mais sobre SQL e NoSQL, utilizando como exemplo o AWS RDS (que vimos em aula) e o DynamoDB. Agora você conseguirá escolher entre os serviços e tipos de bancos relacionais e não relacionais.

> **💡 Complemento — quadro de decisão RDS x DynamoDB:**
>
> | Critério | RDS (relacional) | DynamoDB (NoSQL) |
> |---|---|---|
> | Modelo | Tabelas com esquema, joins, SQL | Chave-valor/documento, sem joins |
> | Consultas | Ad hoc e complexas (relatórios) | Pelas chaves e índices planejados |
> | Consistência | ACID completo | Eventual por padrão; leitura fortemente consistente opcional; transações limitadas |
> | Escala | Vertical + réplicas de leitura | Horizontal, praticamente ilimitada |
> | Operação | Instância (tamanho, janelas de manutenção) | Serverless, sem instância |
> | Custo | Por hora de instância + storage | Por requisição/capacidade + storage |
>
> Também existe o **Aurora Serverless v2** (relacional com escala automática, inclusive até 0 ACU em versões recentes) e o **Aurora DSQL** (relacional distribuído serverless), que ficam entre os dois mundos.

### O que você viu nesta aula?

Você conheceu o banco relacional da AWS, chamado RDS, um serviço focado e administrado pela AWS voltado para dados. Também criamos nosso primeiro banco, que será utilizado em aulas futuras.

Além disso, aprendemos a configurar o banco e a garantir segurança e performance. Vimos também sobre o serviço DynamoDB da AWS, que é voltado para bancos não relacionais. Por fim, conseguimos diferenciar quando escolher RDS ou DynamoDB em uma arquitetura.

### Referências da aula

- AWS. *O que é o Amazon DynamoDB?* — https://docs.aws.amazon.com/pt_br/amazondynamodb/latest/developerguide/Introduction.html
- AWS. *O que é o Amazon Relational Database Service (Amazon RDS)?* — https://docs.aws.amazon.com/pt_br/AmazonRDS/latest/UserGuide/Welcome.html
- AWS. *Trabalhar com grupos de parâmetros* — https://docs.aws.amazon.com/pt_br/AmazonRDS/latest/UserGuide/USER_WorkingWithParamGroups.html

Palavras-chave: RDS, DynamoDB, SQL, NoSQL.

### Pontos-chave

- RDS é banco **relacional gerenciado** (Aurora, PostgreSQL, MySQL, MariaDB, Oracle, SQL Server): a AWS cuida de hardware, patches e backups.
- Configurações-chave: **engine**, **instance class**, **parameter group**, **option group** e **subnet group** (subnets privadas em pelo menos duas AZs).
- Segurança: banco **não público**, security group liberado apenas para a aplicação, criptografia e credenciais no **Secrets Manager**.
- **Multi-AZ** = alta disponibilidade (failover); **Read Replica** = escala de leitura; backups automáticos permitem *point-in-time restore*.
- DynamoDB é **NoSQL serverless** (chave-valor/documento), com latência de milissegundos, replicação em 3 AZs e tabelas globais.
- No DynamoDB, a chave primária é **simples** (partição) ou **composta** (partição + classificação); GSIs habilitam outros padrões de acesso.
- Escolha RDS para **consistência ACID e consultas complexas**; DynamoDB para **escala massiva, baixa latência e esquema flexível**.

---

## Aula 10 - Criando uma aplicação com a AWS (SonarQube)

### O que vem por aí?

Nesta aula faremos a criação de duas arquiteturas diferentes utilizando o RDS como banco de dados. No ECR, para coletar a imagem e para a execução e orquestração dos containers, vamos utilizar os serviços da AWS. Realizaremos a criação da estrutura com AWS ECS e AWS EKS e faremos o deploy do SonarQube em ambos os serviços para aplicar todo o conhecimento adquirido durante a disciplina.

### Hands On

Nesta aula vamos criar toda a estrutura necessária para rodar o SonarQube no AWS ECS e no AWS EKS, utilizando nosso banco de dados criado e nosso ECR para pegar a imagem e fazer o deploy em ambos os serviços.

> **💡 Complemento — pré-requisitos do SonarQube que o deploy precisa respeitar:**
>
> - **Banco de dados:** PostgreSQL (o mais usado), Microsoft SQL Server ou Oracle. **MySQL não é suportado.** Crie no RDS um database e um usuário dedicados (ex.: `sonarqube`).
> - **Variáveis de ambiente** da imagem oficial: `SONAR_JDBC_URL` (ex.: `jdbc:postgresql://<endpoint-rds>:5432/sonarqube`), `SONAR_JDBC_USERNAME`, `SONAR_JDBC_PASSWORD`.
> - **Porta** HTTP: `9000`. Login inicial `admin`/`admin` (o sistema obriga a troca no primeiro acesso).
> - **Memória:** o SonarQube embute um Elasticsearch e precisa de pelo menos ~2 GB de RAM (na prática, 4 GB é mais confortável).
> - **`vm.max_map_count`** ≥ 524288 no host, exigido pelo Elasticsearch. Em EC2/EKS com nós próprios ajusta-se via `sysctl` (o Helm chart oficial tem um *init container* para isso). No **Fargate** não é possível alterar `sysctl`; o contorno usual é a variável `SONAR_SEARCH_JAVAADDITIONALOPTS=-Dnode.store.allow_mmap=false` (alguns guias também usam `SONAR_ES_BOOTSTRAP_CHECKS_DISABLE=true`).
> - **Persistência:** os diretórios `/opt/sonarqube/data`, `/opt/sonarqube/extensions` e `/opt/sonarqube/logs` devem ficar em volume (EFS no ECS; PVC no EKS). A Community Edition **não** escala horizontalmente — rode **uma réplica**.
>
> Enviando a imagem para o ECR:
>
> ```bash
> aws ecr create-repository --repository-name sonarqube
> aws ecr get-login-password --region us-east-1 | \
>   docker login --username AWS --password-stdin 123456789012.dkr.ecr.us-east-1.amazonaws.com
>
> docker pull sonarqube:community
> docker tag sonarqube:community 123456789012.dkr.ecr.us-east-1.amazonaws.com/sonarqube:community
> docker push 123456789012.dkr.ecr.us-east-1.amazonaws.com/sonarqube:community
> ```

> **💡 Complemento — esboço do deploy no ECS (Fargate):** trecho de *task definition* (JSON). A senha vem do Secrets Manager via `secrets`, não em texto puro:
>
> ```json
> {
>   "family": "sonarqube",
>   "requiresCompatibilities": ["FARGATE"],
>   "networkMode": "awsvpc",
>   "cpu": "2048",
>   "memory": "4096",
>   "executionRoleArn": "arn:aws:iam::123456789012:role/ecsTaskExecutionRole",
>   "containerDefinitions": [
>     {
>       "name": "sonarqube",
>       "image": "123456789012.dkr.ecr.us-east-1.amazonaws.com/sonarqube:community",
>       "portMappings": [{ "containerPort": 9000, "protocol": "tcp" }],
>       "environment": [
>         { "name": "SONAR_JDBC_URL", "value": "jdbc:postgresql://fcg-postgres.xxxxxx.us-east-1.rds.amazonaws.com:5432/sonarqube" },
>         { "name": "SONAR_JDBC_USERNAME", "value": "sonarqube" },
>         { "name": "SONAR_SEARCH_JAVAADDITIONALOPTS", "value": "-Dnode.store.allow_mmap=false" }
>       ],
>       "secrets": [
>         { "name": "SONAR_JDBC_PASSWORD", "valueFrom": "arn:aws:secretsmanager:us-east-1:123456789012:secret:sonarqube-db-AbCdEf:password::" }
>       ],
>       "logConfiguration": {
>         "logDriver": "awslogs",
>         "options": {
>           "awslogs-group": "/ecs/sonarqube",
>           "awslogs-region": "us-east-1",
>           "awslogs-stream-prefix": "sonarqube"
>         }
>       }
>     }
>   ]
> }
> ```
>
> Depois: criar o *cluster*, o *service* (1 task) atrás de um **Application Load Balancer** com health check em `/api/system/status`, e liberar no security group do RDS a porta 5432 para o security group das tasks. A *execution role* precisa de permissão para ler o segredo e puxar a imagem do ECR.

> **💡 Complemento — esboço do deploy no EKS:** o caminho recomendado pela SonarSource é o **Helm chart oficial**:
>
> ```bash
> helm repo add sonarqube https://SonarSource.github.io/helm-chart-sonarqube
> helm repo update
>
> kubectl create namespace sonarqube
> kubectl -n sonarqube create secret generic sonar-db \
>   --from-literal=password='<senha-do-usuario-sonarqube>'
>
> helm upgrade --install sonarqube sonarqube/sonarqube -n sonarqube -f values.yaml
> ```
>
> `values.yaml` usando o RDS em vez do PostgreSQL embutido do chart (os nomes das chaves variam entre versões do chart — confira o `values.yaml` da versão instalada):
>
> ```yaml
> image:
>   repository: 123456789012.dkr.ecr.us-east-1.amazonaws.com/sonarqube
>   tag: community
>
> postgresql:
>   enabled: false
>
> jdbcOverwrite:
>   enabled: true
>   jdbcUrl: "jdbc:postgresql://fcg-postgres.xxxxxx.us-east-1.rds.amazonaws.com:5432/sonarqube"
>   jdbcUsername: "sonarqube"
>   jdbcSecretName: "sonar-db"
>   jdbcSecretPasswordKey: "password"
>
> persistence:
>   enabled: true
>   storageClass: gp3
>   size: 10Gi
>
> service:
>   type: ClusterIP
> ```
>
> Exponha com um `Ingress` (AWS Load Balancer Controller) ou, para teste, `kubectl -n sonarqube port-forward svc/sonarqube-sonarqube 9000:9000`. Para os nós EKS acessarem o ECR, a role dos nós precisa da política `AmazonEC2ContainerRegistryReadOnly`; para o PVC funcionar, o **EBS CSI Driver** precisa estar instalado no cluster.

### Saiba mais

O SonarQube é uma plataforma de código aberto desenvolvida pela SonarSource que permite realizar análises estáticas e dinâmicas do código-fonte. Ele ajuda a identificar problemas de qualidade, bugs, vulnerabilidades de segurança e code smells, promovendo assim práticas de desenvolvimento de software mais saudáveis e sustentáveis.

> **💡 Complemento — precisão e atualização:**
>
> - O SonarQube faz essencialmente **análise estática** (SAST — o código é analisado sem ser executado). Métricas como cobertura de testes são **importadas** de relatórios gerados pelos seus testes; o SonarQube não executa a aplicação (isso seria DAST, outra categoria de ferramenta).
> - Apenas a edição gratuita é *open source* (LGPL). Atualização de nomenclatura: desde o fim de 2024 a edição gratuita chama-se **SonarQube Community Build** e as edições comerciais passaram a se chamar **SonarQube Server** (com versões no formato `2025.x`); a versão SaaS é o **SonarQube Cloud** (antigo SonarCloud). Recursos como análise de *branches* e *pull request decoration* exigem edição paga (ou o plugin comunitário de terceiros).

#### Funcionalidades do SonarQube

**Análise de Qualidade de Código**

- **Bugs:** identificação de erros de programação que podem causar comportamentos indesejados ou falhas.
- **Vulnerabilidades:** detecção de problemas de segurança que podem ser explorados por atacantes.
- **Code Smells:** identificação de padrões de código que indicam problemas de manutenção a longo prazo.

> **💡 Complemento — atualização da taxonomia:** a partir do SonarQube 10.x, as issues passaram a ser classificadas pelo **impacto nas qualidades de software** — **Security**, **Reliability** e **Maintainability** — que correspondem, respectivamente, às antigas vulnerabilidades, bugs e code smells. Existem ainda os **Security Hotspots**: trechos sensíveis que exigem revisão humana (não são necessariamente vulnerabilidades).

**Métricas de Código**

- **Cobertura de Testes:** avaliação da eficácia dos testes automatizados.
- **Duplicação de Código:** detecção de código duplicado que pode ser refatorado.
- **Complexidade Ciclomática:** medição da complexidade do fluxo de controle do código.

> **💡 Complemento — cobertura em projetos .NET:** o SonarQube não calcula cobertura sozinho; você gera o relatório (ex.: com `coverlet` em formato OpenCover) e informa o caminho ao scanner. Além da complexidade ciclomática, o SonarQube usa a **complexidade cognitiva**, que mede o quão difícil o código é de *entender* (mais útil para revisão do que a ciclomática).

**Integração Contínua**

O SonarQube pode ser integrado com ferramentas de CI/CD, como Jenkins, GitLab CI e outros, permitindo análises automáticas a cada commit ou pull request.

> **💡 Complemento — analisando um projeto .NET (SonarScanner for .NET):**
>
> ```bash
> dotnet tool install --global dotnet-sonarscanner
>
> dotnet sonarscanner begin /k:"fcg-users-api" \
>   /d:sonar.host.url="http://sonarqube.exemplo.com:9000" \
>   /d:sonar.token="$SONAR_TOKEN" \
>   /d:sonar.cs.opencover.reportsPaths="**/coverage.opencover.xml"
>
> dotnet build --no-incremental
> dotnet test --collect:"XPlat Code Coverage;Format=opencover"
>
> dotnet sonarscanner end /d:sonar.token="$SONAR_TOKEN"
> ```
>
> Em versões antigas do scanner o parâmetro era `sonar.login`; hoje usa-se `sonar.token`. Gere um token em *My Account → Security* e guarde-o como segredo da pipeline. Para a pipeline **falhar** quando o Quality Gate reprovar, use `/d:sonar.qualitygate.wait=true` no `begin`.
>
> Exemplo no GitHub Actions:
>
> ```yaml
> - name: Análise SonarQube
>   env:
>     SONAR_TOKEN: ${{ secrets.SONAR_TOKEN }}
>   run: |
>     dotnet tool install --global dotnet-sonarscanner
>     dotnet sonarscanner begin /k:"fcg-users-api" /d:sonar.host.url="${{ vars.SONAR_HOST_URL }}" /d:sonar.token="$SONAR_TOKEN" /d:sonar.qualitygate.wait=true /d:sonar.cs.opencover.reportsPaths="**/coverage.opencover.xml"
>     dotnet build --no-incremental
>     dotnet test --collect:"XPlat Code Coverage;Format=opencover"
>     dotnet sonarscanner end /d:sonar.token="$SONAR_TOKEN"
> ```
>
> No Azure DevOps existem as tasks `SonarQubePrepare`, `SonarQubeAnalyze` e `SonarQubePublish` (extensão do Marketplace).

**Suporte a Múltiplas Linguagens**

Ele suporta uma ampla variedade de linguagens de programação, incluindo Java, C#, JavaScript, Python, PHP e muitas outras.

**Painel de Controle e Relatórios**

Fornece dashboards e relatórios detalhados sobre a qualidade do código, permitindo a visualização de tendências e a identificação de áreas que necessitam de melhorias.

#### Quality Gates

Quality Gates no SonarQube são um conjunto de regras que determinam se um projeto atende aos padrões mínimos de qualidade antes de ser aprovado para produção. Eles funcionam como pontos de verificação que ajudam a garantir que o código cumpre certos critérios de qualidade e segurança.

*Figura 1 – Quality Gates (elaborado pelo autor, 2024): tela de Quality Gates do SonarQube, com o gate e a lista de condições (métrica, operador e valor) aplicadas ao projeto.*

**Configuração de Quality Gates**

- **Métricas Padrão:** o SonarQube oferece métricas padrão que podem ser usadas para configurar Quality Gates, como cobertura de testes, complexidade e duplicação de código, entre outras.
- **Customização:** é possível criar Quality Gates personalizados, ajustando as regras e os níveis de criticidade conforme as necessidades específicas do projeto ou da organização.
- **Integração com Workflows de CI/CD:** os Quality Gates podem ser integrados em pipelines de CI/CD, permitindo que a análise de qualidade seja parte do processo de build e deployment.

**Componentes dos Quality Gates**

- **Condições:** são regras específicas que precisam ser atendidas. Por exemplo: a cobertura de testes deve ser superior a 80% ou o número de bugs críticos deve ser zero.
- **Níveis de Severidade:** as condições podem ter diferentes níveis de severidade, como bloqueante, crítico, maior, menor e informativo. Dependendo da severidade, diferentes ações podem ser tomadas.
- **Status:** após a análise, um projeto pode ser marcado como Passed (Aprovado) ou Failed (Reprovado) com base nos Quality Gates configurados.

> **💡 Complemento — esclarecendo severidade e o gate padrão:**
>
> - Tecnicamente, a severidade (Blocker, Critical, Major, Minor, Info — nas versões recentes, impactos **Blocker/High/Medium/Low/Info**) é atributo das **regras e issues**; as condições do gate usam métricas derivadas delas (ex.: "Reliability Rating pior que A" ou "número de issues bloqueantes > 0").
> - O gate padrão **"Sonar way"** segue a filosofia **Clean as You Code**: as condições valem para o **código novo** (*new code period*), por exemplo: nenhuma issue nova, todos os Security Hotspots revisados, cobertura ≥ 80% e duplicação ≤ 3% no código novo. Assim, projetos legados podem adotar o gate sem precisar corrigir todo o histórico de uma vez.
> - Armadilha comum: cobertura sempre em 0% porque o caminho do relatório (`reportsPaths`) não bate com o arquivo gerado, ou porque o `dotnet test` rodou fora do intervalo `begin`/`end`.

**Benefícios dos Quality Gates**

- **Prevenção de Débito Técnico:** ajuda a evitar a introdução de débitos técnicos, garantindo que o código novo ou modificado não degrade a qualidade geral do projeto.
- **Segurança:** melhora a segurança do código, assegurando que vulnerabilidades conhecidas sejam identificadas e corrigidas antes de avançar.
- **Consistência:** mantém a consistência da qualidade do código ao longo do tempo, facilitando a manutenção e a evolução do software.
- **Feedback Rápido:** fornece feedback imediato às pessoas desenvolvedoras, permitindo correções rápidas durante o ciclo de desenvolvimento.

#### Quality Profiles

Quality Profiles no SonarQube são conjuntos de regras de análise de código que determinam como o código será avaliado. Cada linguagem de programação pode ter um ou mais perfis de qualidade associados, definindo padrões específicos que o código deve seguir.

*Figura 2 – Quality Profiles (elaborado pelo autor, 2024): tela de Quality Profiles do SonarQube, listando os perfis por linguagem, o perfil padrão e a quantidade de regras ativas.*

**Configuração de Quality Profiles**

- **Perfis Padrão:** o SonarQube fornece perfis padrão para várias linguagens de programação, cobrindo regras comuns e melhores práticas.
- **Customização:** é possível criar e customizar Quality Profiles para atender às necessidades específicas de um projeto ou organização, adicionando, removendo ou ajustando regras.
- **Importação e Exportação:** os Quality Profiles podem ser importados e exportados, facilitando a padronização em diferentes projetos e equipes.

Quality Gates e Quality Profiles são ferramentas essenciais no SonarQube para garantir que o código cumpra critérios mínimos de qualidade antes de ser promovido para produção. Eles ajudam a manter a saúde do projeto, prevenir problemas de segurança, manter padrões de qualidade do código e débito técnico, além de fornecer feedback contínuo a especialistas em desenvolvimento.

> **💡 Complemento — Profile x Gate em uma frase:** o **Quality Profile** define *quais regras* geram issues durante a análise; o **Quality Gate** define *quais limites* sobre os resultados aprovam ou reprovam o projeto. Os perfis padrão ("Sonar way") são somente leitura: para customizar, **estenda** (*extend*) ou **copie** o perfil, assim você continua recebendo regras novas das atualizações. Em .NET, regras de analisadores Roslyn e o `.editorconfig` complementam o SonarQube já na IDE (o **SonarQube for IDE**, antigo SonarLint, mostra as mesmas regras no Visual Studio/VS Code/Rider).

### O que você viu nesta aula?

Você viu como subir um servidor do SonarQube com AWS ECS e EKS. Além disso, utilizamos o banco de dados RDS e o ECR para nossa imagem do SonarQube para a criação do nosso container. Por fim, fizemos o teste da ferramenta.

### Referências da aula

- HOSE, A. *Transform Your Code Quality With SonarQube On AWS ECS: A Comprehensive Guide* (2023) — https://alexanderhose.com/transform-your-code-quality-with-sonarqube-on-aws-ecs-a-comprehensive-guide/
- SONARQUBE. *Deploy SonarQube on Kubernetes* — https://docs.sonarsource.com/sonarqube/9.9/setup-and-upgrade/deploy-on-kubernetes/deploy-sonarqube-on-kubernetes/
- SONARQUBE. *SonarQube 10.6 Documentation* — https://docs.sonarsource.com/sonarqube/latest/

Palavras-chave: SonarQube, EKS, ECS, RDS, Quality Gates.

### Pontos-chave

- A aula integra o que foi visto na disciplina: imagem no **ECR**, execução em **ECS** e em **EKS**, e banco no **RDS**.
- SonarQube é uma plataforma de **análise estática** de código que aponta bugs, vulnerabilidades e code smells, além de métricas de cobertura, duplicação e complexidade.
- O SonarQube precisa de banco externo (PostgreSQL/SQL Server/Oracle — **não MySQL**), porta 9000, memória suficiente e ajustes do Elasticsearch embutido.
- **Quality Gates** são o "portão" de aprovação: condições sobre métricas que resultam em **Passed** ou **Failed**.
- **Quality Profiles** são os conjuntos de regras por linguagem, customizáveis e exportáveis.
- Integrar o scanner na pipeline (com espera pelo gate) transforma qualidade em **critério de bloqueio** do deploy, prevenindo débito técnico.

---

## Aplicação no Tech Challenge da Fase 4

Como os temas das aulas 7 a 10 se conectam ao projeto **FIAP Cloud Games (FCG)**:

### NotificationsAPI como Lambda (já existente desde a fase 3)

- A **NotificationsAPI** já é uma função **Lambda** acionada por mensageria (**SNS → SQS → Lambda**) e persistindo em **DynamoDB** desde a fase 3. Ou seja, o projeto já usa na prática os dois mundos da Aula 9: relacional para os serviços principais e NoSQL para notificações.
- Pontos de melhoria com base nas aulas:
  - Garantir **idempotência** no consumo (a entrega SQS é *at-least-once*), por exemplo gravando no DynamoDB com escrita condicional pelo `MessageId`/`EventId`.
  - Configurar **DLQ** na fila e `ReportBatchItemFailures` no event source mapping.
  - Criar **alarmes CloudWatch** para `Errors` e `Throttles` da Lambda e para `ApproximateAgeOfOldestMessage` / `ApproximateNumberOfMessagesVisible` da fila e da DLQ.
  - Definir **retenção** no log group `/aws/lambda/...`.
  - Se alguma notificação for periódica (ex.: resumo diário de promoções), usar regra **EventBridge com cron em UTC**; fluxos de várias etapas (ex.: compra → pagamento → liberação do jogo → notificação) podem virar uma **Step Function**.
  - Manter o runtime .NET LTS suportado no Lambda (atenção às datas de *deprecation*).

### PostgreSQL no RDS

- O PostgreSQL usado pelas APIs (usuários, catálogo de jogos, pagamentos) pode sair de um container/StatefulSet e ir para o **Amazon RDS for PostgreSQL**:
  - DB subnet group com **subnets privadas**, `--no-publicly-accessible`, security group liberando a 5432 apenas para os nós/pods do EKS.
  - Senha master **gerenciada no Secrets Manager**, entregue aos pods via External Secrets Operator ou Secrets Store CSI Driver (em vez de `Secret` do Kubernetes versionado no repositório).
  - `EnableRetryOnFailure()` no EF Core, backups automáticos com retenção definida, Multi-AZ apenas se o orçamento permitir (custa ~2x).
  - Migrations do EF Core rodando como **Job** do Kubernetes ou etapa de pipeline, não na inicialização de várias réplicas ao mesmo tempo.
- Para demonstração/avaliação, `db.t4g.micro` com `gp3` de 20 GB costuma bastar; lembre-se de apagar a instância e os snapshots ao final.

### Observabilidade no EKS: Container Insights x Prometheus/Grafana

| Aspecto | CloudWatch Container Insights | Prometheus + Grafana (fase 3) |
|---|---|---|
| Instalação | Add-on **Amazon CloudWatch Observability** do EKS (CloudWatch Agent + Fluent Bit) | Helm (ex.: `kube-prometheus-stack`) |
| Métricas | Cluster, nó, pod, container; modo *enhanced observability* com mais granularidade; integra com Application Signals | Qualquer métrica exposta em `/metrics` (ex.: `prometheus-net` / OpenTelemetry nas APIs .NET) |
| Logs | Enviados ao CloudWatch Logs (consulta via Logs Insights) | Normalmente Loki ou outra stack à parte |
| Alertas | Alarmes CloudWatch → SNS | Alertmanager |
| Custo/operação | Gerenciado; cobrança por métricas/logs ingeridos | Sem custo de licença, mas você opera e armazena (ou usa Amazon Managed Prometheus/Grafana) |

Sugestão para o Tech Challenge: manter Prometheus/Grafana para métricas de aplicação já construídas na fase 3 e habilitar o Container Insights para ter, com pouco esforço, métricas de infraestrutura do EKS, logs centralizados e alarmes nativos — e mostrar no vídeo um dashboard CloudWatch reunindo EKS, RDS, SQS e Lambda.

### SonarQube como etapa da pipeline CI/CD

- Adicionar à pipeline de cada microsserviço (GitHub Actions ou Azure DevOps) a etapa `dotnet sonarscanner begin` → `build` → `test` com cobertura OpenCover → `end`, com `sonar.qualitygate.wait=true` para **bloquear o deploy** quando o Quality Gate reprovar.
- Ordem sugerida: build/test → análise SonarQube (gate) → build da imagem → push para o **ECR** → deploy no **EKS**.
- Hospedagem do SonarQube: reaproveitar o deploy da Aula 10 (EKS via Helm, banco no RDS) ou usar o **SonarQube Cloud**, gratuito para repositórios públicos, o que evita manter um servidor ligado.
- Definir um Quality Gate do projeto (ex.: cobertura ≥ 80% no código novo, zero vulnerabilidades novas, hotspots revisados) e registrar o print do gate aprovado como evidência.

### Medindo latência para demonstrar o ganho do cache Redis

- Para provar o ganho do **Redis** (ex.: ElastiCache ou Redis no cluster) na listagem do catálogo de jogos, meça **antes e depois** com os mesmos parâmetros:
  - Teste de carga com **k6** ou **JMeter** (mesmo número de usuários virtuais e duração), comparando **p50, p95 e p99** de latência e o throughput.
  - Métricas do lado servidor: histograma de duração HTTP (`http_server_request_duration_seconds` via OpenTelemetry/Prometheus), métrica `TargetResponseTime` do ALB no CloudWatch e taxa de *cache hit* (ex.: métricas `CacheHits`/`CacheMisses` do ElastiCache ou contadores próprios).
  - No RDS, mostrar a queda de `ReadIOPS`/`CPUUtilization` e de conexões (`DatabaseConnections`) quando o cache está ativo.
- Apresentar o resultado num dashboard (CloudWatch ou Grafana) com as duas execuções lado a lado.

### Glossário

| Termo | Significado |
|---|---|
| **Alarm (CloudWatch)** | Regra que avalia uma métrica contra um limiar e muda de estado (`OK`/`ALARM`/`INSUFFICIENT_DATA`), disparando ações. |
| **Cold start** | Latência extra na primeira invocação de um novo ambiente de execução da Lambda. |
| **Container Insights** | Recurso do CloudWatch que coleta métricas e logs de clusters ECS/EKS. |
| **CRON** | Sintaxe de agendamento por campos de tempo; no EventBridge tem 6 campos e roda em UTC. |
| **DLQ** | *Dead-letter queue*: fila que recebe mensagens que falharam repetidamente. |
| **EventBridge** | Barramento de eventos serverless com regras de roteamento e agendamento. |
| **GSI** | *Global Secondary Index* do DynamoDB, com chave de partição/classificação alternativa. |
| **Layer** | Pacote de dependências compartilhado entre funções Lambda, montado em `/opt`. |
| **Multi-AZ** | Configuração do RDS com standby síncrono em outra AZ para failover automático. |
| **Parameter group** | Conjunto de parâmetros de configuração do engine de um banco RDS. |
| **Quality Gate** | Conjunto de condições do SonarQube que aprova ou reprova um projeto. |
| **Quality Profile** | Conjunto de regras de análise por linguagem no SonarQube. |
| **Read Replica** | Cópia assíncrona do banco RDS usada para escalar leituras. |
| **Step Functions** | Serviço de orquestração por máquinas de estado (ASL). |
| **Subnet group** | Conjunto de subnets (em pelo menos duas AZs) onde o RDS pode ser alocado. |
