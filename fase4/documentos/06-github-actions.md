# 6. GitHub Actions

> **Disciplina de origem:** Pós-Tech FIAP — Arquitetura de Sistemas .NET — Fase 4 — *GitHub Actions*
>
> **Aulas:**
> 1. Aula 1 — Introdução
> 2. Aula 2 — Fundamentos básicos
> 3. Aula 3 — GitHub Actions em ambientes On-Premises
> 4. Aula 4 — Conceitos básicos de Docker
> 5. Aula 5 — Repositório de imagens
>
> **Convenção deste material:** o texto corrido reproduz o conteúdo das aulas. Os blocos
> **💡 Complemento** são acréscimos (esclarecimentos, atualizações e boas práticas) e **não fazem parte do
> material original**.

---

## Aula 1 - Introdução

### O que vem por aí?

Prepare-se para embarcar em uma aventura através do mundo da integração contínua e entrega contínua, ou CI/CD,
tendo nosso foco voltado para uma ferramenta poderosa e amplamente utilizada: o **GitHub Actions**. Ao longo desta
jornada, você aprenderá conceitos fundamentais e práticas recomendadas para automatizar seus fluxos de trabalho de
desenvolvimento de software, tornando-os mais eficientes, seguros e escaláveis.

Com uma abordagem prática e exemplos concretos, desvendaremos as capacidades do GitHub Actions, indo desde o básico
até recursos mais avançados. Você aprenderá como configurar seu primeiro fluxo de trabalho, integrar com diversas
ferramentas e serviços, executar testes automatizados e, finalmente, entregar de forma segura e eficaz seu software
diretamente para usuários.

Esta não é apenas uma aula: é um convite para transformar a maneira como você e sua equipe trabalham com software.
Independentemente de você ser um(a) desenvolvedor(a) individual, parte de uma pequena startup ou de um grande time
de uma empresa, as habilidades que você irá adquirir aqui têm o potencial de elevar seu trabalho a um novo patamar.

### Hands On — criando uma conta no GitHub

Neste Hands On, percorremos o processo de criação de uma conta no GitHub, uma etapa essencial para quem deseja
iniciar sua jornada no universo do desenvolvimento de software e, mais especificamente, do GitHub Actions.

Os vídeos de acompanhamento guiam cada passo, desde a visita à página inicial do GitHub até o momento em que você se
torna possuidor(a) de uma nova conta. São explicados todos os campos que você precisa preencher, as opções que pode
escolher e as configurações iniciais que pode definir para começar com o pé direito.

Passos básicos:

1. Visite o site do GitHub.
2. Clique em **"Sign up"**, no canto superior direito.
3. Preencha suas informações (nome de usuário, endereço de e-mail e senha).
4. Confirme que você não é um robô.
5. Escolha o plano que melhor se adapta às suas necessidades (o plano gratuito é suficiente para muitos usuários
   iniciantes).
6. Configure um pouco mais o seu perfil (se quiser); ou então, você pode pular este passo por enquanto.
7. Verifique seu endereço de e-mail. Acesse seu e-mail e clique no link de verificação que o GitHub enviou para você.

Depois de concluir esses passos, você terá sua própria conta no GitHub e poderá explorar ainda mais o universo do
GitHub Actions nos próximos vídeos.

*Figura 1 — Exemplo de arquitetura tradicional x virtualizada (1) (diagrama comparativo elaborado pelo autor, 2023).*

*Figura 2 — Exemplo de arquitetura tradicional x virtualizada (2) (continuação do diagrama comparativo).*

> **💡 Complemento:** as figuras 1 e 2 aparecem no Hands On sem texto explicativo. A comparação "tradicional x
> virtualizada" contrasta aplicações instaladas diretamente sobre um sistema operacional/hardware com aplicações
> executadas sobre camadas de virtualização (VMs) — ideia que será retomada na Aula 4, quando os contêineres são
> apresentados como uma forma mais leve de isolamento (compartilham o kernel do host, em vez de cada um ter um SO
> completo). Além disso, ao criar a conta, **ative a autenticação em dois fatores (2FA)** — o GitHub a exige para
> contas que contribuem com código — e prefira autenticar o `git` via SSH ou HTTPS com *Personal Access Token*
> (de preferência *fine-grained*), já que senha de conta não é aceita para operações Git por HTTPS.

### Saiba mais

O **GitHub Actions** é uma plataforma de automação de software desenvolvida pelo GitHub, incorporada diretamente no
sistema de gerenciamento de repositórios. Lançado em 2018, ele permite a criação, a personalização e a execução de
pipelines de CI/CD (Integração Contínua e Entrega Contínua) em uma interface familiar. A plataforma foi projetada
para facilitar o desenvolvimento, teste e implantação de código, proporcionando a especialistas em desenvolvimento
mais tempo para se concentrar na criação de um software de qualidade.

*Figura 3 — Fluxo GitHub Actions (fonte: GitHub, 2023): ilustra um evento no repositório disparando um workflow,
cujos jobs e steps são executados em runners.*

> **💡 Complemento:** o GitHub Actions foi anunciado em 2018 (beta) e o suporte a CI/CD ficou disponível de forma
> geral (GA) em novembro de 2019.

#### Integração contínua (CI)

Antes de nos aprofundarmos no GitHub Actions, é importante entender o conceito de CI/CD.

A **integração contínua** é um método fundamental no desenvolvimento de software, especialmente dentro da abordagem
DevOps. Essa prática envolve especialistas em desenvolvimento combinando regularmente suas alterações de código em
um repositório central. Após essa consolidação, as compilações são criadas e os testes são executados, garantindo a
coesão e a qualidade do código.

A integração contínua não se refere apenas ao estágio de compilação ou integração no processo de lançamento de
software; ela também engloba:

- um **componente de automação** (como uma ferramenta de CI ou um serviço de compilação); e
- um **componente cultural** (como a incorporação de uma mentalidade de integração frequente).

Os objetivos primordiais da integração contínua incluem:

- detecção e resolução de bugs de forma mais ágil;
- aprimoramento da qualidade geral do software;
- redução do tempo necessário para validar e implementar novas atualizações de software.

Esses aspectos contribuem para um ciclo de desenvolvimento mais eficiente e uma entrega mais rápida, o que beneficia
tanto a equipe de desenvolvimento quanto os usuários finais.

**Como era antes:** no passado, era comum que especialistas em desenvolvimento de uma equipe trabalhassem
isoladamente por extensos períodos, combinando suas alterações com a ramificação mestre apenas após a conclusão de
suas tarefas individuais. Essa abordagem fazia com que a fusão das mudanças de código se tornasse um processo
complexo e demorado. Além disso, contribuía para o acúmulo de erros não corrigidos por longos intervalos de tempo.

Esses fatores criavam barreiras significativas para a distribuição eficiente e ágil de atualizações de software. A
dificuldade em integrar diversas alterações simultâneas levava a conflitos e inconsistências, o que atrasava o
lançamento de novas versões. A ausência de uma prática regular de integração também significava que os bugs podiam
permanecer ocultos por mais tempo, comprometendo a qualidade do produto.

**Abordagem moderna:** a integração contínua contrasta com essa prática, promovendo uma colaboração mais estreita
entre membros da equipe e uma verificação constante do código. Isso facilita a detecção precoce de problemas, agiliza
o processo de desenvolvimento e garante uma entrega mais rápida e confiável de atualizações para clientes.

Com a prática de integração contínua, desenvolvedores realizam confirmações (*commits*) frequentes em um repositório
compartilhado utilizando um sistema de controle de versão, como o Git. Essa abordagem colaborativa e regular permite
que cada um deles mantenha uma conexão constante com o projeto global, refletindo as mudanças em tempo real.

Antes de cada confirmação, é comum que especialistas em desenvolvimento optem por executar **testes de unidade
locais** em seus códigos. Esses testes atuam como uma camada adicional de verificação, garantindo que as alterações
sejam compatíveis e livres de erros antes de serem integradas ao repositório central.

Além disso, um **serviço de integração contínua**, configurado para atuar automaticamente, cria e executa testes de
unidade nas novas alterações de código. Esse processo é vital para destacar e corrigir imediatamente qualquer erro ou
inconsistência. Com isso, a integração contínua promove um ciclo de desenvolvimento mais eficiente, minimizando
riscos e acelerando a entrega de um software robusto e de alta qualidade.

*Figura 4 — Fluxo DevOps (fonte: Walter, 2020): o ciclo contínuo de planejar, codificar, construir, testar,
liberar, implantar, operar e monitorar.*

#### Entrega contínua (CD)

A **distribuição contínua**, ou **entrega contínua**, é uma evolução lógica da integração contínua, sendo um
elemento crucial no panorama do desenvolvimento de aplicativos modernos. Essa prática implica que as alterações de
código são automaticamente preparadas e prontas para serem lançadas em produção.

Expandindo-se sobre a integração contínua, a distribuição contínua vai além, garantindo que todas as alterações de
código sejam automaticamente implementadas em um ambiente de teste e/ou de produção após a etapa de compilação.
Quando corretamente executada, essa abordagem assegura que especialistas em desenvolvimento sempre terão um
**artefato de compilação validado e pronto para implantação**, que já passou por um rigoroso processo de teste
padronizado.

O poder da distribuição contínua reside em sua capacidade de automatizar uma variedade de testes, além dos testes de
unidade convencionais. Isso inclui testes de:

- Interface do Usuário (IU);
- carga;
- integração;
- confiabilidade de API;
- entre outros.

Esses testes multifacetados permitem a verificação das atualizações de aplicativos em várias dimensões antes de
disponibilizá-las para clientes, aumentando a precisão na validação de atualizações e a prevenção de problemas.

Com o advento da computação em nuvem, tornou-se muito mais fácil e econômico automatizar a criação e a replicação de
vários ambientes de teste. O que antes era um desafio para se executar localmente agora pode ser feito de maneira
eficiente e escalável. Isso não só acelera o ciclo de desenvolvimento como também melhora a confiabilidade e a
qualidade do produto final.

> **💡 Complemento — Entrega contínua x Implantação contínua:** a literatura costuma distinguir:
> - **Continuous Delivery (entrega contínua):** todo commit aprovado gera um artefato pronto para produção, mas a
>   ida para produção depende de uma **aprovação manual** (um "botão").
> - **Continuous Deployment (implantação contínua):** a ida para produção é **automática**, sem intervenção humana,
>   desde que o pipeline passe.
>
> No GitHub Actions, a diferença costuma ser implementada com **environments** (`environment: production`) que exigem
> *required reviewers*: com aprovação = entrega contínua; sem aprovação = implantação contínua.

#### Leituras recomendadas

Para aprofundar seu conhecimento no GitHub Actions, é altamente recomendável explorar a documentação oficial, que
fornece visão geral, guias de início rápido, tutoriais e referências completas de sintaxe:

- GitHub Actions documentation
- Understanding GitHub Actions
- Workflow syntax for GitHub Actions
- O que significa integração contínua? (AWS)
- O que significa distribuição contínua? (AWS)

### O que você viu nesta aula?

Uma introdução sobre integração contínua e entrega contínua (CI/CD) utilizando o GitHub Actions. Isso envolve
automatizar os processos de desenvolvimento de software para torná-los mais eficientes e seguros. Além disso, você
entendeu como configurar fluxos de trabalho automatizados, realizar testes automáticos e entregar software de forma
segura a usuários. Essas habilidades têm o potencial de transformar a maneira como você e sua equipe trabalham com
software, independentemente do tamanho dela ou da empresa.

**Palavras-chave:** GitHub, CI/CD, Action, GitHub Actions, Integração Contínua, Entrega Contínua.

### Referências da aula

- AWS. *O que significa distribuição contínua?* — <https://aws.amazon.com/pt/devops/continuous-delivery/>
- AWS. *O que significa integração contínua?* — <https://aws.amazon.com/pt/devops/continuous-integration/>
- GitHub. *GitHub Actions* — <https://github.com/actions>
- GitHub Docs. *GitHub Actions documentation* — <https://docs.github.com/en/actions>
- GitHub Docs. *Understanding GitHub Actions* — <https://docs.github.com/en/actions/learn-github-actions/understanding-github-actions>
- GitHub Docs. *Workflow syntax for GitHub Actions* — <https://docs.github.com/en/actions/using-workflows/workflow-syntax-for-github-actions>
- WALTER, M. *5 dicas para aplicar DevOps na sua empresa* (2020) — <https://www.objective.com.br/insights/5-dicas-para-aplicar-devops/>

