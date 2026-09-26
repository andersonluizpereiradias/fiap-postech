# 04 - Mensageria e Arquitetura Orientada a Eventos (Event-Driven)

> **Para quem é este resumo:** você passou mais de uma década no mundo PowerBuilder — client-server síncrono, DataWindows amarradas ao banco, lógica de negócio rodando "ali mesmo", jobs noturnos em batch para o que não dava para fazer na hora. Este documento mostra como o mundo cloud-native troca esse modelo por **comunicação assíncrona, desacoplada e em tempo quase real**, usando mensageria e eventos como espinha dorsal. Não vou reexplicar lógica de programação — você domina isso. Vou construir **pontes** do que você já conhece para os conceitos novos.

---

## Visão geral: o que é EDA e que problema ela resolve

No mundo PowerBuilder clássico, quando o usuário clicava em "Finalizar Pedido", o fluxo era essencialmente **uma escada de chamadas síncronas**: valida pagamento → baixa estoque → grava nota fiscal → dispara e-mail. Tudo na mesma transação, no mesmo thread, **bloqueando a tela** até a última etapa terminar. Se o servidor de e-mail estava fora, ou a operação inteira falhava, ou você gambiarrava um "tenta de novo depois". O que não cabia no clique virava **job noturno** lendo uma tabela de pendências (`STATUS = 'P'`) — o seu "processamento assíncrono" era um agendador rodando SELECT de hora em hora.

**Arquitetura Orientada a Eventos (Event-Driven Architecture, EDA)** inverte essa lógica. Em vez de um serviço **chamar** outro e esperar resposta, o serviço **publica um fato** ("um pedido foi criado") em um intermediário (o *broker*) e segue a vida. Quem se interessa por esse fato — estoque, fiscal, e-mail, antifraude — **reage** quando puder. Um evento é, nas palavras da Aula 1, *"uma notificação de que algo significativo aconteceu no sistema"*: uma compra foi realizada, um usuário se cadastrou, um pagamento foi processado.

A analogia direta com o seu passado:

| Mundo PowerBuilder / client-server | Mundo Event-Driven |
|---|---|
| Chamada de função síncrona que bloqueia a tela | Publicação de evento num broker; o publisher não espera |
| Trigger de banco que dispara outra operação na mesma transação | Evento publicado que **outros serviços** consomem de forma independente |
| Job noturno lendo tabela de pendências (`STATUS='P'`) | Consumer processando uma fila **continuamente**, em tempo quase real |
| Se o destino caiu, a operação inteira falha | Se o consumer caiu, a mensagem **fica na fila** e é processada quando ele voltar |
| Acoplamento rígido: A precisa conhecer B, C e D | Desacoplamento: A só conhece o broker; não sabe quem consome |

### Por que isso importa (os 3 ganhos centrais)

A Aula 1 destaca três vantagens que valem mais que a complexidade adicional:

- **Desacoplamento** — *"os produtores de eventos não precisam conhecer quem irá consumir esses eventos, e os consumidores não precisam saber quem os produziu"*. Equipes evoluem de forma autônoma, em velocidades diferentes, sem quebrar umas às outras. No PowerBuilder, adicionar uma nova reação a "pedido criado" significava abrir o código do fluxo de finalização e mexer nele. Em EDA, você **sobe um novo consumer** assinando o mesmo evento — o publisher nem fica sabendo.
- **Escalabilidade** — picos de carga viram filas. Numa Black Friday, as compras são **enfileiradas** e processadas conforme a capacidade de cada serviço, sem derrubar o sistema. É o oposto do batch noturno: aqui o "amortecedor" (a fila) trabalha em tempo real.
- **Resiliência** — se um serviço está temporariamente fora, os eventos ficam **armazenados** e são processados quando ele voltar. Isso elimina as **falhas em cascata** típicas do síncrono, onde a queda de um serviço derruba toda a cadeia de chamadas.

### O outro lado da moeda (não existe almoço grátis)

A Aula 1 é honesta quanto aos custos, e você precisa internalizá-los:

- **Complexidade operacional** sobe muito: agora você opera brokers, monitora filas, lida com mensagens duplicadas e se preocupa com ordem de processamento.
- **Consistência eventual**: no síncrono você tinha consistência **imediata** (terminou, está tudo atualizado). Com eventos há um *delay* entre publicar e processar — existe uma **janela de inconsistência temporal**. Para alguém vindo de transações ACID monolíticas, esse é o ajuste mental mais difícil.
- **Debugging e rastreamento** ficam mais complexos: rastrear uma chamada síncrona é trivial; rastrear um evento que se propaga por seis serviços exige **observabilidade** de verdade (correlation IDs, distributed tracing).

> Em outras palavras: EDA não é "melhor que síncrono". É uma **troca consciente** — você cede consistência imediata e simplicidade operacional em favor de desacoplamento, escala e resiliência. Use onde esses ganhos pagam o custo.

---

## Mapa das aulas (índice)

| Aula | Tema | O que você leva |
|---|---|---|
| **1** | Fundamentos de EDA | Vocabulário base: evento, broker, pub/sub, garantias de entrega, idempotência |
| **2** | RabbitMQ com .NET | Modelo AMQP (exchange, queue, routing key), tipos de exchange, producer/consumer em C# |
| **3** | MassTransit | Abstração sobre brokers, consumers, contratos, por que simplifica |
| **4** | Padrões e Event Sourcing | Pub/Sub, Saga, CQRS, Event Sourcing, Outbox, Idempotent Consumer |
| **5** | Apache Kafka | Log distribuído particionado, partitions, offsets, consumer groups, streaming |
| **6** | Kafka CDC com SQL Server | Change Data Capture, Debezium, transformar mudanças do banco em eventos |

