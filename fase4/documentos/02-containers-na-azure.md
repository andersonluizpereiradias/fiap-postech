# 2. Containers na Azure: Docker, ACR, ACI, Web App e Container Apps

> **Disciplina de origem:** Azure DevOps — Pós-Tech FIAP, Arquitetura de Sistemas .NET, Fase 4.
>
> **Aulas cobertas neste documento:**
>
> - Aula 5 - Conceitos básicos de Docker
> - Aula 6 - Azure Container Registry (ACR)
> - Aula 7 - Azure Container Instance (ACI)
> - Aula 8 - Web App (Azure Web App for Containers)
> - Aula 9 - Azure Container Apps
>
> O conteúdo das aulas foi reproduzido a partir dos PDFs oficiais e reorganizado em Markdown. Os blocos
> marcados com **💡 Complemento** são acréscimos de estudo (não fazem parte do material original).

---

## Aula 5 - Conceitos básicos de Docker

### O que vem por aí?

Nesta aula, você aprenderá o que são containers, qual sua função e como eles ajudarão a resolver problemas com
recursos do computador, como CPU, memória RAM, disco etc.

Você também aprenderá como instalar o subsistema Linux no Windows, o WSL, e suas versões e distribuições (Ubuntu,
Debian etc.), além de como instalar corretamente o Docker, o que é Docker, como ele funciona e quais vantagens
teremos em usá-lo. Por fim, executaremos nosso primeiro container.

### Hands on

Nesta primeira aula, faremos a instalação do WSL via PowerShell no Windows; depois, com o ambiente Linux rodando,
faremos a instalação do Docker Desktop e a configuração para que a integração com o WSL seja feita. É no ambiente
Linux que executaremos os comandos relacionados ao Docker.

Por fim, executaremos alguns comandos básicos de Docker para entender um pouco sobre sua estrutura e como ela
funciona, além de executar nosso primeiro container.

> **💡 Complemento:** o passo a passo de instalação é mostrado no vídeo; o PDF não traz os comandos. Um roteiro
> mínimo equivalente, conforme a documentação da Microsoft e do Docker:
>
> ```powershell
> # PowerShell como administrador: instala o WSL 2 com a distribuição padrão (Ubuntu)
> wsl --install
> # lista distribuições disponíveis / instala outra
> wsl --list --online
> wsl --install -d Debian
> # confere a versão (deve ser 2)
> wsl -l -v
> ```
>
> Depois, instale o Docker Desktop marcando o backend WSL 2 e habilite a integração com a distro em
> *Settings > Resources > WSL integration*. No terminal Linux:
>
> ```bash
> docker version            # cliente e engine respondendo
> docker run hello-world    # primeiro container
> docker ps -a              # lista containers (inclusive parados)
> docker images             # lista imagens locais
> docker run -d -p 8080:80 --name web nginx   # container em segundo plano, porta 8080 do host -> 80
> docker logs web
> docker stop web && docker rm web
> ```

### Saiba mais

#### Origem do Docker e o kernel Linux

O Docker foi lançado em 2013 pela empresa dotCloud, e é uma ferramenta Open Source que foi criada com o intuito de
melhorar o isolamento e o uso de recursos, além de rodar aplicações sem a necessidade de uma interface gráfica se
comparado com uma VM (Virtual Machine = Máquina Virtual). Sua existência só foi possível graças à possibilidade de
isolar processos e à virtualização presentes no kernel do Linux.

*Figura 1 - Kernel Linux (Fonte: Josh, 2015): diagrama em camadas — "Applications" no topo, "Kernel" no meio e,
abaixo, "CPU", "Memory" e "Devices", com setas indicando que o kernel intermedeia a comunicação entre aplicações e
hardware.*

Por sua vez, o Kernel Linux é o principal componente de um sistema operacional Linux: a interface central se
comunica entre o hardware e seus processos, controlando todas as principais funções e sendo responsável por
gerenciar os recursos com eficiência. Em tradução livre, kernel significa núcleo.

As principais funções do kernel incluem gerenciar memória, processos, drivers, chamadas do sistema e segurança.
Junto do kernel temos duas outras tecnologias que fazem com que o uso dos containers seja isolado um dos outros, que
se chamam **Cgroups** e **Namespaces**.

#### Cgroups

Os Cgroups são responsáveis por permitir definir limites no uso de recursos em processos Linux. Com eles, podemos
estabelecer o quanto de CPU um determinado processo pode usar, priorizando os que forem mais importantes ou
definidos no Cgroups. Também é possível colocar limites no uso dos recursos como CPU e memória, por exemplo,
mantendo o controle de quais processos podem/devem ser reiniciados, interrompidos ou congelados com um único
comando. Isso serve para controlar processos em execução em um container e esta é uma tecnologia essencial para o
funcionamento correto e sem gargalos de um container.

#### Namespaces

Já Namespaces é uma tecnologia que permite criar e lidar com diferentes cenários em um mesmo sistema, permitindo
analisar propriedades globais diferentes e isoladas em cada contexto. O container tem um ambiente isolado similar ao
de uma VM, mas pode ter containers diferentes com aplicações diferentes rodando em paralelo em um mesmo servidor.
Os Namespaces são responsáveis por criar esses isolamentos de forma transparente e lógica, sendo que cada container
pode ter um conjunto de usuários, rede diferente, disco e assim por diante.

Dessa forma, caso algum dos containers que esteja rodando quebrar por algum motivo, como por exemplo usar 100% de
CPU, os demais containers rodando em paralelo não terão o mesmo problema de CPU. Isso garante que aplicações
diferentes e que não se conversam não sejam afetadas por conta do container "ruim".

Imagine um cargueiro carregando vários containers: caso algum deles venha a cair no mar, os demais não serão
afetados, nem mesmo o cargueiro que representa o host em que os containers estão rodando. A figura 2 retrata
exatamente como eles são.

*Figura 2 - Containers (Fonte: Google Imagens, 2024): foto de um navio cargueiro carregado de containers coloridos.*

> **💡 Complemento:** a garantia "um container a 100% de CPU não afeta os demais" só vale se houver **limites
> configurados** (`docker run --cpus=1 --memory=512m ...`, ou `resources.limits` no Kubernetes). Sem limites, um
> container pode, sim, disputar CPU/memória do host com os outros. Além disso, containers **compartilham o mesmo
> kernel** do host — o isolamento é mais leve (e mais fraco do ponto de vista de segurança) que o de uma VM.

#### VMs x Containers

A diferença entre VMs e containers são poucas, mas mudam completamente o modo de execução e isolamento das
aplicações. As figuras 3 e 4 retratam um pouco esse cenário.

*Figura 3 - Diferenças entre VMs e Containers (Fonte: Elaborado pelo autor, 2024): à esquerda, "Virtual Machines" —
App 1/2/3, cada uma com Bins/Lib e Guest OS próprios, sobre Hypervisor, Operating System e Infrastructure; à direita,
"Containers" — App 1/2/3 com Bins/Lib, sobre um único Container Engine, Operating System e Infrastructure (sem Guest
OS por aplicação).*

*Figura 4 - Ilustrando o conceito de containers (Fonte: Elaborado pelo autor, 2024): a mesma pilha de containers, à
direita "materializada": apps em Node, .NET e Python sobre o Docker (Container Engine), sobre Linux (Operating
System) e infraestrutura.*

| Aspecto | Máquina Virtual | Container |
|---|---|---|
| Sistema operacional | Um Guest OS completo por VM | Compartilha o kernel do host |
| Camada de virtualização | Hypervisor | Container Engine (ex.: Docker) |
| Isolamento | Por hardware virtualizado | Por processos (Namespaces + Cgroups) |
| Peso / inicialização | Gigabytes, minutos | Megabytes, segundos |

> **💡 Complemento:** a tabela acima é uma síntese das figuras 3 e 4 (as ordens de grandeza de tamanho/tempo são
> típicas, não absolutas). No Windows/macOS, o Docker Desktop roda os containers Linux dentro de uma VM leve
> (no Windows, a do WSL 2), porque containers Linux precisam de um kernel Linux.

#### Imagens

O Docker tem algumas funcionalidades vitais para criar e rodar um container e a primeira são as imagens. As imagens
são responsáveis por empacotar o sistema operacional, dependências, portas expostas, variáveis de ambiente...
Existem milhares de imagens personalizadas já criadas, além de ser possível criar sua própria imagem e compartilhar
com a comunidade.

Imagine que para rodar uma aplicação .NET você precise instalar a versão do .NET compatível com seu código, como
instalar as dependências pelo NuGet, por exemplo, aquela configuração padrão que toda aplicação .NET precisa ter
pré-instalada para poder funcionar e rodar o código criado. As imagens personalizadas têm esse papel na comunidade.

> **💡 Complemento:** imagem x container — a **imagem** é o artefato imutável (camadas somente leitura); o
> **container** é uma instância em execução dessa imagem, com uma camada gravável por cima. Uma imagem pode gerar
> vários containers. Tecnicamente a imagem não traz um "sistema operacional completo", e sim o *userland*
> (bibliotecas e binários) de uma distribuição; o kernel é sempre o do host.

#### Docker Hub

