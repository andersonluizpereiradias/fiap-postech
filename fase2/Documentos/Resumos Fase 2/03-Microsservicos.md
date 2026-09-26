# 🧩 Microsserviços — Guia Aprofundado (Arquitetura de Sistemas .NET, Fase 2)

> **Para quem é este resumo:** você vem de 10+ anos de **PowerBuilder** — mundo client-server, DataWindows, aplicações **monolíticas** sentadas sobre **um banco relacional central**. Você sabe o que é transação ACID, integridade referencial, JOIN e stored procedure melhor do que muita gente. O que muda aqui não é "como programar"; é **como o sistema é decomposto, implantado e como os pedaços conversam pela rede**. Vou usar o monólito que você domina como ponto de partida e mostrar, peça por peça, o que muda — e por quê dói quando muda mal.
>
> A ponte mental mais valiosa: no PowerBuilder, uma "chamada de função" era uma chamada **local, instantânea e confiável**. Em microsserviços, a mesma colaboração vira uma **chamada de rede — lenta, falível e potencialmente indisponível**. Quase tudo de complexidade nova nasce dessa única troca.

---

## 🗺️ Mapa das aulas (índice)

| Aula | Tema | Onde está neste resumo |
|------|------|------------------------|
| 01 | Introdução a Microsserviços | [Visão geral](#1-visão-geral-o-que-são-microsserviços), [Monólito vs Microsserviços](#2-monólito--microsserviços-o-contraste) |
| 02 | Arquitetando Microsserviços | [Princípios de design (DDD, coesão, acoplamento)](#3-princípios-de-design-como-decompor) |
| 03 | Banco de Dados em Microsserviços | [Dados distribuídos (DB-per-service, Saga, CQRS, Event Sourcing, CAP)](#4-dados-em-microsserviços-onde-seu-mundo-mais-muda) |
| 04 | Padrões de Comunicação | [Síncrono vs Assíncrono, API Gateway, BFF](#5-padrões-de-comunicação) |
| 05 | Resiliência e Alta Disponibilidade | [Circuit Breaker, Retry, Bulkhead, Fallback](#6-resiliência-e-alta-disponibilidade) |
| 06 | Observabilidade e Monitoramento | [Logs, Métricas, Traces](#7-observabilidade-e-monitoramento) |
| 07 | Segurança dos Microsserviços | [OAuth2/OIDC, JWT, mTLS, segredos, OWASP](#8-segurança) |

Complementos: **🐳 Docker**, **☸️ Kubernetes** e **📨 Messageria** têm resumos próprios — referencio-os ao longo do texto em vez de reexplicá-los.

---

## 1. Visão geral: o que são microsserviços

Microsserviços são uma **abordagem arquitetural que divide a aplicação em um conjunto de serviços pequenos, independentes e focados em uma única tarefa de negócio**. Cada serviço (o "micro") é **autônomo**: pode ser desenvolvido, implantado e escalado **de forma independente** dos demais.

As características centrais que as aulas destacam:

- **Autonomia** — cada serviço é responsável por uma única função da aplicação e possui (idealmente) seus próprios dados.
- **Desenvolvimento descentralizado** — times diferentes trabalham em serviços diferentes, podendo usar linguagens e tecnologias distintas.
- **Escalabilidade seletiva** — você escala **apenas** o serviço que precisa de mais recursos, em vez de clonar a aplicação inteira.
- **Comunicação via contratos de rede** — REST, gRPC, GraphQL ou **mensageria** (filas/eventos). Não há mais a "chamada de função local".

> 🏛️ **Observação do Arquiteto — microsserviço é uma decisão organizacional, não só técnica.**
> A motivação real raramente é desempenho. É **velocidade de entrega de times independentes**. A famosa **Lei de Conway** diz que "a arquitetura de um sistema espelha a estrutura de comunicação da organização que o constrói". Se você tem **um time só**, microsserviços tendem a dar mais trabalho do que valor — você paga o custo de sistema distribuído sem colher o benefício de paralelizar times. A pergunta certa antes de fatiar não é "isso escala?", é "**quantos times preciso deixar trabalhar sem pisar um no outro?**".

---

## 2. Monólito ↔ Microsserviços: o contraste

No seu mundo PowerBuilder, o monólito tem virtudes que você sentiu na pele: uma transação ACID resolve consistência de graça, um JOIN cruza qualquer tabela, um deploy publica tudo de uma vez, e um stack trace local te leva direto ao bug. As aulas listam as **dores** que aparecem quando o monólito cresce:

- **Unidade coesa, mas rígida** — qualquer alteração exige **recompilar e reimplantar a aplicação inteira**.
- **Dependências fortes** — uma falha em um componente pode derrubar todo o sistema.
- **Escala desperdiçada** — se só o módulo de relatórios precisa de CPU, mesmo assim você escala tudo.
- **Ciclo lento** — cada mudança implica testar o bloco inteiro; risco de impacto inesperado em outra parte.
- **Manutenção complexa** — quanto mais cresce, mais arriscado mexer.

### Tabela de trade-offs (honesta)

| Dimensão | 🏛️ Monólito (seu mundo) | 🧩 Microsserviços |
|----------|------------------------|-------------------|
| **Deploy** | Tudo junto, atômico | Independente por serviço |
| **Escala** | A aplicação inteira | Só o serviço que precisa |
| **Consistência de dados** | ACID forte, "de graça" | **Consistência eventual**, exige design explícito |
| **Comunicação** | Chamada de função local (rápida, confiável) | Chamada de rede (lenta, falível) |
| **Banco de dados** | Um banco central, JOINs livres | **Um banco por serviço**, sem JOIN entre serviços |
| **Times** | Coordenação alta (todos no mesmo código) | Times independentes por serviço |
| **Tecnologia** | Stack única | Poliglota (linguagem/banco por serviço) |
| **Debug / rastreio** | Stack trace local | **Trace distribuído** entre serviços |
| **Falha** | Tudo cai junto | Falha isolável (se bem projetado) |
| **Complexidade operacional** | Baixa | **Alta** (rede, orquestração, observabilidade) |
| **Transação distribuída** | Não existe — é só uma transação | Vira um problema de arquitetura (Saga) |

### ⚖️ Quando NÃO usar microsserviços

As aulas listam os **desafios** (complexidade, testes mais difíceis, governança descentralizada, latência acumulada em cadeias de chamadas, consistência de dados, versionamento, maturidade DevOps da equipe). A leitura sênior disso é: **microsserviços têm um custo fixo alto de entrada.** Não vale para todo projeto.

- **Comece com um monólito (monolith-first).** Para um produto novo, cujos limites de domínio ainda são incertos, o monólito é mais rápido de evoluir e mais barato de errar. Mover uma fronteira dentro do mesmo código é refatorar; mover entre serviços é renegociar contrato de rede + migração de dados.
- **Prefira o monólito modular como meio-termo.** Um monólito bem fatiado internamente (módulos com fronteiras claras, sem acoplamento cruzado de banco) entrega **90% do benefício de organização** com **10% do custo operacional**. É frequentemente o destino correto — não uma fase de transição.
- **Não tem DevOps maduro? Não comece.** Sem CI/CD, automação de infra e observabilidade, microsserviços viram um monte de monólitos pequenos difíceis de operar.

> 🏛️ **Observação do Arquiteto — as 8 falácias da computação distribuída.**
> Engenheiros vindos do mundo monolítico tropeçam nas mesmas suposições falsas (L. Peter Deutsch et al.). Memorize-as, porque cada padrão de resiliência da Aula 05 existe para **negar uma destas**:
> 1. A rede é confiável. 2. A latência é zero. 3. A banda é infinita. 4. A rede é segura. 5. A topologia não muda. 6. Há um administrador único. 7. O custo de transporte é zero. 8. A rede é homogênea.
> No PowerBuilder, chamar um método de outra janela nunca falhava por "rede caiu". Em microsserviços, **toda colaboração entre serviços pode falhar, demorar ou chegar duplicada** — e seu código tem que assumir isso como normal, não como exceção.

---

## 3. Princípios de design (como decompor)

O **maior desafio** dos microsserviços, segundo a Aula 02, é **definir os limites entre os serviços**. Não há bala de prata. A decomposição deve refletir o **domínio de negócio**, não camadas técnicas.

### 3.1 Bounded Context / DDD na decomposição

A abordagem recomendada nas aulas é a **modelagem estratégica do DDD (Domain-Driven Design)**. O fluxo sugerido (baseado no material da Microsoft):

1. **Analisar o domínio** com o especialista de negócio.
2. **Separar os domínios** (ex.: Autenticação, ADM, Professor, Empresa, Candidato).
3. Desenhar os **Bounded Contexts** (contextos delimitados) — cada um vira candidato a microsserviço.

A regra de ouro: **estruture serviços por capacidade de negócio**, não por camada técnica. "Serviço de Pedidos" é capacidade de negócio; "Serviço de Acesso ao Banco" é camada técnica (errado).

> 🏛️ **Observação do Arquiteto — o Bounded Context é a fronteira de dados, não só de código.**
> Para você, vindo do banco único, este é o salto conceitual mais difícil. No DDD, dentro de um Bounded Context existe uma **Linguagem Ubíqua** própria: a palavra "Cliente" pode significar coisas diferentes em "Vendas" e em "Cobrança", com atributos diferentes. No monólito você teria **uma tabela CLIENTE compartilhada**; em microsserviços, **cada contexto tem sua própria noção de Cliente, em seu próprio banco**, e elas se sincronizam por eventos. Aceitar que "o mesmo dado existe em formatos diferentes em lugares diferentes" é o pré-requisito mental para tudo na Aula 03.

### 3.2 Alta coesão e baixo acoplamento

- **Alta coesão funcional:** cada serviço tem um propósito único e bem definido (ex.: "gerenciar contas de usuário", "registrar histórico de entregas"). Isso é o **SRP (Single Responsibility Principle)** aplicado à arquitetura.
- **Baixo acoplamento:** um serviço deve poder mudar **sem forçar mudança simultânea em outro**. Cada serviço **esconde a complexidade interna** atrás de uma interface simples — o candidato agenda um bate-papo com o professor sem saber como a alocação de recursos acontece por dentro.
- **Cuidado com o acoplamento temporal da comunicação síncrona:** a Aula 02 alerta que quando serviços dependem de chamadas síncronas, eles passam a **compartilhar características arquiteturais** (se A chama B de forma síncrona, a disponibilidade de A fica refém da de B).

### 3.3 Tamanho do serviço

Não existe medida exata. "Micro" **não significa minúsculo** — significa **com responsabilidade única e bem delimitada**. Errar pequeno demais é tão ruim quanto errar grande demais:

- **Grande demais** → vira um mini-monólito, sem ganho de autonomia.
- **Pequeno demais** → explosão de chamadas de rede, latência acumulada em cadeia, e um **monólito distribuído** (o pior dos mundos — veja [armadilhas](#9--erros-comuns--armadilhas)).

### 3.4 API Gateway e BFF

A Aula 04 introduz o **API Gateway** como ponto central de entrada quando há muitos serviços:

- **Função:** roteia requisições ao serviço correto, agrega respostas, e centraliza preocupações transversais (autenticação, autorização, rate limiting, TLS).
- **Vantagem:** o cliente fala com **um único endpoint**, em vez de orquestrar N APIs.
- **Desvantagem:** pode virar **ponto único de falha** e adicionar latência — exige alta disponibilidade.

**BFF (Backend for Frontend)** é uma variação: em vez de um gateway genérico, você cria **um gateway por tipo de cliente** (um para o app mobile, outro para a web), cada um moldando os dados ao que aquele front precisa. Evita que um gateway único vire um "monólito de roteamento".

### 3.5 Service Discovery

Em um ambiente onde instâncias sobem e descem dinamicamente (escala horizontal, failover), os endereços de rede mudam o tempo todo. **Service Discovery** (ex.: **Consul**, citado na Aula 05, ou o DNS interno do **Kubernetes** — ver resumo de ☸️ K8s) resolve "onde está o serviço X agora?" sem IPs fixos hardcoded. No mundo monolítico isso simplesmente não existia: o módulo estava no mesmo processo.

---

## 4. Dados em microsserviços (onde seu mundo mais muda)

Esta é a seção que mais contraria 20 anos de instinto de quem vive em banco relacional central. Leia com calma.

### 4.1 Database-per-Service

A prática recomendada (Aula 03): **cada microsserviço tem seu próprio banco de dados, e nenhum serviço acessa diretamente o banco de outro.** A comunicação acontece por **API ou eventos** — nunca por `SELECT` na tabela alheia.

```
  ❌ Monólito (seu mundo)            ✅ Microsserviços
  ┌──────────────────────┐         ┌─────────┐  ┌─────────┐  ┌─────────┐
  │ Pedidos  Estoque     │         │ Pedidos │  │ Estoque │  │ Pagto   │
  │ Pagamento  Usuário   │         └────┬────┘  └────┬────┘  └────┬────┘
  │      ↓  ↓  ↓  ↓       │              │            │            │
  │  ┌────────────────┐  │           ┌──┴──┐      ┌──┴──┐      ┌──┴──┐
  │  │  BANCO ÚNICO   │  │           │ DB  │      │ DB  │      │ DB  │
  │  └────────────────┘  │           └─────┘      └─────┘      └─────┘
  └──────────────────────┘        (sem JOIN entre serviços; só API/eventos)
```

Cada serviço pode escolher a tecnologia que melhor o serve — **persistência poliglota**: o serviço de Catálogo usa **MongoDB** (esquema flexível para produtos), enquanto o de Pagamentos usa **PostgreSQL** (transações ACID seguras). Essa liberdade é um benefício real da autonomia.

> 🏛️ **Observação do Arquiteto — o JOIN morreu, e isso é de propósito.**
> Aqui está a perda mais dolorosa para você: **não existe mais o `JOIN` entre dados de serviços diferentes**. Se o serviço de Pedidos precisa do nome do cliente que vive no serviço de Usuários, ele tem três opções: (a) **chamar a API** de Usuários (acoplamento síncrono + latência); (b) **manter uma cópia local** do nome, atualizada por eventos (duplicação consciente + consistência eventual); ou (c) **compor na leitura** via um modelo CQRS/BFF. A duplicação de dados, que no mundo relacional era pecado mortal (normalização!), aqui vira **estratégia legítima**. O dado deixa de ter "uma fonte da verdade central" e passa a ter "**um dono por contexto, e réplicas eventualmente consistentes em quem precisa**".

### 4.2 Por que o "banco único" deixa de valer — Teorema CAP

A Aula 03 fundamenta isso no **Teorema CAP**: um sistema distribuído só consegue garantir **2 de 3**:

- **C — Consistência:** todos os nós veem o mesmo dado ao mesmo tempo.
- **A — Disponibilidade:** toda requisição recebe resposta.
- **P — Particionamento (Partition tolerance):** o sistema continua operando mesmo com partes da rede desconectadas.

Em sistemas distribuídos, **P é inevitável** (a rede *vai* falhar — falácia nº 1). Logo, a escolha real é entre **C e A**. Bancos SQL tendem a priorizar **CP** (consistência forte); muitos NoSQL escolhem **AP** (disponibilidade + consistência eventual). No monólito, com um banco só, **não havia partição** — você tinha CA confortável. É exatamente essa garantia que você perde ao distribuir.

| | **SQL** (MySQL, PostgreSQL) | **NoSQL** (MongoDB, Cassandra, Redis) |
|---|---|---|
| Esquema | Rígido, validado | Flexível / dinâmico |
| Transações | **ACID** forte | Geralmente consistência eventual |
| Escala | Vertical, JOINs e agregações ricas | **Horizontal**, particionável |
| Tendência CAP | Consistência | Disponibilidade + partição |
| Use quando | Consistência forte: bancário, pagamentos, e-commerce | Alto volume / dados não estruturados: redes sociais, big data, IoT |

### 4.3 Consistência eventual

No banco central você tinha **consistência forte e imediata**. Distribuído, adota-se **consistência eventual**: os dados podem ficar **temporariamente inconsistentes**, mas convergem após um tempo. Isso melhora disponibilidade e escalabilidade, ao custo de o sistema ter de **lidar elegantemente com a janela de inconsistência**.

Exemplo clássico da aula (e-commerce): um item aparece "disponível" para dois usuários ao mesmo tempo. Quem fechar a compra primeiro leva; o segundo é **notificado da indisponibilidade**. A inconsistência temporária é tratada como regra de negócio, não como bug.

### 4.4 Transações distribuídas

Quando uma operação cruza vários serviços (cada um com seu banco), a transação ACID local não basta. As aulas apresentam duas abordagens:

#### Two-Phase Commit (2PC)
Protocolo com **fase de preparação** (todos confirmam que conseguem) + **fase de commit** (efetiva). Dá **consistência forte**, mas introduz **latência alta** e **acoplamento** (todos precisam estar vivos e prontos ao mesmo tempo). Citado para cenários como **transferência bancária**. Na prática, é **evitado** em microsserviços por ser síncrono, bloqueante e frágil a partições.

#### Saga (a abordagem recomendada)
Uma transação de negócio é quebrada em **uma sequência de transações locais**, uma por serviço. Cada passo **publica um evento** indicando sucesso ou falha. Se um passo falha, executam-se **ações compensatórias** (transações que desfazem os passos anteriores).

> Exemplo da aula — reserva de viagem: reservar voo → hotel → carro. Se o **voo falha**, o sistema **cancela** (compensa) hotel e carro. Não há rollback global automático; **cada serviço sabe como desfazer o que fez**.

A Saga tem **dois sabores**:

| | **Coreografia** | **Orquestração** |
|---|---|---|
| Coordenação | Distribuída: cada serviço reage a eventos e emite os seus | Centralizada: um **orquestrador** comanda os passos |
| Acoplamento | Baixo (serviços não se conhecem) | Orquestrador conhece o fluxo todo |
| Visibilidade | Fluxo "espalhado", difícil enxergar o todo | Fluxo explícito num lugar só |
| Risco | Cadeias de eventos viram "efeito dominó" difícil de depurar | Orquestrador pode virar gargalo / ponto central |
| Bom para | Fluxos simples, poucos passos | Fluxos longos, com regras e compensações complexas |

```
COREOGRAFIA (cada um reage a eventos)
 Pedidos --(PedidoCriado)--> Pagamento --(PagamentoOk)--> Estoque --(EstoqueReservado)--> Envio
   ^                                                                                          │
   └──────────────────── (se falha em qualquer ponto: eventos de compensação) ───────────────┘

ORQUESTRAÇÃO (um maestro comanda)
                 ┌─────────────── Orquestrador da Saga ───────────────┐
                 ▼                 ▼                 ▼                 ▼
             Pagamento          Estoque           Envio        (compensa em falha)
```

> 🏛️ **Observação do Arquiteto — não tente recriar o ACID por cima da rede.**
> A tentação do veterano de banco é: "vou orquestrar tudo com 2PC e manter consistência forte como sempre tive". Resista. 2PC distribuído acopla disponibilidade (volta à falácia da rede confiável) e não escala. O movimento mental correto é **trocar "transação atômica" por "processo de negócio com compensação"**. Modele o **desfazer** explicitamente: "estornar pagamento", "liberar estoque reservado". Isso é mais trabalho de design — mas é o preço de não ter mais um banco único arbitrando tudo. Para o aprofundamento de filas/eventos que carregam essas Sagas, veja o resumo de **📨 Messageria**.

### 4.5 CQRS (Command Query Responsibility Segregation)

Separa o modelo de **escrita (Command)** do modelo de **leitura (Query)**:

- **Command** → normalizado, focado em integridade e consistência (criar/atualizar/cancelar pedido).
- **Query** → desnormalizado, focado em desempenho de leitura (listar pedidos, buscar catálogo).

Isso permite **escalar leitura e escrita independentemente** (réplicas de leitura para consultas pesadas sem impactar escrita) e **otimizar cada lado** para seu propósito. Custo: **mais complexidade** e **consistência eventual** entre os dois modelos (o lado de leitura pode estar momentaneamente atrasado em relação ao de escrita).

> Para você: é como ter as DataWindows de relatório lendo de uma **réplica desnormalizada pré-calculada**, enquanto as telas de cadastro escrevem no modelo normalizado — só que aqui a separação é **arquitetural e assíncrona**, não apenas duas views do mesmo banco.

### 4.6 Event Sourcing

Em vez de guardar **o estado atual**, guarda-se a **sequência imutável de eventos** que levaram a ele ("PedidoCriado", "PedidoAtualizado", "PedidoEnviado"). O estado atual é **reconstruído reexecutando os eventos**.

- **Benefícios:** auditabilidade total (histórico completo de cada mudança — ótimo para compliance), facilita consistência eventual, escalabilidade.
- **Desafios:** complexidade de implementação e **consumo de armazenamento** (todos os eventos ficam guardados).
- **Casa naturalmente com CQRS:** os eventos alimentam projeções de leitura.
- Exemplo da aula — contabilidade: o saldo de uma conta é o **replay** de todos os depósitos e retiradas.

### 4.7 Outbox Pattern (complemento prático)

> *(Não detalhado nas aulas, mas é o padrão que fecha o buraco entre "salvar no banco" e "publicar evento" — agrega valor direto ao seu projeto.)*

Problema: ao concluir uma transação local, o serviço precisa **(1) gravar no seu banco** e **(2) publicar um evento** na mensageria. Se gravar e o broker cair antes de publicar (ou vice-versa), você perde o evento ou publica algo que não foi salvo — **inconsistência**.

**Solução Outbox:** dentro da **mesma transação ACID local**, grave a mudança de negócio **e** uma linha numa tabela `Outbox`. Um processo separado (relay) lê a tabela `Outbox` e publica os eventos na fila, marcando como enviados. Como gravação de negócio e registro do evento estão na **mesma transação**, ou ambos acontecem ou nenhum. Garante **entrega ao menos uma vez** (at-least-once) — e por isso o consumidor precisa ser **idempotente** (ver [§6.5](#65-idempotência)).

```
 Transação local ACID            Relay (assíncrono)
 ┌───────────────────┐           ┌──────────────┐
 │ UPDATE pedido ...  │           │ lê Outbox    │──> publica no broker (Kafka/RabbitMQ)
 │ INSERT outbox ...  │  ──────►  │ marca enviado│
 └───────────────────┘           └──────────────┘
```

---

## 5. Padrões de comunicação

A Aula 04 divide em **síncrono** e **assíncrono** — e a escolha define performance, escalabilidade e resiliência do sistema.

### 5.1 Comunicação síncrona (REST, gRPC)

O cliente **espera a resposta** antes de continuar. É a sua "chamada de função", só que pela rede.

**REST** — estilo arquitetural sobre HTTP. Características que a aula reforça:
- **Stateless** — cada requisição carrega tudo o que precisa; o servidor não guarda estado entre chamadas (melhora escalabilidade e tolerância a falhas).
- **Recursos via URI**, operações via **verbos HTTP** (GET, POST, PUT, DELETE).
- Representação textual (**JSON/XML**), cacheável, interface uniforme.
- ⚠️ **Status codes corretos são obrigatórios:** nunca devolva `200` quando houve erro — o serviço chamador precisa do código real (`4xx`, `5xx`) para decidir retry, circuit breaker, alerta etc. Isto foi enfatizado já na Aula 01.

**gRPC** — alternativa do Google sobre HTTP/2, usando **Protocol Buffers (protobuf)** para serializar em **binário**. Menor latência, maior throughput, contrato fortemente tipado. Ideal para **comunicação interna serviço-a-serviço** de alta performance (REST continua ótimo para APIs públicas).

| | **Vantagens** | **Desvantagens** |
|---|---|---|
| **REST/gRPC (síncrono)** | Simplicidade, resposta imediata, controle de fluxo | **Acoplamento temporal** (se o servidor cai/demora, o cliente sofre), dificuldade sob alta carga (muitas conexões simultâneas) |

> **Acoplamento temporal** é o conceito-chave aqui: na comunicação síncrona, **o chamador só funciona se o chamado estiver vivo e rápido agora**. Encadeie A→B→C→D síncronos e a latência (e a probabilidade de falha) **se acumula** — a Aula 01 já avisava sobre cadeias de chamadas.

### 5.2 Comunicação assíncrona (mensageria/eventos)

O serviço **envia uma mensagem e não espera** resposta imediata; o receptor processa no seu tempo. Usa brokers como **RabbitMQ, Kafka, AWS SQS**.

| | **Vantagens** | **Desvantagens** |
|---|---|---|
| **Mensageria (assíncrono)** | **Desacoplamento temporal** (cliente não espera; mais resiliente e escalável), filas absorvem picos de carga | Complexidade operacional (o broker é mais um ponto a operar), mensagens podem **perder-se ou duplicar** → exige **retry, confirmação e idempotência** |

> 🏛️ **Observação do Arquiteto — assíncrono é desacoplamento, não "REST mais lento".**
> A vantagem real não é velocidade; é que **o produtor não precisa saber quem consome, nem se o consumidor está vivo agora**. Você publica `PagamentoAprovado` e segue a vida; quem se importa (Notificações, Estoque, Faturamento) consome quando puder. Isso quebra o acoplamento temporal e deixa cada serviço falhar/escalar isoladamente. O preço: você troca "consistência imediata" por "consistência eventual" e precisa abraçar entrega *at-least-once* com consumidores idempotentes. **O aprofundamento de filas, tópicos, exchanges, DLQ e garantias de entrega está no resumo de 📨 Messageria** — aqui basta saber *quando* escolher assíncrono: sempre que a operação **tolera** processamento posterior e você quer **desacoplar**.

### 5.3 Regra prática de escolha

- **Precisa da resposta agora para continuar** (ex.: validar login, consultar saldo na hora) → **síncrono** (REST/gRPC).
- **A operação pode acontecer "logo mais"** e você quer desacoplar (ex.: enviar e-mail de confirmação, atualizar estoque, gerar nota) → **assíncrono** (evento/fila).
- A Aula 01 já recomendava **assíncrono + filas para mitigar latência** em cadeias de serviços.

---

## 6. Resiliência e alta disponibilidade

Premissa da Aula 05: **em sistemas distribuídos, falhas são inevitáveis** (rede, serviço, hardware). **Resiliência** = continuar operando apesar das falhas. **Alta disponibilidade (HA)** = permanecer operacional com mínimo downtime. No monólito, "ou está no ar ou não está"; aqui, o objetivo é **falhar parcialmente sem derrubar o todo**.

Bases de HA citadas: **redundância** (várias instâncias), **balanceamento de carga**, **failover automático**, **escalabilidade horizontal** (adicionar instâncias, não engordar uma) e **replicação de dados**. Muito disso é entregue pelo **Kubernetes** (ver resumo de ☸️ K8s) — réplicas, self-healing, autoscaling.

### 6.1 Circuit Breaker (disjuntor)

Padrão central da aula. Analogia: o **disjuntor elétrico** (ou o *circuit breaker* da bolsa que pausa o pregão em queda abrupta). Quando um serviço dependente começa a **falhar repetidamente**, o disjuntor **abre** e **para de tentar**, em vez de martelar um serviço já doente. Três estados:

```
        falhas consecutivas atingem o limiar
 ┌──────────┐ ───────────────────────────────► ┌──────────┐
 │  CLOSED  │                                    │   OPEN   │
 │ (passa   │ ◄─────────── sucesso ───────────── │ (bloqueia│
 │  tudo)   │                          ┌──────── │  na hora)│
 └──────────┘                          │  falha   └────┬─────┘
       ▲                               ▼               │ após timeout
       │                         ┌────────────┐ ◄──────┘
       └──── sucesso ─────────── │ HALF-OPEN  │
                                 │ (testa com │
                                 │  1 chamada)│
                                 └────────────┘
```

- **Closed:** tudo passa. Se as falhas consecutivas ultrapassarem o limiar → abre.
- **Open:** chamadas são **bloqueadas imediatamente** (retorna erro ou um **fallback**, ex.: dado em cache no Redis). Evita sobrecarregar o serviço doente e o chamador.
- **Half-Open:** após um tempo, deixa **passar uma chamada de teste**. Sucesso → volta a Closed; falha → volta a Open.

### 6.2 Retry com Backoff Exponencial (+ Jitter)

Ao falhar, **tentar de novo após intervalos crescentes** (1s, 2s, 4s, 8s...) dá tempo ao serviço se recuperar e evita martelá-lo.

> **Jitter** (complemento além do slide): adicione **aleatoriedade** ao intervalo. Sem jitter, se 500 instâncias falham juntas, todas retentam **exatamente** em 1s, 2s, 4s — um **"thundering herd"** que derruba o serviço de novo no mesmo instante. Backoff + jitter espalha as tentativas no tempo. **Regra:** só retente operações **idempotentes** e **erros transitórios** (timeout, 503); nunca retente um `400 Bad Request`.

### 6.3 Bulkhead (anteparo)

Analogia dos **compartimentos estanques de um navio**: isole recursos por serviço/grupo, para que uma seção inundada não afunde o navio inteiro. Na prática: pools de conexões/threads separados por dependência. Se o serviço de Recomendações trava e esgota seu pool, ele **não** consome as threads do serviço de Checkout. **Isolamento de falhas** + possibilidade de **dedicar recursos a serviços críticos**.

### 6.4 Fallback

Comportamento alternativo quando algo falha: retornar **dado padrão**, uma resposta **"enlatada"** ou de cache, em vez de quebrar por completo. Ex.: catálogo de produtos indisponível → mostrar lista cacheada com aviso "preços podem estar desatualizados".

### 6.5 Idempotência

> *(Conceito de resiliência decisivo; ligue-o à mensageria.)*

Uma operação é **idempotente** quando executá-la **N vezes tem o mesmo efeito de executá-la 1 vez**. Como retries e entrega *at-least-once* **vão** causar mensagens/requisições duplicadas, o receptor **precisa** ser idempotente — senão você cobra o cliente duas vezes. Técnicas: chave de idempotência (ex.: `RequestId` único que o serviço registra e ignora se repetido), `UPSERT` em vez de `INSERT`, verificação de estado antes de aplicar.

### 6.6 Health Checks

Endpoints que respondem "estou saudável?" para o orquestrador. Distinção importante (não está explícita no slide, mas é padrão .NET/K8s):
- **Liveness** — "estou vivo?" Se não, o K8s **reinicia** o pod.
- **Readiness** — "estou pronto para receber tráfego?" Se não (ex.: ainda subindo, dependência fora), o load balancer **para de mandar requisições** para ele, mas não o mata.

### 6.7 Ferramentas

A aula cita **Netflix Hystrix** (Circuit Breaker — hoje em manutenção), **Kubernetes** (deploy/escala/self-healing), **Consul** (service discovery), **Prometheus** (monitoramento/alertas).

> 🏛️ **Polly — o canivete de resiliência do .NET.**
> No ecossistema .NET, o **Polly** (integrado nativamente como `Microsoft.Extensions.Http.Resilience` / `Microsoft.Extensions.Resilience`) implementa todos esses padrões de forma composável. Esqueleto conceitual:

```csharp
// Pipeline de resiliência: timeout + retry com backoff/jitter + circuit breaker + fallback
var pipeline = new ResiliencePipelineBuilder<HttpResponseMessage>()
    .AddRetry(new RetryStrategyOptions<HttpResponseMessage>
    {
        MaxRetryAttempts = 3,
        BackoffType      = DelayBackoffType.Exponential, // 2s, 4s, 8s...
        UseJitter        = true,                         // espalha o "thundering herd"
        ShouldHandle     = new PredicateBuilder<HttpResponseMessage>()
                              .Handle<HttpRequestException>()
                              .HandleResult(r => (int)r.StatusCode >= 500)
    })
    .AddCircuitBreaker(new CircuitBreakerStrategyOptions<HttpResponseMessage>
    {
        FailureRatio     = 0.5,                          // abre se 50% falharem...
        SamplingDuration = TimeSpan.FromSeconds(30),     // ...na janela de 30s
        BreakDuration    = TimeSpan.FromSeconds(15)      // fica Open por 15s (depois Half-Open)
    })
    .AddTimeout(TimeSpan.FromSeconds(10))                // timeout é a base de tudo
    .Build();
```

> Em produção você normalmente pluga isso no `HttpClient` via `AddStandardResilienceHandler()` no `IHttpClientFactory` — uma linha que já traz retry + circuit breaker + timeout com defaults sensatos. **Timeout é o padrão mais subestimado:** sem ele, uma dependência lenta **segura suas threads indefinidamente** e a falha se propaga para cima (efeito cascata). Sempre coloque timeout em **toda** chamada de rede.

---

## 7. Observabilidade e Monitoramento

Premissa da Aula 06: quanto mais distribuído e complexo o sistema, mais **inegociável** fica enxergar o que acontece dentro dele. No monólito, um stack trace local resolvia; aqui, **uma única ação do usuário pode atravessar 6 serviços** — sem ferramentas, você fica cego.

**Distinção-chave da aula:**
- **Monitoramento** responde *"O QUE está acontecendo?"* — coleta dados e dispara alertas/painéis sobre comportamento conhecido.
- **Observabilidade** responde *"POR QUÊ está acontecendo?"* — capacidade de entender o **estado interno** a partir do que o sistema emite, inclusive diagnosticando problemas **que você não previu**.

### Os três pilares

| Pilar | O que é | Pergunta que responde |
|-------|---------|------------------------|
| **📝 Logs** | Registros detalhados de eventos em cada serviço | "O que aconteceu exatamente neste ponto?" |
| **📊 Métricas** | Dados numéricos de desempenho (latência, taxa de erro, CPU, memória, req/s) | "O sistema está dentro dos parâmetros?" |
| **🔍 Traces (tracing distribuído)** | Rastreia a **jornada de UMA requisição** por todos os serviços que ela cruza | "Onde, na cadeia, está o gargalo/falha?" |

> 🏛️ **Observação do Arquiteto — sem trace distribuído e correlação, você está cego.**
> Este é **o** ganho que o monólito não precisava. Cada requisição recebe um **Correlation ID / Trace ID** na borda (no API Gateway) e o **propaga** por todas as chamadas seguintes — síncronas (header HTTP) e assíncronas (metadado da mensagem). Assim você consulta um único ID e vê a requisição inteira atravessando Gateway → Pedidos → Pagamento → Estoque, com o tempo gasto em cada salto. **Logs centralizados sem correlação são quase inúteis em microsserviços** — você teria que cruzar manualmente milhares de linhas de serviços diferentes. Garanta o Correlation ID **desde o primeiro serviço que você sobe**, não depois.

### Ferramentas (Aula 06)

- **Prometheus** — coleta de métricas + alertas (via Alertmanager).
- **Grafana** — dashboards/visualização sobre Prometheus, Elasticsearch, InfluxDB.
- **ELK (Elasticsearch + Logstash + Kibana)** — centralização, busca e visualização de **logs**.
- **Jaeger** — **tracing distribuído** (origem na Uber); rastreia requisições ponta a ponta, identifica gargalos.
- **Datadog / New Relic** — plataformas SaaS unificadas (métricas + logs + traces + APM).
- **OpenTelemetry (OTel)** — **padrão aberto** de instrumentação (APIs/SDKs) para coletar traces, métricas e logs e **exportar para qualquer backend** (Prometheus, Jaeger, Datadog...). É a escolha estratégica: instrumente uma vez, troque o backend sem reinstrumentar.

> No .NET, **OpenTelemetry** integra nativamente (`System.Diagnostics.Activity` para traces, `Meter` para métricas) e o **Application Insights** (Azure) é o equivalente gerenciado mais comum no ecossistema Microsoft.

### Boas práticas (Aula 06)
Métricas e logs claros por serviço; **alertas proativos** baseados em limiares (ex.: latência acima de X); **coleta de traces distribuídos**; **logs centralizados** (ELK); **automação de escala e recuperação** via Kubernetes.

---

## 8. Segurança

Aula 07: ao quebrar o monólito em N serviços que conversam pela rede, a **superfície de ataque cresce**. Desafios novos: mais pontos de entrada (cada API), comunicação trafegando por redes (públicas/internas), **autenticação/autorização distribuídas** e **gestão de segredos** espalhada.

### 8.1 Autenticação e Autorização

- **OAuth 2.0** — padrão de **autorização**: permite que serviços acessem recursos **em nome do usuário sem expor as credenciais** dele.
- **OpenID Connect (OIDC)** — estende o OAuth 2.0 adicionando **autenticação federada** (login único / SSO entre serviços).
- **JWT (JSON Web Token)** — token compacto, **assinado digitalmente**, que carrega claims do usuário/serviço. Validável **localmente por cada serviço** sem ir ao banco a cada request — é o que torna a autorização **distribuída e stateless** (casa com o REST stateless da Aula 04). A Aula 02 já propunha um **serviço de Autenticação emitindo JWT com roles** compartilhado entre os demais.

> Para você, vindo do login único do monólito: a virada é que **não há mais uma sessão central no servidor**. O JWT é "auto-contido" — cada serviço confia na **assinatura** do emissor e lê as roles do próprio token. Use tokens **de vida curta** + **refresh tokens** para conter o estrago caso um vaze.

### 8.2 Segurança serviço-a-serviço

- **Criptografia em trânsito (TLS):** **toda** comunicação entre serviços deve ser criptografada, especialmente atravessando redes públicas. Inegociável na nuvem.
- **mTLS (TLS mútuo)** — *(complemento além do slide, mas é o padrão de mercado)*: além do cliente verificar o servidor, **o servidor também verifica o cliente** via certificado. Garante que **só serviços legítimos** conversem entre si — nem todo serviço dentro da rede deve poder chamar qualquer outro. Service meshes (Istio, Linkerd — ver resumo de ☸️ K8s) automatizam mTLS entre pods.
- **Mensageria segura:** mensagens em filas (Kafka/RabbitMQ) devem ser **criptografadas e assinadas** para impedir injeção de mensagens maliciosas.
- **Criptografia em repouso:** dados e arquivos armazenados (bancos, buckets) criptografados — proteção mesmo se o storage for acessado diretamente.

### 8.3 Gestão de segredos

Chaves de API, tokens, credenciais de banco **não** ficam em código ou `appsettings` versionado. Use cofres: **HashiCorp Vault**, **AWS Secrets Manager**, **Azure Key Vault** — com armazenamento seguro e **rotação** de credenciais.

### 8.4 Defesa em profundidade

- **Privilégios mínimos (least privilege):** cada serviço opera com o mínimo de permissões necessárias — limita o estrago de uma invasão.
- **RBAC (Role-Based Access Control):** acesso baseado em funções, bem definido e auditado.
- Cada serviço implementa **seu próprio** controle de acesso (não confie só no gateway).

### 8.5 OWASP Top 10 aplicado a microsserviços

| Ameaça | Mitigação (Aula 07) |
|--------|---------------------|
| **Broken Access Control** (quebra de controle de acesso) | RBAC forte, permissões bem definidas, **auditoria regular**; cada serviço valida acesso |
| **Sensitive Data Exposure** (exposição de dados sensíveis) | TLS em trânsito + criptografia em repouso + privilégio mínimo no acesso ao dado |
| **Injection** (SQL/comando) | Validar e higienizar **toda** entrada; usar **ORM** e **consultas parametrizadas** |
| **Security Misconfiguration** | Automatizar config com **IaC**; auditorias frequentes de conformidade |

Frameworks de governança citados: **OWASP**, **ISO/IEC 27001**, **NIST Cybersecurity Framework**, **COBIT (ISACA)**.

---

## 9. ⚠️ Erros comuns / armadilhas

- **🪨 O Monólito Distribuído** — o pior dos mundos: serviços separados fisicamente, mas **acoplados** entre si (mudar um exige mudar/redeployar vários juntos, fluxos síncronos encadeados A→B→C→D). Você pagou todo o custo da rede e não ganhou autonomia. **Sintoma:** "não dá pra subir o serviço X sozinho". A causa quase sempre é fronteira de domínio errada (§3.1).
- **🗄️ Banco compartilhado por baixo dos panos** — dois serviços lendo/escrevendo na mesma tabela "só pra facilitar". Isso **viola o database-per-service** e reacopla tudo silenciosamente: agora uma mudança de esquema quebra dois serviços, e você perdeu a autonomia sem perceber. Se precisa do dado alheio, use **API ou evento** — nunca SQL direto.
- **🔗 Transações distribuídas síncronas (2PC em toda parte)** — tentar manter consistência forte ACID atravessando serviços via 2PC: acopla disponibilidade, não escala, trava sob partição. Use **Saga + compensação** e abrace consistência eventual.
- **🌊 Cascata de falhas sem isolamento** — sem timeout, circuit breaker e bulkhead, um serviço lento **segura threads** e derruba os que dependem dele, em efeito dominó.
- **📭 Consumidor não idempotente** — assumir entrega "exatamente uma vez". Mensageria é *at-least-once*: duplicatas **vão** acontecer. Sem idempotência, você cobra duas vezes / cria pedido duplicado.
- **🔍 Observabilidade como "depois"** — subir microsserviços sem Correlation ID e trace distribuído desde o dia 1. Quando o bug aparecer em produção, você estará cego e cruzando logs no braço.
- **📉 Status code mentiroso** — devolver `200` em erro. Quebra retry, circuit breaker e métricas dos chamadores (Aula 01).
- **✂️ Fatiar cedo/fino demais** — decompor antes de entender o domínio, ou criar serviços minúsculos. Mover fronteira entre serviços é caríssimo. **Comece monólito/monólito modular** e extraia quando a dor justificar.
- **🔓 Confiar na "rede interna"** — achar que tráfego dentro do cluster é seguro. Sem mTLS e least privilege, um serviço comprometido alcança todos os outros.

---

## 10. 📖 Glossário rápido

| Termo | Definição curta |
|-------|-----------------|
| **Bounded Context** | Fronteira de um modelo de domínio (DDD); candidato natural a microsserviço — e a banco próprio. |
| **Database-per-Service** | Cada serviço dono exclusivo do seu banco; ninguém acessa o banco alheio direto. |
| **Consistência eventual** | Dados ficam temporariamente divergentes e convergem depois; troca consistência imediata por disponibilidade. |
| **Teorema CAP** | Sistema distribuído garante no máx. 2 de {Consistência, Disponibilidade, Partição}; com P inevitável, escolhe-se C ou A. |
| **Saga** | Transação de negócio = sequência de transações locais com **compensações** em caso de falha. |
| **Coreografia / Orquestração** | Saga distribuída por eventos / Saga comandada por um orquestrador central. |
| **2PC (Two-Phase Commit)** | Protocolo de commit distribuído com fase de preparação + commit; consistência forte, alto custo. |
| **CQRS** | Separar modelo de escrita (Command) do de leitura (Query), escaláveis e otimizáveis à parte. |
| **Event Sourcing** | Persistir a sequência imutável de eventos, não o estado atual; estado = replay dos eventos. |
| **Outbox** | Gravar mudança + evento na mesma transação local; relay publica depois. Garante consistência negócio↔evento. |
| **Acoplamento temporal** | Dependência do chamador em o chamado estar vivo/rápido **agora** (típico do síncrono). |
| **API Gateway / BFF** | Ponto único de entrada / gateway dedicado por tipo de cliente. |
| **Service Discovery** | Mecanismo para localizar instâncias de serviços com endereços dinâmicos. |
| **Circuit Breaker** | Disjuntor: para de chamar um serviço em falha (Closed→Open→Half-Open). |
| **Backoff exponencial + Jitter** | Retentar com intervalos crescentes + aleatórios, evitando "thundering herd". |
| **Bulkhead** | Isolamento de recursos por serviço (compartimentos estanques). |
| **Idempotência** | Executar N vezes = executar 1 vez; pré-requisito para retry/at-least-once. |
| **Health Check (liveness/readiness)** | "Estou vivo?" (reinicia se não) / "Pronto p/ tráfego?" (tira do LB se não). |
| **Observabilidade** | Entender o **porquê** do estado interno via logs+métricas+traces. |
| **Correlation/Trace ID** | Identificador propagado por toda a jornada de uma requisição. |
| **OAuth2 / OIDC / JWT** | Autorização delegada / autenticação federada / token assinado auto-contido. |
| **mTLS** | TLS mútuo: cliente **e** servidor se autenticam por certificado. |
| **OWASP Top 10** | Lista das vulnerabilidades web mais críticas; baliza de segurança. |

---

## 11. 🔗 Como isto se conecta

- **🐳 Docker** — cada microsserviço é empacotado como **imagem de contêiner** autônoma (com seu runtime e dependências). É o que viabiliza "deploy independente" na prática e a persistência poliglota (cada serviço sobe seu banco em contêiner). *Ver resumo de Docker.*
- **☸️ Kubernetes** — orquestra esses contêineres: **réplicas** (HA/redundância), **self-healing** (failover automático via health checks da §6.6), **autoscaling** (escalabilidade horizontal da §6), **service discovery** via DNS interno, **Secrets** (§8.3) e **service mesh** para mTLS (§8.2). Boa parte do que a Aula 05 chama de "alta disponibilidade" é entregue pelo K8s. *Ver resumo de Kubernetes.*
- **📨 Messageria** — a espinha dorsal da comunicação **assíncrona** (§5.2), das **Sagas** por coreografia (§4.4), do **Outbox** (§4.7) e da consistência eventual. Filas, tópicos, garantias de entrega, DLQ e idempotência são aprofundados lá. *Ver resumo de Messageria.*
- **🎮 FIAP Cloud Games (este projeto)** — a solução **já está fatiada em microsserviços**: `UsersAPI`, `CatalogAPI`, `PaymentsAPI` e `NotificationsAPI`, cada um com seu `compose.yaml`/projeto próprio. Mapeando ao que vimos:
  - **UsersAPI** → Bounded Context de identidade; candidato a emitir **JWT com roles** (§8.1) consumido pelas demais APIs.
  - **CatalogAPI** → leitura intensa de catálogo de jogos; candidato a **CQRS** e a banco com esquema flexível.
  - **PaymentsAPI** → consistência forte; banco **SQL/ACID**; orquestra a **Saga** de compra (reservar → cobrar → liberar jogo, com compensação se a cobrança falhar).
  - **NotificationsAPI** → consumidor **assíncrono** por excelência: reage a eventos (`PagamentoAprovado`, `JogoLiberado`) via mensageria, **idempotente** para não notificar em duplicidade.
  - A compra de um jogo é exatamente o cenário onde tudo converge: comunicação síncrona na borda + Saga assíncrona entre Payments↔Catalog↔Notifications + Outbox + trace distribuído amarrando o fluxo.

---

## 12. ✅ Checklist de domínio

Marque com sinceridade — se travar em algum, volte à seção indicada.

- [ ] Sei explicar **por que** microsserviços são decisão organizacional (Conway) e **quando NÃO** usar (monólito-first). (§1, §2)
- [ ] Consigo justificar a tabela de trade-offs monólito↔microsserviço para um decisor. (§2)
- [ ] Sei usar **Bounded Context / DDD** para definir fronteiras e por que isso é fronteira de **dados**, não só de código. (§3)
- [ ] Entendo **database-per-service** e por que o **JOIN entre serviços** acabou. (§4.1)
- [ ] Explico o **Teorema CAP** e por que o banco único dava CA confortável. (§4.2)
- [ ] Diferencio **Saga (coreografia × orquestração)** de **2PC**, e sei modelar **compensações**. (§4.4)
- [ ] Sei quando aplicar **CQRS**, **Event Sourcing** e **Outbox**. (§4.5–4.7)
- [ ] Escolho entre **síncrono (REST/gRPC)** e **assíncrono (mensageria)** e explico **acoplamento temporal**. (§5)
- [ ] Implemento **timeout + retry/backoff/jitter + circuit breaker + bulkhead + fallback** (com **Polly** no .NET) e garanto **idempotência**. (§6)
- [ ] Configuro os **três pilares** de observabilidade com **Correlation ID / trace distribuído**. (§7)
- [ ] Protejo o sistema com **OAuth2/OIDC/JWT**, **mTLS**, **cofre de segredos**, **least privilege** e **OWASP Top 10**. (§8)
- [ ] Reconheço os **anti-padrões** — monólito distribuído, banco compartilhado, 2PC síncrono. (§9)

## 13. 🚀 Próximos passos

1. **Pratique no FIAP Cloud Games:** implemente a **Saga de compra** entre `PaymentsAPI` → `CatalogAPI` → `NotificationsAPI` usando mensageria + Outbox; faça `NotificationsAPI` idempotente.
2. **Adicione resiliência:** pluge **Polly** (`AddStandardResilienceHandler`) nos `HttpClient` entre serviços; configure circuit breaker e timeouts.
3. **Instrumente observabilidade:** suba **OpenTelemetry** + um backend (Jaeger/Prometheus/Grafana ou Application Insights) e propague o **Correlation ID** ponta a ponta.
4. **Endureça a segurança:** centralize emissão de **JWT** na `UsersAPI`, valide em cada serviço, e mova segredos para um **Key Vault**.
5. **Aprofunde nos resumos complementares:** 🐳 Docker (empacotamento), ☸️ Kubernetes (orquestração/HA), 📨 Messageria (filas/eventos/garantias).
6. **Leitura de referência:** Sam Newman, *Building Microservices* (citado na Aula 05) e a documentação da Microsoft sobre análise de domínio para microsserviços (Aula 02).

---

> **Síntese de uma frase:** microsserviços trocam a **simplicidade interna** do monólito (um banco, uma transação, uma chamada local) pela **autonomia de times e serviços** — e quase toda a complexidade nova (consistência eventual, Saga, resiliência, observabilidade, mTLS) é o preço de fazer colaborações que antes eram chamadas de função locais acontecerem agora **pela rede, que falha**.
