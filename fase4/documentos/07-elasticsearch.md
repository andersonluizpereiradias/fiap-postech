# 7. Elasticsearch

> **Disciplina de origem:** Pós-Tech FIAP — Arquitetura de Sistemas .NET — Fase 4 — Elasticsearch
>
> **Aulas:**
> 1. Aula 01 — Introdução ao Elasticsearch e Busca de Texto
> 2. Aula 02 — Configuração e Instalação
> 3. Aula 03 — Elasticsearch API e .NET
> 4. Aula 04 — Indexação de Documentos
> 5. Aula 05 — Pesquisa e Consultas Avançadas
>
> **Como ler este material:** o texto corrido de cada aula reproduz o conteúdo do PDF original, reorganizado em Markdown. Os blocos **💡 Complemento** são acréscimos de estudo (esclarecimentos, atualizações e boas práticas) e **não fazem parte do material da FIAP**.

---

## Aula 1 - Introdução ao Elasticsearch e Busca de Texto

### O que vem por aí?

Você já se perguntou como é possível encontrar exatamente o que procura em um vasto oceano de dados com apenas alguns cliques? A resposta reside no poderoso mundo do Elasticsearch. Neste capítulo introdutório, vamos desvendar a fascinante história dessa ferramenta que transformou a busca por texto em uma arte refinada e uma ciência precisa.

Imagine um mundo antes do Elasticsearch: a busca por informações era tediosa e imprecisa. Com o advento desta tecnologia revolucionária, tudo mudou. Vamos explorar como o Elasticsearch não apenas simplificou a maneira como acessamos informações mas também como ele evoluiu para se tornar um dos mecanismos de busca mais sofisticados e amplamente utilizados do mundo.

Desde suas humildes origens até se tornar uma ferramenta indispensável em diversas indústrias, esta jornada pelo Elasticsearch é uma história de inovação, desafios e triunfos.

Ao longo deste capítulo, você aprenderá sobre os princípios fundamentais do Elasticsearch, sua arquitetura única e as inúmeras maneiras pelas quais ele está moldando o futuro da busca por texto. Prepare-se para mergulhar nas profundezas dessa tecnologia transformadora e entender como ela se tornou um pilar essencial na era digital.

### Hands On

Neste momento da aula, vamos mergulhar na parte prática do Elasticsearch. Você terá a oportunidade de aplicar os conceitos discutidos até agora e criar um ambiente Elasticsearch funcional. Em seguida, aprenderemos como inserir dados e realizar consultas básicas.

Para começar, é importante configurar um ambiente de Elasticsearch. Isso é feito criando um contêiner com Elasticsearch usando Docker. Certifique-se de que o Docker esteja instalado em sua máquina antes de prosseguir.

Uma vez configurado o ambiente, poderemos inserir dados no Elasticsearch. Também usaremos comandos específicos para a inserção de informações em nosso ambiente.

Após essa inserção, aprenderemos como realizar consultas para verificar se os documentos foram inseridos corretamente e para buscar informações específicas no Elasticsearch.

Lembre-se: este Hands On é apenas o começo de sua jornada com o Elasticsearch.

> **💡 Complemento:** o PDF não traz os comandos do Hands On (eles ficam nas videoaulas). Um roteiro mínimo equivalente, para reproduzir localmente:
>
> ```bash
> # Sobe um nó único do Elasticsearch 8.x sem segurança (apenas para estudo local)
> docker run -d --name es01 -p 9200:9200 \
>   -e "discovery.type=single-node" \
>   -e "xpack.security.enabled=false" \
>   -e "ES_JAVA_OPTS=-Xms1g -Xmx1g" \
>   docker.elastic.co/elasticsearch/elasticsearch:8.15.0
>
> # Verifica se o nó respondeu
> curl http://localhost:9200
> ```
>
> ```http
> POST /pessoas/_doc/1
> Content-Type: application/json
>
> { "Nome": "João", "idade": 30 }
> ```
>
> ```http
> GET /pessoas/_search
> Content-Type: application/json
>
> { "query": { "match": { "Nome": "João" } } }
> ```
>
> A partir da versão 8, a segurança (TLS + usuário `elastic`) vem **habilitada por padrão**; desabilitá-la só é aceitável em ambiente local de estudo.

### Saiba mais

#### História e origem

O Elasticsearch é um mecanismo de busca e análise de dados em tempo real que tem sua origem e história relacionadas ao desenvolvimento de tecnologias de busca e indexação de informações. Sua história remonta ao início dos anos 2000, quando Shay Banon, um programador de software, começou a trabalhar em uma solução para melhorar a busca em seu próprio site.

Banon estava insatisfeito com as opções disponíveis na época para indexar e pesquisar conteúdo na web. Ele desejava criar uma ferramenta mais eficiente e flexível que permitisse buscar e analisar grandes volumes de dados em tempo real. Com essa visão em mente, ele começou a desenvolver o que mais tarde se tornaria o Elasticsearch.

A primeira versão pública desta ferramenta foi lançada em 2010, marcando o início de sua jornada como uma tecnologia de código aberto. O projeto rapidamente ganhou popularidade devido a sua facilidade de uso, escalabilidade e desempenho impressionante.

O Elasticsearch é construído sobre o **Apache Lucene**, uma biblioteca de código aberto para indexação e pesquisa de texto. O que diferencia o Elasticsearch é sua capacidade de fornecer uma camada de abstração amigável para pessoas desenvolvedoras, simplificando a criação de aplicativos que precisam de recursos de busca e análise em tempo real.

À medida que o Elasticsearch ganhou destaque, seu ecossistema se expandiu com o desenvolvimento de produtos adicionais pela Elastic, a empresa por trás da tecnologia. Isso inclui o **Kibana**, uma ferramenta de visualização de dados, o **Beats**, para coleta de dados, e o **Logstash**, para processamento de logs.

O Elasticsearch também encontrou uma ampla variedade de casos de uso em todo o mundo, desde buscas em sites e comércio eletrônico até análise de dados em tempo real e monitoramento de segurança. Sua capacidade de escalabilidade horizontal e flexibilidade fizeram dele uma escolha popular em empresas de todos os tamanhos e setores.

O Elasticsearch evoluiu continuamente, incorporando novos recursos, melhorias de desempenho e aprimoramentos de segurança. Atualmente, ele é uma das principais ferramentas de busca e análise de dados em tempo real do mundo, continuando a desempenhar um papel crucial na capacidade das organizações de extrair insights valiosos de seus dados e manter sistemas complexos sob observação constante.

> **💡 Complemento (atualização — licença e OpenSearch):** em 2021 (versão 7.11) a Elastic trocou a licença Apache 2.0 por SSPL/Elastic License. Em resposta, a AWS criou o **OpenSearch**, um *fork* do Elasticsearch **7.10.2** (e do Kibana 7.10.2, que virou OpenSearch Dashboards), mantido sob Apache 2.0 e hoje governado pela OpenSearch Software Foundation (Linux Foundation). Em 2024 a Elastic voltou a oferecer o Elasticsearch também sob AGPLv3. Os dois produtos compartilham a base (Lucene, Query DSL, API REST), mas divergem desde então em recursos, versões e clientes.

#### Por que o Elasticsearch não é um banco de dados tradicional

Embora o Elasticsearch seja uma ferramenta poderosa para buscar, analisar e indexar dados em tempo real, ele não é considerado um banco de dados tradicional e há boas razões para isso.

Ele foi projetado com foco na pesquisa e análise de texto, tornando-o ideal para tarefas como busca de texto completo, análise de logs, monitoramento de segurança e outros cenários em que a pesquisa eficiente é fundamental. No entanto, ele não foi projetado para ser usado como um banco de dados primário para armazenar dados críticos ou transacionais.

Aqui estão algumas razões pelas quais o Elasticsearch não deve ser usado como o armazenamento principal de dados de uma aplicação:

- **Modelagem de Dados Limitada:** o Elasticsearch é otimizado para estruturas de dados de documentos semiestruturados. Se sua aplicação requer relacionamentos complexos entre dados ou uma estrutura de dados altamente normalizada, ele pode não ser a melhor escolha. Bancos de dados relacionais ou NoSQL podem ser mais adequados para esses casos.
- **Escrita Assíncrona:** o Elasticsearch prioriza a velocidade de leitura e pesquisa em detrimento da gravação síncrona. Isso significa que, ao inserir dados nele, pode haver um pequeno atraso antes que esses dados estejam disponíveis para consulta. Isso não é adequado para cenários em que a consistência imediata é crucial.
- **Consumo de Recursos:** o Elasticsearch é conhecido por ser intensivo em recursos, especialmente em termos de CPU e memória. Se sua aplicação exige armazenamento e recuperação de grandes volumes de dados, o uso do Elasticsearch como principal método de armazenamento pode ser caro e ineficiente.
- **Backup e Recuperação:** o Elasticsearch não é a melhor escolha para backup e recuperação de dados de longo prazo. É mais adequado para casos em que os dados têm uma vida útil mais curta, como logs e métricas. Para backups de dados críticos, é melhor usar soluções de backup de banco de dados especializadas.
- **Conformidade com ACID:** o Elasticsearch não segue o modelo ACID (Atomicidade, Consistência, Isolamento, Durabilidade) que os bancos de dados tradicionais garantem. Isso pode ser um problema se sua aplicação requer transações complexas e garantias de consistência estrita.

O Elasticsearch é uma ferramenta valiosa para pesquisa e análise de dados em tempo real, mas não deve ser usado como a única fonte de armazenamento de dados em uma aplicação. Em vez disso, é aconselhável usar bancos de dados adequados para o armazenamento principal de dados, com o Elasticsearch complementando as funcionalidades de busca e análise. Essa abordagem garante que cada tecnologia seja usada em seu ponto forte, resultando em um sistema mais robusto e eficiente.

> **💡 Complemento (esclarecimento — "near real-time"):** o "pequeno atraso" citado em *Escrita Assíncrona* tem nome: o Elasticsearch é **near real-time (NRT)**. Um documento indexado só fica visível para buscas depois de um *refresh*, que por padrão ocorre a cada **1 segundo** (`index.refresh_interval`) em índices que estão recebendo buscas. A gravação em si é durável (vai para o *translog*), mas a visibilidade não é imediata. Um `GET /indice/_doc/{id}` é *realtime* e enxerga o documento antes do refresh; um `_search`, não. Em testes automatizados, use `?refresh=wait_for` na indexação para evitar falsos negativos — evite em produção com alto volume.

#### Conectando ao Elasticsearch com .NET

Existem várias formas de se conectar ao Elasticsearch, permitindo que pessoas desenvolvedoras e aplicativos interajam com esse mecanismo de busca e análise de dados em tempo real. Uma das maneiras mais populares é usando as bibliotecas e clientes específicos fornecidos pela Elastic, que simplificam a comunicação com ele.

Um exemplo de como você pode se conectar ao Elasticsearch usando o .NET Core é por meio do cliente oficial da Elastic, chamado **"Elasticsearch.Net"** e **"NEST"** (Elasticsearch DSL para .NET). Essas bibliotecas facilitam a integração de aplicativos .NET com o Elasticsearch.

Aqui está um exemplo simples de como você pode utilizar o .NET Core para se conectar ao Elasticsearch e realizar uma consulta:

```csharp
using System;
using Elasticsearch.Net;
using Nest;

class Program
{
    static void Main()
    {
        // Configuração básica do cliente Elasticsearch
        var settings = new ConnectionSettings(new Uri("http://localhost:9200"))
            .DefaultIndex("nome-do-indice"); // Substitua "nome-do-indice" pelo nome do seu índice

        var client = new ElasticClient(settings);

        // Exemplo de consulta
        var searchResponse = client.Search<Pessoa>(s => s
            .Query(q => q
                .Match(m => m
                    .Field(f => f.Nome)
                    .Query("João")
                )
            )
        );

        // Processamento dos resultados
        if (searchResponse.IsValid)
        {
            Console.WriteLine("Resultados encontrados:");
            foreach (var hit in searchResponse.Hits)
            {
                Console.WriteLine($"ID: {hit.Id}, Nome: {hit.Source.Nome}");
            }
        }
        else
        {
            Console.WriteLine($"Erro na consulta: {searchResponse.DebugInformation}");
        }
    }
}

public class Pessoa
{
    public string Nome { get; set; }
}
```

*Código-fonte 1 — Exemplo de código-fonte C# (Fonte: elaborado pelo autor, 2024).*

Nesse exemplo, primeiro configuramos o cliente Elasticsearch com as informações de conexão, como a URL do servidor Elasticsearch e o índice no qual desejamos realizar a consulta. Em seguida, realizamos uma consulta simples para encontrar documentos com o campo "Nome" igual a "João" e exibimos os resultados.

Lembre-se de que, para usar esse exemplo, você precisa ter a biblioteca Elasticsearch.Net e NEST instalada em seu projeto .NET Core. Além disso, simplesmente copiar e colar o código não garante que ele vá funcionar: é necessário entender o contexto e, se preciso, adaptar o código.

> **💡 Complemento (atualização — clientes .NET):**
>
> | Cenário | Pacote NuGet | Observação |
> |---|---|---|
> | Elasticsearch 7.x (legado) | `NEST` + `Elasticsearch.Net` | Usado na aula. **Obsoleto**: última linha é a 7.17; não recebe novos recursos. |
> | Elasticsearch 8.x / 9.x | `Elastic.Clients.Elasticsearch` | Cliente oficial atual. Classes `ElasticsearchClientSettings` e `ElasticsearchClient`; API majoritariamente assíncrona; respostas usam `IsValidResponse`. A API *fluent* mudou entre as versões 8 e 9 do cliente — confira a versão no NuGet. |
> | OpenSearch / Amazon OpenSearch Service | `OpenSearch.Client` (alto nível) + `OpenSearch.Net` (baixo nível) | *Fork* do NEST 7.x: a sintaxe é quase idêntica à da aula (`ConnectionSettings`, `OpenSearchClient`, `IsValid`). Para autenticação IAM na AWS, há o pacote `OpenSearch.Net.Auth.AwsSigV4`. |
>
> **Armadilha de compatibilidade:** o cliente da Elastic verifica o produto do servidor (*product check*, introduzido no NEST 7.14 e mantido no cliente 8+) e **recusa conexão com OpenSearch**. Do outro lado, o `OpenSearch.Client` não é testado contra Elasticsearch 8. Escolha o cliente conforme o motor de destino e, se quiser trocar de motor no futuro, isole o acesso atrás de uma interface própria (ex.: `ISearchService`).
>
> Observação sobre o exemplo: o campo é "igual a João" no sentido de *full-text* — `match` analisa o texto; para igualdade exata use `term` sobre um campo `keyword`. Note também que `Field(f => f.Nome)` é serializado em *camelCase* (`nome`) por padrão no NEST.

#### Casos de uso

O Elasticsearch oferece uma ampla gama de casos de uso em diversos setores e cenários. Seu poder reside na capacidade de indexar, buscar e analisar dados com rapidez e eficiência, tornando-o uma escolha valiosa para uma variedade de aplicações.