O Docker Hub é basicamente um GitHub voltado para imagens Docker; assim como o GitHub tem repositórios públicos que
qualquer pessoa consegue clonar, fazer o fork e usar de fato o código que outra pessoa criou, o Docker Hub funciona
de maneira bem similar. Nele encontraremos imagens oficiais e imagens não oficiais (criadas pela comunidade), seja
para ajudar outras pessoas ou até mesmo para benefício próprio, como meio de salvar as imagens em um local seguro
(privado). Podemos utilizar essas imagens fazendo o Pull por meio da URL e tag delas.

> **💡 Complemento:** as imagens oficiais da Microsoft para .NET **não** ficam no Docker Hub, e sim no Microsoft
> Artifact Registry (`mcr.microsoft.com`), como se vê nos Dockerfiles abaixo. O Docker Hub aplica limites de taxa
> (*rate limits*) para pulls anônimos/gratuitos — em pipelines de CI isso causa falhas intermitentes; por isso, em
> produção, é comum espelhar imagens base em um registry privado (ACR, ECR).

#### O que são as tags?

As tags são utilizadas para definir uma versão da imagem criada, como forma de controle, atualização e organização,
e fazem melhorias constantes nas imagens, seja para corrigir bugs, melhorar o processo ou até mesmo correções de
segurança. É bem parecido com o GitHub, não é mesmo?

> **💡 Complemento (armadilha comum):** `latest` é só um nome de tag padrão, **não** significa "a mais recente"
> nem é atualizada automaticamente. Em produção, use tags **imutáveis e rastreáveis** (versão SemVer, SHA do commit,
> número do build) e, se possível, referencie por digest (`imagem@sha256:...`). Assim, um rollback é só voltar a tag
> anterior e você sabe exatamente qual código está rodando.

#### Dockerfile

Para que essas imagens sejam criadas de forma personalizada, é preciso declarar os comandos, instalações, variáveis,
portas etc. Isso é feito por meio de um arquivo chamado Dockerfile (o nome do arquivo já é sua extensão) e é nele
que as instruções devem ser feitas. Veremos mais sobre isso na próxima aula. Assim, as figuras 5 e 6 ilustram um
Dockerfile básico e outro avançado.

**Dockerfile simples** (Figura 5):

```dockerfile
FROM mcr.microsoft.com/dotnet/aspnet:8.0

WORKDIR /App

COPY . ./

RUN dotnet restore

RUN dotnet publish -c Release -o out

ENTRYPOINT ["dotnet", "DotNet.Docker.dll"]
```

> **💡 Complemento (atenção):** este Dockerfile "simples", como está, **não funcionaria**: a imagem
> `dotnet/aspnet` contém apenas o *runtime* do ASP.NET Core, sem o SDK — logo `dotnet restore` e `dotnet publish`
> falham. Além disso, o `publish` grava em `/App/out`, mas o `ENTRYPOINT` procura a DLL em `/App`. Para um estágio
> único, a base teria de ser `dotnet/sdk:8.0` (gerando uma imagem grande, com SDK e código-fonte em produção). É
> justamente esse problema que o multi-stage resolve.

**Dockerfile multistage** (Figura 6):

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

> **💡 Complemento (boas práticas de Dockerfile .NET):**
>
> - **Multi-stage**: o estágio `build-env` usa o SDK (~800 MB) e só o resultado do `publish` vai para o estágio
>   final com o runtime `aspnet` (~220 MB). Código-fonte e ferramentas de build não chegam à imagem de produção.
> - **Cache de camadas**: copie primeiro só o(s) `.csproj` e rode `dotnet restore`; depois copie o restante. Assim,
>   mudar uma linha de código não invalida o cache do restore:
>
>   ```dockerfile
>   FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build
>   WORKDIR /src
>   COPY ["MeuServico.Api/MeuServico.Api.csproj", "MeuServico.Api/"]
>   RUN dotnet restore "MeuServico.Api/MeuServico.Api.csproj"
>   COPY . .
>   RUN dotnet publish "MeuServico.Api/MeuServico.Api.csproj" -c Release -o /app/publish /p:UseAppHost=false
>
>   FROM mcr.microsoft.com/dotnet/aspnet:8.0 AS final
>   WORKDIR /app
>   COPY --from=build /app/publish .
>   USER $APP_UID
>   EXPOSE 8080
>   ENTRYPOINT ["dotnet", "MeuServico.Api.dll"]
>   ```
>
> - **Usuário não-root**: a partir do .NET 8, as imagens oficiais já trazem o usuário `app` (variável `APP_UID`) e
>   escutam por padrão na porta **8080** (`ASPNETCORE_HTTP_PORTS=8080`), justamente para permitir rodar sem root.
> - **Imagens menores**: variantes `-alpine`, `-jammy-chiseled`/`-noble-chiseled` (sem shell nem gerenciador de
>   pacotes) reduzem tamanho e superfície de ataque.
> - **`.dockerignore`**: sempre crie um, para que `COPY . .` não leve `bin/`, `obj/`, `.git/`, `.vs/`, segredos
>   locais (`appsettings.Development.json`, `.env`) para o contexto de build.
>
>   ```text
>   **/bin
>   **/obj
>   **/.vs
>   **/.git
>   **/*.user
>   **/.env
>   **/node_modules
>   ```

### O que você viu nesta aula?

Nesta aula, você viu como os containers funcionam, a distribuição Linux e a possibilidade de usá-la no Windows por
meio do WSL. Também aprendeu sobre o Docker e seus principais comandos.

Além disso, você criou o primeiro container e entendeu como ele funciona e qual seu papel. O básico sobre esses
temas está disponível em texto, vídeo e imagens: aproveitem o conteúdo, pois as próximas aulas serão mais hands on
do que essa.

### Referências da aula

- JOSH. *Demystifying The Linux Kernel*. 2015. <https://digilent.com/blog/demystifiying-the-linux-kernel/>
- MICROSOFT. *Como instalar o Linux no Windows com o WSL*. 2023. <https://learn.microsoft.com/pt-br/windows/wsl/install>
- RED HAT. *O que é o kernel Linux*. 2019. <https://www.redhat.com/pt-br/topics/linux/what-is-the-linux-kernel>
- ROGÉRIO, P. *Containers: o que são namespaces e cgroups*. 2021. <https://etcd.dev/2021/09/20/containers-o-que-sao-namespaces-e-cgroups/>

Palavras-chave: Docker. Container. Linux. WSL.

### Pontos-chave

- Docker (2013, dotCloud) depende de recursos do kernel Linux: **Namespaces** isolam (rede, usuários, processos,
  disco) e **Cgroups** limitam o consumo (CPU, memória).
- Containers compartilham o kernel do host e não têm Guest OS: são mais leves e rápidos que VMs, com isolamento
  mais fraco.
- No Windows, o Docker roda containers Linux via **WSL 2**, com a integração habilitada no Docker Desktop.
- **Imagem** = pacote imutável com dependências, portas e variáveis; **container** = instância em execução.
- Docker Hub funciona como um "GitHub de imagens" (oficiais e da comunidade, públicas ou privadas); imagens .NET
  oficiais vêm do `mcr.microsoft.com`.
- **Tags** versionam imagens; evite depender de `latest` em produção.
- O **Dockerfile** descreve a imagem; o **multi-stage** separa build (SDK) de execução (runtime), deixando a
  imagem final menor e mais segura.

---

## Aula 6 - Azure Container Registry (ACR)

### O que vem por aí?

Nesta aula, vocês aprenderão sobre o Azure Container Registry, como usá-lo da forma correta, criar um repositório
de imagens e enviar para o Azure a primeira imagem criada localmente, além de subir uma imagem por meio do Azure
Pipelines.

### Hands on

Nesta aula, realizaremos a criação de uma imagem Docker por meio do Azure Pipelines de forma automatizada, além de
enviá-la para o Azure Container Registry.

> **💡 Complemento:** o ACR é o *registry* privado de imagens OCI gerenciado da Azure (equivalente ao **Amazon
> ECR** na AWS). Cada registry tem um *login server* `<nome>.azurecr.io` e contém **repositórios** (um por
> imagem, ex.: `fiap-azure`), que por sua vez contêm **tags**. Há três SKUs: *Basic*, *Standard* e *Premium*
> (este último com geo-replicação, Private Link e mais throughput). O envio manual de uma imagem local — feito no
> vídeo — segue este fluxo:
>
> ```bash
> az login
> az acr create -g fiap-app -n fiapregistry --sku Basic
> az acr login -n fiapregistry
> docker build -t fiapregistry.azurecr.io/dotnet-teste:latest .
> docker push fiapregistry.azurecr.io/dotnet-teste:latest
> az acr repository list -n fiapregistry -o table
> ```
>
> (nomes `fiapregistry`/`fiap-app`/`dotnet-teste` iguais aos que aparecem nos prints da aula; o comando
> `az acr build` também permite construir a imagem na própria nuvem, via ACR Tasks, sem Docker local.)

### Saiba mais

Nesta aula, faremos o push da imagem a partir do Azure Pipelines e do código hospedado no Azure Repos.