### Pontos-chave

- GitHub Actions é a plataforma de automação/CI/CD integrada ao próprio repositório GitHub.
- **CI** = integrar código com frequência em um repositório central, com build e testes automáticos a cada mudança.
- CI tem um lado de **automação** (ferramenta/serviço) e um lado **cultural** (integrar cedo e sempre).
- Integrar raramente gera *merges* dolorosos, conflitos e bugs ocultos por muito tempo.
- **CD** estende a CI: todo commit validado vira um artefato pronto para implantar em teste e/ou produção.
- CD automatiza testes além dos unitários: UI, carga, integração, confiabilidade de API.
- A nuvem barateou a criação e replicação de ambientes de teste.

---

## Aula 2 - Fundamentos básicos

### O que vem por aí?

Nesta jornada, você vai desvendar os mistérios do GitHub Actions e explorar um mundo em que integração
contínua/entrega contínua (CI/CD), automação de tarefas e processos são a norma, não a exceção. Imagine o poder de
testar, construir e implantar seu código diretamente de seu repositório Git.

### Hands On

#### Configuração inicial

1. Crie um novo repositório no GitHub. Ele será utilizado para experimentar e testar o GitHub Actions.
2. Clone o repositório em sua máquina local usando `git clone`.

#### Implementando CI/CD com GitHub Actions

1. **Crie um arquivo de fluxo de trabalho:** na raiz do seu repositório, crie uma pasta chamada `.github/workflows`
   e, dentro dela, um arquivo chamado `ci-cd.yml`.
2. **Configure o fluxo de trabalho:** abra `ci-cd.yml` e adicione o seguinte conteúdo:

```yaml
name: CI/CD Pipeline

on:
  push:
    branches:
      - main

jobs:
  build-and-test:
    runs-on: ubuntu-latest

    steps:
      - name: Checkout code
        uses: actions/checkout@v2

      - name: Set up Node.js
        uses: actions/setup-node@v2
        with:
          node-version: '14'

      - name: Install dependencies
        run: npm install

      - name: Run tests
        run: npm test
```

3. **Faça push do arquivo:** use `git add`, `git commit` e `git push` para adicionar e enviar seu arquivo de fluxo
   de trabalho ao repositório do GitHub.
4. **Verifique o GitHub Actions:** vá ao seu repositório no GitHub e clique na aba **"Actions"**; você deverá ver seu
   fluxo de trabalho CI/CD em execução.

```bash
git add .github/workflows/ci-cd.yml
git commit -m "Adiciona pipeline de CI/CD"
git push
```

> **💡 Complemento — atualização de versões:** o exemplo da aula usa versões **desatualizadas**:
> - `actions/checkout@v2` e `actions/setup-node@v2` rodavam em Node 12, *runtime* já removido dos runners
>   hospedados. Use no mínimo `actions/checkout@v4` / `actions/setup-node@v4`; as versões mais novas (v5+) usam
>   Node 24, pois o GitHub está descontinuando actions baseadas em Node 20. Consulte a página de *releases* de cada
>   action para a versão vigente.
> - `node-version: '14'` está fora de suporte (EOL em 2023). Use uma versão LTS ativa (ex.: `'22'`).
>
> Versão equivalente para um projeto **.NET** (o foco do curso):
>
> ```yaml
> name: CI
>
> on:
>   push:
>     branches: [ main ]
>   pull_request:
>     branches: [ main ]
>
> permissions:
>   contents: read
>
> jobs:
>   build-and-test:
>     runs-on: ubuntu-latest
>     steps:
>       - uses: actions/checkout@v4
>       - uses: actions/setup-dotnet@v4
>         with:
>           dotnet-version: '8.0.x'
>           cache: true                      # cache de NuGet (requer packages.lock.json)
>           cache-dependency-path: '**/packages.lock.json'
>       - run: dotnet restore --locked-mode
>       - run: dotnet build --no-restore -c Release
>       - run: dotnet test --no-build -c Release --logger trx
> ```
>
> Para o cache funcionar com `setup-dotnet`, habilite `<RestorePackagesWithLockFile>true</RestorePackagesWithLockFile>`
> nos projetos (gera `packages.lock.json`). Alternativa: `actions/cache` apontando para `~/.nuget/packages`.

### Saiba mais

Para solidificar seu entendimento, a aula traz um guia teórico que contém:

- uma introdução detalhada ao GitHub Actions;
- explicações dos principais conceitos (Workflows, Eventos, Jobs, Passos, Ações);
- imagens que ilustram o fluxo e a estrutura de um workflow, interação de eventos, execução de jobs, funcionamento
  dos passos e uso de ações;
- exemplos detalhados e comentários;
- referências para documentação oficial e recursos adicionais.

O GitHub Actions é uma ferramenta poderosa de automação que permite criar, testar e implantar aplicativos
diretamente do GitHub. É uma solução completa para integração contínua e entrega contínua (CI/CD) que facilita a
automação de todas as suas tarefas de desenvolvimento de software.

Esta ferramenta permite configurar **"actions"** em resposta a eventos específicos no GitHub, como fazer push para
um repositório ou criar uma pull request. Uma ação é um pedaço reutilizável de código que executa uma tarefa, como
fazer build de um projeto ou executar testes. Você pode combinar ações em **"workflows"**, que definem uma sequência
de ações a serem executadas.

A grande vantagem do GitHub Actions é sua **integração direta com o GitHub**: você pode automatizar tarefas
diretamente de seus repositórios, sem precisar de uma ferramenta externa de CI/CD. Além disso, o GitHub Actions é
altamente flexível e personalizável: você pode usar ações predefinidas do GitHub ou da comunidade, ou ainda criar
suas próprias ações para atender às suas necessidades específicas.

#### Principais conceitos

| Conceito | Definição |
|---|---|
| **Workflows** | Pipelines de automação definidos no repositório. Um fluxo de trabalho é composto por um ou mais jobs e especifica quando e em que circunstâncias esses jobs devem ser executados. |
| **Triggers** (eventos) | Atividades específicas que acionam a execução de um fluxo de trabalho. Ex.: um push para o repositório, uma pull request ou até mesmo um cronograma definido. |
| **Jobs** | Partes constituintes dos fluxos de trabalho. Um job é uma série de passos executados na mesma instância de runner. |
| **Steps** | Comandos individuais que compõem um job. Cada passo em um job executa uma única ação (ou script). |
| **Actions** | O menor bloco de construção de um fluxo de trabalho. Uma ação é um pedaço de código reutilizável que um passo pode executar. |

*Figura 1 — Fluxo de Steps (elaborado pelo autor, 2023): mostra a hierarquia evento → workflow → jobs → steps →
actions, executados em um runner.*

> **💡 Complemento:** falta na tabela um conceito central: o **runner** — a máquina (VM ou contêiner) que executa
> um job. Pode ser **GitHub-hosted** (`ubuntu-latest`, `windows-latest`, `macos-latest`) ou **self-hosted** (tema
> da Aula 3). Cada job roda em um runner novo e isolado; por isso arquivos gerados em um job **não** estão
> disponíveis em outro, a menos que você use *artifacts* (`actions/upload-artifact` / `actions/download-artifact`)
> ou *outputs* de job.

#### Workflows

Um **workflow** é a definição de um processo automatizado que você configura no seu repositório. Fluxos de trabalho
são compostos por um ou mais "jobs", ou tarefas, e podem ser acionados por vários "eventos" do GitHub.

Eles são armazenados como arquivos `.yml` ou `.yaml`, na pasta `.github/workflows` do seu repositório. Cada arquivo
de fluxo de trabalho define uma única pipeline de automação. Um workflow básico pode parecer algo assim:

```yaml
name: Meu primeiro fluxo de trabalho

on: [push]

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout code
        uses: actions/checkout@v2
```

Este exemplo define um workflow chamado "Meu primeiro fluxo de trabalho", que é acionado sempre que ocorre um "push"
no repositório. Há um "job" chamado `build` que é executado na última versão do Ubuntu. Esse job tem um "step" que
usa a ação `actions/checkout@v2` para realizar o checkout do código do repositório.

#### Eventos

Os **eventos** são atividades específicas que acionam a execução de um fluxo de trabalho. O GitHub Actions suporta
uma grande variedade de eventos, incluindo:

- **`push`**: aciona o fluxo de trabalho cada vez que alguém faz push para o repositório.
- **`pull_request`**: aciona o fluxo de trabalho cada vez que alguém abre uma pull request.
- **`schedule`**: aciona o fluxo de trabalho em um cronograma definido (por exemplo: todos os dias à meia-noite).

Você pode configurar seu workflow para ser acionado por um ou mais eventos. Por exemplo:

```yaml
on:
  push:
    branches: [ master ]
  pull_request:
    branches: [ master ]
```

Neste exemplo, o fluxo de trabalho é acionado por push ou pull request no branch `master`.

Lembre-se de que os workflows e eventos são a espinha dorsal do GitHub Actions, proporcionando a estrutura básica
sobre a qual você pode construir pipelines de automação complexos e poderosos.

> **💡 Complemento — outros eventos e filtros úteis:**
> - `workflow_dispatch`: disparo manual pela aba Actions (aceita `inputs`).
> - `schedule` usa sintaxe **cron em UTC**: `- cron: '0 3 * * *'` (todo dia às 03:00 UTC = 00:00 em Brasília).
> - `pull_request` por padrão dispara nos tipos `opened`, `synchronize` e `reopened` (não só na abertura).
> - `paths` / `paths-ignore` limitam o disparo a mudanças em determinadas pastas — essencial em monorepos com
>   várias APIs: `on: push: paths: ['src/UsersAPI/**']`.
> - `workflow_call`: transforma o workflow em **reusable workflow**, chamado por outros com `uses:` no nível do job.
> - Hoje o branch padrão do GitHub é `main` (não mais `master`); ajuste os filtros conforme o seu repositório.

#### Jobs

Os **jobs** são os blocos de construção individuais de um fluxo de trabalho do GitHub Actions. Cada um deles
representa uma fase do seu pipeline de CI/CD e é composto por um ou mais passos que são executados na mesma instância
do runner. Um fluxo de trabalho pode conter múltiplos jobs que são executados **em paralelo ou sequencialmente**,
dependendo das necessidades do seu pipeline.

Um job tem sua própria configuração de ambiente e é executado de forma independente em sua máquina virtual. Isso
permite que você configure diferentes ambientes para diferentes jobs. Por exemplo: um job pode ser executado em um
runner baseado em Linux e outro em um runner baseado em Windows.

```yaml
jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout code
        uses: actions/checkout@v2

  test:
    runs-on: windows-latest
    steps:
      - name: Checkout code
        uses: actions/checkout@v2
      - name: Run tests
        run: dotnet test
```

Neste exemplo, temos dois jobs. O job `build` é executado no ambiente Ubuntu mais recente, enquanto o job `test` é
executado no ambiente Windows mais recente. Ambos fazem checkout do código do repositório, mas o job `test` também
executa um comando para testar o código.

> **💡 Complemento:** por padrão, jobs rodam **em paralelo**. Para criar ordem, use `needs:` (ex.: `needs: build`).
> Para testar em várias combinações sem duplicar YAML, use **matrix**:
>
> ```yaml
> jobs:
>   test:
>     strategy:
>       fail-fast: false
>       matrix:
>         os: [ubuntu-latest, windows-latest]
>         dotnet: ['8.0.x', '10.0.x']
>     runs-on: ${{ matrix.os }}
>     steps:
>       - uses: actions/checkout@v4
>       - uses: actions/setup-dotnet@v4
>         with:
>           dotnet-version: ${{ matrix.dotnet }}
>       - run: dotnet test
> ```

#### Steps

Já **steps** são as tarefas individuais executadas dentro de um job. Cada passo pode executar uma única ação ou um
script. Os passos podem:

- executar comandos shell;
- executar ações, que são pedaços de código reutilizável que podem ser executados como parte do seu job.

```yaml
steps:
  - name: Checkout code
    uses: actions/checkout@v2

  - name: Install dependencies
    run: npm install

  - name: Run tests
    run: npm test
```

Neste exemplo, temos três passos. O primeiro usa a ação `actions/checkout@v2` para fazer checkout do código do
repositório; o segundo executa o comando `npm install` para instalar as dependências e o terceiro executa o comando
`npm test` para testar o código.

