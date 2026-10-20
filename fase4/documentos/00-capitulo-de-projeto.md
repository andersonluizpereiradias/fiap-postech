# 0. Capítulo de Projeto - Fase 4 (Orquestração de Containers e Elasticsearch)

> **Comparação com o "TC NETT - Fase 4.pdf": DIFERENTE.** Os dois documentos não compartilham nenhum trecho de texto.
> - **PDF principal** ("NETT - Capitulo de Projeto - Fase 4", 4 páginas, das quais só 2 têm conteúdo): é uma **carta de boas-vindas** ("Welcome to Arquitetura de Sistemas .NET") que apresenta as disciplinas da fase (Azure DevOps, AWS, NoSQL, GitHub Actions e Elasticsearch) e cita o Projeto Integrador em um único parágrafo.
> - **TC NETT - Fase 4.pdf** (7 páginas, 5 com conteúdo): é o **enunciado do Tech Challenge**, com o problema, o desafio, os requisitos técnicos obrigatórios e desejáveis, os entregáveis e o peso de 90% na nota.
> - **Diferenças objetivas:**
>   1. O PDF principal não tem nenhum requisito, critério de avaliação, entregável, prazo nem peso de nota.
>   2. O PDF principal descreve o projeto só como "implantar sua arquitetura na nuvem, utilizando pipelines automatizados e integrando uma solução de busca de alta performance". Ele não menciona NoSQL, cache, segredos nem o vídeo.
>   3. O PDF principal cita a disciplina **NoSQL** (MongoDB, Redis, DynamoDB) e serviços que o TC não exige: Azure Boards/Repos, ACI, Azure Container Apps, ECS, RDS, CloudWatch, Lambda e runners on-premises.
>   4. O TC exige itens que o PDF principal não cita: Kubernetes gerenciado (EKS/AKS/GKE/OKE), Load Balancer/Ingress, `/search` com Fuzzy Search, Rolling Update, Zero Hardcoded Credentials e o vídeo de até 25 min.
>
> **Como este arquivo está organizado:** a Parte 1 reproduz o PDF principal por completo. A Parte 2 reproduz o enunciado do TC, que é a fonte de todos os requisitos, do checklist e do mapa de disciplinas.

---

# Parte 1 - Welcome to Arquitetura de Sistemas .NET (PDF principal)

## Fase 4 - Orquestração de Containers e Elasticsearch

Olá, estudante!

Seja muito bem-vindo(a) à **Fase 4** da PósTech em **Arquitetura de Sistemas .NET**! Na fase passada, focamos intensamente no desenho da aplicação, nos dados e na inteligência do software. Agora, é hora de tirar essa arquitetura do papel e levá-la para o mundo real. Um(a) Arquiteto(a) de Soluções completo(a) não apenas desenha o sistema, mas define onde ele vai rodar e como ele será entregue com qualidade e automação.

Nesta fase, expandiremos seus horizontes para dominar as duas maiores nuvens do mercado e as ferramentas de automação mais utilizadas, além de adicionar uma poderosa engine de busca ao seu repertório e compreender totalmente o mundo de NoSQL.

### Azure DevOps

Começaremos explorando o ecossistema Microsoft com Azure DevOps. Você verá que ele é muito mais que uma ferramenta de CI/CD: é uma suíte completa de gestão. Vamos desde o planejamento com Azure Boards e gestão de código com Azure Repos até a construção de esteiras robustas de entrega contínua com Azure Pipelines (incluindo multi-stage). O foco aqui é forte em modernização: você aprenderá a fazer o deploy de containers utilizando serviços como ACR (Registry), ACI (Instances) e as modernas Azure Container Apps.

> **💡 Complemento:** para o Tech Challenge, o que se aproveita diretamente desta disciplina são o **Azure Pipelines** (multi-stage: build/test → imagem → push → deploy) e o **ACR**. ACI e Azure Container Apps são conteúdo de aula, mas **não** atendem ao requisito de orquestração do TC, que exige Kubernetes gerenciado (AKS, se a nuvem for Azure).

