# Docker e Contêineres — Guia Aprofundado (Fase 2)

> **Arquitetura de Sistemas .NET — PósTech FIAP**
> Resumo consolidado das Aulas 1 a 6 da disciplina de Docker, escrito para quem já tem rodagem em sistemas, mas está construindo a base cloud-native.

---

## Por que isto importa para você

Você passou mais de uma década no mundo **client-server**: compilava um `.exe` PowerBuilder, gerava as DataWindows, copiava os binários para um servidor de aplicação, e rezava para que aquele servidor tivesse a *runtime* certa, a DLL certa, a versão certa do banco e as variáveis de ambiente certas. Quando funcionava na sua máquina e quebrava no servidor do cliente, a investigação era arqueológica: "qual service pack está instalado lá?", "que versão do driver ODBC?", "alguém mexeu no registro?".

**Docker existe para matar essa classe inteira de problema.** A ideia central é: em vez de instalar a aplicação *e suas dependências* num servidor que já tem mil outras coisas, você **empacota a aplicação junto com todo o ambiente que ela precisa** — sistema operacional base, runtime, bibliotecas, variáveis, portas — num artefato único, imutável e versionado chamado **imagem**. Esse artefato roda **igual** na sua máquina, no servidor de homologação e na nuvem. O famoso "na minha máquina funciona" deixa de ser desculpa porque *a sua máquina viaja junto com o código*.

Para o seu cenário .NET, isso significa: a mesma imagem que você testa localmente é a que sobe para a AWS. Sem "preparar o servidor". Sem checklist de instalação. O servidor só precisa saber rodar contêineres — nada mais.

---

## Mapa das aulas

| Aula | Tema | O que cobriu |
|------|------|--------------|
| **1** | Introdução ao Docker | O que é Docker, Kernel Linux, cgroups/namespaces, VM vs contêiner, imagens, Docker Hub, tags, Dockerfile, WSL |
| **2** | Gerenciamento de Contêineres | Comandos do dia a dia (`run`, `ls`, `inspect`, `update`), limites de CPU/memória, volumes, container de dados, rede, registries na cloud |
| **3** | Orquestração de Contêineres | Docker Compose, arquivo `.yml`, services/networks/volumes, políticas de restart, comandos do Compose |
| **4** | Melhores Práticas e Troubleshooting | Camadas (layers), cache de build, ARG vs ENV, imagens enxutas |
| **5** | Segurança de Contêineres | Análise de vulnerabilidades com Trivy, severidades, imagens `alpine`, superfície de ataque |
| **6** | Amazon ECS | Cluster, task, service, definição de tarefa, EC2 vs Fargate, integração IAM/CloudWatch/ELB |

---

## 1. O que é Docker e o problema que ele resolve

Docker foi lançado em **2013** pela empresa dotCloud. É uma ferramenta **open source** criada para melhorar o **isolamento** e o **uso de recursos** (CPU, memória, disco) e para rodar aplicações **sem a necessidade de uma interface gráfica** ou de um sistema operacional convidado completo, ao contrário de uma máquina virtual.

A mágica não é mágica: ela vem de três recursos do **Kernel do Linux** (o núcleo que faz a ponte entre hardware e processos, gerenciando memória, processos, drivers, chamadas de sistema e segurança):

- **Namespaces** — criam o **isolamento lógico**. Cada contêiner enxerga seu próprio conjunto de processos, sua própria rede, seus próprios usuários e seu próprio sistema de arquivos, como se estivesse sozinho na máquina. É o que faz dois contêineres rodando lado a lado não "se enxergarem".
- **Cgroups** (control groups) — impõem **limites de recursos**: quanto de CPU e memória cada processo pode consumir, quais podem ser reiniciados, parados ou congelados. É o que impede que um contêiner que disparou para 100% de CPU derrube os vizinhos.
- (Junto, esses dois dão o efeito "navio cargueiro": se um contêiner cai no mar, os outros e o próprio navio — o **host** — seguem firmes.)

### VM pesada vs contêiner leve

Esta é a comparação que mais conversa com a sua bagagem de infraestrutura on-premise:

| Aspecto | Máquina Virtual (VM) | Contêiner |
|---------|----------------------|-----------|
| O que virtualiza | Hardware inteiro + SO convidado completo | Apenas o processo (compartilha o Kernel do host) |
| Peso | Gigabytes; minutos para subir | Megabytes; segundos (ou menos) para subir |
| Isolamento | Forte (hypervisor) | Forte o suficiente (namespaces/cgroups), mais leve |
| Densidade | Poucas VMs por host | Dezenas/centenas de contêineres por host |
| SO | Cada VM tem o seu | Compartilham o Kernel do host |

> **🏛️ Observação do Arquiteto**
> A VM virtualiza o *hardware*; o contêiner virtualiza o *processo*. Por isso o contêiner é tão mais leve — ele não carrega um SO inteiro, ele empresta o Kernel do host. Consequência prática para você: como o contêiner usa o **Kernel Linux**, no Windows ele roda sobre o **WSL2** (Windows Subsystem for Linux), que é um Linux real e leve embarcado no Windows. O Docker Desktop instala e integra esse WSL para você. Imagens .NET modernas (`mcr.microsoft.com/dotnet/aspnet`) são imagens **Linux** — é assim que você roda ASP.NET Core em contêiner mesmo desenvolvendo no Windows. Existem imagens Windows, mas são raras, pesadas e quase sempre desnecessárias.