Dessa maneira, todo novo push no Repos iniciará a pipeline que criará a imagem docker e a enviará para o Azure
Container Registry de forma automática, para que não nos preocupemos com essa entrega. É necessário ter Azure Repos,
Azure Pipelines e Azure Container Registry para executar os passos a seguir.

Vamos partir da premissa de que o Repos e o Pipelines já estão criados a partir de aulas anteriores. Então, agora
precisamos editar a pipeline adicionando o stage que faz o build da imagem e em seguida envia para o ACR.

#### Dockerfile da aplicação

O Dockerfile deve estar parecido com a figura 1.

**Figura 1 - Dockerfile dotnet:**

```dockerfile
FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build-env

WORKDIR /App

COPY . ./

ENV NODE_VERSION=16.13.0
RUN apt install -y curl
RUN curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash
ENV NVM_DIR=/root/.nvm
RUN . "$NVM_DIR/nvm.sh" && nvm install ${NODE_VERSION}
RUN . "$NVM_DIR/nvm.sh" && nvm use v${NODE_VERSION}
RUN . "$NVM_DIR/nvm.sh" && nvm alias default v${NODE_VERSION}
ENV PATH="/root/.nvm/versions/node/v${NODE_VERSION}/bin/:${PATH}"
RUN node --version
RUN npm --version

RUN npm install

RUN dotnet restore

RUN dotnet publish -c Release -o out

FROM mcr.microsoft.com/dotnet/aspnet:8.0

WORKDIR /App

COPY --from=build-env /App/out .

ENTRYPOINT ["dotnet", "DotNet.Docker.dll"]
```

> **💡 Complemento:** o Node.js é instalado (via `nvm`) apenas no estágio de build porque o projeto compila assets
> front-end (no log da pipeline aparecem os passos *Run npm install* e *Compile Sass assets*). Graças ao
> multi-stage, Node e `node_modules` não vão para a imagem final. Observações:
>
> - `apt install` sem um `apt-get update` antes pode falhar por índice de pacotes vazio/desatualizado; a forma
>   usual é `RUN apt-get update && apt-get install -y --no-install-recommends curl && rm -rf /var/lib/apt/lists/*`.
> - Node 16 está fora de suporte (EOL em set/2023) — **atualização**: prefira uma versão LTS vigente.
> - Uma alternativa mais limpa é um estágio separado `FROM node:<lts> AS assets` que compila o front-end e cujo
>   resultado é copiado com `COPY --from=assets`.

#### Stage de build existente

Em "Pipelines", edite a pipeline existente; o passo que envia a imagem para o ACR deve estar nos stages de deploy.
É possível inseri-lo em todos os stages relacionados a deploy ou somente em um específico. Neste caso, vamos
adicioná-lo ao stage Dev.

Antes da inserção do passo que envia a imagem, o stage fica da seguinte forma (figura 2):

*Figura 2 - Stage Build: editor de YAML do Azure Pipelines (repositório `fiap`, branch `azure-pipelines`, arquivo
`azure-pipelines.yml`), linhas 43 a 67.*

```yaml
    - task: DotNetCoreCLI@2
      displayName: 'Restore project dependencies'
      inputs:
        command: 'restore'
        projects: '**/*.csproj'

    - task: DotNetCoreCLI@2
      displayName: 'Build the project - $(buildConfiguration)'
      inputs:
        command: 'build'
        arguments: '--no-restore --configuration $(buildConfiguration)'
        projects: '**/*.csproj'

    - task: DotNetCoreCLI@2
      displayName: 'Publish the project - $(buildConfiguration)'
      inputs:
        command: 'publish'
        projects: '**/*.csproj'
        publishWebProjects: false
        arguments: '--no-build --configuration $(buildConfiguration) --output $(Build.ArtifactStagingDirectory)/$(buildConfiguration)'
        zipAfterPublish: true

    - publish: '$(Build.ArtifactStagingDirectory)'
      artifact: drop
```

#### Montando a task Docker@2

Logo abaixo da linha 66 da figura 2, depois de `artifact`, devemos inserir o campo `- task` e apontar a task usada
para o step em questão. Neste caso temos **`Docker@2`**, responsável por utilizar o módulo de Docker para executar
comandos relacionados a ele. Em seguida, podemos adicionar um `displayName` para identificar na execução da
pipeline; vamos nomeá-lo como "Build and Push an image to container registry". Uma descrição objetiva ajuda quem
está lendo o arquivo a identificar o que de fato a task fará.

Depois temos os `inputs`, comandos e informações necessárias para que a imagem vá para a cloud correta, o
repositório correto e com o nome de imagem correto:

1. **`command`** — o comando da task que será empregado. Nesse caso, faremos o build e o push da imagem; então
   devemos setar `buildAndPush`. Dentre as opções possíveis, podemos usar uma da lista a seguir:

   *Figura 3 - Commands: dropdown "Command" da task Docker com as opções `buildAndPush` (selecionada), `build`,
   `push`, `login`, `logout`, `start` e `stop`.*

2. **`repository`** — aponta o nome do repositório em que a imagem ficará salva. Como esse campo pode mudar com o
   tempo, não devemos inserir o valor diretamente; podemos usar uma variável para isso. Dessa forma, uma variável
   pode ser apontada com `$(nome-variável)`, que terá somente o valor do nome do repositório. Nesta aula, vamos
   usar o nome `fiap-azure`, mas fique à vontade para utilizar o valor que faça mais sentido para você.

3. **`Dockerfile`** — campo que indicará onde o arquivo Dockerfile se encontra. Por padrão o arquivo costuma ficar
   na raiz do Repos, então podemos definir **`**/Dockerfile`**, apontando para raiz + nome do arquivo.

4. **`containerRegistry`** — o penúltimo comando está relacionado ao container registry criado; neste campo o valor
   deve ser coletado por meio de uma conexão com o Registry (Service Connection, descrita a seguir).

5. **`tags`** — por último temos o comando tags, que será responsável por inserir a tag correta que será usada no
   push. Ela organiza e identifica o repositório e registry usados.

#### Criando a Service Connection do tipo Docker Registry

1. Clique em **Project Settings**, no canto esquerdo inferior, e em seguida em **Service Connections**.
2. No canto superior direito, há a opção **New Service Connection**; selecione a opção **Docker Registry**.

   *Figura 4 - Service connections: Project Settings com "Service connections" destacado no menu Pipelines e o
   painel "New Azure service connection" com a opção "Docker Registry" marcada.*

3. Avançando, é necessário selecionar a opção **Azure Container Registry** em **Registry Type**.
4. Em **Authentication Type**, podemos escolher **Service Principal** e em seguida selecionar nossa
   subscription/conta da Azure. Isso abrirá uma tela de login da Microsoft para logar na conta e gerar o token de
   acesso.

   *Figura 5 - New Docker Registry: painel "New Docker Registry service connection" (Registry type = Azure
   Container Registry, Authentication Type = Service Principal, Subscription) ao lado da janela de login da
   Microsoft.*

5. Ao logar na conta, será necessário selecionar o ACR criado. Nesta aula, criamos o **fiapregistry**.
6. Em **Service Connection Name** devemos nomear essa Service Connection; ela será o identificador em nossas
   conexões e esse nome será utilizado no apontamento da pipeline a seguir.

   *Figura 6 - Service connections list: lista com "Azure subscription 1" e a nova conexão "fiapregistry".*

> **💡 Complemento (atualização):** o próprio print da aula mostra o aviso da Microsoft *"Convert your existing
> Azure Resource Manager service connections which use secrets to authenticate to leverage Workload identity
> federation"*. Hoje a recomendação para conexões com a Azure é **Workload Identity Federation (OIDC)**, que
> dispensa segredos de Service Principal com expiração. O conceito equivalente na AWS é a federação OIDC do
> provedor de CI (GitHub Actions, Azure DevOps) com uma IAM Role, em vez de access keys fixas.

#### Pipeline final

Voltando para Pipelines, vamos editar a existente, navegar até a task de Docker e inserir o Docker Registry Service
Connection criado anteriormente. Basta ir até a task, selecionar **Settings** e o **Service Connections**, neste
caso `fiapregistry`.

Se preferir, você pode pular a parte de Settings e escrever na pipeline o nome da service connection; isso já basta.
A task de build deve ficar dessa maneira (Figura 7 - Pipeline):

```yaml
- task: Docker@2
  displayName: Build and push an image to container registry
  inputs:
    containerRegistry: 'fiapregistry'
    repository: '$(imageRepository)'
    command: 'buildAndPush'
    Dockerfile: '**/Dockerfile'
    tags: '$(Build.BuildId)'
```

E a única variável setada foi a `imageRepository`, com o nome do repositório. O valor deve ser parecido com o da
figura 8 (Pipeline vars):

```yaml
variables:
  buildConfiguration: 'Release'
  releaseBranchName: 'release'
  imageRepository: 'fiap-azure'
```

Com a pipeline pronta, podemos salvá-la e executá-la para ver a saída.

*Figura 9 - Pipeline push ACR: execução "Jobs in run #20240124.9" com o job de build (Checkout, Use .NET SDK 8.x,
Run npm install, Compile Sass assets, Restore, Build, Publish, PublishPipelineArtifact) e o passo "Build and push an
image to container registry" concluído; o log mostra `docker images`, `docker push` para `***/fiap-azure:51` e o
`docker history` das camadas.*

