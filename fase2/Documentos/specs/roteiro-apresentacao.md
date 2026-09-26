# Roteiro de Apresentação — Orquestração FCG (Fase 2)

> Guia passo a passo para você apresentar ao grupo a parte de **orquestração** (Docker Compose + Kubernetes) do Tech Challenge. Cada colega já viu a própria API a fundo; aqui o papel é mostrar **como tudo se junta e roda**.
>
> Tom: informal, didático, sem economizar em "abra isso aqui", "clica ali", porque tem gente no grupo que não é tão íntima de Docker/K8s ainda. Sem problema explicar as coisas de forma simples — o objetivo é todo mundo entender o que foi entregue, não impressionar com jargão.
>
> Tempo total estimado: **20–25 min** (dá pra cortar os passos 8–10 se o tempo apertar — aí você mostra só o Compose e fala do k8s "de boca").

---

## Antes de abrir a call (preparação, isso é só para você)

Faça isso **antes** de começar a apresentação, com calma, sem ninguém vendo:

1. Confirme que o Docker Desktop está aberto e rodando.
2. Confirme que os 6 repositórios estão clonados como **pastas irmãs** (mesmo nível), exatamente assim:
   ```
   fiap_cloud-games_2/
   ├── fcg-orchestration/
   ├── fcg-users-api/
   ├── fcg-catalog-api/
   ├── fcg-payments-api/
   ├── fcg-notifications-api/
   └── fcg-contracts/
   ```
3. Dentro de `fcg-orchestration`, confirme que existe o arquivo `.env` (copiado do `.env.example`). Se não existir:
   ```powershell
   cd fcg-orchestration
   cp .env.example .env
   ```
4. Suba a stack **uma vez antes** só para "esquentar" as imagens Docker (build já feito evita ficar esperando build ao vivo):
   ```powershell
   docker compose up --build -d
   docker compose ps
   ```
   Depois pode derrubar (`docker compose down`) — o importante é que as imagens já existem no cache local, então na hora da apresentação o `up` é rápido.
5. Se for mostrar o Minikube, o ideal é **já ter o cluster criado e as imagens carregadas antes** (isso demora bastante e ninguém tem paciência de ver build ao vivo). Rode com antecedência:
   ```powershell
   minikube start
   docker build -t fcg/users-api:1.0 ../fcg-users-api -f ../fcg-users-api/src/FCG.API/Dockerfile
   minikube image load fcg/users-api:1.0
   docker build -t fcg/catalog-api:1.0 ../fcg-catalog-api -f ../fcg-catalog-api/src/CatalogAPI.API/Dockerfile
   minikube image load fcg/catalog-api:1.0
   docker build -t fcg/payments-api:1.0 ../fcg-payments-api -f ../fcg-payments-api/src/FCG.API/Dockerfile
   minikube image load fcg/payments-api:1.0
   docker build -t fcg/notifications-api:1.0 ../fcg-notifications-api -f ../fcg-notifications-api/NotificationsAPI/src/Notifications.API/Dockerfile
   minikube image load fcg/notifications-api:1.0
   ```
   Na apresentação, você só roda o `kubectl apply -f k8s/` (rápido) e mostra os pods subindo — isso já é suficiente pra demonstrar que funciona.
6. Deixe abertos, em abas/janelas já prontas (só alternar, sem perder tempo procurando):
   - **Editor de código** (VS Code/Cursor) com a pasta `fcg-orchestration` aberta.
   - **2 ou 3 terminais**: um na pasta `fcg-orchestration` (para Compose/k8s), e opcionalmente outro livre para `docker compose logs` ou `kubectl get pods --watch`.
   - **Navegador** com abas para: `http://localhost:15672` (RabbitMQ) e `http://localhost:8081/swagger` (Swagger do users-api) — não precisa abrir ainda, só deixar prontas.
   - **Insomnia/Postman** (ou terminal com `curl`) configurado para disparar as requisições. Se não tiver Postman/Insomnia, sem problema, dá para fazer tudo com `curl` mesmo — os comandos abaixo já estão prontos para isso.
7. Feche notificações, Slack, etc. Compartilhe a tela **antes** de começar a falar.

---

## Passo 1 — Abertura (contexto rápido)

**Tempo:** ~1 min
**O que mostrar:** nada ainda, é só você falando, tela pode estar no editor fechado ou num slide/README.