- **Busca em sites e e-commerce:** uma das aplicações mais comuns do Elasticsearch é a busca em sites e plataformas de comércio eletrônico. Ele permite que indivíduos encontrem produtos e informações de maneira eficaz, melhorando a experiência do usuário e impulsionando as conversões.
- **Análise de logs:** o Elasticsearch é amplamente utilizado na análise de logs, auxiliando empresas na detecção precoce de problemas, monitoramento de desempenho e resolução rápida de incidentes.
- **Segurança cibernética:** é uma ferramenta essencial para monitorar e detectar atividades suspeitas e ameaças em redes de computadores. Sua capacidade de análise em tempo real é fundamental para identificar potenciais violações de segurança.
- **Marketing e mídias sociais:** empresas e profissionais de marketing se beneficiam do Elasticsearch ao analisar grandes volumes de dados de mídias sociais. Essa análise fornece insights valiosos sobre tendências de mercado, sentimentos de consumidores e padrões de comportamento, informando estratégias de marketing e tomada de decisões.
- **Recomendações personalizadas:** em aplicativos que oferecem recomendações personalizadas, como serviços de streaming, o Elasticsearch é usado para filtrar e sugerir conteúdo com base nas preferências de usuários, melhorando a retenção e a satisfação do cliente.
- **Monitoramento de infraestrutura:** auxilia na identificação de gargalos e falhas em sistemas complexos.
- **Gerenciamento de documentos e conteúdo:** plataformas fazem uso do Elasticsearch para oferecer busca avançada e pesquisa de texto completo em documentos e arquivos.
- **Internet das Coisas (IoT):** coleta e analisa registros de sensores em tempo real, facilitando o monitoramento e a tomada de decisões baseadas em dados gerados por dispositivos IoT.
- **Desenvolvimento de aplicativos (APM):** usado para monitorar o desempenho em tempo real, rastrear solicitações, medir latência e analisar erros.
- **Catálogos de produtos:** em sites de comércio eletrônico e catálogos de produtos, permite a busca avançada em catálogos, facilitando a localização de produtos por meio de pesquisa textual avançada, filtros e classificações.

Esses exemplos demonstram a versatilidade do Elasticsearch e como ele pode ser aplicado em diversos cenários para melhorar a eficiência, proporcionar insights valiosos e aprimorar a experiência de usuário. Sua flexibilidade, escalabilidade e capacidade de lidar com dados em tempo real fazem dele uma escolha valiosa para organizações que procuram soluções avançadas de busca e análise de dados.

#### Arquitetura

A compreensão da arquitetura do Elasticsearch é fundamental para utilizar eficazmente essa poderosa ferramenta. Sua arquitetura é projetada para ser altamente escalável e distribuída, permitindo o processamento eficiente de grandes volumes de dados.

- **Clusters:** um cluster no Elasticsearch é uma coleção de um ou mais nós (servidores) que trabalham juntos para armazenar dados e fornecer recursos de indexação e pesquisa. Cada cluster é identificado por um nome único, o que evita que nós de clusters diferentes se conectem acidentalmente entre si.
- **Nós:** cada nó é um servidor individual que faz parte de um cluster. Cada nó tem um nome atribuído, que pode ser gerado automaticamente ou definido manualmente. Os nós podem desempenhar diferentes papéis dentro do cluster, incluindo:
  - **Nós Master:** responsáveis pelo gerenciamento do estado do cluster, incluindo a criação ou exclusão de índices e o rastreamento dos nós que fazem parte do cluster.
  - **Nós Data:** armazenam dados e executam operações relacionadas a dados, como buscas e agregações.
  - **Nós Ingest:** usados para pré-processar dados antes que sejam indexados.
  - **Nós de Machine Learning:** empregados para análises preditivas e detecção de anomalias.
- **Shards:** um shard é uma subdivisão de um índice no Elasticsearch. Cada índice pode ser dividido em múltiplos shards, permitindo a distribuição de dados por vários nós e, consequentemente, a distribuição da carga de trabalho. Existem dois tipos de shards: primários e réplicas.
  - **Shards Primários:** cada documento em um índice pertence a um único shard primário. Eles são responsáveis por armazenar e manipular os dados.
  - **Shards de Réplica:** são cópias dos shards primários e proporcionam redundância de dados. Isso ajuda na prevenção de perda de dados e permite consultas paralelas em diferentes nós.

A arquitetura do Elasticsearch permite que os clusters se expandam horizontalmente para lidar com cargas de trabalho crescentes, garantindo alta disponibilidade e recuperação de falhas. Além disso, a distribuição de shards permite a divisão dos dados em unidades gerenciáveis, melhorando o desempenho e a escalabilidade.

É importante compreender essa arquitetura ao projetar e implementar sistemas que utilizam o Elasticsearch, pois ela influencia a escalabilidade, a disponibilidade e o desempenho de suas operações de busca e análise de dados em tempo real.

> **💡 Complemento (esclarecimento — shards e roteamento):**
> - Cada shard é, internamente, um **índice Lucene** completo.
> - O documento vai para o shard primário calculado por `hash(_routing) % número_de_shards_primários` (por padrão, `_routing` = `_id`). Por isso **o número de shards primários não pode ser alterado** em um índice existente sem `_split`/`_shrink` ou reindexação; já o número de réplicas pode ser alterado a qualquer momento.
> - Uma réplica **nunca** é alocada no mesmo nó do seu primário. Em um cluster de nó único, as réplicas ficam *unassigned* e o *health* fica `yellow` — normal em ambiente local.
> - Desde a versão 7.0 o padrão é **1 shard primário e 1 réplica** por índice. Para um catálogo pequeno (milhares de jogos), 1 shard primário é o suficiente; *oversharding* é um erro comum.
> - Status de saúde: `GET /_cluster/health` → `green` (tudo alocado), `yellow` (réplicas não alocadas), `red` (algum primário indisponível).

### O que você viu nesta aula?

Nesta seção, chegamos ao ponto de processamento de aprendizagem, um checkpoint importante em nossa jornada de descoberta sobre o Elasticsearch: a história, a arquitetura e os diversos casos de uso dessa poderosa ferramenta.

As videoaulas relacionadas a este conteúdo oferecem uma oportunidade valiosa de ver esses conceitos em ação e aprender como aplicá-los em situações reais. A prática é fundamental para a aprendizagem eficaz: realize as atividades práticas e explore o Elasticsearch por conta própria. Este conteúdo está sempre à sua disposição para ser revisitado.

### Referências da aula

- ELASTIC.CO. *What is Elasticsearch?* 2024. <https://www.elastic.co/guide/en/elasticsearch/reference/current/elasticsearch-intro.html>
- ELASTIC.CO. *Quick Start.* 2024. <https://www.elastic.co/guide/en/elasticsearch/reference/current/getting-started.html>
- ELASTIC.CO. *Somos a Elastic.* 2024. <https://www.elastic.co/pt/about>
- Palavras-chave: .NET, Elasticsearch, Kibana, Data, Logs, Elastic, ELK, ELK Stack.

### Pontos-chave

- Elasticsearch é um motor de busca e análise distribuído, *open source* na origem (2010, Shay Banon), construído sobre o Apache Lucene.
- O ecossistema (Elastic Stack/ELK) inclui Kibana (visualização), Logstash (processamento) e Beats (coleta).
- Ele **não** substitui o banco de dados principal: não é ACID, é *near real-time*, consome muitos recursos e tem modelagem limitada para relacionamentos.
- O uso recomendado é complementar: o banco relacional é a fonte da verdade; o Elasticsearch atende busca e análise.
- Arquitetura: cluster → nós (master, data, ingest, ML) → índices → shards primários e réplicas.
- Réplicas dão redundância e paralelismo de leitura; shards distribuem os dados e a carga.
- O cliente .NET da aula (NEST/Elasticsearch.Net) está obsoleto; hoje usa-se `Elastic.Clients.Elasticsearch` (Elastic) ou `OpenSearch.Client` (OpenSearch).

---

## Aula 2 - Configuração e Instalação

### O que vem por aí?

Boas-vindas ao emocionante mundo do Elasticsearch, uma ferramenta poderosa que está revolucionando a forma como lidamos com grandes volumes de dados e buscas complexas.

Imagine-se como um(a) arquiteto(a) prestes a construir uma estrutura magnífica. Antes de erguer as paredes e decorar os interiores, é essencial preparar o terreno e estabelecer uma base sólida. Esse é o papel da configuração e instalação do Elasticsearch: ser o alicerce sobre o qual todas as suas operações de busca e análise de dados serão construídas.

Nesta aula, você será guiado(a) passo a passo pelo processo de instalação e configuração do Elasticsearch. Mas, mais do que simplesmente seguir instruções, você vai entender a importância de cada etapa no contexto maior do gerenciamento de dados. O Elasticsearch não é apenas uma ferramenta; é um portal para um mundo em que a informação é processada com velocidade e precisão inigualáveis.

Ao se aventurar por esta aula, você aprenderá a instalar o Elasticsearch e também configurá-lo de maneira eficiente para atender às suas necessidades específicas. Este conhecimento é crucial, pois uma configuração inadequada pode levar a desafios operacionais no futuro. Assim como um(a) piloto(a) precisa conhecer todos os instrumentos de sua aeronave, você, como usuário(a) do Elasticsearch, deve se familiarizar com todos os aspectos de sua configuração e instalação.

### Hands On

Neste segmento do curso, exploraremos de forma interativa a configuração e a instalação do Elasticsearch. Através de uma série de exposições práticas, você aprenderá sobre sua flexibilidade e potência. Cobriremos aspectos essenciais, desde a instalação básica até configurações avançadas, e como integrá-lo com ferramentas como **Kibana** para análise de dados, **Filebeat** para coleta de logs e **Logstash** para processamento de dados. Estes conteúdos são apresentados de maneira didática e aplicada, proporcionando uma experiência de aprendizado rica e envolvente.

Este guia é o seu primeiro passo em direção à maestria no Elasticsearch. Ao final desta aula, você terá mais do que habilidades técnicas; terá uma compreensão clara de como uma configuração bem executada é fundamental para o sucesso de suas operações de busca e análise de dados. Prepare-se para embarcar nesta jornada transformadora, em que cada configuração é uma peça vital no grande quebra-cabeça do gerenciamento de dados moderno.

> **💡 Complemento:** o PDF não inclui o `docker-compose` usado nas videoaulas. Um exemplo mínimo de Elasticsearch + Kibana para desenvolvimento local (segurança desabilitada — **nunca** em produção):
>
> ```yaml
> services:
>   elasticsearch:
>     image: docker.elastic.co/elasticsearch/elasticsearch:8.15.0
>     container_name: elasticsearch
>     environment:
>       - discovery.type=single-node
>       - xpack.security.enabled=false
>       - ES_JAVA_OPTS=-Xms1g -Xmx1g
>     ports:
>       - "9200:9200"
>     volumes:
>       - esdata:/usr/share/elasticsearch/data
>
>   kibana:
>     image: docker.elastic.co/kibana/kibana:8.15.0
>     container_name: kibana
>     environment:
>       - ELASTICSEARCH_HOSTS=http://elasticsearch:9200
>     ports:
>       - "5601:5601"
>     depends_on:
>       - elasticsearch
>
> volumes:
>   esdata:
> ```
>
> Equivalente com OpenSearch (útil para simular o Amazon OpenSearch Service localmente):
>
> ```yaml
> services:
>   opensearch:
>     image: opensearchproject/opensearch:2.17.0
>     environment:
>       - discovery.type=single-node
>       - DISABLE_SECURITY_PLUGIN=true
>       - OPENSEARCH_JAVA_OPTS=-Xms1g -Xmx1g
>     ports:
>       - "9200:9200"
>
>   opensearch-dashboards:
>     image: opensearchproject/opensearch-dashboards:2.17.0
>     environment:
>       - OPENSEARCH_HOSTS=["http://opensearch:9200"]
>       - DISABLE_SECURITY_DASHBOARDS_PLUGIN=true
>     ports:
>       - "5601:5601"
>     depends_on:
>       - opensearch
> ```
>
> Armadilhas comuns: (1) no Linux/WSL2, o contêiner pode falhar com `max virtual memory areas vm.max_map_count [65530] is too low` — ajuste com `sysctl -w vm.max_map_count=262144`; (2) use **a mesma versão** para Elasticsearch e Kibana; (3) o *Dev Tools* do Kibana (`http://localhost:5601/app/dev_tools#/console`) é a forma mais prática de testar as queries desta apostila.

### Saiba mais

#### Técnicas avançadas de configuração (`elasticsearch.yml`)

Durante as aulas vimos algumas técnicas de configuração que podem ser feitas no arquivo `elasticsearch.yml`, mas temos também algumas técnicas avançadas que precisamos ter em mente ao configurar nosso cluster com Elasticsearch. As "Técnicas Avançadas de Configuração" para o Elasticsearch se concentram em otimizar o arquivo `elasticsearch.yml`, que é crucial para o desempenho e a escalabilidade do sistema. Esse arquivo contém configurações essenciais que impactam como o Elasticsearch opera em diferentes ambientes. Algumas áreas-chave incluem:

- **Escalabilidade:** configurações para gerenciar o crescimento de dados e tráfego, incluindo ajustes em shards e réplicas.
- **Ajuste de Desempenho:** ajustes em cache, tamanhos de buffer e parâmetros de indexação para melhorar a velocidade de pesquisa e indexação.
- **Gestão de Recursos:** configurações que otimizam o uso de memória e CPU, essenciais em ambientes de produção de grande escala.

Essas técnicas avançadas exigem um entendimento profundo das necessidades específicas do seu ambiente e dos princípios operacionais do Elasticsearch. A otimização destas configurações pode levar a um aumento significativo na eficiência e desempenho do sistema.

Alguns exemplos de técnicas avançadas de configuração para o Elasticsearch incluem:

- **Ajuste de Shard e Réplica:** para balancear carga e melhorar a resiliência, você pode ajustar o número de shards e réplicas. Por exemplo: aumentar o número de réplicas pode melhorar a tolerância a falhas e a velocidade de leitura.
- **Configuração de Memória Heap:** definir adequadamente o tamanho da memória heap do Elasticsearch é crucial. Uma configuração muito baixa pode levar a problemas de desempenho, enquanto um valor muito alto pode causar problemas de coleta de lixo no Java.
- **Thread Pools:** o Elasticsearch usa diferentes tipos de thread pools para operações como pesquisa, indexação etc. Ajustar o tamanho e o tipo desses pools conforme a carga de trabalho pode melhorar significativamente o desempenho.
- **Cache de Nós e Buffer Sizes:** ajustar o tamanho do cache de filtro e os tamanhos dos buffers de indexação pode ajudar a acelerar as operações de pesquisa e reduzir o tempo de resposta. *(No PDF consta "Cache de Nóveis"; provável erro de digitação.)*

Essas são apenas algumas das muitas opções de configuração que você pode ajustar para otimizar o desempenho do Elasticsearch. É importante testar essas configurações em um ambiente de teste antes de aplicá-las em produção.

> **💡 Complemento (onde cada configuração mora):**
> - **Heap** não fica no `elasticsearch.yml`, e sim em `jvm.options` / `jvm.options.d/*.options` (`-Xms`/`-Xmx`, sempre iguais) ou na variável `ES_JAVA_OPTS`. Regra prática: no máximo **50% da RAM** do host (o restante fica para o *filesystem cache*, que o Lucene usa intensamente) e abaixo de ~31 GB para manter *compressed oops*. Nas versões recentes, o Elasticsearch já dimensiona o heap automaticamente se você não definir.
> - **Shards e réplicas** são configurações **do índice** (`settings` na criação do índice ou *index templates*), não do `elasticsearch.yml`.
> - Exemplos de configurações de nó que vão no `elasticsearch.yml`: `cluster.name`, `node.name`, `node.roles`, `network.host`, `discovery.seed_hosts`, `cluster.initial_master_nodes`, `path.data`, `indices.memory.index_buffer_size`, `indices.queries.cache.size`.
> - Mexer em *thread pools* raramente é necessário; o padrão é bem calibrado e ajustes errados costumam piorar o desempenho. Prefira escalar nós ou otimizar queries antes.
> - Em serviços gerenciados (Amazon OpenSearch Service, Elastic Cloud) você **não edita** o `elasticsearch.yml`: configura tamanho/quantidade de nós, armazenamento e políticas pelo console/API do provedor.

#### Gerenciamento e escalabilidade de clusters

Outro ponto importante que precisamos conhecer é o gerenciamento e a escalabilidade de clusters no Elasticsearch, fundamentais para pessoas desenvolvedoras de software que trabalham com grandes volumes de dados e buscam alto desempenho.

Na prática diária, uma pessoa desenvolvedora pode se deparar com desafios como a necessidade de processar e analisar rapidamente grandes conjuntos de dados, provenientes de logs de aplicativos, sistemas de monitoramento ou análises de tráfego web. Para lidar com isso, é essencial ter um cluster Elasticsearch bem gerenciado, que possa escalar de acordo com a demanda.