O push da imagem foi feito corretamente. Voltando no Azure Container Registry/Repositórios, podemos notar um segundo
repositório chamado **fiap-azure** com a imagem enviada pelo Pipelines.

*Figura 10 - ACR Repo: no portal, a lista de repositórios mostra `dotnet-teste` e `fiap-azure`; no repositório
`fiap-azure` aparece a tag (rótulo) `51`, que é o `Build.BuildId` da execução.*

A partir de agora, com todo novo push o build será executado e uma nova imagem será enviada para o ACR.

> **💡 Complemento:**
>
> - Usar `$(Build.BuildId)` como tag é uma boa prática: cada build gera uma tag única e rastreável até a execução
>   da pipeline. Para ligar a imagem ao código, também é comum usar o SHA do commit (`$(Build.SourceVersion)`).
>   Se quiser também `latest`, a task aceita múltiplas tags (uma por linha no input `tags`).
> - Com `command: buildAndPush`, o input `arguments` da Docker@2 é **ignorado**; para passar `--build-arg` etc.,
>   separe em dois passos (`build` com `arguments` e depois `push`).
> - O ACR permite travar tags contra sobrescrita (`az acr repository update --image repo:tag --write-enabled false`);
>   no ECR o equivalente é ativar *tag immutability* no repositório.
> - Imagens acumulam custo de armazenamento: configure limpeza (ACR: `az acr run` com `acr purge` ou política de
>   retenção no Premium; ECR: *lifecycle policies*).

### O que você viu nesta aula?

Nesta aula, você viu como gerar uma imagem docker por meio do Azure Pipelines e enviá-la para o Azure Container
Registry de forma automática, sem a necessidade de executar manualmente o processo de criação de imagem e push para
o repositório criado no ACR.

### Referências da aula

- MICROSOFT. *Build and push Docker images to Azure Container Registry using Docker templates*. 2023. <https://learn.microsoft.com/en-us/azure/devops/pipelines/ecosystems/containers/acr-template?view=azure-devops>
- MICROSOFT. *Definir recursos no YAML*. 2023. <https://learn.microsoft.com/pt-br/azure/devops/pipelines/process/resources?view=azure-devops&tabs=schema#troubleshooting-authorization-for-a-yaml-pipeline>
- MICROSOFT. *Manage service connections*. 2022. <https://learn.microsoft.com/en-us/azure/devops/pipelines/library/service-endpoints?view=azure-devops&tabs=yaml>

Palavras-chave: Docker. ACR. Azure Pipelines.

### Pontos-chave

- O ACR é o registry privado gerenciado da Azure (`<nome>.azurecr.io`), organizado em repositórios e tags;
  equivale ao Amazon ECR.
- A pipeline usa a task **`Docker@2`** com `command: buildAndPush` para construir e publicar a imagem em um único
  passo.
- A autenticação da pipeline com o ACR é feita por uma **Service Connection** do tipo *Docker Registry* →
  *Azure Container Registry* (na aula, via Service Principal).
- Inputs essenciais: `containerRegistry` (nome da service connection), `repository`, `Dockerfile` (`**/Dockerfile`)
  e `tags`.
- O nome do repositório fica em variável (`imageRepository`) para não ficar fixo no código.
- A tag `$(Build.BuildId)` gera uma versão única por execução (ex.: tag `51` no repositório `fiap-azure`).
- Com o gatilho da pipeline, todo push no Azure Repos gera e publica automaticamente uma nova imagem.

---

## Aula 7 - Azure Container Instance (ACI)

### O que vem por aí?

Nesta aula, vocês aprenderão sobre o Azure Container Instance (ACI), como usá-lo da forma correta, criar uma task
para ser executada via Azure Pipelines e executar o deploy no Azure de forma automática.

### Hands on

Nesta aula, faremos a criação de um container por meio do Azure Pipelines, em forma de código na pipeline criada, e
executaremos um deploy no Azure.

> **💡 Complemento:** o ACI executa containers (ou *container groups*, vários containers que compartilham rede e
> ciclo de vida, parecido com um pod) **sem gerenciar VMs nem cluster**, com cobrança por segundo de vCPU/memória.
> Não há orquestração: nada de auto-scaling, rolling update, service discovery ou balanceamento entre réplicas. É
> ótimo para jobs, tarefas pontuais, ambientes de teste e demos. O paralelo mais próximo na AWS é uma *task* do
> ECS rodando em **Fargate** de forma avulsa.

### Saiba mais

Neste documento de aula, faremos o deploy de nossa aplicação a partir do Azure Pipelines e do código hospedado no
Azure Repos.

Dessa maneira, todo novo push no Repos iniciará a pipeline em que será criada a imagem docker e enviada para o Azure
Container Registry de forma automática, para que não nos preocupemos com essa entrega. Em seguida, se iniciará
nosso deploy no container criado. É necessário ter Azure Repos, Azure Pipelines e Azure Container Registry criados,
além do Azure Container Instance, para executar os passos a seguir.

Vamos partir da premissa de que o Repos, o Pipelines e o ACR já foram criados a partir de aulas feitas
anteriormente. Então, agora precisamos editar a pipeline adicionando o stage que faz o deploy da aplicação em um
container existente.

#### Configurando a task Azure CLI

1. Edite a pipeline existente e selecione a opção **Azure CLI** na lateral direita da tela, em **Tasks**.
2. Em **Azure Resource Manager Connection**, selecione a subscription utilizada para o deploy no Azure.
3. Em **Script Type**, selecione qual terminal você usará para executar o comando de deploy: **Powershell**.
4. Em **Script Location**, selecione **Inline Script**; ele abrirá um campo para inserirmos o comando necessário
   para o deploy. Então, copie o código a seguir. Podemos notar que temos diversas variáveis; isso ocorre para que
   você possa utilizar os valores relacionados à sua conta Azure e à sua aplicação criada.

```bash
'az container create -g $(resourceGroup)
--name $(appName)
--image $(acrLoginServer)/$(acrName):$(Build.BuildId)
--cpu 1
--memory 1
--registry-login-server $(acrLoginServer)
--registry-username $(acrName)
--registry-password $(acrPassword)
--ports 80'
```

> ** Todo script deve estar na mesma linha na pipeline; o código acima pula linhas para ficar legível.

#### Variáveis da pipeline

As variáveis devem ter os seguintes valores:

- **resourceGroup** = nome do resource group na Azure.
- **appName** = nome do container escolhido.
- **acrLoginServer** = endereço do repositório ACR criado; costuma terminar com `azurecr.io`.
- **acrName** = nome do repositório ACR (a tag da imagem é baseada no número do build executado).
- **acrUsername** = usuário criado no ACR.
- **acrPassword** = senha criada no ACR.

A figura 1 traz um modelo de como as variáveis devem se parecer.

*Figura 1 - Pipelines Variables: painel "Variables" da pipeline com os valores de exemplo abaixo.*

| Variável | Valor de exemplo (Figura 1) |
|---|---|
| acrLoginServer | `fiapregistry.azurecr.io` |
| acrName | `fiap-azure` |
| acrPassword | `123senhausadapeloACR` |
| acrUsername | `fiapregistry` |
| appName | `aci-fiap` |
| resourceGroup | `fiap-app` |

Para obter o valor das variáveis `acrUsername` e `acrPassword`, basta ir ao Azure, navegar até o serviço Azure
Container Registry, entrar no registry e em seguida em **Chaves de Acesso**. Pegue os valores **Nome de Usuário** e
**Password**, conforme a figura 2.

*Figura 2 - Chaves de acesso: no portal, `fiapregistry | Chaves de acesso` mostrando Nome do Registro, Servidor de
logon (`fiapregistry.azurecr.io`), a opção "Usuário administrador" habilitada, Nome de usuário e as senhas
`password`/`password2` (ocultas).*

> **💡 Complemento (segurança):**
>
> - As "Chaves de acesso" só aparecem com o **usuário administrador** do ACR habilitado (vem desabilitado por
>   padrão). A Microsoft o indica para testes; em produção, prefira **Managed Identity** (o ACI suporta pull com
>   identidade gerenciada) ou um Service Principal com papel `AcrPull` restrito.
> - Nunca deixe a senha em texto puro: marque a variável como **secret** (cadeado) ou use um *Variable Group*
>   vinculado ao **Azure Key Vault**.
> - **Armadilha no script da aula:** `--registry-username` recebe `$(acrName)` (`fiap-azure`, que é o nome do
>   repositório), enquanto o usuário real está em `$(acrUsername)` (`fiapregistry`). Para o login funcionar, use
>   `--registry-username $(acrUsername)` — a variável `acrUsername` foi definida justamente para isso.

#### Pipeline do stage Dev

Depois de inserir todos os valores nas variáveis, basta salvar e voltar para o código da pipeline. A pipeline deve
ficar parecida com a seguinte (Figura 3 - ACI Pipelines, linhas 74 a 103):