---

## 2. Imagens vs Contêineres — a distinção que tudo gira em torno

Esta é a confusão #1 de quem está começando, então vale fincar a estaca:

- **Imagem** = o **molde**, imutável e versionado. Empacota o SO base, dependências, portas expostas e variáveis de ambiente. É o seu "`.exe` + tudo que ele precisa", só que padronizado. Uma imagem **não roda** — ela fica parada num registro, igual um binário num repositório.
- **Contêiner** = uma **instância em execução** de uma imagem. É o processo vivo. Você pode subir 1, 10 ou 100 contêineres a partir da *mesma* imagem.

A analogia .NET mais limpa: **imagem está para contêiner assim como classe está para objeto**. A imagem é o `class`, o contêiner é o `new`. Você instancia quantos objetos quiser da mesma classe; eles têm estados independentes mas compartilham a definição.

> **🏛️ Observação do Arquiteto**
> Contêineres são **descartáveis e efêmeros** ("cattle, not pets"). A mentalidade certa: nunca entre num contêiner em produção para "arrumar" algo e deixá-lo rodando alterado. Se precisa mudar, mude a *imagem*, gere uma nova versão e substitua o contêiner. Qualquer estado que precise sobreviver à morte do contêiner (banco, uploads, logs persistentes) **tem que estar num volume**, não dentro do contêiner. Isso é o oposto do servidor PowerBuilder de estimação que ficava anos no ar e ninguém ousava reiniciar.

---

## 3. Dockerfile — a receita da imagem

O **Dockerfile** (o nome do arquivo *é* a extensão — não tem `.txt`) é onde você declara, instrução por instrução, como a imagem é montada: qual base usar, o que copiar, o que instalar, quais variáveis e portas, e qual comando inicia a aplicação.

### Exemplo comentado (uma API ASP.NET Core)

```dockerfile
# Camada 0: imagem base — runtime do .NET 8 já com tudo para ASP.NET Core
FROM mcr.microsoft.com/dotnet/aspnet:8.0

# Diretório de trabalho dentro do contêiner
WORKDIR /app

# Copia os binários já publicados da máquina de build para a imagem
COPY ./publish .

# Documenta a porta que a aplicação escuta
EXPOSE 8080

# Variável de ambiente lida pela aplicação em runtime
ENV ASPNETCORE_URLS=http://+:8080

# Comando que inicia o processo principal quando o contêiner sobe
ENTRYPOINT ["dotnet", "FiapCloudGames.dll"]
```

Instruções essenciais:

| Instrução | Para que serve |
|-----------|----------------|
| `FROM` | Imagem base. Sempre a primeira; é a **camada zero**. |
| `WORKDIR` | Define o diretório de trabalho dentro da imagem. |
| `COPY` / `ADD` | Copia arquivos do host para a imagem. |
| `RUN` | Executa um comando **durante o build** (instalar pacotes, restaurar dependências). |
| `ENV` | Define variável de ambiente que persiste em runtime. |
| `ARG` | Argumento que existe **só durante o build** (ver seção de boas práticas). |
| `EXPOSE` | Documenta a porta que o contêiner escuta. |
| `CMD` / `ENTRYPOINT` | Comando que executa quando o contêiner **inicia**. |

### Camadas (layers) e cache — o pulo do gato do build

Cada instrução do Dockerfile vira uma **camada (layer)**. O `FROM` é a camada zero; cada instrução seguinte empilha uma camada nova, e **a de baixo depende da de cima**.

Por que isso importa? **Cache.** Quando você rebuilda a imagem, o Docker reaproveita as camadas que **não mudaram** e só reconstrói da camada alterada para baixo. No material, um build inicial levou ~55s; com cache, o mesmo build caiu para ~15s — porque só as camadas afetadas foram refeitas.

A regra de ouro decorre disso: **coloque o que muda pouco em cima, o que muda muito embaixo.** Em .NET, isso significa restaurar pacotes *antes* de copiar o código-fonte:

```dockerfile
# Copia só os .csproj e restaura — esta camada só refaz quando dependências mudam
COPY *.csproj ./
RUN dotnet restore

# Só agora copia o código-fonte — muda a cada commit, mas o restore acima fica em cache
COPY . ./
RUN dotnet publish -c Release -o /app/publish
```

> **🏛️ Observação do Arquiteto**
> Esse ordenamento é a otimização de build mais valiosa que existe. Se você copiar tudo (`COPY . .`) *antes* do `dotnet restore`, qualquer alteração numa linha de código invalida o cache do restore e seu build baixa todos os NuGets de novo — toda. santa. vez. Em CI/CD isso é a diferença entre um pipeline de 2 minutos e um de 12. O `.dockerignore` (próxima seção) complementa: sem ele, um `bin/`, `obj/` ou `.git` enorme entra no contexto de build e estoura o cache à toa.

---

## 4. Registries — onde as imagens moram

Uma imagem precisa de um lugar para ser guardada e distribuída. Esse lugar é o **registry** (registro de contêineres). Pense nele como o equivalente ao seu repositório de binários versionados, só que para imagens.