Por exemplo: se uma pessoa desenvolvedora está trabalhando em um sistema de e-commerce que registra milhões de interações do usuário diariamente, ela precisará de um cluster Elasticsearch que possa escalar para lidar com o influxo de dados. Isso envolve não apenas o equilíbrio de carga entre os nós, garantindo que nenhum nó seja sobrecarregado, mas também o monitoramento contínuo da saúde do cluster para detectar e resolver rapidamente quaisquer problemas.

A habilidade de ajustar dinamicamente os recursos e balancear a carga entre diferentes tipos de nós (como mestre, dados e ingest) é crucial. Por exemplo: em períodos de alta demanda, como durante uma grande promoção ou evento, a pessoa desenvolvedora pode precisar aumentar temporariamente os recursos ou adicionar mais nós ao cluster para manter a performance.

Além disso, o monitoramento constante do cluster é essencial para garantir a estabilidade e a eficiência. Ferramentas como Kibana podem ser usadas para visualizar métricas de desempenho, identificar gargalos e agir proativamente para resolver problemas antes que eles impactem usuários finais.

> **💡 Complemento (boa prática — quórum de masters):** em produção, use **3 nós elegíveis a master** (número ímpar) para evitar *split brain* e manter quórum se um nó cair. Em serviços gerenciados, isso corresponde a habilitar *dedicated master nodes* (Amazon OpenSearch Service) ou escolher uma topologia com múltiplas zonas (Elastic Cloud).

#### Segurança

Contudo, não podemos nos esquecer da segurança do nosso cluster. Melhorar a segurança no Elasticsearch é uma tarefa crucial para a pessoa desenvolvedora, visando proteger os dados contra acessos indevidos e vazamentos.

- **HTTPS:** implementar o HTTPS é o primeiro passo, assegurando que os dados transmitidos estejam criptografados e seguros.
- **Autenticação de usuários:** outra prática importante, frequentemente realizada através de sistemas externos de gerenciamento de identidade, garantindo que somente usuários autorizados possam acessar o Elasticsearch.
- **Controle de acesso baseado em funções (RBAC):** permite definir permissões específicas para diferentes usuários ou grupos, restringindo o acesso apenas ao necessário para cada função.
- **Criptografia de dados em repouso:** protege as informações armazenadas de acessos não autorizados.

Estas medidas são fundamentais para manter a integridade e a confidencialidade dos dados, especialmente em ambientes que demandam alta segurança.

> **💡 Complemento (segurança na prática para uma API .NET):**
> - Nunca exponha o cluster diretamente à internet nem ao *frontend*; somente o *backend* (ex.: CatalogAPI) deve falar com ele.
> - Prefira **API Keys** (Elastic) ou **IAM/SigV4** (Amazon OpenSearch Service) a usuário/senha fixos; guarde credenciais em um *secret store* (AWS Secrets Manager, Azure Key Vault, *user-secrets* em dev), nunca no `appsettings.json` versionado.
> - Conceda ao serviço o **mínimo privilégio**: leitura/escrita apenas no índice (ou alias) que ele usa.
> - No Amazon OpenSearch Service, prefira domínio dentro de **VPC**, *encryption at rest*, *node-to-node encryption* e *fine-grained access control*.

#### Integração com outras ferramentas (Elastic Stack)

É importante também termos a ciência de que o Elasticsearch não trabalha sozinho: integrar o Elasticsearch com outras ferramentas, como Kibana, Logstash e Beats, é como montar um quebra-cabeça em que cada peça tem um papel único e, juntas, criam uma imagem completa.

- **Logstash:** imagine uma pessoa desenvolvedora usando o Logstash para coletar e processar dados de diversas fontes, transformando-os em um formato adequado antes de enviá-los para o Elasticsearch.
- **Kibana:** esses dados, uma vez armazenados, são visualizados no Kibana, em que se pode criar dashboards intuitivos e realizar análises profundas.
- **Beats:** atua como os olhos e ouvidos em diferentes servidores, coletando informações vitais e enviando-as diretamente para o Elasticsearch.

Essa integração transforma o fluxo de trabalho em um processo coeso e eficiente, no qual os dados são coletados, analisados e visualizados de forma integrada, permitindo uma visão completa do sistema.

> **💡 Complemento:** Beats é uma família de agentes leves — **Filebeat** (arquivos de log), **Metricbeat** (métricas de sistema/serviços), Packetbeat, Heartbeat etc. Nas versões recentes, a Elastic incentiva o **Elastic Agent** (agente unificado gerenciado pelo Fleet) e a ingestão via **OpenTelemetry**. No mundo OpenSearch, os equivalentes são **Data Prepper** e o **OpenSearch Dashboards**.

#### Otimização de performance

Após termos todas as partes do quebra-cabeça funcionando, precisamos otimizar a performance. Esse é um processo multifacetado e essencial para pessoas desenvolvedoras que lidam com grandes volumes de dados.

1. **Otimização das consultas:** inicialmente, a otimização das consultas é crucial. Isso envolve entender como as consultas são processadas e como utilizar as capacidades de busca do Elasticsearch de forma eficiente. Por exemplo: utilizar consultas bem estruturadas, evitar termos desnecessários e utilizar filtros adequados pode reduzir drasticamente o tempo de resposta.
2. **Gerenciamento eficaz de índices:** em segundo lugar, o gerenciamento eficaz de índices é vital. Índices bem projetados e mantidos garantem um desempenho otimizado. Isso inclui a escolha correta do número de shards e réplicas, o balanceamento de carga entre eles e a limpeza regular de índices antigos ou não utilizados. Técnicas como o uso de índices rolantes (*rollover*) em aplicações de logs podem ser muito benéficas.
3. **Compreender o motor Lucene:** por fim, compreender o motor Lucene subjacente é um aspecto fundamental. Lucene é a biblioteca de busca por trás do Elasticsearch e entender seu funcionamento pode ajudar na otimização de índices e consultas. Por exemplo: o ajuste fino do uso de caches de Lucene e a compreensão de como as operações de leitura e escrita são realizadas podem levar a melhorias significativas no desempenho de busca e indexação.

Esses aspectos combinados podem ter um impacto substancial no desempenho geral do Elasticsearch, tornando-o uma ferramenta mais poderosa para desenvolvedores(as) em ambientes de dados intensivos.

> **💡 Complemento (como o Lucene grava):** o Lucene escreve dados em **segmentos imutáveis**. Uma atualização de documento é, na verdade, *marcar o antigo como deletado + gravar um novo*; os segmentos são periodicamente fundidos (*merge*), quando os deletados são removidos de fato. Consequências práticas: atualizações frequentes do mesmo documento custam caro; cargas massivas ficam mais rápidas com `refresh_interval` maior (ou `-1` durante a carga) e com a **Bulk API**. Para índices de logs, use **ILM** (Elastic) ou **ISM** (OpenSearch) para *rollover* e expurgo automáticos.

#### Casos de uso reais

No mundo real, o Elasticsearch é utilizado em diversos setores e para variados casos de uso, proporcionando soluções eficazes para problemas complexos de dados.

- **E-commerce:** empresas utilizam o Elasticsearch para melhorar a experiência de busca e recomendação de produtos para seus clientes.
- **Saúde:** é aplicado para analisar e cruzar grandes volumes de dados médicos e de pacientes, agilizando diagnósticos e pesquisas.
- **Streaming:** em serviços como o Spotify, o Elasticsearch é usado para personalizar recomendações musicais e gerenciar vastas bibliotecas de conteúdo.
- **Mídias sociais:** em plataformas como o LinkedIn, ele é empregado para otimizar a busca e a análise de conexões entre usuários.

Esses exemplos mostram como o Elasticsearch se adapta a diferentes necessidades e contextos, oferecendo soluções de dados escaláveis e eficientes.

#### Solução de problemas e manutenção

Mas em meio a tantas condições de uso, temos que ficar atentos(as) às manutenções e à solução de problemas. Na solução de problemas e manutenção do Elasticsearch, a pessoa desenvolvedora enfrenta desafios como performance degradada, falhas de nós e problemas de indexação. Para resolver esses problemas, ela precisa monitorar constantemente o cluster, utilizando ferramentas como o Elastic Stack. Por exemplo: a identificação de gargalos de performance pode ser resolvida reconfigurando shards ou ajustando as configurações de cache.

Quanto à manutenção:

- **Backups regulares** são fundamentais para a recuperação de dados em caso de falhas. Estratégias de **snapshot e restore** são comumente utilizadas.
- **Limpeza periódica de índices antigos** ajuda a manter o cluster em um estado saudável e eficiente.
- **Manter o software atualizado e aplicar patches de segurança** são práticas essenciais para garantir a estabilidade e a segurança do cluster a longo prazo.

A adesão a essas práticas de manutenção preventiva e proativa ajuda a minimizar interrupções e garante que o sistema permaneça resiliente e confiável.

> **💡 Complemento (comandos úteis de diagnóstico):**
>
> ```http
> GET /_cluster/health
> GET /_cat/nodes?v
> GET /_cat/indices?v
> GET /_cat/shards?v
> GET /_cluster/allocation/explain
> ```
>
> `allocation/explain` responde "por que este shard não foi alocado?" — o primeiro passo quando o cluster fica `yellow`/`red`.

#### Síntese

Com isso, entendemos diversos aspectos do Elasticsearch, desde técnicas avançadas de configuração, gerenciamento e escalabilidade de clusters até melhorias de segurança e integração com outras ferramentas. Discutimos também a otimização de performance, a importância da solução de problemas e manutenção e exploramos casos de uso reais.

Tudo isso evidencia a versatilidade e a potência do Elasticsearch em diferentes cenários, destacando sua relevância no mundo do desenvolvimento de software e na gestão de grandes volumes de dados. As práticas e estratégias discutidas são essenciais para maximizar o potencial do Elasticsearch, garantindo sistemas eficientes, seguros e escaláveis.

### O que você viu nesta aula?

Nesta aula, exploramos o Elasticsearch, cobrindo desde configurações avançadas e gerenciamento de clusters até integração com outras ferramentas e otimização de desempenho. Discutimos a importância de práticas eficientes de segurança e manutenção, destacando casos de uso em diferentes indústrias.

Essa exploração ressalta a versatilidade do Elasticsearch em ambientes de desenvolvimento de software, enfatizando sua capacidade de gerenciar grandes volumes de dados e sua aplicabilidade em cenários complexos. A aula oferece uma base sólida para compreender e aplicar as funcionalidades do Elasticsearch de forma eficaz.

### Referências da aula

- MITCHELL, E. *Getting started with the Elastic Stack and Docker Compose: Part 2.* 2023. <https://www.elastic.co/pt/blog/getting-started-with-the-elastic-stack-and-docker-compose-part-2>
- MITCHELL, E. *Introdução ao Elastic Stack e ao Docker Compose: parte 1.* 2023. <https://www.elastic.co/pt/blog/getting-started-with-the-elastic-stack-and-docker-compose>
- SHETTI, B. *Best practices for instrumenting OpenTelemetry.* 2023. <https://www.elastic.co/pt/blog/best-practices-instrumenting-opentelemetry>
- Palavras-chave: Elasticsearch, Kibana, Filebeat, Metricbeat.

### Pontos-chave

- O `elasticsearch.yml` concentra configurações de nó/cluster; shards e réplicas são configurações de índice; heap fica em `jvm.options`/`ES_JAVA_OPTS`.
- Heap mal dimensionado causa lentidão (pouco) ou pausas de GC (muito); regra prática: ≤ 50% da RAM.
- Escalar = adicionar nós e balancear papéis (master, data, ingest); monitorar a saúde continuamente (Kibana, `_cluster/health`).
- Segurança: HTTPS, autenticação, RBAC e criptografia em repouso — habilitados por padrão desde a 8.x.
- Elastic Stack: Logstash/Beats coletam e processam, Elasticsearch armazena e busca, Kibana visualiza.
- Performance depende de queries bem escritas (filtros), índices bem dimensionados e entendimento do Lucene (segmentos, caches).
- Manutenção: snapshots/restore, limpeza de índices antigos (ILM/ISM) e atualização de versões.

---

## Aula 3 - Elasticsearch API e .NET

### O que vem por aí?

Nesta aula você aprenderá a criar dois microsserviços para corte de *livestream* utilizando a integração do Elasticsearch para registrar cada etapa do processo de corte de vídeo.

Essa abordagem prática permitirá não só entender a teoria como também aplicá-la a um contexto real, em que cada ação no corte do vídeo é meticulosamente logada e analisada.

Isso proporcionará uma experiência valiosa no que diz respeito a como lidar com dados em tempo real e como eles podem ser utilizados para melhorar processos e fluxos de trabalho.

### Hands On

Durante essa aula vamos construir dois microsserviços:

1. **Microsserviço de requisição de corte:** lida com o recebimento de requisições HTTP para cortar vídeos ao vivo. Ao receber uma solicitação, esse microsserviço processa o pedido e o encaminha para uma fila do **RabbitMQ**, uma etapa crucial para gerenciar as tarefas de corte de forma assíncrona e eficiente. Após o envio para a fila, ele registra a ação em um log enviado ao Elasticsearch através da sua API. Isso permite o monitoramento e a análise efetiva de cada etapa do processo.
2. **Microsserviço processador:** desempenha um papel complementar, sendo responsável por escutar a fila do RabbitMQ. Ao receber uma mensagem, ele executa a união dos segmentos de vídeo utilizando a biblioteca **FFmpeg**, uma ferramenta poderosa para processamento de vídeo. Posteriormente, realiza o corte do vídeo conforme os tempos especificados na requisição original. Finalmente, o vídeo cortado é salvo em um diretório especificado.

Este fluxo de trabalho permite uma abordagem modular e eficiente para a edição de vídeos ao vivo, garantindo que cada etapa seja processada e registrada adequadamente, resultando em uma solução de software robusta e confiável para essa tarefa específica.

> **💡 Complemento:** o código dos microsserviços está nas videoaulas, não no PDF. Para **logs** em .NET, o caminho mais comum não é chamar a API do Elasticsearch "na mão", e sim usar o Serilog com um *sink* — `Elastic.Serilog.Sinks` (sucessor oficial do antigo `Serilog.Sinks.Elasticsearch`) ou `Serilog.Sinks.OpenSearch` — ou exportar via OpenTelemetry. Isso dá *buffering*, envio em lote (*bulk*) e tolerância a falhas sem bloquear a requisição. Lembre-se de incluir um **correlation id** (ex.: o id da solicitação de corte) em todos os logs dos dois serviços, para rastrear o fluxo HTTP → RabbitMQ → FFmpeg ponta a ponta no Kibana.

### Saiba mais

#### O que é a Elasticsearch API

O Elasticsearch API é a interface que permite a desenvolvedores(as) interagir com o Elasticsearch para realizar várias operações, como indexação, consulta e análise de dados. Aqui estão algumas das principais funcionalidades do Elasticsearch API e como ele ajuda essas pessoas:

- **Indexação de Dados:** o Elasticsearch API permite que especialistas em desenvolvimento indexem (armazenem) dados em um formato estruturado, tornando-os pesquisáveis e acessíveis. Ele suporta a indexação de uma ampla variedade de tipos de dados, desde texto simples até números, datas e objetos JSON complexos.
- **Pesquisa de Dados:** o Elasticsearch oferece uma poderosa capacidade de pesquisa textual e analítica. Profissionais de desenvolvimento podem realizar consultas complexas, como pesquisa por palavra-chave, pesquisa de texto completo, pesquisa de correspondência parcial, pesquisa geoespacial, agregações e filtragem.
- **Escalabilidade e Distribuição:** o Elasticsearch é altamente escalável e distribuído, o que permite lidar com grandes volumes de dados e consultas de forma eficiente. Ele pode ser configurado em um cluster, distribuindo os dados e as consultas em vários nós para melhorar o desempenho e a disponibilidade.
- **Facilidade de Uso:** o Elasticsearch API é relativamente fácil de usar e oferece uma variedade de linguagens de consulta, como JSON ou DSL (*Domain Specific Language*) baseada em JSON. Os resultados das consultas podem ser facilmente formatados e personalizados para atender às necessidades do aplicativo.
- **Recursos Avançados:** o Elasticsearch inclui recursos avançados, como suporte a análise de texto em várias línguas, suporte a análise de relevância, autenticação e autorização, monitoramento e alertas.
- **Integração:** o Elasticsearch pode ser integrado com muitas outras ferramentas e tecnologias, como Kibana (para visualização e análise de dados), Logstash (para coleta e processamento de dados) e Beats (para coleta de dados de diferentes fontes), entre outros.
- **Ecossistema:** o Elasticsearch faz parte do Elastic Stack, que inclui várias ferramentas e produtos para lidar com logs, métricas, segurança e muito mais.