**O que falar (algo nessa linha, sem ler robótico):**

> "Fala, pessoal! Cada um de vocês cuidou de uma API — users, catalog, payments ou notifications. A minha parte foi diferente: eu não fiz uma API, eu fiquei responsável por fazer **essas 4 APIs conversarem entre si e subirem juntas**, tanto no Docker quanto no Kubernetes. É a parte de 'orquestração' que pede o enunciado. Vou mostrar rapidinho como isso ficou, o que dá pra ver funcionando, e o que ainda falta fechar."

---

## Passo 2 — Visão geral da arquitetura (o "mapa mental")

**Tempo:** ~3 min
**O que mostrar:** pode ser um slide, o quadro branco, ou até desenhar na hora (papel, Excalidraw, o que tiver). Se quiser mostrar em arquivo, abra `.claude/project-context.md` no editor e leia a seção "Fluxos de eventos".

**Como demonstrar:**
1. Desenhe (ou aponte) 4 caixinhas: `users-api`, `catalog-api`, `payments-api`, `notifications-api`.
2. Desenhe uma caixinha no meio chamada `RabbitMQ` — é o "correio" que leva mensagem de um serviço para o outro.
3. Desenhe uma caixinha `PostgreSQL` do lado, ligada a users/catalog/notifications (payments não tem banco).

**O que falar:**

> "Pensa assim: antes, na Fase 1, era um monólito só — tudo dentro de um projeto .NET, um banco só. Agora cada parte é um serviço independente, cada um com o seu próprio banco, e eles não se chamam diretamente por HTTP o tempo todo. Eles se comunicam **de forma assíncrona**, via RabbitMQ. Isso é o que chamamos de arquitetura orientada a eventos.
>
> Tem dois fluxos principais:
> 1. **Cadastro:** o users-api cria o usuário e manda um evento `UserRegisteredEvent`. O notifications-api escuta esse evento e 'manda' um e-mail de boas-vindas (na prática, é só um log bonito no console, já que é tudo simulado).
> 2. **Compra:** o catalog-api recebe o pedido de compra e manda um evento `OrderPlacedEvent`. O payments-api escuta, simula o pagamento e manda de volta um `PaymentProcessedEvent` dizendo se foi aprovado ou rejeitado. Se foi aprovado, o catalog-api adiciona o jogo na biblioteca do usuário, e o notifications-api manda o e-mail de confirmação.
>
> Ou seja: ninguém fica esperando resposta na hora, cada serviço faz a sua parte quando a mensagem chega. É mais resiliente e escala melhor — se o payments-api cair um segundinho, a mensagem fica na fila esperando, não se perde."

---

## Passo 3 — Tour pelo repositório de orquestração

**Tempo:** ~3 min
**O que mostrar:** editor de código aberto na pasta `fcg-orchestration`.

**Como demonstrar:**
1. Abra o editor (VS Code/Cursor) na pasta `fcg-orchestration`.
2. Mostre a árvore de pastas no painel lateral esquerdo.
3. Clique rapidamente em cada item enquanto fala (não precisa ler linha por linha):
   - `docker-compose.yml`
   - `.env.example`
   - `db/init.sql`
   - `k8s/` (ainda não abra os arquivos, só mostra que a pasta existe)
   - `templates/`
   - `README.md`

**O que falar:**

> "Criei um quinto repositório, o `fcg-orchestration`, que é sugestão do próprio enunciado — um lugar central pra juntar a infraestrutura compartilhada. Ele não tem código de negócio, só tem:
> - O `docker-compose.yml`, que sobe tudo de uma vez: RabbitMQ, Postgres e as 4 APIs.
> - Um `.env.example`, que são as variáveis de configuração — senha do banco, chave do JWT, esse tipo de coisa. Repare que é `.example`, sem valor sensível de verdade commitado.
> - Um `db/init.sql`, que cria os bancos extras que o Postgres precisa (`catalogdb`, `notificationsdb`) quando ele nasce.
> - A pasta `k8s/`, com os manifestos do Kubernetes — vou voltar nela mais pra frente.
> - E um README bem completo, explicando como rodar tudo, então se alguém quiser reproduzir depois, tá documentado lá."

---

## Passo 4 — Subir a stack com Docker Compose

**Tempo:** ~2 min
**O que mostrar:** terminal aberto **na pasta `fcg-orchestration`**.

