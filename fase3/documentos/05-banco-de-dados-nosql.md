# 5. Banco de Dados NoSQL

> Categoria 5 de 5 — Classificação dos resumos em PDF da pasta `resumos-fase-3`.
> Disciplina de origem: **Banco de Dados NoSQL** (MongoDB, Redis, DynamoDB) — Fase 3 do PósTech FIAP em Arquitetura de Sistemas .NET.

## Bloco 1 — Fundamentos NoSQL

### Aula 1 — Introdução ao NoSQL: ACID, BASE e Teorema CAP
- **Objetivo:** justificar por que bancos relacionais tradicionais nem sempre atendem sistemas distribuídos de alta escala, e apresentar os fundamentos teóricos do NoSQL.
- **Conceitos-chave:** **ACID** (Atomicidade, Consistência, Isolamento, Durabilidade — modelo forte dos bancos relacionais) vs. **BASE** (Basically Available, Soft state, Eventually consistent — modelo mais flexível do NoSQL); **Teorema CAP** (Consistency, Availability, Partition Tolerance — em um sistema distribuído só é possível garantir 2 das 3 propriedades simultaneamente durante uma partição de rede).
- **Tipos de banco NoSQL:** chave-valor (Redis, DynamoDB), documentos (MongoDB), colunar/column-family (Cassandra), grafos (Neo4j) — cada um otimizado para um padrão de acesso diferente.
- **Conceito de mercado:** **Polyglot Persistence** — usar múltiplos bancos (relacional + diferentes NoSQL) no mesmo sistema, cada um para o que faz melhor.

## Bloco 2 — MongoDB (Documentos)

### Aula 2 — Introdução ao MongoDB
- **Objetivo:** apresentar o MongoDB como banco orientado a documentos.
- **Conceitos-chave:** formato **BSON** (binário, extensão do JSON); hierarquia Database → Collection → Document; cada documento tem um `_id` único; modelagem de relacionamentos via **documentos embutidos** (embedded, para dados fortemente acoplados e lidos juntos) ou **referenciados** (referenced, similar a foreign key, para dados grandes/reutilizados).

### Aula 3 — Operações CRUD no MongoDB
- **Objetivo:** praticar as operações básicas de manipulação de dados.
- **Conceitos-chave:** `insertOne`/`insertMany`, `find`/`findOne` com operadores de consulta (`$gt`, `$lt`, `$in` etc.), `updateOne`/`updateMany` (`$set`, `$inc`), `deleteOne`/`deleteMany`.

### Aula 4 — Indexação e Agregações no MongoDB
- **Objetivo:** otimizar performance de consulta e construir relatórios agregados.
- **Conceitos-chave:** tipos de índice (simples, composto, único, textual, hashed, **TTL** — expiração automática de documentos); **Aggregation Framework** (pipeline de estágios: `$match`, `$group`, `$unwind`, `$sum`, `$project` etc.) para relatórios que um `find` simples não resolveria.

### Aula 5 — Replicação e Sharding no MongoDB
- **Objetivo:** entender como o MongoDB escala horizontalmente e garante alta disponibilidade.
- **Conceitos-chave:** **Replica Set** (nó primário para escrita, nós secundários para leitura/failover, e um **arbiter** opcional só para votação de eleição, sem armazenar dados); **Sharding** (particionamento horizontal dos dados entre múltiplos servidores com base em uma **shard key**, permitindo escalar além da capacidade de uma única máquina).

## Bloco 3 — Redis (Chave-Valor em Memória)

### Aula 6 — Introdução ao Redis e Estruturas de Dados
- **Objetivo:** apresentar o Redis como banco chave-valor em memória, focado em velocidade.
- **Conceitos-chave:** estruturas de dados nativas — **Strings**, **Hashes** (objetos com múltiplos campos), **Lists** (filas/pilhas ordenadas), **Sets** (coleções sem duplicatas) e **Sorted Sets** (sets ordenados por score, úteis para rankings/leaderboards).

### Aula 7 — Redis como Cache Distribuído
- **Objetivo:** usar o Redis para reduzir carga em bancos de dados primários e acelerar leituras frequentes.
- **Conceitos-chave:** padrões de cache — **Cache-Aside** (aplicação lê do cache, e só consulta o banco e popula o cache em caso de miss), **Write-Through** (toda escrita vai para o cache e o banco simultaneamente) e **Write-Behind** (escrita vai primeiro para o cache e é persistida no banco de forma assíncrona/em lote).