No geral, o Elasticsearch API é uma ferramenta poderosa para especialistas em desenvolvimento que precisam indexar, pesquisar e analisar grandes volumes de dados de forma eficiente e escalável. Ele é amplamente utilizado em uma variedade de aplicativos, incluindo pesquisa na web, análise de registros (*log analysis*), monitoramento de sistemas, análise de segurança e muito mais. A capacidade de consulta flexível e os recursos avançados tornam o Elasticsearch uma escolha popular para lidar com dados não estruturados e semiestruturados em muitos cenários de desenvolvimento de software.

> **💡 Complemento (mapa rápido da API REST):**
>
> | Operação | Endpoint |
> |---|---|
> | Criar índice (com settings/mappings) | `PUT /{indice}` |
> | Ver mapping | `GET /{indice}/_mapping` |
> | Indexar com id definido (cria ou substitui) | `PUT /{indice}/_doc/{id}` |
> | Indexar com id gerado | `POST /{indice}/_doc` |
> | Criar somente se não existir | `PUT /{indice}/_create/{id}` |
> | Ler por id | `GET /{indice}/_doc/{id}` |
> | Atualização parcial | `POST /{indice}/_update/{id}` |
> | Excluir | `DELETE /{indice}/_doc/{id}` |
> | Operações em lote | `POST /_bulk` (NDJSON) |
> | Buscar | `GET/POST /{indice}/_search` |
> | Contar | `GET /{indice}/_count` |
> | Testar analyzer | `POST /{indice}/_analyze` |
> | Reindexar | `POST /_reindex` |
> | Aliases | `POST /_aliases` |
>
> Além da Query DSL, existem linguagens adicionais: no Elasticsearch, **ES|QL** (linguagem com *pipes*, GA na 8.14) e SQL; no OpenSearch, **PPL** e SQL. Para busca *full-text* em uma API, a Query DSL continua sendo a opção principal.

#### Indexando dados a partir de um serviço .NET

Quando você estiver trabalhando em um serviço construído em .NET e precisar indexar dados usando o Elasticsearch API, existem alguns passos essenciais que você deve seguir:

1. **Ter o Elasticsearch instalado e funcionando.** Você vai precisar das informações de conexão, como URL do Elasticsearch e credenciais, se a autenticação estiver habilitada.
2. **Integrar uma biblioteca cliente Elasticsearch para .NET**, como o "Elasticsearch.Net" ou "NEST". Essas bibliotecas facilitam muito a comunicação com o Elasticsearch e fornecem classes e métodos para tornar a interação com o Elasticsearch API mais simples.
3. **Criar um índice.** Antes de indexar seus dados, você precisará criar um índice no Elasticsearch. Pense no índice como algo semelhante a uma tabela de banco de dados em que você pode armazenar um conjunto de documentos relacionados. Certifique-se de configurar o **mapeamento de campos** para especificar como os diferentes tipos de dados devem ser tratados. O Elasticsearch suporta diversos tipos de campos, como texto, números, datas e geoespaciais.
4. **Indexar os documentos.** Depois de preparar o índice, você pode começar a indexar seus documentos. Os dados são representados como documentos JSON, em que cada um corresponde a um registro ou item que você deseja armazenar e pesquisar. Use o cliente Elasticsearch .NET para criar, atualizar, recuperar e excluir documentos conforme necessário.
5. **Consultar.** Após a indexação, você pode realizar consultas para recuperar dados do Elasticsearch. O Elasticsearch API oferece muitas opções de consulta para atender às suas necessidades de pesquisa e o cliente Elasticsearch .NET também ajuda a recuperar e manipular os resultados das consultas. Você pode analisar, filtrar, paginar e formatar os resultados de acordo com os requisitos do seu aplicativo.
6. **Otimizar.** À medida que seus dados crescem, é importante considerar a otimização de desempenho, como a configuração adequada de índices com shards e réplicas, bem como a criação de consultas eficientes para obter tempos de resposta mais rápidos.
7. **Monitorar e proteger.** Por fim, não esqueça de monitorar o desempenho e a saúde do seu cluster Elasticsearch e de aplicar políticas de segurança adequadas para proteger seus dados. Certifique-se de que seu serviço .NET esteja configurado para autenticar-se corretamente com o Elasticsearch, se necessário.

> **💡 Complemento (atualização — passo 2 e boas práticas no .NET):**
> - Em projetos novos contra Elasticsearch 8/9, use `Elastic.Clients.Elasticsearch`; contra OpenSearch/Amazon OpenSearch, `OpenSearch.Client`. NEST/Elasticsearch.Net só para manter sistemas legados 7.x.
> - Registre o cliente como **singleton** no DI (`builder.Services.AddSingleton(...)`): ele é *thread-safe* e mantém o *pool* de conexões; criar um cliente por requisição desperdiça conexões.
> - "Índice ≈ tabela" é uma analogia útil, mas desde a 7.0 os *mapping types* foram removidos: **um índice = um tipo de documento**. Não misture entidades diferentes no mesmo índice.
> - Crie o índice com **mapping explícito** (ver Aula 4) na inicialização da aplicação ou em um *migration job*, de forma idempotente (verificar se existe antes de criar).

#### Consultando dados

Depois de ter indexado seus dados no Elasticsearch, a próxima etapa é recuperar informações relevantes através de consultas. O Elasticsearch API oferece uma ampla variedade de opções de consulta que podem ser ajustadas para atender às necessidades específicas da sua pesquisa.

Imagine que você deseja buscar informações em um grande conjunto de documentos indexados. O Elasticsearch permite realizar consultas de correspondência exata, pesquisas de texto completo, correspondência parcial (como um motor de busca), filtragem por critérios específicos e até mesmo agregações para obter resumos ou estatísticas sobre os dados.

Você pode usar consultas simples, como correspondência de termos (`match`), correspondência de frases (`match_phrase`) ou correspondência de prefixo (`prefix`) para encontrar documentos que contenham palavras-chave específicas. Além disso, o Elasticsearch suporta consultas avançadas, como consultas booleanas (`bool`), consultas de intervalo (`range`), consultas geoespaciais e muito mais.

Você também pode aplicar **filtros** para restringir ainda mais os resultados da sua consulta. Isso é útil quando você deseja encontrar documentos que atendam a critérios específicos, como uma faixa de datas ou um valor numérico mínimo.

O Elasticsearch API também permite que você **classifique** os resultados das consultas de acordo com critérios específicos e realize **paginação** para lidar com grandes volumes de dados de maneira eficaz.

Além disso, você pode formatar e personalizar os resultados da consulta conforme necessário para atender aos requisitos do seu aplicativo. Isso pode incluir a seleção de campos específicos para retornar, a formatação dos resultados em JSON, XML ou outro formato desejado e a manipulação dos resultados para apresentá-los da maneira desejada a usuários finais.

Em resumo, as consultas de dados no Elasticsearch são flexíveis e poderosas. Com uma variedade de opções de consulta, filtros, classificação e formatação, você pode recuperar informações precisas e relevantes de maneira eficaz para atender às necessidades do seu aplicativo.

> **💡 Complemento (exemplos dos tipos citados):**
>
> ```json
> { "query": { "match_phrase": { "title": "god of war" } } }
> ```
>
> ```json
> { "query": { "prefix": { "title.keyword": "Zel" } } }
> ```
>
> ```json
> {
>   "from": 0,
>   "size": 10,
>   "_source": ["id", "title", "price"],
>   "query": { "match": { "description": "mundo aberto" } },
>   "sort": [ { "_score": "desc" }, { "releaseDate": "desc" } ]
> }
> ```
>
> - A API sempre responde em **JSON**; "XML ou outro formato" significa que a aplicação transforma o resultado depois. `_source` (*source filtering*) controla quais campos voltam.
> - **Paginação:** `from` + `size` funciona até `index.max_result_window` (10.000 por padrão). Para paginação profunda use `search_after` (com *point in time* no Elasticsearch/OpenSearch recentes).
> - **Ordenação:** sem `sort`, os resultados vêm por `_score` decrescente (relevância). Ordenar por campo de texto exige um campo `keyword` (ou `fielddata`, não recomendado).

#### Otimização de desempenho

À medida que você trabalha com volumes crescentes de dados no Elasticsearch, é crucial considerar a otimização de desempenho para garantir que suas consultas sejam executadas de maneira eficiente e que seu sistema continue sendo responsivo.

- **Shards e réplicas adequados:** uma das primeiras considerações é a configuração de índices com shards e réplicas adequadas. Os shards são unidades de distribuição de dados no Elasticsearch e você pode dividir seus índices em múltiplos shards. Esse processo é chamado de *sharding* e é útil para distribuir a carga de trabalho em vários nós do cluster, melhorando a escalabilidade. No entanto, a escolha do número de shards e réplicas depende do tamanho dos seus dados, da capacidade do hardware e das necessidades de consulta. Configurar um número excessivo de shards pode causar sobrecarga, enquanto poucos shards podem limitar o desempenho.
- **Consultas eficientes:** é importante criar consultas eficientes para minimizar o tempo de resposta. Isso envolve a elaboração de consultas que são tão específicas quanto possível para reduzir o escopo de pesquisa. Evite consultas amplas que precisam percorrer grandes volumes de dados, pois isso pode prejudicar o desempenho. Utilize consultas de filtro para restringir os resultados antes de aplicar consultas de correspondência.
- **Hardware e infraestrutura:** certifique-se de que os recursos do seu servidor Elasticsearch, como CPU, memória e armazenamento, estejam dimensionados adequadamente para a carga de trabalho. O monitoramento contínuo do desempenho do cluster é fundamental para identificar gargalos e tomar medidas corretivas.
- **Caches:** utilizar caches de consultas e resultados é uma estratégia eficaz para acelerar consultas frequentes. O Elasticsearch oferece suporte a caches que podem armazenar resultados de consultas e agilizar consultas subsequentes.
- **Atualizações:** mantenha seu Elasticsearch atualizado com as versões mais recentes e aplique patches de segurança e atualizações recomendadas. As versões mais recentes geralmente incluem melhorias de desempenho e correções de bugs que podem beneficiar sua implantação.

> **💡 Complemento (armadilhas de performance):**
> - Referência usual de tamanho: shards entre **10 GB e 50 GB**; muitos shards pequenos custam memória de heap e coordenação.
> - Evite `wildcard`/`regexp` com curinga no **início** (`*texto`) e `query_string` aberta ao usuário final; prefira `match`/`multi_match`, n-gramas ou `search_as_you_type`.
> - Caches do Elasticsearch: *node query cache* (cláusulas em contexto de filtro), *shard request cache* (por padrão, respostas com `size: 0`, típico de agregações) e o *filesystem cache* do SO. Eles são invalidados a cada *refresh* que altera o shard.
> - Use o **Profile API** (`"profile": true` no `_search`) para ver onde a query gasta tempo.

### O que você viu nesta aula?

Nesta aula, exploramos como indexar dados, realizar consultas e otimizar o desempenho usando o Elasticsearch API em serviços .NET. Essas práticas são essenciais para criar aplicativos eficientes e escaláveis que lidam com grandes volumes de dados não estruturados de forma eficaz.

### Referências da aula

- ELASTIC.CO. *.NET Agent Reference.* 2024. <https://www.elastic.co/guide/en/apm/agent/dotnet/current/intro.html>
- CHOU, S.; TRIPATHI, A. *Elastic Search 8.12: Making Lucene fast and developers faster.* 2024. <https://www.elastic.co/pt/blog/whats-new-elastic-search-8-12-0>
- THEEPIREDDY, U.; SUBHRATA K. *Achieving seamless API management: Introducing AWS API Gateway integration with Elastic.* 2023. <https://www.elastic.co/pt/blog/api-management-aws-api-gateway-integration-elastic>
- Palavras-chave: .NET, API, Elastic, Elasticsearch, Kibana, Log.

### Pontos-chave

- A API do Elasticsearch é REST + JSON e cobre indexação, busca, agregações, administração de índices e cluster.
- Hands On: dois microsserviços (HTTP → RabbitMQ → FFmpeg) registrando cada etapa como log no Elasticsearch.
- Roteiro .NET: conexão → cliente → índice com mapping → indexação de documentos JSON → consultas → otimização → monitoramento/segurança.
- Tipos de consulta: `match`, `match_phrase`, `prefix`, `bool`, `range`, geoespaciais e agregações; com filtros, ordenação e paginação.
- Filtros antes da correspondência reduzem o escopo e aproveitam cache.
- Número de shards é um compromisso: shards demais geram sobrecarga, poucos limitam o paralelismo.
- No .NET atual: cliente singleton, `Elastic.Clients.Elasticsearch` (Elastic) ou `OpenSearch.Client` (OpenSearch); para logs, Serilog/OpenTelemetry em vez de chamadas manuais.

---

## Aula 4 - Indexação de Documentos

### O que vem por aí?

Vamos mergulhar no fascinante mundo do Elasticsearch e explorar como ele revoluciona a maneira de indexar e buscar dados. Imagine substituir as restrições dos bancos de dados tradicionais por uma flexibilidade incrível, em que cada informação é um documento em um índice, parecido com livros em uma biblioteca moderna.

Vamos descobrir também como realizar operações CRUD com uma API intuitiva baseada em JSON, sem se preocupar com esquemas rígidos. E não é só isso! Prepare-se para explorar funcionalidades avançadas como correspondência difusa, stemização, pontuação de relevância, realce em documentos e tokenização.

Além disso, vamos entender por que a **desnormalização** de dados no Elasticsearch facilita uma recuperação de dados rápida e eficiente. Se você acha que isso já é incrível, espere até vermos como ele lida com tipos de dados variados, desde texto até geolocalização e vetores densos!

Essa aula vai ser um verdadeiro mergulho na busca e indexação de dados, então prepare-se para ter sua mente expandida e suas habilidades de desenvolvimento elevadas a um novo patamar!

### Hands On

Vamos botar a mão na massa com o Elasticsearch, sem enrolação. Primeiro, criaremos índices como quem organiza estantes de livros, cada um com seu próprio conjunto de documentos. Depois, vamos brincar com a inserção de dados — alguns comandos simples e pronto! Seus dados estarão lá, prontinhos para serem buscados.

Por falar em busca, prepare-se para ver a mágica acontecer: vamos fazer consultas que parecem ser um truque de mágica, usando correspondência difusa e stemização e vamos até adicionar um pouco de realce, para destacar o que é importante.

Ah, não esqueça da tokenização: vamos fragmentar textos como quem corta uma pizza, só para ver como o Elasticsearch os reorganiza de forma inteligente. Será uma sessão super interativa e dinâmica, em que a teoria vai ganhar vida e você verá o poder do Elasticsearch em ação.