```yaml
- stage: 'Dev'
  displayName: 'Deploy to the dev environment'
  dependsOn: Build
  condition: succeeded()
  jobs:
  - deployment: Deploy
    pool: self-hosted
    environment: dev
    variables:
    - group: 'Release'
    strategy:
      runOnce:
        deploy:
          steps:
          - download: current
            artifact: drop
          - task: AzureCLI@2
            inputs:
              azureSubscription: 'Azure subscription 1(2e3695b2-20e9-45c7-83cb-f561c6151b28)'
              scriptType: 'ps'
              scriptLocation: 'inlineScript'
              inlineScript: 'az container create -g $(resourceGroup) \
              --name $(appName) \
              --image $(acrLoginServer)/$(acrName):$(Build.BuildId) \
              --cpu 1 \
              --memory 1 \
              --registry-login-server $(acrLoginServer) \
              --registry-username $(acrName) \
              --registry-password $(acrPassword) \
              --ports 80'
```

Neste exemplo, faremos o deploy no stage Dev e precisamos nos atentar a CPU, memória e portas, pois esses valores
estão fora de variáveis (poderiam estar). Lembre-se de alterar tais valores se necessário.

> **💡 Complemento (armadilhas):**
>
> - `\` é continuação de linha do **bash**; em PowerShell a continuação é o acento grave (`` ` ``). Por isso a aula
>   recomenda deixar o comando em uma única linha. Uma alternativa legível é `scriptType: 'bash'` com um bloco
>   `inlineScript: |` multilinha.
> - As imagens ASP.NET Core 8+ escutam por padrão na porta **8080**, não 80 (o próprio log da aula 6 mostra
>   `ASPNETCORE_HTTP_PORTS=8080`). Exponha `--ports 8080` ou defina `--environment-variables ASPNETCORE_HTTP_PORTS=80`.
> - Para acessar pela internet, o container group precisa de IP público: `--ip-address Public` e/ou
>   `--dns-name-label <nome>`.
> - Rodar `az container create` de novo com o mesmo nome atualiza o container group, mas algumas propriedades não
>   podem ser alteradas e exigem `az container delete` antes. Não há *rolling update*: há indisponibilidade
>   durante a troca.

#### Executando e validando

Agora podemos salvar a pipeline e fazer com que ela seja executada. Vamos observar os passos e por fim checar no
Azure se o container foi criado corretamente.

Nossa pipeline foi executada com sucesso, conforme a figura 4.

*Figura 4 - Stage Deploy: execução "Jobs in run #20240126.4" com o stage "Deploy to the dev environment" (Initialize
job, Download, AzureCLI, Finalize Job) concluído; o log da task AzureCLI mostra a versão do `azure-cli` (2.56.0) e o
`az login --service-principal`.*

Vamos ao Azure checar se nossa aplicação foi criada utilizando as informações corretas:

1. Na página inicial, pesquise por **Grupos de Recursos** e selecione essa opção.

   *Figura 5 - Grupos de recursos: busca do portal com "grupos de recursos" digitado e o serviço destacado.*

2. Selecione o grupo de recursos em que a aplicação foi criada e procure-a na lista. Baseada em nossas variáveis, a
   aplicação criada foi a **aci-fiap**.

   *Figura 6 - aci-fiap: grupo de recursos `fiap-app` (região Brazil South) listando `aci-fiap`, `acifiap`,
   `fiapaci` (Instâncias de contêiner) e `fiapregistry` (Registro de contêiner).*

3. Podemos checar as informações entrando em **Contêineres** e **Propriedades**.

   *Figura 7 - Container: `aci-fiap | Contêineres` mostrando o container `aci-fiap` com a imagem
   `fiapregistry.azurecr.io/fiap-azure:58`, estado "Waiting", 1 núcleo de CPU e 1 GiB de memória.*

Chegamos ao fim de mais uma aula; espero que vocês tenham gostado do conteúdo e aprendido com ele.

> **💡 Complemento:** o estado **Waiting** (visível na Figura 7) indica que o container ainda não está rodando —
> causas típicas são falha de pull (credencial errada, como a do item acima), imagem/tag inexistente ou o processo
> encerrando logo após iniciar. Diagnóstico: `az container show -g fiap-app -n aci-fiap --query instanceView`,
> `az container logs -g fiap-app -n aci-fiap` e a aba **Eventos** do portal.

### O que você viu nesta aula?

Nesta aula, você viu como fazer um deploy no Azure Container Instance a partir do Azure Pipelines de forma
automatizada, atualizando a aplicação a cada nova imagem criada por meio de alterações no código feitas pelo Azure
Repos.

### Referências da aula

- MICROSOFT. *Build and push Docker images to Azure Container Registry using Docker templates*. 2023. <https://learn.microsoft.com/en-us/azure/devops/pipelines/ecosystems/containers/acr-template?view=azure-devops>
- MICROSOFT. *Início Rápido: Implantar uma instância de contêiner no Azure usando o portal do Azure*. 2024. <https://learn.microsoft.com/pt-br/azure/container-instances/container-instances-quickstart-portal>
- MICROSOFT. *Limites de cota e disponibilidade de recursos para ACI*. 2024. <https://learn.microsoft.com/pt-br/azure/container-instances/container-instances-region-availability>

Palavras-chave: Docker. ACR. Azure Pipelines. ACI.

### Pontos-chave

- O ACI roda containers sob demanda, sem VM ou cluster para gerenciar, mas **sem orquestração** (sem auto-scaling
  nem rolling update).
- O deploy é feito no stage `Dev` com a task **`AzureCLI@2`** executando `az container create` em script inline.
- O comando recebe resource group, nome, imagem (`login-server/repositório:BuildId`), CPU, memória, credenciais do
  registry e portas.
- Valores sensíveis e de ambiente ficam em **variáveis da pipeline**; senhas devem ser secretas (ou vir do Key Vault).
- Credenciais vêm de *Chaves de acesso* do ACR (usuário admin); em produção, prefira Managed Identity/`AcrPull`.
- A validação é feita no portal: grupo de recursos → instância de contêiner → Contêineres/Propriedades/Eventos/Logs.
- Atenção à porta padrão 8080 do .NET 8+ e ao usuário correto (`acrUsername`) no `--registry-username`.

---

## Aula 8 - Web App

### O que vem por aí?

Nesta aula, vocês aprenderão uma forma de realizar o deploy de WebApp no Azure usando o Azure Pipelines. Isso
garante que toda alteração feita no repositório inicie o deploy da aplicação de forma automática.

### Hands on

Nesta aula, realizaremos a criação de uma pipeline no Azure Repos e executaremos um deploy no WebApp a partir do
Azure Pipelines em forma de código.

> **💡 Complemento:** o Web App é parte do **Azure App Service**, uma PaaS para aplicações web. Na modalidade
> **Web App for Containers**, ele roda a sua imagem Docker em um *App Service Plan* (você escolhe o tamanho e a
> quantidade de instâncias), oferecendo domínio `*.azurewebsites.net` com HTTPS, *deployment slots*, auto-scale
> por regras e logs integrados. Paralelos na AWS: **Elastic Beanstalk** (plataforma Docker) ou **App Runner**.

### Saiba mais

Nesta aula, faremos o deploy de nossa aplicação WebApp a partir do Azure Pipelines e do código hospedado no Azure
Repos.

Dessa maneira, todo novo push no Repos iniciará a pipeline em que será criada a imagem docker e enviada para o Azure
Container Registry de forma automática, para que não nos preocupemos com essa entrega. Em seguida, nosso deploy no
WebApp criado será iniciado. É necessário ter Azure Repos, Azure Pipelines e Azure Container Registry criados, além
do Azure WebApp, para executar os passos a seguir.

Vamos pegar o mesmo projeto do Azure Samples, uma aplicação .NET (o link do repositório está nas referências). Com o
repositório clonado no Azure Repos, mandaremos uma versão da imagem para o Azure Container Registry e em seguida
precisamos criar a aplicação WebApp no Azure como um **Aplicativo Web**, assim como na aula em vídeo.

A diferença é que dessa vez devemos selecionar a opção **Contêiner** do Docker e, na aba **Docker**, apontar para o
repositório do ACR e a versão da imagem. Com isso criado e certo, vamos conceber a pipeline referente ao WebApp.

#### Criando a pipeline

1. Vá até **Pipelines** e selecione **Create Pipeline**.
2. Selecione **Azure Repos Git** e, por fim, o repositório.
3. Para configurar a pipeline, expanda as opções e selecione **ASP.NET Core**.

   *Figura 1 - Configure Pipeline: lista de templates (Docker build, Docker build and push to ACR, Deploy to Azure
   Kubernetes Service, Starter pipeline, Existing Azure Pipelines YAML file, .NET Core Function App, .NET Desktop,
   Android, Ant, ASP.NET, ASP.NET Core) com "ASP.NET Core" destacado.*

4. Com a pipeline aberta, selecione a opção **Show Assistant**.

   *Figura 2 - Pipeline Assistant: tela "Review your pipeline YAML" do repositório `fiap-webapp` com o botão "Show
   assistant" destacado e o YAML gerado pelo template:*

   ```yaml
   # ASP.NET Core
   # Build and test ASP.NET Core projects targeting .NET Core.
   # Add steps that run tests, create a NuGet package, deploy, and more:
   # https://docs.microsoft.com/azure/devops/pipelines/languages/dotnet-core

   trigger:
   - master

   pool:
     vmImage: ubuntu-latest

   variables:
     buildConfiguration: 'Release'

   steps:
   - script: dotnet build --configuration $(buildConfiguration)
     displayName: 'dotnet build $(buildConfiguration)'
   ```