Compreender os conceitos de jobs e passos é fundamental para construir fluxos de trabalho eficazes no GitHub Actions.
Eles permitem que você estruture sua pipeline de CI/CD de maneira lógica e modular.

> **💡 Complemento:** `uses:` executa uma action; `run:` executa comandos no shell do runner (bash no Linux,
> PowerShell (`pwsh`) no Windows por padrão). Steps de um mesmo job compartilham o sistema de arquivos e podem
> trocar dados via `$GITHUB_ENV` (variáveis) e `$GITHUB_OUTPUT` (outputs com `id:`). Condicionais com `if:`
> (ex.: `if: github.ref == 'refs/heads/main'`) evitam, por exemplo, deploy a partir de PRs.

#### Actions

As **ações** são o menor bloco de construção em um fluxo de trabalho do GitHub Actions e encapsulam sequências de
comandos ou rotinas executadas como parte de um passo. Elas podem ser pequenas tarefas, como fazer checkout do
código, instalar dependências e executar testes, ou ações mais complexas, que interagem com outros serviços.

Uma das grandes vantagens do GitHub Actions é a grande variedade de ações predefinidas disponíveis, desenvolvidas
pelo GitHub e pela comunidade. Elas cobrem muitas tarefas comuns de CI/CD, facilitando a construção de fluxos de
trabalho complexos.

Exemplo de como uma ação é usada em um fluxo de trabalho:

```yaml
steps:
  - name: Checkout code
    uses: actions/checkout@v2
```

Neste exemplo, usamos a `actions/checkout@v2`, uma ação predefinida fornecida pelo GitHub. Ela faz checkout do
código do seu repositório para o runner, para que possa ser construído, testado ou implantado.

As ações podem ser **reutilizadas** entre vários fluxos de trabalho e repositórios, tornando mais fácil manter e
atualizar seus fluxos de trabalho. Você pode até mesmo compartilhar suas ações com a comunidade do GitHub
(Marketplace), tornando-as disponíveis para outros especialistas em desenvolvimento.

Se as ações predefinidas não atenderem às suas necessidades, você pode criar suas próprias **ações
personalizadas**, que podem ser um script simples ou um programa complexo, dependendo das necessidades do seu fluxo
de trabalho. As ações personalizadas são armazenadas em seus próprios repositórios e podem ser escritas em qualquer
linguagem que possa ser executada em um runner do GitHub Actions.

Compreender as ações e como usá-las efetivamente é a chave para aproveitar ao máximo o GitHub Actions: elas
permitem automatizar tarefas complexas, simplificar fluxos de trabalho e compartilhar código com a comunidade.

> **💡 Complemento — tipos de action e reuso:**
> - Há três tipos de action personalizada: **JavaScript** (Node), **Docker container action** e **composite
>   action** (sequência de steps em `action.yml`). As referências da aula citam "Criando uma ação de contêiner do
>   Docker".
> - **Composite action** reutiliza *steps*; **reusable workflow** (`on: workflow_call`) reutiliza *jobs inteiros*
>   (com runners, environments e secrets próprios). Para várias APIs com o mesmo pipeline, um reusable workflow
>   evita copiar e colar YAML.

#### Aplicações práticas

O GitHub Actions pode ser aplicado de várias maneiras para melhorar e automatizar seus fluxos de trabalho:

- **Integração Contínua/Entrega Contínua (CI/CD):** automatizar a construção, teste e implantação de seu código.
  Por exemplo: cada vez que você faz push para o branch principal, o GitHub Actions pode construir seu projeto,
  executar todos os testes e depois implantar o código para o ambiente de produção se todos os testes passarem.

```yaml
on:
  push:
    branches:
      - main

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout code
        uses: actions/checkout@v2
      - name: Build
        run: make
      - name: Test
        run: make test

  deploy:
    needs: build
    runs-on: ubuntu-latest
    steps:
      - name: Deploy
        run: make deploy
```

- **Automação de Issues e Pull Requests:** automatizar o gerenciamento de issues e pull requests. Por exemplo:
  configurar um fluxo de trabalho para adicionar automaticamente etiquetas (*labels*) a novas issues ou para fechar
  pull requests que não têm atividade há certo tempo.

> **💡 Complemento:** no exemplo, `needs: build` garante que `deploy` só rode se `build` terminar com sucesso.
> Observe que o job `deploy` **não faz checkout** — como cada job roda em um runner novo, um `make deploy` real
> precisaria de `actions/checkout` ou de um artifact produzido no job anterior. Para issues/PRs inativos existe a
> action oficial `actions/stale`; para rotular PRs por caminho, `actions/labeler`.

#### Melhores práticas

- **Segurança:** tenha cuidado ao usar ações de terceiros. Elas têm os mesmos privilégios que o seu workflow e podem
  executar código malicioso. Use ações de fontes confiáveis e **sempre as fixe em uma versão específica**, para
  evitar mudanças inesperadas.
- **Otimização de recursos:** os minutos do GitHub Actions são limitados, então é importante otimizar seus fluxos de
  trabalho. Utilize estratégias como a **matriz de jobs**, para testar em vários ambientes em paralelo, e use
  **ações de cache** para acelerar a instalação de dependências.
- **Documentação:** mantenha sua configuração do GitHub Actions bem documentada para que outras pessoas possam
  entender e contribuir. Comente seu código e forneça uma descrição clara do que cada fluxo de trabalho faz.

> **💡 Complemento — segurança na prática:**
> - **Fixar por SHA:** tags como `@v4` são móveis e podem ser reapontadas por quem controla o repositório da
>   action. O único pin imutável é o **SHA completo do commit**: `uses: actions/checkout@<sha-de-40-caracteres> # v4.x.y`.
>   Em março de 2025, a action `tj-actions/changed-files` foi comprometida e suas tags foram reapontadas para código
>   que vazava secrets nos logs — quem usava SHA não foi afetado. O **Dependabot** (`package-ecosystem:
>   github-actions`) mantém esses SHAs atualizados.
> - **`permissions` mínimas:** declare no topo `permissions: contents: read` e conceda o resto por job
>   (`id-token: write` só onde há OIDC, `packages: write` só onde publica no GHCR etc.). O `GITHUB_TOKEN` passa a
>   ter só o necessário.
> - **Secrets:** use *repository/environment secrets* (`${{ secrets.NOME }}`), nunca valores no YAML. Cuidado com
>   `pull_request_target` e com interpolar `${{ github.event.* }}` diretamente em `run:` (risco de *script
>   injection*) — passe por variável de ambiente.
> - **`concurrency`:** evita execuções simultâneas concorrendo pelo mesmo deploy:
>   `concurrency: { group: deploy-${{ github.ref }}, cancel-in-progress: false }`.
> - **`timeout-minutes`** por job evita runners presos consumindo minutos (o padrão é 360 minutos).

### O que você viu nesta aula?

Você aprendeu a utilizar o GitHub Actions para integração contínua/entrega contínua (CI/CD) e automação de tarefas.
Também explorou como testar, construir e implantar seu código diretamente de seu repositório Git e ganhou habilidades
em configuração de fluxos de trabalho personalizados, testes automatizados, implantação segura e integração com
ferramentas externas.

**Palavras-chave:** CI/CD, Integração, Jobs, Marketplace, Integração Contínua, Entrega Contínua, GitHub, GitHub
Actions, Pipelines.

### Referências da aula

- GitHub Docs. *Criando uma ação de contêiner do Docker* — <https://docs.github.com/pt/actions/creating-actions/creating-a-docker-container-action>
- GitHub Docs. *Criar ações* — <https://docs.github.com/pt/actions/creating-actions>
- GitHub Docs. *Documentação do GitHub Actions* — <https://docs.github.com/pt/actions>
- GitHub Docs. *Entendendo o GitHub Actions* — <https://docs.github.com/pt/actions/learn-github-actions/understanding-github-actions>
- GitHub Docs. *Eventos que disparam fluxos de trabalho* — <https://docs.github.com/pt/actions/using-workflows/events-that-trigger-workflows>
- GitHub Docs. *Fortalecimento de segurança para o GitHub Actions* — <https://docs.github.com/pt/actions/security-guides/security-hardening-for-github-actions>
- GitHub Docs. *Jobs* e *jobs.<job_id>.steps* — <https://docs.github.com/pt/actions/learn-github-actions/workflow-syntax-for-github-actions#jobs>
- GitHub Docs. *Sintaxe de fluxo de trabalho para o GitHub Actions* — <https://docs.github.com/pt/actions/learn-github-actions/workflow-syntax-for-github-actions>
- GitHub Docs. *Sobre fluxos de trabalho (build matrix)* — <https://docs.github.com/pt/actions/using-workflows/about-workflows#using-a-build-matrix>
- GitHub Marketplace. *Actions* — <https://github.com/marketplace?type=actions>

### Pontos-chave

- Workflows ficam em `.github/workflows/*.yml` e cada arquivo é um pipeline.
- Hierarquia: **evento (trigger) → workflow → jobs → steps → actions**, executados em **runners**.
- Eventos comuns: `push`, `pull_request`, `schedule` (e, como complemento, `workflow_dispatch`).
- Jobs rodam em paralelo por padrão, cada um em sua própria VM; `needs:` cria dependência/sequência.
- Steps usam `uses:` (action reutilizável) ou `run:` (comando shell).
- Actions vêm do GitHub, da comunidade (Marketplace) ou são criadas por você.
- Boas práticas: fixar versões de actions (idealmente por SHA), usar matrix e cache, documentar workflows.

---

## Aula 3 - GitHub Actions em ambientes On-Premises

### O que vem por aí?

Nesta jornada, mergulhamos no universo do GitHub Actions para **ambientes On-Premises**. Você perceberá que esta é
mais do que apenas uma ferramenta de integração e entrega contínua: é uma poderosa aliada que impulsiona a
produtividade e a eficácia da equipe.

### Hands On

Durante a aula prática, é demonstrado como configurar o GitHub Actions em um ambiente On-Premises, nas seguintes
etapas:

1. Instalação e configuração de um servidor local (On-Premises) adequado para o GitHub Actions.
2. Configuração do GitHub Actions nesse servidor, demonstrando o processo de criação e gerenciamento de workflows.
3. Uso de ações para automatizar tarefas, como compilação de código, execução de testes e implantação de software.
4. Apresentação de cenários reais de uso e de como o GitHub Actions lida com eles no ambiente On-Premises.

> **💡 Complemento — registrando um self-hosted runner (passo a passo de referência):** o PDF não traz os comandos;
> o fluxo oficial é:
> 1. No repositório (ou organização): **Settings → Actions → Runners → New self-hosted runner**, escolha o SO e a
>    arquitetura. A página exibe os comandos com a versão atual e um **token de registro temporário**.
> 2. No servidor (Linux), algo como:
>
> ```bash
> mkdir actions-runner && cd actions-runner
> # baixe o pacote indicado na página (a URL/versão muda a cada release)
> curl -o actions-runner-linux-x64.tar.gz -L <URL-exibida-na-pagina>
> tar xzf ./actions-runner-linux-x64.tar.gz
> ./config.sh --url https://github.com/<owner>/<repo> --token <TOKEN> --labels onprem,linux
> ./run.sh                     # execução interativa, para teste
> sudo ./svc.sh install        # ou instale como serviço (systemd)
> sudo ./svc.sh start
> ```
>
> 3. No workflow, direcione o job ao runner pelos labels:
>
> ```yaml
> jobs:
>   deploy-local:
>     runs-on: [self-hosted, linux, onprem]
>     steps:
>       - uses: actions/checkout@v4
>       - run: dotnet publish -c Release -o ./out
> ```
>
> No Windows, o `config.cmd` oferece instalar o runner como serviço do Windows. O runner se conecta ao GitHub por
> **HTTPS de saída** (*long polling*), portanto **não é preciso abrir portas de entrada** no firewall.

### Saiba mais

#### O que são ambientes On-Premises

Ambientes On-Premises são infraestruturas de TI mantidas fisicamente dentro dos limites da organização, ao contrário
dos serviços em nuvem, que são hospedados remotamente e acessados através da Internet. O termo "on-premises" é
originário do inglês e significa "no local".

#### Vantagens dos ambientes On-Premises

- **Controle total:** a organização tem controle total sobre seus sistemas e dados, o que pode ser crucial para
  empresas que lidam com informações sensíveis. Isso também permite personalização completa do ambiente para atender
  às necessidades específicas da organização.
