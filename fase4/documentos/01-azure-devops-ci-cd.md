# 1. Azure DevOps e CI/CD

> **Disciplina de origem:** Pós-Tech FIAP — Arquitetura de Sistemas .NET — Fase 4 — *Azure DevOps*
>
> **Aulas cobertas:**
> 1. Aula 01 — Conhecendo o Azure DevOps (Azure Boards, Azure Repos, Test Plans e Artifacts)
> 2. Aula 02 — Azure Dashboards e Azure Wiki
> 3. Aula 03 — Azure Pipelines e Release CI/CD
> 4. Aula 04 — Multi Stage Pipeline
>
> **Como ler este material:** o texto corrido e os blocos de código reproduzem o conteúdo dos PDFs das aulas. Tudo o que aparece em blocos `> **💡 Complemento:**` é material adicional (esclarecimentos, atualizações, boas práticas e comparações) e **não** faz parte do PDF original. Os PDFs são o material de apoio das videoaulas; parte do conteúdo prático (ex.: criação da primeira pipeline, Boards, Dashboards) é mostrada apenas em vídeo, e por isso foi complementada aqui.

---

## Aula 1 - Conhecendo o Azure DevOps

### O que vem por aí?

Nesta aula você aprenderá sobre o Azure DevOps e os seus principais serviços, como **Boards**, **Repos**, **Test Plans** e **Artifacts**.

Daremos um overview sobre cada item e quais as principais seções que podemos retirar da ferramenta. Além disso, nesta aula veremos mais sobre o **Free Tier** do Azure e quais serviços e quantidades englobam o Free Tier.

> **💡 Complemento:** visão geral dos serviços do Azure DevOps (o overview de cada serviço é feito na videoaula; segue um resumo para consulta):
>
> | Serviço | Para que serve | Equivalente aproximado no ecossistema GitHub |
> |---|---|---|
> | **Azure Boards** | Gestão ágil do trabalho: *work items* (Epic, Feature, User Story/PBI, Task, Bug), backlogs, sprints, quadros Kanban, queries e gráficos. Processos disponíveis: *Basic*, *Agile*, *Scrum* e *CMMI*. | GitHub Issues + Projects |
> | **Azure Repos** | Repositórios Git privados ilimitados (e TFVC, legado), Pull Requests com revisores obrigatórios, *branch policies* (build de validação, nº mínimo de revisores, work item vinculado). | GitHub Repositories + branch protection/rulesets |
> | **Azure Pipelines** | CI/CD em YAML (ou editor clássico), agentes hospedados pela Microsoft ou *self-hosted*, *environments* com aprovações e checks. | GitHub Actions |
> | **Azure Test Plans** | Testes manuais e exploratórios planejados, suítes de teste, rastreabilidade requisito-teste-bug. | Sem equivalente nativo direto |
> | **Azure Artifacts** | Feeds de pacotes (NuGet, npm, Maven, Python, Cargo, Universal Packages), com *upstream sources* (ex.: proxy do nuget.org). | GitHub Packages |
>
> Hierarquia: **Organization** (`https://dev.azure.com/<organizacao>`) → **Projects** → (repos, boards, pipelines etc.). Permissões e cobranças são, em geral, por organização.

### Hands on

Boas-vindas, alunos e alunas.

Nesta primeira aula conheceremos o Azure DevOps, além de aprender sobre o Free Tier da Azure.

Bons estudos!

### Saiba mais: o Free Tier da Azure

Atualmente, as principais Clouds contam com o **Free Tier** (nível gratuito), que tem o intuito de liberar uma demo para que qualquer pessoa consiga testar seus serviços sem precisar desembolsar dinheiro para isso.

A Azure disponibiliza uma quantidade de serviços para testes que estão dentro do nível gratuito; essa abordagem por parte das empresas garante testes eficientes para que usuários consigam ter certeza de que o serviço será valioso para o negócio, evitando desistências e insatisfações, além de trazer muitos clientes para dentro da Cloud Azure, permitindo que usuários testem e se encantem com os serviços da empresa.

Na figura 1, temos um overview sobre os principais serviços disponíveis no nível gratuito e qual quantidade caracteriza esse nível. Serviços como **Virtual Machines** (máquinas virtuais) permitem usar **750 horas** nas opções **B1s, B2pts v2 (ARM) e B2ats v2 (AMD)** durante o período de **12 meses**, ou 750 horas para usar bancos de dados com arquitetura **B1MS** com até **32 GB de armazenamento + 32 GB de armazenamento de backup**, seja MySQL, Postgres ou SQL Server.

O **Azure DevOps** também está neste Free Tier e permite **até 5 usuários com repositórios Git ilimitados**, além de se manter **sempre gratuito**, não limitando-se aos 12 meses dos demais serviços citados, desde que o limite de 5 usuários na plataforma seja mantido.

_Figura 1 – Azure Free Tier (Fonte: Azure, 2024): cards "Take advantage of free products" com os itens abaixo._

| Validade | Serviço | Quantidade gratuita (conforme a figura) |
|---|---|---|
| 12 meses | Azure Virtual Machines — Windows | 750 horas de cada B1s, B2pts v2 (Arm) e B2ats v2 (AMD), VMs *burstable* |
| 12 meses | Azure Virtual Machines — Linux | 750 horas de cada B1s, B2pts v2 (Arm) e B2ats v2 (AMD), VMs *burstable* |
| Sempre | Azure SQL Database | 100.000 vCore-segundos de uso *serverless* por mês, com 32 GB de armazenamento |
| 12 meses | Azure Blob Storage | 5 GB LRS *hot block*, com 20.000 leituras e 10.000 escritas |
| Sempre | Azure Cosmos DB | 1.000 RU/s de *throughput* provisionado com 25 GB de armazenamento |
| Sempre | Azure App Service | 10 apps web, mobile ou API com 1 GB de armazenamento, 1 hora por dia |
| Sempre | Azure Functions | 1 milhão de requisições |
| Sempre | Azure Event Grid | 100.000 operações por mês |

Além desse nível gratuito, é possível obter **200 dólares para usar nos primeiros 30 dias** para testar a fundo os serviços Azure que estejam dentro do Free Tier ou ainda para usar com serviços que não estejam no nível gratuito: basta preencher os dados. A Azure garante que **não haverá cobranças automáticas**.

Isso significa que, ao consumir os 200 dólares, será confirmado primeiramente com o usuário se ele quer continuar com a opção **pay-as-you-go** (pagar pelo que usa); caso não queira, os serviços que utilizou fora do Free Tier somando os 200 dólares deixarão de estar disponíveis e será possível utilizar somente os serviços que englobam o Free Tier pelo tempo baseado em cada serviço.

_Figura 2 – Azure Sign Up (Fonte: Azure, 2024): formulário "Your profile" (Country/Region = Brazil, nome, e-mail, telefone com botões "Text me"/"Call me", CNPJ opcional, endereço) e, ao lado, "Create your Azure free account": serviços populares grátis por 12 meses, 55+ serviços sempre grátis, USD 200 de crédito nos primeiros 30 dias, "No automatic charges"._

#### Criando a conta

É importante selecionar uma **região** que atenda aos dados preenchidos, neste caso o Brasil (a tela avisa que essa seleção não pode ser alterada depois). Outro campo importante é o de **telefone**, pois a Azure precisará confirmar a veracidade da conta com um SMS ou ligação.

Ao preencher todos os campos necessários para criar uma conta, basta clicar em **Next**. Lembrando que o campo do **CNPJ** precisa ser preenchido se você criar uma conta em nome de uma empresa. Se for para uso individual, basta deixar o campo em branco.

Assim como as demais provedoras Cloud, será necessário inserir um **cartão de crédito válido**. Porém não será cobrado nenhum valor, apenas se você sair do Free Tier, terminar os créditos de 200 dólares e aprovar o uso do pay-as-you-go. Do contrário, o cartão será utilizado somente para criação da conta.

Se você utilizar **somente o Azure DevOps não será necessário inserir um cartão de crédito**, já que se trata de um serviço totalmente gratuito. Assim, no final das contas, o Free Tier + os 200 dólares de crédito garantem um teste efetivo da plataforma e um valor alto para utilizar nos serviços.

#### Azure for Students

Se você não quiser utilizar ou se não tiver um cartão de crédito para obter os 200 dólares de crédito, dá para obter **100 dólares com o programa "Azure para Estudantes"**. Não é necessário um cartão de crédito, mas é preciso seguir alguns requisitos para a obtenção do crédito. O "Azure for Students" está disponível apenas para estudantes que atendam aos seguintes requisitos:

- Você deve afirmar que frequenta uma instituição educacional credenciada, que concede diploma, com duração de dois ou quatro anos e onde é estudante em tempo integral.
- Você deve verificar seu status acadêmico por meio do endereço de e-mail da sua organização.