### AWS

Mas um(a) arquiteto(a) moderno(a) precisa ser versátil. Por isso, dedicaremos um módulo robusto à AWS. Aqui, você vai aprofundar conhecimentos fundamentais de infraestrutura como IAM (Identidade) e VPC (Rede), além de avançar para serviços gerenciados. Vamos revisitar a orquestração de containers sob a ótica da Amazon com ECS e EKS, gerenciar dados com RDS, monitorar com CloudWatch e explorar o poder da computação serverless com Lambda Functions.

> **💡 Complemento:** no TC, a orquestração precisa ser **EKS**. O ECS é visto nas aulas, mas não é Kubernetes. O IAM entra nas permissões da pipeline (de preferência via OIDC) e dos nós/pods, o ECR é o registry e a VPC é a rede do cluster. RDS, CloudWatch e Lambda não são exigidos pelo TC, mas podem compor a solução (por exemplo, o banco relacional principal no RDS).

### NoSQL

No mundo dos dados, a disciplina de NoSQL abrirá um novo leque de possibilidades. Você aprenderá quando e como utilizar bancos não-relacionais, mergulhando no MongoDB (orientado a documentos), Redis (para cache e alta performance) e DynamoDB (chave-valor na nuvem), entendendo as nuances de modelagem e persistência de cada um.

> **💡 Complemento:** esta disciplina sustenta dois requisitos **obrigatórios** do TC: NoSQL (MongoDB ou DynamoDB, com driver oficial .NET) e cache distribuído (Redis). Não há PDF de aula de NoSQL na pasta local `Fase4` (só `aws`, `azure-devops`, `elasticsearch` e `github-actions`), e a lista de arquivos de estudo planejada também não tem um arquivo dedicado. Vale baixar esse material do portal.

### GitHub Actions

Ainda no pilar de automação, traremos o GitHub Actions, a ferramenta que tem redefinido o CI/CD no mercado. Você aprenderá a criar workflows flexíveis, configurar runners em ambientes on-premises e automatizar a construção e a publicação de imagens Docker, garantindo que você tenha opções de ferramentas para qualquer cenário de projeto.

> **💡 Complemento:** é a alternativa ao Azure DevOps para o pipeline do TC. Basta escolher **uma** das duas ferramentas. Runners on-premises (self-hosted) são opcionais: os runners hospedados pelo GitHub bastam para build, push e deploy no cluster.

### Elasticsearch

Por fim, para resolver problemas de performance em consultas complexas nas quais bancos tradicionais não dão conta, mergulharemos no Elasticsearch. Você aprenderá a configurar e integrar essa poderosa engine de busca com suas aplicações .NET, dominando a indexação de documentos e a execução de consultas Full-Text avançadas.

> **💡 Complemento:** no TC, isso vira o endpoint `/search` do CatalogAPI, com Fuzzy Search e ordenação por relevância, usando um serviço **gerenciado** (Amazon OpenSearch, Elastic Cloud ou equivalente) e indexação a cada criação ou edição de jogo.

### Projeto Integrador

O Projeto Integrador desta fase será o teste definitivo da sua capacidade de entrega: você deverá implantar sua arquitetura na nuvem, utilizando pipelines automatizados e integrando uma solução de busca de alta performance.

Esta é a fase que conecta o seu código à infraestrutura global. Vamos construir essas pontes juntos!

> **💡 Complemento:** este parágrafo é só um resumo. Os requisitos que de fato serão avaliados estão no enunciado do Tech Challenge, reproduzido na Parte 2.

---

# Parte 2 - Enunciado do Tech Challenge (TC NETT - Fase 4.pdf)

## Tech Challenge

O Tech Challenge é o projeto da fase e reúne os conhecimentos obtidos em todas as disciplinas dela. A princípio, é uma atividade em grupo. Fique atento ao prazo de entrega: a atividade é obrigatória e vale **90% da nota de todas as disciplinas da fase**.