- **Segurança:** embora os provedores de nuvem invistam muito em segurança, ter um ambiente On-Premises pode
  proporcionar maior controle sobre aspectos de segurança, uma vez que a organização define e implementa suas
  próprias políticas.
- **Conformidade:** algumas regulamentações podem exigir que os dados sejam armazenados localmente. Nestes casos, um
  ambiente On-Premises pode ser mais apropriado.

#### Desvantagens dos ambientes On-Premises

- **Custo:** manter um ambiente On-Premises pode ser caro. Os custos incluem não apenas o hardware, mas também
  manutenção, atualização, segurança e a necessidade de pessoal qualificado para gerir o ambiente.
- **Escalabilidade:** em contraste com a nuvem, os ambientes On-Premises não são tão facilmente escaláveis. A adição
  de mais capacidade requer planejamento, compra e instalação de novos servidores.
- **Tempo de inatividade e recuperação:** os provedores de nuvem geralmente possuem recursos robustos de redundância
  e recuperação de desastres. Já em um ambiente On-Premises, a empresa é responsável por garantir a redundância e a
  recuperação de desastres, o que pode ser caro e complexo.

Entender as diferenças entre os ambientes On-Premises e em nuvem é crucial para escolher a melhor estratégia para sua
organização. A decisão dependerá das necessidades específicas da empresa, como requisitos de conformidade, controle
de dados, segurança, custo e escalabilidade.

#### Runners hospedados x auto-hospedados (self-hosted)

Os **runners** do GitHub Actions desempenham um papel crucial quando se trata de integrá-lo a ambientes
On-Premises. Runners são agentes que hospedam a execução dos jobs em um workflow do GitHub Actions. O GitHub fornece
runners hospedados em sua infraestrutura, mas em muitos casos — especialmente com ambientes On-Premises — pode ser
mais benéfico utilizar **runners auto-hospedados** (*self-hosted*).

Situações em que você pode querer usar runners auto-hospedados em vez dos hospedados pelo GitHub:

- **Requisitos de hardware ou software específicos:** os runners hospedados pelo GitHub têm um conjunto fixo de
  hardware e software. Se seus jobs precisam de um tipo específico de hardware ou de uma versão específica de
  software indisponível nos runners hospedados, você pode configurar seus próprios runners com o necessário.
- **Restrições de rede:** se seus jobs precisam acessar recursos dentro da sua rede interna, ou se suas políticas de
  segurança não permitem que os jobs sejam executados na nuvem, você pode usar runners auto-hospedados para manter a
  execução dentro da sua rede.
- **Capacidade de controle e gerenciamento:** com runners auto-hospedados, você tem total controle sobre a
  infraestrutura de execução do job, gerenciando atualizações de software, patches de segurança e monitoramento de
  acordo com suas próprias políticas e cronogramas.
- **Custos de execução de jobs:** embora o GitHub forneça certa quantidade de minutos gratuitos para os runners
  hospedados, você pode incorrer em custos se exceder essa quantidade. Se você tem seus próprios servidores ou muita
  capacidade de computação ociosa, pode ser mais econômico usar runners auto-hospedados.
- **Configuração personalizada:** os runners auto-hospedados permitem total controle sobre o ambiente de execução,
  com o software, dependências e ferramentas necessárias para sua base de código e aplicativos.
- **Desempenho:** em algumas situações, pode ser mais rápido executar jobs em máquinas locais, especialmente se a
  carga de trabalho exigir quantidade significativa de recursos de computação.

Ao mesmo tempo, o uso de runners auto-hospedados vem com **responsabilidades adicionais**: você precisará gerenciar e
manter os runners, incluindo garantir que estejam seguros e atualizados, e será responsável por qualquer custo
associado à infraestrutura. Portanto, a decisão deve considerar o *trade-off* entre **controle e conveniência**.

| Aspecto | GitHub-hosted | Self-hosted |
|---|---|---|
| Manutenção | Feita pelo GitHub | Sua responsabilidade (SO, runner, patches) |
| Hardware/software | Conjunto fixo | Personalizável |
| Acesso à rede interna | Não (por padrão) | Sim |
| Custo | Minutos incluídos no plano + excedente | Infraestrutura própria |
| Ambiente a cada job | Limpo (VM nova) | Persistente, a menos que configurado como efêmero |

*(Tabela de síntese organizada a partir do texto da aula; a última linha é complemento.)*

#### Boas práticas para runners auto-hospedados

- **Isolamento de workloads:** separe os workloads de produção dos de desenvolvimento/teste. É uma boa prática de
  segurança e ajuda a evitar contaminação cruzada entre diferentes tipos de workloads.
- **Gerenciamento de atualizações:** mantenha seus runners atualizados — tanto o software do runner quanto o sistema
  operacional e outras dependências —, evitando problemas de compatibilidade e protegendo contra as vulnerabilidades
  mais recentes.
- **Segurança do runner:** restrinja o acesso ao seu runner, limitando quem pode enviar jobs para ele e quais ações
  ele pode realizar. Evite armazenar segredos ou outras informações sensíveis no runner.
- **Monitoramento e logging:** configure monitoramento e logging adequados para detectar e resolver problemas
  rapidamente. Os logs também são úteis para auditoria e conformidade.
- **Recuperação de desastres e redundância:** planeje cenários de falha, como runners de backup ou um plano para
  migrar rapidamente para os runners hospedados pelo GitHub, se necessário.
- **Rotatividade regular de runners:** por segurança, reinicie regularmente seus runners ou configure-os para serem
  **efêmeros**, reduzindo o risco de ameaça persistente caso um ator mal-intencionado comprometa o runner.
- **Gerenciamento de capacidade:** monitore a utilização dos runners e planeje a capacidade conforme as necessidades
  da equipe — adicionando runners em períodos de alto uso ou configurando runners com hardware diferente para tipos
  de jobs diferentes.

Essas são diretrizes gerais; as melhores práticas específicas podem variar conforme suas necessidades e seu
ambiente. É importante equilibrar segurança, eficiência e conveniência.

> **💡 Complemento — segurança de self-hosted runners:**
> - **Nunca use self-hosted runners em repositórios públicos.** Qualquer pessoa pode abrir um PR de um fork e
>   executar código arbitrário na sua máquina (e, a partir dela, na sua rede interna). A própria documentação do
>   GitHub faz essa recomendação.
> - **Runners efêmeros:** `./config.sh --ephemeral` faz o runner aceitar **um único job** e se desregistrar; combine
>   com recriação automática da VM/contêiner. Em Kubernetes, o **Actions Runner Controller (ARC)** com *runner scale
>   sets* cria pods de runner sob demanda e os destrói após cada job.
> - **Runner groups** (em organizações) restringem quais repositórios e workflows podem usar cada grupo de runners
>   — ex.: um grupo "produção" acessível só ao repositório de deploy.
> - Execute o serviço com um **usuário sem privilégios** (não root/Administrator) e evite dar ao runner acesso ao
>   socket do Docker do host sem necessidade (equivale a root no host).
> - Prefira credenciais de curta duração (OIDC, ver Aula 5/Tech Challenge) a chaves gravadas no disco do runner.
> - Alternativa gerenciada: os **larger runners** do GitHub (com IP estático e, no plano Enterprise, rede privada
>   via Azure) atendem parte dos casos de "rede/hardware específico" sem que você mantenha servidores.

#### Limites de uso com runners auto-hospedados

Existem alguns limites no uso do GitHub Actions com runners auto-hospedados (sujeitos a alterações):

| Limite | Valor |
|---|---|
| Tempo de execução do workflow | Cada execução de workflow é limitada a **35 dias**; ao atingir o limite, é cancelada. Inclui duração da execução, tempo em espera e aprovação. |
| Tempo na fila do job | Cada job para runners auto-hospedados pode ficar em fila por no máximo **24 horas**; se nenhum runner começar a executá-lo nesse prazo, o job é terminado e falha. |
| Requisições à API | Até **1.000 requisições por hora** à API do GitHub, somando todas as ações de um repositório. Excedido o limite, chamadas adicionais falham, o que pode fazer jobs falharem. |
| Matriz de jobs | No máximo **256 jobs** por execução de workflow (vale para runners hospedados e auto-hospedados). |
| Fila de execução do workflow | No máximo **500 execuções** de workflow enfileiradas em um intervalo de 10 segundos por repositório; acima disso, a execução é terminada e falha. |
| Registro de runners | No máximo **10.000 runners** auto-hospedados por grupo de runners. |

Em resumo, os runners auto-hospedados são uma parte essencial da utilização do GitHub Actions em ambientes
On-Premises. Eles fornecem a ponte necessária para que o GitHub Actions interaja de maneira eficaz e segura com a
infraestrutura local.

> **💡 Complemento:** além desses limites, um **job** em self-hosted runner pode durar até **5 dias** (em runners
> hospedados pelo GitHub, até **6 horas**). O limite de 1.000 requisições/hora refere-se ao `GITHUB_TOKEN` por
> repositório. Limites e preços mudam com frequência — o GitHub revisou a precificação de Actions em 2025/2026 —,
> então confira a página *"Usage limits, billing, and administration"* antes de dimensionar.

### O que você viu nesta aula?

- Ambientes On-Premises são infraestruturas de TI localizadas fisicamente na empresa, diferentemente dos serviços em
  nuvem. **Vantagens:** controle total sobre sistemas e dados, maior controle sobre a segurança e adequação a
  regulamentações que exigem armazenamento local. **Desvantagens:** custos elevados com hardware, manutenção,
  atualização e pessoal; dificuldade em escalar rapidamente; responsabilidade total sobre redundância e recuperação
  de desastres.
- Runners são agentes que hospedam a execução de jobs no GitHub Actions; podem ser hospedados pelo GitHub ou
  auto-hospedados. Vantagens dos auto-hospedados: suporte a requisitos específicos de hardware e software,
  atendimento a restrições de rede, maior controle e gerenciamento, possível economia, configuração personalizada e
  potencial de melhor desempenho. Desafios: responsabilidade total pela manutenção e segurança e custo de
  infraestrutura própria.
- Boas práticas: isolar workloads de produção e desenvolvimento/teste; manter runners atualizados; restringir o
  acesso; implementar monitoramento e logs; ter planos de recuperação de desastres e redundância; reiniciar runners
  periodicamente; monitorar a capacidade de uso.
- Limitações: máximo de 35 dias por execução de workflow; 24 horas em fila por job; 1.000 requisições à API por hora
  por repositório; 256 jobs por matriz; 500 execuções em fila a cada 10 segundos por repositório; 10.000 runners por
  grupo.

**Palavras-chave:** GitHub, GitHub Actions, On-Premises, Self-Hosted Runner, Pipelines, Build, Release.

### Referências da aula

- GitHub Docs. *About self-hosted runners* — <https://docs.github.com/en/actions/hosting-your-own-runners/managing-self-hosted-runners/about-self-hosted-runners>
- GitHub Docs. *Adding self-hosted runners* — <https://docs.github.com/en/actions/hosting-your-own-runners/managing-self-hosted-runners/adding-self-hosted-runners>
- GitHub Docs. *Configuring the self-hosted runner application as a service* — <https://docs.github.com/en/actions/hosting-your-own-runners/managing-self-hosted-runners/configuring-the-self-hosted-runner-application-as-a-service>
- GitHub Docs. *Security hardening for GitHub Actions* — <https://docs.github.com/en/actions/security-guides/security-hardening-for-github-actions>
- GitHub Docs. *Sobre executores auto-hospedados* — <https://docs.github.com/pt/actions/hosting-your-own-runners/managing-self-hosted-runners/about-self-hosted-runners>
- GitHub Docs. *Usage limits, billing, and administration* — <https://docs.github.com/en/actions/learn-github-actions/usage-limits-billing-and-administration>

### Pontos-chave

- On-Premises = infraestrutura dentro da organização; troca escalabilidade/conveniência por controle e conformidade.
- Runner é o agente que executa jobs; pode ser **GitHub-hosted** ou **self-hosted**.
- Self-hosted se justifica por hardware/software específico, acesso à rede interna, controle, custo ou desempenho.
- Self-hosted transfere para você manutenção, segurança e custo da infraestrutura.
- Boas práticas: isolar produção, atualizar, restringir acesso, monitorar, planejar DR, rotacionar/efêmeros,
  gerenciar capacidade.
- Limites: 35 dias/workflow, 24 h na fila, 1.000 req/h à API, 256 jobs/matriz, 500 runs/10 s, 10.000 runners/grupo.
- (Complemento) Nunca use self-hosted runners em repositórios públicos.

