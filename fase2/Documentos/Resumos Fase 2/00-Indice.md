# 📚 Fase 2 — Arquitetura de Sistemas .NET · Trilha de Estudos

> Índice dos quatro resumos didáticos da Fase 2, organizados como uma **trilha única** de aprendizado cloud-native.
> Público-alvo: analista sênior (10+ anos de PowerBuilder / client-server) em transição para **.NET cloud-native**, nível iniciante-a-intermediário, que precisa **aprofundar os conceitos**.

---

## 🗺️ Os quatro pilares

| # | Documento | Tema | O que você sai sabendo |
|---|-----------|------|------------------------|
| 1 | [01-Docker.md](01-Docker.md) | **Docker / Contêineres** | Empacotar a aplicação de forma portátil e reproduzível: imagens, Dockerfile, multi-stage build .NET, Compose, segurança e ECS. |
| 2 | [02-Kubernetes.md](02-Kubernetes.md) | **Kubernetes / AKS** | Orquestrar contêineres em escala com modelo declarativo: Pods, Services, Deployments, Probes, HPA e a prática no Azure AKS com CI/CD. |
| 3 | [03-Microsservicos.md](03-Microsservicos.md) | **Microsserviços** | Quebrar o monólito com critério: DDD, dados distribuídos (Saga/CQRS/Outbox), resiliência (Circuit Breaker/Polly), observabilidade e segurança. |
| 4 | [04-Messageria.md](04-Messageria.md) | **Messageria / Event-Driven** | Conectar os serviços de forma assíncrona e desacoplada: EDA, RabbitMQ, MassTransit, Kafka e CDC com SQL Server. |

---

## 🧭 Como os quatro se conectam

Pense nos temas como **camadas que se empilham**, não como assuntos soltos:

```
                    ┌─────────────────────────────────────────────┐
   MESSAGERIA  ───▶ │  o "sistema nervoso": eventos entre serviços │  (RabbitMQ / Kafka)
                    └─────────────────────────────────────────────┘
                                      ▲
                    ┌─────────────────────────────────────────────┐
 MICROSSERVIÇOS ─▶  │  como decompor o domínio em serviços         │  (UsersAPI, CatalogAPI,
                    │  pequenos, autônomos e resilientes           │   PaymentsAPI, NotificationsAPI)
                    └─────────────────────────────────────────────┘
                                      ▲
                    ┌─────────────────────────────────────────────┐
   KUBERNETES   ─▶  │  como rodar e orquestrar esses serviços      │  (AKS, Deployments, HPA)
                    │  em escala, com autocura e escala automática │
                    └─────────────────────────────────────────────┘
                                      ▲
                    ┌─────────────────────────────────────────────┐
    DOCKER      ─▶  │  como empacotar cada serviço de forma        │  (imagens, contêineres)
                    │  portátil e reproduzível — a fundação        │
                    └─────────────────────────────────────────────┘
```

- **Docker** é a fundação: cada microsserviço vira uma **imagem**.
- **Kubernetes** pega essas imagens e as **orquestra** (réplicas, balanceamento, autocura, escala).
- **Microsserviços** é a **arquitetura** que decide como o sistema é fatiado e como cada parte fala com as outras.
- **Messageria** é o **tecido conjuntivo** que liga os serviços sem acoplá-los no tempo (comunicação assíncrona por eventos).

> 🏛️ **Ponte com o seu mundo:** no monólito PowerBuilder, tudo isso era uma coisa só — um `.exe` falando direto com um banco central por chamadas síncronas. A Fase 2 explode esse modelo em peças independentes e ensina as quatro disciplinas necessárias para que elas voltem a funcionar como um todo coeso, só que distribuído, escalável e resiliente.

---

## 📈 Ordem de leitura recomendada

A numeração já reflete a **progressão didática** — siga 1 → 2 → 3 → 4:

1. **Docker** primeiro: sem entender a unidade de empacotamento, o resto não assenta.
2. **Kubernetes** depois: orquestrar pressupõe que você já sabe o que é um contêiner.
3. **Microsserviços** em seguida: agora que você sabe empacotar e orquestrar, entra o *porquê* e o *como* decompor.
4. **Messageria** por último: é o que costura os microsserviços de forma desacoplada — faz mais sentido depois de entender a arquitetura.

> Cada documento é **autossuficiente** (pode ser lido isolado), mas as referências cruzadas assumem essa ordem. Se você já domina contêineres, pule direto para o tema que precisa.

---

## 🎯 O projeto-fio-condutor: FIAP Cloud Games

Os quatro resumos amarram os conceitos a um sistema de exemplo consistente — uma plataforma de jogos decomposta em microsserviços:

| Serviço | Responsabilidade |
|---------|------------------|
| `UsersAPI` | Cadastro, autenticação e perfil dos usuários |
| `CatalogAPI` | Catálogo de jogos |
| `PaymentsAPI` | Processamento de compras/pagamentos |
| `NotificationsAPI` | Notificações ao usuário |

Cenário recorrente nos documentos: a **compra de um jogo** — uma **Saga** (reservar → cobrar → liberar acesso, com compensação em caso de falha), com o evento `JogoComprado` trafegando pela messageria e o padrão **Outbox** garantindo entrega confiável. Esse fio liga Microsserviços (§ arquitetura e dados), Messageria (§ eventos e Saga) e Kubernetes (§ como cada API roda como Deployment).

---

## ✅ Checklist de domínio da Fase 2

Ao final da trilha, você deve conseguir:

- [ ] Escrever um `Dockerfile` multi-stage para uma API ASP.NET Core e subir o conjunto com Docker Compose.
- [ ] Explicar o modelo **declarativo** do Kubernetes e descrever um `Deployment` + `Service` + `Probe` + `HPA`.
- [ ] Provisionar/implantar em **AKS** e montar um pipeline **CI/CD** (build → push no registry → deploy).
- [ ] Decidir, com critério, **quando (e quando NÃO)** quebrar um monólito em microsserviços.
- [ ] Modelar dados distribuídos com **database-per-service**, **Saga**, **CQRS** e **Outbox**, sabendo o custo da consistência eventual.
- [ ] Aplicar **resiliência** (timeout, retry com backoff, Circuit Breaker via Polly, idempotência) e **observabilidade** (logs, métricas, traces).
- [ ] Publicar e consumir eventos com **RabbitMQ**/**MassTransit**, entender as semânticas de entrega e usar **Kafka**/**CDC** para streaming.

---

## 📂 Sobre os arquivos

| Arquivo | Linhas |
|---------|-------:|
| `01-Docker.md` | 579 |
| `02-Kubernetes.md` | 829 |
| `03-Microsservicos.md` | 544 |
| `04-Messageria.md` | 767 |

Cada documento segue a mesma estrutura: **visão geral → mapa das aulas → conteúdo aprofundado → 🏛️ Observações do Arquiteto (valor agregado) → ⚠️ Erros comuns → glossário → 🔗 Como isto se conecta → checklist e próximos passos.**

> Material produzido a partir das aulas da pasta `Aulas Fase 2/`, com conteúdo complementar sinalizado como observação do arquiteto, revisado tecnicamente.
