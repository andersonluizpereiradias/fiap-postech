# 4. AWS Containers: ECR, ECS e EKS

> **Disciplina de origem:** AWS — Pós-Tech FIAP, Arquitetura de Sistemas .NET, Fase 4
>
> **Aulas cobertas:**
> - Aula 4 - Explorando o ECR
> - Aula 5 - Utilizando o ECS
> - Aula 6 - Gerenciamento de Kubernetes com EKS
>
> **Sobre este material:** o texto das aulas foi reproduzido a partir dos PDFs oficiais e reorganizado em Markdown. Os PDFs trazem a parte teórica ("Saiba mais"); o passo a passo prático ("Hands on") é feito em vídeo e aparece no PDF só como um resumo. Por isso, os comandos de console/CLI, as task definitions e os manifestos usados na prática aparecem aqui como **complementos**, sempre marcados como `💡 Complemento`.

---

## Aula 4 - Explorando o ECR

### O que vem por aí?

Nesta aula você vai aprender sobre o versionamento de imagens e sobre os repositórios que as armazenam para uso posterior. Os repositórios estudados são o **Docker Hub** e o **AWS ECR**.

Também vamos ver como as **tags** funcionam e como o **lifecycle** ajuda a excluir imagens que não são mais usadas. Além disso, a aula explica o que são containers, qual a função deles e como ajudam a resolver problemas com recursos do computador, como CPU, memória RAM e disco. Por fim, criamos nossa primeira imagem e a enviamos para o ECR.

### Hands on

Nesta aula criamos uma imagem Docker, que será usada depois no deploy de aplicações baseadas em containers. A aula também aprofunda o **AWS ECR**: criamos um repositório, aplicamos as boas práticas de configuração e armazenamos nossa primeira imagem.

> **💡 Complemento — passo a passo do hands on (ECR via console e CLI):**
>
> 1. **Console > Amazon ECR > Private registry > Repositories > Create repository.**
>    - *Visibility*: **Private**.
>    - *Repository name*: ex. `fcg/users-api` (o nome pode ter namespace com `/`).
>    - *Tag immutability*: **Immutable** (boa prática; veja abaixo).
>    - *Image scanning*: **Scan on push** (no console mais novo, a configuração de scan fica no nível do registry, em *Private registry > Settings > Scanning*).
>    - *Encryption*: AES-256 (padrão) ou KMS.
> 2. Autentique o Docker no registry (o token vale 12 horas):
>
> ```bash
> aws ecr get-login-password --region us-east-1 \
>   | docker login --username AWS --password-stdin <ACCOUNT_ID>.dkr.ecr.us-east-1.amazonaws.com
> ```
>
> 3. Gere a imagem, aplique a tag com a URI do repositório e envie:
>
> ```bash
> docker build -t fcg/users-api:1.0 .
> docker tag fcg/users-api:1.0 <ACCOUNT_ID>.dkr.ecr.us-east-1.amazonaws.com/fcg/users-api:1.0
> docker push <ACCOUNT_ID>.dkr.ecr.us-east-1.amazonaws.com/fcg/users-api:1.0
> ```
>
> 4. No console, abra a imagem enviada e consulte a aba **Vulnerabilities** com o resultado do scan (a aula termina fazendo essa análise de vulnerabilidade).
>
> O botão **View push commands** do console mostra exatamente esses comandos, já preenchidos com a sua conta e região.

### Saiba mais

Esta seção traz a parte teórica da aula sobre versionamento de imagens. Começamos pelo que são containers e pelo Docker, a ferramenta que ajuda a criar containers e imagens.

#### Docker e o Kernel Linux

O Docker foi lançado em 2013 pela empresa dotCloud. É uma ferramenta Open Source criada para melhorar o isolamento e o uso de recursos e para rodar aplicações sem interface gráfica, em comparação com uma VM (Virtual Machine, ou máquina virtual). Ele só existe porque o Kernel do Linux permite isolar processos e oferece recursos de virtualização.

*Figura 1 - Kernel Linux: diagrama em camadas. "Applications" fica em cima, "Kernel" no meio, e "CPU", "Memory" e "Devices" embaixo, com setas bidirecionais entre o Kernel e cada camada. (Fonte: Digilent, 2023)*

O Kernel Linux é o principal componente de um sistema operacional Linux. Ele é a interface central que faz a comunicação entre o hardware e os processos, controla todas as funções principais e gerencia os recursos com eficiência. Em tradução livre, *kernel* significa núcleo.

As principais funções do Kernel são gerenciar memória, processos, drivers, chamadas do sistema e segurança. Junto com o Kernel, duas outras tecnologias permitem que os containers fiquem isolados uns dos outros: os **Cgroups** e os **Namespaces**.

#### Cgroups

Os Cgroups permitem definir limites de uso de recursos para processos Linux. Com eles é possível definir quanto de CPU um processo pode usar, priorizando os mais importantes ou os definidos nos cgroups. Também é possível limitar recursos como CPU e memória e controlar quais processos podem ou devem ser reiniciados, interrompidos ou congelados com um único comando. Os Cgroups controlam os processos em execução dentro de um container e são essenciais para que ele funcione corretamente e sem gargalos.

#### Namespaces

Namespaces permitem criar e tratar cenários diferentes dentro de um mesmo sistema, cada contexto com propriedades globais próprias e isoladas. O container tem um ambiente isolado parecido com o de uma VM, mas vários containers com aplicações diferentes podem rodar em paralelo no mesmo servidor.

Os Namespaces criam esse isolamento de forma transparente e lógica. Cada container pode ter seu próprio conjunto de usuários, sua rede, seu disco e assim por diante. Assim, se um container quebrar por algum motivo (por exemplo, usando 100% da CPU), os outros containers que rodam em paralelo não sofrem o mesmo problema. Isso garante que aplicações diferentes, que não se comunicam entre si, não sejam afetadas pelo container "ruim".

Imagine um cargueiro carregando vários containers: se um deles cair no mar, os outros não são afetados, e o cargueiro também não. O cargueiro representa o host em que os containers rodam.

*Figura 2 - Containers: foto de um navio cargueiro carregado de containers coloridos, ilustrando a analogia. (Fonte: wtsnet.com.br, 2023)*

> **💡 Complemento:** na prática, os **cgroups** limitam *quanto* o processo consome (CPU, memória, I/O) e os **namespaces** limitam *o que* o processo enxerga (PID, rede, mount, UTS/hostname, IPC, user). Quando um container usa 100% de CPU, quem impede que ele afete os vizinhos é o limite de cgroup, e esse limite precisa estar configurado (ex.: `--cpus`/`--memory` no Docker, `resources.limits` no Kubernetes, `cpu`/`memory` na task definition do ECS). Sem limite, um container ainda consegue disputar a CPU do host.

#### VMs x Containers

As diferenças entre VMs e containers são poucas, mas mudam bastante o modo de execução e o isolamento das aplicações. As duas figuras a seguir mostram esse cenário.

*Figura 3 - Diferenças entre VMs e Containers: à esquerda ("Virtual Machines"), as camadas App 1/2/3, depois Bins/Lib, Guest OS, Hypervisor, Operating System e Infrastructure. À direita ("Containers"), App 1/2/3, Bins/Lib, Container Engine, Operating System e Infrastructure, sem Guest OS por aplicação. (Fonte: elaborado pelo autor, 2024)*

*Figura 4 - Ilustrando o conceito de containers: a pilha genérica (Apps, Bins/Lib, Container Engine, Operating System, Infrastructure) ao lado da versão concreta, com Node, .NET e Python sobre Docker, Docker sobre Linux e Linux sobre a infraestrutura. (Fonte: elaborado pelo autor, 2024)*

> **💡 Complemento:** a diferença central é que cada VM carrega um **sistema operacional convidado completo** sobre um hypervisor, enquanto os containers **compartilham o kernel do host**. Por isso os containers sobem em segundos, ocupam MBs em vez de GBs e permitem mais densidade por servidor. Em troca, o isolamento é mais fraco que o de uma VM. Na AWS, o Fargate (ECS/EKS) roda cada task/pod em uma micro-VM Firecracker justamente para unir as duas abordagens.

#### Imagens

O Docker tem algumas funcionalidades essenciais para criar e rodar um container. A primeira são as **imagens**.

As imagens empacotam o sistema operacional, as dependências, as portas expostas e as variáveis de ambiente. Existem milhares de imagens personalizadas prontas, e também é possível criar sua própria imagem e compartilhá-la com a comunidade.

Imagine que, para rodar uma aplicação .NET, você precise instalar a versão do .NET compatível com o seu código e as dependências pelo NuGet, ou seja, toda aquela configuração padrão que uma aplicação .NET precisa ter pré-instalada para rodar. As imagens personalizadas cumprem esse papel na comunidade.

#### Docker Hub

O Docker Hub é basicamente um GitHub de imagens Docker. Assim como no GitHub qualquer pessoa pode clonar, fazer fork e usar o código de outra pessoa em repositórios públicos, o Docker Hub funciona de forma parecida. Nele encontramos imagens **oficiais** e **não oficiais** (criadas pela comunidade), feitas para ajudar outras pessoas ou para uso próprio, como forma de guardar imagens em um local seguro (privado). Essas imagens são usadas por meio de um **Pull** com a URL e a **Tag** da imagem.