- **Docker Hub** — é "basicamente um GitHub voltado para imagens". Tem imagens **oficiais** (ex.: a página oficial do Python, do Node, do `dotnet`), imagens **verificadas** de publishers, e imagens da **comunidade**. Você consome com `docker pull <url>:<tag>`.
- **AWS ECR** (Elastic Container Registry), **Azure Container Registry (ACR)** e **Google Container Registry** — registries privados das nuvens. É onde você publica *as suas* imagens para que serviços como ECS, AKS ou Kubernetes as consumam. O cache de camadas também vale aqui: o push/pull só transfere as camadas que faltam.

### Tags — o controle de versão da imagem

A **tag** define a **versão** da imagem (`python:3.8`, `node:18`, `node:18-alpine`). Serve para controle, atualização e organização — corrigir bugs, melhorar o processo, aplicar correções de segurança. A última versão recebe convencionalmente a tag **`latest`**.

> **🏛️ Observação do Arquiteto**
> **Nunca confie em `latest` em produção.** `latest` é uma etiqueta móvel: a imagem por trás dela muda sem aviso, e dois deploys "iguais" podem rodar binários diferentes — exatamente o tipo de não-determinismo que o Docker veio eliminar. Use **tags imutáveis**: versão semântica (`1.4.2`) ou, melhor ainda em pipelines, o **SHA do commit** (`fcg-api:8a3f9c1`). Assim "a imagem que rodou em homologação" é, byte a byte, "a imagem que rodou em produção". E **cuidado com imagens da comunidade**: o próprio material avisa que existem imagens suspeitas no Docker Hub. Prefira oficiais/verificadas e escaneie tudo (seção de segurança).

---

## 5. Comandos essenciais do dia a dia

### Ciclo de vida de um contêiner

```bash
docker container run -d -p 8080:80 --name fcg-api fcg-api:1.0
#   run            -> cria E inicia um contêiner a partir da imagem
#   -d             -> detached (roda em background)
#   -p 8080:80     -> mapeia porta_do_host : porta_do_container
#   --name         -> dá um nome amigável (senão o Docker sorteia um)

docker container ls          # lista os contêineres EM EXECUÇÃO
docker container ls -a       # lista TODOS, inclusive os parados
docker container stop fcg-api
docker container start fcg-api
docker container rm fcg-api  # remove (precisa estar parado)
```

O `docker container ls -a` mostra as colunas que você vai ler o tempo todo:

| Coluna | Significado |
|--------|-------------|
| `CONTAINER ID` | ID único do contêiner |
| `IMAGE` | imagem que gerou o contêiner |
| `COMMAND` | comando em execução |
| `CREATED` | quando foi criado |
| `STATUS` | estado atual (Up, Exited…) |
| `PORTS` | mapeamento de portas host↔container |
| `NAMES` | nome do contêiner |

### Limites de recursos (cgroups na prática)

```bash
# Sobe um contêiner com no máximo 1 CPU e 512 MB de RAM
docker container run --cpus=1 -m 512m minha-imagem

# Verifica se aplicou (pega o ID no ls, faz inspect e filtra)
docker container inspect <ID> | grep -i cpu
docker container inspect <ID> | grep -i mem

# Ajusta recursos de um contêiner JÁ EM EXECUÇÃO, sem matá-lo
docker container update --cpus=2 -m 1g <ID>
```

O `update` vale para CPU e RAM e é elegante: o contêiner não precisa morrer para receber mais recursos.

### Construir e publicar imagens

```bash
docker build -t fcg-api:1.0 .          # -t = tag ; "." = contexto de build (pasta atual)
docker tag fcg-api:1.0 <registry>/fcg-api:1.0
docker push <registry>/fcg-api:1.0
docker pull <registry>/fcg-api:1.0
```

---

## 6. Volumes e persistência

Contêiner é efêmero: quando ele morre, o sistema de arquivos *dentro* dele vai junto. Para dados que precisam **sobreviver** (banco de dados, uploads, logs), usa-se **volume**.

```bash
# Cria um volume nomeado, gerenciado pelo Docker (mora na raiz do Docker, não num path que você gerencia)
docker volume create dadosdb

# Monta o volume num contêiner MySQL: /var/lib/mysql passa a persistir no volume
docker container run -d --name banco -v dadosdb:/var/lib/mysql mysql
```

O material destaca dois pontos importantes:

- **Backup de volumes**: garantir uma cópia segura de um volume é prática recomendada. Se houver falha ou exclusão por engano, você recria o volume a partir do backup. Persistência sem backup é só uma falsa sensação de segurança.
- **Container de dados**: um contêiner cujo único papel é **hospedar um volume nomeado** que outros contêineres consomem. A vantagem citada: você não precisa se preocupar com um diretório específico no host — a pasta é criada automaticamente na raiz do Docker, e todo mundo conecta no *container de dados*, não num caminho físico.

> **🏛️ Observação do Arquiteto**
> Existem dois jeitos de persistir: **volume nomeado** (gerenciado pelo Docker, recomendado para dados) e **bind mount** (você aponta uma pasta do host, do tipo `-v C:\meus-logs:/app/logs`). Bind mount é ótimo em desenvolvimento — você edita um arquivo no Windows e o contêiner enxerga na hora. Em produção, prefira volume nomeado: é portável e não acopla a aplicação à estrutura de pastas de um host específico. E um conselho que vem da sua era client-server: **banco de dados de produção dificilmente deve viver dentro de um contêiner no mesmo host da aplicação.** Contêiner é ótimo para a *aplicação stateless*; o estado pesado normalmente vai para um serviço gerenciado (RDS, Azure SQL). O `container de dados` da aula é excelente didaticamente e para dev/teste — não o confunda com arquitetura de produção.