> **💡 Complemento (roteiro equivalente ao Hands On, para o Kibana Dev Tools):**
>
> ```http
> PUT /produtos
> {
>   "settings": { "number_of_shards": 1, "number_of_replicas": 0 },
>   "mappings": {
>     "properties": {
>       "nome":      { "type": "text", "analyzer": "portuguese" },
>       "descricao": { "type": "text", "analyzer": "portuguese" },
>       "preco":     { "type": "scaled_float", "scaling_factor": 100 },
>       "categoria": { "type": "keyword" }
>     }
>   }
> }
> ```
>
> ```http
> POST /produtos/_doc/1
> { "nome": "Smartphone X", "descricao": "Smartphone com câmera de alta qualidade", "preco": 650.00, "categoria": "eletrônicos" }
> ```
>
> ```http
> POST /produtos/_update/1
> { "doc": { "preco": 599.90 } }
> ```
>
> ```http
> GET /produtos/_search
> {
>   "query": { "match": { "descricao": { "query": "camaras", "fuzziness": "AUTO" } } },
>   "highlight": { "fields": { "descricao": {} } }
> }
> ```
>
> ```http
> POST /produtos/_analyze
> { "field": "descricao", "text": "Corridas de carros rápidos" }
> ```
>
> ```http
> DELETE /produtos/_doc/1
> ```
>
> O `_analyze` mostra os *tokens* gerados (minúsculas, *stopwords* removidas, radicais) — a melhor ferramenta para entender por que uma busca acha (ou não) um documento.

### Saiba mais

#### Indexação: índices e documentos

Indexação, no Elasticsearch, é o coração do sistema, onde a mágica acontece. Imagine que você está construindo um sistema de busca para uma grande loja online: você tem milhões de produtos, todos com informações detalhadas. Como você armazena e busca esses dados de maneira eficiente? É aqui que a indexação entra.

Pense em um **índice** como um grande livro que contém informações sobre todos os produtos da loja. Mas, diferentemente de um livro físico, um índice no Elasticsearch é altamente otimizado para pesquisa. Ele possui um nome exclusivo, como "produtos", para que você possa identificá-lo facilmente.

Dentro desse "livro" (índice) você tem **documentos**, que são como as páginas do livro. Cada documento representa um produto específico em sua loja. Por exemplo: um documento pode representar um smartphone com informações como nome, preço, descrição e até mesmo avaliações de clientes.

Agora, imagine que um cliente está procurando um smartphone na faixa de preço de R$ 500 a R$ 700. O Elasticsearch é capaz de consultar rapidamente o índice "produtos", localizar todos os documentos que se encaixam nesse intervalo de preço e retornar os resultados em milissegundos.

Além disso, o Elasticsearch também permite consultas avançadas, como pesquisa de texto completo. Se um cliente procurar "smartphone com câmera de alta qualidade", o Elasticsearch poderá encontrar todos os produtos que correspondem a essa descrição em segundos.

Isso é incrivelmente poderoso para sistemas de busca e análise de dados em larga escala. O Elasticsearch torna a pesquisa de grandes volumes de dados eficiente e rápida, permitindo que especialistas em desenvolvimento construam sistemas de busca e análise robustos.

Portanto, a indexação no Elasticsearch é o alicerce sobre o qual você constrói sistemas de busca poderosos e eficientes, organizando seus dados em índices e documentos para que possam ser recuperados de forma rápida e precisa.

#### Elasticsearch x bancos de dados relacionais

Outro ponto que precisamos ter em mente é a diferença entre Elasticsearch e bancos de dados relacionais. Imagine que estamos construindo um sistema de armazenamento de informações e temos duas opções: o Elasticsearch e um banco de dados relacional. Vamos pensar no Elasticsearch como uma **livraria moderna e automatizada** e no banco de dados relacional como uma **biblioteca tradicional**.

A livraria moderna (Elasticsearch) é incrivelmente flexível em relação à estrutura dos dados. Assim como você pode armazenar não apenas livros, mas também revistas, DVDs e muito mais em uma livraria moderna, no Elasticsearch você pode armazenar diferentes tipos de dados sem a necessidade de definir uma estrutura rígida com tabelas e esquemas.

Em uma livraria moderna, você pode mudar as seções e prateleiras quando quiser, certo? Da mesma forma, no Elasticsearch, você pode adicionar ou modificar campos nos seus documentos sem interromper o funcionamento do sistema. Isso proporciona uma agilidade incrível.

Além disso, assim como uma livraria moderna pode se integrar facilmente com sistemas de gerenciamento de estoque, sistemas de pagamento e até mesmo sistemas de recomendação, o Elasticsearch é altamente integrável com diversas ferramentas. Isso significa que você pode conectar facilmente o seu sistema de busca a outras partes do seu ecossistema tecnológico.

Agora, vamos pensar em um banco de dados relacional como uma biblioteca tradicional. Em uma biblioteca, você tem prateleiras fixas e um sistema rígido de catalogação para os livros. Da mesma forma, nos bancos de dados relacionais você precisa definir uma estrutura de tabela e um esquema bem específico, em que os tipos de dados e as relações entre tabelas são rigidamente especificados.

Se você quiser adicionar um novo tipo de mídia à sua biblioteca tradicional, isso pode ser um processo complexo, envolvendo mudanças físicas nas prateleiras e no sistema de catalogação. Nos bancos de dados relacionais, fazer mudanças na estrutura de tabelas existentes também pode ser complicado.

Então, para resumir, o Elasticsearch é como uma livraria moderna, oferecendo flexibilidade, campos de tempo de execução (*runtime fields*) e integração com diversas ferramentas, enquanto um banco de dados relacional é como a biblioteca tradicional, com estruturas rígidas e menos adaptabilidade a tipos variados de dados. Essa comparação destaca como o Elasticsearch é uma escolha poderosa para sistemas de busca e análise flexíveis.

> **💡 Complemento (armadilha — "sem esquema" não é bem assim):** o Elasticsearch é *schema-on-write* com **mapeamento dinâmico**: o primeiro documento que chega define o tipo de cada campo novo, e **o tipo de um campo existente não pode ser alterado** — só adicionar campos novos. Se o primeiro documento trouxer `"preco": "10"`, o campo pode virar `text`/`keyword` e quebrar buscas por intervalo depois. Na prática:
> - Defina **mapping explícito** para índices de produção e, se quiser rigidez, use `"dynamic": "strict"` (rejeita campos não mapeados).
> - O mapeamento dinâmico de strings cria um campo `text` com subcampo `.keyword` (`ignore_above: 256`) — útil para começar, mas dobra o armazenamento e raramente é o que você quer.
> - Mudar o tipo/analyzer de um campo exige **criar um novo índice e reindexar** (ver complemento sobre alias e `_reindex` abaixo).
> - *Runtime fields* (citados na aula) permitem criar campos calculados na hora da consulta, sem reindexar — ao custo de desempenho na busca.

#### Interação com a API: CRUD com JSON RESTful

Como vimos anteriormente, vamos falar sobre a interação com a API do Elasticsearch. Isso é o que o torna tão incrivelmente flexível e poderoso. Imagine que você tem um grande conjunto de dados que deseja armazenar, pesquisar e gerenciar. Bem, a API é o seu meio de comunicação com o Elasticsearch e ela é baseada em JSON e funciona de maneira muito amigável.

Vamos descompactar essa ideia de uma API baseada em JSON RESTful. O que isso significa é que o Elasticsearch fornece um conjunto de *endpoints* (URLs) que você pode acessar usando solicitações HTTP comuns. Esses *endpoints* são como portas de entrada para interagir com o Elasticsearch. O RESTful significa que a API segue os princípios da arquitetura REST, que são um conjunto de regras para construir aplicativos web. É uma abordagem padrão e amplamente usada na web, então é bem familiar para muitas pessoas especialistas em desenvolvimento.

Agora, aqui está o grande ponto: com essa API você pode fazer operações **CRUD**, que são as quatro operações principais: *create* (criar), *read* (recuperar ou ler), *update* (atualizar) e *delete* (excluir) documentos. Isso significa que você pode inserir novos dados (criar), buscar dados específicos (recuperar), modificar informações (atualizar) ou remover dados (excluir) no Elasticsearch, tudo através dessas solicitações HTTP.

Uma coisa realmente legal aqui é que você não precisa definir um esquema rígido ou uma estrutura de tabela antes de começar a usar o Elasticsearch. Isso é diferente de bancos de dados tradicionais, em que você precisa definir como suas tabelas serão antes de inserir dados. No Elasticsearch, você pode simplesmente começar a enviar seus documentos JSON e ele os aceitará e lidará com eles de forma inteligente.

Então, basicamente, você envia solicitações HTTP para a API do Elasticsearch com seu JSON e faz todas essas coisas incríveis — indexar, buscar, atualizar e excluir documentos — sem qualquer necessidade de rigidez de esquema. É como ter uma conversa com o Elasticsearch, pedindo a ele para fazer o que você precisa com seus dados, tudo através de simples solicitações HTTP e JSON. É uma maneira poderosa e flexível de trabalhar com dados.

> **💡 Complemento (boas práticas — bulk, concorrência e reindexação):**
>
> **Bulk API** — para carga inicial ou sincronização em lote, nunca indexe documento por documento. O corpo é NDJSON (uma linha de ação + uma linha de documento, terminando com quebra de linha):
>
> ```http
> POST /_bulk
> { "index": { "_index": "games", "_id": "1" } }
> { "title": "The Legend of Zelda", "genre": "Aventura", "price": 299.90 }
> { "index": { "_index": "games", "_id": "2" } }
> { "title": "God of War", "genre": "Ação", "price": 249.90 }
> { "delete": { "_index": "games", "_id": "3" } }
> ```
>
> Lotes de ~5–15 MB (ou alguns milhares de documentos) costumam ser um bom ponto de partida. A resposta do bulk retorna HTTP 200 mesmo com falhas parciais — verifique o campo `errors` e cada item.
>
> **Id determinístico** — use o id do banco relacional como `_id`. Assim, reprocessar o mesmo evento é **idempotente** (sobrescreve em vez de duplicar).
>
> **Concorrência otimista** — use `if_seq_no`/`if_primary_term` para evitar sobrescrever com dados velhos, ou `version_type=external` passando uma versão crescente vinda do banco (ex.: `UpdatedAt` em *ticks*); uma versão menor é rejeitada com `409 Conflict`.
>
> **Alias + reindexação sem downtime** — a aplicação deve ler/escrever sempre em um **alias** (`games`), nunca no índice físico (`games-v1`). Para mudar o mapping:
>
> ```http
> PUT /games-v2
> { "mappings": { "properties": { "title": { "type": "text", "analyzer": "portuguese" } } } }
> ```
>
> ```http
> POST /_reindex
> { "source": { "index": "games-v1" }, "dest": { "index": "games-v2" } }
> ```
>
> ```http
> POST /_aliases
> {
>   "actions": [
>     { "remove": { "index": "games-v1", "alias": "games" } },
>     { "add":    { "index": "games-v2", "alias": "games", "is_write_index": true } }
>   ]
> }
> ```
>
> As ações de `_aliases` são atômicas. Alternativa comum quando o banco é a fonte da verdade: em vez de `_reindex`, recarregar `games-v2` a partir do PostgreSQL via bulk e então trocar o alias.

#### Funcionalidades avançadas de busca

Na nossa jornada de aprendizagem, precisamos compreender as funcionalidades avançadas de busca. Assim, temos:

- **Correspondência Difusa (*fuzzy matching*):** essa é uma funcionalidade poderosa que permite ao Elasticsearch encontrar documentos com termos aproximados ou pequenos erros. Por exemplo: se um usuário digitar "casa" em sua pesquisa, a correspondência difusa pode encontrar documentos que contenham palavras como "casar", "casado" ou "casinha". Isso é útil quando usuários podem cometer erros ortográficos ou desejam resultados mais amplos do que uma correspondência exata.
- **Stemização (*stemming*):** a stemização é uma técnica linguística que reduz palavras à sua forma base ou raiz. Isso ajuda na busca por diferentes formas da mesma palavra. Por exemplo: quando um usuário busca "corrida", a stemização pode encontrar documentos que contenham "correr" ou "corridas". Isso é essencial para abranger variações de palavras e melhorar a precisão das pesquisas.
- **Pontuação de Relevância (*relevance scoring*):** essa funcionalidade é fundamental para a classificação dos resultados da pesquisa. O Elasticsearch atribui pontuações aos documentos com base na sua relevância para a consulta. Isso significa que documentos mais relevantes para a pesquisa do usuário aparecerão no topo dos resultados. O cálculo da pontuação de relevância leva em consideração diversos fatores, como a frequência das palavras-chave no documento e a importância dos campos.
- **Realce (*highlighting*):** o realce é uma funcionalidade visual que destaca partes dos documentos que correspondem à consulta do usuário. Por exemplo: se um usuário pesquisar "Elasticsearch" e um documento contiver essa palavra, o Elasticsearch pode realçar a palavra nos resultados, tornando mais fácil para ele identificar por que o documento foi retornado como resultado relevante. Isso melhora significativamente a usabilidade do sistema de busca.
- **Tokenização:** a tokenização é o processo de dividir o texto em partes menores, chamadas de "tokens", para melhor entendimento e indexação. Por exemplo: a frase "O gato preto" seria dividida em três tokens: "O", "gato" e "preto". Isso permite que o Elasticsearch entenda as palavras individualmente e as indexe de forma eficiente para facilitar as buscas. Também é importante para lidar com diferentes idiomas e palavras compostas.

Essas funcionalidades avançadas de busca tornam o Elasticsearch uma ferramenta poderosa para construir sistemas de busca e análise de dados altamente precisos e flexíveis. Elas garantem que os resultados da pesquisa sejam relevantes, mesmo em cenários complexos e variados, tornando a experiência do usuário mais eficaz e agradável.

> **💡 Complemento (fuzziness e distância de Levenshtein — precisando o exemplo da aula):** a busca difusa usa a **distância de edição de Levenshtein** (Damerau-Levenshtein, por padrão): o número mínimo de inserções, remoções, substituições — e, com `fuzzy_transpositions: true` (padrão), transposições de letras vizinhas — para transformar um termo em outro. Com `"fuzziness": "AUTO"` (equivale a `AUTO:3,6`):
>
> | Tamanho do termo | Edições permitidas |
> |---|---|
> | 0–2 caracteres | 0 (precisa ser exato) |
> | 3–5 caracteres | 1 |
> | 6+ caracteres | 2 |
>
> O máximo absoluto é 2. Aplicando ao exemplo: "casa" tem 4 letras → 1 edição. **"casar"** (1 inserção) casa; **"casado"** (2 edições) e **"casinha"** (4 edições) **não** casam pela fuzziness — esses só apareceriam via stemização ou n-gramas. Fuzziness serve para **erros de digitação** ("zelad" → "zelda", "fifa" ↔ "fiaf"), não para variações morfológicas. Parâmetros úteis: `prefix_length` (quantas letras iniciais precisam bater — melhora desempenho e precisão) e `max_expansions` (limite de termos candidatos, padrão 50).
>
> **Analyzers (tokenização + stemização na prática):** um *analyzer* é a combinação de `char_filter` → `tokenizer` → `filter` (token filters). O `standard` (padrão) quebra por palavras (Unicode) e aplica `lowercase`, sem remover *stopwords*. Os analyzers de idioma `portuguese` e `brazilian` acrescentam *stopwords* e *stemmer*. Ponto crítico: o **mesmo analyzer é aplicado na indexação e na busca** (salvo `search_analyzer` diferente); por isso "O gato preto" vira, com `standard`, os tokens `o`, `gato`, `preto` — em minúsculas — e, com `portuguese`, o "o" (*stopword*) seria descartado. Para acentos, adicione o filtro `asciifolding` (assim "acao" encontra "ação"). Observação: *stemmers* algorítmicos reduzem a radicais ("corrida", "corridas" → mesmo radical), mas nem sempre unem verbo e substantivo ("correr" pode gerar outro radical); teste com `_analyze`.
>
> **Highlight:** o resultado vem em `hits[].highlight.<campo>` com o trecho envolvido por `<em>...</em>` (configurável com `pre_tags`/`post_tags`). Se exibir em HTML, cuide de *escaping* para evitar XSS (`"encoder": "html"`).

#### Funcionalidades adicionais

Para consolidar nossos conhecimentos em Elasticsearch, vamos entender algumas funcionalidades adicionais:

- **Índices Invertidos:** é uma base fundamental para buscas eficientes no Elasticsearch. Um índice invertido é uma estrutura de dados que permite a busca textual eficiente. Basicamente, ele mapeia todas as palavras em seus documentos para os documentos que as contêm. Isso permite que o Elasticsearch localize documentos relevantes rapidamente, mesmo em grandes volumes de dados, porque ele sabe quais documentos têm as palavras-chave desejadas. É como um índice de palavras-chave em um livro, mas super eficiente e escalável.
- **Buscas Numéricas e de Geolocalização:** o Elasticsearch não se limita apenas a pesquisas de texto, ele também é incrivelmente bom em buscas numéricas e de geolocalização para análise espacial eficiente. Isso significa que você pode encontrar documentos com base em coordenadas geográficas ou valores numéricos, como faixas de preço, classificações de produtos ou até mesmo datas. É como ter um GPS para seus dados, permitindo que você localize informações geograficamente ou com base em valores numéricos de forma eficiente.
- **Busca Vetorial/Semântica com PLN (Processamento de Linguagem Natural):** essa é uma funcionalidade avançada e empolgante do Elasticsearch. Ela utiliza "embedding de texto", que é uma técnica de representação de texto em um espaço vetorial. Isso permite ao Elasticsearch encontrar documentos que são semanticamente semelhantes, mesmo que as palavras-chave sejam diferentes. Por exemplo: se um usuário busca "carro", o Elasticsearch pode encontrar documentos que mencionam "automóvel" ou "veículo". Isso é muito poderoso para compreender o significado por trás das palavras e fornecer resultados mais relevantes com base na semântica.

Essas funcionalidades adicionais tornam o Elasticsearch uma escolha excepcional para uma ampla gama de aplicações, desde pesquisa textual até análise espacial e busca semântica. Elas permitem que você vá além da pesquisa básica de palavras-chave e crie sistemas de busca e análise de dados altamente sofisticados e precisos, atendendo a diversas necessidades de aplicação. É como ter um conjunto diversificado de ferramentas avançadas à sua disposição para explorar e entender seus dados de maneira profunda e eficaz.

> **💡 Complemento (índice invertido, por dentro):** para os documentos `1: "God of War"` e `2: "War Thunder"`, analisados com `standard`, o índice invertido do campo `title` fica:
>
> | Termo | Documentos (postings) |
> |---|---|
> | `god` | 1 |
> | `of` | 1 |
> | `thunder` | 2 |
> | `war` | 1, 2 |
>
> A busca por "war" vai direto ao termo e obtém a lista {1, 2}, sem varrer documentos — por isso é rápida, ao contrário de um `LIKE '%war%'` no SQL. A lista também guarda frequência e posições (necessárias para `match_phrase` e para o *score*). Campos numéricos, datas e `geo_point` **não** usam índice invertido, e sim estruturas BKD-tree, otimizadas para intervalos e geometria; para ordenação e agregações o Lucene usa *doc values* (armazenamento colunar).
>
> **Desnormalização (citada na abertura da aula):** como não há `JOIN` eficiente, o documento deve carregar tudo o que a busca precisa — ex.: o documento do jogo inclui o nome da publicadora e a lista de gêneros, em vez de apenas seus ids. O custo é reindexar os documentos afetados quando o dado compartilhado muda. Para arrays de objetos que precisam ser consultados de forma correlacionada, use o tipo `nested`.
>
> **Vetores:** a busca semântica usa o tipo `dense_vector` (Elasticsearch, com busca `knn`) ou `knn_vector` (OpenSearch, plugin k-NN). Os *embeddings* são gerados por um modelo (externo ou implantado no cluster), e é comum combinar com BM25 em **busca híbrida**.

### O que você viu nesta aula?

Esta aula foi uma verdadeira jornada pelo universo do Elasticsearch, não foi? Vimos como ele transforma a indexação e a busca de dados de algo complexo para algo super flexível e dinâmico. Agora você tem uma compreensão sólida de como criar e gerenciar índices, quase como organizar livros em uma estante virtual.

Percebeu como é prático inserir e buscar dados com aquelas operações CRUD via API JSON? A parte mais impressionante é a capacidade do Elasticsearch de lidar com buscas complexas, como aquelas com correspondência difusa e stemização, sem falar no realce e na tokenização que dão um show à parte.

E não se esqueça da nossa conversa sobre a desnormalização de dados — isso é fundamental para entender como o Elasticsearch acelera a recuperação de informações. Agora, você não só conhece as ferramentas como também entende o "porquê" e o "como" por trás delas. É esse tipo de conhecimento prático que faz a diferença no desenvolvimento.

### Referências da aula

- SIERRA, C. *Três práticas recomendadas para usar e solucionar problemas da API Reindex.* 2022. <https://www.elastic.co/pt/blog/3-best-practices-for-using-and-troubleshooting-the-reindex-api>
- RIBEIRO, F. *Melhore a performance do seu Elasticsearch com um eficiente Capacity Planning.* 2021. <https://blog.4linux.com.br/planejando-o-tamanho-correto-do-seu-elastic-cluster/>
- MISKOVIC, N. *Introdução à ES|QL (Elasticsearch Query Language).* 2023. <https://www.elastic.co/pt/blog/getting-started-elasticsearch-query-language>
- Palavras-chave: API, Elastic, Elasticsearch, Kibana, LOG.

### Pontos-chave

- Índice ≈ coleção de documentos JSON do mesmo tipo; documento ≈ registro (um produto, um jogo).
- A API REST/JSON oferece CRUD completo sobre documentos; use Bulk API para volume.
- Esquema flexível (mapeamento dinâmico), mas o tipo de um campo existente é imutável: em produção, mapping explícito + alias + reindexação.
- Funcionalidades de busca: correspondência difusa (Levenshtein), stemização, pontuação de relevância, realce e tokenização — todas dependem do *analyzer*.
- O índice invertido (termo → documentos) é o que torna a busca textual rápida; números/datas/geo usam BKD-trees.
- Desnormalizar é o padrão no Elasticsearch: o documento carrega o que a busca precisa.
- Além de texto: buscas numéricas, geoespaciais e vetoriais/semânticas (embeddings).

---

## Aula 5 - Pesquisa e Consultas Avançadas

### O que vem por aí?

Nessa aula, você vai aprender como realizar pesquisas e consultas avançadas de forma eficiente e direta. Vamos abordar as técnicas e ferramentas que permitem extrair informações precisas a partir de uma enorme quantidade de dados disponíveis.

Esta aula prática tem o objetivo de aprimorar suas habilidades de busca com Elasticsearch, ensinando você a filtrar o excesso de informações e a localizar exatamente o que procura, seja para trabalhos acadêmicos, pesquisa profissional ou uso pessoal. Ao final desta aula, você terá adquirido conhecimentos práticos para otimizar suas buscas.

### Hands On

Nesse Hands On, nos debruçaremos mais a fundo na **Query DSL** do Elasticsearch. Vamos iniciar com o básico da estrutura em JSON, progredindo para a elaboração de consultas **Match** e **Bool**, componentes cruciais para uma busca eficaz.

Em seguida, exploraremos como o Elasticsearch analisa e indexa o texto, uma etapa fundamental para a recuperação eficiente de documentos. Você aprenderá a medir a relevância dos resultados, a utilizar **agregações** para extrair estatísticas valiosas e a otimizar suas buscas com técnicas de filtragem.

Vamos exercitar o conhecimento com exemplos de código práticos que ilustrarão cada conceito, desde a manipulação de **documentos aninhados** até a compreensão das diferenças entre **consultas e filtros**, com foco em objetivos específicos, relevância e análise de texto.

Este Hands On é projetado para fortalecer sua compreensão teórica através da prática aplicada, garantindo que você saia com habilidades reais que podem ser imediatamente implementadas em seus projetos de Elasticsearch.

> **💡 Complemento (exemplos de agregação e documento aninhado, citados no Hands On):**
>
> ```json
> {
>   "size": 0,
>   "aggs": {
>     "por_genero": { "terms": { "field": "genres", "size": 10 } },
>     "preco_medio": { "avg": { "field": "price" } },
>     "faixas_preco": {
>       "range": { "field": "price", "ranges": [ { "to": 100 }, { "from": 100, "to": 200 }, { "from": 200 } ] }
>     }
>   }
> }
> ```
>
> ```json
> {
>   "query": {
>     "nested": {
>       "path": "reviews",
>       "query": {
>         "bool": {
>           "must": [
>             { "match": { "reviews.comment": "gráficos" } },
>             { "range": { "reviews.rating": { "gte": 4 } } }
>           ]
>         }
>       }
>     }
>   }
> }
> ```
>
> `terms` exige campo `keyword` (ou numérico). Agregações por `terms` são a base de **facetas** ("Ação (12)", "RPG (8)") em telas de busca. A query `nested` só funciona se `reviews` estiver mapeado como `"type": "nested"`; sem isso, os objetos do array são "achatados" e a condição pode casar campos de *reviews* diferentes.

### Saiba mais

#### Query DSL

No universo do Elasticsearch, o termo "Query DSL" se refere à Linguagem de Consulta de Domínio Específico (*Domain Specific Language*, DSL) utilizada para construir consultas (*queries*) em Elasticsearch. Essa linguagem permite que usuários formulem consultas complexas para recuperar dados que correspondam aos critérios específicos definidos.

A Query DSL do Elasticsearch é baseada em JSON (*JavaScript Object Notation*), o que a torna fácil de entender e escrever para especialistas em desenvolvimento familiarizados(as) com JSON. Com a Query DSL, usuários podem especificar os diferentes parâmetros de consulta, tais como campos a serem consultados, termos de pesquisa, filtros, regras de ordenação e muito mais.

A principal vantagem da Query DSL é sua capacidade de expressar consultas altamente sofisticadas e personalizadas. Por exemplo: você pode criar consultas que combinem múltiplos critérios de pesquisa, apliquem filtros complexos, classifiquem os resultados de acordo com diferentes critérios e agreguem os dados recuperados para análise.

Aqui está um exemplo simples de uma consulta usando a Query DSL do Elasticsearch:

```json
{
    "query": {
        "match": {
           "title": "elasticsearch"
        }
    }
}
```

*Código-fonte 1 — Consulta usando a Query DSL do Elasticsearch (Fonte: elaborado pelo autor, 2024).*

Neste exemplo, estamos buscando documentos em que o campo "title" contenha a palavra "elasticsearch". Esta é apenas uma consulta básica; a Query DSL permite a construção de consultas muito mais complexas para atender às necessidades específicas de cada aplicação.

> **💡 Complemento (`match`, `multi_match` e boosting):**
> - `match` analisa o texto da busca com o analyzer do campo e, por padrão, combina os termos com `OR` (`"operator": "and"` exige todos; `minimum_should_match` dá meio-termo, ex.: `"75%"`).
> - `multi_match` executa a busca em **vários campos** de uma vez. Tipos principais: `best_fields` (padrão — usa o score do melhor campo; bom para "a frase inteira está em um campo"), `most_fields` (soma os scores dos campos; bom com o mesmo texto analisado de formas diferentes), `cross_fields` (trata os campos como um campo só; bom para nome + sobrenome), `phrase`/`phrase_prefix` e `bool_prefix`.
> - **Boosting** por campo usa a sintaxe `campo^N`: `"fields": ["title^3", "description"]` faz um acerto no título valer ~3× mais. Também existe `boost` em cláusulas individuais, `function_score` (ex.: somar popularidade ou avaliação ao score) e a query `boosting` (rebaixar, sem excluir, documentos que casam com um critério negativo).
> - Fuzziness é aceita em `match` e em `multi_match` dos tipos `best_fields`, `most_fields` e `bool_prefix`; **não** é suportada com `cross_fields`, `phrase` e `phrase_prefix`.
>
> ```json
> {
>   "query": {
>     "multi_match": {
>       "query": "zelad breath",
>       "fields": ["title^3", "description"],
>       "fuzziness": "AUTO"
>     }
>   }
> }
> ```

#### Filtros

Na Query DSL do Elasticsearch, os filtros são usados para restringir os resultados de uma consulta com base em critérios específicos, limitando os documentos que serão considerados na consulta, o que pode melhorar significativamente sua eficiência, especialmente em índices grandes.

Os filtros na Query DSL podem ser aplicados de várias maneiras, incluindo:

- **Filtros de Termo (*Term Filters*):** esses filtros são usados para encontrar documentos que contenham um valor específico em um campo específico. Por exemplo: você pode filtrar documentos em que o campo "status" seja "publicado".
- **Filtros de Correspondência (*Match Filters*):** estes filtros são usados para encontrar documentos que correspondam a uma determinada condição. Por exemplo: você pode filtrar documentos em que o campo "categoria" corresponda a "eletrônicos".

```json
{
    "query": {
        "bool": {
            "filter": {
                "match": { "category": "eletrônicos" }
            }
        }
    }
}
```

*Código-fonte 2 — Filtro de correspondência (Fonte: elaborado pelo autor, 2024).*

- **Filtros de Intervalo (*Range Filters*):** estes filtros permitem que você selecione documentos com valores dentro de um intervalo específico. Por exemplo: você pode filtrar documentos com um campo "preço" entre 100 e 200.

```json
{
    "query": {
        "bool": {
            "filter": {
                "range": {
                    "price": { "gte": 100, "lte": 200 }
                }
            }
        }
    }
}
```

*Código-fonte 3 — Filtro de intervalo (Fonte: elaborado pelo autor, 2024).*

- **Filtros Combinados (*Compound Filters*):** você também pode combinar vários filtros usando operadores lógicos, como "must", "should" e "must_not". Isso permite construir consultas complexas.

```json
{
    "query": {
        "bool": {
            "filter": [
                { "term": { "status": "publicado" } },
                { "range": { "price": { "gte": 100, "lte": 200 } } }
            ]
        }
    }
}
```

*Código-fonte 4 — Filtro combinado (Fonte: elaborado pelo autor, 2024).*

Esses são apenas alguns exemplos de filtros disponíveis na Query DSL do Elasticsearch. Eles fornecem uma maneira poderosa de refinar suas consultas e encontrar os documentos exatos que você está procurando.

> **💡 Complemento (as quatro cláusulas do `bool` e a armadilha do `term`):**
>
> | Cláusula | Precisa casar? | Afeta o `_score`? | Cacheável? |
> |---|---|---|---|
> | `must` | Sim | Sim | Não |
> | `should` | Opcional* | Sim (soma) | Não |
> | `filter` | Sim | **Não** | Sim |
> | `must_not` | Não pode casar | Não | Sim |
>
> \* Se o `bool` não tiver `must` nem `filter`, pelo menos um `should` precisa casar; havendo, os `should` só aumentam o score (ajustável com `minimum_should_match`).
>
> - Em "Filtros Combinados" a aula cita `must`/`should`/`must_not`, mas o Código-fonte 4 usa `filter` com array — que é um **AND** sem cálculo de relevância. Para **OR** em contexto de filtro, aninhe um `bool` com `should` dentro do `filter`.
> - **Armadilha do `term`:** `term` **não** analisa o valor. `{"term": {"status": "publicado"}}` só funciona se `status` for `keyword` (e com o valor exato, inclusive maiúsculas/acentos). Sobre um campo `text`, o valor indexado foi transformado (minúsculas, radicais), e o `term` costuma não achar nada. Já `match` dentro de `filter` (Código-fonte 2) analisa o texto, mas não pontua.
> - Exemplo completo de busca + filtros:
>
> ```json
> {
>   "query": {
>     "bool": {
>       "must":     [ { "match": { "title": { "query": "zelda", "fuzziness": "AUTO" } } } ],
>       "filter":   [ { "term": { "genres": "Aventura" } }, { "range": { "price": { "lte": 300 } } } ],
>       "must_not": [ { "term": { "isActive": false } } ],
>       "should":   [ { "term": { "platforms": "Switch" } } ]
>     }
>   }
> }
> ```

#### Query x filtro

Com isso podemos entender que query e filtros têm papéis distintos na recuperação e filtragem de dados de um índice:

- As **consultas** são usadas para encontrar documentos que correspondam aos critérios de pesquisa especificados, levando em consideração a relevância dos termos buscados. Elas são úteis quando é necessário classificar os resultados com base na sua relevância para os termos de pesquisa.
- Os **filtros** são utilizados para restringir os documentos considerados em uma consulta com base em critérios específicos, sem calcular a relevância. Isso os torna mais eficientes em termos de desempenho, especialmente em consultas que não requerem cálculos de relevância.