> **💡 Complemento:** como o projeto vale 90% da nota de **todas** as disciplinas, perder o prazo compromete a fase inteira. O entregável que vai para avaliação é o **Relatório de Entrega** (ver adiante), com os links. Confira se repositórios e vídeo estão acessíveis a quem não é membro do grupo (repositório público ou com acesso concedido; vídeo "não listado" em vez de "privado").

## O problema

A FIAP Cloud Games (FCG) já é uma plataforma funcional, distribuída e observável. Mas, para chegar a um nível profissional e suportar crescimento global, a infraestrutura precisa superar três gargalos críticos:

1. **Ambiente de Produção Gerenciado:** garantir o uso do Kubernetes na Cloud em favor da resiliência e da segurança.
2. **Automação de Entrega (CI/CD):** eliminar processos manuais lentos e suscetíveis a erros.
3. **Performance e Latência:** com o aumento do tráfego, depender só de bancos relacionais e de buscas simples virou um impeditivo. É preciso otimizar a persistência de dados e a velocidade de resposta aos usuários.

## O desafio

Esta fase foca em automação, performance e portabilidade. O desafio consiste em:

- **Utilizar a mesma Infraestrutura Cloud:** na fase anterior, subimos o cluster na Cloud e a aplicação rodando no Kubernetes gerenciado da nuvem de sua preferência (AWS EKS, Azure AKS, Google GKE ou Oracle OKE).
- **Pipeline de CI/CD Multi-Cloud:** automatizar o ciclo de vida da aplicação com GitHub Actions ou Azure DevOps.
- **Persistência Poliglota (NoSQL):** implementar MongoDB ou DynamoDB para lidar com dados não estruturados ou de alta escala.
- **Otimização com Cache:** implementar uma camada de cache (ex.: Redis) para reduzir a latência e a carga nos bancos de dados.
- **Busca Avançada:** integrar Elasticsearch (ou OpenSearch) para buscas rápidas e tolerantes a erros.

> **💡 Complemento:** "Multi-Cloud" aqui se refere à ferramenta de CI/CD (GitHub Actions e Azure DevOps conseguem publicar em qualquer nuvem). O enunciado **não** exige implantar em mais de uma nuvem. Basta um provedor, de preferência o mesmo da Fase 3, reaproveitando cluster e registry.

## Detalhamento técnico e funcionalidades obrigatórias

Nesta fase, a exigência é entregar uma solução **Cloud-Native** totalmente resiliente, que use diferentes modelos de persistência para otimizar a performance e a experiência do usuário.

### 1. Infraestrutura Gerenciada e Portabilidade (mesma estrutura da fase anterior)

- **Provedor de Nuvem:** escolha livre entre AWS, Azure, Google Cloud (GCP) ou Oracle Cloud (OCI).
- **Orquestração:** provisionamento de um cluster Kubernetes Gerenciado (EKS, AKS, GKE ou OKE). Não será aceito o uso de instâncias isoladas (IaaS) para rodar containers manualmente.
- **Registry:** uso de um serviço de registro de imagens privado nativo da Cloud escolhida (ex.: Amazon ECR, Azure ACR).
- **Exposição:** a aplicação deve ser acessível externamente via Load Balancer ou Ingress Controller configurado no cluster.

> **💡 Complemento:**
> - **O que conta como atendido:** um cluster gerenciado ativo (por exemplo, `kubectl get nodes` respondendo contra EKS/AKS), imagens puxadas de um registry **privado da mesma nuvem** e uma URL pública (DNS/IP de um `Service` do tipo `LoadBalancer` ou de um `Ingress`) que responde às APIs.
> - **Armadilhas:** rodar `docker run` numa VM/EC2, usar ECS/Container Apps/App Service no lugar do Kubernetes gerenciado (fora da regra de orquestração) ou usar Docker Hub como registry (não é nativo da Cloud). Um cluster local (kind/minikube/Docker Desktop) também não atende. Lembre que o control plane do EKS e os load balancers são cobrados por hora; desligue o ambiente depois de gravar o vídeo.

### 2. Persistência Poliglota e Alta Performance