> **💡 Complemento — Docker Hub x Amazon ECR:**
>
> | Aspecto | Docker Hub | Amazon ECR |
> |---|---|---|
> | Modelo | Registry SaaS público/privado | Registry gerenciado da AWS (privado por padrão; existe também o **ECR Public**) |
> | Autenticação | Usuário/token Docker Hub | IAM (`aws ecr get-login-password`); nos nodes EKS/ECS, pela role do node/da task |
> | Limites | Rate limit de pull para usuários anônimos/gratuitos | Sem rate limit de pull do Docker Hub; cobrança por armazenamento e transferência |
> | Scan | Docker Scout | Basic scanning (gratuito) ou Enhanced scanning (Amazon Inspector) |
> | Integração | Genérica | Nativa com ECS, EKS, Lambda, CodeBuild, IAM, KMS, replicação entre regiões/contas |
>
> O ECR também oferece **pull through cache**, que espelha imagens do Docker Hub, do ECR Public, do Quay, do GitHub Container Registry e de outros registries dentro do seu ECR privado. Isso evita o rate limit e deixa as imagens base mais próximas do cluster.

#### O que são as Tags?

As tags definem uma versão da imagem criada e servem para controle, atualização e organização. As imagens recebem melhorias constantes para corrigir bugs, melhorar processos ou corrigir falhas de segurança. É bem parecido com o GitHub, não é mesmo?

Para criar imagens personalizadas, é preciso declarar os comandos, as instalações, as variáveis, as portas etc.

Isso é feito em um arquivo chamado **Dockerfile** (o nome do arquivo já é a sua "extensão"). É nele que as instruções são escritas. Veremos mais sobre ele na próxima aula, mas as figuras a seguir mostram um Dockerfile básico e outro avançado.

> **💡 Complemento — boas práticas de tags no ECR:**
>
> - **Não use `latest` em produção.** Ela é uma tag móvel: o mesmo nome aponta para imagens diferentes com o tempo, então um rollback ou uma investigação ficam impossíveis de reproduzir. Prefira o **SHA curto do commit** (`users-api:3f2a9c1`) e/ou **SemVer** (`users-api:1.4.2`).
> - **Tag immutability** (`IMMUTABLE`): impede sobrescrever uma tag já publicada. Um push com uma tag que já existe falha, o que garante que `1.4.2` seja sempre a mesma imagem. Hoje existe também a opção de imutabilidade **com exclusões** (filtros de tags que continuam mutáveis, ex.: `latest`). Se o seu fluxo usa uma tag móvel, verifique se a sua região/conta já tem esse recurso.
> - Para máxima garantia, faça o deploy por **digest** (`image@sha256:...`), que é imutável por definição.
>
> **Lifecycle policy (limpeza automática):** a aula cita o *lifecycle* para remover imagens que não são mais usadas. Exemplo de política que expira imagens sem tag após 1 dia e mantém só as 20 imagens mais recentes:
>
> ```json
> {
>   "rules": [
>     {
>       "rulePriority": 1,
>       "description": "Remove imagens sem tag após 1 dia",
>       "selection": {
>         "tagStatus": "untagged",
>         "countType": "sinceImagePushed",
>         "countUnit": "days",
>         "countNumber": 1
>       },
>       "action": { "type": "expire" }
>     },
>     {
>       "rulePriority": 2,
>       "description": "Mantém apenas as 20 imagens mais recentes",
>       "selection": {
>         "tagStatus": "any",
>         "countType": "imageCountMoreThan",
>         "countNumber": 20
>       },
>       "action": { "type": "expire" }
>     }
>   ]
> }
> ```
>
> ```bash
> aws ecr put-lifecycle-policy --repository-name fcg/users-api \
>   --lifecycle-policy-text file://lifecycle.json
> ```
>
> Use o **Lifecycle policy preview** do console antes de aplicar, para ver quais imagens seriam removidas.

**Dockerfile simples:**

*Figura 5 - Dockerfile simples (print do VS Code). (Fonte: elaborado pelo autor, 2024)*

```dockerfile
FROM mcr.microsoft.com/dotnet/aspnet:8.0

WORKDIR /App

COPY . ./

RUN dotnet restore

RUN dotnet publish -c Release -o out

ENTRYPOINT ["dotnet", "DotNet.Docker.dll"]
```

**Dockerfile multistage:**

*Figura 6 - Dockerfile multistage (print do VS Code). (Fonte: elaborado pelo autor, 2023)*

```dockerfile
FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build-env

WORKDIR /App

COPY . ./

RUN dotnet restore

RUN dotnet publish -c Release -o out

FROM mcr.microsoft.com/dotnet/aspnet:8.0

WORKDIR /App

COPY --from=build-env /App/out .

ENTRYPOINT ["dotnet", "DotNet.Docker.dll"]
```

> **💡 Complemento — sobre os dois Dockerfiles:**
>
> - O Dockerfile "simples" usa a imagem `aspnet:8.0`, que contém **só o runtime**, sem o SDK. Por isso, `dotnet restore` e `dotnet publish` **falham** nessa imagem. Para um estágio único funcionar, seria preciso usar `sdk:8.0`, o que gera uma imagem bem maior (o SDK tem centenas de MB). Esse é exatamente o problema que o **multistage** resolve: compila no estágio `sdk` e copia apenas os binários publicados para o estágio final `aspnet`.
> - Melhorias comuns no multistage: copiar primeiro só o `*.csproj` e rodar `dotnet restore` antes do `COPY . ./` (aproveita o cache de camadas); publicar com `--no-restore`; usar um `.dockerignore` (`bin/`, `obj/`, `.git/`); rodar como usuário não root (as imagens .NET 8 já trazem o usuário `app`, com `USER app`); e saber que a porta padrão do ASP.NET Core no .NET 8 é **8080**.
> - Se o build roda em máquina ARM (Apple Silicon) e o cluster usa nodes x86, gere a imagem com `docker buildx build --platform linux/amd64` (ou multi-arch). Do contrário, aparece o erro `exec format error` no pod.

### O que você viu nesta aula?

Você viu como funciona um repositório para versionamento e armazenamento de imagens e usou o **AWS ECR** para criar esse repositório.

Também aprendeu como os containers funcionam, conheceu o Docker, a criação de um Dockerfile e o build de uma imagem. Essa imagem foi enviada para o ECR, onde fizemos a **análise de vulnerabilidade**, uma funcionalidade do próprio AWS ECR.

> *Nota: o PDF diz "utilizamos o AWS ECS para a criação do repositório"; o serviço correto é o ECR. Foi corrigido como erro de digitação.*

> **💡 Complemento — scan de vulnerabilidades no ECR:**
>
> - **Basic scanning:** gratuito, usa a base de CVEs (hoje com tecnologia AWS nativa) e pode rodar *on push* ou manualmente.
> - **Enhanced scanning:** integrado ao **Amazon Inspector**. Faz scan contínuo (reavalia quando surgem CVEs novos), cobre pacotes de linguagem (NuGet, npm, pip...) além dos pacotes do SO, e é cobrado à parte.
> - Na pipeline, você pode bloquear o deploy se houver findings `CRITICAL` (consultando `aws ecr describe-image-scan-findings`) ou usar um scanner no CI (Trivy, Grype) antes do push.

### Pontos-chave

- Containers dependem de dois recursos do kernel Linux: **cgroups** (limitam recursos) e **namespaces** (isolam a visão do processo).
- VMs virtualizam o hardware e carregam um SO convidado; containers compartilham o kernel do host e por isso são mais leves e rápidos.
- Uma **imagem** empacota SO base, dependências, portas e variáveis; o **Dockerfile** descreve como construí-la.
- **Docker Hub** é um registry público/privado de imagens; o **Amazon ECR** é o registry privado e gerenciado da AWS, integrado ao IAM.
- **Tags** versionam imagens; em produção, use tags imutáveis (SHA/SemVer) e evite `latest`.
- **Lifecycle policies** removem imagens antigas ou sem tag automaticamente e controlam o custo de armazenamento.
- **Multistage build** separa a compilação (SDK) da execução (runtime) e gera imagens menores e mais seguras.
- O ECR faz **scan de vulnerabilidades** (basic ou enhanced via Inspector), de preferência configurado como *scan on push*.

### Referências da aula

- AWS. *O que é o Amazon Elastic Container Registry?* (2024). https://docs.aws.amazon.com/pt_br/AmazonECR/latest/userguide/what-is-ecr.html
- DIGILENT. *Demystifying The Linux Kernel* (2015). https://digilent.com/blog/demystifiying-the-linux-kernel/
- ETCD. *Containers: o que são namespaces e cgroups* (2021). https://etcd.dev/2021/09/20/containers-o-que-sao-namespaces-e-cgroups/
- LEARN (Microsoft). *Como instalar o Linux no Windows com o WSL* (2023). https://learn.microsoft.com/pt-br/windows/wsl/install
- RED HAT. *O que é o kernel Linux?* (2019). https://www.redhat.com/pt-br/topics/linux/what-is-the-linux-kernel

Palavras-chave: Docker, Container, Linux, ECR, Tags.

---

## Aula 5 - Utilizando o ECS

### O que vem por aí?

Nesta aula você vai aprender a orquestrar containers com o **AWS ECS** e com o **Docker Compose** para execução local. No ECS, vamos ver o que são **Task Definitions**, **Services** e **Clusters**, e toda a configuração necessária para subir um novo serviço em poucos passos, usando a imagem que enviamos para o ECR na aula anterior.

Também vamos escrever um arquivo `.yml` que cria os containers de forma automatizada, com base nas instruções do arquivo, e ver como os comandos funcionam. Além disso, vamos conhecer o básico do docker-compose e suas funcionalidades, rodar uma aplicação **WordPress** com banco **MySQL** e testar o acesso via Web.

### Hands on

Nesta aula escrevemos nosso primeiro arquivo `docker-compose.yml` no VSCode e o executamos pelo terminal do WSL, criando os containers de forma automatizada e acessando a aplicação via Web.