_Figura 3 – Azure for Students (Fonte: Azure, 2024): página "Crie gratuitamente na nuvem com o Azure for Students" — "Comece com US$ 100 de crédito do Azure", "Não é necessário cartão de crédito" + serviços gratuitos enquanto tiver crédito; botões "Comece gratuitamente" e "Saiba mais sobre elegibilidade"._

No caso do programa de estudantes, o crédito de 100 dólares pode ser resgatado no final dos 12 meses: basta se inscrever novamente no programa para receber o crédito mais uma vez.

> **💡 Complemento (atualização):** valores, SKUs e prazos do Free Tier mudam com frequência — os números acima refletem a página da Azure em abril/2024 (data de acesso das referências da aula). Antes de criar recursos, confira `https://azure.microsoft.com/pricing/free-services` e configure um **Budget com alerta** em *Cost Management* para não ser surpreendido. Lembre-se também de que "750 horas/mês" equivale a **uma** VM ligada o mês inteiro; duas VMs ligadas consomem a cota na metade do tempo, e discos, IPs públicos e tráfego de saída podem ser cobrados à parte.

> **💡 Complemento:** o que é gratuito especificamente no **Azure DevOps** (plano por organização):
> - **Basic**: os 5 primeiros usuários são grátis; usuários **Stakeholder** (acesso limitado, ex.: ver e editar work items) são ilimitados e gratuitos.
> - **Azure Pipelines**: 1 *parallel job* hospedado pela Microsoft (para projetos privados, com limite mensal de minutos) e 1 *parallel job* **self-hosted** com minutos ilimitados. **Armadilha comum:** em organizações novas, o *parallel job* hospedado gratuito precisa ser **solicitado** via formulário da Microsoft (medida contra abuso/mineração); até a aprovação, a pipeline fica na fila com o erro "No hosted parallelism has been purchased or granted". Usar um agente *self-hosted* (Aula 3) contorna isso.
> - **Azure Artifacts**: 2 GiB de armazenamento gratuitos.
> - **Azure Test Plans**: **não** está incluso no Basic; é uma licença paga (Basic + Test Plans), com período de avaliação.

### O que você viu nesta aula?

Nesta aula, você viu como ter acesso aos serviços da Azure gratuitos durante 1 ano, além de obter um crédito de 200 dólares válidos pelos primeiros 30 dias.

Também analisou a possibilidade de utilizar a licença para estudantes com crédito de 100 dólares, sem a necessidade de um cartão de crédito e sendo possível uma renovação anual.

### Referências da aula

- AZURE. *Build in the cloud free with Azure for Students*. <https://azure.microsoft.com/en-us/free/students/>
- AZURE. *Criar sua conta gratuita do Azure*. <https://signup.azure.com/signup?offer=MS-AZR-0044P>
- AZURE. *Explore free Azure services*. <https://azure.microsoft.com/en-us/pricing/free-services>
- MICROSOFT BUILD. *Azure DevOps documentation*. <https://learn.microsoft.com/en-us/azure/devops/?view=azure-devops>

Palavras-chave: Azure. DevOps. Free Tier.

### Pontos-chave

- O Azure DevOps reúne **Boards** (gestão ágil), **Repos** (Git), **Pipelines** (CI/CD), **Test Plans** (testes manuais) e **Artifacts** (feeds de pacotes).
- O Azure DevOps é **sempre gratuito** para até **5 usuários** com repositórios Git privados ilimitados, e não exige cartão de crédito.
- O Free Tier da Azure combina serviços grátis por **12 meses**, serviços **sempre grátis** e **US$ 200 de crédito** nos primeiros 30 dias.
- Não há cobrança automática: ao esgotar o crédito, a Azure pergunta se você quer migrar para **pay-as-you-go**.
- O **Azure for Students** oferece **US$ 100** sem cartão de crédito, renováveis anualmente, mediante verificação por e-mail institucional.
- A região escolhida no cadastro não pode ser alterada depois; CNPJ só é necessário para contas empresariais.
- Cotas e SKUs do Free Tier mudam: sempre confira a página oficial e configure alertas de orçamento.

---

## Aula 2 - Azure Dashboards e Azure Wiki

### O que vem por aí?

Boas-vindas, alunos e alunas!

Nesta aula, você aprenderá como criar **Dashboards** e uma **Wiki** para o seu projeto Azure, além de aprender os comandos mais utilizados na linguagem **Markdown**.

Bons estudos!

### Hands on

Nesta segunda aula, você aprenderá alguns comandos Markdown para a utilização em nosso Azure Wiki.

É importante ressaltar que **todos os comandos descritos nessa aula também funcionarão no `README.md`**.

> **💡 Complemento:** Dashboards e Wiki no Azure DevOps (a criação é demonstrada na videoaula; resumo para consulta):
>
> **Dashboards** (*Overview → Dashboards*): painéis compostos por **widgets** para dar visibilidade ao time e aos stakeholders. Podem ser **de time** (*team dashboard*) ou **de projeto** (*project dashboard*). Widgets comuns: *Build History*, *Deployment status*, *Release Pipeline Overview*, *Test Results Trend*, *Burndown/Burnup*, *Sprint Overview*, *Velocity*, *Cumulative Flow Diagram*, *Query Results/Query Tile* (a partir de queries do Boards), *Markdown* (texto livre) e *Code Tile*. Boa prática: um dashboard enxuto por público (time de desenvolvimento x gestão) em vez de um painel com dezenas de widgets.
>
> **Wiki** (*Overview → Wiki*): há dois tipos:
> - **Project wiki**: criada pelo próprio portal; por baixo é um repositório Git oculto (`<projeto>.wiki`). Bom para documentação geral do projeto.
> - **Code wiki** (*Publish code as wiki*): publica uma pasta de um repositório existente (ex.: `/docs`) como wiki. A documentação passa a ser versionada junto com o código e revisada via Pull Request — abordagem de *docs as code*, geralmente preferível para documentação técnica.
>
> A ordem das páginas de uma pasta pode ser controlada com o arquivo `.order`.

### Saiba mais: Markdown

Como podemos ver, na seção Wiki utilizamos a linguagem **Markdown**. Essa linguagem também é utilizada no `README.md` do repositório e é possível inserir diversas informações diferentes. Assim, nesta seção, vamos abordar esses elementos.

#### Títulos e subtítulos

O primeiro e principal objeto utilizado no Markdown são os **títulos e subtítulos**; os tamanhos se diferenciam pela quantidade de `#` antes da escrita.

_Figura 1 – Títulos e Subtítulos Markdown: à esquerda o código, à direita a renderização com "Fiap" em cinco tamanhos decrescentes._

```markdown
# Fiap

## Fiap

### Fiap

#### Fiap

##### Fiap
```

#### Listas ordenadas, listas com marcadores e listas aninhadas

Outra coisa bastante utilizada diz respeito aos **números ordenados** e **listas com marcadores**, os quais são empregados para montar listas e indicar opções. Além dos dois citados, temos a opção de **listas aninhadas**, que têm o intuito de inserir uma lista e uma sublista no mesmo bloco.

_Figura 2 – Tipos de ordenação Markdown (1): código e renderização de lista numerada, lista com marcadores e lista com sublista, separadas por linhas horizontais (`---`)._

```markdown
1. Numeros
2. Ordenados
3. Fiap
---
- Lista
- com
- marcadores
---
- Lista
  - aninhadas
  - ou
  - sublistas
```

#### Citações em bloco (blockquotes)

Além da opção de citações em bloco ou "blockquotes": basta trocar o traço por `>`.

_Figura 3 – Tipos de ordenação Markdown (2): citação "Fiap On" com uma citação aninhada contendo três cursos._

```markdown
> Fiap On
>> Curso DevOps
>> Curso .NET
>> Curso Redes
```

#### Checklist (lista de tarefas)

Uma **lista de tarefas** ou **checklist** pode ser inserida para analisar o andamento de uma tarefa, o que pode ser usado em uma documentação de **Pull Request**. Para criar uma checklist, é necessário utilizar o sinal de lista e inserir colchetes (`[ ]` para item pendente e `[x]` para item concluído).

_Figura 4 – Checklist Markdown: itens A–F renderizados como caixas de seleção, com B, E e F marcados._

```markdown
- [ ] A
- [x] B
- [ ] C
- [ ] D
- [x] E
- [x] F
```

#### Links, imagens e âncoras

Outro recurso bastante usado é o de **Link**, **Imagens** e **Âncoras**, em que cada um possui um papel específico. O **link** somente insere um link externo para que seja acessado a partir de um "alias" ou nome amigável; já o de **imagem** pega imagens salvas localmente e torna possível inserir o link em que a imagem está sendo disponibilizada.

Os links de imagens fazem com que a imagem seja inserida na página, diferentemente do link de um site externo, que não insere uma imagem do site em questão.

Por fim, os **links âncoras** têm o papel de referenciar um título ou campo inserido no documento. O link âncora pode apontar para uma página diferente ou para um tópico dentro da mesma página.