### Aula 8 — Persistência e Locks Distribuídos no Redis
- **Objetivo:** entender como o Redis (por padrão em memória) pode persistir dados e coordenar concorrência entre múltiplas instâncias.
- **Conceitos-chave:** **RDB** (snapshot periódico do dataset em disco) e **AOF** (log de todas as operações de escrita, mais durável porém mais pesado); **Redlock** (algoritmo de lock distribuído do Redis para coordenar acesso exclusivo a um recurso entre múltiplos clientes/instâncias); **Pub/Sub** (mensageria simples entre publishers e subscribers de um canal).

## Bloco 4 — DynamoDB (Chave-Valor/Documentos Gerenciado na AWS)

### Aula 9 — Introdução ao DynamoDB
- **Objetivo:** apresentar o DynamoDB como banco NoSQL **totalmente gerenciado** pela AWS, com foco em performance consistente e escala automática.
- **Conceitos-chave:** modelo chave-valor e de documentos; **Partition Key** (define em qual partição física o item fica) e **Sort Key** opcional (permite múltiplos itens por partition key, ordenados); escalabilidade horizontal automática e alta disponibilidade **Multi-AZ** nativa (sem configuração manual de replicação, diferente do MongoDB).

### Aula 10 — Índices Secundários e Modelagem no DynamoDB
- **Objetivo:** ir além da chave primária para suportar múltiplos padrões de consulta sobre a mesma tabela.
- **Conceitos-chave:** **GSI** (Global Secondary Index — nova partition/sort key independente da tabela original, pode ser criado a qualquer momento) vs. **LSI** (Local Secondary Index — mesma partition key da tabela, sort key diferente, deve ser definido na criação da tabela); **Single Table Design** (modelar múltiplas entidades em uma única tabela, padrão idiomático do DynamoDB) vs. **Multiple Tables Design** (mais próximo do modelo relacional, mais simples de entender porém menos eficiente em joins que não existem no DynamoDB).

### Aula 11 — Capacidade, Hotspots e Transações no DynamoDB
- **Objetivo:** dimensionar corretamente a capacidade da tabela e evitar armadilhas de performance.
- **Conceitos-chave:** **WCU** (Write Capacity Unit) e **RCU** (Read Capacity Unit) como unidades de cobrança/capacidade; **Hotspots** (quando uma partition key concentra desproporcionalmente as requisições, criando um gargalo — mitigado com chaves mais distribuídas); **transactions** (operações atômicas multi-item, similar a transações SQL); **leituras consistentes** — **strong consistency** (sempre reflete a escrita mais recente, mais lenta) vs. **eventual consistency** (pode retornar dado levemente desatualizado, porém mais rápida e mais barata).

### Aula 12 — Comparativo entre Bancos NoSQL
- **Objetivo:** consolidar critérios de decisão entre MongoDB, Redis e DynamoDB (e bancos relacionais) para um projeto real.
- **Conceitos-chave:** MongoDB para modelagem flexível de documentos ricos e consultas ad-hoc; Redis para cache/sessão/rankings de baixíssima latência; DynamoDB para cargas previsíveis, gerenciadas e com escala automática na AWS; reforço do conceito de **Polyglot Persistence** — combinar mais de um desses bancos conforme o padrão de acesso de cada parte do sistema.

---

## Resumo funcional da categoria

Esta trilha cobre a camada de **persistência não-relacional** do projeto: parte da teoria (**ACID vs. BASE**, **Teorema CAP**, tipos de NoSQL) e avança por três bancos com propósitos complementares — **MongoDB** (documentos flexíveis, agregações, replicação/sharding), **Redis** (cache distribuído em memória, estruturas de dados especializadas, locks) e **DynamoDB** (chave-valor totalmente gerenciado na AWS, com índices secundários e modelagem *single-table*). O fio condutor é a **Polyglot Persistence**: escolher o banco certo para cada padrão de acesso, em vez de forçar um único modelo relacional para tudo — decisão que se conecta diretamente ao **Write/Read Model** do CQRS (categoria anterior) e à necessidade de escalabilidade tratada na categoria de Arquitetura de Software.