---

## Aula 4 - Conceitos básicos de Docker

### O que vem por aí?

Nesta jornada pelo mundo dos containers, você vai descobrir como o Docker transformou o desenvolvimento de software:
uma nova era em que a criação, o teste e a implantação de aplicações são mais simples e eficientes, e em que a
escalabilidade encontra a praticidade.

### Hands On — instalando o Docker

Antes de começar, é vital ter o Docker instalado e funcionando.

#### Windows

- Acesse o **Docker Desktop for Windows**.
- Siga as instruções para baixar e instalar o Docker Desktop.
- Após a instalação, reinicie o computador se necessário.

#### Mac

- Acesse o **Docker Desktop for Mac**.
- Siga as instruções para baixar e instalar o Docker Desktop.

#### Linux (Ubuntu como exemplo)

Atualize a lista de pacotes:

```bash
sudo apt-get update
```

Instale os pacotes necessários:

```bash
sudo apt-get install apt-transport-https ca-certificates curl software-properties-common
```

Adicione a chave GPG oficial do Docker:

```bash
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
```

Adicione o repositório Docker:

```bash
sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
```

Atualize a lista de pacotes novamente e instale o Docker:

```bash
sudo apt-get update
sudo apt-get install docker-ce
```

> **💡 Complemento — atualização da instalação no Ubuntu:** o `apt-key` está **depreciado** no Ubuntu/Debian. O
> procedimento atual da documentação do Docker grava a chave em `/etc/apt/keyrings` e referencia-a com `signed-by`:
>
> ```bash
> sudo apt-get update
> sudo apt-get install ca-certificates curl
> sudo install -m 0755 -d /etc/apt/keyrings
> sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
> sudo chmod a+r /etc/apt/keyrings/docker.asc
> echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] \
>   https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
>   sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
> sudo apt-get update
> sudo apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
> sudo docker run hello-world   # teste
> ```
>
> Para usar `docker` sem `sudo`: `sudo usermod -aG docker $USER` (e abra nova sessão) — lembrando que o grupo
> `docker` equivale a acesso root. No Windows, o Docker Desktop usa o **WSL 2** como backend. Nos runners
> `ubuntu-latest` do GitHub Actions, Docker e Buildx já vêm instalados.

### Saiba mais

Atualmente, o desenvolvimento e a implantação de aplicativos se tornaram processos cada vez mais complexos.
Especialistas em desenvolvimento e administração de sistemas se deparam com desafios constantes, como
compatibilidade, gerenciamento de dependências e inconsistências entre ambientes de desenvolvimento e produção. É
aqui que o Docker entra em cena, oferecendo uma solução elegante e eficaz para esses problemas.

O **Docker** é uma plataforma aberta que permite criar, empacotar e executar aplicativos em contêineres. Um
**contêiner** é um pacote leve e independente que contém tudo que o aplicativo precisa para ser executado: código,
bibliotecas, variáveis de ambiente e assim por diante. Esses contêineres são isolados uns dos outros, garantindo que
funcionem da mesma forma, independentemente de onde sejam implantados.

A conteinerização transformou o modo como desenvolvemos e implantamos aplicativos. Ao encapsular um aplicativo e
suas dependências em um contêiner, podemos garantir que ele funcionará da mesma forma em qualquer ambiente. Isso
elimina o famoso problema **"funciona na minha máquina"**, em que diferenças entre ambientes de desenvolvimento,
teste e produção podem causar falhas inesperadas.

Além disso, os contêineres são incrivelmente eficientes em termos de recursos, visto que **compartilham o kernel do
sistema operacional**, mas mantêm processos e arquivos separados. Isso permite executar muitos contêineres em uma
única máquina, sem o *overhead* de uma máquina virtual completa.

O Docker não apenas simplificou o processo de desenvolvimento como também acelerou a entrega de aplicativos. Agora é
possível empacotar, distribuir e executar aplicativos de maneira rápida e confiável. A capacidade de replicar
ambientes de forma consistente torna a colaboração mais fácil, permitindo que as equipes se concentrem em criar
ótimos produtos em vez de resolver problemas de compatibilidade.

Em resumo, o Docker é uma tecnologia revolucionária que está moldando o futuro do desenvolvimento de software,
oferecendo uma abordagem flexível e eficiente para a criação e a implantação de aplicativos, com consistência entre
diferentes ambientes.

> **💡 Complemento — VM x contêiner:**
>
> | | Máquina virtual | Contêiner |
> |---|---|---|
> | Isolamento | Hypervisor; cada VM tem seu próprio SO/kernel | Processos isolados (namespaces/cgroups) sobre o kernel do host |
> | Tamanho | GBs | MBs a centenas de MBs |
> | Inicialização | Minutos | Segundos ou menos |
> | Densidade | Poucas por host | Muitas por host |
>
> Consequência prática: contêineres Linux precisam de kernel Linux (no Windows/Mac o Docker Desktop roda uma VM
> Linux leve por baixo).

#### Imagens e contêineres no Docker

Uma **imagem Docker** é um pacote leve, autônomo e executável, que inclui tudo que é necessário para executar um
software: código, bibliotecas, variáveis de ambiente e arquivos de configuração. As imagens são a base de um
contêiner Docker e servem como um **"modelo"** a partir do qual os contêineres são criados.

As imagens são compostas por várias **camadas** (*layers*), e cada uma delas representa uma instrução no
**Dockerfile** da imagem. As camadas são empilhadas e cada uma depende da anterior, criando uma estrutura coesa. Isso
permite reutilização eficiente, uma vez que camadas comuns podem ser compartilhadas entre várias imagens.

As imagens são geralmente armazenadas em repositórios, como o **Docker Hub**, um serviço de hospedagem para imagens
Docker. Especialistas em desenvolvimento podem baixar imagens públicas ou criar e armazenar suas próprias imagens
privadas.

Um **contêiner Docker** é uma **instância executável de uma imagem**. Enquanto uma imagem é um modelo estático, um
contêiner é a execução viva desse modelo — o contêiner é a imagem em tempo de execução. Você pode iniciar, parar,
mover ou excluir um contêiner usando a API ou a CLI do Docker.

Os contêineres isolam o software da máquina host e de outros contêineres; cada um interage diretamente com o kernel
do sistema operacional, mas está separado de outros processos e recursos do sistema. Essa separação oferece alto
grau de controle e eficiência, permitindo que várias instâncias sejam executadas simultaneamente sem interferência.

É fundamental entender que imagens e contêineres estão intrinsecamente ligados: a imagem funciona como modelo para a
criação de contêineres, e eles são as instâncias ativas desse modelo. Juntos, formam a essência do Docker,
permitindo o encapsulamento, a portabilidade e a escalabilidade que tornam a plataforma tão poderosa.

> **💡 Complemento — Dockerfile e comandos essenciais:** o PDF cita o Dockerfile e o Compose apenas nas
> palavras-chave. Um Dockerfile **multi-stage** típico para uma API ASP.NET Core:
>
> ```dockerfile
> # Etapa 1: build (imagem com SDK)
> FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build
> WORKDIR /src
> COPY ["src/UsersAPI/UsersAPI.csproj", "src/UsersAPI/"]
> # camada de restore fica em cache enquanto o .csproj não muda
> RUN dotnet restore "src/UsersAPI/UsersAPI.csproj"
> COPY . .
> RUN dotnet publish "src/UsersAPI/UsersAPI.csproj" -c Release -o /app/publish /p:UseAppHost=false
>
> # Etapa 2: runtime (imagem menor, sem SDK)
> FROM mcr.microsoft.com/dotnet/aspnet:8.0 AS final
> WORKDIR /app
> COPY --from=build /app/publish .
> # usuário não root já presente nas imagens .NET 8+
> USER $APP_UID
> # porta padrão do ASP.NET Core em contêiner a partir do .NET 8
> EXPOSE 8080
> ENTRYPOINT ["dotnet", "UsersAPI.dll"]
> ```
>
> Observação: no Dockerfile, `#` só inicia comentário no começo da linha — não use comentários ao final de uma
> instrução.
>
> (Use a tag da versão de .NET do seu projeto; o .NET 10 é a LTS mais recente e o suporte do .NET 8 vai até
> novembro de 2026.) Comandos do dia a dia:
>
> ```bash
> docker build -t users-api:1.0.0 .          # constrói a imagem a partir do Dockerfile
> docker images                              # lista imagens locais
> docker run -d -p 8080:8080 --name users users-api:1.0.0   # cria e inicia um contêiner
> docker ps                                  # contêineres em execução (-a inclui parados)
> docker logs -f users                       # acompanha logs
> docker exec -it users sh                   # abre shell dentro do contêiner
> docker stop users && docker rm users       # para e remove
> docker compose up -d                       # sobe vários serviços definidos em compose.yaml
> ```
>
> Inclua um `.dockerignore` (`bin/`, `obj/`, `.git/`) para builds menores e mais rápidos.

#### Estudos de casos

O Docker revolucionou a maneira como as empresas desenvolvem, implantam e operam suas aplicações. Seu sistema de
containers permitiu a padronização, facilitando a colaboração e aumentando a eficiência.

- **Desenvolvimento e teste:** empresas usam o Docker para criar ambientes consistentes de desenvolvimento e teste.
  Containers garantem que especialistas trabalhem em um ambiente idêntico ao de produção, minimizando problemas de
  "funciona na minha máquina".
- **Integração Contínua/Entrega Contínua (CI/CD):** o Docker é utilizado em pipelines de CI/CD para automatizar a
  compilação, o teste e a implantação de aplicações, agilizando a entrega e reduzindo o tempo de lançamento no
  mercado.
- **Microsserviços:** a containerização facilita o design de microsserviços, permitindo que as empresas desenvolvam
  e implantem serviços independentes que funcionem em conjunto, aumentando a escalabilidade e a resiliência do
  sistema.
- **Orquestração:** com ferramentas como **Kubernetes**, as empresas podem gerenciar e escalar containers de forma
  eficiente, respondendo dinamicamente às demandas de carga de trabalho.

#### Impacto na indústria de tecnologia

O Docker não apenas mudou a maneira como as aplicações são construídas e implantadas, mas também transformou a
indústria de tecnologia:

- **Padronização:** a containerização proporcionou padronização sem precedentes em ambientes de desenvolvimento,
  teste e produção, reduzindo a complexidade e os custos de manutenção.
- **Agilidade e eficiência:** empresas que adotaram o Docker experimentaram agilidade significativa em
  desenvolvimento e implantação, reduzindo o tempo de comercialização e aumentando a competitividade.
- **Inovação em infraestrutura:** o Docker promoveu inovação em orquestração, monitoramento e segurança de
  containers, levando ao surgimento de uma nova geração de ferramentas e práticas.
- **Ecossistema próspero:** o Docker catalisou um ecossistema vibrante, com ampla variedade de produtos, serviços e
  comunidades que continuam a enriquecer a tecnologia de containerização.
- **Sustentabilidade e economia de recursos:** ao otimizar o uso dos recursos de hardware, o Docker contribuiu para a
  eficiência energética, aspecto crítico na sustentabilidade das operações de TI.

Em resumo, o Docker tornou-se uma ferramenta indispensável para muitas empresas modernas, oferecendo flexibilidade,
eficiência e inovação. Sua influência afeta não apenas como o software é criado, mas também como é entregue e
operado, redefinindo padrões e práticas em toda a cadeia de valor de TI.

O Docker introduziu uma camada de abstração que permite empacotar aplicações em containers portáteis, eficientes e
padronizados, permitindo maior colaboração e agilidade em todo o ciclo de vida do desenvolvimento. Neste material
foram explorados os fundamentos do Docker — conceitos básicos, imagens e containers, repositórios de imagens,
considerações de segurança e casos de uso —, além do impacto do Docker na indústria, com ênfase em padronização,
inovação e sustentabilidade.

> **💡 Complemento — Docker no GitHub Actions:** o encontro dos dois temas acontece em três pontos: (1) **construir
> imagens no pipeline** (`docker/setup-buildx-action` + `docker/build-push-action`, atualmente na v6, com cache via
> `cache-from/cache-to: type=gha`); (2) **service containers** (`services:` no job) para subir, por exemplo, um
> PostgreSQL durante testes de integração; (3) **Docker container actions** (actions empacotadas como imagem).

#### Recursos para continuar aprendendo