- A arquitetura deve evoluir para suportar diferentes tipos de dados e cargas de trabalho, garantindo baixa latência.
- **NoSQL (Obrigatório):** implementar MongoDB ou DynamoDB.
  - Cenário de uso: deve ser usado para dados flexíveis ou de alta volumetria (ex.: catálogo expandido, logs de eventos, perfis de usuário ou sistema de avaliações).
  - Implementação: usar os drivers oficiais para .NET (`MongoDB.Driver` ou `AWSSDK.DynamoDBv2`).
- **Cache de Persistência (Obrigatório):** implementar uma camada de cache distribuído (ex.: Redis).
  - Cenário de uso: guardar temporariamente dados de sessão, resultados de consultas onerosas ou configurações globais para reduzir o round-trip até o banco de dados principal.
  - Implementação: usar a biblioteca `StackExchange.Redis` ou as abstrações do ASP.NET Core (`IDistributedCache`).

> **💡 Complemento (NoSQL):**
> - **O que conta como atendido:** pelo menos um caso de uso real da aplicação (não um endpoint de "teste") lendo e gravando no MongoDB/DynamoDB pelo driver oficial. O banco relacional continua existindo; "poliglota" significa usar **mais de um** modelo de persistência, cada um para o dado adequado.
> - **Armadilhas:** usar outro NoSQL (Cosmos DB, Firestore, Cassandra) foge do enunciado, que cita só MongoDB ou DynamoDB. A exceção discutível é o Cosmos DB com API do MongoDB acessado via `MongoDB.Driver`, mas confirme com os professores no Discord antes. A string de conexão também cai na regra de *Zero Hardcoded Credentials* (item 5). Prepare uma justificativa do porquê aquele dado foi para o NoSQL: ela será pedida no vídeo.
>
> **💡 Complemento (Cache):**
> - **O que conta como atendido:** um cache **distribuído** (Redis acessível por todas as réplicas do pod), com política de expiração (TTL) e invalidação quando o dado muda. Um padrão comum é o *cache-aside*: consulta o cache, em caso de miss busca no banco e grava no cache.
> - **Armadilhas:** `IMemoryCache` é cache em memória do processo, **não** é distribuído, e cada pod teria o próprio. Para registrar o Redis atrás de `IDistributedCache`, use o pacote `Microsoft.Extensions.Caching.StackExchangeRedis` (`AddStackExchangeRedisCache`). O vídeo precisa **mostrar o ganho** (tempo de resposta com e sem cache, ou em miss versus hit), então tenha uma forma de medir: logs, header de tempo, Postman ou métricas.

### 3. Busca Avançada com Elasticsearch

- O motor de busca deve ser independente da consulta tradicional do banco de dados relacional.
- **Serviço:** usar Amazon OpenSearch, Elastic Cloud ou uma instância gerenciada do Elasticsearch.
- **Sincronização:** implementar a lógica de indexação no CatalogAPI. Sempre que um jogo for inserido ou editado no banco principal, o índice do Elasticsearch deve ser atualizado.
- **Funcionalidades:** o endpoint de busca (`/search`) deve obrigatoriamente suportar Fuzzy Search (tolerância a erros de digitação) e ordenação por relevância.

> **💡 Complemento:**
> - **O que conta como atendido:** um endpoint `/search` no CatalogAPI que consulta **só** o Elasticsearch/OpenSearch (sem `LIKE` no SQL), usando uma query com `fuzziness` (por exemplo, `match`/`multi_match` com `"fuzziness": "AUTO"`) e resultados ordenados por `_score`, que é o padrão quando não se informa `sort`. Exemplo para o vídeo: buscar "Zelad" e receber "Zelda".
> - **Sincronização:** toda criação e toda edição de jogo precisa refletir no índice. A remoção não é citada explicitamente, mas manter o índice consistente nas exclusões evita resultados "fantasmas". A indexação pode ser síncrona, logo após o `SaveChanges`, ou por evento/mensageria, aproveitando a arquitetura das fases anteriores.
> - **Armadilhas:** o enunciado pede serviço **gerenciado** (Amazon OpenSearch, Elastic Cloud ou equivalente). Um Elasticsearch via Docker local ou como pod simples no cluster pode não ser aceito como "instância gerenciada". Quanto ao client .NET: `Elastic.Clients.Elasticsearch` (Elasticsearch 8.x+) e `OpenSearch.Client` (OpenSearch) não são intercambiáveis. Escolha o client compatível com o serviço contratado.