---

## 7. Redes

Por padrão, cada contêiner roda isolado. Para que se comuniquem (a API falar com o banco, por exemplo), eles precisam estar na **mesma rede Docker**. O isolamento de rede vem dos namespaces — cada contêiner pode ter sua própria stack de rede.

O conceito de mapeamento de porta é onde a maioria tropeça. No formato `host:container`:

```
ports: 8002:3306
```

- **3306** (`portaContainer`) é a porta pela qual **outros contêineres** alcançam o serviço dentro da rede Docker.
- **8002** (`portaDockerHost`) é a porta exposta **externamente**, acessível do host (`localhost:8002`).

Ou seja: outro contêiner conecta no banco pela `3306`; você, do seu navegador/cliente local, conecta pela `8002`. São dois caminhos diferentes para o mesmo serviço.

> **🏛️ Observação do Arquiteto**
> Dentro de uma rede Docker, contêineres se enxergam **pelo nome do serviço**, não por IP. Se você tem um serviço chamado `db`, a sua connection string .NET aponta para `Server=db;Port=3306;...` — o Docker resolve `db` para o IP interno automaticamente (DNS embutido). Isso é libertador para quem vem de connection strings com IPs fixos: o endereço do banco vira o *nome lógico* do serviço, e a infra cuida do resto.

---

## 8. Orquestração — de um contêiner para muitos

Rodar **um** contêiner com `docker run` é fácil. Mas uma aplicação real tem vários: API + banco + cache + gateway + migrations. Subir e conectar tudo isso na mão, na ordem certa, é tedioso e propenso a erro. Aí entra a **orquestração**.

### Docker Compose — orquestração na sua máquina

O **Docker Compose** gerencia **múltiplos contêineres** declarados num único arquivo **`docker-compose.yml`** (YAML). Você descreve o estado desejado e o Compose materializa tudo com um comando.

```yaml
version: "3.8"

networks:
  app-net:                      # rede compartilhada pelos serviços

volumes:
  dadosdb:                      # volume persistente do banco

services:
  db:
    image: mysql:8.0
    environment:                # variáveis de ambiente (ou use env_file: .env)
      MYSQL_ROOT_PASSWORD: ${DB_PASS}
    volumes:
      - dadosdb:/var/lib/mysql
    networks: [app-net]
    restart: always

  api:
    build: .                    # constrói a imagem a partir do Dockerfile no contexto "."
    ports:
      - "8080:80"               # host:container
    depends_on:
      - db                      # só sobe a api depois que db estiver no ar
    environment:
      ConnectionStrings__Default: "Server=db;Database=fcg;User=root;Password=${DB_PASS}"
    networks: [app-net]
    restart: on-failure
```

Blocos e instruções principais (direto do material):

- **`version`** — define a sintaxe/steps aceitos no arquivo.
- **`networks`** — cria rede(s) para os contêineres se comunicarem.
- **`volumes`** — cria disco(s) persistente(s); podem ser vários, cada um com `nome:`.
- **`services`** — onde cada contêiner é declarado. Dentro de cada serviço:
  - **`image`** — imagem a usar; ou **`build`** — caminho/contexto do Dockerfile a construir.
  - **`ports`** — mapeamento `host:container`.
  - **`depends_on`** — ordem: "x" só inicia depois de "y".
  - **`environment`** / **`env_file`** — variáveis (inline ou apontando um `.env`).
  - **`volumes`** — aponta pastas dentro de um volume criado.
  - **`command`** / **`entrypoint`** — sobrescrevem o `CMD`/`ENTRYPOINT` da imagem.
  - **`restart`** — política de reinício (ver tabela).
  - **`links`** — "linka" um contêiner a outro (recurso legado; hoje a rede compartilhada já resolve).

#### Políticas de `restart`

| Política | Comportamento |
|----------|---------------|
| `no` | nunca reinicia |
| `on-failure` | reinicia só se a saída for diferente de zero (falha) |
| `always` | reinicia sempre que parar, por qualquer motivo |
| `unless-stopped` | reinicia sempre, **exceto** se você parou de propósito |

#### Comandos do Compose

| Comando | O que faz |
|---------|-----------|
| `docker compose up` | cria e inicia todos os contêineres |
| `docker compose build` | só builda as imagens (agiliza o `up` depois) |
| `docker compose ps` | lista os contêineres do projeto |
| `docker compose logs` | mostra os logs |
| `docker compose restart` | reinicia |
| `docker compose start` / `stop` | inicia / paralisa |
| `docker compose scale` | aumenta o número de réplicas de um serviço |
| `docker compose down` | **paralisa e remove tudo**: contêineres, rede, e — cuidado — volumes/imagens conforme as flags |