Os filtros são frequentemente empregados para refinar os resultados de consultas, melhorando a precisão e a eficiência das operações de busca. Essa distinção entre consultas e filtros é fundamental para otimizar o processo de recuperação e filtragem de dados no Elasticsearch, garantindo resultados precisos e rápidos conforme as necessidades específicas da aplicação.

> **💡 Complemento (regra prática):** pergunta "quão bem casa?" → **query context** (`must`/`should`). Pergunta "casa ou não casa?" (sim/não: gênero, faixa de preço, status, data) → **filter context** (`filter`/`must_not`). Filtros são cacheados pelo nó (*node query cache*) e reutilizados entre buscas.

#### Cálculo de relevância

Falamos na sessão anterior que os filtros são utilizados para restringir os documentos considerados em uma consulta com base em critérios específicos, sem calcular a relevância. Mas o que é cálculo de relevância?

No contexto do Elasticsearch, o cálculo de relevância refere-se ao processo pelo qual o mecanismo de busca determina a importância ou pertinência de um documento em relação aos termos de pesquisa fornecidos pelo usuário. Quando uma consulta é feita, o Elasticsearch calcula a relevância de cada documento em relação aos termos de pesquisa, levando em consideração vários fatores:

- **Frequência do termo:** quão frequentemente os termos de pesquisa aparecem nos campos indexados do documento.
- **Localização do termo:** se os termos de pesquisa aparecem em campos mais relevantes ou importantes do documento.
- **Comprimento do documento** e a **presença de termos exclusivos**, que podem aumentar sua relevância.
- **Normas de campo:** podem influenciar a maneira como os valores dos campos são normalizados.
- **Relevância do próprio termo:** alguns termos são considerados mais importantes do que outros com base em seu contexto ou significado.

Esses fatores contribuem para determinar a relevância de um documento em relação aos termos de pesquisa e ajudam a garantir que os resultados retornados por uma consulta sejam os mais pertinentes possível para o usuário.

> **💡 Complemento (BM25 e `_score`):** desde a versão 5.0, o algoritmo de similaridade padrão é o **Okapi BM25** (antes era TF-IDF clássico). Os fatores da aula correspondem a:
> - **TF (*term frequency*)**: quanto mais vezes o termo aparece no campo, maior o score — mas com **saturação** controlada por `k1` (padrão 1.2): a 10ª ocorrência vale bem menos que a 1ª.
> - **IDF (*inverse document frequency*)**: termos raros no índice valem mais que termos comuns ("zelda" pesa mais que "jogo") — é a "relevância do próprio termo / termos exclusivos".
> - **Normalização pelo comprimento do campo** (`b`, padrão 0.75): um acerto em um campo curto (título) vale mais que em um campo longo (descrição) — são as "normas de campo".
> - **Boost** de campo/cláusula: a "localização do termo" que você controla explicitamente (ex.: `title^3`).
>
> O `_score` é **relativo à consulta e ao índice** (não é percentual, não compare scores entre consultas diferentes) e é calculado por shard — com poucos documentos e vários shards, as estatísticas de IDF podem variar entre shards (o parâmetro `search_type=dfs_query_then_fetch` corrige isso a um custo extra). Para depurar: `"explain": true` na busca ou `GET /indice/_explain/{id}`.

#### Índices

Outro tópico importante para nos aprofundarmos no conhecimento sobre Elasticsearch são os índices, lembrando que um índice é uma estrutura de armazenamento fundamental que organiza e gerencia os dados. Ele pode ser comparado a um banco de dados em um sistema de gerenciamento de banco de dados relacional, mas com algumas diferenças significativas em termos de arquitetura e funcionalidade.

- **Armazenamento de Dados:** no Elasticsearch, os dados são armazenados em forma de documentos JSON. Cada documento é armazenado individualmente dentro de um índice. Por exemplo: em um índice de "produtos", cada documento pode representar um produto com seus atributos, como nome, preço, descrição etc.
- **Esquema Flexível:** ao contrário dos bancos de dados relacionais que requerem um esquema predefinido, o Elasticsearch possui um esquema flexível. Isso significa que você pode adicionar documentos com estruturas diferentes dentro do mesmo índice. Por exemplo: em um índice de "clientes" alguns documentos podem ter um campo "endereço", enquanto outros não.
- **Índices Multiplataforma:** o Elasticsearch permite criar vários índices, cada um com seu próprio conjunto de documentos e configurações. Isso é útil para separar dados com diferentes propósitos ou de diferentes fontes. Por exemplo: você pode ter um índice para registros de logs, outro para dados de usuários e outro para dados de produtos.
- **Particionamento e Escalabilidade:** os índices no Elasticsearch são particionados em shards, que são unidades básicas de armazenamento distribuído. Isso permite distribuir os dados em várias máquinas, facilitando a escalabilidade horizontal conforme a quantidade de dados aumenta.
- **Recuperação de Dados Eficiente:** os índices são projetados para permitir a recuperação eficiente de dados. Eles são otimizados para pesquisa e suportam consultas complexas usando a Query DSL do Elasticsearch.

> **💡 Complemento:** note que na Aula 3 o índice foi comparado a uma **tabela**, e aqui a um **banco de dados**. Desde a remoção dos *mapping types* (7.0), a analogia mais fiel é **índice ≈ tabela** (um tipo de documento por índice). Uma busca pode abranger vários índices de uma vez (`GET /logs-2024-*/_search`) ou um alias que aponte para vários índices.

#### N-gramas

Agora que entendemos sobre índices podemos entender também sobre N-gramas. No Elasticsearch, os N-gramas são uma técnica de análise de texto usada para indexar e pesquisar texto de forma mais flexível e robusta. Quando um documento é indexado, o Elasticsearch pode dividir o texto em unidades menores, chamadas N-gramas, em vez de apenas palavras individuais. Isso é particularmente útil em cenários em que se deseja lidar com pesquisas que envolvem termos parciais, termos com erros ortográficos ou palavras compostas.

Por exemplo: considere a palavra "elefante". Se usarmos uma abordagem de 3-gramas (trigramas), ela será dividida em `["ele", "lef", "efa", "fan", "ant", "nte"]`. Isso significa que, ao indexar um documento com a palavra "elefante", ele será indexado não apenas com a palavra completa, mas também com esses trigramas individuais. Portanto, uma consulta por "elefante" irá retornar o documento, mas também uma consulta por "lefan" ou "elef" terá uma alta probabilidade de encontrar o mesmo documento, o que é útil para pesquisas com erros ortográficos ou consultas parciais.

Os N-gramas podem ser configurados durante a configuração do analisador de texto no Elasticsearch. Você pode definir o tamanho dos N-gramas (como unigramas, bigramas, trigramas etc.) com base em suas necessidades específicas. Essa configuração é realizada em um campo por meio de um **analisador personalizado**, que define como o texto é dividido em tokens durante o processo de indexação.

Os N-gramas são particularmente úteis em casos de uso em que a flexibilidade na pesquisa de texto é importante, como em mecanismos de busca de texto, correção ortográfica, autocompletar e outras funcionalidades semelhantes. Eles ajudam a melhorar a capacidade do Elasticsearch de lidar com consultas imprecisas ou parciais, tornando os resultados de pesquisa mais abrangentes e precisos.

> **💡 Complemento (configurando n-gramas e edge n-gramas):** quando o campo usa somente o analyzer de n-gramas, o índice guarda os n-gramas (e não a palavra inteira, a menos que você também indexe um subcampo com o analyzer normal — o padrão recomendado). A consulta "lefan" funciona porque **ela também é quebrada em trigramas** (`lef`, `efa`, `fan`) que coincidem com os indexados. Para **autocompletar**, o mais comum é o **edge n-gram** (n-gramas ancorados no início: `el`, `ele`, `elef`...), aplicado só na indexação, com `search_analyzer` padrão:
>
> ```json
> PUT /games-autocomplete
> {
>   "settings": {
>     "analysis": {
>       "filter": {
>         "autocomplete_filter": { "type": "edge_ngram", "min_gram": 2, "max_gram": 15 }
>       },
>       "analyzer": {
>         "autocomplete": {
>           "type": "custom",
>           "tokenizer": "standard",
>           "filter": ["lowercase", "asciifolding", "autocomplete_filter"]
>         }
>       }
>     }
>   },
>   "mappings": {
>     "properties": {
>       "title": {
>         "type": "text",
>         "analyzer": "autocomplete",
>         "search_analyzer": "standard"
>       }
>     }
>   }
> }
> ```
>
> Cuidados: n-gramas aumentam muito o tamanho do índice; a diferença entre `max_gram` e `min_gram` é limitada por `index.max_ngram_diff` (padrão 1) para o tipo `ngram`; e o tipo de campo pronto `search_as_you_type` resolve o caso típico de autocompletar sem configuração manual. **N-gramas x fuzziness:** n-gramas ajudam em termos parciais; fuzziness, em erros de digitação — podem ser combinados.

### O que você viu nesta aula?

Nesta aula, exploramos uma ampla gama de conceitos e técnicas relacionadas ao Elasticsearch, um poderoso mecanismo de busca e análise de texto. Começamos entendendo a importância dos índices e como eles organizam e gerenciam os dados, fornecendo uma base fundamental para as operações de busca e recuperação de informações.

Em seguida, mergulhamos no mundo dos N-gramas, uma técnica essencial de análise de texto que permite lidar com consultas parciais, erros ortográficos e outros desafios comuns em processamento de linguagem natural.

Ao compreender como configurar e usar os N-gramas no Elasticsearch, ganhamos uma compreensão mais profunda de como essa ferramenta pode ser adaptada e otimizada para atender às necessidades específicas de busca e análise de texto em diversos contextos.

No geral, esta aula nos proporcionou uma visão abrangente e prática das capacidades e aplicações do Elasticsearch, preparando-nos para explorar ainda mais suas funcionalidades e potenciais em nossos projetos futuros.

### Referências da aula

- BRASETVIK, A. *Elasticsearch de baixo para cima, parte 1.* 2013. <https://www.elastic.co/pt/blog/found-elasticsearch-from-the-bottom-up>
- ELASTIC.CO. *O que são embeddings de palavras?* [s.d.] <https://www.elastic.co/pt/what-is/word-embedding>
- ELASTIC.CO. *N-gram token filter.* [s.d.] <https://www.elastic.co/guide/en/elasticsearch/reference/current/analysis-ngram-tokenfilter.html>
- Palavras-chave: Elasticsearch, N-grama, Kibana, .NET.

### Pontos-chave

- Query DSL é a linguagem de consulta em JSON do Elasticsearch; `match` e `bool` são a base.
- Filtros (`term`, `match`, `range`, combinados) restringem resultados **sem** calcular relevância e são cacheáveis.
- `bool`: `must` e `should` pontuam; `filter` e `must_not` apenas incluem/excluem.
- `term` não analisa o valor — use-o com campos `keyword`; `match` analisa — use-o com campos `text`.
- Relevância (BM25): frequência do termo (com saturação), raridade do termo (IDF), comprimento do campo e boosts.
- Índices armazenam documentos JSON com esquema flexível, particionados em shards.
- N-gramas (e edge n-gramas) permitem busca parcial e autocompletar, ao custo de índice maior; fuzziness cobre erros de digitação.

---

## Aplicação no Tech Challenge da Fase 4

### Requisitos do enunciado

- Implementar um **motor de busca independente do banco relacional** (o PostgreSQL continua sendo a fonte da verdade).
- Usar um **serviço gerenciado** — por exemplo, **Amazon OpenSearch Service** ou **Elastic Cloud**.
- **Sincronização no CatalogAPI** (.NET, que já usa PostgreSQL + Redis): ao **inserir/editar um jogo**, atualizar o índice de busca.
- Expor um endpoint **`/search`** com **Fuzzy Search** e **ordenação por relevância**.

> **💡 Complemento:** tudo a partir daqui é proposta de estudo, não material da FIAP. Adapte nomes de campos e classes ao seu CatalogAPI.

### Arquitetura proposta

```text
                    ┌──────────────┐  escrita (fonte da verdade)  ┌────────────┐
 POST/PUT /games ──►│  CatalogAPI  │─────────────────────────────►│ PostgreSQL │
                    │   (.NET)     │                              └────────────┘
                    │              │─── invalida chaves ─────────►┌────────────┐
 GET /games/{id} ──►│              │◄── cache-aside ──────────────│   Redis    │
                    │              │                              └────────────┘
 GET /search ──────►│              │─── index / search ──────────►┌──────────────────────┐
                    └──────────────┘                              │ OpenSearch / Elastic │
                                                                  │  alias "games"       │
                                                                  └──────────────────────┘
```

> **💡 Complemento (escolha do serviço gerenciado):**
>
> | | Amazon OpenSearch Service | Elastic Cloud |
> |---|---|---|
> | Motor | OpenSearch (fork do ES 7.10.2) ou Elasticsearch legado ≤ 7.10 | Elasticsearch 8.x/9.x |
> | Cliente .NET | `OpenSearch.Client` (+ `OpenSearch.Net.Auth.AwsSigV4` para IAM) | `Elastic.Clients.Elasticsearch` |
> | Autenticação típica | IAM (SigV4) ou usuário interno do *fine-grained access control* | API Key |
> | Afinidade | Melhor se o restante do Tech Challenge já roda na AWS (VPC, IAM, CloudWatch) | Melhor se quiser os recursos mais novos do Elasticsearch/Kibana |
>
> Para o escopo do desafio, a Query DSL usada abaixo (`multi_match`, `fuzziness`, `bool`, `range`, `term`) é idêntica nos dois motores. Há também o **OpenSearch Serverless** (coleções do tipo *search*), que dispensa dimensionar nós, mas tem diferenças de API (ex.: sem controle de shards) — verifique antes de adotar.

### Mapping proposto para o índice `games`

> **💡 Complemento:** índice físico versionado (`games-v1`) + alias `games`, mapping explícito e `dynamic: strict`.

```http
PUT /games-v1
{
  "settings": {
    "number_of_shards": 1,
    "number_of_replicas": 1,
    "analysis": {
      "analyzer": {
        "pt_folded": {
          "type": "custom",
          "tokenizer": "standard",
          "filter": ["lowercase", "asciifolding", "brazilian_stop", "brazilian_stemmer"]
        },
        "autocomplete": {
          "type": "custom",
          "tokenizer": "standard",
          "filter": ["lowercase", "asciifolding", "autocomplete_edge"]
        }
      },
      "filter": {
        "brazilian_stop":    { "type": "stop", "stopwords": "_brazilian_" },
        "brazilian_stemmer": { "type": "stemmer", "language": "brazilian" },
        "autocomplete_edge": { "type": "edge_ngram", "min_gram": 2, "max_gram": 15 }
      }
    }
  },
  "mappings": {
    "dynamic": "strict",
    "properties": {
      "id":          { "type": "keyword" },
      "title": {
        "type": "text",
        "analyzer": "standard",
        "fields": {
          "pt":           { "type": "text", "analyzer": "pt_folded" },
          "autocomplete": { "type": "text", "analyzer": "autocomplete", "search_analyzer": "standard" },
          "keyword":      { "type": "keyword", "ignore_above": 256 }
        }
      },
      "description": { "type": "text", "analyzer": "pt_folded" },
      "genres":      { "type": "keyword" },
      "platforms":   { "type": "keyword" },
      "publisher":   { "type": "keyword" },
      "price":       { "type": "scaled_float", "scaling_factor": 100 },
      "releaseDate": { "type": "date" },
      "isActive":    { "type": "boolean" },
      "popularity":  { "type": "integer" },
      "updatedAt":   { "type": "date" }
    }
  }
}
```

```http
POST /_aliases
{ "actions": [ { "add": { "index": "games-v1", "alias": "games", "is_write_index": true } } ] }
```

Decisões:

- `title` em três versões: `standard` (preserva a palavra como digitada, melhor para fuzzy), `.pt` (stemização/acentos) e `.autocomplete` (edge n-gram para sugestões); `.keyword` para ordenação alfabética e igualdade exata.
- `genres`, `platforms`, `publisher` como `keyword`: servem a filtros (`term`/`terms`) e facetas (agregações), desnormalizados (nomes, não ids).
- `price` como `scaled_float` evita imprecisão de `float` em valores monetários.
- `isActive` permite "soft delete" na busca sem remover o documento, se for regra de negócio.

### Query de busca: fuzzy `multi_match` com boost no título

> **💡 Complemento:**

```http
GET /games/_search
{
  "from": 0,
  "size": 10,
  "track_total_hits": true,
  "_source": ["id", "title", "genres", "platforms", "price", "releaseDate"],
  "query": {
    "bool": {
      "must": [
        {
          "multi_match": {
            "query": "zelad brath of the wild",
            "type": "best_fields",
            "fields": ["title^3", "title.pt^2", "description"],
            "fuzziness": "AUTO",
            "prefix_length": 1,
            "operator": "or",
            "minimum_should_match": "70%"
          }
        }
      ],
      "should": [
        { "match_phrase": { "title": { "query": "zelad brath of the wild", "boost": 2 } } }
      ],
      "filter": [
        { "term": { "isActive": true } }
      ]
    }
  },
  "highlight": {
    "encoder": "html",
    "fields": { "title": {}, "description": {} }
  }
}
```

- `fuzziness: AUTO` corrige "zelad" → "zelda" e "brath" → "breath" (1 edição cada).
- `title^3` dá mais peso ao título; `should` com `match_phrase` premia a frase exata quando existir (sem excluir os demais).
- `filter` não interfere na relevância; sem `sort`, a resposta já vem **ordenada por `_score`** (relevância), como pede o enunciado. Se adicionar ordenação secundária, mantenha `_score` primeiro: `"sort": [{"_score": "desc"}, {"popularity": "desc"}]`.
- Para filtros opcionais do endpoint (gênero, plataforma, faixa de preço), acrescente `term`/`range` no `filter`.

### Esboço de código C# (OpenSearch.Client — Amazon OpenSearch Service)

> **💡 Complemento:** esboço com `OpenSearch.Client` (sintaxe herdada do NEST, a mesma da Aula 1). Os nomes de tipos do seu projeto (handler, entidade) são ilustrativos. Pacotes: `OpenSearch.Client` e, para IAM, `OpenSearch.Net.Auth.AwsSigV4`.

```csharp
// Documento do índice (desnormalizado; separado da entidade de domínio/EF Core)
public sealed record GameDocument(
    string Id,
    string Title,
    string Description,
    IReadOnlyList<string> Genres,
    IReadOnlyList<string> Platforms,
    string Publisher,
    decimal Price,
    DateTime ReleaseDate,
    bool IsActive,
    int Popularity,
    DateTime UpdatedAt);

public sealed record SearchResult(string Id, string Title, decimal Price, double? Score);

// Abstração que isola o motor de busca (troca OpenSearch <-> Elastic sem afetar o domínio)
public interface IGameSearchService
{
    Task IndexAsync(GameDocument doc, CancellationToken ct = default);
    Task DeleteAsync(string id, CancellationToken ct = default);
    Task<(long Total, IReadOnlyList<SearchResult> Items)> SearchAsync(
        string term, int page, int pageSize, CancellationToken ct = default);
}
```

```csharp
using OpenSearch.Client;

public sealed class OpenSearchGameSearchService(IOpenSearchClient client) : IGameSearchService
{
    private const string Alias = "games";

    public async Task IndexAsync(GameDocument doc, CancellationToken ct = default)
    {
        // _id = id do PostgreSQL -> reindexar o mesmo jogo é idempotente
        var response = await client.IndexAsync(doc, i => i.Index(Alias).Id(doc.Id), ct);
        if (!response.IsValid)
            throw new InvalidOperationException($"Falha ao indexar jogo {doc.Id}: {response.DebugInformation}");
    }

    public async Task DeleteAsync(string id, CancellationToken ct = default)
    {
        var response = await client.DeleteAsync<GameDocument>(id, d => d.Index(Alias), ct);
        if (!response.IsValid && response.Result != Result.NotFound)
            throw new InvalidOperationException($"Falha ao remover jogo {id}: {response.DebugInformation}");
    }

    public async Task<(long Total, IReadOnlyList<SearchResult> Items)> SearchAsync(
        string term, int page, int pageSize, CancellationToken ct = default)
    {
        var response = await client.SearchAsync<GameDocument>(s => s
            .Index(Alias)
            .From((page - 1) * pageSize)
            .Size(pageSize)
            .TrackTotalHits()
            .Query(q => q
                .Bool(b => b
                    .Must(m => m
                        .MultiMatch(mm => mm
                            .Query(term)
                            .Fields(f => f
                                .Field(p => p.Title, boost: 3)
                                .Field("title.pt", boost: 2)
                                .Field(p => p.Description))
                            .Fuzziness(Fuzziness.Auto)
                            .PrefixLength(1)
                            .MinimumShouldMatch("70%")))
                    .Filter(f => f.Term(t => t.Field(p => p.IsActive).Value(true))))),
            ct);

        if (!response.IsValid)
            throw new InvalidOperationException($"Falha na busca: {response.DebugInformation}");

        var items = response.Hits
            .Select(h => new SearchResult(h.Source.Id, h.Source.Title, h.Source.Price, h.Score))
            .ToList();

        return (response.Total, items);
    }
}
```

```csharp
// Program.cs (trechos)
using OpenSearch.Client;
using OpenSearch.Net;
using OpenSearch.Net.Auth.AwsSigV4;

builder.Services.AddSingleton<IOpenSearchClient>(_ =>
{
    var endpoint = new Uri(builder.Configuration["Search:Endpoint"]!);
    var pool = new SingleNodeConnectionPool(endpoint);

    // Em dev (docker local), use a conexão padrão; na AWS, assine com SigV4 (credenciais da role da task/instância)
    var settings = builder.Environment.IsDevelopment()
        ? new ConnectionSettings(pool)
        : new ConnectionSettings(pool, new AwsSigV4HttpConnection());

    settings.DefaultIndex("games");
    return new OpenSearchClient(settings);
});
builder.Services.AddScoped<IGameSearchService, OpenSearchGameSearchService>();

// Endpoint /search
app.MapGet("/search", async (string q, int page, int pageSize, IGameSearchService search, CancellationToken ct) =>
{
    if (string.IsNullOrWhiteSpace(q)) return Results.BadRequest("Informe o termo de busca (q).");
    page = Math.Max(page, 1);
    pageSize = Math.Clamp(pageSize, 1, 50);

    var (total, items) = await search.SearchAsync(q.Trim(), page, pageSize, ct);
    return Results.Ok(new { total, page, pageSize, items });
});
```

> **💡 Complemento (se optar por Elastic Cloud):** troque a implementação de `IGameSearchService` por uma baseada em `Elastic.Clients.Elasticsearch` — `new ElasticsearchClient(new ElasticsearchClientSettings(new Uri(url)).Authentication(new ApiKey(key)))` (ou o construtor com *Cloud ID*), `IndexAsync`, `DeleteAsync`, `SearchAsync<GameDocument>` com `MultiMatch` e `Fuzziness("AUTO")`, verificando `IsValidResponse`. A estrutura da query é a mesma; a API *fluent* difere entre as versões 8 e 9 do cliente, então confira a documentação da versão instalada. A interface `IGameSearchService` mantém o restante do CatalogAPI intocado.

### Estratégia de sincronização: síncrona no handler x evento/outbox

> **💡 Complemento:**

| Critério | A) Síncrona no handler | B) Outbox + evento (assíncrona) |
|---|---|---|
| Como funciona | Após `SaveChangesAsync` no PostgreSQL, o mesmo handler chama `IGameSearchService.IndexAsync` | Na **mesma transação** do PostgreSQL grava-se uma linha em `outbox_messages` (`GameUpserted`/`GameDeleted`); um *worker* (BackgroundService, MassTransit/Wolverine com outbox, ou fila SQS/RabbitMQ) lê e indexa |
| Complexidade | Baixa | Média |
| Latência da escrita | Aumenta (soma a chamada ao cluster) | Inalterada |
| Consistência | Risco de **dual write**: banco grava e a indexação falha (ou o processo cai entre as duas) → índice desatualizado sem ninguém saber | Garantia de **entrega ao menos uma vez**: se o banco gravou, o evento existe; reprocessa até conseguir |
| Disponibilidade | Se o cluster cair, ou a escrita falha, ou você ignora o erro e perde a sincronização | O CatalogAPI continua aceitando escritas; o índice "alcança" depois |
| Indicada quando | MVP/escopo acadêmico, com *retry* (Polly) e log de falhas | Produção e quando o Tech Challenge já tem mensageria (é o caso de microsserviços da Fase) |

Recomendação: **B (outbox)**, com estes cuidados:

1. **Idempotência:** `_id` = id do jogo; reprocessar o mesmo evento apenas sobrescreve.
2. **Ordem/versões:** eventos podem chegar fora de ordem; use `version_type=external` com uma versão crescente (ex.: `UpdatedAt.Ticks` ou uma coluna `Version`) — uma versão antiga é rejeitada com `409`, que o worker trata como "já processado".
3. **Payload:** o worker pode reler o jogo do PostgreSQL pelo id (garante o estado mais recente e simplifica o evento) e montar o `GameDocument` desnormalizado.
4. **Exclusão:** `GameDeleted` → `DeleteAsync` (ou `isActive=false`, se for *soft delete*).
5. **Reconciliação:** um job/endpoint administrativo de **reindexação completa** (bulk a partir do PostgreSQL para `games-vN` + troca de alias) para corrigir divergências e aplicar mudanças de mapping.
6. **Consistência eventual na UX:** após criar um jogo, ele pode levar de milissegundos a ~1 s (refresh) — ou mais, com fila — para aparecer no `/search`. Documente isso; nos testes de integração, use `refresh=wait_for` ou faça *polling*.

Esboço do lado da escrita (opção B):

```csharp
// Dentro do handler de criação/edição — mesma transação para o jogo e a mensagem de outbox
await using var tx = await db.Database.BeginTransactionAsync(ct);

db.Games.Update(game);
db.OutboxMessages.Add(OutboxMessage.Create(
    type: "GameUpserted",
    payload: JsonSerializer.Serialize(new { GameId = game.Id, Version = game.UpdatedAt.Ticks })));

await db.SaveChangesAsync(ct);
await tx.CommitAsync(ct);

// Cache: invalida após o commit (ver seção seguinte)
await cache.RemoveAsync($"catalog:game:{game.Id}", ct);
```

```csharp
// Worker (BackgroundService) — processa o outbox em lote
var pending = await db.OutboxMessages
    .Where(m => m.ProcessedAt == null)
    .OrderBy(m => m.CreatedAt)
    .Take(100)
    .ToListAsync(ct);

foreach (var msg in pending)
{
    var evt = JsonSerializer.Deserialize<GameChanged>(msg.Payload)!;
    var game = await db.Games.AsNoTracking().FirstOrDefaultAsync(g => g.Id == evt.GameId, ct);

    if (game is null) await search.DeleteAsync(evt.GameId.ToString(), ct);
    else await search.IndexAsync(GameMapper.ToDocument(game), ct);

    msg.ProcessedAt = DateTime.UtcNow;
}
await db.SaveChangesAsync(ct);
// Com muitos itens, prefira a Bulk API (client.BulkAsync) em vez de um IndexAsync por mensagem.
```

### Invalidação do cache Redis junto com a indexação

> **💡 Complemento:**

- **O que fica no Redis:** o padrão *cache-aside* do CatalogAPI para leituras por id/listagens (ex.: `catalog:game:{id}`, `catalog:games:page:{n}`). Resultados do `/search` podem ser cacheados com **TTL curto** (30–120 s) e chave derivada do termo normalizado + página (`catalog:search:{hash(q)}:{page}`), já que o motor de busca já é rápido e o ganho é só para termos "quentes".
- **Quando invalidar:** **depois do commit** no PostgreSQL (nunca antes, para não repopular o cache com o dado antigo entre a invalidação e o commit). Remova a chave do item e as chaves de listagens afetadas.
- **Listagens e buscas:** apagar chaves por padrão (`SCAN` + `DEL`) é custoso; prefira **versionar o namespace** (`catalog:games:v{n}:...` — incrementar `n` no Redis invalida tudo de uma vez) ou confiar no TTL curto para o cache de busca.
- **Com outbox:** o worker pode invalidar o cache do `/search` **após** indexar com sucesso, alinhando cache e índice; a chave do item por id pode ser invalidada já no handler.
- **Nunca** trate o Redis ou o índice de busca como fonte da verdade: em caso de dúvida, a leitura por id vai ao PostgreSQL.

### Checklist do Tech Challenge

- [ ] Domínio gerenciado criado (Amazon OpenSearch Service ou Elastic Cloud), acessível só pelo backend.
- [ ] Índice `games-v1` com mapping explícito + alias `games`.
- [ ] Carga inicial via Bulk a partir do PostgreSQL.
- [ ] Sincronização ao inserir/editar (e excluir) jogo — preferencialmente via outbox.
- [ ] `GET /search?q=&page=&pageSize=` com `multi_match` + `fuzziness: AUTO` + boost no título, ordenado por `_score`.
- [ ] Invalidação do Redis após commit/indexação.
- [ ] Testes: termo com erro de digitação retorna o jogo correto; jogo recém-editado aparece atualizado.
- [ ] Credenciais em *secret store*; logs de falhas de indexação com correlation id.

### Glossário

| Termo | Definição curta |
|---|---|
| **Alias** | Nome lógico que aponta para um ou mais índices; permite trocar o índice físico sem mudar a aplicação. |
| **Analyzer** | Pipeline `char_filter` → `tokenizer` → `token filters` que transforma texto em termos indexáveis. |
| **BM25** | Algoritmo padrão de relevância (TF com saturação, IDF e normalização por comprimento). |
| **Boost** | Multiplicador de peso aplicado a um campo (`title^3`) ou cláusula. |
| **Bulk API** | Endpoint `_bulk` para executar muitas operações de indexação/exclusão em uma requisição (NDJSON). |
| **Cluster / Nó** | Conjunto de servidores (nós) que compartilham dados e carga; nós têm papéis (master, data, ingest, ML). |
| **Documento** | Unidade de dado em JSON, identificada por `_id`, armazenada em um índice. |
| **Doc values** | Estrutura colunar usada em ordenação e agregações. |
| **Edge n-gram** | N-gramas ancorados no início da palavra; base do autocompletar. |
| **Filter context** | Parte da query que só inclui/exclui documentos, sem calcular score; cacheável. |
| **Fuzziness** | Tolerância a erros medida pela distância de edição (Levenshtein); `AUTO` ajusta pelo tamanho do termo. |
| **Highlight** | Trechos do documento com os termos encontrados destacados. |
| **Índice** | Coleção de documentos com mapping e settings próprios, dividida em shards. |
| **Índice invertido** | Estrutura termo → lista de documentos que o contêm; base da busca textual. |
| **Mapping** | Esquema do índice: tipos dos campos e analyzers. |
| **`multi_match`** | Query `match` executada em vários campos (tipos `best_fields`, `most_fields`, `cross_fields`...). |
| **Near real-time (NRT)** | Documentos ficam pesquisáveis após o *refresh* (padrão ~1 s). |
| **OpenSearch** | Fork open source do Elasticsearch 7.10.2 mantido pela comunidade/AWS; base do Amazon OpenSearch Service. |
| **Outbox** | Padrão em que o evento é gravado na mesma transação do dado e publicado depois por um worker. |
| **Query DSL** | Linguagem de consulta em JSON do Elasticsearch/OpenSearch. |
| **Réplica** | Cópia de um shard primário, para tolerância a falhas e leitura paralela. |
| **Shard** | Partição de um índice (um índice Lucene), distribuída entre nós. |
| **Stemização** | Redução de palavras ao radical ("corridas" → "corrid"). |
| **`_score`** | Pontuação de relevância de um documento para uma consulta específica. |