### 4. Automação de CI/CD e GitOps

- Todo o ciclo de vida do software deve ser automatizado, garantindo que o código em `main` reflita o que está em produção.
- **Ferramentas:** GitHub Actions ou Azure DevOps.
- **Escopo:** a pipeline deve cobrir, no mínimo, os serviços UsersAPI e CatalogAPI.
- **Workflow:**
  - **Build & Test:** compilação do código e execução de testes unitários automatizados.
  - **Containerização:** geração da imagem Docker com versionamento (Tags).
  - **Security Scan (Desejável):** verificação de vulnerabilidades na imagem.
  - **Push:** upload para o Registry da Cloud.
  - **Deploy:** atualização do ambiente de produção (Kubernetes) sem downtime (Rolling Update).

> **💡 Complemento:**
> - **O que conta como atendido:** um push/merge em `main` dispara automaticamente, para UsersAPI **e** CatalogAPI, a sequência `dotnet build` → `dotnet test` (a pipeline falha se um teste falhar) → `docker build` com tag única (SHA do commit ou versão semântica) → push para ECR/ACR → atualização do Deployment no cluster (`kubectl set image`, `kubectl apply` com a nova tag ou Helm) → espera do `kubectl rollout status`.
> - **Rolling Update sem downtime:** é a estratégia padrão do `Deployment`, mas só não gera indisponibilidade se houver `readinessProbe` configurada, mais de uma réplica (ou `maxUnavailable: 0`) e encerramento gracioso dos pods.
> - **Armadilhas:** usar só a tag `latest` não cumpre o "versionamento (Tags)" e pode não disparar o rollout. Credenciais da nuvem e do registry devem ficar em *secrets* da ferramenta (GitHub Secrets/Environments, ou Library/Service Connections no Azure DevOps), nunca no `.yml`. Na AWS, prefira OIDC (`aws-actions/configure-aws-credentials` com role) a chaves de acesso estáticas.
> - **Security Scan (desejável):** é opcional, mas costuma pesar a favor. Opções comuns: Trivy (`aquasecurity/trivy-action`), scan on push do ECR ou Microsoft Defender for Containers no ACR.
> - **"GitOps":** o título cita GitOps, mas o corpo do enunciado exige só o pipeline de push com deploy no cluster. Ferramentas como Argo CD/Flux não são citadas como obrigatórias.

### 5. Segurança e Gestão de Segredos

- **Zero Hardcoded Credentials:** nenhuma string de conexão, chave de API ou senha de banco de dados deve estar no código-fonte ou nos arquivos YAML.
- **Injeção de Secrets:** usar os Secrets do Kubernetes ou serviços gerenciados (AWS Secrets Manager/Azure Key Vault) integrados ao cluster para injetar as credenciais em tempo de execução.

> **💡 Complemento:**
> - **O que conta como atendido:** `appsettings.json` e os manifests versionados **sem** valores sensíveis. As credenciais (SQL, MongoDB/DynamoDB, Redis, Elasticsearch, JWT etc.) chegam aos pods por `env.valueFrom.secretKeyRef`/`envFrom`, por volume montado ou pelo Secrets Store CSI Driver/External Secrets ligado ao Secrets Manager ou ao Key Vault.
> - **Armadilha clássica:** versionar um `Secret` do Kubernetes com os valores em `data:` (Base64 é só codificação, não criptografia), o que viola a regra dos "arquivos YAML". Crie o Secret fora do repositório (pela pipeline, com valores vindos de secrets da ferramenta de CI, ou pelo provedor gerenciado). Revise também o **histórico do Git**: uma senha removida num commit posterior continua exposta e deve ser trocada.