> **🏛️ Observação do Arquiteto**
> `depends_on` garante a **ordem de inicialização**, mas **não** garante que o serviço dependido esteja *pronto*. O contêiner do MySQL pode estar "no ar" mas ainda inicializando o banco quando sua API tenta conectar e quebra. A solução robusta é a aplicação **tentar reconectar com backoff** (resiliência — tema da disciplina de Microsserviços) ou usar **healthchecks** no Compose com `condition: service_healthy`. Vindo do mundo client-server, onde o banco estava sempre lá antes da aplicação subir, essa corrida de inicialização é uma armadilha nova e comum. Outra distinção importante: **Compose é para a sua máquina e ambientes simples**; produção em escala pede um orquestrador de verdade (ECS, Kubernetes), que é o passo seguinte.

---

## 9. Boas práticas de imagens

### Imagens enxutas

Quanto **menor** a imagem base, menos peso, menos tempo de build/deploy e — crucialmente — **menos superfície de ataque**. O material mostra o caso clássico: `node:18` vs `node:18-alpine`. A variação **Alpine** (baseada na distribuição Linux Alpine, mínima) é "bem menor" e, no teste, **não tinha nenhuma vulnerabilidade**, enquanto a `node:18` cheia trazia várias. Menos pacotes pré-instalados = menos coisa para dar errado e para ser explorada.

### Multi-stage build

O Dockerfile pode ter **vários estágios**: um para *construir* (pesado, com SDK e ferramentas) e outro para *rodar* (leve, só o runtime). Você copia apenas o resultado final do estágio de build para o estágio de runtime, e descarta todo o ferramental. Em .NET isso é praticamente obrigatório:

```dockerfile
# ---- Estágio 1: build (imagem grande, com o SDK do .NET) ----
FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build
WORKDIR /src
COPY *.csproj ./
RUN dotnet restore
COPY . ./
RUN dotnet publish -c Release -o /app/publish

# ---- Estágio 2: runtime (imagem pequena, só o aspnet) ----
FROM mcr.microsoft.com/dotnet/aspnet:8.0
WORKDIR /app
COPY --from=build /app/publish .      # traz SÓ os binários publicados
USER app                               # roda como usuário não-root (ver segurança)
ENTRYPOINT ["dotnet", "FiapCloudGames.dll"]
```

A imagem final não carrega o SDK (centenas de MB de compiladores e ferramentas) — só o runtime e os binários. Menor, mais rápida, mais segura.

### ARG vs ENV (não exponha segredos no Dockerfile)

- **`ARG`** existe **só durante o build** e é passado de fora: `docker build --build-arg VERSAO=1.4 .`. Não fica embutido na imagem final como variável de runtime.
- **`ENV`** persiste como variável de ambiente em **runtime**.

O material mostra o padrão de usar `ARG` para receber valores no build e, quando apropriado, popular um `ENV` a partir dele — evitando deixar valores sensíveis *escritos* dentro do Dockerfile.

> **🏛️ Observação do Arquiteto**
> Atenção a uma pegadinha: nem `ARG` nem `ENV` são bons para **secrets** (senhas, tokens, connection strings com credencial). `ENV` fica visível em `docker inspect` e no histórico da imagem; `ARG` vaza no histórico de build. **Segredo de verdade não entra na imagem.** Em produção, injete via mecanismo de secrets do orquestrador: `secrets` do Docker/Compose, **AWS Secrets Manager / SSM Parameter Store** (integrados ao ECS), Azure Key Vault, ou variáveis injetadas pela esteira de CI/CD. A imagem deve ser *agnóstica de ambiente*: a mesma imagem sobe em dev, homolog e prod, e o que muda é a configuração injetada de fora — exatamente o que o `appsettings.{Environment}.json` + variáveis de ambiente do ASP.NET Core já te dão.

### Outras boas práticas
- **`.dockerignore`** — análogo ao `.gitignore`. Impede que `bin/`, `obj/`, `.git`, `node_modules` etc. entrem no contexto de build, o que deixa o build mais rápido e evita invalidar cache à toa.
- **Usuário não-root** — não rode a aplicação como `root` dentro do contêiner (princípio do menor privilégio).
- **Tags imutáveis** — versione, não confie em `latest`.

---

## 10. Segurança de contêineres

A premissa da Aula 5: **identificar e corrigir vulnerabilidades antes que alguém mal-intencionado as explore.** Uma imagem não é só o seu código — ela arrasta o SO base e dezenas de bibliotecas, cada uma com seu próprio histórico de CVEs.

### Scan de vulnerabilidades com Trivy

**Trivy** (Aqua Security) é uma ferramenta open source que escaneia imagens em busca de vulnerabilidades conhecidas. Fluxo do material:

```bash
# Instalação (WSL Ubuntu) — baixa, extrai e move para o PATH
wget https://github.com/aquasecurity/trivy/releases/download/v0.48.0/trivy_0.48.0_Linux-64bit.tar.gz \
  && tar -xzf trivy_0.48.0_Linux-64bit.tar.gz
sudo mv trivy /usr/local/bin/
trivy version

# Builda a imagem com uma tag e escaneia
docker build -t teste-trivy:latest .
trivy image teste-trivy:latest

# Filtra só os níveis que importam
trivy image --severity CRITICAL,HIGH teste-trivy:latest
trivy image --severity CRITICAL teste-trivy:latest
```