_Figura 5 – Links Markdown: renderização de "Link externo" (Fiap Pós Tech), "Link de imagem" (banner Fiap On exibido na página) e "Link ancora" apontando para o título "Link externo"._

```markdown
# Link externo
[Fiap Pós Tech](https://postech.fiap.com.br/)

---


# Link de imagem
![Fiap On](https://sindpd.org.br/sindpd/upload/news/1638378752874.jpg)

---


# Link ancora
[Link externo](#link-externo)
```

É possível notar as diferenças entre os links:

- Link externo: `[ ]( )`
- Link de imagem: `![ ]( )`
- Link âncora: `[ ](#)`

O link âncora linka um título ou página específica e o nome do título deve estar em **caracteres minúsculos**; além disso, é necessário **trocar o espaço por traço (`-`)**.

> **💡 Complemento:** na âncora, além de minúsculas e espaços viram `-`, a maioria dos renderizadores remove pontuação (ex.: `## Aula 1 - Introdução` vira algo como `#aula-1---introdução`). Em caso de dúvida, passe o mouse sobre o título renderizado e copie o link gerado. No Azure DevOps Wiki, para linkar outra página da wiki use o caminho da página, ex.: `[Guia](/Arquitetura/Guia-de-Deploy)` — note que espaços no nome da página viram `-` no caminho.

#### Tabelas

As **tabelas** podem organizar informações que tenham colunas e linhas e são usadas para estruturar informações de forma que não fiquem juntas; é possível colocar um cabeçalho assim como no Excel.

Para criar uma tabela é necessário seguir um padrão: `|` para separador de colunas, `-` para separar o cabeçalho das linhas e `:` para alinhar os textos dentro das colunas.

_Figura 6 – Tabela Markdown: tabela centralizada com colunas 2022–2025._

```markdown
| 2022 | 2023 | 2024 | 2025 |
|:-----------:|:-----------:|:-----------:|:-----------:|
| DevOps |Docker | Github |  IA |
| Azure | Kubernetes | Azure DevOps | Terraform |
| AWS | Jenkins | Github Actions | Ansible |
```

> **💡 Complemento:** alinhamento com `:` — `:---` alinha à esquerda, `---:` à direita e `:---:` centraliza (como na figura). O número de hífens não importa (mínimo de três é a convenção).

#### Blocos de código com linguagem

Aprofundando um pouco sobre o **bloco de código**, é possível escolher a linguagem empregada nesse bloco para alterar as cores em destaque (*syntax highlighting*) com base na linguagem escolhida. Sabemos que para adicionar um bloco de código podemos digitar ` ``` ` para abri-lo e ` ``` ` para fechá-lo.

Para definir uma linguagem, basta inserir o nome da linguagem na abertura do bloco de código.

Exemplo de bloco C#:

_Figura 7 – Csharp Markdown: código à esquerda e renderização com destaque de sintaxe à direita._

````markdown
```csharp
using System;
using static System.Linq.Enumerable;
using static System.Math;

class Tpk
{
    static double F(double t) => Sqrt(Abs(t))
    + 5 * Pow(t, 3);

    static void Main()
    {
        var a = Range(0, 11).Select(_ => double.Parse
        (Console.ReadLine())).ToArray();
        foreach (var i in Range(0, a.Length).Reverse())
        {
            var y = F(a[i]);
            Console.WriteLine(y > 400 ? $"{i} TOO LARGE" :
            $"{i} {y}");
        }
    }
}
```
````

Exemplo em Node:

_Figura 8 – Node Markdown: bloco `javascript` com um servidor Express renderizado com destaque de sintaxe._

````markdown
```javascript
const express = require('express');
const app = express();
const PORT = process.env.PORT || 3000;

app.get('/', (req, res) => {
  res.send('Hello, Docker!');
});

app.listen(PORT, () => {
  console.log(`Server running on port ${PORT}`);
});

```
````