## Entregáveis da Fase 4

### 1. Vídeo "Pitch Final" (até 25 min)

- Demonstrar a infraestrutura rodando na nuvem escolhida (mostre o painel da AWS/Azure e os pods no Kubernetes).
- Fazer um **Live Deploy**: altere o código, faça push e mostre a pipeline atualizando a aplicação em produção automaticamente.
- Demonstrar a Busca Avançada e o impacto positivo do Cache na resposta da API.
- Explicar como o NoSQL foi integrado à arquitetura.

> **💡 Complemento:** 25 minutos é o **limite máximo**. Faça um roteiro e ensaie, porque a pipeline pode levar vários minutos. No Live Deploy, mude algo **visível** (uma mensagem ou um campo na resposta), mostre o commit/push, a execução da pipeline, o rollout dos pods (`kubectl get pods -w`) e a resposta nova pela URL pública. Na busca, mostre um termo com erro de digitação retornando o jogo certo. No cache, mostre os números (antes/depois ou miss/hit).

### 2. Repositórios de Código

- Código atualizado com os novos drivers de NoSQL e Cache.
- Arquivos YAML de infraestrutura (Terraform, CloudFormation ou Manifestos K8s).
- Definições de Pipeline (`.yml`).

> **💡 Complemento:** o enunciado diz "Arquivos YAML", mas Terraform usa `.tf` (HCL). Ele aparece como opção válida, então Terraform é aceito. Os manifestos K8s (Deployment, Service/Ingress e referências a Secrets, sem os valores) devem estar versionados. Os `.yml` da pipeline ficam em `.github/workflows/` (GitHub Actions) ou em `azure-pipelines.yml` (Azure DevOps).

### 3. Relatório de Entrega

- Nomes do grupo e usernames no Discord.
- Link da documentação (README detalhado).
- Links dos repositórios e do vídeo (YouTube ou Drive).

> **💡 Complemento:** o "README detalhado" deve explicar a arquitetura (diagrama), as tecnologias por serviço (SQL/NoSQL/Redis/Elasticsearch), como provisionar e fazer o deploy, as variáveis/secrets necessários (só os nomes, nunca os valores), como rodar os testes e como usar o `/search`.

Em caso de dúvida, é só chamar a equipe no Discord!

---

## Checklist de entrega

### Infraestrutura (obrigatório)
- [ ] Provedor de nuvem escolhido (AWS, Azure, GCP ou OCI), de preferência o mesmo da Fase 3
- [ ] Cluster Kubernetes **gerenciado** (EKS/AKS/GKE/OKE) ativo, sem containers manuais em VMs/IaaS
- [ ] Imagens hospedadas em registry **privado nativo** da nuvem (ECR/ACR/...)
- [ ] Aplicação acessível externamente via Load Balancer ou Ingress Controller

### Persistência poliglota e performance (obrigatório)
- [ ] MongoDB ou DynamoDB implementado com driver oficial (`MongoDB.Driver` ou `AWSSDK.DynamoDBv2`)
- [ ] NoSQL usado num cenário real de dados flexíveis ou de alta volumetria (catálogo expandido, logs, perfis, avaliações...)
- [ ] Cache distribuído (Redis) via `StackExchange.Redis` ou `IDistributedCache`
- [ ] Cache aplicado a sessões, consultas onerosas ou configurações globais, com TTL e invalidação

### Busca avançada (obrigatório)
- [ ] Elasticsearch/OpenSearch **gerenciado** (Amazon OpenSearch, Elastic Cloud ou equivalente)
- [ ] Busca independente da consulta relacional
- [ ] Indexação no CatalogAPI ao inserir **e** ao editar jogos
- [ ] Endpoint `/search` com Fuzzy Search
- [ ] Endpoint `/search` com ordenação por relevância