Os **níveis de severidade**: `UNKNOWN`, `LOW`, `MEDIUM`, `HIGH`, `CRITICAL`. A saída lista cada vulnerabilidade com um link (coluna *Title*) para os detalhes na base de dados (Aqua Vulnerability Database / NVD). No exemplo da aula, a `node:18` arrastava uma falha do **OpenSSH < 9.3** via biblioteca herdada da imagem base — e trocar para `node:18-alpine` zerou as vulnerabilidades, **sem mudar a versão do Node**.

### Princípios de segurança

- **Reduza a superfície de ataque**: imagens enxutas (Alpine, `distroless`) têm menos pacotes, logo menos CVEs. O que não está instalado não pode ser explorado.
- **Princípio do menor privilégio**: usuário **não-root**, capacidades Linux mínimas, sistema de arquivos read-only quando possível.
- **Secrets fora da imagem**: nunca em `ENV`/`ARG`/Dockerfile/código; use cofres gerenciados.
- **Não exponha o que não precisa**: só publique as portas estritamente necessárias.

> **🏛️ Observação do Arquiteto**
> Scan de vulnerabilidade não é evento único — é **portão do pipeline**. Coloque `trivy` (ou o scanner nativo do ECR/ACR) como etapa do CI/CD que **reprova o build** se aparecer `CRITICAL`. E lembre: uma imagem que era limpa há três meses **não é mais** — CVEs novos são publicados o tempo todo contra bibliotecas que você já empacotou. Por isso se **reconstrói e re-escaneia periodicamente**, mesmo sem mudança de código. Para quem vem do mundo onde "atualizar o servidor" era um evento traumático anual: aqui a atualização é trocar a imagem base e rebuildar — rápido, versionado e reversível.

---

## 11. Troubleshooting — o kit de diagnóstico

Quando um contêiner não sobe, sobe e morre, ou está de pé mas não responde, este é o roteiro:

```bash
# 1. O contêiner está rodando? Qual o STATUS / EXIT CODE?
docker container ls -a

# 2. O que a aplicação cuspiu? (stdout/stderr do processo principal)
docker logs <container>
docker logs -f <container>          # acompanha em tempo real (follow)
docker logs --tail 100 <container>  # só as últimas 100 linhas

# 3. Entrar no contêiner vivo para investigar por dentro
docker exec -it <container> sh      # ou bash, se a imagem tiver
#   -i interativo, -t aloca terminal

# 4. Configuração completa: rede, montagens, env, limites, comando...
docker container inspect <container>

# 5. Consumo de recursos ao vivo (CPU, memória, rede, I/O)
docker stats
```

| Sintoma | Causa provável | Onde olhar |
|---------|----------------|-----------|
| Contêiner sai logo após subir (`Exited`) | App crashou no boot; faltou variável/connection string; `ENTRYPOINT` errado | `docker logs` |
| "Connection refused" entre serviços | Não estão na mesma rede; usou IP em vez do nome do serviço; banco ainda inicializando | `inspect` (rede), `logs` |
| Porta não responde do host | Esqueceu `-p host:container`; app escutando em `localhost` e não em `0.0.0.0` | mapeamento `ports`, config do app |
| Build lento / sempre do zero | Ordem ruim de camadas; falta `.dockerignore`; cache invalidado | revisar Dockerfile |
| Contêiner morto por falta de memória (OOMKilled) | Limite `-m` baixo demais; vazamento | `docker stats`, `inspect` |

> **🏛️ Observação do Arquiteto**
> Um princípio cloud-native que muda seu instinto de logging: **logue para `stdout`/`stderr`, não para arquivo dentro do contêiner.** O `docker logs` (e, na nuvem, o **CloudWatch**) lê a saída padrão do processo. Se sua API ASP.NET escreve log num arquivo dentro do contêiner, esse log some quando o contêiner morre e ninguém o coleta. Configure o logging para o console — o orquestrador captura e centraliza. Imagens **Alpine/distroless** não têm `bash` (às vezes nem `sh`), então o `docker exec -it ... sh` pode falhar; é o preço da imagem enxuta, e o motivo de você depender mais de `logs` e `inspect` do que de "entrar e bisbilhotar".

---

## 12. Amazon ECS (Elastic Container Service)

O Compose orquestra na sua máquina. Para produção na AWS, entra o **ECS** — o serviço gerenciado da Amazon para **executar, escalar e gerenciar contêineres Docker** num cluster de servidores.

### Os quatro conceitos fundamentais

| Conceito | O que é |
|----------|---------|
| **Cluster** | Conjunto lógico de capacidade computacional — instâncias **EC2** ou capacidade **Fargate**. É o "ambiente" onde os contêineres rodam. |
| **Task Definition** (definição de tarefa) | A "receita" da execução: qual imagem Docker, quanto de CPU/memória, portas, variáveis de ambiente. É o análogo de runtime do seu `docker run`/serviço do Compose. |
| **Task** (tarefa) | A **menor unidade de execução** — uma instância em execução de uma Task Definition (um ou mais contêineres juntos). |
| **Service** (serviço) | Mantém **N tarefas rodando simultaneamente**, **reinicia** as que falham e **balanceia carga** entre elas. É o que garante "sempre 3 réplicas no ar". |

A hierarquia mental: **Cluster → Service → Task (definida por uma Task Definition) → contêiner(es)**.

### EC2 vs Fargate — o trade-off central