> **💡 Complemento:** recursos específicos do Markdown do **Azure DevOps Wiki** que não existem no Markdown "puro":
> - `[[_TOC_]]` — insere um sumário automático da página.
> - `[[_TOSP_]]` — lista as subpáginas.
> - Diagramas **Mermaid** com a sintaxe de bloco `::: mermaid` ... `:::` (no GitHub a sintaxe é um bloco de código ` ```mermaid `).
> - Menção a pessoas com `@` e a work items com `#123` (gera link para o item do Boards).
>
> Para Markdown escrito dentro de repositórios (README, ADRs), prefira o subconjunto comum (CommonMark/GFM), que funciona tanto no Azure Repos quanto no GitHub.

### O que você viu nesta aula?

Você viu nesta aula como criar dashboards e para qual finalidade eles se propõem.

Além disso, também aprendeu a criar um Azure Wiki para os demais membros do projeto, além de aprender mais a fundo os principais comandos do Markdown.

### Referências da aula

- MICROSOFT BUILD. *Use Markdown in Azure DevOps*. <https://learn.microsoft.com/en-us/azure/devops/project/wiki/markdown-guidance?view=azure-devops>
- MARKDOWN GUIDE. *Markdown Guide*. <https://www.markdownguide.org/>
- SILVEIRA, P. *Markdown: como trabalhar com essa linguagem de markup?* Alura, 2022. <https://www.alura.com.br/artigos/como-trabalhar-com-markdown>

Palavras-chave: Azure. Markdown. Wiki.

### Pontos-chave

- **Dashboards** dão visibilidade ao andamento do projeto por meio de widgets (builds, deploys, sprints, queries).
- A **Azure Wiki** usa **Markdown**, e os mesmos comandos funcionam no `README.md`.
- Títulos usam `#` (mais `#` = nível menor); listas usam `1.` ou `-`, com indentação para sublistas; citações usam `>`.
- Checklists (`- [ ]` / `- [x]`) são úteis em descrições de Pull Request.
- Links: externo `[ ]( )`, imagem `![ ]( )`, âncora `[ ](#titulo-em-minusculas-com-tracos)`.
- Tabelas usam `|` para colunas, `-` para o cabeçalho e `:` para alinhamento.
- Blocos de código com o nome da linguagem após ` ``` ` ativam o destaque de sintaxe.
- Prefira *code wiki* (docs versionadas no repositório) para documentação técnica que evolui com o código.

---

## Aula 3 - Azure Pipelines e Release CI/CD

### O que vem por aí?

Boas-vindas, alunos e alunas.

Nesta aula, você aprenderá como criar uma **pipeline** e entenderá quais as diferenças existentes entre **CI** e **CD**. Além disso, também criaremos nosso próprio **pool** e um **grupo de variáveis**.

Bons estudos!

> **💡 Complemento:** CI x CD — conceitos.
> - **CI (Continuous Integration / Integração Contínua):** a cada push ou Pull Request, o código é integrado à branch principal e automaticamente **compilado e testado** (restore, build, testes unitários, análise estática). O produto da CI é um **artefato** versionado e imutável (um pacote, um `.zip` publicado ou uma imagem Docker).
> - **CD (Continuous Delivery / Entrega Contínua):** o artefato gerado pela CI é promovido automaticamente pelos ambientes (dev → staging), ficando **sempre pronto** para ir à produção — a ida para produção depende de uma aprovação manual.
> - **CD (Continuous Deployment / Implantação Contínua):** igual à anterior, mas **sem** aprovação manual: tudo que passa nos testes vai para produção.
>
> Regra de ouro: **build once, deploy many** — o mesmo artefato que foi testado é o que vai para cada ambiente; o que muda entre ambientes é a configuração (variáveis/segredos), nunca o binário.
>
> No Azure DevOps existem duas formas de definir isso: **pipelines YAML** (`azure-pipelines.yml` versionado no repositório, cobrindo CI e CD com *stages*) e o editor **clássico** (*Classic Build* + *Releases*, configurados pela interface web). O título "Release CI/CD" remete às **Releases** clássicas.
>
> **Atualização:** a Microsoft recomenda YAML para novos projetos; novos recursos (ex.: *environments*, checks, templates) são focados em YAML, e organizações novas costumam vir com a criação de pipelines clássicas **desabilitada** por padrão (configuração *Disable creation of classic build and release pipelines* em *Organization/Project Settings → Pipelines → Settings*).

> **💡 Complemento:** exemplo mínimo de pipeline de CI para uma API .NET (ilustrativo — não faz parte do PDF):
>
> ```yaml
> trigger:
>   branches:
>     include:
>       - main
>
> pr:
>   - main
>
> pool:
>   vmImage: ubuntu-latest
>
> variables:
>   buildConfiguration: 'Release'
>
> steps:
>   - task: UseDotNet@2
>     inputs:
>       packageType: 'sdk'
>       version: '8.x'
>
>   - script: dotnet restore
>     displayName: 'Restore'
>
>   - script: dotnet build --configuration $(buildConfiguration) --no-restore
>     displayName: 'Build'
>
>   - script: dotnet test --configuration $(buildConfiguration) --no-build --logger trx
>     displayName: 'Testes'
>
>   - task: PublishTestResults@2
>     condition: succeededOrFailed()
>     inputs:
>       testResultsFormat: 'VSTest'
>       testResultsFiles: '**/*.trx'
>
>   - script: dotnet publish --configuration $(buildConfiguration) --output $(Build.ArtifactStagingDirectory)
>     displayName: 'Publish'
>
>   - task: PublishPipelineArtifact@1
>     inputs:
>       targetPath: '$(Build.ArtifactStagingDirectory)'
>       artifact: 'drop'
> ```
>
> Estrutura hierárquica de uma pipeline YAML: **pipeline → stages → jobs → steps** (cada *step* é um `script`/`bash`/`pwsh` ou uma `task`). Cada **job** roda em um **agente**; *steps* do mesmo job compartilham o mesmo workspace.

### Hands on

Nesta terceira aula, vamos criar nosso primeiro **pool** para que nossas pipelines rodem utilizando nossa própria máquina.

### Saiba mais: Agent pools e agentes self-hosted

No Azure DevOps temos o serviço de **pipelines**, as quais são responsáveis por nos auxiliar e executar nossa pipeline CI/CD de forma automatizada sempre que um evento específico ocorrer. E toda vez que essa pipeline roda, ela roda em alguma máquina com um sistema operacional necessário para executar comandos que criam e "buildam" nossas aplicações.

Elas são chamadas de **pools** e, por padrão, executamos em pools disponibilizados pela própria Azure, que rodam em Azure Containers. Também há a opção de rodar nos seguintes sistemas operacionais:

- Linux.
- Windows.
- MacOS.

Eles não ficam restritos a somente essas três opções: é possível também executar em uma máquina qualquer, só é necessário instalar alguns pacotes disponibilizados pela Azure para que a máquina usada tenha as configurações mínimas para executar como pool dentro do Azure Pipelines.

> **💡 Complemento:** terminologia precisa — **agent** (agente) é o software/máquina que executa os jobs; **agent pool** é o agrupamento de agentes. Os agentes **Microsoft-hosted** (pool *Azure Pipelines*) são, na prática, **VMs efêmeras** criadas para cada job e descartadas ao final (imagens como `ubuntu-latest`, `windows-latest`, `macos-latest`), já com SDKs e ferramentas comuns instaladas. Os **self-hosted** são máquinas suas (VM, servidor on-premises, container ou até seu notebook), que mantêm estado entre execuções (cache, ferramentas instaladas) e podem acessar redes privadas. Há ainda os **Managed DevOps Pools** / *Azure Virtual Machine Scale Set agents*, que são agentes self-hosted com escala automática gerenciada pela Azure.

Nesta aula, você aprenderá como instalar e rodar uma pipeline usando sua própria máquina como pool dentro do Azure DevOps.

#### Passo 1 — Criar o agent pool

Primeiro, será necessário logar na organização Azure DevOps em que será criado o pool, além de estar dentro do projeto em que a pipeline rodará.

1. Para criar um pool, vá para **Project Settings** e em seguida selecione a opção **Agent pools**, na seção **Pipelines**.
2. Clique no botão no canto superior direito **Add Pool**.
3. Em **Pool to Link**, marque a opção **New** e em **Pool Type** selecione **"Self-hosted"**.
4. Dê um nome e uma descrição para o pool e selecione as permissões, garantindo acesso para todas as pipelines (*Grant access permission to all pipelines*). Se quiser limitar as permissões e liberar caso a caso, não marque esta opção.
5. Por fim, clique em **"Create"**.

> **💡 Complemento (boa prática):** evite marcar "acesso para todas as pipelines" em pools que tenham acesso a redes ou credenciais sensíveis. Sem essa opção, na primeira execução a pipeline pede autorização para usar o pool, o que dá controle sobre quais pipelines podem rodar código em suas máquinas.

#### Passo 2 — Instalar o agent (Linux Ubuntu via WSL)

Com o pool criado, será necessário instalar um novo **agent**, que será responsável por habilitar a conexão entre a sua máquina e o Azure DevOps. Uma nova tela aparecerá (botão **New agent**) para seguir os comandos baseados no sistema operacional que deseja usar como pool. Para esta aula, vamos instalar o agent no **Linux Ubuntu por meio do WSL do Windows**.

_Figura 1 – Agent pool - Pipelines: janela "Get the agent" com abas Windows/macOS/Linux (Linux x64 selecionado), botão "Download" e os comandos de criação, configuração e execução do agente._

Comandos exibidos na tela (Linux x64):

```bash
# Create the agent
~/$ mkdir myagent && cd myagent
~/myagent$ tar zxvf ~/Downloads/vsts-agent-linux-x64-3.232.1.tar.gz

# Configure the agent
~/myagent$ ./config.sh

# Optionally run the agent interactively
# (If you didn't run as a service above)
~/myagent$ ./run.sh
```

Agora, os comandos devem ser executados conforme os passos em tela. No momento de configurar o agent (`./config.sh`), uma confirmação será necessária para aceitar os termos da instalação; digite **`Y`** e Enter. Em **Server URL**, insira a URL da organization que criou; o valor tem que ficar parecido com este:

```text
https://dev.azure.com/profdouglaslima
```

Em **Authentication Type**, pressione **Enter** para **PAT** (*Personal Access Token*).

#### Passo 3 — Gerar o Personal Access Token (PAT)

O valor do token será solicitado e, para pegar este valor, vá novamente para as configurações, no canto superior direito da tela, e selecione **User Settings > Personal Access Tokens**.

_Figura 2 – PAT - Pipelines: menu do ícone "User settings" (ao lado do avatar) com a opção "Personal access tokens" destacada._

1. Crie um token clicando no botão **+ New Token**.
2. Dê um nome para ele, atrele a **organization** em que o pool estará (caso tenha mais de uma) e selecione a **expiração** do token. Por padrão teremos 30 dias, mas dá para selecionar 60, 90 ou definir um tempo específico.
3. Selecione o escopo **Agent Pools: Read & manage**.
4. Finalize a criação com o botão **Create**.
5. Copie e salve o token em um local seguro, volte para o WSL e cole o token gerado.

> **💡 Complemento (segurança):** o PAT é uma credencial com o seu nível de acesso. Use **sempre o escopo mínimo** (aqui, só *Agent Pools: Read & manage* — nunca *Full access*), validade curta e nunca o coloque em código ou em arquivos versionados. O PAT é usado apenas no **registro** do agente; depois disso o agente passa a usar credenciais próprias, então o PAT pode expirar ou ser revogado sem derrubar o agente já registrado.
>
> **Atualização:** a Microsoft vem desincentivando PATs no Azure DevOps em favor de autenticação via **Microsoft Entra ID** (ex.: *service principal* ou *managed identity*), inclusive para registrar agentes (`config.sh` aceita outros tipos de autenticação além de PAT). Para estudo, o PAT é o caminho mais simples; em produção, avalie as alternativas.

#### Passo 4 — Registrar o agente

_Figura 3 – Agent pool install - Pipelines: terminal do WSL (`fiap@DESKTOP-6FOSH4S:~/myagent`) executando o agente v3.232.1 — aceite da licença, conexão ao servidor com PAT e registro no pool `self-hosted`._

Em seguida, o agente se conectará com o Azure DevOps e solicitará algumas informações para prosseguir, como o nome do **agent pool** e o nome do **agente**. Se preferir, você pode pressionar Enter que os valores irão como padrão.

Sequência mostrada no terminal:

```text
>> End User License Agreements:

Building sources from a TFVC repository requires accepting the Team Explorer Everywhere End User License Agreement. This step is not required for building sources from Git repositories.

A copy of the Team Explorer Everywhere license agreement can be found at:
  /home/fiap/myagent/license.html

Enter (Y/N) Accept the Team Explorer Everywhere license agreement now? (press enter for N) > Y

>> Connect:

Enter server URL > https://dev.azure.com/profdouglaslima
Enter authentication type (press enter for PAT) >
Enter personal access token > ****************************************************
Connecting to server ...

>> Register Agent:

Enter agent pool (press enter for default) > self-hosted
Enter agent name (press enter for DESKTOP-6FOSH4S) >
Scanning for tool capabilities.
Connecting to the server.
Successfully added the agent
Testing agent connection.
Enter work folder (press enter for _work) >
2024-01-19 04:32:35Z: Settings Saved.
```

#### Passo 5 — Colocar o agente on-line

Volte para **Project Settings > Agent Pools > Nome-Do-Agent-Pool > Agents** e perceba que a máquina está lá, mas **offline**.

_Figura 4 – Agent pool offline - Pipelines: Project Settings → Agent pools → pool `self-hosted` → aba "Agents", com o agente `DESKTOP-6FOSH4S` listado como "Offline" (status "Idle")._

Agora vamos deixá-la on-line com o último comando:

```bash
./run.sh
```

Com o último comando executado, podemos observar que agora o agente está **on-line** e podemos usá-lo em nossas pipelines.

_Figura 5 – Agent pool online - Pipelines: agente `DESKTOP-6FOSH4S` com status "Online"._

> **💡 Complemento:** `./run.sh` executa o agente **interativamente** — ao fechar o terminal (ou o WSL), o agente fica offline de novo. Para deixá-lo permanente em uma VM/servidor Linux, instale-o como serviço (systemd):
>
> ```bash
> sudo ./svc.sh install
> sudo ./svc.sh start
> sudo ./svc.sh status
> ```
>
> Também é possível configurar sem prompts (útil em scripts de provisionamento), ex.: `./config.sh --unattended --url https://dev.azure.com/<org> --auth pat --token <PAT> --pool self-hosted --agent <nome> --acceptTeeEula`. Obs.: dentro do WSL, `systemd` precisa estar habilitado na distro para o modo serviço funcionar.
>
> **Atualização:** a versão do agente na aula é a 3.232.1; o Azure Pipelines já distribui a série **4.x** do agente. Baixe sempre o pacote indicado na tela *New agent* da sua organização, pois o nome do `.tar.gz` muda a cada versão.

#### Passo 6 — Usar o pool na pipeline

Atualizamos a pipeline e trocamos a seção:

_Figura 6 – vmImage - Pipelines: trecho original do YAML usando agente hospedado._

```yaml
pool:
  vmImage: ubuntu-latest
```

Por:

_Figura 7 – self-hosted - Pipelines: trecho do YAML apontando para o pool criado._

```yaml
pool: self-hosted
```

A pipeline começará a rodar. No exemplo da figura 8, deixamos um job com `vmImage` usando Ubuntu e no segundo job, de deploy, utilizamos nosso pool criado.

_Figura 8 – Pipeline exec - Pipelines: run `#20240119.7` com os jobs "Build" (falhou no step "Build an image") e "Deploy" (sucesso no step "Deploy on Cloud"). O log do step Docker mostra `The command 'docker' could not be found in this WSL 2 distro. We recommend to activate the WSL integration in Docker Desktop settings.` e termina com `##[error]The process '/mnt/c/Program Files/Docker/Docker/resources/bin/docker' failed with exit code 1`._

Agora você sabe como rodar uma pipeline utilizando sua máquina como executora. O pool é bastante utilizado para rodar as pipelines **on-premises** ou para rodar projetos utilizando o ambiente local com as dependências e features já instaladas.

> **💡 Complemento (armadilha da Figura 8):** o agente self-hosted só enxerga as ferramentas instaladas **na máquina dele**. O erro mostrado acontece porque o Docker Desktop do Windows não estava integrado à distro do WSL. Solução: Docker Desktop → *Settings → Resources → WSL integration* → habilitar para a distro (ou instalar o Docker Engine diretamente no Ubuntu), e adicionar o usuário do agente ao grupo `docker`. Depois de instalar ferramentas novas, **reinicie o agente**: ele detecta as *capabilities* (ferramentas disponíveis) na inicialização.

> **💡 Complemento:** outras formas de referenciar pools no YAML e de escolher agentes por *capabilities*:
>
> ```yaml
> # Pool self-hosted, exigindo um agente que tenha docker
> pool:
>   name: self-hosted
>   demands:
>     - docker
>
> # Jobs diferentes em pools diferentes (como no exemplo da Figura 8)
> jobs:
>   - job: Build
>     pool:
>       vmImage: ubuntu-latest
>     steps:
>       - script: echo "build"
>   - job: Deploy
>     dependsOn: Build
>     pool: self-hosted
>     steps:
>       - script: echo "deploy"
> ```
>
> **Segurança:** nunca use um agente self-hosted em pipelines que rodem código de Pull Requests de forks/repositórios públicos — qualquer pessoa poderia executar comandos na sua máquina. Agentes self-hosted guardam estado entre execuções (arquivos de builds anteriores, credenciais em cache); limpe o workspace (`workspace: clean: all` no job) quando isso importar.

> **💡 Complemento:** **grupos de variáveis** (*variable groups*), citados na introdução da aula. Ficam em *Pipelines → Library → + Variable group* e permitem compartilhar variáveis entre várias pipelines. Variáveis marcadas com o cadeado viram **secretas** (mascaradas como `***` nos logs e não expostas automaticamente como variável de ambiente). Um grupo pode ser **vinculado a um Azure Key Vault**, de modo que os segredos ficam no cofre e não no Azure DevOps.
>
> ```yaml
> variables:
>   - group: fiap-api-dev          # grupo criado em Pipelines > Library
>   - name: buildConfiguration
>     value: 'Release'
>
> steps:
>   - script: echo "Ambiente: $(ambiente)"
>   # Segredos precisam ser mapeados explicitamente para variáveis de ambiente
>   - script: ./deploy.sh
>     env:
>       DB_PASSWORD: $(dbPassword)
> ```
>
> Para acessar recursos externos (Azure, registries, Kubernetes), use **Service connections** (*Project Settings → Service connections*) — preferencialmente do tipo *Workload Identity Federation* (OIDC), que dispensa segredos de longa duração.

### O que você viu nesta aula?

Nesta aula, vimos como criar uma pipeline CI e uma CD. Além disso, também aprendemos a criar o próprio pool a partir da sua máquina, utilizando seu sistema operacional e suas features.

### Referências da aula

- MICROSOFT BUILD. *Create and manage agent pools*. <https://learn.microsoft.com/en-us/azure/devops/pipelines/agents/pools-queues?view=azure-devops&tabs=yaml%2Cbrowser>
- MICROSOFT BUILD. *Self-hosted Linux agents*. <https://learn.microsoft.com/en-us/azure/devops/pipelines/agents/linux-agent?view=azure-devops>
- MICROSOFT BUILD. *What is Azure Pipelines?* <https://learn.microsoft.com/en-us/azure/devops/pipelines/get-started/what-is-azure-pipelines?view=azure-devops>

Palavras-chave: Agent Pool. Self-hosted. WSL. Azure Pipelines.

### Pontos-chave

- **CI** compila e testa a cada mudança gerando um artefato; **CD** promove esse mesmo artefato pelos ambientes (com ou sem aprovação manual).
- Toda pipeline roda em um **agente**, agrupado em **agent pools**: Microsoft-hosted (VMs efêmeras Linux/Windows/macOS) ou **self-hosted** (sua máquina).
- Criar pool: *Project Settings → Agent pools → Add pool → New → Self-hosted*.
- Instalar o agente: baixar o pacote, `./config.sh` (URL da organização + PAT com escopo *Agent Pools: Read & manage*) e `./run.sh` para ficar on-line.
- No YAML, troca-se `pool: vmImage: ubuntu-latest` por `pool: self-hosted`; jobs diferentes podem usar pools diferentes.
- O agente self-hosted só tem as ferramentas instaladas na máquina — atenção à integração Docker/WSL.
- Segredos ficam em **variable groups** (secretos ou ligados ao Key Vault) e **service connections**, nunca no YAML.

---

## Aula 4 - Multi Stage Pipeline

### O que vem por aí?

Boas-vindas, alunos e alunas.

Nesta aula, você aprenderá sobre **environments** dentro das pipelines do Azure DevOps, além de conseguir definir regras de deploys sobre **pipelines multistage**.

Bons estudos!

### Hands on

Nesta aula, criaremos uma pipeline multistage com **fluxo de aprovação** e **entrega contínua**. Além disso, também aprenderemos sobre environments.

> **💡 Complemento:** estrutura de uma pipeline **multistage** (ilustrativa, no formato do tutorial oficial da Microsoft referenciado na aula, cujos stages aparecem na Figura 4: *Build the web application → Deploy to the dev environment → Deploy to the staging environment → Deploy to the production environment*):
>
> ```yaml
> trigger:
>   - main
>   - stage
>
> stages:
>   - stage: Build
>     displayName: 'Build the web application'
>     jobs:
>       - job: Build
>         pool:
>           vmImage: ubuntu-latest
>         steps:
>           - script: dotnet publish -c Release -o $(Build.ArtifactStagingDirectory)
>           - publish: $(Build.ArtifactStagingDirectory)
>             artifact: drop
>
>   - stage: Dev
>     displayName: 'Deploy to the dev environment'
>     dependsOn: Build
>     jobs:
>       - deployment: Deploy
>         pool:
>           vmImage: ubuntu-latest
>         environment: dev
>         strategy:
>           runOnce:
>             deploy:
>               steps:
>                 - download: current
>                   artifact: drop
>                 - script: echo "deploy em dev"
>
>   - stage: Staging
>     displayName: 'Deploy to the staging environment'
>     dependsOn: Dev
>     jobs:
>       - deployment: Deploy
>         environment: staging
>         strategy:
>           runOnce:
>             deploy:
>               steps:
>                 - script: echo "deploy em staging"
>
>   - stage: Production
>     displayName: 'Deploy to the production environment'
>     dependsOn: Staging
>     jobs:
>       - deployment: Deploy
>         environment: production   # aprovações/checks configurados no environment
>         strategy:
>           runOnce:
>             deploy:
>               steps:
>                 - script: echo "deploy em produção"
> ```
>
> Pontos importantes: um **stage** agrupa jobs e é a unidade que aparece no diagrama da execução; por padrão, cada stage depende do anterior (`dependsOn` implícito). Um **deployment job** (`- deployment:`) é um job especial que registra o histórico de deploys no **environment** e aplica os checks dele; ele **não faz checkout automático** do repositório (use `- checkout: self` se precisar). Estratégias disponíveis: `runOnce`, `rolling` (para environments com recursos do tipo VM) e `canary` (para recursos Kubernetes).
>
> **Aprovações não ficam no YAML**: elas são configuradas no environment (portal), o que impede que alguém remova a aprovação simplesmente editando o arquivo da pipeline.

### Saiba mais: Environments

Nesta seção vamos nos aprofundar mais nos **environments** da Azure Pipelines, que são conjuntos de regras específicas que podem ser utilizadas em execuções de pipeline. É possível criar diversas regras e aplicar a um único stage dentro de uma pipeline ou ainda definir regras para uma branch específica e utilizá-las na pipeline.

Vamos olhar cada possibilidade que o environment oferece para que nossa aplicação seja entregue da melhor forma e mais segura.

Ao criar um environment (*Pipelines → Environments → New environment*), podemos dar um **nome**, uma **descrição** e selecionar um **recurso** específico em que as regras criadas nesse environment vão se aplicar. Por padrão, vamos deixar como **None** (Nenhum).

> **💡 Complemento:** as opções de recurso de um environment são **Kubernetes** (um namespace de um cluster, inclusive AKS ou outro cluster acessível) e **Virtual machines** (VMs Linux/Windows registradas no environment). Com um recurso vinculado, o Azure DevOps mostra o rastreamento do que foi implantado em cada recurso (workloads do namespace, commits e work items de cada deploy). **None** serve para environments usados apenas como "portão" de aprovação/checks e histórico.

Quando um novo environment é criado, ele tem como tela principal os **deployments** que foram executados utilizando-o e uma aba chamada **"Approvals and checks"** ao lado de Deployments.

Nela, podemos adicionar algumas regras que mudarão o funcionamento de nossa pipeline: clicando em **"See all"**, podemos analisar todas as opções disponíveis atualmente. São elas:

- **Approvals:** permite adicionar pessoas para serem as responsáveis pela aprovação de um determinado deployment.
- **Branch control:** permite que os deployments sejam executados quando uma determinada branch for alterada (somente a partir de branches permitidas).
- **Business hours:** permite definir janelas de tempo específicas em que os deployments ocorrerão; é basicamente agendar um horário para que o deploy seja feito.
- **Evaluate artifact:** permite que artefatos tenham políticas customizadas. Essa feature só é possível de ser utilizada no que diz respeito a **imagens de containers**.
- **Exclusive lock:** permite limitar o acesso a determinado recurso para somente **um único stage por vez**.
- **Invoke Azure function:** permite executar uma função criada por meio do serviço **Azure Functions** da cloud Azure.
- **Invoke REST API:** permite invocar uma **API REST** como parte de um step da pipeline.
- **Query Azure Monitor alerts:** permite analisar o monitoramento criado e configurado pelo **Azure Monitor** para alertas ativos.
- **Required template:** permite a obrigatoriedade de usar um ou mais **templates YAML** em uma pipeline. Isso evita que cada pipeline utilize o mesmo step de formas diferentes, uma regra que garante padronização nas pipelines.

_Figura 1 – Approvals and checks - Environment: painel "Add check" listando Approvals, Branch control, Business Hours, Evaluate artifact (preview), Exclusive Lock, Invoke Azure Function, Invoke REST API, Query Azure Monitor alerts e Required template, cada um com sua descrição curta._

> **💡 Complemento:** detalhes úteis sobre os checks:
> - **Approvals**: dá para exigir aprovação de usuários ou grupos, definir **timeout** (se ninguém aprovar, o stage falha) e impedir que quem disparou a execução aprove o próprio deploy.
> - **Invoke Azure Function / Invoke REST API**: o check pode ser *síncrono* ou aguardar *callback*, e pode ser reavaliado periodicamente até passar (ex.: "só faça o deploy se o change request estiver aprovado no ITSM").
> - **Query Azure Monitor alerts**: típico para bloquear deploy enquanto houver alertas ativos em produção (ou validar após o deploy em um ambiente anterior).
> - **Exclusive lock**: evita que duas execuções façam deploy simultâneo no mesmo ambiente; combinado com `lockBehavior: sequential` ou `runLatest` no YAML define quem espera ou quem é cancelado.
> - Checks também podem ser aplicados a outros recursos protegidos (service connections, agent pools, variable groups, secure files, repositórios), não apenas a environments.

### Passo a passo: Branch control por ambiente

Na videoaula criamos environments para **approvals** e dessa vez criaremos para **branch**, com o **branch control**. Então, ainda na tela de **Approvals and checks**, selecione **Branch control**.

1. Crie um check com o nome **`branch-control-prod`** e defina a branch **`main`** em **Allowed branches**. Salve.
2. Vamos criar uma segunda branch control, só que agora para stage: o nome deve ser **`branch-control-stage`** e, na branch, vamos colocar **`stage`** mesmo.

> **💡 Complemento:** no campo *Allowed branches* do Branch control a branch costuma ser informada pela referência completa (`refs/heads/main`), e aceita curingas (ex.: `refs/heads/release/*`). Há também a opção de exigir que a branch tenha **branch protection/policies** configuradas (*Verify branch protection*). Na aula, cada environment (`branch-control-prod` e `branch-control-stage`) recebe o seu check.

Agora, com os environments criados, precisamos editar nossa pipeline para inserir esses environments e executar a pipeline para ver se ela funciona corretamente.

Minha branch principal é a `main`, então vou usá-la para abrigar o código de **produção** e a branch `stage` com as configurações de **stage**. Dessa maneira, o environment funcionará e o stage de deploy em stage só será executado quando a branch de stage receber alterações.

Ao entrar em algum environment criado, podemos observar no meio da tela, quando na aba **Deployments**, o comando necessário para utilizar o environment em questão.

_Figura 2 – Environment branch control - Environment: tela "Get started!" do environment, informando "Your environment is ready to use in pipeline YAML" com o trecho abaixo e o botão "Add resource"._

```yaml
environment: branch-control-stage
```

Vá para **Pipelines** e edite a pipeline em que deseja adicionar os environments criados.

_Figura 3 – Edit pipeline - Environment: lista "Recently run pipelines" com a pipeline `fiap` e o menu de três pontos aberto, destacando a opção "Edit" (demais opções: Run pipeline, Manage security, Rename/move, Delete)._

Agora, com a pipeline em edição, procure o stage de **Staging** e troque o environment atual pelo criado. Nesse caso, vamos adicionar `environment: branch-control-stage`, além de adicionar uma **condition** para que a execução da pipeline não quebre, já que a branch `stage` não estará em execução.

Na condition, adicione para stage:

```yaml
condition: eq(variables['Build.SourceBranch'], 'refs/heads/stage')
```

E para produção:

```yaml
condition: eq(variables['Build.SourceBranch'], 'refs/heads/main')
```

Isso fará com que a execução passe a olhar a condition e **pule** essa execução caso a alteração não seja na branch relacionada ao environment. O mesmo deve ser feito para o stage de production.

> **💡 Complemento:** como fica o trecho completo dos dois stages (ilustrativo, montado a partir das instruções da aula):
>
> ```yaml
>   - stage: Staging
>     displayName: 'Deploy to the staging environment'
>     dependsOn: Dev
>     condition: and(succeeded(), eq(variables['Build.SourceBranch'], 'refs/heads/stage'))
>     jobs:
>       - deployment: Deploy
>         environment: branch-control-stage
>         strategy:
>           runOnce:
>             deploy:
>               steps:
>                 - script: echo "deploy em staging"
>
>   - stage: Production
>     displayName: 'Deploy to the production environment'
>     dependsOn: [Build, Dev]     # não depende de Staging, que é pulado na main
>     condition: and(succeeded(), eq(variables['Build.SourceBranch'], 'refs/heads/main'))
>     jobs:
>       - deployment: Deploy
>         environment: branch-control-prod
>         strategy:
>           runOnce:
>             deploy:
>               steps:
>                 - script: echo "deploy em produção"
> ```
>
> **Armadilhas comuns com `condition`:**
> 1. Ao declarar uma `condition`, ela **substitui** a condição padrão `succeeded()`. Com apenas `eq(...)`, o stage roda **mesmo que o stage anterior tenha falhado**. Por isso, combine com `and(succeeded(), ...)`.
> 2. Se o stage anterior foi **skipped**, `succeeded()` (que olha as dependências diretas) não é satisfeito e o stage seguinte também é pulado. No exemplo, como Staging é sempre pulado na `main`, Production declara `dependsOn: [Build, Dev]` em vez de depender de Staging; caso contrário, a produção nunca rodaria.
> 3. `Build.SourceBranch` traz a referência completa (`refs/heads/main`); já `Build.SourceBranchName` traz só o último segmento (`main`). Em execuções de PR, o valor é `refs/pull/<id>/merge`.
> 4. A `condition` (no YAML) e o **Branch control** (no environment) são complementares: a condition evita que o stage sequer tente rodar (status *Skipped*); o Branch control é a **barreira de segurança**, pois quem edita o YAML pode remover a condition, mas não consegue burlar o check configurado no environment.

Feitas todas as alterações necessárias, basta salvar a pipeline no canto superior direito e **comitar** na branch desejada. Assim, vamos comitar na branch `main`. Se a alteração der certo, a pipeline começará o fluxo definido.

Como podemos analisar na figura 4, o push foi feito na branch `main` (produção) e o stage que faz o deploy em staging (branch `stage`) recebeu o status de **skipped**, uma vez que o push ou alteração não foi feita na branch da regra, neste caso a branch `stage`.

_Figura 4 – Stage skipped - environment: execução `#20240120.8 • Update azure-pipelines.yml for Azure Pipelines` na branch `main`, com os stages "Build the web application" (sucesso, 1 artifact), "Deploy to the dev environment" (sucesso), "Deploy to the staging environment" (**Skipped**) e "Deploy to the production environment" (**Waiting** — "Permission needed"), e o aviso "This pipeline needs permission to access a resource before this run can continue to Deploy to the production environment" com o botão "View"._

Dessa maneira, conseguimos separar os ambientes por meio de regras criadas utilizando environments.

> **💡 Complemento:** o aviso "This pipeline needs permission to access a resource" (Figura 4) aparece na **primeira vez** que uma pipeline usa um environment (ou pool, service connection etc.) que não está liberado para todas as pipelines. Clique em **View → Permit** para autorizar; é uma autorização única por pipeline/recurso, diferente das aprovações, que são pedidas a cada execução.

> **💡 Complemento:** estratégia de branches. O modelo da aula (uma branch por ambiente: `stage` → staging, `main` → produção) funciona, mas obriga a "promover" código por merges entre branches, o que pode fazer com que o artefato de produção seja diferente do testado em staging. Uma alternativa muito usada é o **trunk-based**: um único build da `main` gera o artefato, que passa por dev → staging → produção na **mesma execução**, com **Approvals** como portão de produção. Assim vale o princípio *build once, deploy many*.

### O que você viu nesta aula?

Você viu nesta aula como funcionam os environments do Azure Pipelines. Além disso, você aprendeu também a criar um environment com o branch control e aplicar em cada branch que deseja.

### Referências da aula

- MICROSOFT. *Create and target an environment*. <https://learn.microsoft.com/en-us/azure/devops/pipelines/process/environments?view=azure-devops>
- MICROSOFT. *Specify conditions*. <https://learn.microsoft.com/en-us/azure/devops/pipelines/process/conditions?view=azure-devops&tabs=yaml%2Cstages>
- MICROSOFT. *Tutorial: criar um pipeline de várias fases com o Azure DevOps*. <https://learn.microsoft.com/pt-br/azure/devops/pipelines/process/create-multistage-pipeline?view=azure-devops>

Palavras-chave: Environment. Branch Control. Multistage.

### Pontos-chave

- Uma pipeline **multistage** organiza o fluxo em **stages** (build → dev → staging → produção), cada um com seus jobs.
- **Environments** representam ambientes de deploy e concentram histórico de deployments e **Approvals and checks**.
- Checks disponíveis: Approvals, Branch control, Business hours, Evaluate artifact, Exclusive lock, Invoke Azure Function, Invoke REST API, Query Azure Monitor alerts e Required template.
- **Branch control** restringe quais branches podem fazer deploy em um environment (ex.: só `main` em produção).
- No YAML, o environment é referenciado com `environment: <nome>` em um **deployment job**.
- `condition: eq(variables['Build.SourceBranch'], 'refs/heads/<branch>')` faz o stage ser **skipped** em outras branches — combine com `succeeded()` para não ignorar falhas.
- Aprovações e checks ficam fora do YAML, o que os torna uma barreira real de governança.

---

## Aplicação no Tech Challenge da Fase 4

O Tech Challenge da Fase 4 pede que os microsserviços .NET do **FIAP Cloud Games** — **UsersAPI**, **CatalogAPI**, **PaymentsAPI** e **NotificationsAPI** — tenham uma pipeline de CI/CD que faça: **build + testes**, **imagem Docker com tag**, **scan de vulnerabilidades**, **push para o registry da cloud** e **deploy com rolling update em Kubernetes gerenciado**, com **zero credenciais hardcoded**.

O grupo tende a usar **AWS (EKS + ECR)** e **GitHub Actions**. Mesmo assim, quase tudo desta disciplina se transfere, porque os conceitos são os mesmos e só mudam os nomes:

| Conceito visto na disciplina (Azure DevOps) | Equivalente no GitHub Actions | Uso no FIAP Cloud Games |
|---|---|---|
| Pipeline YAML (`azure-pipelines.yml`) | Workflow (`.github/workflows/*.yml`) | Um workflow por microsserviço, ou um workflow com *matrix* e filtro `paths:` por pasta |
| `trigger` / `pr` | `on: push` / `on: pull_request` | CI em todo PR; CD só na `main` |
| Stages → jobs → steps | Jobs (com `needs:`) → steps | `build-test` → `image-scan-push` → `deploy` |
| Task (ex.: `UseDotNet@2`) | Action (ex.: `actions/setup-dotnet@v4`) | Setup do SDK .NET |
| Agent pool Microsoft-hosted (`vmImage: ubuntu-latest`) | Runner GitHub-hosted (`runs-on: ubuntu-latest`) | Padrão para todos os jobs |
| Agent self-hosted (Aula 3) | Self-hosted runner | Só se precisar acessar rede privada (ex.: cluster EKS com endpoint privado) |
| Variable groups / variáveis secretas / Key Vault | Secrets e Variables (repo/org/environment) + AWS Secrets Manager | Nenhum segredo no YAML ou no código |
| Service connection (Workload Identity Federation) | **OIDC** + `aws-actions/configure-aws-credentials` com `role-to-assume` | Acesso à AWS sem access keys de longa duração |
| Environments + Approvals (Aula 4) | Environments + *required reviewers* | Aprovação manual antes de produção |
| Branch control (Aula 4) | *Deployment branches and tags* do environment + branch protection/rulesets | Só a `main` faz deploy em produção |
| `condition: eq(variables['Build.SourceBranch'], ...)` | `if: github.ref == 'refs/heads/main'` | Pular deploy em PRs e outras branches |
| Exclusive lock | `concurrency:` | Evitar dois deploys simultâneos no mesmo ambiente |
| Required template | Reusable workflows (`workflow_call`) / composite actions | Um workflow-padrão reaproveitado pelas 4 APIs |
| `PublishPipelineArtifact` | `actions/upload-artifact` | Resultados de testes / relatório do scan |
| Estratégia `rolling`/`canary` do deployment job | Feita pelo próprio Kubernetes (`Deployment` com `RollingUpdate`) | `kubectl rollout status` como verificação |
| Dashboards (Aula 2) | Aba Actions, badges de status, Insights | Badge no README de cada serviço |
| Wiki/Markdown (Aula 2) | README / docs no repositório / GitHub Wiki | Documentar arquitetura, pipeline e como rodar localmente |

> **💡 Complemento:** esqueleto de workflow para um dos serviços (ex.: CatalogAPI), ilustrando os requisitos do desafio. Ajuste nomes, região, caminhos e fixe as versões das actions (de preferência por SHA do commit).
>
> ```yaml
> name: catalog-api-ci-cd
>
> on:
>   push:
>     branches: [main]
>     paths: ['src/CatalogAPI/**', '.github/workflows/catalog-api.yml']
>   pull_request:
>     paths: ['src/CatalogAPI/**']
>
> permissions:
>   contents: read
>   id-token: write          # necessário para OIDC com a AWS
>
> env:
>   AWS_REGION: us-east-1
>   ECR_REPOSITORY: fcg/catalog-api
>   IMAGE_TAG: ${{ github.sha }}
>
> jobs:
>   build-test:
>     runs-on: ubuntu-latest
>     steps:
>       - uses: actions/checkout@v4
>       - uses: actions/setup-dotnet@v4
>         with:
>           dotnet-version: '8.0.x'
>       - run: dotnet restore src/CatalogAPI
>       - run: dotnet build src/CatalogAPI -c Release --no-restore
>       - run: dotnet test tests/CatalogAPI.Tests -c Release --logger trx
>
>   image-scan-push:
>     needs: build-test
>     if: github.ref == 'refs/heads/main'
>     runs-on: ubuntu-latest
>     outputs:
>       image: ${{ steps.meta.outputs.image }}
>     steps:
>       - uses: actions/checkout@v4
>       - uses: aws-actions/configure-aws-credentials@v4
>         with:
>           role-to-assume: ${{ secrets.AWS_ROLE_ARN }}   # role IAM com trust policy OIDC do GitHub
>           aws-region: ${{ env.AWS_REGION }}
>       - id: ecr
>         uses: aws-actions/amazon-ecr-login@v2
>       - id: meta
>         run: echo "image=${{ steps.ecr.outputs.registry }}/${{ env.ECR_REPOSITORY }}:${{ env.IMAGE_TAG }}" >> "$GITHUB_OUTPUT"
>       - run: docker build -t ${{ steps.meta.outputs.image }} -f src/CatalogAPI/Dockerfile .
>       - name: Scan de vulnerabilidades (falha se houver HIGH/CRITICAL)
>         uses: aquasecurity/trivy-action@0.28.0
>         with:
>           image-ref: ${{ steps.meta.outputs.image }}
>           severity: HIGH,CRITICAL
>           exit-code: '1'
>           ignore-unfixed: true
>       - run: docker push ${{ steps.meta.outputs.image }}
>
>   deploy:
>     needs: image-scan-push
>     runs-on: ubuntu-latest
>     environment: production        # required reviewers + deployment branch = main
>     concurrency: deploy-catalog-production
>     steps:
>       - uses: aws-actions/configure-aws-credentials@v4
>         with:
>           role-to-assume: ${{ secrets.AWS_DEPLOY_ROLE_ARN }}
>           aws-region: ${{ env.AWS_REGION }}
>       - run: aws eks update-kubeconfig --name ${{ vars.EKS_CLUSTER_NAME }} --region ${{ env.AWS_REGION }}
>       - run: |
>           kubectl set image deployment/catalog-api catalog-api=${{ needs.image-scan-push.outputs.image }} -n fcg
>           kubectl rollout status deployment/catalog-api -n fcg --timeout=180s
> ```
>
> Observações:
> - **Tag da imagem**: use o SHA do commit (imutável e rastreável) em vez de `latest`; habilite *tag immutability* no repositório ECR. Isso é o *build once, deploy many* da Aula 3.
> - **Zero credenciais hardcoded**: a autenticação na AWS é por **OIDC** (sem `AWS_ACCESS_KEY_ID`/`AWS_SECRET_ACCESS_KEY` guardados); o ARN da role não é segredo, mas guardá-lo em *secrets/vars* evita espalhá-lo. Connection strings e chaves das APIs ficam no **AWS Secrets Manager** (ex.: via *External Secrets Operator* ou *Secrets Store CSI Driver* no EKS) — nunca em `appsettings.json` versionado ou no manifesto.
> - **Rolling update**: o `Deployment` deve declarar `strategy.type: RollingUpdate` (com `maxUnavailable`/`maxSurge`) e ter **readiness probe** (ex.: endpoint de health check do ASP.NET Core); sem readiness probe, o Kubernetes considera o pod pronto antes da API subir e o rolling update pode derrubar tráfego. `kubectl rollout undo` faz o rollback.
> - O acesso do role de deploy ao cluster EKS precisa ser concedido no próprio cluster (EKS *access entries* ou o `aws-auth` ConfigMap, em clusters mais antigos).
> - O scan também pode ser feito pelo próprio ECR (*scan on push*/Amazon Inspector), mas o scan no pipeline tem a vantagem de **bloquear** a publicação da imagem vulnerável.

**O que desta disciplina se aproveita mesmo usando AWS + GitHub Actions:**

1. **Modelo mental de pipeline** (Aulas 3 e 4): CI x CD, artefato imutável, stages/jobs/steps, dependências entre etapas — idêntico em qualquer ferramenta.
2. **Environments com aprovação e branch control** (Aula 4): a mesma ideia é configurada nos *Environments* do GitHub (required reviewers, deployment branches) para proteger produção.
3. **Condições por branch** (Aula 4): `if: github.ref == 'refs/heads/main'` cumpre o papel do `condition: eq(variables['Build.SourceBranch'], ...)`.
4. **Agentes/runners** (Aula 3): entender hosted x self-hosted ajuda a decidir se um runner na VPC é necessário (cluster privado) e quais os riscos de segurança.
5. **Gestão de segredos** (Aula 3): variable groups/Key Vault/service connections → GitHub Secrets/Environments + OIDC + AWS Secrets Manager. O princípio "nenhum segredo no YAML" é o mesmo requisito do desafio.
6. **Documentação em Markdown** (Aula 2): README de cada microsserviço, diagrama de arquitetura (Mermaid funciona no GitHub), checklist de PR e o relatório de entrega do Tech Challenge.
7. **Padronização** (Required template, Aula 4): um *reusable workflow* compartilhado pelas quatro APIs evita quatro pipelines divergentes.

> **💡 Complemento:** GitHub Actions x Azure Pipelines, em resumo. Ambos são maduros e equivalentes para o desafio. Pesam a favor do **GitHub Actions** o código já estar no GitHub, o marketplace enorme de actions (inclusive as oficiais da AWS) e a configuração em um só lugar. Pesam a favor do **Azure Pipelines** a integração com Boards/Test Plans, os checks avançados de environments (Business hours, Azure Monitor, REST API) e as *Required templates* como governança central. O Azure Pipelines também consegue construir código hospedado no GitHub e fazer deploy na AWS (via *AWS Toolkit for Azure DevOps*), então a escolha é de ecossistema, não de capacidade.

### Glossário da disciplina

| Termo | Definição curta |
|---|---|
| **Azure DevOps** | Plataforma da Microsoft com Boards, Repos, Pipelines, Test Plans e Artifacts. |
| **Organization** | Nível mais alto no Azure DevOps (`dev.azure.com/<org>`), que agrupa projetos, usuários e cobrança. |
| **Free Tier** | Nível gratuito da Azure: serviços grátis por 12 meses, serviços sempre grátis e crédito inicial. |
| **Pay-as-you-go** | Modelo de cobrança em que se paga apenas pelo que se consome. |
| **Dashboard** | Painel com widgets (builds, deploys, sprints, queries) para dar visibilidade ao projeto. |
| **Wiki** | Documentação do projeto em Markdown (project wiki ou code wiki publicada a partir de um repositório). |
| **Markdown** | Linguagem de marcação leve usada em wikis, READMEs e Pull Requests. |
| **CI** | Integração contínua: build e testes automáticos a cada mudança, gerando um artefato. |
| **CD** | Entrega/implantação contínua: promoção automática do artefato pelos ambientes. |
| **Pipeline** | Definição automatizada (YAML ou clássica) das etapas de CI/CD. |
| **Stage / Job / Step** | Níveis da pipeline: fase lógica / unidade executada em um agente / comando ou task individual. |
| **Task** | Passo pré-empacotado do Azure Pipelines (ex.: `UseDotNet@2`, `Docker@2`). |
| **Agent** | Máquina/software que executa os jobs da pipeline. |
| **Agent pool** | Conjunto de agentes; pode ser Microsoft-hosted ou self-hosted. |
| **Self-hosted agent** | Agente instalado em máquina própria (ex.: WSL, VM, servidor on-premises). |
| **vmImage** | Imagem da VM do agente hospedado pela Microsoft (ex.: `ubuntu-latest`). |
| **PAT** | *Personal Access Token*: token pessoal com escopo e validade, usado aqui para registrar o agente. |
| **Variable group** | Conjunto de variáveis (inclusive secretas ou ligadas ao Key Vault) compartilhado entre pipelines. |
| **Service connection** | Credencial gerenciada para a pipeline acessar serviços externos (Azure, registries, Kubernetes). |
| **Multistage pipeline** | Pipeline YAML com vários stages encadeados (build → dev → staging → produção). |
| **Environment** | Alvo de deploy no Azure Pipelines, com histórico de deployments e Approvals and checks. |
| **Deployment job** | Job (`- deployment:`) que implanta em um environment e respeita seus checks. |
| **Approvals and checks** | Regras que precisam ser satisfeitas antes de um stage usar um recurso protegido. |
| **Branch control** | Check que só permite deploy a partir de branches autorizadas. |
| **Exclusive lock** | Check que permite apenas um stage por vez usando o recurso. |
| **Required template** | Check que obriga a pipeline a estender templates YAML aprovados. |
| **Condition** | Expressão que decide se um stage/job/step roda (ex.: `eq(variables['Build.SourceBranch'], 'refs/heads/main')`). |
| **Skipped** | Status de um stage/job que não foi executado porque sua condição não foi atendida. |