### CI/CD (obrigatório, exceto onde indicado)
- [ ] Pipeline em GitHub Actions ou Azure DevOps
- [ ] Pipeline cobre no mínimo UsersAPI **e** CatalogAPI
- [ ] Build & Test com testes unitários automatizados
- [ ] Imagem Docker com tag de versão (não só `latest`)
- [ ] Push para o registry da nuvem
- [ ] Deploy automático no Kubernetes via Rolling Update sem downtime
- [ ] `main` reflete o que está em produção
- [ ] *(Desejável)* Security Scan de vulnerabilidades na imagem

### Segurança (obrigatório)
- [ ] Zero credenciais no código-fonte e nos YAML (inclusive no histórico do Git)
- [ ] Credenciais injetadas em tempo de execução via Kubernetes Secrets, AWS Secrets Manager ou Azure Key Vault

### Vídeo "Pitch Final" (até 25 min)
- [ ] Duração de no máximo 25 minutos
- [ ] Mostra o painel da nuvem (AWS/Azure) e os pods no Kubernetes
- [ ] Live Deploy: alteração de código → push → pipeline → aplicação atualizada em produção
- [ ] Demonstração da Busca Avançada (fuzzy + relevância)
- [ ] Demonstração do impacto positivo do Cache no tempo de resposta
- [ ] Explicação de como o NoSQL foi integrado à arquitetura

### Repositórios
- [ ] Código atualizado com drivers de NoSQL e Cache
- [ ] Arquivos de infraestrutura (Terraform, CloudFormation ou manifests K8s)
- [ ] Definições de pipeline (`.yml`)
- [ ] Repositórios acessíveis aos avaliadores

### Relatório de entrega
- [ ] Nomes dos integrantes e usernames no Discord
- [ ] Link da documentação (README detalhado)
- [ ] Links dos repositórios
- [ ] Link do vídeo (YouTube ou Drive) com permissão de acesso

---

## Mapa das disciplinas

| Requisito do Tech Challenge | Arquivos de estudo relacionados |
|---|---|
| Pipeline CI/CD com Azure DevOps (build, test, multi-stage, release) | [01-azure-devops-ci-cd.md](01-azure-devops-ci-cd.md) |
| Docker, imagens versionadas e registry privado na Azure (ACR); contexto de containers gerenciados | [02-containers-na-azure.md](02-containers-na-azure.md) |
| Infraestrutura na AWS: IAM (permissões da pipeline e do cluster), VPC (rede do EKS), EC2 (nós) | [03-aws-fundamentos-iam-vpc-ec2.md](03-aws-fundamentos-iam-vpc-ec2.md) |
| Cluster Kubernetes gerenciado (EKS), registry privado (ECR), exposição via Load Balancer/Ingress, Rolling Update | [04-aws-containers-ecr-ecs-eks.md](04-aws-containers-ecr-ecs-eks.md) |
| Observabilidade, banco relacional gerenciado (RDS), funções auxiliares (Lambda) e qualidade/segurança de código (SonarQube) | [05-aws-cloudwatch-lambda-rds-sonarqube.md](05-aws-cloudwatch-lambda-rds-sonarqube.md) |
| Pipeline CI/CD com GitHub Actions (build, test, Docker, push, deploy, secrets, security scan) | [06-github-actions.md](06-github-actions.md) |
| Busca avançada: indexação no CatalogAPI, Fuzzy Search, relevância, client .NET | [07-elasticsearch.md](07-elasticsearch.md) |
| Gestão de segredos (Kubernetes Secrets, Secrets Manager, Key Vault) | [01-azure-devops-ci-cd.md](01-azure-devops-ci-cd.md), [03-aws-fundamentos-iam-vpc-ec2.md](03-aws-fundamentos-iam-vpc-ec2.md), [04-aws-containers-ecr-ecs-eks.md](04-aws-containers-ecr-ecs-eks.md), [06-github-actions.md](06-github-actions.md) |
| NoSQL (MongoDB/DynamoDB) e Cache (Redis) | Não há disciplina específica nesta lista. Apoio parcial em [05-aws-cloudwatch-lambda-rds-sonarqube.md](05-aws-cloudwatch-lambda-rds-sonarqube.md) (persistência gerenciada na AWS) |
