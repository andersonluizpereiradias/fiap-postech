# 4. CQRS e Event Sourcing

> Categoria 4 de 5 — Classificação dos resumos em PDF da pasta `resumos-fase-3`.
> Disciplina de origem: **CQRS com Event Sourcing** (Fase 3 do PósTech FIAP em Arquitetura de Sistemas .NET).

## Resumo funcional das aulas relacionadas

### Aula 1 — Do CRUD ao CQS
- **Objetivo:** questionar o paradigma **CRUD** (Create, Read, Update, Delete) como modelo único para todas as operações de um sistema.
- **Conceitos-chave:** **CQS** (Command Query Separation) — todo método é um **Command** (altera estado, não retorna dado) ou uma **Query** (retorna dado, não altera estado); motivação: leituras e escritas têm necessidades, volumes e formatos de dados muito diferentes (ex.: relatórios exigem modelos de leitura otimizados que um CRUD tradicional não entrega bem).
- **Aplicação prática:** primeiro passo mental para separar responsabilidades de leitura e escrita antes de adotar CQRS propriamente.

### Aula 2 — CQRS (Command Query Responsibility Segregation)
- **Objetivo:** levar o CQS ao nível arquitetural, com **modelos de dados separados** para escrita e leitura.
- **Conceitos-chave:** **Write Model** (otimizado para consistência e regras de negócio, geralmente normalizado) e **Read Model** (otimizado para consulta, geralmente desnormalizado/agregado, podendo usar um banco diferente, ex.: NoSQL); **Mediator Pattern** (desacopla quem envia um Command/Query de quem o processa, permitindo pipelines com validação, logging e cache); trade-off de consistência eventual entre os dois modelos.
- **Aplicação prática:** referência direta para decidir a persistência do projeto da fase (ex.: escrita em SQL/NoSQL transacional e leitura em uma projeção NoSQL desnormalizada para dashboards).

### Aula 3 — Event Sourcing
- **Objetivo:** apresentar uma forma alternativa de persistir estado: **guardar eventos, não o estado atual**.
- **Conceitos-chave:** cada mudança de estado é um **evento imutável e append-only**; o estado atual de um **agregado** é reconstruído "replay-ando" todos os seus eventos; **Event Store** (banco especializado, ex.: EventStoreDB) organizado em **Streams** (um por agregado); versionamento e **concorrência otimista** (grava um evento apenas se a versão esperada do stream ainda for válida); benefícios: **time travel** (reconstruir o estado em qualquer ponto do passado) e **auditoria completa** nativa (histórico = trilha de auditoria).
- **Conceitos avançados:** **Snapshots** (foto do estado em um ponto para evitar replay de milhares de eventos), **upcasting** (migração de esquema de eventos antigos para o formato atual) e **crypto-shredding** (técnica de "exclusão" de dados sensíveis em LGPD/GDPR sem violar a imutabilidade — descarta-se a chave de criptografia, não o evento).
- **Aplicação prática:** essencial para domínios que exigem auditoria rigorosa (financeiro, pedidos, jogos com histórico de partidas) — muito alinhado a um catálogo de jogos com histórico de compras/transações.

### Aula 4 — Saga Pattern
- **Objetivo:** coordenar transações que atravessam múltiplos serviços/agregados sem usar transações distribuídas tradicionais (ACID entre serviços).
- **Conceitos-chave:** duas abordagens — **coreografia** (cada serviço reage a eventos de forma descentralizada, sem um controlador central) e **orquestração** (um **Process Manager**/orquestrador central comanda cada etapa e decide o próximo passo); **transações compensatórias** (ações de "desfazer" quando uma etapa falha, já que não há rollback distribuído real); **idempotência** (processar o mesmo evento múltiplas vezes sem efeito colateral duplicado) como requisito obrigatório; necessidade de **observabilidade distribuída** (tracing) para depurar sagas complexas.
- **Aplicação prática:** padrão de referência para fluxos de negócio compostos (ex.: compra de jogo → pagamento → liberação de acesso → notificação), decidindo entre coreografia (mais simples, mais acoplamento implícito via eventos) ou orquestração (mais visibilidade e controle centralizado).

---

## Resumo funcional da categoria

Esta trilha evolui o raciocínio de persistência em quatro passos: primeiro separa leitura e escrita a nível de método (**CQS**), depois a nível arquitetural com modelos de dados distintos (**CQRS**), então propõe uma forma alternativa e auditável de guardar o estado através de uma sequência imutável de eventos (**Event Sourcing**), e por fim mostra como coordenar transações de negócio que cruzam múltiplos serviços sem transações distribuídas (**Saga Pattern**). Juntas, essas quatro peças formam um kit de padrões avançados de arquitetura de dados, especialmente relevante quando o projeto da fase precisa de auditoria, histórico completo de mudanças e composição de fluxos de negócio entre múltiplos serviços/bancos (incluindo bancos NoSQL, tratados na próxima categoria).