- **Documentação oficial do Docker:** a fonte mais confiável para informações técnicas detalhadas e guias práticos.
- **Docker Hub:** repositório central para encontrar e compartilhar containers de software; excelente para explorar
  imagens oficiais e comunitárias.
- **Comunidade Docker:** fóruns, grupos de usuários e conferências oferecem suporte, insights e oportunidades de
  colaboração.
- **Livros e blogs:** abordam desde o uso básico até tópicos avançados, como orquestração e segurança.

### O que você viu nesta aula?

Uma introdução ao Docker, uma poderosa plataforma de virtualização de contêineres. Através de exemplos práticos, você
pôde compreender como o Docker transformou o desenvolvimento de software, simplificando o processo de
empacotamento, distribuição e implantação de aplicativos, tornando-o mais eficiente e confiável.

**Palavras-chave:** Docker, Containers, Docker Hub, Imagens Docker, Workflow, Branch, Compose, Imagem, Dockerfile.

### Referências da aula

- AWS. *O que é o Docker?* — <https://aws.amazon.com/pt/docker/>
- Docker. *Develop faster. Run anywhere.* — <https://www.docker.com>
- Microsoft. *O que é o Docker?* — <https://learn.microsoft.com/pt-br/dotnet/architecture/microservices/container-docker-introduction/docker-defined>
- Red Hat. *Docker: desenvolvimento de aplicações em containers* — <https://www.redhat.com/pt-br/topics/containers/what-is-docker>

### Pontos-chave

- Docker cria, empacota e executa aplicações em **contêineres** com tudo o que elas precisam.
- Contêineres eliminam o "funciona na minha máquina" e compartilham o kernel do host (mais leves que VMs).
- **Imagem** = modelo estático em camadas (uma por instrução do Dockerfile); **contêiner** = instância em execução.
- Camadas comuns são reaproveitadas entre imagens (cache de build e de armazenamento).
- Imagens são distribuídas por repositórios/registries, como o Docker Hub.
- Usos: dev/teste consistentes, CI/CD, microsserviços e orquestração (Kubernetes).
- (Complemento) No Ubuntu, `apt-key` está depreciado; use keyrings com `signed-by`.

---

## Aula 5 - Repositório de imagens

### O que vem por aí?

Nesta jornada, você compreenderá a "magia" por trás dos repositórios de imagens e o poder que eles têm de transformar
ideias em realidade em questão de minutos. Todos os dias, milhares de especialistas em desenvolvimento de todo o
mundo contribuem com imagens novas e otimizadas, garantindo acesso à tecnologia mais recente sem o esforço de
construir tudo do zero. Cada imagem no repositório é como um livro em uma biblioteca colossal.

Mais do que códigos e ferramentas, estamos falando de uma **comunidade** que acredita no compartilhamento, na
construção conjunta e no avanço contínuo. Cada especialista, iniciante ou experiente, pode se beneficiar desse acervo
enquanto também contribui para o crescimento coletivo.

### Hands On — Docker Hub

#### O que é o Docker Hub?

O **Docker Hub** é um serviço de nuvem que permite que você compartilhe e acesse imagens de container com a
comunidade Docker e sua equipe. Pense nele como um **"GitHub para imagens Docker"**.

#### Criação de uma conta no Docker Hub

- Acesse o Docker Hub.
- Clique em **"Register"**.
- Preencha os detalhes necessários e siga as instruções.

*Figura 1 — Página inicial do Docker Hub (print da tela inicial, com acesso ao cadastro/login).*

#### Procurando imagens no Docker Hub

- Acesse o Docker Hub.
- No campo de busca, insira o nome da imagem que procura, como "nginx" ou "node".
- Explore os resultados, prestando atenção nas descrições e na quantidade de downloads (isso pode indicar
  popularidade e confiabilidade).

*Figura 2 — Página de busca de imagens no Docker Hub (print dos resultados de uma busca).*

#### Baixando uma imagem do Docker Hub

- No terminal, digite `docker pull nome_da_imagem:tag` (se você não especificar uma tag, a versão **`latest`** será
  baixada por padrão).

```bash
docker pull nginx:latest
```

> **💡 Complemento:** prefira imagens com selo **Docker Official Image** ou **Verified Publisher** em vez de se guiar
> apenas pelo número de downloads. Em produção, **evite `latest`**: é uma tag móvel, que não diz qual versão está
> rodando e quebra a rastreabilidade. Use tags explícitas (`nginx:1.27`) ou até o *digest* imutável
> (`nginx@sha256:...`). O Docker Hub também aplica **limites de pull** para usuários anônimos e contas gratuitas —
> em CI, autentique-se (`docker/login-action`) para não esbarrar neles.

#### Enviando sua própria imagem para o Docker Hub

Antes de enviar sua imagem, você precisa criar um repositório no Docker Hub:

1. Faça login no Docker Hub.
2. Clique em **"Create Repository"** (Figura 3).
3. Nomeie seu repositório e defina a visibilidade (**público** ou **privado**) (Figura 4).

*Figura 3 — Página para criação de repositório (print com o botão "Create Repository").*

*Figura 4 — Formulário de criação de repositório (print com os campos de nome, descrição e visibilidade).*

Agora, envie sua imagem:

1. No seu terminal, identifique sua imagem com `docker images`.
2. Renomeie sua imagem para corresponder ao formato do Docker Hub: `docker tag minha_imagem meu_usuario/nome_do_repositório:tag`.
3. Faça login no Docker Hub via terminal: `docker login`.
4. Envie sua imagem: `docker push meu_usuario/nome_do_repositório:tag`.

```bash
docker images
docker tag minha_imagem meu_usuario/nome_do_repositorio:tag
docker login
docker push meu_usuario/nome_do_repositorio:tag
```

> **💡 Complemento:** no `docker login` interativo, use um **Personal Access Token** do Docker Hub (Account settings →
> Personal access tokens) no lugar da senha. No GitHub Actions, guarde usuário e token em secrets e use
> `docker/login-action@v3` com `username: ${{ secrets.DOCKERHUB_USERNAME }}` e
> `password: ${{ secrets.DOCKERHUB_TOKEN }}`.

#### Gerenciando suas imagens no Docker Hub

- Editar as descrições das suas imagens.
- Configurar **webhooks** para automatizar fluxos de trabalho.
- Excluir ou atualizar imagens conforme necessário.

O Docker Hub é uma ferramenta poderosa para gerenciar e compartilhar imagens Docker. Ao se familiarizar com essa
plataforma, você potencializa seu fluxo de trabalho em Docker e colabora com a ampla comunidade de especialistas em
desenvolvimento. Continue experimentando, explorando novas imagens e, se tiver criado algo legal, compartilhe com a
comunidade!

### Saiba mais

#### O que é um repositório de imagens?

Um **repositório de imagens Docker** é um local de armazenamento centralizado em que imagens Docker podem ser
armazenadas, recuperadas, compartilhadas e gerenciadas. É uma parte essencial da infraestrutura Docker, atuando como
ponto de intersecção entre especialistas em desenvolvimento e administração e outros *stakeholders* no processo de
desenvolvimento e implantação.

Assim como uma biblioteca contém uma vasta coleção de livros e publicações, um repositório de imagens é uma coleção de
imagens prontas para uso. Essas imagens podem ser oficiais, provenientes de fornecedores de software conhecidos, ou
criadas e compartilhadas por membros da comunidade.

> **💡 Complemento — registry x repositório x tag:** tecnicamente, **registry** é o serviço (Docker Hub, ECR, ACR...);
> **repositório** é a coleção de versões de *uma* imagem dentro dele; **tag** identifica uma versão. Em
> `123456789012.dkr.ecr.us-east-1.amazonaws.com/users-api:1.4.2`, o registry é
> `123456789012.dkr.ecr.us-east-1.amazonaws.com`, o repositório é `users-api` e a tag é `1.4.2`. Sem host no nome,
> o Docker assume o Docker Hub (`docker.io`).

#### Funções e utilidades

- **Armazenamento:** os repositórios agem como um armazém, mantendo as imagens seguras e acessíveis.
- **Recuperação:** especialistas em desenvolvimento e operação podem baixar imagens necessárias com facilidade e
  eficiência.
- **Compartilhamento:** permite que indivíduos compartilhem suas criações com colegas ou com a comunidade global.
- **Gerenciamento:** facilita o gerenciamento de versões, atualizações e manutenção de imagens.

Os repositórios de imagens facilitam a colaboração e aceleram o processo de desenvolvimento ao fornecer uma fonte
confiável e centralizada de componentes de software pré-configurados. Isso reduz a necessidade de recriar soluções
comuns, permitindo que as equipes se concentrem em tarefas mais complexas e específicas.

#### Tipos de repositórios

- **Públicos:** acessíveis por qualquer pessoa, oferecem uma variedade de imagens gratuitas e de código aberto.
- **Privados:** controlados e acessíveis apenas por indivíduos ou equipes autorizadas, oferecendo maior segurança e
  personalização.

#### Serviços de repositórios de imagens

No mundo ágil e colaborativo do desenvolvimento de software, as imagens Docker desempenham papel crucial, atuando como
*snapshots* de um ambiente de software completo, prontos para serem executados em qualquer lugar. Contudo, armazenar,
organizar, compartilhar e manter essas imagens requer uma solução eficaz de gerenciamento.

As plataformas de gerenciamento de imagens Docker fornecem um local centralizado para hospedar e gerenciar imagens de
contêiner. Elas não apenas armazenam imagens, como também facilitam o fluxo de trabalho de desenvolvimento ao
oferecer busca rápida, controle de versão, segurança e integração com outras ferramentas de DevOps.

Seja uma grande corporação buscando soluções robustas e seguras ou uma pessoa desenvolvedora procurando facilidade de
uso e acesso a uma comunidade global, existe uma plataforma adequada para cada necessidade. As plataformas variam em
recursos, escalabilidade, compatibilidade e modelo de preços, e a escolha certa pode acelerar o ciclo de
desenvolvimento e promover uma colaboração mais eficaz.

| Plataforma | Descrição | Recursos |
|---|---|---|
| **Docker Hub** | Repositório padrão do Docker; escolha popular para repositórios públicos e privados. | Busca, armazenamento, compartilhamento e gerenciamento de imagens; varredura de segurança e integração com CI/CD. |
| **Google Container Registry (GCR)** | Serviço de gerenciamento de contêineres do Google Cloud, otimizado para desempenho e segurança. | Integração nativa com outros serviços do Google Cloud, controle de acesso IAM e repositórios privados. |
| **Amazon Elastic Container Registry (ECR)** | Serviço gerenciado da AWS para armazenar, gerenciar e implantar imagens Docker. | Integração com Amazon ECS e Kubernetes, políticas de segurança flexíveis e replicação entre regiões. |
| **Azure Container Registry (ACR)** | Serviço da Microsoft Azure para armazenar e gerenciar imagens de contêiner para todos os tipos de implantação. | Suporte a Docker CLI e API, integração com Azure DevOps e recursos avançados de autenticação. |
| **GitLab Container Registry** | Integrado ao GitLab; permite criar, publicar e compartilhar imagens no mesmo fluxo de desenvolvimento. | Facilidade de uso com o CI/CD do GitLab, repositórios privados e recursos de automação. |
| **Quay by Red Hat** | Solução empresarial com segurança robusta e recursos de automação. | Varredura de segurança automatizada, controle de acesso granular e suporte a vários protocolos de registro. |
| **JFrog Artifactory** | Repositório universal que suporta todos os principais tipos de pacote, incluindo Docker. | Múltiplos repositórios, controle de acesso, integração com ferramentas populares de CI/CD e recursos de análise. |

*Figura 5 — Repositório de imagens no Docker Hub (print da página de um repositório).*

*Figura 6 — Dashboard do registry de contêineres da AWS (no PDF a legenda diz "ACR da AWS"; o serviço da AWS é o
ECR — print do console).*

*Figura 7 — Azure Container Registry (print do serviço no portal Azure).*

*Figura 8 — Documentação do GitLab Container Registry (print da página de documentação).*