5. Procure na lista a opção **Azure Web App for Containers**.

#### Service Connection do tipo Azure Resource Manager

Se não encontrar a subscription, será necessário conectar na conta antes de avançar. Para isso, vá em **Project
Settings**, no canto esquerdo inferior da tela, clique em **Service Connections**, em **Create Service Connection** e
em **Azure Resource Manager**, conforme a figura 3.

*Figura 3 - Service Connections: Project Settings do projeto `fiap-webapp` com "Service connections" destacado e o
painel "New service connection" com "Azure Resource Manager" selecionado.*

Preencha com as informações necessárias que aparecerão na tela e, se o ID da Subscription da Azure for pedido, basta
ir ao Azure: na tela inicial, em pesquisar, digite **Assinaturas**, selecione a primeira opção e colete as
informações como **ID** e **Nome da Assinatura**. Volte à pipeline e preencha os campos corretos.

#### Configurando a task Azure Web App for Containers

De volta à pipeline, vamos selecionar a subscription da lista e inserir o nome do **App Name** como foi criado no
Azure via painel. Em seguida, aponte uma imagem do Azure Container Registry; se quiser que o processo de build e
envio da imagem seja feito por meio do Azure Pipelines, basta seguir a aula sobre o Azure Container Registry (Aula
6), onde explicamos passo a passo como criar a pipeline para executar o build e o envio da imagem para o ACR.

Depois de pronta, a pipeline deve ficar parecida com a figura 4.

*Figura 4 - Pipeline: YAML do `fiap-webapp` à esquerda e, à direita, o assistente "Azure Web App for Containers"
preenchido (Azure subscription = `Azure`, App name = `pipe-web`, Image name =
`fiapregistry.azurecr.io/webapp-dotnet:latest`, Configuration File e Startup command vazios).*

```yaml
# ASP.NET Core

# Build and test ASP.NET Core projects targeting .NET Core.
# Add steps that run tests, create a NuGet package, deploy, and more:
# https://docs.microsoft.com/azure/devops/pipelines/languages/dotnet-core

trigger:
- master

pool: self-hosted

variables:
  buildConfiguration: 'Release'

steps:

- task: AzureWebAppContainer@1
  inputs:
    azureSubscription: 'Azure'
    appName: 'pipe-web'
    containers: 'fiapregistry.azurecr.io/webapp-dotnet:latest'
```

#### Executando e validando

Depois de salva, a execução da pipeline iniciará. Agora podemos observar o deploy. Podemos notar que o deploy
ocorreu corretamente e a pipeline executou sem problemas.

*Figura 5 - Pipeline Success: execução "Jobs in run #20240202.6" com a task "AzureWebAppContainer" concluída; o log
mostra "Single-container Deployment to the webapp 'pipe-web' as only the image detail was specified", a atualização
das configurações do App Service (`linuxFxVersion: DOCKER|fiapregistry.azurecr.io/...`), o restart do App Service e
a URL `https://pipe-web.azurewebsites.net`.*

Agora, vamos até o Azure para garantir que o deploy foi feito corretamente. No **Centro de Implantação**, podemos
notar que o Azure Repos com Pipelines se conectou à aplicação, conforme evidencia a figura 6.

*Figura 6 - Centro de Implantação: `pipe-web | Centro de Implantação` informando que o app está configurado com o
Azure Pipelines como provedor de build; Source = Azure Repos (Project/Repository `fiap-webapp`, Branch
`refs/heads/master`); Registry settings com Server URL `fiapregistry.azurecr.io`, Login `fiapregistry`, Image name
`webapp-dotnet` e Tag `latest`.*

Voltando para **Visão Geral**, podemos ver a URL no canto direito superior chamada **Domínio Padrão**. Basta clicar
no link logo abaixo e seremos direcionados para a aplicação. O resultado será parecido com o seguinte:

*Figura 7 - WebApp deployed: navegador em `pipe-web.azurewebsites.net` exibindo a aplicação `dotnetcoresample` com o
título "Disciplina Azure DevOps - FIAP" e o sistema operacional do host (Linux).*

Nossa aula termina aqui, espero que tenham gostado!

> **💡 Complemento:**
>
> - Esta pipeline só faz o **deploy** de uma imagem já existente; ela não compila nem gera imagem nova (o passo
>   `dotnet build` do template foi removido). Para um fluxo completo, combine com a task `Docker@2` da Aula 6 e use
>   `containers: 'fiapregistry.azurecr.io/webapp-dotnet:$(Build.BuildId)'`.
> - **Armadilha da tag `latest`:** se o deploy sempre aponta para `latest`, o App Service pode não perceber que a
>   imagem mudou (ou puxar uma versão diferente da esperada após um restart), e não há como saber qual build está no
>   ar nem fazer rollback preciso. Use a tag do build.
> - O App Service tenta detectar a porta do container; se a aplicação escutar em uma porta não padrão, defina a
>   app setting `WEBSITES_PORT`.
> - `pool: self-hosted` indica que a aula usou um agente próprio; em projetos novos sem paralelismo gratuito
>   liberado para agentes hospedados pela Microsoft, isso é comum.
> - Para trocar de versão sem downtime, use **deployment slots** (deploy em `staging`, validação e *swap*).

### O que você viu nesta aula?

Você viu como fazer um deploy no Azure WebApp a partir do Azure Pipelines de forma automatizada, atualizando a
aplicação a cada nova imagem criada por meio de alterações no código feitas pelo Azure Repos.

### Referências da aula

- LIMA, D. *dougls / dotnetcore-docs-hello-world*. 2024. <https://github.com/dougls/dotnetcore-docs-hello-world>
- MICROSOFT. *Início Rápido: Implantar um aplicativo Web ASP.NET*. 2024. <https://learn.microsoft.com/pt-br/azure/app-service/quickstart-dotnetcore?tabs=net70&pivots=development-environment-vscode>
- MICROSOFT. *Manage service connections*. 2024. <https://learn.microsoft.com/en-us/azure/devops/pipelines/library/service-endpoints?view=azure-devops&tabs=yaml>

Palavras-chave: Docker. ACR. Azure Pipelines. WebApp.

### Pontos-chave

- O Web App (App Service) pode rodar containers: na criação, escolha publicar como **Contêiner** e aponte, na aba
  Docker, para o repositório e a tag no ACR.
- A pipeline parte do template **ASP.NET Core** e usa o assistente para adicionar a task
  **`AzureWebAppContainer@1`** (`azureSubscription`, `appName`, `containers`).
- A conexão com a assinatura é uma Service Connection **Azure Resource Manager** (ID e nome em *Assinaturas*).
- O deploy atualiza a configuração do App Service (`linuxFxVersion: DOCKER|...`) e reinicia o app.
- O **Centro de Implantação** mostra origem (Azure Repos), registry, imagem e tag; a URL fica em *Domínio Padrão*.
- Evite a tag `latest` no deploy; prefira tags por build e *deployment slots* para trocas sem downtime.

---

## Aula 9 - Azure Container Apps

### O que vem por aí?

Nesta aula, vocês aprenderão sobre Azure Container Apps, como usá-lo da forma correta, suas principais
funcionalidades e quais as similaridades entre ele e o AWS Elastic Container Service, além de entender mais sobre
containers.

### Hands on

Nesta aula, faremos a criação de um app serverless com o Azure Container Apps utilizando nossa imagem que está salva
no Azure Container Registry, a fim de aproveitar a mesma imagem, subir a mesma aplicação e analisar as diferenças
entre as outras opções de aulas anteriores.

Com a aplicação no ar, vamos aprender a analisar o uso de recursos como CPU, memória RAM e logs dos containers em
execução.

> **💡 Complemento:** o Azure Container Apps (ACA) é uma plataforma serverless de containers **construída sobre
> Kubernetes** (com KEDA para auto-scaling por eventos, Envoy para ingress e suporte opcional a Dapr), mas que
> **não expõe a API do Kubernetes** — você não usa `kubectl`, não acessa o cluster nem aplica manifests. Conceitos
> principais: **Environment** (fronteira de rede/logs compartilhada por vários apps), **Container App**,
> **Revisions** (versões imutáveis do app, que permitem dividir tráfego entre versões), **Ingress** e **escala a
> zero**. Um fluxo mínimo via CLI equivalente ao do vídeo:
>
> ```bash
> az extension add --name containerapp --upgrade
> az containerapp env create -g fiap-app -n fiap-env -l brazilsouth
> az containerapp create -g fiap-app -n fiap-aca --environment fiap-env \
>   --image fiapregistry.azurecr.io/fiap-azure:58 \
>   --registry-server fiapregistry.azurecr.io --registry-identity system \
>   --target-port 8080 --ingress external \
>   --cpu 0.5 --memory 1.0Gi --min-replicas 0 --max-replicas 5
> az containerapp logs show -g fiap-app -n fiap-aca --follow
> ```
>
> (nomes de exemplo baseados nos recursos das aulas anteriores; métricas de CPU/memória ficam em *Monitoramento >
> Métricas* do app e os logs no Log Analytics do environment.)