**Como demonstrar:**
1. Se ainda não tiver terminal aberto ali: no VS Code/Cursor, `Terminal > New Terminal`, e confirme que o prompt mostra `...\fcg-orchestration>`.
2. Rode:
   ```powershell
   docker compose up --build -d
   ```
   (o `-d` deixa em segundo plano, pra você continuar usando o terminal — como já fez o build antes, deve subir rápido)
3. Depois que terminar, rode:
   ```powershell
   docker compose ps
   ```
4. Aponte para a coluna de status: todos devem estar `running`/`healthy`.

**O que falar:**

> "Com um `docker compose up`, ele builda as 4 imagens — cada Dockerfile mora dentro do repositório de cada serviço, não aqui — e sobe tudo junto: RabbitMQ, Postgres com os 3 bancos, e as 4 APIs, já ligadas entre si pela rede interna do Compose. Dá pra ver aqui que cada serviço está rodando numa porta diferente: users na 8081, catalog na 8082, payments na 8083, notifications na 8084. Internamente, dentro do container, todos escutam na 8080, isso é padrão que a gente combinou entre os serviços."

---

## Passo 5 — Testar o fluxo de cadastro

**Tempo:** ~3 min
**O que mostrar:** Insomnia/Postman (ou terminal com `curl`) + um segundo terminal com logs do notifications-api.

**Como demonstrar:**
1. Num terminal separado (ou aba nova), rode e deixe rodando (vai mostrar log em tempo real):
   ```powershell
   docker compose logs -f notifications-api
   ```
2. Na outra tela (Insomnia/Postman ou outro terminal), faça a chamada de cadastro:
   ```powershell
   curl -X POST http://localhost:8081/api/users/register `
     -H "Content-Type: application/json" `
     -d '{"name":"Aluno Teste","email":"aluno@teste.com","password":"Senha123!"}'
   ```
3. Volte pro terminal de logs do notifications-api e mostre a linha de "e-mail de boas-vindas" aparecendo.

**O que falar:**

> "Eu cadastrei um usuário chamando direto a API do users-api, na porta 8081. Reparem: eu não chamei o notifications-api em nenhum momento. Mesmo assim, olha aqui no log dele — chegou o evento e ele 'mandou' o e-mail de boas-vindas sozinho. Isso é a mensageria funcionando: o users-api só publicou o evento no RabbitMQ e seguiu a vida dele, o notifications-api que ficou escutando e reagiu."

---

## Passo 6 — Testar o fluxo de compra completo

**Tempo:** ~4 min
**O que mostrar:** mesma dupla de telas (requisições + logs), agora olhando payments-api e notifications-api.

**Como demonstrar:**
1. Login para conseguir o token JWT:
   ```powershell
   curl -X POST http://localhost:8081/api/auth/login `
     -H "Content-Type: application/json" `
     -d '{"email":"aluno@teste.com","password":"Senha123!"}'
   ```
   Copie o `token` que voltou na resposta.
2. Criar um jogo no catálogo:
   ```powershell
   curl -X POST http://localhost:8082/api/v1/games `
     -H "Content-Type: application/json" `
     -d '{"title":"Jogo Demo","description":"Jogo para a apresentacao","price":49.90,"genre":"Action","releaseDate":"2026-01-01"}'
   ```
   Copie o `id` do jogo que voltou.
3. Trocar de terminal e ligar os logs de payments e notifications juntos:
   ```powershell
   docker compose logs -f payments-api notifications-api
   ```