O ECS oferece dois modos de **onde** as tarefas rodam:

| | **Modo EC2** | **Modo Fargate** |
|---|---|---|
| Modelo | Você provisiona e gerencia as instâncias EC2 | **Serverless**: a AWS gerencia os servidores |
| Controle | Máximo (tipo de instância, SO, tuning) | Você só declara CPU/memória da tarefa |
| Operação | Você cuida de patch, scaling do cluster, capacidade | Zero gestão de servidor |
| Custo | Pode ser mais barato em alta utilização constante | Paga por tarefa/tempo; ótimo para carga variável |
| Quando usar | Precisa de controle fino, GPUs, uso previsível e denso | Quer simplicidade e foco na aplicação, carga intermitente |

### Integrações que vêm de graça

- **IAM** — controle de acesso e o fluxo de credenciais (a instância pega credenciais do metadata do EC2, o agente ECS busca credenciais de função, inicia a tarefa e define o segredo do contêiner, e a tarefa usa esse segredo para obter suas próprias credenciais).
- **CloudWatch** — monitoramento, métricas e centralização de logs.
- **ELB** (Elastic Load Balancing) — distribui o tráfego entre as tarefas.
- **VPC** — isolamento de rede dos recursos.
- **Auto-scaling** — escala as tarefas automaticamente por métricas de CPU/memória.

### Casos de uso citados
Desenvolvimento/teste (subir e destruir ambientes rápido), **microsserviços** (orquestrar muitos contêineres, cada um um serviço), aplicações de alto desempenho/alta disponibilidade, e big data / processamento em lote.

> **🏛️ Observação do Arquiteto**
> Não confunda os "três E" da AWS: **EC2** é máquina virtual (servidor), **ECR** é o *registry* (onde a imagem mora), **ECS** é o *orquestrador* (quem roda a imagem). O caminho típico do FIAP Cloud Games na AWS: build da imagem no CI → `push` para o **ECR** → o **ECS** (provavelmente **Fargate**, pela simplicidade) puxa a imagem e sobe as **tasks** governadas por um **service**, com **ELB** na frente e **CloudWatch** coletando logs. Para uma equipe pequena que não quer administrar servidores, **comece por Fargate** — você só descobre que precisa do modo EC2 quando bate num limite concreto (custo em escala alta, hardware específico). E ECS vs Kubernetes (próxima disciplina): ECS é mais simples e "AWS-nativo"; Kubernetes é o padrão de mercado, portável entre nuvens, porém mais complexo. Os conceitos que você acabou de aprender (task ≈ pod, service ≈ deployment/service) transferem-se quase 1:1.

---

## ⚠️ Erros comuns / armadilhas

1. **Confundir imagem com contêiner.** Imagem é o molde imutável; contêiner é a instância viva. Editar um contêiner "na mão" não muda a imagem — e some no próximo deploy.
2. **Usar `latest` em produção.** Etiqueta móvel = deploy não-determinístico. Use tags imutáveis (versão semântica ou SHA do commit).
3. **Guardar estado dentro do contêiner.** Contêiner é efêmero. Dado importante vai para **volume** (e o volume precisa de **backup**).
4. **Ordem ruim de camadas no Dockerfile.** `COPY . .` antes do `dotnet restore` destrói o cache e refaz o restore a cada build. Restaure dependências antes de copiar o código.
5. **Esquecer o `.dockerignore`.** `bin/`, `obj/`, `.git` inflam o contexto de build e invalidam cache.
6. **Colocar segredos em `ENV`/`ARG`/Dockerfile.** Vazam em `inspect` e no histórico da imagem. Use cofres gerenciados.
7. **Rodar como root.** Viola o menor privilégio; em caso de comprometimento, o estrago é maior. Defina um `USER` não-root.
8. **Imagem base gigante.** Mais peso, mais lentidão e mais CVEs. Prefira `alpine`/`distroless` e multi-stage.
9. **Confiar que `depends_on` garante "pronto".** Garante só a ordem de início, não que o serviço esteja respondendo. Implemente retry/healthcheck.
10. **Logar em arquivo dentro do contêiner.** O log morre com o contêiner. Logue em `stdout`/`stderr` para o orquestrador coletar.
11. **`docker compose down` distraído.** Pode remover volumes/redes e levar dados embora. Saiba o que as flags fazem.
12. **Esquecer o mapeamento de porta** ou a app escutando em `localhost` em vez de `0.0.0.0` — o host não alcança o serviço.

---

## 📖 Glossário rápido