> **💡 Complemento — conceitos do ECS usados no hands on:**
>
> - **Cluster:** agrupamento lógico onde as tasks rodam. A capacidade vem de **Fargate** (serverless, você não gerencia servidores), de **EC2** (instâncias suas, via Auto Scaling Group/capacity provider) ou de **ECS Managed Instances** (opção mais recente, em que a AWS gerencia as instâncias EC2 por você).
> - **Task Definition:** a "receita" versionada (revisions) de um ou mais containers: imagem, CPU/memória, portas, variáveis, secrets, logs, roles IAM. É o equivalente, no ECS, a um `PodSpec`/`docker-compose.yml`.
> - **Task:** uma instância em execução de uma task definition (análoga a um Pod).
> - **Service:** mantém N tasks rodando (desired count), substitui tasks com falha, integra com o **ALB/NLB** e faz **rolling update** em novos deploys (análogo a Deployment + Service do Kubernetes).
> - **Task execution role:** usada pelo *agente* do ECS para fazer pull no ECR e escrever logs no CloudWatch.
> - **Task role:** usada pela *aplicação* para chamar serviços AWS (S3, SQS, Secrets Manager...).

> **💡 Complemento — exemplo de task definition (Fargate) apontando para a imagem do ECR:**
>
> ```json
> {
>   "family": "users-api",
>   "networkMode": "awsvpc",
>   "requiresCompatibilities": ["FARGATE"],
>   "cpu": "256",
>   "memory": "512",
>   "runtimePlatform": { "operatingSystemFamily": "LINUX", "cpuArchitecture": "X86_64" },
>   "executionRoleArn": "arn:aws:iam::<ACCOUNT_ID>:role/ecsTaskExecutionRole",
>   "taskRoleArn": "arn:aws:iam::<ACCOUNT_ID>:role/usersApiTaskRole",
>   "containerDefinitions": [
>     {
>       "name": "users-api",
>       "image": "<ACCOUNT_ID>.dkr.ecr.us-east-1.amazonaws.com/fcg/users-api:1.0",
>       "essential": true,
>       "portMappings": [{ "containerPort": 8080, "protocol": "tcp" }],
>       "environment": [{ "name": "ASPNETCORE_ENVIRONMENT", "value": "Production" }],
>       "secrets": [
>         {
>           "name": "ConnectionStrings__DefaultConnection",
>           "valueFrom": "arn:aws:secretsmanager:us-east-1:<ACCOUNT_ID>:secret:fcg/users-db"
>         }
>       ],
>       "logConfiguration": {
>         "logDriver": "awslogs",
>         "options": {
>           "awslogs-group": "/ecs/users-api",
>           "awslogs-region": "us-east-1",
>           "awslogs-stream-prefix": "ecs"
>         }
>       },
>       "healthCheck": {
>         "command": ["CMD-SHELL", "curl -f http://localhost:8080/health || exit 1"],
>         "interval": 30,
>         "timeout": 5,
>         "retries": 3,
>         "startPeriod": 15
>       }
>     }
>   ]
> }
> ```
>
> Observações: no Fargate, `cpu`/`memory` precisam seguir combinações válidas (ex.: 256 CPU units com 512 MB, 1 GB ou 2 GB). O `healthCheck` com `curl` só funciona se o binário existir na imagem (as imagens `aspnet` não trazem `curl` por padrão); o mais comum é deixar o health check para o **target group do ALB**.
>
> Fluxo típico no console: *ECS > Clusters > Create cluster (Fargate)* → *Task definitions > Create new* → *Cluster > Services > Create* (launch type Fargate, desired tasks, VPC/subnets/security group, Application Load Balancer, deployment type **Rolling update** com *minimum healthy percent* 100% e *maximum percent* 200%, além do **deployment circuit breaker com rollback** ativado).

### Saiba mais

Sabemos que o AWS ECS é o serviço da AWS que orquestra containers. Mas como testar a comunicação entre os serviços localmente?

Com o orquestrador **Docker Compose**! Ele gerencia múltiplos containers e facilita a comunicação e as dependências entre as aplicações. Nesta seção, vamos entender melhor o Docker Compose e criar nosso arquivo YAML para orquestrar a aplicação com banco de dados. Com o Docker Compose também é possível criar múltiplos containers de outras maneiras, por exemplo definindo um serviço que aponta para um Dockerfile.

Você vai conhecer mais a fundo os comandos do Docker Compose e entender em detalhes o que cada parte do arquivo faz. O Docker Compose ajuda a criar os serviços e a testar a comunicação entre eles antes de levá-los para o AWS ECS, já que corrigir problemas localmente é mais fácil do que depois de enviar a imagem para o ECR e usá-la no ECS.

Vamos detalhar agora a criação de um arquivo YAML para o Docker Compose.

Um arquivo YAML do Docker Compose segue alguns padrões, o que facilita a criação dos próximos arquivos. A seguir, detalhamos todas as partes de um arquivo e, no final, criamos uma aplicação WordPress com banco de dados MySQL.

#### Estrutura do arquivo docker-compose.yaml

- **version\***: define a versão do formato do arquivo `docker-compose.yml`. Versões diferentes suportam conjuntos diferentes de recursos e sintaxes. *\*Este campo foi descontinuado.*
- **networks**: define as redes que os contêineres usam para se comunicar entre si. Você pode criar redes personalizadas para isolar partes da aplicação.
- **volumes**: usados para persistir os dados gerados pelos contêineres. Você pode definir volumes compartilhados entre múltiplos contêineres.
- **services**: define os serviços (contêineres) que compõem a aplicação. Cada serviço pode ser configurado com vários parâmetros.

Dentro do bloco `services` pode haver várias instruções. As principais e mais usadas são:

- **image**: especifica a imagem Docker usada para criar o contêiner.
- **ports**: mapeia portas do contêiner para portas do host, no formato `"host:contêiner"`.
- **volumes** (dentro de services): monta volumes dentro do contêiner, o que permite persistir dados e compartilhá-los entre contêineres.
- **restart**: políticas que definem quando o contêiner é reiniciado. As opções são:
  - **no**: os containers não são reiniciados.
  - **on-failure**: reinicia o contêiner em caso de falha. É considerada falha uma saída com código diferente de zero.
  - **always**: o contêiner é reiniciado sempre que parar de funcionar.
  - **unless-stopped**: sempre reinicia o contêiner, a menos que ele tenha sido parado intencionalmente. Serve para deixar um serviço X desligado.

  Em muitos casos, cada serviço tem a sua própria política de restart.
- **depends_on**: especifica dependências entre serviços, garantindo que um serviço só comece depois que outro estiver em execução.
- **environment**: define variáveis de ambiente. Muitos serviços deixam variáveis vazias para que os valores sejam definidos de fora, e o `environment` fornece esses valores. É possível usar `env_file` no lugar de `environment`, apontando para qualquer arquivo `.env` no host.
- **healthcheck**: configura um comando de verificação de saúde que determina se o contêiner está funcionando corretamente.
- **command** e **entrypoint**: permitem alterar o comando principal que inicia o contêiner. Com eles, o `CMD` ou o `ENTRYPOINT` da imagem/Dockerfile é substituído pelo `command` ou `entrypoint` do compose.

#### Exemplo: WordPress + MySQL

*Figura 1 - docker compose (print do VS Code). (Fonte: elaborado pelo autor, 2024)*

```yaml
version: '3.8'

networks:
  fiap_network:
    driver: bridge

volumes:
  mysql_data:
  wordpress_data:

services:
  db:
    image: mysql:latest
    environment:
      MYSQL_DATABASE: wordpress
      MYSQL_USER: wordpress_user
      MYSQL_PASSWORD: wordpress_password
      MYSQL_ROOT_PASSWORD: root_password
    volumes:
      - mysql_data:/var/lib/mysql
    networks:
      - fiap_network
    restart: always
    healthcheck:
      test: ["CMD", "mysqladmin", "ping", "-h", "localhost"]
      interval: 30s
      timeout: 10s
      retries: 5

  wordpress:
    image: wordpress:latest
    ports:
      - "8080:80"
    volumes:
      - wordpress_data:/var/www/html
    networks:
      - fiap_network
    restart: always
    depends_on:
      db:
        condition: service_healthy
    environment:
      WORDPRESS_DB_HOST: db:3306
      WORDPRESS_DB_USER: wordpress_user
      WORDPRESS_DB_PASSWORD: wordpress_password
      WORDPRESS_DB_NAME: wordpress
```

#### Explicação do Healthcheck

O healthcheck do serviço `db` usa o comando `mysqladmin ping -h localhost` para verificar se o MySQL está respondendo. Se o healthcheck falhar, o Docker tenta de novo a cada 30 segundos, até no máximo 5 tentativas. O serviço WordPress só inicia quando o serviço MySQL estiver saudável, conforme definido em `depends_on` com a condição `service_healthy`.

> **💡 Complemento:** o `depends_on` simples (lista de nomes) só garante a **ordem de criação**, não que a dependência esteja pronta. O que faz o WordPress esperar o MySQL é a forma longa com `condition: service_healthy`. No Kubernetes não existe `depends_on`: a aplicação precisa tolerar a dependência indisponível (retry), e as **readiness probes** impedem que um pod receba tráfego antes de estar pronto. Depois de executar `docker compose up -d`, acesse `http://localhost:8080` para concluir a instalação do WordPress.

#### Comandos mais usados do docker-compose

- `docker compose up`: cria e inicia os containers.
- `docker compose build`: executa só a etapa de build das imagens que serão usadas. Facilita muito na hora do `up`.
- `docker compose logs`: mostra os logs dos containers.
- `docker compose restart`: reinicia os containers.
- `docker compose ps`: lista os containers.
- `docker compose scale`: aumenta o número de réplicas de um contêiner.
- `docker compose start`: inicia os containers.
- `docker compose stop`: para os containers.
- `docker compose down`: para e remove todos os containers e seus componentes, como rede, imagem e volume.