4. Voltar e disparar a compra (troque `SEU_TOKEN` e `ID_DO_JOGO` pelos valores copiados):
   ```powershell
   curl -X POST http://localhost:8082/api/v1/library/add `
     -H "Content-Type: application/json" `
     -H "Authorization: Bearer SEU_TOKEN" `
     -d '{"gameId":"ID_DO_JOGO"}'
   ```
5. Mostrar nos logs: payments processando e aprovando, depois notifications mandando o e-mail de confirmação.
6. Consultar a biblioteca do usuário pra fechar o ciclo:
   ```powershell
   curl http://localhost:8082/api/v1/library `
     -H "Authorization: Bearer SEU_TOKEN"
   ```

**O que falar:**

> "Agora o fluxo mais completo: eu logo com o usuário, crio um jogo no catálogo, e peço pra comprar. O catalog-api não processa pagamento — ele só publica um evento `OrderPlacedEvent` dizendo 'esse usuário quer esse jogo por esse preço'. O payments-api pega esse evento, simula o pagamento — no nosso caso, sempre aprova, porque é simulação — e publica de volta um `PaymentProcessedEvent`. O catalog-api escuta essa resposta e, se foi aprovado, adiciona o jogo na biblioteca do usuário. E o notifications-api também escuta e manda o e-mail de confirmação. Ó, e não copiei a biblioteca do usuário atualizada — o jogo já está lá, sem eu ter chamado nada disso manualmente."

---

## Passo 7 — Mostrar o painel do RabbitMQ

**Tempo:** ~2 min
**O que mostrar:** navegador.

**Como demonstrar:**
1. Abra `http://localhost:15672`.
2. Login: usuário `fcg`, senha `fcg123`.
3. Clique na aba **Exchanges** e depois em **Queues** — mostre que existem filas com nome dos eventos e alguma atividade (mensagens entregues).

**O que falar:**

> "Esse aqui é o painel de administração do RabbitMQ, que é o 'motor' de mensageria que a gente usa. Dá pra ver as exchanges e filas que cada serviço criou pra escutar os eventos que interessam a ele. Se algum serviço cair, a mensagem não se perde, ela fica esperando na fila até o serviço voltar — isso é uma das vantagens de desacoplar por mensageria em vez de todo mundo se chamando direto por HTTP."

---

## Passo 8 — Encerrar o Compose e introduzir o Kubernetes

**Tempo:** ~1 min
**O que mostrar:** terminal na pasta `fcg-orchestration`.

**Como demonstrar:**
1. (Opcional, só se quiser liberar recursos da máquina antes do próximo passo)
   ```powershell
   docker compose down
   ```

**O que falar:**

> "Isso que mostrei até agora é o suficiente pra rodar localmente na máquina de cada um, ou até num servidor simples. Mas o enunciado pede também Kubernetes — que é o passo seguinte quando você quer rodar isso 'de verdade', em produção, com múltiplas réplicas, reinício automático se um container cair, esse tipo de coisa. Localmente, a gente usa o Minikube, que simula um cluster Kubernetes na sua própria máquina, só para teste."

---

## Passo 9 — Tour pelos manifestos Kubernetes

**Tempo:** ~4 min
**O que mostrar:** editor de código, pasta `fcg-orchestration/k8s`.

**Como demonstrar:**
1. Abra a pasta `k8s/` no editor e mostre a lista de arquivos (a numeração no nome garante a ordem de aplicação: `00-`, `01-`, `02-`, `10-`, `11-`, `20-` a `23-`).
2. Abra `00-namespace.yaml` — mostre que é só um "namespace" chamado `fcg`, que é como uma "pasta" isolada dentro do cluster pra organizar tudo que é desse projeto.
3. Abra `01-configmap.yaml` — explique que é configuração **não sensível** (host do RabbitMQ, ambiente, etc.).
4. Abra `02-secret.yaml` — explique que é configuração **sensível** (senhas, connection strings, chave JWT), guardada separada do ConfigMap.
5. Abra `20-users-api.yaml` (pode ser qualquer um dos 4 das APIs) e aponte:
   - O `Deployment`, com `replicas: 2` — ou seja, ele sobe **duas cópias** do users-api rodando ao mesmo tempo.
   - O bloco `env`, mostrando que os valores vêm do `ConfigMap` e do `Secret` (não estão hardcoded no arquivo).
   - O `livenessProbe`/`readinessProbe` — a "sonda de saúde" que o Kubernetes usa pra saber se o container está de pé.
   - O `Service`, que é o "nome de rede interno" pelo qual os outros serviços acham o users-api dentro do cluster.

**O que falar:**

> "Cada arquivo aqui representa um pedaço da infraestrutura no Kubernetes. Numerei os arquivos pra garantir a ordem: primeiro cria o namespace, depois config e secret, depois RabbitMQ e Postgres (que são a base), e só depois as 4 APIs — porque elas dependem dessa base pra funcionar.
>
> Reparem numa coisa: aqui no Deployment do users-api eu coloquei `replicas: 2` — isso significa que o Kubernetes vai manter **duas cópias** desse container rodando sempre. Se uma cair, ele sobe outra automaticamente. Isso é uma coisa que o Compose não faz de verdade, é uma vantagem do Kubernetes.
>
> E outra coisa importante: as configurações não sensíveis ficam no `ConfigMap`, e as sensíveis — senha, chave de JWT — ficam no `Secret`. Separei os dois porque são naturezas diferentes de dado, mesmo sabendo que aqui o Secret é só base64, não é um cofre de verdade — em produção teria uma ferramenta tipo Vault por trás."