### Saiba mais

Neste documento vamos entender melhor as similaridades entre Azure Container Apps e AWS Elastic Container Service,
além de aprender mais sobre containers e como eles funcionam.

#### Revisitando containers

Um dos problemas mais comuns que encontramos ao rodar um projeto local em nossa máquina é a desorganização e o uso
excessivo de memória RAM e CPU, além da configuração necessária para rodar o projeto se misturar com nossos
programas já instalados no computador.

Se instalarmos algo errado, ou até mesmo não dimensionarmos corretamente os recursos utilizados no momento em que o
projeto rodar, isso pode resultar em uma baita "dor de cabeça", e muitas vezes é necessário até mesmo formatar o
computador.

Podemos enxergar diversos problemas e, pensando nisso, os containers foram criados com o intuito de separar um
pedacinho do computador e isolá-lo para rodar projetos, testar sistemas operacionais e corrigir problemas sem afetar
a máquina principal e sem a necessidade de precisar redimensionar CPU, RAM, disco e rede, como no caso de uma VM
(Virtual Machine = Máquina Virtual).

Dessa maneira, um container é um ambiente isolado dentro de um servidor/máquina que divide e separa seus recursos
entre o servidor/máquina e os containers.

Imagine que o servidor é um navio cargueiro e os containers são os containers de carga deste navio: o navio tem a
base e a estrutura principal e em cada container de carga há diversos objetos, muitas vezes com conteúdo diferente
uns dos outros. No cenário em que um dos containers de carga é danificado ou perdido, os demais não são afetados,
exatamente por estarem isolados carregando seus próprios objetos.

*Figura 1 - Containers (Fonte: Google Imagens, 2024): foto de navio cargueiro com containers, a mesma analogia da
Aula 5.*

Sendo assim, um container é totalmente responsável pelo que estiver dentro dele; nesse caso, uma aplicação.

Um container pode estar rodando uma aplicação NodeJS com node, npm e assim por diante e outro container rodando uma
aplicação em .NET com msbuild. Tudo que estiver instalado no container NodeJS não será compartilhado com o .NET.
Diferentemente de uma VM, que separa, mas não totalmente — alguns problemas podem ser compartilhados entre as VMs —,
o que não acontece com os containers.

> **💡 Complemento (precisão conceitual):** na prática, o isolamento de uma VM (por hypervisor, com kernel próprio)
> é **mais forte** que o de um container, que compartilha o kernel do host. A vantagem dos containers está na
> leveza, na portabilidade e na separação das dependências de cada aplicação — não em um isolamento superior ao de
> VMs. Por isso ambientes multi-tenant sensíveis usam micro-VMs (ex.: Firecracker, usado pelo Fargate e pelo
> Lambda) ou sandboxes por baixo dos containers.

Para a execução de containers podemos utilizar o Docker, que é uma tecnologia que utiliza o Kernel do Linux e seus
recursos, como por exemplo Cgroups e Namespaces, que são empregados para isolar os processos de cada container.

- **Kernel**: é o principal componente do Linux; é responsável pela comunicação entre o hardware e os processos.
- **Cgroup**: é o responsável por colocar limites no uso dos recursos Linux, como CPU, RAM, rede etc.
- **Namespaces**: são os responsáveis por isolar processos, como rede e grupos de usuários. É o elemento que garante
  que um host (container) não veja os processos de outro host.

O isolamento é feito devido aos recursos citados.

#### Azure Container Apps x AWS ECS (Fargate)

Agora vamos falar sobre um serviço similar ao Azure Container Apps, só que da cloud AWS, chamado de **Elastic
Container Service** ou **ECS**. Ambos os serviços são serverless (não precisamos nos preocupar com a infraestrutura
por trás) e muitas pessoas conhecem o ECS serverless como **Fargate**. As similaridades são grandes, mas também há
algumas diferenças.

Com o AWS ECS, por exemplo, dividimos as seções em três pontos:

1. **Cluster** — a primeira camada, responsável por abrigar os serviços e tasks. Com ele conseguimos concentrar e
   organizar serviços de determinados grupos; por exemplo, podemos criar um cluster só para aplicações Python, outro
   só para aplicações .NET e um último para aplicações Node e, dentro de cada um, ter somente serviços (containers)
   relacionados à linguagem em questão.
2. **Service** — a segunda camada, responsável por concentrar todos os containers relacionados a uma aplicação.
   Vamos imaginar que um serviço chamado `fiap-dotnet-api` tenha dez containers rodando; é entrando no serviço
   `fiap-dotnet-api` que podemos ver somente os dez containers desse serviço.
3. **Task Definition** — a última camada; é nela que cadastramos tudo relacionado à aplicação, como por exemplo
   quanta CPU cada container terá, quanta memória, em quais portas a aplicação rodará, configurações de log e
   configurações de volumes e rede, além de apontar a imagem que a aplicação usará. Basicamente essa camada é a
   camada de configuração/inventário da aplicação; é o arquivo de configuração com informações vitais para que o
   container suba com a imagem correta, portas e afins.

Podemos notar certa similaridade com o Azure e isso é proposital, já que a ideia não é inventar a roda, mas copiar
fazendo melhor. Na figura 2 temos um reflexo sobre o que foi descrito.

*Figura 2 - AWS Fargate (Fonte: Shakya, 2022): "Users" → "ALB" → "ECS Cluster" contendo "Backend Service" →
"Backend Task Definition" → "Backend Container" executando em "Fargate"; o container puxa a imagem do "ECR" e acessa
um "Database".*

> **💡 Complemento:** mapeamento aproximado dos conceitos (não é 1:1):
>
> | AWS ECS/Fargate | Azure Container Apps | Kubernetes (EKS/AKS) |
> |---|---|---|
> | Cluster | Container Apps Environment | Cluster / Namespace |
> | Service | Container App | Deployment + Service |
> | Task (em execução) | Réplica | Pod |
> | Task Definition (revisão) | Revision / template do app | Spec do Pod (manifest) |
> | ALB + Target Group | Ingress integrado (Envoy) | Ingress / Load Balancer |
> | Service Auto Scaling | Regras de escala (KEDA) | HPA / KEDA |
>
> Diferença importante: no ACA o ingress e o balanceamento já vêm embutidos; no ECS você cria e configura o ALB.

Na imagem podemos ver dois serviços que não citamos, sendo eles ALB e ECR.

O **ALB**, ou Application Load Balancer, é o balanceador de carga que fica na frente dos containers e é responsável
por dividir o tráfego entre os containers existentes. Vamos imaginar que temos três containers da mesma aplicação
rodando e três pessoas acessando a aplicação neste momento. O ALB faz o trabalho de balancear a carga de cada
container, direcionando cada um dos três usuários para cada container; a conta não é exata, mas basicamente assim
funciona e trabalha um Load Balancer.

O outro serviço vocês já conhecem do Azure, onde ele se chama Azure Container Registry: isso mesmo, o **ECR** ou
Elastic Container Registry. É o repositório de imagens que serão usadas para subir e rodar os containers.

Ele é mais um repositório disponível dentre outros para hospedarmos nossas imagens e não fica preso à AWS. Podemos
usar o repositório da AWS para empregarmos em um deploy do Azure Container Apps; ele precisa estar autenticado, mas é
possível atualmente.

> **💡 Complemento (armadilha):** o token de autenticação do ECR (`aws ecr get-login-password`) **expira em 12
> horas**. Usar o ECR a partir de outra nuvem exige renovar essa credencial periodicamente, o que é frágil; o
> padrão é usar o registry nativo da nuvem onde o workload roda (ACR para Azure, ECR para AWS).

Também temos a opção de rodar um container no ECS usando uma **EC2** (Elastic Compute Cloud), em outras palavras uma
VM. Outra similaridade com o nosso serviço Azure Container Instance.

> **💡 Complemento (precisão):** a analogia mais exata seria: ECS com *launch type* EC2 = você gerencia as VMs que
> formam a capacidade do cluster (algo como nós de um cluster). O **ACI**, ao contrário, é serverless (não há VM sua
> para gerenciar) e se parece mais com uma task avulsa do ECS em **Fargate**.

#### Conclusão da aula

Há diversas comparações entre serviços de ambas as clouds; então, se você aprende no Azure o conceito por trás e
como funciona, isso se aplica na AWS, Google e outras clouds. A única diferença principal está na disposição entre os
serviços e no layout de cada cloud, mas no geral o envio da imagem para ECR e para ACR é basicamente da mesma
maneira, assim como mandar o deploy via pipeline para AWS e para Azure são similares também: o que muda são os
comandos, mas os passos são bem similares.

Então, experimentem outras clouds: ambas possuem o Free Tier anual para testar os principais serviços de forma
gratuita utilizando a menor arquitetura de cada cloud.