Diferente do Docker, em que administramos um único contêiner, com o Docker Compose administramos um **grupo** de containers e fazemos o build e o run de todos com um único comando: `docker compose up` para subir os containers e `docker compose down` para derrubá-los.

> **💡 Complemento — precisão sobre os comandos:**
>
> - `docker compose down` remove, por padrão, **containers e redes**. **Volumes nomeados só são removidos com `-v`/`--volumes`**, e imagens só com `--rmi all` (ou `--rmi local`). Isso protege os dados do `mysql_data` entre execuções.
> - `docker compose up -d` roda em segundo plano; `docker compose logs -f <serviço>` acompanha os logs em tempo real.
> - Para escalar, a forma mais usada é `docker compose up -d --scale wordpress=3`. Um serviço com porta fixa no host (`8080:80`) não consegue ter várias réplicas, porque haveria conflito de porta.
> - `version:` hoje é ignorado pelo Docker Compose v2 (que segue a *Compose Specification*) e gera apenas um aviso de que o campo é obsoleto.
> - Não versione senhas em texto puro no compose. Use `.env` (fora do Git) ou `secrets:`.

*Figura 2 - Diferença entre Docker e Docker Compose: à esquerda, um único container ("App NodeJS") gerenciado pelo Docker; à direita, um grupo com "DB MySQL", "phpAdmin" e "Wordpress" dentro de uma moldura "Docker-Compose". (Fonte: elaborado pelo autor, 2024)*

#### Exemplo avançado: Kong API Gateway + Konga

A seguir há um exemplo avançado de `docker-compose.yml`, disponível para download no material de apoio. Os serviços são:

- banco de dados **Postgres**, construído a partir de um Dockerfile local;
- **migrations** executadas no banco para atualizar as tabelas;
- o **Kong**, um API gateway com versão open source;
- um serviço que executa um comando de preparação do **Konga**, um frontend open source criado pela comunidade para facilitar o cadastro de entradas no Kong API Gateway;
- e, por fim, o frontend **Konga**.

Este exemplo usa `.env`, Dockerfiles e um arquivo `.sql` que cria um usuário dentro do banco. Ele também traz instruções ainda não vistas:

- **links**: liga diretamente um container a outro;
- **build**: faz o build da imagem a partir do Dockerfile;
- **context**: define o caminho onde está o Dockerfile. Como ele está na raiz, usamos um ponto (`.`).

*Figura 3 - docker-compose.yml kong api gateway (print do VS Code em duas partes). (Fonte: elaborado pelo autor, 2024)*

```yaml
version: '3.7'

networks:
  kong-net:
    driver: bridge

services:
  kong-database:
    build:
      context: .
      dockerfile: Dockerfile
    image: postgres:11.16
    restart: always
    networks:
      - kong-net
    environment:
      - POSTGRES_USER=${KONG_DB_USERNAME}
      - POSTGRES_PASSWORD=${KONG_DB_PASSWORD}
      - POSTGRES_DB=${KONG_DB_NAME}
  kong-migrations:
    build:
      context: .
      dockerfile: Dockerfile-kong-migrations
    image: kong:latest
    entrypoint: sh c- "sleep 10 && kong migrations bootstrap -v"
    environment:
      - KONG_DATABASE=${KONG_DATABASE}
      - KONG_PG_HOST=${KONG_DB_HOST}
      - KONG_PG_DATABASE=${KONG_DB_NAME}
      - KONG_PG_USER=${KONG_DB_USERNAME}
      - KONG_PG_PASSWORD=${KONG_DB_PASSWORD}
    depends_on:
      - kong-database
    networks:
      - kong-net
    restart: on-failure
  kong:
    build:
      context: .
      dockerfile: Dockerfile-kong
    image: kong:latest
    environment:
      - KONG_DATABASE=${KONG_DATABASE}
      - KONG_PG_HOST=${KONG_DB_HOST}
      - KONG_PG_DATABASE=${KONG_DB_NAME}
      - KONG_PG_USER=${KONG_DB_USERNAME}
      - KONG_PG_PASSWORD=${KONG_DB_PASSWORD}
      - KONG_PROXY_ACCESS_LOG=${KONG_PROXY_ACCESS_LOG}
      - KONG_ADMIN_ACCESS_LOG=${KONG_ADMIN_ACCESS_LOG}
      - KONG_PROXY_ERROR_LOG=${KONG_PROXY_ERROR_LOG}
      - KONG_ADMIN_ERROR_LOG=${KONG_ADMIN_ERROR_LOG}
    restart: on-failure
    ports:
      - $KONG_PROXY_PORT:8000
      - $KONG_PROXY_SSL_PORT:8443
    depends_on:
      - kong-database
      - kong-migrations
    networks:
      - kong-net
  kong-prepare:
    image: pantsel/konga:next
    command: "-c prepare -a postgres -u postgresql://kong:kong@kong-database:5432/konga"
    networks:
      - kong-net
    restart: on-failure
    links:
      - kong-database
    depends_on:
      - kong-database
  konga:
    image: pantsel/konga:next
    environment:
      - TOKEN_SECRET=${KONGA_TOKEN_SECRET}
      - DB_ADAPTER=${KONGA_DATABASE}
      - DB_HOST=${KONGA_DB_HOST}
      - DB_PORT=${KONGA_DB_PORT}
      - DB_DATABASE=${KONGA_DB_NAME}
      - DB_USER=${KONGA_DB_USERNAME}
      - DB_PASSWORD=${KONGA_DB_PASSWORD}
      - NODE_ENV=${KONGA_NODE_ENV}
    restart: always
    ports:
      - ${KONGA_PORT}:${KONGA_PORT}
    depends_on:
      - kong-database
      - konga-prepare
    networks:
      - kong-net
```

> **💡 Complemento — pontos de atenção no exemplo do Kong (o código acima foi mantido como no PDF):**
>
> - `entrypoint: sh c- "..."` tem um erro de digitação: o correto é `sh -c "sleep 10 && kong migrations bootstrap -v"`.
> - O serviço `konga` depende de `konga-prepare`, mas o serviço declarado se chama `kong-prepare`. O Compose acusaria dependência inexistente. Os nomes precisam ser iguais.
> - Quando um serviço tem `build:` e `image:` juntos, a imagem construída **recebe a tag** do valor de `image` (ex.: o build local seria tagueado como `postgres:11.16`). Isso pode confundir. Prefira uma tag própria (ex.: `fcg/kong-db:1.0`).
> - `links:` é uma funcionalidade **legada**. Serviços na mesma rede (`kong-net`) já se resolvem pelo nome via DNS interno do Docker.
> - O `sleep 10` é uma espera "frágil". O ideal é um `healthcheck` no Postgres (`pg_isready`) + `depends_on: condition: service_healthy`, e `condition: service_completed_successfully` para o job de migrations.
> - O projeto Konga não recebe manutenção ativa há anos. Use-o só como exemplo didático.

### O que você viu nesta aula?

Você viu como orquestrar containers com o **AWS ECS**. Continuando a aula anterior, em que enviamos nossa imagem para o ECR, nesta aula criamos um **serviço** e apontamos a **task definition** para essa imagem.

Também entendemos por que o ECS é bom para rodar containers de forma simples. Orquestramos múltiplos containers com o **Docker Compose** e vimos como criar um arquivo `.yml`, os comandos mais usados e o que cada comando e instrução faz no Docker Compose.

Por fim, vimos um exemplo avançado de Docker Compose e subimos o serviço para analisar os logs de um container antes de levá-lo para a AWS com o ECS.

> **💡 Complemento — Docker Compose → ECS (mapeamento de conceitos):**
>
> | Docker Compose | Amazon ECS |
> |---|---|
> | Arquivo `docker-compose.yml` | Task Definition (JSON, versionada por *revision*) |
> | `services.<nome>` | `containerDefinitions[]` (vários containers numa task = *sidecars*) ou um Service por microsserviço |
> | `image` | `image` (URI do ECR) |
> | `ports` | `portMappings` + target group do ALB |
> | `environment` / `env_file` | `environment` / `environmentFiles` (S3) |
> | segredos no `.env` | `secrets` (Secrets Manager / SSM Parameter Store) |
> | `restart: always` | Service com `desiredCount` (o scheduler repõe tasks que pararem) |
> | `healthcheck` | `healthCheck` do container e/ou health check do target group |
> | `depends_on` | `dependsOn` (só entre containers da **mesma** task) |
> | rede `bridge` | `awsvpc` (cada task ganha uma ENI/IP na VPC) + Service Connect/Cloud Map para descoberta |
> | `volumes` | EFS, EBS (volumes por task) ou bind mounts efêmeros |
>
> O antigo `docker compose` com contexto ECS (integração Docker–ECS) foi **descontinuado**. Hoje a conversão costuma ser feita manualmente, com IaC (Terraform, CDK, CloudFormation) ou com o **ECS Express Mode**, que cria serviço, ALB e auto scaling a partir de uma imagem com poucos parâmetros.

### Pontos-chave

- O **ECS** é o orquestrador de containers nativo da AWS, com três conceitos centrais: **Cluster**, **Task Definition** e **Service**.
- A task definition aponta para a imagem no **ECR** e define CPU/memória, portas, variáveis, secrets, logs e roles.
- **Fargate** elimina o gerenciamento de servidores; **EC2** dá mais controle e pode custar menos em uso constante.
- O **Docker Compose** orquestra vários containers localmente e é ideal para testar a comunicação antes de ir para a nuvem.
- Blocos principais do compose: `networks`, `volumes`, `services`; no serviço: `image`, `ports`, `volumes`, `restart`, `depends_on`, `environment`, `healthcheck`, `command`/`entrypoint`.
- `depends_on` com `condition: service_healthy` garante que a dependência esteja **saudável**, não apenas criada.
- `docker compose up`/`down` sobem e derrubam o conjunto inteiro; `down` só apaga volumes com `-v`.
- O campo `version` do compose está obsoleto, e `links` é legado (use redes).