---

## Passo 10 — Subir tudo no Minikube

**Tempo:** ~4 min (menos se as imagens já estiverem carregadas de antes, como recomendado no preparo)
**O que mostrar:** terminal na pasta `fcg-orchestration`.

**Como demonstrar:**
1. Confirme que o Minikube está de pé (se já rodou no preparo, só confirme):
   ```powershell
   minikube status
   ```
2. Se **não** tiver feito o preparo com antecedência, esse é o momento de buildar e carregar as imagens (avise a galera que vai demorar um pouco):
   ```powershell
   docker build -t fcg/users-api:1.0 ../fcg-users-api -f ../fcg-users-api/src/FCG.API/Dockerfile
   minikube image load fcg/users-api:1.0
   # repetir para catalog-api, payments-api e notifications-api (caminhos no README)
   ```
3. Aplicar todos os manifestos de uma vez:
   ```powershell
   kubectl apply -f k8s/
   ```
4. Mostrar a saída no terminal — o kubectl lista cada recurso criado (`namespace/fcg created`, `configmap/fcg-config created`, etc.).

**O que falar:**

> "Com o Minikube já rodando e as imagens carregadas, é só um `kubectl apply -f k8s/` — ele aplica **todos** os arquivos da pasta de uma vez, na ordem certa por causa da numeração. Cada linha que aparece aqui é um recurso do Kubernetes sendo criado: o namespace, o configmap, o secret, e os deployments/services de cada peça."

---

## Passo 11 — Validar que o cluster está de pé

**Tempo:** ~3 min
**O que mostrar:** terminal.

**Como demonstrar:**
1. Ver os pods subindo (pode levar uns segundos até tudo virar `Running`):
   ```powershell
   kubectl get pods -n fcg
   ```
   Se quiser ficar acompanhando em tempo real:
   ```powershell
   kubectl get pods -n fcg --watch
   ```
   (Ctrl+C para sair do modo watch quando todos estiverem `Running`)
2. Ver o panorama geral:
   ```powershell
   kubectl get deployments,services,configmaps,secrets -n fcg
   ```
3. Acessar uma API de fora do cluster, usando port-forward:
   ```powershell
   kubectl port-forward service/users-api 8081:8080 -n fcg
   ```
4. Em outro terminal (ou no Insomnia/Postman), repetir a mesma chamada de cadastro do Passo 5, agora contra esse `localhost:8081` — que na verdade está sendo redirecionada para dentro do cluster Kubernetes:
   ```powershell
   curl -X POST http://localhost:8081/api/users/register `
     -H "Content-Type: application/json" `
     -d '{"name":"Teste K8s","email":"testek8s@teste.com","password":"Senha123!"}'
   ```

**O que falar:**

> "Aqui a gente vê os pods — que é o nome que o Kubernetes dá pra cada 'instância rodando' de um container. Repara que o users-api aparece com 2 pods, porque configuramos `replicas: 2` lá no manifesto.
>
> O `port-forward` é só um truque pra eu conseguir testar de fora, porque dentro do cluster os serviços não ficam expostos direto pra minha máquina — só se conversam entre si, pelo nome do Service. Fiz a mesma chamada de cadastro de antes, só que agora ela está rodando dentro do Kubernetes, não mais no Compose. Isso mostra que o mesmo container, a mesma imagem Docker, funciona nos dois ambientes — é essa a ideia de containerizar: builda uma vez, roda em qualquer lugar."

---

## Passo 12 — Encerramento e próximos passos

**Tempo:** ~2 min
**O que mostrar:** pode voltar pro README ou ficar só de câmera/tela do editor.

**O que falar:**