Roteiro deste resumo:
1. [Fundamentos de EDA](#1-fundamentos-de-eda)
2. [RabbitMQ com .NET](#2-rabbitmq-com-net)
3. [MassTransit](#3-masstransit-mensageria-sem-acoplar-ao-broker)
4. [Padrões de mensageria e Event Sourcing](#4-padrões-de-mensageria-e-event-sourcing)
5. [Apache Kafka](#5-apache-kafka-log-de-streaming)
6. [Kafka CDC com SQL Server](#6-kafka-cdc-com-sql-server)
7. [Erros comuns e armadilhas](#-erros-comuns--armadilhas)
8. [Glossário](#-glossário-rápido)
9. [Como isto se conecta](#-como-isto-se-conecta)
10. [Checklist e próximos passos](#-checklist-de-domínio)

---

## 1. Fundamentos de EDA

### 1.1 Evento vs. Comando vs. Mensagem

Três palavras que parecem sinônimos, mas têm semântica diferente — e confundi-las leva a arquiteturas ruins:

| Conceito | Intenção | Tempo verbal | Quem conhece o destino | Exemplo |
|---|---|---|---|---|
| **Comando** (*command*) | "Faça isto" | Imperativo | O emissor **sabe** quem deve executar | `ProcessarPagamento` |
| **Evento** (*event*) | "Isto aconteceu" | Passado | O emissor **não sabe** (nem se importa) quem reage | `PagamentoProcessado` |
| **Mensagem** (*message*) | Termo guarda-chuva | — | Depende | Qualquer payload trafegando no broker |

A distinção é arquitetural, não técnica. Um **comando** tem um dono e expressa uma ordem; ainda há acoplamento (você sabe quem vai executar). Um **evento** é um fato consumado, imutável, e gera o desacoplamento máximo: você grita "pedido criado!" para o mundo e quem quiser que escute. **Mensagem** é o envelope físico que transporta qualquer um dos dois.

> **Ponte PowerBuilder:** comando ≈ chamar uma stored procedure específica (você sabe o que ela faz). Evento ≈ um trigger `AFTER INSERT` que notifica que uma linha nasceu, sem o INSERT saber quem vai reagir. EDA pega essa ideia de trigger e a tira de dentro do banco, colocando-a num broker distribuído.

### 1.2 Os atores: Producer, Consumer e Broker

- **Producer / Publisher** — produz e publica mensagens. Na Aula 2: *"os produtores são responsáveis por enviar mensagens"*.
- **Consumer / Subscriber** — recebe e processa. *"Os consumidores são responsáveis por receber e processar essas mensagens"*.
- **Broker** — o intermediário que recebe, armazena e entrega. É o RabbitMQ, o Kafka, o Azure Service Bus. É a peça que **quebra o acoplamento direto** entre producer e consumer.

### 1.3 Fila (Queue) vs. Tópico (Topic) — Ponto-a-ponto vs. Pub/Sub

Esta é a distinção mais importante dos fundamentos:

- **Fila (ponto-a-ponto / point-to-point):** uma mensagem é entregue a **um único** consumidor. Se há N consumidores na mesma fila, eles **dividem** o trabalho (cada mensagem vai para um só). É o padrão **Competing Consumers** — vários workers brigando pelas mensagens para paralelizar.
- **Tópico (publish/subscribe):** uma mensagem é entregue a **todos** os assinantes interessados. Cada subscriber recebe **sua cópia**.

A Aula 1 define Pub/Sub como fundamental: *"publishers enviam eventos para um tópico ou exchange e múltiplos subscribers podem se inscrever para receber esses eventos. O publisher não conhece os subscribers, criando um desacoplamento total"*. Ideal para notificações em tempo real, atualização de cache distribuído e sincronização entre serviços.

| | Fila (P2P) | Tópico (Pub/Sub) |
|---|---|---|
| Quem recebe cada mensagem | **Um** consumidor | **Todos** os assinantes |
| Uso típico | Distribuir trabalho (workers) | Distribuir eventos/notificações |
| Analogia | Fila de caixa de banco | Lista de transmissão / broadcast |

### 1.4 Padrões de comunicação assíncrona (Aula 1)

Além do Pub/Sub, a Aula 1 apresenta:

- **Request/Response assíncrono** — comunicação bidirecional **sem bloquear** o thread. O cliente envia a requisição, continua trabalhando e é notificado quando a resposta chega. Usa-se um **correlation ID** para casar pergunta e resposta. É o contraste direto com o request/response síncrono do PowerBuilder, onde a tela trava esperando.

```csharp
// Request/Response assíncrono com correlation ID (Aula 1)
public class PaymentService
{
    public async Task<PaymentResult> ProcessPaymentAsync(PaymentRequest request)
    {
        var correlationId = Guid.NewGuid().ToString();
        await _messageBus.SendAsync("payment.process", request, correlationId);
        // não bloqueia o thread; aguarda a resposta correlacionada com timeout
        return await _responseHandler.WaitForResponseAsync<PaymentResult>(
            correlationId, TimeSpan.FromMinutes(5));
    }
}
```

- **Event Notification** — notifica que algo mudou **sem carregar todos os dados**. Manda o mínimo (ex.: só o ID) e quem se interessa busca os detalhes depois. Economiza banda e permite que cada serviço tenha sua própria visão dos dados. (Voltaremos a isso em ["evento gordo vs. magro"](#-erros-comuns--armadilhas).)

### 1.5 Garantias de entrega (delivery semantics)

Decisão central de qualquer sistema de mensageria. A Aula 1 e a Aula 5 cobrem os três níveis:

| Garantia | O que promete | Risco | Quando usar |
|---|---|---|---|
| **At-most-once** | No máximo uma vez | Pode **perder** mensagens | Métricas/telemetria onde perder 1 evento não dói |
| **At-least-once** | Pelo menos uma vez | Pode **duplicar** mensagens | Padrão da maioria; exige idempotência |
| **Exactly-once** | Exatamente uma vez | Alto custo/overhead e complexidade | Raro de verdade; ver observação abaixo |

A Aula 5 deixa explícito que o **Kafka garante at-least-once por padrão**: *"se um consumer falhar após processar uma mensagem, mas antes de reconhecer o processamento ao broker, o broker enviará a mensagem novamente"*. Ou seja: na prática, **planeje para duplicatas**.

> ### 🏛️ Observação do Arquiteto: exactly-once é quase um mito
> "Exactly-once delivery" é uma das frases mais perigosas da computação distribuída. O que existe de verdade é **exactly-once *processing*** dentro de fronteiras controladas (ex.: transações Kafka, ou idempotência no consumer + deduplicação). A entrega de rede, sozinha, **não** consegue garantir exactly-once sem que producer e consumer cooperem com deduplicação. A receita pragmática que a indústria adotou é: **at-least-once na entrega + consumer idempotente**. Isso entrega o mesmo efeito prático (cada efeito acontece uma vez) sem o custo proibitivo do exactly-once "puro". Sempre que alguém prometer exactly-once de graça, desconfie — provavelmente há idempotência escondida fazendo o trabalho pesado.

### 1.6 Ordenação (ordering)

Em sistemas distribuídos, **não assuma ordem global**. RabbitMQ preserva ordem dentro de **uma fila** com **um consumer**; assim que você paraleliza (competing consumers), a ordem se perde. Kafka garante ordem **apenas dentro de uma partição** (ver [Seção 5](#5-apache-kafka-log-de-streaming)). Se a ordem importa (ex.: "criou conta" antes de "atualizou conta"), você precisa de uma **chave de particionamento** que mantenha eventos relacionados na mesma partição/fila.

### 1.7 Idempotência

Como você vai conviver com duplicatas (at-least-once), seus handlers precisam ser **idempotentes**: produzir o mesmo resultado mesmo executados várias vezes com os mesmos dados. A Aula 1 traz o exemplo canônico — checar se já processou antes de agir:

```csharp
// Handler idempotente (Aula 1): verifica se o evento já foi processado
public class IdempotentOrderHandler : IEventHandler<OrderCreatedEvent>
{
    private readonly IOrderRepository _repository;

    public async Task Handle(OrderCreatedEvent eventData)
    {
        var existingOrder = await _repository.GetByIdAsync(eventData.OrderId);
        if (existingOrder != null)
            return; // já processado — ignora a duplicata

        var order = new Order(eventData.OrderId, eventData.CustomerId, eventData.Amount);
        await _repository.SaveAsync(order);
    }
}
```

> **Ponte PowerBuilder:** idempotência é a versão distribuída do velho `IF NOT EXISTS (SELECT ...) THEN INSERT`. A diferença é que aqui não basta a unicidade do banco — você desenha o handler inteiro para tolerar reprocessamento, porque a duplicata é a regra, não a exceção.

### 1.8 Dead-Letter Queue (DLQ)

Mensagem que falha repetidamente (não desserializa, viola regra, estoura *retries*) é uma **poison message** — se ficar sendo reprocessada para sempre, ela **trava a fila** inteira. A solução é a **Dead-Letter Queue**: após N tentativas, a mensagem é desviada para uma fila de "quarentena" para análise manual, e a fila principal segue fluindo. A Aula 1 cita DLQ entre os recursos de entrega confiável do RabbitMQ.

> ### 🏛️ Observação do Arquiteto: DLQ não é caixa de descarte, é caixa de entrada operacional
> Muita equipe configura DLQ e nunca mais olha. Erro grave: a DLQ é um **sinal de saúde do sistema**. Trate cada mensagem lá como um incidente: monitore a profundidade da DLQ (alerta se passar de zero por muito tempo), registre **por que** a mensagem morreu (com a stack trace original) e tenha um processo para **reprocessar** após o fix. Uma DLQ silenciosamente enchendo é dado de negócio sendo perdido — só que sem ninguém perceber.

---

## 2. RabbitMQ com .NET

### 2.1 O modelo AMQP — e por que ele não é "só uma fila"

A grande sacada da Aula 2 (e a que mais surpreende quem vem do mundo simples): **no RabbitMQ o producer não publica diretamente na fila**. Ele publica numa **Exchange**, e a exchange — segundo regras de roteamento — decide para qual(is) fila(s) a mensagem vai.

> *"No RabbitMQ, as mensagens não são enviadas diretamente para as filas, mas para as trocas (exchanges). As trocas recebem mensagens dos produtores e as encaminham para as filas com base em regras de roteamento."* — Aula 2

Os quatro conceitos do modelo AMQP:

- **Exchange (troca):** o ponto de entrada. Recebe do producer e roteia.
- **Queue (fila):** onde a mensagem **descansa** até ser consumida.
- **Binding:** a "ligação" entre uma exchange e uma fila (a regra que diz "mensagens que batem com X vão para esta fila").
- **Routing key:** o "endereço" que o producer carimba na mensagem; a exchange usa essa chave (junto com os bindings) para decidir o destino.

```
Producer → [Exchange] --(binding + routing key)--> [Queue] → Consumer
```

### 2.2 Os quatro tipos de Exchange

A escolha do tipo de exchange é onde mora o poder de roteamento do RabbitMQ (Aula 2):

| Tipo | Como roteia | Analogia | Uso típico |
|---|---|---|---|
| **direct** | Routing key **exata** bate com o binding | Correspondência por CEP exato | Roteamento direcionado (ex.: por severidade de log) |
| **fanout** | **Ignora** a routing key; envia para **todas** as filas ligadas | Megafone / broadcast | Pub/Sub puro, notificar todo mundo |
| **topic** | Routing key bate com um **padrão** (`*` e `#`) | Filtro por assunto | Roteamento por hierarquia: `pedido.*.criado` |
| **headers** | Ignora routing key; roteia por **argumentos de cabeçalho** | Filtro por metadados | Roteamento por múltiplos atributos |

A Aula 2: *"a troca direct encaminha com base em uma chave de roteamento; a fanout transmite para todas as filas; a topic encaminha com base em padrão de correspondência; a headers ignora a chave e usa argumentos de cabeçalho"*.

### 2.3 Producer e Consumer em C# (RabbitMQ.Client)

A Aula 2 usa a biblioteca oficial `RabbitMQ.Client`. Producer:

```csharp
var factory = new ConnectionFactory() { HostName = "localhost" };
using (var connection = factory.CreateConnection())
using (var channel = connection.CreateModel())
{
    channel.QueueDeclare(queue: "hello", durable: false, exclusive: false,
                         autoDelete: false, arguments: null);
    var body = Encoding.UTF8.GetBytes("Hello World!");
    // exchange "" = default exchange; routingKey = nome da fila
    channel.BasicPublish(exchange: "", routingKey: "hello",
                         basicProperties: null, body: body);
}
```

Consumer:

```csharp
var factory = new ConnectionFactory() { HostName = "localhost" };
using (var connection = factory.CreateConnection())
using (var channel = connection.CreateModel())
{
    channel.QueueDeclare(queue: "hello", durable: false, exclusive: false,
                         autoDelete: false, arguments: null);
    var consumer = new EventingBasicConsumer(channel);
    consumer.Received += (model, ea) =>
    {
        var message = Encoding.UTF8.GetString(ea.Body.ToArray());
        Console.WriteLine(" [x] Received {0}", message);
    };
    channel.BasicConsume(queue: "hello", autoAck: true, consumer: consumer);
    Console.ReadLine();
}
```

Note `channel.CreateModel()` — no RabbitMQ.Client, **"model" é sinônimo de channel** (canal). E **conexão é cara, canal é barato**: abra uma conexão TCP por aplicação e multiplexe vários canais sobre ela.

### 2.4 Subir RabbitMQ via Docker

A Aula 2 já assume Docker (ver resumo de Docker para o detalhe). Um comando e você tem broker + UI:

```bash
docker run -d --hostname my-rabbit --name rabbitmq \
  -p 15672:15672 -p 5672:5672 rabbitmq:3-management
```

- Porta **5672**: protocolo AMQP (onde a app conecta).
- Porta **15672**: **Management UI** web (`http://localhost:15672`, login `guest`/`guest`). Habilitada pelo plugin `rabbitmq_management`. É aqui que você monitora filas, vê profundidade, taxa de mensagens e republica mensagens.

### 2.5 Confiabilidade: ack/nack, durabilidade e prefetch

Conceitos que a Aula 2 menciona em "Considerações Avançadas" e que são **a diferença entre brinquedo e produção**:

- **Acknowledgement (ack/nack):** o consumer **confirma** (`ack`) que processou com sucesso; só então o broker descarta a mensagem. Se rejeita (`nack`) ou o consumer cai sem confirmar, a mensagem **volta para a fila** (requeue). ⚠️ Nos exemplos acima usa-se `autoAck: true`, que confirma **na entrega**, antes do processamento — se a app cair no meio, a mensagem **se perde**. Em produção, use `autoAck: false` e confirme manualmente **depois** de processar.
- **Durabilidade:** filas e mensagens marcadas como `durable`/`persistent` **sobrevivem a um restart do broker** (são gravadas em disco). A Aula 2 define isso como *"garantir que as mensagens não sejam perdidas em caso de falhas do servidor"*. Os exemplos usam `durable: false` — bom para aprender, ruim para produção.
- **Publisher confirms:** confirmação de que o **broker recebeu** a mensagem do producer (a outra ponta do ack). Fecha o ciclo de entrega confiável.
- **Prefetch (QoS):** limita quantas mensagens não confirmadas o broker entrega a um consumer por vez (`BasicQos`). Sem isso, um consumer rápido "abocanha" milhares de mensagens e desequilibra a distribuição entre workers. Com prefetch baixo, o trabalho se distribui de forma justa.

> ### 🏛️ Observação do Arquiteto: o quarteto da entrega confiável
> Entrega confiável no RabbitMQ não é um botão — é a **combinação** de quatro coisas: (1) `durable` na fila + `persistent` na mensagem, (2) `autoAck: false` com ack manual **após** processar, (3) publisher confirms no producer, e (4) prefetch ajustado para distribuição justa. Faltando qualquer uma, você tem um ponto de perda silenciosa. Em PowerBuilder você confiava no commit transacional do banco para isso; aqui a "transação" está espalhada por rede, broker e disco, e você monta a garantia peça por peça. E mesmo com tudo isso, você ainda lida com **at-least-once** — então idempotência continua obrigatória.

### 2.6 Limitação reconhecida

A própria Aula 2 admite: o RabbitMQ *"pode ter dificuldades com volumes extremamente altos de mensagens pequenas"*. É um **broker de filas** otimizado para roteamento sofisticado e entrega confiável — não para throughput de milhões de eventos/segundo. Para esse caso, o Kafka entra ([Seção 5](#5-apache-kafka-log-de-streaming)).

---

## 3. MassTransit: mensageria sem acoplar ao broker

### 3.1 O problema que o MassTransit resolve

Reveja o código da Seção 2: você está mexendo em `ConnectionFactory`, `CreateModel`, `BasicPublish`, serializando bytes na mão. Isso é a **API crua do RabbitMQ** — verbosa, repetitiva e, pior, **acoplada ao RabbitMQ**. Se amanhã a empresa migrar para Azure Service Bus, você reescreve tudo.

O **MassTransit** é uma biblioteca .NET open-source que é uma **camada de abstração** por cima dos brokers. A Aula 3 o define como algo que *"fornece uma API unificada e fácil de usar para enviar e receber mensagens através de uma variedade de transportes"*. Você programa contra o MassTransit; o **transporte** (RabbitMQ, Azure Service Bus, etc.) vira **detalhe de configuração**.

### 3.2 Os três conceitos do MassTransit (Aula 3)

1. **Contrato de Mensagem (Message Contract):** uma **interface C#** que define o formato da mensagem. *"Cada contrato de mensagem deve ter um identificador único."*
2. **Consumer:** uma classe que implementa `IConsumer<T>`, onde `T` é o tipo de mensagem que ela processa.
3. **Transporte:** o mecanismo físico de transferência (RabbitMQ, Azure SB...).

### 3.3 Os três blocos de código

**Contrato** — apenas uma interface:

```csharp
public interface SubmitOrder
{
    Guid OrderId { get; }
}
```

**Consumer** — implementa `IConsumer<T>`:

```csharp
public class SubmitOrderConsumer : IConsumer<SubmitOrder>
{
    public Task Consume(ConsumeContext<SubmitOrder> context)
    {
        Console.WriteLine("Order Submitted: {0}", context.Message.OrderId);
        return Task.CompletedTask;
    }
}
```

**Configuração** — registra no contêiner DI; note como o RabbitMQ é só um `UsingRabbitMq`:

```csharp
public void ConfigureServices(IServiceCollection services)
{
    services.AddMassTransit(x =>
    {
        x.AddConsumer<SubmitOrderConsumer>();
        x.UsingRabbitMq((context, cfg) =>      // troque por UsingAzureServiceBus e pronto
        {
            cfg.ReceiveEndpoint("submit-order", e =>
            {
                e.ConfigureConsumer<SubmitOrderConsumer>(context);
            });
        });
    });
    services.AddMassTransitHostedService();
}
```

Compare mentalmente com a Seção 2: **não há** `ConnectionFactory`, `CreateModel`, `BasicPublish` nem serialização manual. O MassTransit cuida de declarar exchanges/filas, serializar (JSON por padrão), correlacionar e entregar ao seu consumer já desserializado e tipado.

### 3.4 Por que simplifica (e por que isso é estratégico)

A Aula 3 lista que o MassTransit suporta, "de fábrica", recursos que você teria de construir à mão no RabbitMQ.Client:

- **Retry** — repetição automática de mensagens que falharam, com políticas (immediate, interval, exponential).
- **Saga** — máquinas de estado para transações distribuídas de longa duração (ver [Seção 4](#43-saga-pattern)).
- **Serialização** — JSON automático, contratos versionáveis.
- **Pub/Sub e Request/Reply** — padrões prontos via `Publish()` e request clients.
- **Programação e expiração de mensagens**, **entrega garantida**, **middleware** plugável.

> ### 🏛️ Observação do Arquiteto: a abstração também é uma corrente (com elo de escape)
> A maior vantagem do MassTransit — **não acoplar ao broker** — é real e valiosíssima: trocar RabbitMQ por Azure Service Bus é mudar uma linha de configuração, e isso protege seu investimento. Mas tenha consciência de dois pontos: (1) você troca o acoplamento ao broker por um **acoplamento à abstração** (MassTransit vira dependência crítica); e (2) abstrações vazam — features específicas de um broker (ex.: o particionamento do Kafka, ou sessões do Azure SB) podem não estar 100% expostas, e em algum momento você "fura" a abstração. A regra prática: para o **fluxo comum** de pub/sub e comandos, use a abstração e ganhe portabilidade; para o **caminho crítico de altíssima performance**, esteja preparado para descer ao SDK nativo. O MassTransit é excelente como **padrão da casa**, mantendo o SDK cru como exceção consciente.

---

## 4. Padrões de mensageria e Event Sourcing

A Aula 4 sobe o nível: já não falamos de "como mandar uma mensagem", mas de **como organizar o sistema** em torno de mensagens.

### 4.1 Catálogo de padrões

| Padrão | Problema que resolve | Ideia central |
|---|---|---|
| **Publish/Subscribe** | Distribuir um evento para vários interessados | Publisher não conhece subscribers |
| **Competing Consumers** | Escalar processamento / vazão | N workers dividindo uma fila |
| **Routing** | Direcionar mensagens por critério | Exchanges/bindings (RabbitMQ) ou chaves |
| **Saga** | Transação distribuída entre serviços | Máquina de estado coordenando passos + compensação |
| **Outbox** | Atomicidade entre gravar no banco **e** publicar evento | Persistir evento na mesma transação do dado |
| **Idempotent Consumer** | Conviver com duplicatas (at-least-once) | Detectar e ignorar reprocessamento |

### 4.2 CQRS (Command Query Responsibility Segregation)

A Aula 4 define CQRS como o padrão que *"separa a leitura (queries) e a gravação (commands) em modelos diferentes, melhorando performance, escalabilidade e segurança"*. Na prática, você divide a aplicação em dois lados: um modelo de **escrita** (otimizado para validar e gravar comandos) e um modelo de **leitura** (otimizado para consulta, muitas vezes com banco e schema próprios). Cada lado **escala independentemente**.

> **Ponte PowerBuilder:** no mundo client-server, a **mesma** DataWindow (e a mesma tabela) servia para gravar e para listar. Se o relatório pesado travava o banco, o cadastro sofria junto. CQRS é como ter uma **réplica de leitura** dedicada aos relatórios e DataWindows de consulta, alimentada por eventos do lado de escrita — só que isso vira uma decisão de arquitetura, não um truque de DBA. A sincronização entre os dois lados costuma ser **eventual** (via eventos/mensageria), o que reforça o tema de consistência eventual.

### 4.3 Saga Pattern

O calcanhar de Aquiles dos microsserviços: **não dá para abrir uma transação ACID que abrange seis bancos de dados diferentes**. A Aula 4 apresenta o **Saga Pattern** como a resposta — *"um padrão de design para coordenar transações distribuídas... garante que, se uma operação falhar, todas as outras operações associadas serão revertidas, mantendo a consistência dos dados"*.

A Saga é uma **máquina de estado**: cada estado é uma etapa da transação longa. Se uma etapa falha, a Saga dispara **transações de compensação** (o equivalente distribuído de um rollback — só que "manual", desfazendo o que já foi feito). No MassTransit, sagas são `MassTransitStateMachine`:

```csharp
public class OrderSaga : MassTransitStateMachine<OrderSagaState>
{
    public OrderSaga()
    {
        InstanceState(x => x.CurrentState);
        Event(() => OrderSubmitted, x => x.CorrelateById(m => m.Message.OrderId));

        Initially(
            When(OrderSubmitted)
                .Then(context =>
                {
                    context.Instance.SubmitDate = context.Data.Timestamp;
                    context.Instance.CustomerNumber = context.Data.CustomerNumber;
                })
                .TransitionTo(Submitted));
    }

    public State Submitted { get; private set; }
    public Event<OrderSubmitted> OrderSubmitted { get; private set; }
}
```

Quando chega `OrderSubmitted`, a saga grava os dados e transiciona para o estado `Submitted`. O `CorrelateById(m => m.Message.OrderId)` é o que **casa** a mensagem com a instância de saga certa (correlação por ID do pedido).

> ### 🏛️ Observação do Arquiteto: Saga substitui o commit/rollback que você não tem mais
> Em PowerBuilder, `COMMIT`/`ROLLBACK` resolviam consistência de graça — o banco garantia tudo-ou-nada. Em microsserviços, esse luxo acabou: cada serviço tem seu próprio banco e sua própria transação local. A Saga reconstrói a semântica de "tudo-ou-nada" **na camada de aplicação**, com compensações explícitas. O preço: você precisa desenhar, para cada passo, **o que fazer para desfazê-lo** — e nem tudo é trivial de compensar (como "des-enviar" um e-mail já disparado?). Saga não é gratuita; é o imposto que se paga por ter dados distribuídos.

### 4.4 O padrão Outbox (o detalhe que separa amador de profissional)

> **Atenção:** este é provavelmente o conceito mais importante e mais negligenciado de toda mensageria.

O problema: seu serviço precisa **(a)** gravar o pedido no banco **e (b)** publicar `PedidoCriado` no broker. São **dois sistemas diferentes** (banco + broker), sem uma transação que os abranja. O que acontece se:

- Grava no banco ✅ mas cai antes de publicar ❌ → pedido existe, mas **ninguém foi notificado**. Estoque não baixou, e-mail não saiu.
- Publica no broker ✅ mas o banco dá rollback ❌ → todo mundo reage a um pedido que **não existe**.

Essa é a **dupla escrita (dual write)** — uma fonte clássica de inconsistência. A solução é o **padrão Outbox**:

1. Na **mesma transação** que grava o dado de negócio, você grava o evento numa tabela **`Outbox`** do próprio banco. Atomicidade garantida pelo banco (commit/rollback que você já conhece).
2. Um processo separado (um *relay* / *dispatcher*, ou o suporte nativo do MassTransit) lê a tabela Outbox e publica os eventos no broker, marcando-os como enviados.

Assim, "gravar o dado" e "ter o evento para publicar" viram **uma única operação atômica**. A publicação no broker fica garantida (at-least-once) porque o relay reentrega até confirmar.

> **Ponte PowerBuilder:** o Outbox é, no fundo, uma **tabela de pendências** — exatamente aquela `FILA_ENVIO (STATUS='P')` que você criava para o job noturno! A diferença é que agora: (1) a inserção na pendência está na **mesma transação** do dado (atomicidade real), e (2) o "job" não roda à noite — é um relay contínuo publicando em tempo quase real. Você já fazia Outbox sem saber o nome. A formalização só amarrou as pontas soltas.

O MassTransit oferece Outbox nativo (in-memory e baseado em EF Core), o que o torna ainda mais atraente como padrão da casa.

### 4.5 Idempotent Consumer

Já vimos a essência na [Seção 1.7](#17-idempotência). Como padrão formal, o **Idempotent Consumer** mantém um registro dos **IDs de mensagens já processadas** (uma tabela de "inbox" / dedup store) e descarta qualquer reprocessamento. É o par natural do Outbox: Outbox garante que o evento **será publicado** (mesmo que duplicado), e o Idempotent Consumer garante que ele **só terá efeito uma vez**. Juntos, entregam o tal "exactly-once processing" de forma pragmática.

### 4.6 Event Sourcing

Mudança radical de paradigma para quem vem do mundo relacional. No modelo tradicional (e em PowerBuilder), você guarda o **estado atual**: a linha da tabela `CONTA` tem `SALDO = 150`. Quando o saldo muda, você **sobrescreve** — e a informação de como ele chegou a 150 **se perde** (a menos que você mantenha tabelas de auditoria à parte).

**Event Sourcing** inverte isso: você **não guarda o estado atual**; você guarda a **sequência completa de eventos** que produziram esse estado. A Aula 4: *"armazena o estado de um objeto como uma sequência de eventos... o estado pode ser reconstruído a qualquer momento, reprocessando a sequência de eventos"*.

Em vez de `SALDO = 150`, você guarda:
```
ContaAberta(saldo: 0)
Depositado(100)
Depositado(80)
Sacado(30)
```
O saldo atual (150) é **derivado** somando os eventos. O estado é uma **projeção** do log de eventos.

| | Modelo tradicional (CRUD) | Event Sourcing |
|---|---|---|
| O que se persiste | Estado atual (sobrescreve) | Sequência imutável de eventos |
| Histórico | Perdido (ou auditoria à parte) | **É a fonte da verdade** |
| Estado atual | Lido direto da linha | **Calculado** reprocessando eventos |
| Auditoria / "time travel" | Difícil | Nativo — reconstrói o estado em qualquer ponto no tempo |

**Vantagens** (Aula 4): rastreabilidade e **auditabilidade** totais (você sabe exatamente *como* o sistema chegou ao estado atual), capacidade de **reconstruir o estado no passado** (debugging, análise), e os eventos podem **disparar comportamentos adicionais**.

**Desvantagens** (Aula 4): *"pode resultar em um grande volume de dados armazenados, uma vez que cada mudança de estado é registrada"*; a implementação é complexa e exige entendimento profundo do domínio. Reconstruir estado relendo milhares de eventos fica lento — daí os **snapshots**.

**Snapshots:** para não reprocessar o histórico inteiro toda vez, você salva periodicamente uma "foto" do estado (ex.: a cada 100 eventos). A reconstrução parte do último snapshot e aplica só os eventos posteriores. É um cache do estado calculado.

**Relação com CQRS:** Event Sourcing e CQRS são **parceiros naturais**. O lado de **escrita** grava eventos (o event store, ex.: a lib EventStore citada na Aula 4). Os eventos alimentam **projeções** que constroem os modelos de **leitura** otimizados (o lado query do CQRS). A Aula 4 menciona exatamente isso: *"armazenar os eventos em um banco de dados e usar um mecanismo de projeção para construir o estado atual"*.

> ### 🏛️ Observação do Arquiteto: Event Sourcing é poderoso, mas não é default
> Event Sourcing resolve maravilhosamente domínios onde o **histórico é o negócio**: contabilidade, financeiro, jurídico, qualquer coisa auditável. Mas é tentador aplicá-lo em tudo — e isso é um erro caro. Ele traz versionamento de eventos (o que fazer quando o schema do evento de 2 anos atrás muda?), complexidade de projeções, eventual consistency entre escrita e leitura, e o tal volume crescente de dados. A própria Aula 4 alerta: *"não são uma bala de prata... são ferramentas em seu kit de arquitetura"*. Comece com CRUD tradicional; adote Event Sourcing **cirurgicamente**, só nos agregados onde a trilha de auditoria e o replay valem o custo. E lembre: você **não precisa** de Event Sourcing para fazer EDA — são coisas independentes. Dá para ter eventos voando no broker com bancos CRUD comuns nas pontas.

---

## 5. Apache Kafka: log de streaming

### 5.1 Filosofia: log, não fila

Aqui está a diferença mental mais importante deste resumo. RabbitMQ é um **broker de filas**: a mensagem entra, é entregue, é **consumida e some**. É como uma **fila de pessoas** — quem é atendido vai embora.

Kafka é um **log distribuído, append-only e imutável**. A Aula 5 descreve *"um sistema de mensagens em tempo real com capacidade de armazenamento"*, e a Aula 1 reforça: *"o Kafka trata eventos como um log imutável e distribuído, permitindo que múltiplos consumidores leiam os mesmos eventos em velocidades diferentes"*.

Pense num **arquivo de log que cresce no fim e nunca é apagado** (até a retenção expirar). Ler **não consome** — apenas avança um ponteiro. Vários leitores leem o mesmo log, cada um no seu ritmo, e podem **voltar atrás e reler** (replay). Isso é impossível numa fila tradicional.

> **Ponte PowerBuilder:** RabbitMQ ≈ uma fila de tarefas que você processa e descarta. Kafka ≈ o **transaction log do banco** — um registro sequencial e imutável de tudo que aconteceu, que você pode reler do começo para reconstruir o estado. Não por acaso, Kafka é o casamento perfeito com Event Sourcing e com CDC.

### 5.2 Conceitos do Kafka

A Aula 5 apresenta os componentes; aqui com os conceitos que dão o poder ao Kafka:

- **Topic (tópico):** a categoria/nome do log (ex.: `pedidos`). Producers publicam nele.
- **Partition (partição):** cada tópico é **dividido em partições** — e essa é a chave da escala. Cada partição é um log ordenado independente, podendo viver em brokers diferentes. **Paralelismo = número de partições.**
- **Offset:** a posição sequencial de cada mensagem **dentro de uma partição** (0, 1, 2, ...). O consumer guarda "até qual offset eu li". É o "ponteiro do livro".
- **Producer:** publica em tópicos. Pode escolher a **partição** via uma chave (mensagens com a mesma chave caem na mesma partição → **ordem preservada** para aquela chave).
- **Consumer & Consumer Group:** consumers se organizam em **grupos**. Dentro de um grupo, **cada partição é lida por exatamente um consumer** — é o competing consumers do Kafka, e o que permite escalar. Grupos **diferentes** leem o **mesmo** tópico de forma independente (pub/sub entre grupos).
- **Broker:** servidor que armazena partições. Um **cluster** tem vários brokers.
- **Replicação:** cada partição é replicada em N brokers (réplicas líder + seguidoras). Se um broker cai, outra réplica assume → **tolerância a falhas**.
- **Retenção (retention):** quanto tempo as mensagens ficam no log antes de serem descartadas. A Aula 5: *"podemos escolher quanto tempo elas permanecerão disponíveis para consumo antes de serem excluídas"*. Pode ser por tempo (7 dias) ou tamanho — e há quem use retenção **infinita** (Kafka como fonte da verdade).

### 5.3 Ordenação e garantias no Kafka

- **Ordem:** garantida **apenas dentro de uma partição**. Não há ordem global entre partições. Por isso a **chave de particionamento** importa: eventos que precisam de ordem (ex.: tudo do mesmo `clienteId`) devem ir para a mesma partição.
- **Entrega:** **at-least-once por padrão** (Aula 5). Se o consumer processa mas cai antes de commitar o offset, o broker reentrega — logo, **idempotência continua obrigatória**.

### 5.4 Producer e Consumer em .NET (Confluent.Kafka)

A Aula 5 usa a biblioteca `Confluent.Kafka`. Producer:

```csharp
var config = new ProducerConfig { BootstrapServers = "localhost:9092" };
using (var producer = new ProducerBuilder<Null, string>(config).Build())
{
    try
    {
        var dr = await producer.ProduceAsync("topic-name",
            new Message<Null, string> { Value = "message-value" });
        Console.WriteLine($"Delivered '{dr.Value}' to '{dr.TopicPartitionOffset}'");
    }
    catch (ProduceException<Null, string> e)
    {
        Console.WriteLine($"Delivery failed: {e.Error.Reason}");
    }
}
```

Consumer (note `GroupId` e `AutoOffsetReset`):

```csharp
var conf = new ConsumerConfig
{
    GroupId = "test-consumer-group",
    BootstrapServers = "localhost:9092",
    AutoOffsetReset = AutoOffsetReset.Earliest  // começa do início se não há offset salvo
};
using (var c = new ConsumerBuilder<Ignore, string>(conf).Build())
{
    c.Subscribe("topic-name");
    var cts = new CancellationTokenSource();
    Console.CancelKeyPress += (_, e) => { e.Cancel = true; cts.Cancel(); };
    try
    {
        while (true)
        {
            var cr = c.Consume(cts.Token);
            Console.WriteLine($"Consumed '{cr.Value}' at: '{cr.TopicPartitionOffset}'.");
        }
    }
    catch (OperationCanceledException)
    {
        c.Close();
    }
}
```

A `TopicPartitionOffset` no output mostra exatamente os três conceitos: **tópico**, **partição** e **offset**.

### 5.5 Kafka Streams

A Aula 5 cita o **Kafka Streams**: uma biblioteca para *"criar aplicações e microsserviços de processamento de dados em tempo real... transforma fluxos de entrada em fluxos de saída"*. É processamento **contínuo** (não batch): filtra, agrega, junta streams à medida que os dados chegam. (No ecossistema .NET o Streams nativo é limitado; geralmente usa-se consumers + lógica própria, ou ksqlDB.)

### 5.6 RabbitMQ vs. Kafka — quando usar cada um

A própria Aula 5 dá a regra de ouro: *"se você precisa de uma fila de mensagens simples para comunicação entre serviços, talvez seja melhor o RabbitMQ ou SQS; se precisa processar grandes volumes de dados em tempo real, o Kafka é excelente escolha"*.

| Aspecto | **RabbitMQ** (broker de filas) | **Apache Kafka** (log de streaming) |
|---|---|---|
| Modelo mental | Fila: entrega e **descarta** | Log imutável: lê sem consumir, **replay** possível |
| Roteamento | Sofisticado (4 exchanges, bindings) | Simples (tópico + partição por chave) |
| Throughput | Alto, mas sofre com volumes extremos | **Milhões de msg/s** |
| Retenção | Mensagem some após consumo | Configurável (dias, infinito) |
| Reprocessar histórico | Não (mensagem foi consumida) | **Sim** (rebobina o offset) |
| Ordem | Por fila/consumer único | Por **partição** |
| Múltiplos consumidores do mesmo dado | Via fanout (cópias) | Nativo (consumer groups independentes) |
| Casos ideais | Comandos, RPC assíncrono, work queues, roteamento complexo | Event streaming, analytics tempo real, Event Sourcing, CDC, pipelines de dados |
| Custo operacional | Menor; sobe rápido | **Maior**: cluster, ZooKeeper/KRaft, tuning, disco |

E não esqueça o **Azure Service Bus**, citado na Aula 1 como **opção híbrida**: broker enterprise gerenciado, com filas (1:1) e topics (1:many), sessões, detecção de duplicatas e integração nativa com Azure — útil quando você quer mensageria sem operar o broker você mesmo.

> ### 🏛️ Observação do Arquiteto: Kafka não é "RabbitMQ turbinado" — e custa caro
> O erro mais comum é tratar Kafka como um RabbitMQ mais rápido e jogá-lo em qualquer problema. São filosofias diferentes. Kafka brilha em **streaming de alto volume, replay e retenção** — e cobra por isso: você opera um cluster distribuído (brokers, coordenação via ZooKeeper ou KRaft, particionamento, balanceamento de réplicas), dimensiona disco para retenção, e ganha uma curva de aprendizado operacional íngreme. Para "mandar um comando de um serviço para outro e processar uma vez", Kafka é **overkill** — RabbitMQ ou Azure Service Bus entregam com uma fração da complexidade. Escolha pela **forma do problema** (fila de trabalho vs. fluxo de eventos), não pelo benchmark de throughput. Muita arquitetura usa os **dois**: RabbitMQ/MassTransit para comandos e workflows, Kafka para o fluxo de eventos de dados.

---

## 6. Kafka CDC com SQL Server

### 6.1 O problema: como eventos do legado entram no mundo de mensageria?

Você tem um SQL Server cheio de dados e de aplicações legadas (talvez **a sua aplicação PowerBuilder**) escrevendo direto nas tabelas. Esses sistemas **não publicam eventos** — eles fazem `INSERT`/`UPDATE`/`DELETE` e pronto. Como fazer o mundo moderno orientado a eventos **reagir** a essas mudanças sem reescrever o legado?

A resposta é **Change Data Capture (CDC)**.

### 6.2 O que é CDC

A Aula 6 define: *"Change Data Capture (CDC) é uma tecnologia que permite capturar e rastrear alterações em um banco de dados. No SQL Server, o CDC registra inserções, atualizações e deleções em tabelas específicas, permitindo que as aplicações processem essas alterações em tempo real."*

O SQL Server, ao habilitar CDC, passa a **ler o seu transaction log** e a registrar cada mudança em tabelas de captura. Você não precisa colocar triggers manuais nem tocar nas aplicações que escrevem — o banco expõe as mudanças para você.

Habilitar CDC no SQL Server (Aula 6):

```sql
USE YourDatabase;
GO
EXEC sys.sp_cdc_enable_db;          -- habilita CDC no banco
GO
EXEC sys.sp_cdc_enable_table        -- habilita CDC numa tabela
    @source_schema = N'dbo',
    @source_name   = N'YourTable',
    @role_name     = NULL,
    @supports_net_changes = 1;
GO
```

### 6.3 A ponte: Debezium + Kafka Connect

Capturar a mudança no banco é metade do caminho; falta **levá-la ao Kafka**. É aí que entram (Aula 6):

- **Kafka Connect:** o framework de **conectores** do Kafka — pluga fontes (sources) e destinos (sinks) sem escrever código de integração.
- **Debezium SQL Server Connector:** *"uma ferramenta que permite a configuração do CDC e a integração com o Kafka"*. O Debezium lê as tabelas de CDC do SQL Server e **publica cada mudança como um evento num tópico Kafka**.

O pipeline completo:

```
[App legada / PowerBuilder] → INSERT/UPDATE/DELETE → [SQL Server + CDC]
        → [Debezium via Kafka Connect] → [Tópico Kafka] → [Consumer .NET]
```

A Aula 6 monta esse ambiente todo com **Docker Compose** (SQL Server + Kafka + Connect + Debezium em containers — ver resumo de Docker). O consumer .NET é o mesmo `Confluent.Kafka` da Aula 5, agora lendo eventos que **nasceram de mudanças no banco**:

```csharp
using (var c = new ConsumerBuilder<Ignore, string>(conf).Build())
{
    c.Subscribe("YourTopic");   // tópico alimentado pelo Debezium
    while (true)
    {
        var cr = c.Consume();
        Console.WriteLine($"Consumed '{cr.Value}' at: '{cr.TopicPartitionOffset}'.");
        // ex.: atualizar read model, notificar, alimentar analytics em tempo real
    }
}
```

### 6.4 Vantagens, limitações e o caso de uso clássico

**Vantagens** (Aula 6): processamento **em tempo real** das mudanças e **redução de carga no banco** — em vez de aplicações ficarem fazendo *polling* ("alguma coisa mudou?"), as mudanças são **empurradas** conforme ocorrem.

**Limitações** (Aula 6): configurar CDC pode ser **complexo** em bancos grandes com muitas tabelas; tabelas com altíssimo volume de alterações **aumentam a carga** e exigem monitoramento; escalar pode exigir **mais consumers**.

**O caso de uso matador** — citado nas referências da Aula 6 (*"Estrangulamento de aplicações legadas com .NET CORE + Debezium + Kafka"*): o **Strangler Fig Pattern**. Você quer aposentar gradualmente um sistema legado (de novo: imagine seu monólito PowerBuilder). Com CDC, **cada mudança no banco antigo vira um evento**, e novos microsserviços vão consumindo e assumindo responsabilidades aos poucos — sem big-bang, sem parar o legado, "estrangulando-o" pouco a pouco até poder desligá-lo.

> ### 🏛️ Observação do Arquiteto: CDC é o Outbox "para quem não pode tocar no código"
> Repare na simetria com o [padrão Outbox](#44-o-padrão-outbox-o-detalhe-que-separa-amador-de-profissional). O Outbox resolve o dual-write **dentro de uma aplicação que você controla** — você grava o evento na mesma transação. O CDC resolve o mesmo problema **de fora, sem tocar na aplicação**: ele deriva os eventos diretamente do transaction log do banco, então o evento é, por construção, atômico com o dado (ambos vêm do mesmo log). Por isso o CDC é a **ponte de ouro para o legado**: aquele sistema PowerBuilder que você não vai reescrever continua fazendo seus INSERTs como sempre, e o mundo de eventos passa a reagir a ele **sem que ele saiba**. É a forma menos invasiva de trazer um monólito para a arquitetura orientada a eventos. O cuidado: os eventos do CDC são de **baixo nível** (linhas de tabela, schema do banco), não eventos de **negócio** ricos — frequentemente você precisa de uma camada que traduza "linha mudou em `dbo.PEDIDO`" para "`PedidoCriado` de domínio".

---

## ⚠️ Erros comuns / armadilhas

Os pecados capitais de quem está migrando do mundo síncrono para mensageria:

1. **Ignorar reprocessamento (não ser idempotente).** A entrega é **at-least-once** — duplicatas **vão acontecer**. Handler que não tolera ser executado duas vezes vai cobrar dois pagamentos, mandar dois e-mails, dobrar estoque. *Idempotência não é opcional; é a regra.*

2. **Acoplar-se ao broker.** Espalhar `BasicPublish` do RabbitMQ.Client por toda a aplicação amarra você ao RabbitMQ para sempre. Use uma abstração (MassTransit) para o fluxo comum e isole o SDK nativo onde realmente precisar.

3. **Assumir ordenação global (ordering assumptions).** "Os eventos chegam na ordem em que foram publicados" — **falso** em geral. RabbitMQ só garante ordem em fila+consumer único; Kafka só dentro da partição. Se a ordem importa, projete a **chave de particionamento**; se não consegue garantir ordem, projete handlers que **toleram** chegada fora de ordem.

4. **Evento gordo (fat) vs. evento magro (thin) — usado no contexto errado.**
   - *Evento gordo* carrega o estado completo (todos os dados). Bom para desacoplar (consumer não precisa voltar a chamar a origem), mas pesado, acopla ao schema e fica desatualizado.
   - *Evento magro* (Event Notification da Aula 1) carrega só o ID; o consumer busca o resto. Econômico, mas gera carga de leitura de volta na origem e introduz uma janela onde o dado já mudou.
   - A armadilha é escolher sem pensar. Notificações em massa → magro. Quando consumers não devem depender da origem → gordo. Não há resposta universal.

5. **Dual write (gravar no banco e publicar no broker sem atomicidade).** O bug silencioso clássico. Sem **Outbox** (ou CDC), uma falha entre as duas operações deixa banco e broker **inconsistentes**. Já detalhado na [Seção 4.4](#44-o-padrão-outbox-o-detalhe-que-separa-amador-de-profissional).

6. **Tratar DLQ como lixeira.** Mensagens na dead-letter são **incidentes**, não descarte. Monitore e reprocesse. ([Seção 1.8](#18-dead-letter-queue-dlq).)

7. **Esquecer durabilidade e ack manual.** Os exemplos didáticos usam `durable: false` e `autoAck: true` — em produção isso é **perda silenciosa garantida** no primeiro restart ou crash. ([Seção 2.5](#25-confiabilidade-acknack-durabilidade-e-prefetch).)

8. **Não versionar eventos (schema).** Seus eventos vão evoluir. Um consumer antigo precisa entender um evento novo, e vice-versa. Sem estratégia de versionamento (campos opcionais, múltiplas versões de handler, upcasting — Aula 1) e um **schema registry**, uma mudança de contrato derruba consumidores em produção.

9. **Subestimar observabilidade.** "O evento sumiu" é o pesadelo de EDA. Sem **correlation IDs** e **distributed tracing** (Aula 1), você não consegue seguir o rastro de um evento por seis serviços. Monitore **consumer lag** (o quanto os consumers estão atrasados em relação aos producers) — é a métrica de saúde número um.

10. **Usar Kafka onde RabbitMQ bastava (ou o contrário).** Overkill de um lado, limitação do outro. Escolha pela forma do problema. ([Seção 5.6](#56-rabbitmq-vs-kafka--quando-usar-cada-um).)

11. **Achar que consistência eventual é "bug".** Vindo de ACID, é tentador "consertar" a janela de inconsistência forçando sincronismo — e aí você jogou fora todo o benefício de EDA. O certo é **desenhar a UX e o negócio** para conviver com ela (ex.: "seu pedido está sendo processado").

---

## 📖 Glossário rápido

| Termo | Definição curta |
|---|---|
| **EDA** | Event-Driven Architecture — arquitetura onde eventos são o meio principal de comunicação |
| **Evento** | Fato consumado e imutável ("algo aconteceu"), no passado |
| **Comando** | Ordem para algo acontecer ("faça isto"), com destino conhecido |
| **Broker** | Intermediário que recebe, armazena e entrega mensagens (RabbitMQ, Kafka, Azure SB) |
| **Producer / Consumer** | Quem publica / quem processa mensagens |
| **Fila (Queue)** | Canal ponto-a-ponto: uma mensagem para um consumidor |
| **Tópico (Topic)** | Canal pub/sub: uma mensagem para todos os assinantes |
| **Exchange** | (RabbitMQ) Ponto de entrada que roteia mensagens para filas |
| **Binding / Routing key** | Regra de ligação exchange→fila / chave de roteamento da mensagem |
| **Partition** | (Kafka) Subdivisão de um tópico; unidade de paralelismo e ordem |
| **Offset** | (Kafka) Posição sequencial da mensagem dentro de uma partição |
| **Consumer Group** | (Kafka) Grupo que divide partições; grupos diferentes leem o mesmo tópico independentemente |
| **At-least-once** | Garantia de entrega que pode duplicar (padrão; exige idempotência) |
| **Idempotência** | Processar a mesma mensagem N vezes produz o mesmo resultado de 1 vez |
| **DLQ** | Dead-Letter Queue — quarentena para mensagens que falham repetidamente |
| **Poison message** | Mensagem que sempre falha e travaria a fila se não fosse desviada |
| **CQRS** | Separar modelos de leitura (query) e escrita (command) |
| **Saga** | Máquina de estado que coordena transação distribuída com compensações |
| **Outbox** | Gravar o evento na mesma transação do dado, para publicar de forma atômica |
| **Event Sourcing** | Persistir o estado como sequência de eventos, não como estado atual |
| **Snapshot** | Foto do estado para acelerar a reconstrução em Event Sourcing |
| **CDC** | Change Data Capture — capturar mudanças do banco como eventos |
| **Debezium** | Conector que lê CDC e publica no Kafka via Kafka Connect |
| **Consumer lag** | Quanto o consumer está atrasado em relação ao producer |
| **Correlation ID** | Identificador que amarra mensagens relacionadas no rastreamento |
| **MassTransit** | Biblioteca .NET de abstração sobre brokers (RabbitMQ, Azure SB) |
| **AMQP** | Advanced Message Queuing Protocol — protocolo base do RabbitMQ |

---

## 🔗 Como isto se conecta

Mensageria é o **sistema nervoso** da arquitetura cloud-native — ela só faz sentido pleno em conjunto com os outros resumos desta fase:

- **↔ Microsserviços.** Mensageria é **a cola entre microsserviços**. Microsserviços prega autonomia e bancos por serviço; o preço é não ter mais transações ACID globais nem chamadas síncronas confiáveis. EDA é a resposta: serviços se comunicam por **eventos** (desacoplamento), coordenam transações longas com **Saga**, garantem atomicidade local→broker com **Outbox**, e separam leitura/escrita com **CQRS**. Sem mensageria, "microsserviços" viram um monólito distribuído amarrado por chamadas HTTP síncronas — o pior dos dois mundos.

- **↔ Docker.** Toda a parte prática destas aulas roda em **containers**: RabbitMQ (`rabbitmq:3-management`), Kafka, SQL Server e o stack inteiro de CDC (Aula 6) sobem via **Docker Compose**. Docker é o que torna viável ter broker + banco + conectores rodando idênticos no seu notebook e em produção. Consulte o resumo de Docker para `docker run` e `docker compose up/down`.

- **↔ Kubernetes.** Em produção, brokers e consumers viram workloads no cluster. Aqui mensageria e K8s se reforçam: o **consumer lag** (e a profundidade de filas) é o **gatilho ideal de autoscaling** — KEDA escala o número de pods de consumer conforme as mensagens acumulam. Filas absorvem picos; o K8s adiciona réplicas para drenar. É a materialização da "escalabilidade" prometida pela Aula 1.

- **↔ Projeto FIAP Cloud Games.** Onde aplicar concretamente:
  - **Comprou um jogo** → publica `JogoComprado`. Consumers independentes: liberar o jogo na biblioteca, enviar e-mail de confirmação, atualizar recomendações, contabilizar venda. Nenhum deles trava o checkout. (Pub/Sub, exatamente o exemplo `OrderCreatedEvent` da Aula 1.)
  - **Outbox** para garantir que "registrar a compra no banco" e "publicar `JogoComprado`" sejam atômicos — nada de cobrar e não liberar, ou liberar e não cobrar.
  - **Saga** para o fluxo de compra com pagamento externo: reservar → cobrar → liberar; se a cobrança falha, compensa a reserva.
  - **Idempotência** no consumer de "liberar jogo": se o evento chega duplicado, o usuário não recebe a biblioteca duplicada.
  - **Kafka + CDC** se houver um catálogo legado em SQL Server: mudanças de preço/disponibilidade viram eventos que alimentam a vitrine em tempo real — e abrem caminho para estrangular o legado (Strangler Fig).
  - **MassTransit** como padrão da casa para não acoplar o projeto ao RabbitMQ desde o dia 1.

---

## ✅ Checklist de domínio

Você domina este módulo quando consegue, sem consultar:

- [ ] Explicar a diferença semântica entre **evento, comando e mensagem**.
- [ ] Diferenciar **fila (P2P)** de **tópico (pub/sub)** e dar um caso de uso de cada.
- [ ] Explicar as três **garantias de entrega** e por que **exactly-once é praticamente um mito** (e como at-least-once + idempotência o substitui).
- [ ] Escrever um **handler idempotente** e justificar por que ele é obrigatório.
- [ ] Descrever o modelo **AMQP do RabbitMQ** (exchange → binding → queue) e os **4 tipos de exchange**.
- [ ] Listar o **quarteto da entrega confiável** no RabbitMQ (durabilidade, ack manual, publisher confirms, prefetch).
- [ ] Explicar o que o **MassTransit** abstrai e por que **não acoplar ao broker** é estratégico.
- [ ] Distinguir **CQRS, Saga, Event Sourcing** e dizer quando usar cada um.
- [ ] Explicar o problema do **dual write** e como o **Outbox** o resolve.
- [ ] Articular a diferença de **filosofia entre RabbitMQ (fila) e Kafka (log)** e escolher entre eles por caso de uso.
- [ ] Explicar **partition, offset e consumer group** e o que cada um garante (paralelismo, posição, ordem).
- [ ] Descrever o pipeline **CDC → Debezium → Kafka → consumer .NET** e por que é a ponte ideal para o **legado**.
- [ ] Citar pelo menos cinco **armadilhas** e como evitá-las.

## 🚀 Próximos passos

1. **Mão na massa local:** suba `rabbitmq:3-management` via Docker, abra a Management UI (`localhost:15672`) e publique/consuma uma mensagem com `RabbitMQ.Client`. Observe a fila enchendo e esvaziando na UI.
2. **Refaça com MassTransit:** o mesmo cenário usando contrato + `IConsumer<T>`. Sinta a diferença de produtividade e o desacoplamento do broker.
3. **Implemente idempotência de verdade:** force uma duplicata (republique a mesma mensagem na UI) e veja seu handler idempotente ignorá-la.
4. **Configure uma DLQ** e uma política de retry; mande uma poison message e acompanhe ela cair na quarentena.
5. **Suba um Kafka local** (Confluent ou `docker compose`), crie um tópico com várias partições e veja a `TopicPartitionOffset` mudar entre consumers do mesmo grupo.
6. **Monte o lab de CDC** da Aula 6 com Docker Compose (SQL Server + Kafka + Debezium); faça um `UPDATE` numa tabela e veja o evento aparecer no tópico e no seu consumer .NET.
7. **Aplique no FIAP Cloud Games:** modele o evento `JogoComprado` com Outbox no serviço de compras e um consumer idempotente liberando o jogo.
8. **Aprofunde:** estude **schema registry** (versionamento de eventos), **KEDA** (autoscaling por lag no Kubernetes) e **distributed tracing** (OpenTelemetry) para observabilidade ponta a ponta.

---

> **Fechamento.** Você passou anos num mundo onde "comunicação entre componentes" era uma chamada de função que bloqueava a tela, e "assíncrono" era um job noturno. Mensageria e EDA reescrevem essa premissa: componentes conversam por **fatos publicados**, reagem **quando podem**, sobrevivem a falhas dos vizinhos e escalam absorvendo picos em filas. O custo é real — consistência eventual, complexidade operacional, a obrigação de pensar em idempotência e observabilidade. Mas, como conclui a Aula 1, *"os benefícios superam os desafios quando aplicada adequadamente"*. O segredo está nesse "adequadamente": EDA é uma ferramenta de precisão, não um martelo universal. Use eventos onde o desacoplamento e a resiliência pagam a conta — e mantenha o síncrono onde a simplicidade ainda ganha.