### Referências da aula

- AWS. *AWS Fargate para o Amazon ECS* (2024). https://docs.aws.amazon.com/pt_br/AmazonECS/latest/developerguide/AWS_Fargate.html
- AWS. *O que é o Amazon Elastic Container Service?* (2024). https://docs.aws.amazon.com/pt_br/AmazonECS/latest/developerguide/Welcome.html
- CAEIRO, R. *Dominando o Docker Compose: Guia completo para gerenciamento de multi-contêineres* (2021). https://blog.4linux.com.br/docker-compose-explicado/
- DOCKER. *Compose Docker Specification* (2024). https://docs.docker.com/compose/compose-file/develop/
- JAIMES, C. *Docker compose restart policies* (2024). https://www.baeldung.com/ops/docker-compose-restart-policies

Palavras-chave: Docker Compose, Container, Linux, ECS, Task, YAML.

---

## Aula 6 - Gerenciamento de Kubernetes com EKS

### O que vem por aí?

Nesta aula você vai aprender a orquestrar containers com o **AWS EKS**, escrever arquivos `.yml` de **deployments**, **services** e **pods**, e fazer toda a configuração necessária para criar um **Cluster** e um **Node** com EKS.

Também vamos expor a aplicação para a internet e testar o **HPA**, para garantir que ela suporta o tráfego externo com o auto scaling configurado.

### Hands on

Nesta aula criamos um cluster e um node com o AWS EKS. Vamos aprofundar o Kubernetes usando esse serviço da AWS e criar nosso Deployment, Service e Pods para demonstrar o poder do EKS.

> **💡 Complemento — criando o cluster (equivalente ao passo a passo do vídeo):**
>
> Pelo console, o fluxo clássico é: (1) criar a **IAM role do cluster** (policy `AmazonEKSClusterPolicy`); (2) *EKS > Create cluster*, escolher versão do Kubernetes, VPC e subnets (de preferência privadas para nodes e públicas para o load balancer), e acesso ao endpoint (*Public*, *Private* ou *Public and private*); (3) criar a **IAM role dos nodes** (`AmazonEKSWorkerNodePolicy`, `AmazonEC2ContainerRegistryReadOnly`, `AmazonEKS_CNI_Policy`); (4) na aba *Compute*, *Add node group* (managed node group) com tipo de instância, tamanho mínimo/desejado/máximo; (5) instalar os **add-ons** (VPC CNI, CoreDNS, kube-proxy, e opcionalmente metrics-server, EBS CSI driver e Pod Identity Agent).
>
> Com o **eksctl**, isso vira um único comando:
>
> ```bash
> eksctl create cluster \
>   --name fcg-cluster \
>   --region us-east-1 \
>   --nodegroup-name fcg-nodes \
>   --node-type t3.medium \
>   --nodes 2 --nodes-min 2 --nodes-max 4 \
>   --managed
>
> # configura o kubeconfig local (o eksctl já faz isso automaticamente)
> aws eks update-kubeconfig --region us-east-1 --name fcg-cluster
> kubectl get nodes
> ```
>
> **Atualização — EKS Auto Mode (lançado no fim de 2024):** com Auto Mode, a AWS gerencia os nodes (provisionamento via Karpenter, patching, upgrades), o load balancing (ALB/NLB), o storage em blocos (EBS) e a rede do pod. Você cria o cluster e aplica os manifestos, sem node groups nem instalar o AWS Load Balancer Controller. Há uma taxa adicional por instância gerenciada, além do custo do EC2. Para estudo, é o caminho mais curto; para entender os componentes, managed node groups ainda são didáticos.
>
> **Boa prática:** prefira **managed node groups** (ou Auto Mode/Karpenter) a self-managed nodes. A AWS cuida da AMI otimizada, de drain e de rolling update dos nodes em upgrades.

### Saiba mais

O **Kubernetes** é um sistema open source de orquestração de contêineres que automatiza a implantação, o dimensionamento e o gerenciamento de aplicativos em contêineres. Desenvolvido inicialmente pelo Google, ele se tornou um padrão amplamente aceito para gerenciar aplicações em contêineres em produção.

O Kubernetes gerencia a execução de contêineres em um cluster de máquinas e oferece balanceamento de carga, escalabilidade automática, atualizações sem tempo de inatividade e recuperação automática. A arquitetura básica do Kubernetes tem alguns componentes-chave:

- **Master Node**: gerencia o estado do cluster e controla o gerenciamento de recursos. Inclui componentes como API Server, Scheduler, Controller Manager e etcd.
- **Worker Nodes**: executam as aplicações em contêineres e são compostos por componentes como kubelet, kube-proxy e o runtime de contêiner (por exemplo, Docker).

Dentro dos Worker Nodes ficam todas as funcionalidades e configurações, como Pods, Deployments e Services. A seguir, o que cada um representa no Kubernetes.

> **💡 Complemento (atualização de terminologia):**
>
> - A documentação atual chama o "Master Node" de **control plane**. No **EKS, o control plane é gerenciado pela AWS**: API Server e etcd rodam em várias AZs, em uma conta da AWS, e você não vê nem acessa essas máquinas. Você só gerencia os worker nodes (ou nem isso, com Fargate/Auto Mode).
> - Desde o Kubernetes 1.24 o *dockershim* foi removido. Os nodes do EKS usam **containerd** como runtime. Imagens geradas com Docker continuam funcionando normalmente, porque seguem o padrão OCI.
> - Tecnicamente, Pods, Deployments e Services são **objetos da API** guardados no etcd (control plane). Os pods *executam* nos worker nodes, e o kube-proxy implementa os Services em cada node.

#### Pods

O Pod é a menor e mais básica unidade de execução do Kubernetes. Um Pod pode conter um ou mais contêineres que compartilham armazenamento, rede e informações sobre como executá-los. Os contêineres de um mesmo Pod compartilham o mesmo IP e o mesmo espaço de portas, e também podem compartilhar volumes.

#### Deployments

Um Deployment gerencia a criação e a atualização de Pods de forma declarativa. Ele garante que o número desejado de réplicas de um Pod esteja em execução a qualquer momento. Também permite atualizar as versões dos Pods continuamente e voltar para uma versão anterior se algo der errado na atualização.

> **💡 Complemento — Deployment com rolling update sem downtime e probes:**
>
> ```yaml
> apiVersion: apps/v1
> kind: Deployment
> metadata:
>   name: users-api
>   namespace: fcg
> spec:
>   replicas: 2
>   revisionHistoryLimit: 5
>   strategy:
>     type: RollingUpdate
>     rollingUpdate:
>       maxUnavailable: 0   # nunca derruba um pod antes de o novo estar Ready
>       maxSurge: 1         # cria 1 pod extra por vez durante a troca
>   selector:
>     matchLabels: { app: users-api }
>   template:
>     metadata:
>       labels: { app: users-api }
>     spec:
>       containers:
>         - name: users-api
>           image: <ACCOUNT_ID>.dkr.ecr.us-east-1.amazonaws.com/fcg/users-api:3f2a9c1
>           ports:
>             - containerPort: 8080
>           resources:
>             requests: { cpu: 100m, memory: 128Mi }
>             limits:   { memory: 256Mi }
>           readinessProbe:          # controla quando o pod entra no Service/LB
>             httpGet: { path: /health/ready, port: 8080 }
>             initialDelaySeconds: 5
>             periodSeconds: 10
>           livenessProbe:           # reinicia o container se travar
>             httpGet: { path: /health/live, port: 8080 }
>             initialDelaySeconds: 20
>             periodSeconds: 15
> ```
>
> Comandos úteis: `kubectl rollout status deployment/users-api -n fcg`, `kubectl rollout history ...` e `kubectl rollout undo deployment/users-api -n fcg` (rollback). Sem **readinessProbe**, o Kubernetes considera o pod pronto assim que o container inicia, e o tráfego pode chegar antes de a API estar de pé, o que causa erros 5xx durante o deploy. Os `requests` de CPU também são **obrigatórios para o HPA** calcular a utilização percentual.

#### ReplicaSets

O ReplicaSet garante que um número específico de réplicas de um Pod esteja em execução a qualquer momento. Normalmente ele é gerenciado por um Deployment. O ReplicaSet mantém o número desejado de Pods e facilita o dimensionamento horizontal.

#### StatefulSets

Um StatefulSet gerencia Pods com identidades únicas e armazenamento persistente. É ideal para aplicações que precisam de identidade de rede estável e armazenamento persistente, como bancos de dados. Cada Pod tem uma identidade persistente (nome de host e volume de armazenamento). A diferença para o ReplicaSet é que, aqui, a criação e a exclusão de Pods acontecem de forma ordenada.

#### DaemonSets

Um DaemonSet garante que uma cópia de um Pod rode em todos os nós do cluster (ou em um subconjunto deles). É útil para serviços de infraestrutura, como coletores de logs e monitoramento. Um Pod roda em cada Node, para tarefas que precisam executar em todos eles.

> **💡 Complemento:** no EKS, exemplos de DaemonSets são o `aws-node` (VPC CNI) e o `kube-proxy`, além de agentes como Fluent Bit e CloudWatch Agent. Pods em **Fargate** não suportam DaemonSets (cada pod roda isolado na sua própria micro-VM), então os agentes viram sidecars.

#### Services