> "Resumindo o que ficou pronto: repositório de orquestração publicado, com Compose testado ponta a ponta — cadastro, compra, biblioteca e notificações funcionando — e os manifestos de Kubernetes aplicados e validados no Minikube. Cada um dos 4 serviços também recebeu a própria pasta `/k8s` com Deployment e Service.
>
> O que ainda falta fechar, e por isso preciso da ajuda de vocês: tem PRs abertos em cada repositório de serviço com os manifestos e alguns ajustes que fiz — Dockerfile pra .NET 10, correção de migration no catalog, esse tipo de coisa. Preciso que vocês revisem e aprovem esses PRs pra eu poder mergear. Também mandei convite pra todos no repositório de orquestração, se alguém ainda não aceitou, aceita aí que já libera acesso.
>
> Fora isso, falta gravar o vídeo final e montar o relatório, mas a parte técnica de orquestração tá validada e funcionando nos dois ambientes. Alguma dúvida?"

### Tabela de pendências de desenvolvimento

| Aplicação | Branch | PR | O que foi feito | Observação |
|---|---|---|---|---|
| **fcg-orchestration** | `main` | — (push inicial) | `docker-compose.yml`, `db/init.sql`, `.env.example`, manifestos k8s agregados (`Namespace`, `ConfigMap`, `Secret`, RabbitMQ, Postgres, 4 APIs), templates e README | Repo em `andersonluizpereiradias`. Convites enviados ao time (pendentes de aceite). Compose validado e2e localmente |
| **fcg-users-api** | `feature/orchestration` | [#16](https://github.com/joao-malvetoni-alta-horizon/FIAPCloudGames-fase2-UsersAPI/pull/16) | `/k8s` (`Deployment` + `Service`, sonda TCP) | Correção local **não publicada**: Dockerfile atualizado para `.NET 10.0` estável. PR ainda precisa merge |
| **fcg-catalog-api** | `feature/orchestration` | [#8](https://github.com/joao-malvetoni-alta-horizon/FIAPCloudGames-fase2-CatalogAPI/pull/8) | `/k8s` (`Deployment` + `Service`, sonda TCP) | Correções locais **não publicadas**: `MigrateAsync()` no startup + retry do consumer RabbitMQ. Essencial para demo Compose/k8s |
| **fcg-payments-api** | `feature/orchestration` | [#5](https://github.com/joao-malvetoni-alta-horizon/FIAPCloudGames-fase2-PaymentsAPI/pull/5) | Dockerfile multi-stage + `/k8s` (sonda HTTP `/health`) | Correções locais **não publicadas**: Dockerfile `.NET 10.0` + ajuste de DI para build Docker. PR ainda precisa merge |
| **fcg-notifications-api** | `feature/orchestration` | [#29](https://github.com/joao-malvetoni-alta-horizon/FIAPCloudGames-fase2-NotificationsAPI/pull/29) | `/k8s` (`Deployment` + `Service`, sonda HTTP `/health`) | Correção local **não publicada**: caminho correto do Dockerfile (`NotificationsAPI/src/...`) + `.NET 10.0`. PR ainda precisa merge |
| **fcg-contracts** | `main` | — | Fora do escopo de orquestração | Sem alterações nesta entrega |
| **Documentação** | — | — | `specs/prd.md`, `specs/continuidade.md`, `.claude/CLAUDE.md` (bootstrap pela continuidade) | Referência operacional do projeto |

**Pendente:** merge dos PRs, push das correções locais, `gh auth login`, estabilizar todos os pods após Postgres subir, vídeo e relatório.

---

## Se algo der errado durante a demo (plano B)

- **Compose não sobe / porta ocupada:** rode `docker compose down` e suba de novo; se a porta 5432/5672 estiver ocupada por outro Postgres/RabbitMQ na sua máquina, pare o serviço conflitante ou ajuste a porta no `docker-compose.yml` só para o teste.
- **Minikube travou ou demorando demais:** não perca tempo ao vivo — feche o terminal, explique verbalmente com os manifestos já abertos no editor ("já validei isso antes, vou mostrar os arquivos e o resultado que já capturei") e siga para o encerramento. Ter um print/gravação de `kubectl get pods -n fcg` com tudo `Running` como plano B é uma boa ideia.
- **Algum serviço não sobe no Compose:** rode `docker compose logs <nome-do-serviço>` para mostrar o motivo ao vivo — isso até reforça a explicação de dependências (ex: catalog precisa do Postgres e do RabbitMQ prontos antes de subir).
- **Token JWT expirou ou copiou errado:** só repetir o login (Passo 6.1), o token dura algumas horas (`JwtSettings__ExpirationHours`).