> **💡 Complemento (atualização):** os modelos gratuitos mudaram desde a produção da aula. Na AWS, contas criadas a
> partir de julho de 2025 recebem um plano gratuito baseado em **créditos** com prazo limitado, em vez do antigo
> Free Tier de 12 meses; na Azure, a conta gratuita combina crédito inicial por 30 dias com alguns serviços grátis
> por 12 meses. Confira as páginas oficiais antes de criar recursos — e lembre que EKS, AKS com SLA, NAT Gateway e
> Load Balancers geram custo mesmo em contas de estudo.

> **💡 Complemento — panorama dos serviços de containers (Azure x AWS):**
>
> | Necessidade | Azure | AWS |
> |---|---|---|
> | Registry privado | Azure Container Registry (ACR) | Elastic Container Registry (ECR) |
> | Container avulso, sem orquestração | Azure Container Instances (ACI) | Task do ECS em Fargate |
> | Web app em container (PaaS) | App Service / Web App for Containers | Elastic Beanstalk, App Runner |
> | Serverless de containers com escala automática | Azure Container Apps | ECS + Fargate, App Runner |
> | Kubernetes gerenciado | **Azure Kubernetes Service (AKS)** | **Elastic Kubernetes Service (EKS)** |

### O que você viu nesta aula?

Nesta aula, você viu como funcionam os containers e quais as similaridades entre Azure Container Apps e AWS Elastic
Container Service (Fargate).

### Referências da aula

- AWS. *O que é o Amazon Elastic Container Service?*. 2024. <https://docs.aws.amazon.com/pt_br/AmazonECS/latest/developerguide/Welcome.html>
- MICROSOFT. *Visão geral sobre os Aplicativos de Contêiner do Azure*. 2023. <https://learn.microsoft.com/pt-br/azure/container-apps/overview>
- SHAKYA, S. *Setup Application Load Balancer and Point to ECS — Deploy to AWS ECS Fargate with Load Balancer (Last Part)*. 2022. <https://sakyasumedh.medium.com/setup-application-load-balancer-and-point-to-ecs-deploy-to-aws-ecs-fargate-with-load-balancer-4b5f6785e8f>
- TUTORIALS DOJO. *AWS vs Azure Services Comparison Cheat Sheet*. 2023. <https://tutorialsdojo.com/aws-vs-azure-services-comparison>

Palavras-chave: Container. Azure Container Apps. AWS. ECS. Fargate.

### Pontos-chave

- O Azure Container Apps é serverless para containers: reaproveita a imagem do ACR, escala automaticamente (até
  zero) e expõe métricas de CPU/memória e logs.
- Por baixo ele usa Kubernetes, mas **não expõe a API do Kubernetes** ao usuário.
- No AWS ECS, a hierarquia é **Cluster → Service → Task Definition**; o Fargate é o modo serverless do ECS.
- A Task Definition é o "inventário" da aplicação: imagem, CPU, memória, portas, logs, volumes e rede.
- O **ALB** distribui o tráfego entre réplicas; o **ECR** é o equivalente AWS do ACR.
- ECS com EC2 usa VMs como capacidade; o ACI se compara melhor a uma task Fargate avulsa.
- Os conceitos (imagem → registry → deploy via pipeline) são os mesmos entre clouds; mudam nomes e comandos.

---

## Aplicação no Tech Challenge da Fase 4

O Tech Challenge da Fase 4 evolui o **FIAP Cloud Games** para **microsserviços .NET containerizados** que precisam
rodar em **Kubernetes gerenciado**, com imagens publicadas em um **registry privado nativo da cloud** e
**versionadas por tag**. O enunciado **não aceita containers soltos em IaaS** (por exemplo, `docker run` em uma VM/EC2).
O grupo tende a usar **AWS (EKS + ECR)**.

### O que das aulas 5 a 9 se aplica diretamente

| Tópico das aulas | Uso no Tech Challenge |
|---|---|
| Dockerfile multi-stage (Aulas 5 e 6) | Um Dockerfile por microsserviço (ex.: Usuários, Jogos, Pagamentos), SDK no build e `aspnet` (ou *chiseled*) no runtime, usuário não-root, porta 8080, `.dockerignore`. |
| Registry privado (Aula 6) | **ECR**, um repositório por microsserviço (`fcg/users-api`, `fcg/games-api`...), com *tag immutability* e *lifecycle policy*. No Azure seria o ACR. |
| Build e push automatizados (Aula 6) | Pipeline (GitHub Actions ou Azure Pipelines) que, a cada push na branch principal, faz build, testes, `docker build` e `docker push` com tag = SHA do commit ou número do build. |
| Variáveis e segredos (Aulas 6 e 7) | Nada de senha em YAML: OIDC do CI para uma IAM Role na AWS; segredos da aplicação em Secrets Manager/Parameter Store ou Kubernetes Secrets. |
| Deploy via pipeline (Aulas 7 e 8) | O stage de deploy troca o `az container create`/`AzureWebAppContainer@1` por `kubectl apply`/`helm upgrade` no EKS, apontando para a nova tag. |
| Comparativo Azure x AWS (Aula 9) | Mapear: ACR → ECR, ACI → (não usar), Container Apps → (não usar), AKS → **EKS**. |

### Atenção: ACI, Web App e Container Apps **não** atendem o requisito

- **ACI**: container avulso, sem orquestração Kubernetes.
- **Web App for Containers**: PaaS do App Service, sem Kubernetes.
- **Azure Container Apps**: embora rode sobre Kubernetes internamente, **não oferece um cluster Kubernetes
  gerenciado acessível** (sem API do Kubernetes, sem `kubectl`, sem manifests). Não comprova o requisito.
- Os equivalentes AWS (ECS/Fargate, App Runner, Elastic Beanstalk) também **não** contam como Kubernetes.
- O que atende: **EKS** (AWS) — ou **AKS** se o grupo optasse pela Azure.

### Esboço do fluxo na AWS

```bash
# Build e push para o ECR com tag imutável (SHA do commit)
AWS_ACCOUNT_ID=123456789012
AWS_REGION=us-east-1
REPO=fcg/users-api
TAG=$(git rev-parse --short HEAD)
REGISTRY=$AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com

aws ecr get-login-password --region $AWS_REGION | docker login --username AWS --password-stdin $REGISTRY
docker build -t $REGISTRY/$REPO:$TAG -f src/Users.Api/Dockerfile .
docker push $REGISTRY/$REPO:$TAG

# Deploy no EKS apontando para a nova tag
aws eks update-kubeconfig --name fcg-cluster --region $AWS_REGION
kubectl set image deployment/users-api users-api=$REGISTRY/$REPO:$TAG -n fcg
kubectl rollout status deployment/users-api -n fcg
```

(valores de conta, região, cluster e namespace são ilustrativos.)

Checklist sugerido para a entrega:

- [ ] Um Dockerfile multi-stage por microsserviço, com `.dockerignore`, usuário não-root e porta 8080.
- [ ] Repositórios ECR privados, com *scan on push*, *tag immutability* e *lifecycle policy*.
- [ ] Tags por versão/commit; manifests do Kubernetes referenciando a tag exata (nunca `latest`).
- [ ] Pipeline de CI/CD automatizada (build → teste → push → deploy), autenticando na AWS via OIDC.
- [ ] Cluster **EKS** com Deployments, Services, Ingress (AWS Load Balancer Controller), `resources.requests/limits`,
      *probes* de liveness/readiness e HPA.
- [ ] Evidências (prints/logs) de imagens no ECR e pods rodando no EKS.

### Glossário

| Termo | Significado |
|---|---|
| **Container** | Processo isolado (Namespaces) e limitado (Cgroups) que compartilha o kernel do host. |
| **Imagem** | Pacote imutável em camadas com aplicação e dependências, a partir do qual containers são criados. |
| **Dockerfile** | Arquivo de instruções para construir uma imagem. |
| **Multi-stage build** | Dockerfile com vários `FROM`, em que só o artefato final vai para a imagem de runtime. |
| **Tag** | Rótulo de versão de uma imagem em um repositório (ex.: `fiap-azure:51`). |
| **Digest** | Hash `sha256` que identifica de forma imutável o conteúdo de uma imagem. |
| **Registry** | Serviço que armazena e distribui imagens (Docker Hub, ACR, ECR). |
| **Service Connection** | Credencial/conexão do Azure DevOps com um serviço externo (ACR, assinatura Azure, Kubernetes). |
| **ACI** | Azure Container Instances — container avulso serverless, sem orquestração. |
| **App Service / Web App** | PaaS da Azure para aplicações web, que também roda imagens de container. |
| **Azure Container Apps** | Serverless de containers da Azure sobre Kubernetes, sem expor a API do K8s. |
| **ECS / Fargate** | Orquestrador de containers proprietário da AWS / modo serverless de capacidade do ECS. |
| **Task Definition** | Especificação de uma task do ECS (imagem, CPU, memória, portas, logs, rede). |
| **ALB** | Application Load Balancer da AWS, balanceamento HTTP/HTTPS entre réplicas. |
| **AKS / EKS** | Kubernetes gerenciado da Azure / da AWS — o que o Tech Challenge exige. |
| **WSL 2** | Subsistema Windows para Linux, com kernel Linux real, usado pelo Docker Desktop no Windows. |