Um Service define como acessar um conjunto de Pods e oferece um ponto de acesso estável para interagir com eles, independentemente de onde estejam ou do seu estado.

**Tipos de Services:**

- **ClusterIP**: expõe o Service apenas dentro do cluster.
- **NodePort**: expõe o Service em uma porta específica de cada nó.
- **LoadBalancer**: cria um Load Balancer externo que distribui o tráfego para os Pods.
- **ExternalName**: mapeia o Service para um nome DNS externo.

##### ClusterIP

O ClusterIP é o tipo de Service padrão. Ele expõe o Service apenas dentro do cluster, com um endereço IP interno para que os Pods do cluster possam se comunicar com o Service.

##### NodePort

O NodePort expõe o Service em uma porta específica de cada nó do cluster. Isso permite acesso externo ao serviço por qualquer IP de nó na porta NodePort.

##### Load Balancer

O LoadBalancer expõe o Service para fora do cluster e distribui o tráfego para os Pods por meio de um Load Balancer provisionado pela nuvem, como o AWS Elastic Load Balancer.

> **💡 Complemento — `type: LoadBalancer` no EKS:**
>
> - Sem nenhum controller adicional, o controller *in-tree* legado do Kubernetes cria um **Classic Load Balancer** (ou um NLB, com a anotação `service.beta.kubernetes.io/aws-load-balancer-type: nlb`).
> - Com o **AWS Load Balancer Controller** instalado (ou com EKS Auto Mode), o Service `LoadBalancer` vira um **Network Load Balancer** (camada 4), configurado por anotações, e o recurso **Ingress** vira um **Application Load Balancer** (camada 7).
> - Exemplo de Service com NLB via controller:
>
> ```yaml
> apiVersion: v1
> kind: Service
> metadata:
>   name: users-api-public
>   namespace: fcg
>   annotations:
>     service.beta.kubernetes.io/aws-load-balancer-type: external
>     service.beta.kubernetes.io/aws-load-balancer-nlb-target-type: ip
>     service.beta.kubernetes.io/aws-load-balancer-scheme: internet-facing
> spec:
>   type: LoadBalancer
>   selector: { app: users-api }
>   ports:
>     - port: 80
>       targetPort: 8080
> ```
>
> Cada Service `LoadBalancer` cria **um load balancer novo**, e cada um tem custo por hora. Para vários microsserviços, um **Ingress** (um único ALB com regras por host/path) costuma ser mais barato e organizado.

##### ExternalName

Permite criar um Service que funciona como alias DNS para um serviço externo, fora do cluster Kubernetes. É útil para integrar recursos externos sem criar regras complexas de roteamento nem configurar diretamente a comunicação com esses serviços.

> **💡 Complemento:** um uso típico de ExternalName no EKS é apontar `postgres.fcg.svc.cluster.local` para o endpoint de um **Amazon RDS** (`CNAME`). A aplicação continua usando um nome interno estável, e trocar o banco não exige alterar a configuração da app.

#### Ingress

O Ingress gerencia o acesso externo aos serviços do cluster, com roteamento baseado em URL e suporte a SSL/TLS. Ele depende de um **controlador de Ingress** para implementar as regras definidas e permite criar regras de roteamento para diferentes caminhos de URL. Também suporta criptografia SSL/TLS para comunicação segura.

> **💡 Complemento — Ingress com ALB (AWS Load Balancer Controller):**
>
> ```yaml
> apiVersion: networking.k8s.io/v1
> kind: Ingress
> metadata:
>   name: fcg-ingress
>   namespace: fcg
>   annotations:
>     alb.ingress.kubernetes.io/scheme: internet-facing
>     alb.ingress.kubernetes.io/target-type: ip
>     alb.ingress.kubernetes.io/group.name: fcg          # várias Ingress compartilhando 1 ALB
>     alb.ingress.kubernetes.io/healthcheck-path: /health
>     # TLS (opcional): certificado do ACM
>     # alb.ingress.kubernetes.io/certificate-arn: arn:aws:acm:us-east-1:<ACCOUNT_ID>:certificate/<ID>
>     # alb.ingress.kubernetes.io/listen-ports: '[{"HTTP":80},{"HTTPS":443}]'
> spec:
>   ingressClassName: alb
>   rules:
>     - http:
>         paths:
>           - path: /api/users
>             pathType: Prefix
>             backend:
>               service:
>                 name: users-api
>                 port:
>                   number: 8080
> ```
>
> - Pré-requisitos do controller: instalação via Helm (`eks/aws-load-balancer-controller`), uma IAM policy própria associada à service account do controller (via Pod Identity ou IRSA) e subnets com as tags `kubernetes.io/role/elb=1` (públicas) / `kubernetes.io/role/internal-elb=1` (privadas). No **EKS Auto Mode**, crie uma `IngressClass` com `controller: eks.amazonaws.com/alb` (e um `IngressClassParams`), sem instalar nada.
> - `target-type: ip` registra os **IPs dos pods** direto no target group (funciona com Fargate e evita um salto extra pelo NodePort).
> - Alternativa: manter o **ingress-nginx** atrás de um NLB. Atenção: o projeto *ingress-nginx* da comunidade Kubernetes anunciou **aposentadoria** (fim da manutenção em março de 2026). Para projetos novos no EKS, prefira o ALB via AWS Load Balancer Controller ou uma implementação de **Gateway API**.

#### Persistent Volumes (PV)

O Persistent Volume (PV) é um recurso de armazenamento do cluster Kubernetes que abstrai o armazenamento físico por baixo. Ele pode ser provisionado manualmente ou dinamicamente e não depende do ciclo de vida dos Pods que o usam.

#### Persistent Volume Claims (PVC)

O Persistent Volume Claim (PVC) é uma solicitação de armazenamento feita por um usuário. Ele especifica o tamanho, o modo de acesso e a StorageClass desejada. O Kubernetes então vincula o PVC a um PV disponível que atenda a essas especificações.

> **💡 Complemento:** no EKS, o provisionamento dinâmico de PVs em **EBS** exige o add-on **Amazon EBS CSI Driver** (já incluso no Auto Mode) e uma `StorageClass` (ex.: `gp3`). Um volume EBS fica preso a **uma AZ** e só aceita `ReadWriteOnce`. Para `ReadWriteMany`, use **EFS** (EFS CSI Driver). Em produção, bancos de dados costumam sair do cluster e ir para **RDS/Aurora**.

#### ConfigMaps

O ConfigMap armazena dados de configuração que os Pods consomem como variáveis de ambiente, arquivos de configuração ou volumes montados. É ideal para informações não sensíveis que podem ser atualizadas com facilidade.

#### Secrets

Os Secrets armazenam informações sensíveis, como credenciais e tokens. Diferente dos ConfigMaps, os Secrets são codificados em base64 e foram projetados para proteger informações confidenciais.

> **💡 Complemento (precisão importante):** **base64 é codificação, não criptografia.** Qualquer pessoa com permissão de `get secret` lê o valor. A proteção real vem de: (1) **RBAC** restringindo o acesso a Secrets; (2) **criptografia envelope com KMS** no etcd (no EKS, as versões atuais já criptografam *todos* os objetos da API com KMS por padrão, e você ainda pode usar uma chave KMS própria); (3) **não versionar** Secrets em YAML no Git. Para isso existem o **External Secrets Operator** e o **Secrets Store CSI Driver** com o **AWS Secrets Manager**, descritos na seção do Tech Challenge.

#### Horizontal Pod Autoscaler (HPA)

O Horizontal Pod Autoscaler ajusta o número de réplicas de um Pod em um Deployment, ReplicaSet ou StatefulSet com base em métricas de desempenho, como uso de CPU, memória ou métricas personalizadas.

> **💡 Complemento — HPA no EKS:**
>
> O HPA precisa do **metrics-server** (disponível como add-on do EKS ou via Helm). Sem ele, `kubectl get hpa` mostra `<unknown>` nos targets.
>
> ```yaml
> apiVersion: autoscaling/v2
> kind: HorizontalPodAutoscaler
> metadata:
>   name: users-api
>   namespace: fcg
> spec:
>   scaleTargetRef:
>     apiVersion: apps/v1
>     kind: Deployment
>     name: users-api
>   minReplicas: 2
>   maxReplicas: 6
>   metrics:
>     - type: Resource
>       resource:
>         name: cpu
>         target:
>           type: Utilization
>           averageUtilization: 70
> ```
>
> Para testar (como no vídeo da aula), gere carga, por exemplo com `kubectl run -it --rm load --image=busybox -- /bin/sh -c "while true; do wget -q -O- http://users-api.fcg:8080/; done"`, e acompanhe com `kubectl get hpa -w`. O HPA escala **pods**. Se não houver espaço nos nodes, quem cria nodes novos é o **Cluster Autoscaler** ou o **Karpenter** (ou o Auto Mode).

#### Vertical Pod Autoscaler (VPA)

O Vertical Pod Autoscaler ajusta as solicitações e os limites de CPU e memória dos Pods com base no uso real observado durante a execução. É útil para que os Pods tenham os recursos adequados às suas necessidades.

> **💡 Complemento:** o VPA **não vem instalado** por padrão (é um componente do projeto *kubernetes/autoscaler*). Não combine VPA e HPA escalando pela **mesma métrica** (CPU/memória), porque eles entram em conflito. Um uso seguro é o VPA em modo `Off`/recomendação, só para descobrir bons valores de `requests`.

#### Kubernetes local com Minikube

Também é possível rodar o Kubernetes localmente. Antes de ir para o AWS EKS, podemos usar o **Minikube** para criar a estrutura de cluster na máquina local, simulando o ambiente da AWS. O Minikube cria um cluster Kubernetes local usando uma VM (máquina virtual) ou um contêiner, dependendo da configuração. Ele instala e configura todos os componentes essenciais do Kubernetes, incluindo kube-apiserver, kube-controller-manager, kube-scheduler e kubelet.