- **Imagem** — artefato imutável e versionado que empacota app + dependências + SO base.
- **Contêiner** — instância em execução de uma imagem.
- **Dockerfile** — arquivo-receita com as instruções para construir uma imagem.
- **Layer (camada)** — cada instrução do Dockerfile vira uma camada; base do mecanismo de cache.
- **Tag** — rótulo de versão de uma imagem (`1.0`, `18-alpine`, `latest`).
- **Registry** — repositório de imagens (Docker Hub, ECR, ACR, GCR).
- **Volume** — armazenamento persistente que sobrevive ao contêiner.
- **Bind mount** — montagem de uma pasta do host dentro do contêiner.
- **Kernel Linux** — núcleo do SO; base de namespaces e cgroups.
- **Namespaces** — isolamento lógico (processos, rede, FS, usuários) entre contêineres.
- **Cgroups** — limites de recursos (CPU, memória) por contêiner.
- **WSL** — Windows Subsystem for Linux; permite rodar contêineres Linux no Windows.
- **Docker Compose** — orquestra múltiplos contêineres via `docker-compose.yml`.
- **YAML** — formato declarativo usado pelo Compose (e Kubernetes).
- **Multi-stage build** — Dockerfile com estágio de build (pesado) e de runtime (leve).
- **ARG** — variável só de build; **ENV** — variável de runtime.
- **Alpine / distroless** — imagens base mínimas, menor superfície de ataque.
- **Trivy** — scanner open source de vulnerabilidades em imagens.
- **CVE** — identificador de vulnerabilidade pública conhecida.
- **ECS** — Elastic Container Service (orquestrador gerenciado da AWS).
- **ECR** — Elastic Container Registry (registry da AWS).
- **Fargate** — modo serverless do ECS (sem gestão de servidores).
- **Task / Task Definition / Service / Cluster** — unidades de execução do ECS.

---

## 🔗 Como isto se conecta

Docker é a **fundação** da Fase 2. As outras três áreas se empilham sobre ele:

- **Kubernetes** — quando o número de contêineres e nós cresce, o Compose não dá conta. Kubernetes é o orquestrador padrão de mercado, com *Pods* (≈ task), *Deployments/ReplicaSets* (≈ service), *Services*, *ConfigMaps*, *Probes* e *HPA* (auto-scaling). Tudo que você aprendeu — imagem, registry, limites de recursos, healthcheck — é pré-requisito. Na disciplina você vai para o **AKS** (Azure Kubernetes Service) com esteiras de **CI/CD**.
- **Microsserviços** — cada microsserviço é empacotado e versionado como **uma imagem** e deployado como **um contêiner/serviço** independente. Conceitos como bancos distribuídos, resiliência (o retry que cobrimos no `depends_on`), HA, observabilidade e segurança vivem em cima dessa base de contêineres.
- **Mensageria** — a comunicação assíncrona (RabbitMQ, Azure Service Bus) entre os microsserviços; o próprio broker normalmente sobe **como contêiner**, e producers/consumers são serviços conteinerizados.

### No projeto FIAP Cloud Games (Fase 2 — DevOps e Serverless)
A API .NET do FCG vira uma **imagem** (multi-stage, base enxuta, usuário não-root, escaneada com Trivy), versionada por **tag imutável**, publicada no **ECR**, e executada no **ECS/Fargate** com **service** garantindo réplicas, **ELB** distribuindo tráfego, **CloudWatch** coletando logs e **IAM/Secrets Manager** cuidando de credenciais. Localmente, você reproduz a stack (API + banco) com **Docker Compose**. Esse é o fio que liga "rodar na minha máquina" a "rodar em produção na nuvem" — sem o abismo que existia na sua era client-server.

---

## ✅ Checklist de domínio

Você domina Docker para esta fase quando consegue, sem consultar:

- [ ] Explicar a diferença imagem × contêiner e VM × contêiner para um colega.
- [ ] Escrever um Dockerfile **multi-stage** para uma API ASP.NET Core com cache de camadas otimizado.
- [ ] Justificar a ordem das instruções (restore antes de copiar o código) e manter um `.dockerignore`.
- [ ] Construir, taguear (imutável), e publicar uma imagem num registry (`build`/`tag`/`push`).
- [ ] Rodar um contêiner mapeando portas, limitando CPU/memória e nomeando-o.
- [ ] Criar e montar um **volume** persistente e entender quando usar volume vs bind mount.
- [ ] Subir uma stack multi-contêiner com **Docker Compose** (API + banco em rede compartilhada, comunicação por nome de serviço).
- [ ] Diagnosticar um contêiner que não sobe usando `logs`, `exec`, `inspect` e `stats`.
- [ ] Escanear uma imagem com **Trivy** e reduzir vulnerabilidades trocando para base enxuta (Alpine/distroless).
- [ ] Aplicar segurança: usuário não-root, secrets fora da imagem, menor privilégio.
- [ ] Explicar Cluster / Service / Task / Task Definition no **ECS** e decidir entre **EC2 e Fargate**.
- [ ] Diferenciar EC2 × ECR × ECS sem hesitar.

---

## 🚀 Próximos passos

1. **Conteinerize o FCG**: escreva o Dockerfile multi-stage da API .NET e suba a stack local com Compose (API + banco).
2. **Coloque um portão de segurança**: rode Trivy contra a sua imagem e itere até zerar `CRITICAL/HIGH`.
3. **Publique no ECR** e faça um primeiro deploy no **ECS/Fargate** com um service de 2+ réplicas atrás de um ELB.
4. **Avance para Kubernetes/AKS**: remapeie mentalmente task→pod, service→deployment, e monte uma esteira de **CI/CD**.
5. **Conecte com Microsserviços e Mensageria**: quebre o monólito em serviços conteinerizados e introduza um broker (RabbitMQ/Service Bus) como contêiner.

> Você já viveu o problema que o Docker resolve durante uma carreira inteira. A boa notícia: a parte difícil — entender *por que* "na minha máquina funciona" é um pesadelo — você já sabe na pele. Agora é só virar a chave de empacotar e versionar **o ambiente junto com o código**.