> **💡 Complemento — atualizações:**
> - **GCR foi descontinuado:** o Google Container Registry foi substituído pelo **Artifact Registry** (a própria
>   referência da aula já aponta para ele) e foi desativado em 2025. Em projetos novos no Google Cloud, use o
>   Artifact Registry (`REGIAO-docker.pkg.dev/...`).
> - **GitHub Container Registry (GHCR — `ghcr.io`)**, parte do GitHub Packages, não aparece na lista, mas é a opção
>   mais integrada ao GitHub Actions: autentica com o próprio `GITHUB_TOKEN` (`permissions: packages: write`).
> - **ECR — recursos relevantes:** *scan on push* (básico ou avançado via Amazon Inspector), **tag immutability**
>   (impede sobrescrever uma tag já publicada), **lifecycle policies** (ex.: manter só as últimas N imagens),
>   replicação entre regiões/contas e criptografia com KMS. A autenticação usa IAM: `aws ecr get-login-password |
>   docker login --username AWS --password-stdin <registry>` ou, no GitHub Actions, `aws-actions/amazon-ecr-login`.

#### Considerações de segurança

A segurança é uma preocupação primordial quando se trata de gerenciar e utilizar repositórios de imagens Docker.
Aspectos-chave:

- **Varredura de vulnerabilidades:** imagens armazenadas nos repositórios devem ser regularmente escaneadas em busca
  de vulnerabilidades conhecidas. Com ferramentas automatizadas, é possível identificar e corrigir falhas antes que
  sejam exploradas.
- **Assinatura e verificação de imagens:** as imagens podem ser assinadas digitalmente para garantir sua integridade e
  autenticidade. A assinatura permite verificar se uma imagem foi alterada desde que foi criada pelo autor original.
- **Controle de acesso:** políticas rigorosas de controle de acesso garantem que apenas usuários autorizados possam
  baixar, carregar ou modificar imagens em repositórios privados, minimizando o risco de acesso não autorizado ou
  uso malicioso.
- **Políticas de segurança personalizadas:** conforme as necessidades e regulamentações da organização, podem incluir
  padrões de conformidade específicos, restrições de rede ou requisitos de autenticação de dois fatores.
- **Registros e monitoramento:** manter registros detalhados de todas as atividades no repositório e monitoramento em
  tempo real ajuda na detecção precoce de atividades suspeitas e na resposta rápida a incidentes.
- **Atualizações e patches:** é essencial manter todas as imagens atualizadas com as últimas correções de segurança,
  acompanhando e aplicando patches e atualizações de fornecedores confiáveis.
- **Compliance e auditorias:** cumprir regulamentações e padrões do setor, como **GDPR, HIPAA ou PCI-DSS**, é crucial
  para repositórios que armazenam dados sensíveis ou críticos. Auditorias internas e externas regulares garantem que
  políticas e procedimentos estejam alinhados com esses padrões.
- **Educação e conscientização:** treinar os membros da equipe sobre melhores práticas de segurança e manter
  conscientização constante sobre ameaças emergentes e métodos de defesa é fundamental para uma abordagem proativa.

As considerações de segurança vão muito além de simples medidas técnicas: abrangem uma combinação de **tecnologia,
processos e cultura organizacional**. Uma abordagem robusta não só protege ativos e dados, mas também fortalece a
confiança e a colaboração dentro da comunidade de desenvolvimento.

> **💡 Complemento — scan de imagem com Trivy no pipeline:** o **Trivy** (Aqua Security, open source) varre imagens
> em busca de CVEs em pacotes do SO e de dependências da aplicação (inclusive NuGet). Uso típico no GitHub Actions,
> **antes do push** para o registry:
>
> ```yaml
> - name: Scan da imagem com Trivy
>   uses: aquasecurity/trivy-action@<sha-fixado>   # fixe por SHA; consulte a release atual
>   with:
>     image-ref: users-api:${{ github.sha }}
>     format: table
>     exit-code: '1'                 # falha o job se encontrar...
>     severity: CRITICAL,HIGH        # ...vulnerabilidades críticas ou altas
>     ignore-unfixed: true           # ignora CVEs ainda sem correção disponível
> ```
>
> Com `format: sarif` e `github/codeql-action/upload-sarif`, os achados aparecem na aba **Security** do repositório.
> Para **assinatura**, o padrão atual é o **Sigstore Cosign** (com assinatura *keyless* via OIDC do GitHub); o Docker
> Content Trust (Notary v1) é o mecanismo legado do Docker Hub. Também vale gerar **SBOM** e **attestations de
> proveniência** (`docker/build-push-action` com `provenance`/`sbom`, ou `actions/attest-build-provenance`).

### O que você viu nesta aula?

- Um repositório de imagens Docker é um espaço de armazenamento centralizado para guardar, acessar, compartilhar e
  gerenciar imagens Docker — comparável a uma biblioteca. Contém imagens oficiais e compartilhadas pela comunidade.
- Funções: armazenamento seguro e acessível, recuperação fácil, compartilhamento com colegas ou globalmente e
  gerenciamento eficaz, incluindo controle de versões e atualizações.
- Podem ser **públicos** (acessíveis a todos, imagens gratuitas e de código aberto) ou **privados** (acesso restrito,
  mais segurança e personalização).
- Plataformas: Docker Hub (padrão, público e privado); GCR (desempenho e segurança, integrado ao Google Cloud); ECR
  (integração com ECS, Kubernetes e replicação entre regiões); ACR (Microsoft Azure, recursos avançados); GitLab
  Container Registry (integrado ao fluxo do GitLab); Quay by Red Hat (segurança e automação); JFrog Artifactory
  (suporte universal e integração com várias ferramentas de CI/CD).
- Considerações de segurança: varredura de vulnerabilidades; assinatura de imagens; controle de acesso; políticas
  personalizadas; registros e monitoramento; atualizações e patches; compliance e auditorias; educação e
  conscientização.

Em resumo, os repositórios de imagens Docker são ferramentas cruciais na infraestrutura de desenvolvimento moderno,
facilitando a colaboração e acelerando os processos. No entanto, a segurança deve ser prioridade, combinando medidas
técnicas, processuais e culturais.

**Palavras-chave:** Docker Hub, Azure Container Registry, GitLab, ECR, AWS, Amazon Web Services.

### Referências da aula

- AWS. *Amazon Elastic Container Registry* — <https://aws.amazon.com/pt/ecr/>
- Azure. *Azure Container Registry* — <https://azure.microsoft.com/en-us/products/container-registry>
- Docker Hub. *Build and Ship any Application Anywhere* — <https://hub.docker.com>
- GitLab. *GitLab Container Registry* — <https://docs.gitlab.com/ee/user/packages/container_registry/>
- Google Cloud. *Artifact Registry* — <https://cloud.google.com/artifact-registry?hl=pt-br>
- Red Hat. *Red Hat Quay* — <https://www.redhat.com/en/technologies/cloud-computing/quay>

### Pontos-chave

- Docker Hub é o registry padrão — o "GitHub das imagens Docker".
- Fluxo de publicação: `docker images` → `docker tag` → `docker login` → `docker push`; download com `docker pull`.
- Sem tag explícita, vale `latest` — conveniente, mas inadequado para produção (complemento).
- Funções de um repositório: armazenar, recuperar, compartilhar e gerenciar versões.
- Repositórios podem ser públicos ou privados.
- Principais plataformas: Docker Hub, GCR (hoje Artifact Registry), ECR, ACR, GitLab, Quay, JFrog Artifactory.
- Segurança: scan de vulnerabilidades, assinatura, controle de acesso, monitoramento, patches, compliance e cultura.

---

## Aplicação no Tech Challenge da Fase 4

> **💡 Complemento:** esta seção inteira é um complemento, relacionando o conteúdo das aulas com o projeto
> **FIAP Cloud Games (FCG)**. Confira sempre os requisitos exatos no enunciado oficial do Tech Challenge.

### Requisitos de CI/CD e como as aulas se encaixam

| Requisito do Tech Challenge | Onde aparece nas aulas | Como implementar |
|---|---|---|
| Pipeline obrigatória para, no mínimo, **UsersAPI** e **CatalogAPI** (.NET) | Aula 2 (workflows, jobs, matrix) | Um workflow com `matrix` por serviço, ou um *reusable workflow* chamado por um workflow de cada API (com filtros `paths`). |
| **Build & Test** com testes unitários | Aulas 1 e 2 (CI) | `actions/setup-dotnet` + `dotnet restore/build/test`, com cache de NuGet; o pipeline falha se um teste falhar. |
| **Containerização com tag versionada** | Aulas 4 e 5 (imagem, tag) | Dockerfile multi-stage; tag com SHA do commit (imutável e rastreável) e, opcionalmente, versão semântica. Nada de depender de `latest`. |
| **Security scan** (desejável) | Aula 5 (varredura de vulnerabilidades) | Trivy na imagem antes do push; opcionalmente *scan on push* do ECR. |
| **Push no registry da cloud (ECR)** | Aula 5 (ECR) | `aws-actions/configure-aws-credentials` (OIDC) + `aws-actions/amazon-ecr-login` + `docker/build-push-action`. |
| **Deploy no EKS sem downtime** (rolling update) | Aula 4 (orquestração/Kubernetes) | `kubectl set image` + `kubectl rollout status`; Deployment com `RollingUpdate`, `maxUnavailable: 0` e `readinessProbe`. |
| **Zero credenciais hardcoded** | Aula 2 (segurança), Aula 3 (não guardar segredos no runner) | **OIDC** com IAM Role (sem access keys), GitHub secrets/variables, Kubernetes Secrets/AWS Secrets Manager para a aplicação. |
| **"Live deploy" no vídeo** | Aulas 1 e 2 (push → pipeline) | Alterar código → `git push` na `main` → pipeline executa → nova versão no ar sem queda. |

### Pré-requisitos na AWS (uma vez)

1. **Provedor OIDC do GitHub no IAM:** URL `https://token.actions.githubusercontent.com`, audiência
   `sts.amazonaws.com`.
2. **IAM Role para o pipeline** (ex.: `fcg-github-deploy`) com *trust policy* restrita ao seu repositório e branch/
   environment:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": { "Federated": "arn:aws:iam::<ACCOUNT_ID>:oidc-provider/token.actions.githubusercontent.com" },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringEquals": {
          "token.actions.githubusercontent.com:aud": "sts.amazonaws.com",
          "token.actions.githubusercontent.com:sub": "repo:<owner>/<repo>:environment:production"
        }
      }
    }
  ]
}
```

   Permissões da role: push no ECR **apenas** nos repositórios `users-api` e `catalog-api` e `eks:DescribeCluster`
   no cluster.
3. **Repositórios ECR** `users-api` e `catalog-api`, de preferência com *tag immutability* e *scan on push*
   habilitados, e uma *lifecycle policy* para limpar imagens antigas.
4. **Acesso da role ao cluster EKS:** crie uma *access entry* do EKS para a role (ou mapeie-a no `aws-auth`
   ConfigMap, em clusters antigos), com permissão limitada ao namespace da aplicação.
5. **No GitHub:** crie o environment `production` (opcionalmente com *required reviewers*) e as **variables**
   `AWS_ROLE_ARN`, `AWS_REGION` e `EKS_CLUSTER_NAME`. O ARN da role não é segredo, mas manter tudo em variables
   evita valores fixos no YAML.

### Deployment Kubernetes preparado para rolling update sem downtime

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: users-api
  namespace: fcg
spec:
  replicas: 2                       # pelo menos 2 réplicas para não haver queda durante a troca
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxUnavailable: 0             # nunca derruba um pod antes de o novo estar pronto
      maxSurge: 1                   # sobe 1 pod extra por vez
  selector:
    matchLabels:
      app: users-api
  template:
    metadata:
      labels:
        app: users-api
    spec:
      containers:
        - name: users-api           # este nome é usado no "kubectl set image"
          image: <ACCOUNT_ID>.dkr.ecr.us-east-1.amazonaws.com/users-api:inicial
          ports:
            - containerPort: 8080
          readinessProbe:           # só recebe tráfego quando responder OK
            httpGet:
              path: /health
              port: 8080
            initialDelaySeconds: 5
            periodSeconds: 5
          livenessProbe:
            httpGet:
              path: /health
              port: 8080
            initialDelaySeconds: 15
            periodSeconds: 10
          envFrom:
            - secretRef:
                name: users-api-secrets   # connection strings etc. — fora do código e da imagem
```

Na API .NET, exponha o endpoint de saúde com `builder.Services.AddHealthChecks();` e `app.MapHealthChecks("/health");`.

### Exemplo de workflow completo comentado

> **💡 Complemento:** exemplo de referência para o cenário do FCG. As versões de actions estão em tags de *major*
> para legibilidade — **em produção, fixe cada `uses:` pelo SHA completo do commit** (com a versão em comentário) e
> deixe o Dependabot atualizá-los. Ajuste caminhos de projetos/testes à estrutura do seu repositório.