Com o minikube instalado, basta executar `minikube start`: a estrutura e o cluster são criados automaticamente e já é possível subir os deployments para teste local.

*Figura 1 - minikube start: terminal do WSL (Ubuntu) executando `minikube start` (minikube v1.33.1, driver Docker, container com 2 CPUs/2200 MB, Kubernetes v1.30.0 sobre Docker 26.1.1). Mostra a geração de certificados, o boot do control plane, a configuração de RBAC e do bridge CNI, os addons `storage-provisioner` e `default-storageclass` e, no fim, "Done! kubectl is now configured to use "minikube" cluster and "default" namespace by default". (Fonte: elaborado pelo autor, 2024)*

```bash
minikube start
```

Agora que você entendeu como o Kubernetes funciona e como testá-lo localmente, podemos avançar e criar nossa própria estrutura na AWS usando o EKS.

> **💡 Complemento — local x EKS:** no Minikube/kind/Docker Desktop, imagens locais (`fcg/users-api:1.0`) funcionam porque o node enxerga o cache do Docker local (ou via `minikube image load`). No EKS, os nodes **só conseguem fazer pull de um registry**: a imagem precisa estar no ECR (ou em outro registry acessível), e a role do node precisa da permissão `AmazonEC2ContainerRegistryReadOnly`. O `LoadBalancer` no Minikube precisa de `minikube tunnel`; no EKS ele cria um ELB real (e pago).

### O que você viu nesta aula?

Você viu como orquestrar containers com o **AWS EKS** e agora entende a complexidade do serviço e a diferença dele para o **AWS ECS**.

Também criamos nosso Cluster e Node e subimos uma aplicação seguindo boas práticas de arquitetura com EKS. A partir de agora, você consegue executar aplicações com esse serviço da AWS.

> **💡 Complemento — ECS x EKS:**
>
> | Critério | Amazon ECS | Amazon EKS |
> |---|---|---|
> | Orquestrador | Proprietário da AWS | Kubernetes upstream (CNCF), certificado |
> | Curva de aprendizado | Baixa | Alta (objetos K8s, RBAC, add-ons, controllers) |
> | Custo do control plane | **Gratuito** | **US$ 0,10/hora por cluster** (~US$ 73/mês) no suporte padrão; **US$ 0,60/hora** em suporte estendido |
> | Portabilidade | Presa à AWS | Manifestos/Helm portáveis entre nuvens e on-premises |
> | Ecossistema | Integrações AWS nativas | Todo o ecossistema CNCF (Helm, Argo CD, Prometheus, Karpenter, operators) |
> | Compute | Fargate, EC2, Managed Instances | Managed node groups, self-managed, Fargate, Auto Mode, Karpenter |
> | Identidade da app | Task role | EKS Pod Identity ou IRSA |
> | Exposição | Service + ALB/NLB (configurado no próprio service) | Service LoadBalancer / Ingress via AWS Load Balancer Controller |
> | Quando escolher | Times pequenos, só AWS, simplicidade | Requisito de Kubernetes, multi-cloud, padronização, ecossistema |
>
> **Atualizações importantes do EKS (desde a gravação da aula):**
>
> - **Access entries x `aws-auth` ConfigMap:** antes, dar acesso de usuários/roles IAM ao cluster exigia editar o ConfigMap `aws-auth` em `kube-system` (frágil: um erro de YAML podia trancar todo mundo fora do cluster). Hoje o recomendado é o modo de autenticação **`API`** com **access entries** (`aws eks create-access-entry` + `aws eks associate-access-policy`, com policies como `AmazonEKSClusterAdminPolicy`), gerenciadas pela API da AWS/IaC. O `aws-auth` está **depreciado**.
> - **EKS Pod Identity x IRSA:** o IRSA (IAM Roles for Service Accounts) exige um OIDC provider por cluster e uma trust policy amarrada ao issuer de cada cluster. O **EKS Pod Identity** (2023) usa o add-on `eks-pod-identity-agent` e *pod identity associations* (`aws eks create-pod-identity-association --namespace fcg --service-account users-api --role-arn ...`), com trust policy no principal `pods.eks.amazonaws.com`, reutilizável entre clusters. Para novos projetos, prefira Pod Identity. O IRSA continua suportado (e é necessário, por exemplo, em pods no Fargate).
> - **Versões do Kubernetes:** cada versão tem **14 meses de suporte padrão** e mais **12 meses de suporte estendido** (pago). Depois disso, o cluster é atualizado automaticamente. Ao criar o cluster, escolha uma versão recente em suporte padrão (consulte `aws eks describe-cluster-versions` ou a página *Kubernetes version lifecycle* do EKS) e planeje upgrades periódicos (control plane → add-ons → nodes).
> - **EKS Auto Mode:** descrito no Hands on. Simplifica muito o uso para quem não quer operar nodes e add-ons.

> **💡 Complemento — custos e como derrubar o ambiente (importante para não ter surpresa na fatura):**
>
> Valores aproximados em `us-east-1` (podem mudar; confira a página de preços):
>
> | Item | Custo aproximado |
> |---|---|
> | Control plane EKS | US$ 0,10/h (~US$ 73/mês), cobrado mesmo sem nenhum pod |
> | Nodes EC2 | Preço da instância (ex.: 2× `t3.medium` ≈ US$ 0,083/h total) + volumes EBS |
> | NAT Gateway | ~US$ 0,045/h **por NAT** + US$ 0,045/GB processado (o `eksctl` cria 1 por padrão; templates "HA" criam 1 por AZ) |
> | ALB / NLB | ~US$ 0,0225/h cada + LCU/NLCU por uso |
> | IPv4 público | US$ 0,005/h por IP público (nodes em subnet pública, NAT, LB) |
> | ECR | ~US$ 0,10/GB-mês armazenado + transferência para fora da região |
> | CloudWatch Logs | Ingestão e armazenamento de logs (container insights/control plane logs) |
>
> **Ordem para derrubar o ambiente:**
>
> ```bash
> # 1. Remover primeiro o que cria recursos AWS "por fora" do eksctl (LBs, volumes EBS)
> kubectl delete ingress --all -A
> kubectl delete svc --field-selector spec.type=LoadBalancer -A   # ou apague os Services LB manualmente
> kubectl delete pvc --all -A
>
> # 2. Remover o cluster (node groups, VPC e NAT criados pelo eksctl)
> eksctl delete cluster --name fcg-cluster --region us-east-1 --wait
>
> # 3. ECR (opcional) — apaga repositório e imagens
> aws ecr delete-repository --repository-name fcg/users-api --force --region us-east-1
>
> # ECS: zere e apague o service, depois o cluster
> aws ecs update-service --cluster fcg --service users-api --desired-count 0
> aws ecs delete-service --cluster fcg --service users-api --force
> aws ecs delete-cluster --cluster fcg
> ```
>
> Depois, confira no console: **EC2 > Load Balancers**, **Target Groups**, **Elastic IPs** não associados, **NAT Gateways**, **Volumes EBS** "available", **CloudWatch Log groups** e o **Cost Explorer/Billing**. Se você apagar o cluster antes dos Services `LoadBalancer`, o LB pode ficar órfão e travar a exclusão da VPC/stack do CloudFormation. Uma alternativa barata para estudo é manter só o ECR e recriar o cluster quando precisar (via IaC/eksctl), e configurar um **AWS Budget** com alerta.

### Pontos-chave

- O Kubernetes automatiza deploy, escala, balanceamento, atualizações sem downtime e auto-recuperação de containers.
- No **EKS**, a AWS gerencia o **control plane** (API Server, etcd, scheduler, controllers); você gerencia os worker nodes ou usa Fargate/Auto Mode.
- **Pod** é a menor unidade; o **Deployment** gerencia ReplicaSets e faz rolling update e rollback; StatefulSet e DaemonSet atendem casos com estado e por node.
- **Services** (ClusterIP, NodePort, LoadBalancer, ExternalName) dão um endereço estável aos pods; o **Ingress** roteia HTTP por host/path com TLS.
- **ConfigMaps** guardam configuração não sensível; **Secrets** guardam dados sensíveis, mas base64 não é criptografia.
- **HPA** escala réplicas por métricas (exige metrics-server e `requests`); **VPA** ajusta requests/limits.
- O **Minikube** permite testar manifestos localmente; no EKS, as imagens precisam vir de um registry como o ECR.
- Pontos atuais do EKS: access entries (no lugar do `aws-auth`), Pod Identity (no lugar do IRSA), Auto Mode e o ciclo de vida das versões; o cluster tem custo por hora, então derrube o ambiente quando não estiver usando.

### Referências da aula

- AWS. *O que é o Amazon EKS?* (2024). https://docs.aws.amazon.com/pt_br/eks/latest/userguide/what-is-eks.html
- KUBERNETES. *Visão Geral* (2024). https://kubernetes.io/pt-br/docs/concepts/overview/
- MINIKUBE. *Welcome!* (2024). https://minikube.sigs.k8s.io/docs/

Palavras-chave: Kubernetes, EKS, Minikube, Pods.

---

## Aplicação no Tech Challenge da Fase 4

O Tech Challenge da Fase 4 leva o **FIAP Cloud Games (FCG)** (Users, Catalog, Payments e Notifications APIs, além de RabbitMQ e Postgres) do Kubernetes local da fase 3 para a AWS. Os requisitos do enunciado se relacionam com estas aulas assim:

| Requisito do enunciado | Como atender | Aula |
|---|---|---|
| Cluster Kubernetes gerenciado | **Amazon EKS** (managed node groups ou Auto Mode) | 6 |
| Registry privado nativo | **Amazon ECR**, um repositório por microsserviço, com tags imutáveis + scan on push + lifecycle policy | 4 |
| Exposição via Load Balancer ou Ingress Controller | **Ingress `alb`** (AWS Load Balancer Controller/Auto Mode), que cria um único ALB para todas as APIs, ou Service `LoadBalancer` (NLB) | 6 |
| Deploy sem downtime pela pipeline | Deployment com **`RollingUpdate` (`maxUnavailable: 0`, `maxSurge: 1`) + readinessProbe**, com a pipeline atualizando a tag da imagem e aguardando `kubectl rollout status` | 6 |
| Secrets injetados com segurança | **Kubernetes Secrets** (mínimo) ou **AWS Secrets Manager** via **External Secrets Operator** ou **Secrets Store CSI Driver + ASCP** | 6 |

### O que muda dos manifestos da fase 3 para EKS + ECR

Os manifestos atuais (`k8s/20-users-api.yaml` etc.) usam `image: fcg/users-api:1.0` com `imagePullPolicy: IfNotPresent` e um Ingress `ingressClassName: nginx` com hosts `*.fcg.local`. No EKS:

1. **Imagem:** troque `fcg/users-api:1.0` pela URI do ECR, com a tag gerada pela pipeline:
   `image: <ACCOUNT_ID>.dkr.ecr.us-east-1.amazonaws.com/fcg/users-api:<git-sha>`.
   Os nodes fazem pull com a role do node (`AmazonEC2ContainerRegistryReadOnly`), sem `imagePullSecrets`. Com tags imutáveis, cada deploy usa uma tag nova, e o `imagePullPolicy: IfNotPresent` continua correto.
2. **Ingress:** `ingressClassName: nginx` → `ingressClassName: alb`, com as anotações `alb.ingress.kubernetes.io/scheme: internet-facing` e `target-type: ip`. Os hosts `*.fcg.local` só funcionam com entrada no `/etc/hosts` apontando para o IP do LB, o que não é prático porque o ALB tem um DNS dinâmico. Na nuvem, use **roteamento por path** (`/users`, `/catalog`...; pode exigir ajuste de rotas, porque o ALB não faz *rewrite*), ou hosts reais no Route 53 (`users.seudominio.com` → alias do ALB), ou ainda acesse com um header `Host` (`curl -H "Host: users.fcg.local" http://<dns-do-alb>/...`) para a demo. A anotação `nginx.ingress.kubernetes.io/use-regex` deixa de ter efeito.
3. **Estratégia de deploy:** adicione `strategy.rollingUpdate` com `maxUnavailable: 0` / `maxSurge: 1` e mantenha `replicas: 2` ou mais. As probes TCP atuais já ajudam. Um endpoint `/health` HTTP é melhor para o health check do ALB (sem ele, configure `alb.ingress.kubernetes.io/healthcheck-path` para uma rota que retorne 200).
4. **Recursos:** defina `resources.requests` (necessário para o HPA e para o scheduler) e, se usar HPA, instale o metrics-server.
5. **Secrets:** o `02-secret.yaml` não deve ir para o Git com valores reais. Opções:
   - **Kubernetes Secret** criado pela pipeline (`kubectl create secret generic fcg-secrets --from-literal=... --dry-run=client -o yaml | kubectl apply -f -`), com os valores vindos dos *secrets* do GitHub Actions.
   - **External Secrets Operator:** um `ClusterSecretStore` (provider `aws`, service `SecretsManager`, autenticado por Pod Identity/IRSA) e um `ExternalSecret` que sincroniza `fcg/users-db` → Secret `fcg-secrets`. **Os Deployments não mudam**, porque continuam lendo `secretKeyRef`.
   - **Secrets Store CSI Driver + AWS provider (ASCP):** um `SecretProviderClass` monta os segredos como arquivos no pod (e, opcionalmente, sincroniza para um Secret K8s).
6. **Dependências com estado:** RabbitMQ e Postgres podem continuar como pods no cluster (com PVC em EBS via EBS CSI Driver) para a demo. A alternativa gerenciada é **Amazon RDS for PostgreSQL** e **Amazon MQ for RabbitMQ**, com um Service `ExternalName` apontando para os endpoints e as connection strings vindas do Secrets Manager.
7. **Namespace/ConfigMap:** `00-namespace.yaml` e `01-configmap.yaml` seguem praticamente iguais.

Exemplo do trecho que muda no `20-users-api.yaml`:

```yaml
spec:
  replicas: 2
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxUnavailable: 0
      maxSurge: 1
  template:
    spec:
      containers:
        - name: users-api
          image: <ACCOUNT_ID>.dkr.ecr.us-east-1.amazonaws.com/fcg/users-api:<git-sha>
          imagePullPolicy: IfNotPresent
          resources:
            requests: { cpu: 100m, memory: 128Mi }
            limits:   { memory: 256Mi }
```

Esboço da pipeline (GitHub Actions), com deploy sem downtime:

```yaml
permissions:
  id-token: write   # OIDC com a AWS, sem access keys fixas
  contents: read
steps:
  - uses: actions/checkout@v4
  - uses: aws-actions/configure-aws-credentials@v4
    with:
      role-to-assume: arn:aws:iam::<ACCOUNT_ID>:role/github-deploy
      aws-region: us-east-1
  - id: ecr
    uses: aws-actions/amazon-ecr-login@v2
  - run: |
      IMAGE=${{ steps.ecr.outputs.registry }}/fcg/users-api:${GITHUB_SHA::7}
      docker build -t $IMAGE ./UsersAPI
      docker push $IMAGE
      aws eks update-kubeconfig --name fcg-cluster --region us-east-1
      kubectl -n fcg set image deployment/users-api users-api=$IMAGE
      kubectl -n fcg rollout status deployment/users-api --timeout=180s
```

A role do GitHub precisa de permissão de push no ECR e de um **access entry** no cluster com permissão no namespace `fcg`.

### Checklist prático de subida do ambiente

1. [ ] Configurar AWS CLI, `kubectl`, `eksctl` e `helm`; criar um **AWS Budget** com alerta.
2. [ ] Criar os repositórios ECR (`fcg/users-api`, `fcg/catalog-api`, `fcg/payments-api`, `fcg/notifications-api`) com **IMMUTABLE**, **scan on push** e **lifecycle policy**.
3. [ ] Fazer build e push das imagens com tag = SHA do commit (`linux/amd64` se o node for x86).
4. [ ] Criar o cluster EKS (`eksctl create cluster ... --managed`, ou Auto Mode) em uma versão de Kubernetes em suporte padrão; rodar `aws eks update-kubeconfig`.
5. [ ] Configurar o acesso por **access entries** (usuário de admin + role da pipeline).
6. [ ] Instalar os add-ons: metrics-server, EBS CSI Driver (se usar PVC), Pod Identity Agent e **AWS Load Balancer Controller** (dispensável no Auto Mode).
7. [ ] Criar os segredos no **Secrets Manager** e instalar o External Secrets Operator (ou criar o Secret K8s pela pipeline).
8. [ ] Aplicar os manifestos na ordem `00` → `01` → `02` → `10/11` → `2x` → `30` (Ingress `alb`).
9. [ ] Validar: `kubectl get pods -n fcg`, `kubectl get ingress -n fcg` (endereço do ALB), `curl` nas rotas e target groups *healthy*.
10. [ ] Testar o **rolling update**: alterar o código, rodar a pipeline e acompanhar `kubectl rollout status`, com um loop de `curl` em paralelo para mostrar zero erros.
11. [ ] (Opcional) Configurar o HPA e demonstrar a escala sob carga.
12. [ ] **Derrubar o ambiente** depois da gravação/demo (Ingress/Services LB → PVCs → `eksctl delete cluster` → conferir LBs, NAT, EIPs e volumes órfãos).

### Glossário

| Termo | Significado |
|---|---|
| **ECR** | Elastic Container Registry, o registry privado de imagens OCI/Docker da AWS |
| **ECS** | Elastic Container Service, o orquestrador de containers proprietário da AWS |
| **EKS** | Elastic Kubernetes Service, o Kubernetes gerenciado da AWS |
| **Fargate** | Compute serverless para containers (ECS/EKS), sem gerenciar instâncias |
| **Task Definition** | Especificação versionada dos containers de uma task no ECS |
| **Control plane** | API Server, etcd, scheduler e controllers; no EKS é gerenciado pela AWS |
| **Managed node group** | Grupo de instâncias EC2 worker gerenciado pelo EKS (AMI, upgrades, drain) |
| **EKS Auto Mode** | Modo em que a AWS gerencia nodes, load balancing, storage e rede do cluster |
| **AWS Load Balancer Controller** | Controller que cria ALB (Ingress) e NLB (Service) a partir de objetos K8s |
| **Access entry** | Mapeamento de um principal IAM para permissões no cluster EKS (substitui o `aws-auth`) |
| **Pod Identity / IRSA** | Formas de dar uma IAM role a pods via service account |
| **RollingUpdate** | Estratégia de Deployment que troca os pods aos poucos, sem downtime |
| **Readiness/Liveness probe** | Verificações que decidem se o pod recebe tráfego / se o container deve ser reiniciado |
| **HPA / VPA** | Autoscalers horizontal (réplicas) e vertical (requests/limits) de pods |
| **External Secrets Operator** | Operator que sincroniza segredos de um cofre externo (ex.: Secrets Manager) para Secrets K8s |
| **Secrets Store CSI Driver** | Driver que monta segredos externos como volume no pod |
| **Lifecycle policy** | Regra do ECR que expira imagens antigas ou sem tag automaticamente |
| **Tag immutability** | Configuração do ECR que impede sobrescrever uma tag já publicada |