```yaml
# .github/workflows/fcg-ci-cd.yml
name: FCG CI/CD

on:
  push:
    branches: [ main ]
    paths:
      - 'src/UsersAPI/**'
      - 'src/CatalogAPI/**'
      - 'tests/**'
      - '.github/workflows/fcg-ci-cd.yml'
  pull_request:
    branches: [ main ]
  workflow_dispatch: {}                 # permite disparo manual (útil na gravação do vídeo)

# Permissões mínimas por padrão; cada job pede só o que precisa.
permissions:
  contents: read

# Evita dois deploys simultâneos da mesma branch; não cancela um deploy em andamento.
concurrency:
  group: fcg-${{ github.ref }}
  cancel-in-progress: false

env:
  DOTNET_VERSION: '8.0.x'
  DOTNET_NOLOGO: true
  DOTNET_CLI_TELEMETRY_OPTOUT: true

jobs:
  # ---------------------------------------------------------------
  # 1) Build & Test — roda em PRs e em push na main
  # ---------------------------------------------------------------
  build-test:
    name: Build & Test (${{ matrix.service.name }})
    runs-on: ubuntu-latest
    timeout-minutes: 20
    strategy:
      fail-fast: false
      matrix:
        service:
          - { name: users-api,   project: src/UsersAPI/UsersAPI.csproj,     tests: tests/UsersAPI.UnitTests }
          - { name: catalog-api, project: src/CatalogAPI/CatalogAPI.csproj, tests: tests/CatalogAPI.UnitTests }
    steps:
      - uses: actions/checkout@v4

      - uses: actions/setup-dotnet@v4
        with:
          dotnet-version: ${{ env.DOTNET_VERSION }}
          cache: true                                   # cache de NuGet baseado em packages.lock.json
          cache-dependency-path: '**/packages.lock.json'

      - name: Restore
        run: dotnet restore ${{ matrix.service.tests }} --locked-mode

      - name: Build
        run: dotnet build ${{ matrix.service.tests }} --no-restore -c Release

      - name: Testes unitários
        run: >
          dotnet test ${{ matrix.service.tests }} --no-build -c Release
          --logger "trx;LogFileName=results.trx"
          --results-directory ./TestResults

      - name: Publica resultados dos testes
        if: always()                                    # sobe o relatório mesmo se os testes falharem
        uses: actions/upload-artifact@v4
        with:
          name: test-results-${{ matrix.service.name }}
          path: ./TestResults

  # ---------------------------------------------------------------
  # 2) Build da imagem, scan de segurança e push no ECR — só na main
  # ---------------------------------------------------------------
  image:
    name: Imagem (${{ matrix.service.name }})
    needs: build-test
    if: github.event_name != 'pull_request' && github.ref == 'refs/heads/main'
    runs-on: ubuntu-latest
    timeout-minutes: 30
    environment: production             # a trust policy do IAM confia neste environment
    permissions:
      contents: read
      id-token: write                   # necessário para o OIDC com a AWS
      security-events: write            # para enviar o SARIF do Trivy à aba Security
    strategy:
      fail-fast: false
      matrix:
        service:
          - { name: users-api,   dockerfile: src/UsersAPI/Dockerfile }
          - { name: catalog-api, dockerfile: src/CatalogAPI/Dockerfile }
    outputs:
      tag: ${{ steps.meta.outputs.tag }}
    steps:
      - uses: actions/checkout@v4

      - name: Define tag versionada
        id: meta
        # Tag imutável e rastreável: versão + número da execução + SHA curto do commit
        run: echo "tag=1.0.${{ github.run_number }}-${GITHUB_SHA::7}" >> "$GITHUB_OUTPUT"

      - name: Credenciais AWS via OIDC (sem access keys)
        uses: aws-actions/configure-aws-credentials@v4
        with:
          role-to-assume: ${{ vars.AWS_ROLE_ARN }}
          aws-region: ${{ vars.AWS_REGION }}

      - name: Login no Amazon ECR
        id: ecr
        uses: aws-actions/amazon-ecr-login@v2

      - uses: docker/setup-buildx-action@v3

      - name: Build da imagem (carregada localmente para o scan)
        uses: docker/build-push-action@v6
        with:
          context: .
          file: ${{ matrix.service.dockerfile }}
          load: true
          push: false
          tags: ${{ steps.ecr.outputs.registry }}/${{ matrix.service.name }}:${{ steps.meta.outputs.tag }}
          cache-from: type=gha,scope=${{ matrix.service.name }}
          cache-to: type=gha,mode=max,scope=${{ matrix.service.name }}

      - name: Security scan (Trivy) — bloqueia CRITICAL/HIGH
        uses: aquasecurity/trivy-action@<SHA-de-uma-release>   # fixe por SHA (veja as releases da action)
        with:
          image-ref: ${{ steps.ecr.outputs.registry }}/${{ matrix.service.name }}:${{ steps.meta.outputs.tag }}
          format: sarif
          output: trivy-${{ matrix.service.name }}.sarif
          severity: CRITICAL,HIGH
          ignore-unfixed: true
          exit-code: '1'

      - name: Envia resultado do scan para a aba Security
        if: always()
        uses: github/codeql-action/upload-sarif@v3
        with:
          sarif_file: trivy-${{ matrix.service.name }}.sarif
          category: trivy-${{ matrix.service.name }}

      - name: Push da imagem no ECR
        run: docker push ${{ steps.ecr.outputs.registry }}/${{ matrix.service.name }}:${{ steps.meta.outputs.tag }}

  # ---------------------------------------------------------------
  # 3) Deploy no EKS com rolling update (sem downtime)
  # ---------------------------------------------------------------
  deploy:
    name: Deploy EKS (${{ matrix.service }})
    needs: image
    runs-on: ubuntu-latest
    timeout-minutes: 15
    environment: production             # pode exigir aprovação manual (required reviewers)
    permissions:
      contents: read
      id-token: write
    strategy:
      max-parallel: 1                   # um serviço por vez
      matrix:
        service: [ users-api, catalog-api ]
    steps:
      - name: Credenciais AWS via OIDC
        uses: aws-actions/configure-aws-credentials@v4
        with:
          role-to-assume: ${{ vars.AWS_ROLE_ARN }}
          aws-region: ${{ vars.AWS_REGION }}

      - name: Login no Amazon ECR (para obter o endereço do registry)
        id: ecr
        uses: aws-actions/amazon-ecr-login@v2

      - name: Configura kubeconfig do EKS
        run: aws eks update-kubeconfig --name "${{ vars.EKS_CLUSTER_NAME }}" --region "${{ vars.AWS_REGION }}"

      - name: Atualiza a imagem do Deployment (rolling update)
        env:
          IMAGE: ${{ steps.ecr.outputs.registry }}/${{ matrix.service }}:${{ needs.image.outputs.tag }}
        run: |
          kubectl -n fcg set image deployment/${{ matrix.service }} ${{ matrix.service }}="$IMAGE"
          kubectl -n fcg annotate deployment/${{ matrix.service }} \
            kubernetes.io/change-cause="deploy ${{ github.sha }} (run ${{ github.run_number }})" --overwrite

      - name: Aguarda o rollout terminar
        run: kubectl -n fcg rollout status deployment/${{ matrix.service }} --timeout=300s

      - name: Rollback automático se o rollout falhar
        if: failure()
        run: kubectl -n fcg rollout undo deployment/${{ matrix.service }}
```

**Observações sobre o exemplo:**

- O job `image` usa `matrix`, e o `outputs.tag` de um job com matrix guarda o valor da última combinação executada.
  Como a tag é idêntica para os dois serviços (mesmo `run_number` e SHA), isso funciona aqui; se as tags variarem
  por serviço, calcule a tag em um job próprio anterior ou use um *reusable workflow* por serviço.
- `kubectl set image` + `rollout status` é a abordagem mais simples. Alternativas: manter os manifestos no
  repositório e aplicar com `kubectl apply`/Kustomize (substituindo a tag), usar Helm (`helm upgrade --install
  --atomic`) ou GitOps com Argo CD/Flux.
- Para que o pipeline deploye **só o serviço que mudou**, separe em um workflow por API (com `paths`) que chame um
  *reusable workflow* comum.
- Proteja a branch `main` (*branch protection* / *rulesets*) exigindo que o job `build-test` passe nos PRs.

### Roteiro do "live deploy" para o vídeo

1. Mostrar a aplicação em produção respondendo (ex.: `GET /health` ou um endpoint da CatalogAPI via Load Balancer/
   Ingress) e a versão atual: `kubectl -n fcg get deploy catalog-api -o jsonpath='{.spec.template.spec.containers[0].image}'`.
2. Fazer uma alteração visível no código (ex.: um campo novo na resposta ou um texto de versão).
3. `git commit` e `git push` na `main` (ou merge de um PR).
4. Mostrar a aba **Actions**: Build & Test → Imagem (scan Trivy + push no ECR com a nova tag) → Deploy.
5. Durante o rollout, demonstrar que não há queda: um loop de requisições em outro terminal
   (`while true; do curl -s -o /dev/null -w "%{http_code}\n" https://<endpoint>/health; sleep 0.5; done`) só
   deve retornar `200`, e `kubectl -n fcg get pods -w` mostra os pods novos subindo antes de os antigos saírem.
6. Mostrar a nova tag no ECR e a resposta alterada em produção.
7. Mostrar que não há credenciais no repositório: o workflow usa `role-to-assume` via OIDC e `vars`/`secrets`.

### Checklist de segurança do pipeline

- [ ] `permissions` mínimas no topo; `id-token: write` só nos jobs que falam com a AWS.
- [ ] Nenhuma access key da AWS em secrets — apenas OIDC com role de escopo mínimo.
- [ ] Trust policy da role restrita ao repositório e ao environment/branch.
- [ ] Actions de terceiros fixadas por SHA e atualizadas pelo Dependabot.
- [ ] Imagem com usuário não root, base oficial e scan de vulnerabilidades no pipeline.
- [ ] Tags imutáveis no ECR; nada de `latest` em produção.
- [ ] Segredos da aplicação em Kubernetes Secrets/AWS Secrets Manager, nunca no código ou na imagem.
- [ ] Environment `production` com regras de proteção; branch `main` protegida.

### Glossário

| Termo | Significado |
|---|---|
| **CI (Continuous Integration)** | Integração frequente do código em um repositório central, com build e testes automáticos. |
| **CD (Continuous Delivery/Deployment)** | Artefato sempre pronto para produção (delivery) ou implantado automaticamente (deployment). |
| **Workflow** | Arquivo YAML em `.github/workflows` que define um pipeline. |
| **Trigger / evento** | O que dispara o workflow (`push`, `pull_request`, `schedule`, `workflow_dispatch`...). |
| **Job** | Conjunto de steps executados no mesmo runner; jobs rodam em paralelo salvo `needs`. |
| **Step** | Unidade de um job: um `run` (comando) ou um `uses` (action). |
| **Action** | Bloco reutilizável de automação (JavaScript, Docker ou composite). |
| **Runner** | Máquina que executa os jobs: GitHub-hosted ou self-hosted. |
| **Matrix** | Estratégia que gera vários jobs a partir de combinações de variáveis. |
| **Reusable workflow** | Workflow com `on: workflow_call`, chamado por outros workflows. |
| **Environment** | Alvo de deploy no GitHub com secrets próprios e regras de proteção (aprovação). |
| **OIDC** | Federação de identidade: o GitHub emite um token de curta duração que a AWS troca por credenciais temporárias de uma IAM Role. |
| **Imagem / contêiner** | Modelo imutável em camadas / instância em execução desse modelo. |
| **Dockerfile** | Receita de construção de uma imagem. |
| **Registry / repositório / tag** | Serviço de imagens / coleção de versões de uma imagem / identificador de versão. |
| **ECR** | Amazon Elastic Container Registry, registry gerenciado da AWS. |
| **EKS** | Amazon Elastic Kubernetes Service, Kubernetes gerenciado da AWS. |
| **Rolling update** | Estratégia do Kubernetes que troca pods gradualmente, mantendo o serviço disponível. |
| **Readiness probe** | Verificação que define quando um pod pode receber tráfego. |
| **Trivy** | Scanner open source de vulnerabilidades em imagens, arquivos e IaC. |
| **SHA pinning** | Referenciar uma action pelo hash do commit, tornando a versão imutável. |
