# Kubernetes (K8s) — Orquestração de Contêineres na Prática

> **Para quem é este material:** você já domina o mundo client-server (PowerBuilder, DataWindows, apps monolíticos sobre banco relacional) e está aprofundando .NET e cloud-native. Aqui o pressuposto é que **Docker/contêineres você já entende** (há um resumo separado). Kubernetes é o passo seguinte: o que fazer quando você não tem 1 contêiner, mas **dezenas ou centenas** deles para administrar.

---

## Visão geral — qual problema o Kubernetes resolve?

No mundo PowerBuilder, quando a carga crescia, a resposta era previsível: **subir mais um servidor de aplicação na mão**, configurar o balanceador, ajustar o cluster do servidor de aplicação (failover), e torcer para que os ambientes (dev/homolog/prod) estivessem "minimamente parecidos". Cada passo era manual, demorado, propenso a erro humano e caro. Quando a Black Friday passava, aquela capacidade extra ficava ociosa — mas você já tinha pago por ela.

Docker resolveu metade do problema: empacotar a aplicação com todas as dependências numa imagem leve e portátil, que roda igual em qualquer lugar. Mas Docker sozinho não responde a perguntas operacionais:

- E se um contêiner **cair às 3h da manhã**? Quem sobe outro no lugar?
- Como rodar **5 réplicas** da mesma API e distribuir o tráfego entre elas?
- Como **atualizar a versão** sem derrubar o serviço para os usuários?
- Como **crescer e encolher** a infraestrutura automaticamente conforme a demanda?
- Como dar a essas réplicas **um único endereço** estável, já que cada contêiner nasce e morre com IP próprio?

**Kubernetes (abreviado K8s — "K", 8 letras, "s") é o orquestrador de contêineres** que automatiza tudo isso. Ele cria, destrói, reposiciona e monitora contêineres a partir de imagens, mantém a infraestrutura operacional e, em caso de falha, **sobe um novo contêiner sozinho** (autocura). É um projeto open-source, originado no Google, hoje mantido pela CNCF.

Os três pilares que justificam adotá-lo:

| Pilar | O que significa | Paralelo com seu mundo |
|---|---|---|
| **Orquestração** | Decide *onde* e *como* cada contêiner roda no conjunto de servidores | Como um "servidor de aplicação cluster", só que declarativo e automatizado |
| **Autocura (self-healing)** | Detecta falha e recria o que caiu, sem intervenção humana | O failover que você montava na mão, agora nativo |
| **Escala declarativa** | Você declara "quero 5 réplicas" e o K8s garante isso 24/7 | Em vez de "subir servidor na mão", você muda um número num arquivo |

> 🏛️ **Observação do Arquiteto** — O conceito-chave para internalizar não é "contêiner". É **estado desejado vs. estado atual**. No mundo imperativo (scripts, PowerBuilder, instaladores), você descreve *os passos*: "faça A, depois B, depois C". No Kubernetes, você descreve **o resultado final** ("quero 3 réplicas desta imagem, expostas na porta 80, com este config") e o cluster trabalha continuamente para fazer a realidade convergir para essa declaração. Se a realidade divergir (um Pod morreu), o K8s **reconcilia** sozinho. Essa mudança de mentalidade — de imperativo para declarativo — é o que mais custa para quem vem de 10+ anos de programação procedural. Vale parar e digerir.

---

## Mapa das aulas (índice)

Este resumo consolida duas trilhas do curso FIAP:

**Trilha conceitual (Pós-Graduação):**

1. [Arquitetura do cluster e o modelo declarativo](#arquitetura-do-cluster)
2. [kubectl e a API do Kubernetes](#kubectl--a-cli-do-cluster)
3. [Pods, rótulos (labels) e anotações](#pods--a-menor-unidade)
4. [Services e ConfigMap](#services--descoberta-de-serviço)
5. [ReplicaSets e Deployments (rollout/rollback)](#replicaset-e-deployment)
6. [Volumes e armazenamento persistente (PV/PVC/StorageClass)](#volumes--armazenamento-persistente)
7. [Probes (liveness, readiness, startup)](#probes--saúde-e-disponibilidade)
8. [HPA — autoescalonamento horizontal](#hpa--autoescalonamento-horizontal)

**Trilha prática na Azure (AKS):**

9. [O que é AKS](#aks--kubernetes-gerenciado-na-azure)
10. [Provisionando o cluster (Resource Group, Azure CLI)](#provisionando-o-cluster)
11. [Operando o AKS (Cloud Shell, deploy, réplicas)](#operando-o-aks-na-prática)
12. [CI/CD para AKS (build → push → deploy)](#cicd-para-aks)

E ainda: [comandos essenciais](#comandos-essenciais-de-kubectl), [erros comuns](#-erros-comuns--armadilhas), [glossário](#glossário-rápido), [como isto se conecta](#-como-isto-se-conecta) e [checklist de domínio](#checklist-de-domínio).

---

## Arquitetura do cluster

Um **cluster** Kubernetes é um grupo de máquinas (físicas ou VMs) chamadas **nodes (nós)**. Há dois papéis:

- **Control Plane** (antigo "Master node") — o cérebro. Toma decisões: onde colocar cada Pod, o que reconciliar, como responder a falhas.
- **Worker nodes** — o músculo. É onde os Pods (seus contêineres) de fato rodam.

```
┌──────────────────────────── CLUSTER ────────────────────────────┐
│                                                                  │
│   ┌─────────────── CONTROL PLANE (cérebro) ────────────────┐     │
│   │  api-server  │  etcd  │  scheduler  │ controller-manager │   │
│   └────────────────────────────────────────────────────────┘     │
│                              │ (instruções via API)               │
│            ┌─────────────────┼─────────────────┐                  │
│   ┌──────────────────┐            ┌──────────────────┐            │
│   │   WORKER NODE 1  │            │   WORKER NODE 2  │            │
│   │ kubelet          │            │ kubelet          │            │
│   │ kube-proxy       │            │ kube-proxy       │            │
│   │ container runtime│            │ container runtime│            │
│   │  ┌────┐ ┌────┐   │            │  ┌────┐          │            │
│   │  │Pod │ │Pod │   │            │  │Pod │   ...     │            │
│   │  └────┘ └────┘   │            │  └────┘          │            │
│   └──────────────────┘            └──────────────────┘            │
└──────────────────────────────────────────────────────────────────┘
```

### Componentes do Control Plane

| Componente | Função | Analogia |
|---|---|---|
| **api-server** | Porta de entrada única do cluster. Tudo (kubectl, dashboards, componentes internos) fala com o cluster via **API REST** (GET/POST/PUT/DELETE). | O "servidor de aplicação" central que recebe todas as requisições |
| **etcd** | Banco de dados **chave-valor distribuído** que guarda *todo* o estado desejado e atual do cluster (a "fonte da verdade"). | O catálogo/repositório de configuração — perdeu o etcd, perdeu o cluster |
| **scheduler** | Decide **em qual node** cada novo Pod vai rodar, considerando recursos disponíveis, afinidades e restrições. | O "balanceador de alocação" que escolhe o servidor menos carregado |
| **controller-manager** | Roda os **controladores** — loops que comparam estado desejado × atual e reconciliam (ex.: "faltam réplicas, crie mais"). | O motor da autocura |

### Componentes do Worker node

| Componente | Função |
|---|---|
| **kubelet** | Agente que roda em cada node. Recebe ordens do api-server e garante que os contêineres do Pod estejam rodando e saudáveis. É ele quem executa as **probes**. |
| **kube-proxy** | Cuida da **rede**: encaminha o tráfego para os Pods certos, viabilizando os Services. |
| **container runtime** | O motor que de fato executa os contêineres (containerd, CRI-O). Docker era o runtime histórico. |

> 🏛️ **Observação do Arquiteto** — Repare no **fluxo declarativo na prática**: você dispara `kubectl apply -f deploy.yaml` → o **api-server** valida e grava o estado desejado no **etcd** → o **controller-manager** percebe que faltam Pods → o **scheduler** escolhe um node → o **kubelet** daquele node sobe o Pod. Nenhuma etapa é "você mandando subir o contêiner". Você só declarou a intenção; a engrenagem de controladores faz o resto, e continua fazendo para sempre. É exatamente esse loop de reconciliação que dá a autocura "de graça".

> 🏛️ **Observação do Arquiteto — evitar SPOF.** Em produção séria, o Control Plane **nunca** roda em uma máquina só. Você quer 3+ instâncias do api-server e um etcd em quórum (3 ou 5 nós), senão o cérebro vira um *single point of failure* (SPOF). Em ambientes gerenciados como o AKS, **a Microsoft opera o Control Plane para você** — você só gerencia (e paga por) os worker nodes. Esse é o grande apelo do "Kubernetes gerenciado" e voltaremos a isso na trilha AKS.

### Ambientes locais para estudo

Para aprender sem nuvem, você não precisa de um cluster real:

- **Minikube** — sobe um cluster de **um único node** dentro de uma VM/contêiner local. Ideal para estudo. (`minikube start` baixa a imagem do K8s e inicia.)
- **Kubernetes do Docker Desktop** — basta habilitar nas configurações; dá um cluster local de um node.

Para **produção**, os caminhos são os Kubernetes gerenciados: **AKS** (Azure), **EKS** (AWS) e **GKE** (Google).

---

## kubectl — a CLI do cluster

O **kubectl** ("kube control") é a ferramenta de linha de comando que fala com o api-server via REST. É instalável em qualquer SO e é a forma mais produtiva de operar o cluster.

Ele descobre **como** se conectar lendo o arquivo **kubeconfig** (por padrão em `~/.kube/config`), que guarda: endereço do api-server, credenciais e o **context** (qual cluster está ativo). Esse detalhe é importante na trilha AKS — o `az aks get-credentials` é justamente o comando que injeta o kubeconfig do seu cluster Azure aqui.

Os verbos centrais são **get** (consultar estado/saúde), **create**/**apply** (criar) e **delete** (remover). Exemplo imperativo rápido:

```bash
# Cria um Pod nginx direto pela linha de comando (modo imperativo, bom para teste rápido)
kubectl run nginx --image=nginx:1.14.2 --port=80

kubectl get pods            # lista os Pods e seus status
kubectl delete pod nginx    # remove o Pod
```

> 🏛️ **Observação do Arquiteto — imperativo vs. declarativo no kubectl.** O `kubectl run ...` acima é prático para um teste, mas é **imperativo** (você mandou criar). Em qualquer coisa séria, **use arquivos YAML versionados no Git** e aplique com `kubectl apply -f`. A diferença é a mesma de "rodar um INSERT manual no banco" versus "ter o script versionado": o YAML é reproduzível, revisável em PR, e descreve o estado desejado completo. Toda a seção seguinte usa essa abordagem declarativa.

---

## Pods — a menor unidade

O **Pod** é a **menor unidade implantável** do Kubernetes — você nunca sobe um contêiner "solto", sempre dentro de um Pod. Um Pod representa **um processo em execução** e contém **um ou mais contêineres** que compartilham:

- o mesmo **espaço de rede** (mesmo IP interno — contêineres dentro do Pod falam entre si por `localhost`);
- o mesmo **armazenamento** (volumes montados no Pod).

Na esmagadora maioria dos casos, **1 Pod = 1 contêiner** (sua API .NET, por exemplo). Múltiplos contêineres no mesmo Pod são para padrões específicos (sidecars: um proxy, um coletor de logs etc.).

Característica fundamental: **Pods são efêmeros**. Nascem e morrem. Quando um Pod morre e o K8s sobe outro, o **novo Pod tem outro IP**. Por isso você nunca aponta um cliente diretamente para o IP de um Pod — é para isso que existem os **Services** (adiante).

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: meu-pod
  labels:
    app: catalog-api      # rótulo: usado para seleção
  annotations:
    author: "Anderson Dias"   # anotação: metadado livre, não selecionável
spec:
  containers:
    - name: meu-container
      image: nginx:1.14.2
      ports:
        - containerPort: 80
```

Anatomia do YAML (vale para quase todo objeto K8s):

- **apiVersion** — versão da API para este tipo de objeto (`v1` para Pod/Service/ConfigMap; `apps/v1` para Deployment/ReplicaSet).
- **kind** — o tipo do objeto (`Pod`, `Service`, `Deployment`...).
- **metadata** — nome, namespace, labels e annotations.
- **spec** — a especificação do *estado desejado*: o que rodar e como.

### Labels (rótulos), seletores e anotações

Os **labels** são pares **chave-valor** anexados a objetos. Eles são o **mecanismo de identificação e agrupamento** do K8s. Exemplo: `app: catalog-api`, `tier: backend`, `env: prod`. Quase tudo no Kubernetes funciona por **seletor de label**:

- Um **Service** descobre quais Pods atender via `selector: { app: catalog-api }`.
- Um **ReplicaSet/Deployment** sabe quais Pods são "seus" pelo mesmo mecanismo.
- Você filtra na CLI: `kubectl get pods -l app=catalog-api`.

As **annotations** também são chave-valor, mas com propósito diferente: **metadados livres não usados para seleção** — autoria, informação de debug, documentação, configuração de ferramentas externas (ex.: anotações que o ingress-controller ou o cert-manager leem). Pense em label como "índice de busca" e annotation como "campo de observações".

> 🏛️ **Observação do Arquiteto — labels são sua espinha dorsal organizacional.** Adote uma convenção de labels desde o dia 1: `app`, `version`, `tier`, `env`, `team`. Isso paga dividendos enormes em consultas, monitoramento (Prometheus agrupa métricas por label), roteamento de tráfego e billing. É o equivalente cloud-native de uma boa convenção de nomenclatura de objetos — algo que você já valoriza por experiência.

---

## Services — descoberta de serviço

O problema: Pods são efêmeros e têm IPs que mudam. Como um cliente (frontend, outra API) encontra de forma **estável** o conjunto de Pods de uma aplicação que está escalando e sendo recriada o tempo todo?

O **Service** é a resposta. Ele é um objeto que:

1. Dá um **endereço estável** (IP virtual + nome DNS interno) para um grupo de Pods.
2. Seleciona os Pods-alvo por **label selector**.
3. **Balanceia carga** distribuindo o tráfego entre os Pods saudáveis automaticamente.

É exatamente o "VIP do balanceador de carga" que você configurava na mão para um cluster de servidores de aplicação — só que aqui ele se mantém sincronizado sozinho conforme Pods entram e saem.

### Os três tipos de Service

| Tipo | Onde é acessível | Quando usar | Paralelo |
|---|---|---|---|
| **ClusterIP** (padrão) | **Apenas dentro do cluster** (IP interno) | Comunicação serviço-a-serviço interna (ex.: UsersAPI chama CatalogAPI) | Rede interna privada da aplicação |
| **NodePort** | Externamente, via `IP-do-node:porta` | Acesso externo simples, testes, on-premise | Abrir uma porta no firewall do servidor |
| **LoadBalancer** | Externamente, via **IP público** de um balanceador da nuvem | Expor uma API/web ao mundo em produção na nuvem | O balanceador de carga corporativo, provisionado automaticamente |

> Existe ainda o **ExternalName** (mapeia o Service para um nome DNS externo, sem proxy) — citado de passagem nas aulas.

```yaml
apiVersion: v1
kind: Service
metadata:
  name: catalog-service
spec:
  type: ClusterIP            # troque por NodePort ou LoadBalancer conforme a exposição
  selector:
    app: catalog-api         # liga este Service a todos os Pods com label app=catalog-api
  ports:
    - port: 80               # porta do Service (como os clientes o acessam)
      targetPort: 8080       # porta que o contêiner expõe
```

**Descoberta de serviço por DNS:** dentro do cluster, um Service vira um nome DNS resolvível. A CatalogAPI pode chamar `http://users-service` (ou o FQDN `users-service.default.svc.cluster.local`) sem nunca saber IPs de Pods. Esse é o **service discovery** nativo — você troca configuração de endereços hardcoded por nomes lógicos estáveis.

> 🏛️ **Observação do Arquiteto — quem expõe o quê.** Numa arquitetura de microsserviços típica (como o FIAP Cloud Games), a maioria dos Services internos é **ClusterIP** (ninguém de fora precisa falar direto com a PaymentsAPI). Você expõe ao mundo **um único ponto de entrada** — idealmente um **Ingress** (um roteador HTTP de camada 7, que faz host/path routing e TLS) na frente de um LoadBalancer, em vez de um LoadBalancer por serviço. As aulas focam nos três tipos de Service; na vida real, Ingress + ClusterIP é o padrão de produção mais econômico e organizado. Menos IPs públicos = menos custo e menos superfície de ataque.

---

## ConfigMap e Secret

No PowerBuilder você guardava configuração em `.ini`, no registry, em tabelas de parâmetros. No Kubernetes, a configuração é **desacoplada da imagem** — você não recompila o contêiner para mudar uma connection string.

O **ConfigMap** armazena configurações **não-sensíveis** como pares chave-valor, de forma centralizada. Pode ser **injetado no contêiner** de três formas:

- como **variáveis de ambiente** (mais comum);
- como **arquivos montados** num volume;
- como **argumentos de linha de comando**.

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: catalog-config
data:
  ASPNETCORE_ENVIRONMENT: "Production"
  FEATURE_FLAG_NOVO_CATALOGO: "true"
```

Injetando num Deployment via `envFrom` (todas as chaves viram variáveis de ambiente):

```yaml
spec:
  containers:
    - name: catalog-api
      image: catalog-api:1.2.0
      envFrom:
        - configMapRef:
            name: catalog-config
```

### Secret — o irmão para dados sensíveis

Para **connection strings, senhas, chaves de API, tokens**, use **Secret** em vez de ConfigMap. A estrutura é parecida, mas o Secret é tratado como sensível (valores em base64, com controle de acesso mais restrito e integração com cofres externos).

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: catalog-db
type: Opaque
stringData:
  ConnectionStrings__Default: "Server=sql;Database=catalog;User Id=app;Password=..."
```

> 🏛️ **Observação do Arquiteto — Secret não é cofre.** Atenção: por padrão, um Secret é apenas **base64**, não criptografia. Base64 é codificação, não segredo — qualquer um com acesso ao objeto lê o valor. Em produção: (1) habilite **encryption at rest** no etcd; (2) restrinja acesso via **RBAC**; (3) idealmente integre com um cofre real (**Azure Key Vault** via CSI driver, HashiCorp Vault). E o óbvio que muita gente esquece: **nunca** commite o YAML de um Secret com valor real no Git. Use Secrets do GitHub/pipeline para injetar em deploy — exatamente o que a aula de CI/CD faz com o kubeconfig e as credenciais do Docker Hub.

---

## ReplicaSet e Deployment

### ReplicaSet — garantir N réplicas

O **ReplicaSet** garante que **um número específico de réplicas** de um Pod esteja rodando **a todo momento**. Ele monitora os Pods (selecionados por label) e, se uma réplica cair (crash), **sobe outra para repor**. É a autocura aplicada à contagem de réplicas.

```yaml
apiVersion: apps/v1
kind: ReplicaSet
metadata:
  name: nginx-fiap
spec:
  replicas: 3                 # estado desejado: sempre 3 Pods vivos
  selector:
    matchLabels:
      app: nginx-app
  template:                   # o "molde" do Pod a ser replicado
    metadata:
      labels:
        app: nginx-app
    spec:
      containers:
        - name: nginx
          image: nginx:1.14.2
          ports:
            - containerPort: 80
```

Se você tem 3 réplicas e uma morre, o ReplicaSet detecta o desvio (atual=2 ≠ desejado=3) e cria uma nova. Aquele cluster de servidores de aplicação com failover manual? Agora é uma linha: `replicas: 3`.

### Deployment — o que você realmente usa

Na prática você **quase nunca cria um ReplicaSet diretamente**. Você cria um **Deployment**, que **gerencia ReplicaSets por você** e adiciona o que faltava: **controle de versão da aplicação**. O YAML é praticamente idêntico ao do ReplicaSet (só muda `kind: Deployment`), mas o Deployment entrega:

- **Rolling Update** — ao mudar a imagem (ex.: `1.2.0` → `1.3.0`), o Deployment cria um **novo ReplicaSet** com a nova versão e **substitui os Pods gradualmente**, alguns de cada vez, **sem derrubar o serviço**. Em nenhum instante você fica com zero réplicas servindo.
- **Rollback** — deu problema na nova versão? `kubectl rollout undo` volta para a versão anterior. O Deployment guarda o histórico de revisões.
- **Dimensionamento horizontal** — aumentar/diminuir réplicas conforme demanda (`kubectl scale` ou via HPA).

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: catalog-api
spec:
  replicas: 3
  selector:
    matchLabels:
      app: catalog-api
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxUnavailable: 1       # no máximo 1 Pod fora durante o update
      maxSurge: 1             # pode criar 1 Pod a mais temporariamente
  template:
    metadata:
      labels:
        app: catalog-api
    spec:
      containers:
        - name: catalog-api
          image: meurepo/catalog-api:1.3.0
          ports:
            - containerPort: 8080
```

Comandos do ciclo de vida de um Deployment:

```bash
kubectl apply -f deployment.yaml          # cria/atualiza
kubectl set image deployment/catalog-api catalog-api=meurepo/catalog-api:1.3.0  # nova versão
kubectl rollout status deployment/catalog-api   # acompanha o rolling update
kubectl rollout history deployment/catalog-api  # vê as revisões
kubectl rollout undo deployment/catalog-api     # ROLLBACK para a revisão anterior
kubectl scale deployment/catalog-api --replicas=5   # escala manualmente
```

> 🏛️ **Observação do Arquiteto — rolling update só é "sem downtime" se houver readiness probe.** O Deployment promete substituição gradual sem interromper o serviço — mas ele só sabe que um Pod novo está "pronto" se você tiver configurado uma **readiness probe** (próxima seção). Sem ela, o K8s considera o Pod pronto assim que o processo sobe, e começa a mandar tráfego para uma aplicação que ainda está carregando (subindo EF Core, abrindo pool de conexões, fazendo warm-up). Resultado: erros 500 durante todo deploy. Deployment + readiness probe são **um par inseparável** em produção.

> **Teste de carga:** as aulas usam o **K6** (e citam o JMeter) para gerar carga e observar a escala/replicação reagindo. Útil para validar tanto rolling updates quanto HPA antes de produção.

---

## Volumes — armazenamento persistente

Contêineres (e Pods) são **efêmeros**: quando morrem, **o sistema de arquivos interno vai junto**. Para um stateless web service isso é ótimo. Mas e um banco de dados em contêiner? Se o Pod cai e sobe de novo, **os dados sumiriam**. Volumes resolvem isso desacoplando o armazenamento do ciclo de vida do contêiner.

### Tipos de Volume básicos

| Tipo | Vida útil | Uso |
|---|---|---|
| **emptyDir** | Criado quando o Pod inicia, **apagado quando o Pod morre** | Cache temporário, troca de arquivos entre contêineres do mesmo Pod |
| **hostPath** | Monta um diretório do **node** dentro do contêiner | Acessar arquivos do nó (cuidado: amarra o Pod a um node específico) |
| **persistentVolumeClaim** | **Sobrevive** à morte/recriação do Pod | Dados que precisam persistir (bancos, uploads) |

```yaml
spec:
  containers:
    - name: app
      image: nginx
      volumeMounts:
        - name: cache-temp
          mountPath: /cache
  volumes:
    - name: cache-temp
      emptyDir: {}             # zerado a cada morte do Pod
```

### PV, PVC e StorageClass — o modelo de armazenamento durável

Para persistência de verdade, o K8s separa **quem fornece** o armazenamento de **quem consome**:

- **PersistentVolume (PV)** — uma "peça" de armazenamento **provisionada no cluster** (por um admin ou automaticamente), com ciclo de vida **independente do Pod**. Pode ser NFS, iSCSI, **AWS EBS**, Azure Disk etc.
- **PersistentVolumeClaim (PVC)** — uma **requisição** de armazenamento feita pela aplicação: "preciso de 10Gi, modo leitura-escrita". O K8s então **associa o PVC a um PV existente** ou **provisiona um novo** sob demanda.
- **StorageClass (SC)** — define **classes/perfis** de armazenamento (Standard, SSD, SAN...) com políticas de desempenho e provisionamento dinâmico. O PVC pede uma StorageClass e o PV certo é criado automaticamente.

Pense assim: a aplicação fala "preciso de espaço" (PVC) sem se preocupar com *qual* disco físico; o cluster casa isso com um PV real, guiado pela StorageClass. É a **separação dev × infra**: o dev declara a necessidade, a plataforma entrega o storage.

```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: dados-postgres
spec:
  accessModes:
    - ReadWriteOnce          # montável por 1 node para leitura/escrita
  storageClassName: managed-premium   # ex.: SSD gerenciado na Azure
  resources:
    requests:
      storage: 10Gi
```

**Modos de acesso (PVC):**

- **ReadWriteOnce (RWO)** — um único node lê e escreve. Caso típico de banco.
- **ReadOnlyMany (ROX)** — vários nodes leem (somente leitura).
- **ReadWriteMany (RWX)** — vários nodes leem e escrevem (exige storage que suporte, tipo NFS/Azure Files).

> 🏛️ **Observação do Arquiteto — banco de dados no K8s? Pense duas vezes.** É *possível* rodar banco no Kubernetes (com PVs e StatefulSets — objeto além do escopo das aulas, mas que é o correto para cargas com estado, pois dá identidade estável e ordem aos Pods). Mas para a maioria dos times, **banco gerenciado** (Azure SQL, RDS, Cloud SQL) é mais simples, seguro e confiável: backup, replicação, failover e patching ficam por conta do provedor. Reserve o cluster para os serviços **stateless** (suas APIs .NET) — que escalam horizontalmente sem dor — e deixe o **estado** num serviço gerenciado. Isso simplifica enormemente operação, escala e recuperação de desastre.

---

## Probes — saúde e disponibilidade

Como o cluster sabe se sua aplicação está **viva**, **pronta** ou **ainda subindo**? Pelas **probes** (sondas de saúde), definidas no manifesto do Pod e executadas pelo **kubelet**. Por padrão fazem um `HTTP GET` num endpoint e esperam **200 OK** (também há probes **TCP** — porta aberta — e **Exec** — rodar um comando).

| Probe | Pergunta que responde | Ação em caso de falha |
|---|---|---|
| **Liveness** | "A aplicação está **viva** e respondendo?" | **Reinicia o Pod** (mata e recria o contêiner) |
| **Readiness** | "A aplicação está **pronta** para receber tráfego?" | **Remove o Pod do balanceador** (Service para de mandar tráfego), sem matar |
| **Startup** | "A aplicação **terminou de iniciar**?" | Segura liveness/readiness até a partida concluir; se estourar, reinicia |

A distinção **liveness × readiness** é a mais importante:

- **Liveness** detecta **travamento permanente** (deadlock, loop infinito). A aplicação "está rodando" mas não responde mais — só um restart resolve.
- **Readiness** detecta **indisponibilidade temporária**: a app está viva, mas ainda não pode atender (carregando dados, abrindo conexão com o banco, fazendo warm-up). Tirar do balanceador temporariamente é melhor que mandar tráfego e tomar erro.
- **Startup** existe para apps de **partida lenta**: sem ela, uma liveness agressiva poderia matar o Pod *antes* dele terminar de subir, num loop infinito de reinício. A startup dá um período de carência.

```yaml
spec:
  containers:
    - name: exemplo-container
      image: exemplo:1.0
      ports:
        - containerPort: 80
      livenessProbe:
        httpGet:
          path: /health/live
          port: 80
        periodSeconds: 10
        timeoutSeconds: 5
      readinessProbe:
        httpGet:
          path: /health/ready
          port: 80
        periodSeconds: 5
        timeoutSeconds: 3
      startupProbe:
        httpGet:
          path: /health/startup
          port: 80
        initialDelaySeconds: 120
        periodSeconds: 30
        timeoutSeconds: 10
```

**Boas práticas das aulas:** use as **três** probes; **endpoints diferentes** para cada uma (evita conflito); ajuste intervalos conforme a carga/importância da app; comece com os padrões e só refine com cuidado; **teste** e **monitore** as probes (Prometheus); documente as configurações.

> 🏛️ **Observação do Arquiteto — no .NET isso é praticamente de graça.** O ASP.NET Core tem **Health Checks** nativos (`AddHealthChecks()`), com pacotes prontos para checar EF Core, SQL Server, RabbitMQ, Redis etc. Você expõe `/health/live` (liveness — só "o processo respira?") e `/health/ready` (readiness — "consigo falar com banco e fila?") e aponta as probes para eles. **Cuidado com um erro clássico:** **não** coloque a checagem do banco na *liveness*. Se o banco piscar, todas as réplicas falham a liveness ao mesmo tempo, o K8s **reinicia todas** em cascata, e você transforma uma indisponibilidade de banco numa queda total da aplicação. Dependências externas pertencem à **readiness**, não à liveness.

---

## HPA — autoescalonamento horizontal

O **Horizontal Pod Autoscaler (HPA)** ajusta **automaticamente o número de réplicas** de um Deployment com base em **métricas de utilização**. Quando o uso passa do limite que você definiu, ele **cria** réplicas; quando cai, ele **remove** réplicas para economizar recursos. É a "escala elástica" da Black Friday resolvida sem ninguém de plantão.

- **Escala horizontal** (do HPA): adicionar/remover **Pods** (mais cópias). É o que K8s faz bem e barato.
- **Escala vertical**: dar **mais CPU/RAM** ao mesmo Pod/máquina. Tem limite físico e geralmente exige reinício.

**Métricas suportadas:** **CPU** (a mais comum), **memória**, **métricas personalizadas** (definidas pela app — ex.: requisições/seg, profundidade de fila), **métricas externas** (de sistemas como **Prometheus**) e até **E/S de disco**.

```yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: catalog-hpa
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: catalog-api          # qual Deployment escalar
  minReplicas: 1
  maxReplicas: 10
  metrics:
    - type: Resource
      resource:
        name: cpu
        target:
          type: Utilization
          averageUtilization: 70   # alvo: manter CPU média em ~70%
```

Esse HPA mantém as réplicas entre **1 e 10**, mirando **70% de CPU**. Você valida gerando carga (K6/JMeter) e observando: `kubectl get hpa`. Conforme a carga sobe, o número de réplicas sobe; ao reduzir a carga, ele encolhe de volta.

### Requests e limits — o pré-requisito que ninguém vê

O HPA por CPU **só funciona** se cada contêiner declarar **resource requests**. "70% de CPU" é 70% **de quê**? Da quantia que você reservou no `requests`. Sem isso, o HPA não tem denominador e não escala.

```yaml
resources:
  requests:        # o que o Pod RESERVA (o scheduler usa isso para alocar) e a base do %
    cpu: "250m"    # 250 milicores = 0,25 de um núcleo
    memory: "256Mi"
  limits:          # o TETO que o Pod pode usar
    cpu: "500m"
    memory: "512Mi"
```

> 🏛️ **Observação do Arquiteto — requests/limits na prática.** Este é o ajuste operacional **mais subestimado** do Kubernetes:
> - **requests** é o que o **scheduler** usa para decidir em qual node cabe o Pod, e a base de cálculo do HPA. Subestimou? O node fica superlotado e tudo briga por CPU. Superestimou? Você desperdiça (e paga por) capacidade ociosa.
> - **limit de memória** estourado = o Pod leva **OOMKilled** (morto pelo kernel). Em .NET, configure o runtime ciente do limite do contêiner para o GC se comportar bem.
> - **limit de CPU** não mata: ele **estrangula (throttle)** o processo, degradando latência de forma silenciosa — péssimo de diagnosticar.
>
> **Noisy neighbor:** um Pod **sem limits** pode consumir toda a CPU/RAM do node e degradar os vizinhos — o equivalente cloud-native daquele job que travava o servidor de aplicação inteiro. Definir requests/limits é o que dá **isolamento de recursos** e previsibilidade. Comece conservador, **meça** (métricas reais), e ajuste. E combine **HPA + readiness probe**: HPA cria réplicas, readiness garante que só recebam tráfego quando prontas.

---

## Comandos essenciais de kubectl

```bash
# --- APLICAR / CRIAR (declarativo) ---
kubectl apply -f deployment.yaml          # cria ou atualiza a partir do YAML
kubectl apply -f ./manifests/             # aplica todos os YAMLs de uma pasta

# --- CONSULTAR ESTADO ---
kubectl get pods                          # lista Pods
kubectl get pods -o wide                  # com node e IP de cada Pod
kubectl get pods -l app=catalog-api       # filtra por label
kubectl get deployments,services,hpa      # vários tipos de uma vez
kubectl get all                           # panorama geral do namespace

# --- DIAGNOSTICAR ---
kubectl describe pod <nome>               # eventos, probes, motivo de falha (essencial p/ debug)
kubectl logs <pod>                        # logs do contêiner
kubectl logs <pod> -f                     # logs em tempo real (follow)
kubectl logs <pod> --previous             # logs do contêiner ANTERIOR (após um crash)

# --- INTERAGIR / DEPURAR ---
kubectl exec -it <pod> -- /bin/bash       # abre shell DENTRO do contêiner
kubectl port-forward <pod> 8080:80        # túnel da sua máquina para o Pod

# --- ATUALIZAR / ESCALAR ---
kubectl rollout status deployment/<nome>  # acompanha um deploy
kubectl rollout undo deployment/<nome>    # ROLLBACK
kubectl scale deployment/<nome> --replicas=5

# --- REMOVER ---
kubectl delete -f deployment.yaml         # remove o que o YAML declarou
kubectl delete pod <nome>

# --- CONTEXTO / NAMESPACE ---
kubectl config get-contexts               # quais clusters você tem
kubectl get ns                            # lista namespaces
kubectl get pods -n payments              # opera num namespace específico
```

> 🏛️ **Observação do Arquiteto — `describe` é seu melhor amigo.** Quando um Pod não sobe (fica em `Pending`, `CrashLoopBackOff`, `ImagePullBackOff`), o `kubectl describe pod` mostra na seção **Events** o motivo exato: imagem não encontrada, sem CPU disponível no cluster, probe falhando, Secret faltando. É o primeiro lugar para olhar — antes de mexer em qualquer YAML.

---

## AKS — Kubernetes gerenciado na Azure

Operar um cluster Kubernetes "do zero" (manter Control Plane, etcd em quórum, upgrades, patches de segurança) é trabalho de time de plataforma dedicado. O **Azure Kubernetes Service (AKS)** é o **Kubernetes gerenciado** da Microsoft: **a Azure opera o Control Plane para você** (de graça, inclusive) — você só gerencia e paga pelos **worker nodes**. Equivalentes em outras nuvens: **EKS** (AWS) e **GKE** (Google).

O que o AKS entrega pronto: provisionamento do cluster, integração com identidade (Azure AD/Entra), monitoramento (Azure Monitor), upgrades coordenados, escala dos node pools e integração com o registro de imagens **ACR (Azure Container Registry)** — o "Docker Hub privado" da Azure.

### Provisionando o cluster

Ferramentas envolvidas:

- **Azure Portal** — interface gráfica para criar o cluster com cliques.
- **Azure CLI (`az`)** — ferramenta de linha de comando **multiplataforma** (Windows/macOS/Linux), interoperável com Bash/PowerShell/Python, com autenticação integrada (inclui MFA). É a forma scriptável/automatizável.
- **Resource Group (Grupo de Recursos)** — **container lógico** que agrupa recursos relacionados (cluster, IPs, discos, ACR...). Benefícios: organização lógica, gerenciamento e **exclusão unificada** (apaga o grupo, apaga tudo dentro — ótimo para limpar ambiente e **evitar custos**), controle de acesso e **billing agregado** por grupo. Recursos de um mesmo grupo normalmente ficam **na mesma região** (menor latência).

Fluxo típico de criação via CLI:

```bash
# 1. Autenticar na Azure
az login

# 2. Criar o Resource Group (organiza tudo)
az group create --name rg-fiap-games --location brazilsouth

# 3. Criar o cluster AKS (2 nós, monitoramento ligado, ACR anexado)
az aks create \
  --resource-group rg-fiap-games \
  --name aks-fiap-games \
  --node-count 2 \
  --enable-addons monitoring \
  --attach-acr acrfiapgames \
  --generate-ssh-keys

# 4. Baixar as credenciais — isso popula seu kubeconfig e aponta o kubectl para o AKS
az aks get-credentials --resource-group rg-fiap-games --name aks-fiap-games

# 5. A partir daqui é Kubernetes normal:
kubectl get nodes
```

> A integração **`--attach-acr`** dá ao cluster permissão de puxar imagens do seu **ACR privado** sem ter que gerenciar credenciais de pull manualmente. É o "elo" entre onde você guarda imagens e onde elas rodam.

### Operando o AKS na prática

O **Cloud Shell** (botão de terminal no Portal Azure) é um shell **no navegador**, pré-configurado com `az`, `kubectl` e outras ferramentas — **sem instalar nada** na sua máquina. Oferece Bash ou PowerShell e um armazenamento temporário persistente atrelado à sua conta. Ótimo para operar de qualquer dispositivo.

Fluxo prático típico das aulas (deploy de uma API no AKS):

```bash
# Conecta o kubectl ao cluster (já feito pelo get-credentials)
kubectl apply -f app-deployment.yaml      # sobe Deployment + Service (LoadBalancer)
kubectl get service                       # pega o EXTERNAL-IP do LoadBalancer (pode levar 1-2 min)
curl http://<EXTERNAL-IP>/weatherforecast # testa a API publicada
kubectl get pods                          # vê as réplicas rodando

# Atualizar a aplicação:
#  - altera o código, gera nova imagem, faz push pro registro (Docker Hub/ACR)
#  - aponta o YAML para a nova tag e re-aplica:
kubectl apply -f app-deployment.yaml
kubectl scale deployment/app --replicas=2 # ajusta réplicas e observa o K8s reconciliar

# Limpeza (evitar custos!):
kubectl delete deployment app
kubectl delete service app-service
```

As aulas reforçam o porquê das **réplicas**, agora no contexto AKS: **escala horizontal** (acompanhar tráfego), **alta disponibilidade** (se uma réplica cai, as outras atendem), **balanceamento de carga** (o Service distribui), **rolling updates** (atualizar sem downtime), **failover/recuperação** (réplica morta → K8s sobe outra em outro node), **rede** (cada réplica com IP próprio, abstraída pelo Service) e **gerenciamento de config** compartilhada via **ConfigMap/Secret**.

> 🏛️ **Observação do Arquiteto — sempre limpe o ambiente.** Na nuvem você paga por hora de node, por IP público do LoadBalancer, por disco provisionado. O `az group delete --name rg-fiap-games` apaga **tudo** de uma vez ao terminar o estudo. Esquecer um cluster ligado no fim de semana é a fatura surpresa clássica de quem está aprendendo. Use o Resource Group como "interruptor geral".

---

## CI/CD para AKS

A última aula fecha o ciclo: **automatizar build → push → deploy**. Em vez de rodar `docker build` e `kubectl apply` na mão a cada mudança, um **pipeline** faz isso sozinho a cada `push` no Git.

Conceitos:

- **CI (Integração Contínua)** — integrar **pequenas alterações com frequência** ao repositório compartilhado, com **testes automatizados** rodando a cada mudança, para pegar bugs cedo. O **Pull Request (PR)** é o ponto de revisão: colegas revisam, o CI roda testes no código proposto, e só depois de aprovado ocorre o **merge** na branch principal.
- **CD (Entrega Contínua)** — estende a CI **automatizando a implantação**: após integrar com sucesso, o código é implantado (teste, homologação, eventualmente produção) de forma **consistente e repetível**, com suporte a **rollback seguro**.

A ferramenta usada nas aulas é o **GitHub Actions** — automação de CI/CD integrada ao próprio GitHub, acionada por **gatilhos** (ex.: `push` na branch `main`).

### O fluxo do pipeline

```
   git push (branch main)
          │
          ▼
   ┌──────────────────── GitHub Actions ────────────────────┐
   │  1. Checkout do código                                 │
   │  2. (CI) Build + testes automatizados (.NET)           │
   │  3. docker build  → cria a imagem da API               │
   │  4. login no registro (Docker Hub / ACR) via Secret    │
   │  5. docker push   → envia a imagem versionada          │
   │  6. (CD) kubectl apply usando o kubeconfig (via Secret)│
   └────────────────────────┬───────────────────────────────┘
                            │  deploy
                            ▼
                  ┌──────────────────┐
                  │   Cluster AKS    │  ← rolling update das réplicas
                  └──────────────────┘
```

Peças concretas que a aula configura:

- **kubeconfig** gerado via `az aks get-credentials` — autentica o pipeline contra o cluster.
- **GitHub Secrets** — guardam de forma segura o **kubeconfig** e as **credenciais do Docker Hub** (nunca em texto plano no repo).
- **Workflow** (arquivo YAML em `.github/workflows/`) — define os passos: build da imagem, login no registro, push, e `kubectl apply` no AKS.
- **Gatilho automático** — o pipeline dispara em `push` na branch principal → **entrega contínua** das mudanças.

Esboço de um workflow (ilustrativo, consolidando o fluxo das aulas):

```yaml
name: CI-CD-AKS
on:
  push:
    branches: [ main ]
jobs:
  build-and-deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Login no Docker Hub
        uses: docker/login-action@v3
        with:
          username: ${{ secrets.DOCKERHUB_USER }}
          password: ${{ secrets.DOCKERHUB_TOKEN }}

      - name: Build e push da imagem
        run: |
          docker build -t meurepo/catalog-api:${{ github.sha }} .
          docker push meurepo/catalog-api:${{ github.sha }}

      - name: Configurar kubeconfig
        run: echo "${{ secrets.KUBECONFIG }}" > $HOME/.kube/config

      - name: Deploy no AKS
        run: |
          kubectl set image deployment/catalog-api \
            catalog-api=meurepo/catalog-api:${{ github.sha }}
          kubectl rollout status deployment/catalog-api
```

**Tendências de CI/CD citadas nas aulas:** Infraestrutura como Código (IaC); CI/CD para microsserviços/contêineres; **segurança no pipeline** (scan de vulnerabilidades); **CI/CD como código** (pipeline versionado); observabilidade/monitoramento contínuo; testes inteligentes; **implantação progressiva e Blue-Green**; e multicloud/hybrid.

> 🏛️ **Observação do Arquiteto — versione a imagem, nunca dependa de `latest`.** Repare no `${{ github.sha }}` acima: cada build gera uma tag **imutável e rastreável** (o hash do commit). Isso é deliberado. Com `latest`, dois deploys "iguais" podem rodar imagens diferentes, rollback fica impossível ("voltar para qual latest?") e você perde rastreabilidade. **Tag imutável por commit/versão** é a base de um rollback confiável e auditável — exatamente o tipo de disciplina de versionamento que você já pratica com releases de software.

---

## ⚠️ Erros comuns / armadilhas

| Armadilha | O que acontece | Como evitar |
|---|---|---|
| **Sem readiness probe** | O Service manda tráfego para Pods que ainda estão subindo → erros 500 durante todo deploy/escala | Sempre configure readiness apontando para um endpoint que valide as dependências críticas |
| **Banco na liveness probe** | Banco pisca → todas as réplicas falham liveness → K8s reinicia todas em cascata → queda total | Dependências externas vão na **readiness**, nunca na liveness |
| **Sem requests/limits** | "Noisy neighbor": um Pod devora a CPU/RAM do node e degrada os vizinhos; HPA por CPU não funciona | Defina requests (base do scheduler e do HPA) e limits (teto de isolamento) em todo contêiner |
| **Limit de memória apertado** | Pod morre com **OOMKilled** sob carga | Meça o consumo real; configure o GC do .NET ciente do limite do contêiner |
| **Tag `latest`** | Deploys não reproduzíveis; rollback impossível; sem rastreabilidade | Tag imutável por commit/versão semântica |
| **Apontar cliente para IP de Pod** | IP muda quando o Pod é recriado → quebra | Sempre acesse via **Service** (nome DNS estável) |
| **Secret tratado como seguro só por estar em Secret** | Base64 não é criptografia; vaza fácil | Encryption at rest no etcd, RBAC restrito, Key Vault; nunca commitar Secret no Git |
| **Control Plane / etcd em nó único** | SPOF: cérebro cai → cluster inteiro inoperante | Control Plane em HA (3+); ou use gerenciado (AKS opera por você) |
| **Esquecer de limpar recursos na nuvem** | Fatura surpresa (nodes, LoadBalancer, discos rodando ociosos) | `az group delete` ao fim do estudo; use o Resource Group como interruptor geral |
| **Rodar tudo no namespace `default`** | Bagunça: dev, prod e times misturados, sem isolamento | Use **namespaces** por ambiente/time; aplique RBAC e quotas por namespace |
| **Esperar magia de stateful** | Tratar banco em contêiner como stateless → perda de dados | Use PV/PVC + StatefulSet, ou (melhor) banco gerenciado |

---

## Glossário rápido

| Termo | Definição curta |
|---|---|
| **Cluster** | Conjunto de máquinas (nodes) que o K8s gerencia como uma unidade |
| **Node** | Uma máquina (VM/física) do cluster; onde os Pods rodam |
| **Control Plane** | Cérebro do cluster (api-server, etcd, scheduler, controller-manager) |
| **api-server** | Porta de entrada REST; tudo passa por ele |
| **etcd** | Banco chave-valor que guarda o estado do cluster (fonte da verdade) |
| **scheduler** | Decide em qual node cada Pod roda |
| **controller-manager** | Roda os loops de reconciliação (estado desejado × atual) |
| **kubelet** | Agente em cada node; garante os Pods rodando e executa probes |
| **kube-proxy** | Roteamento de rede que viabiliza os Services |
| **Pod** | Menor unidade implantável; 1+ contêineres compartilhando rede e storage |
| **Label** | Par chave-valor para identificar/agrupar/selecionar objetos |
| **Annotation** | Metadado livre, não usado para seleção |
| **Selector** | Filtro por labels (como Services/ReplicaSets acham seus Pods) |
| **ReplicaSet** | Garante N réplicas de um Pod vivas a todo momento |
| **Deployment** | Gerencia ReplicaSets + versionamento (rolling update, rollback) |
| **Rolling Update** | Substituição gradual de Pods numa atualização, sem downtime |
| **Rollback** | Voltar para a revisão anterior do Deployment |
| **Service** | Endereço estável + balanceamento para um grupo de Pods |
| **ClusterIP / NodePort / LoadBalancer** | Service interno / via porta do node / via IP público da nuvem |
| **Ingress** | Roteador HTTP L7 (host/path, TLS) na frente dos Services |
| **ConfigMap** | Configuração não-sensível injetada no Pod |
| **Secret** | Configuração sensível (base64; proteger com RBAC/encryption/Key Vault) |
| **Volume** | Armazenamento montado no Pod (emptyDir, hostPath, PVC...) |
| **PV / PVC / StorageClass** | Armazenamento provisionado / requisição de armazenamento / perfil de storage |
| **Probe** | Sonda de saúde: liveness (viva), readiness (pronta), startup (subindo) |
| **HPA** | Autoescalonamento horizontal por métricas (CPU/memória/custom) |
| **requests / limits** | Recurso reservado / teto de uso por contêiner |
| **Namespace** | Partição lógica do cluster (isolamento por ambiente/time) |
| **kubectl** | CLI que fala com o api-server |
| **kubeconfig** | Arquivo com endereço, credenciais e contexto do cluster |
| **AKS / EKS / GKE** | Kubernetes gerenciado na Azure / AWS / Google |
| **ACR** | Azure Container Registry (registro de imagens privado) |
| **Resource Group** | Container lógico de recursos na Azure (org, billing, exclusão unificada) |
| **CI / CD** | Integração contínua / Entrega contínua |

---

## 🔗 Como isto se conecta

**↔ Docker.** Kubernetes **orquestra** o que o Docker **empacota**. Docker cria a imagem (Dockerfile → imagem → registro). Kubernetes pega essa imagem e a roda em escala, com réplicas, autocura, rede e atualização sem downtime. O `image:` nos YAMLs deste resumo aponta exatamente para imagens que você construiu no resumo de Docker. Sem Docker, não há o que orquestrar; sem K8s, você administra contêineres na mão.

**↔ Microsserviços.** Kubernetes é a casa natural dos microsserviços. Cada serviço vira um **Deployment + Service** próprio, escala de forma independente (HPA por serviço), tem seu ciclo de deploy isolado (rolling update sem afetar os demais) e se descobre por **DNS interno** (ClusterIP). A organização por **labels** e **namespaces** mapeia diretamente a topologia de serviços e times.

**↔ Mensageria.** Numa arquitetura orientada a eventos, **consumers** de fila (RabbitMQ, Service Bus, Kafka) rodam como Deployments no cluster e escalam pela **profundidade da fila** — um caso clássico de **HPA com métrica customizada/externa** (em vez de CPU). O broker pode rodar no cluster (com PV/StatefulSet) ou, mais comum, como serviço gerenciado. As probes garantem que um consumer só receba mensagens quando estiver realmente pronto (readiness).

**↔ Projeto FIAP Cloud Games.** O projeto tem os microsserviços **UsersAPI, CatalogAPI, PaymentsAPI e NotificationsAPI**. O caminho cloud-native:

1. Cada API → uma imagem Docker, publicada no **ACR/Docker Hub**.
2. Cada uma → um **Deployment** (com réplicas) + **Service ClusterIP** interno.
3. Comunicação interna por **DNS de Service** (ex.: PaymentsAPI chama `http://users-service`).
4. **NotificationsAPI** consumindo eventos de fila → escala por HPA conforme o volume de mensagens.
5. Configuração via **ConfigMap**; connection strings e chaves via **Secret** (idealmente Key Vault).
6. Banco em **serviço gerenciado** (Azure SQL), não no cluster.
7. **Ingress** único na frente, expondo só o necessário ao mundo.
8. **Health Checks** do ASP.NET Core ligados às **probes**.
9. **GitHub Actions** fazendo build → push → deploy no **AKS** a cada merge na `main`.

---

## Checklist de domínio

Marque o que você já consegue explicar/fazer sem consultar:

- [ ] Explicar **por que** Kubernetes existe (orquestração, autocura, escala declarativa)
- [ ] Descrever o modelo **declarativo** (estado desejado × atual, loop de reconciliação)
- [ ] Nomear os componentes do **Control Plane** e dos **Worker nodes** e o que cada um faz
- [ ] Escrever um YAML de **Pod** e explicar `apiVersion/kind/metadata/spec`
- [ ] Diferenciar **label** de **annotation** e usar **selectors**
- [ ] Explicar por que se usa **Deployment** e não ReplicaSet/Pod direto
- [ ] Executar e narrar um **rolling update** e fazer **rollback**
- [ ] Escolher entre **ClusterIP / NodePort / LoadBalancer** e justificar
- [ ] Explicar **descoberta de serviço** por DNS interno
- [ ] Injetar config via **ConfigMap** e proteger segredos com **Secret** (e suas limitações)
- [ ] Explicar **PV / PVC / StorageClass** e quando persistir (ou usar banco gerenciado)
- [ ] Configurar as **três probes** e dizer a ação de cada uma na falha
- [ ] Configurar **HPA** e explicar a dependência de **requests/limits**
- [ ] Diagnosticar um Pod travado com `describe` / `logs` / `exec`
- [ ] Provisionar um **cluster AKS** (Resource Group, Azure CLI, get-credentials)
- [ ] Montar um **pipeline CI/CD** (build → push → deploy) no GitHub Actions
- [ ] Listar as principais **armadilhas** (readiness, limits, latest, SPOF, limpeza)

## Próximos passos

1. **Mão na massa local:** suba **Minikube** ou o K8s do Docker Desktop e faça o ciclo completo de um dos serviços do FIAP Cloud Games: Deployment → Service → ConfigMap/Secret → probes → HPA.
2. **Gere carga** com **K6** e observe o HPA escalando — é o "momento aha" da escala declarativa.
3. **Provisione um AKS** pequeno, faça `az aks get-credentials`, publique um serviço com Service `LoadBalancer`, teste via `curl`, e **apague o Resource Group** ao terminar.
4. **Monte o pipeline** GitHub Actions (build → push → deploy) com Secrets para kubeconfig e registro.
5. **Aprofunde além das aulas:** **Ingress** (roteamento L7 + TLS), **StatefulSet** (cargas com estado), **RBAC** (segurança de acesso), **Namespaces + ResourceQuotas** (organização e governança), e **Helm** (empacotar/parametrizar seus manifests). Esses são os próximos degraus naturais para operar Kubernetes em produção de verdade.

> 🏛️ **Observação final do Arquiteto — quando NÃO usar Kubernetes.** Kubernetes é poderoso, mas tem **custo de complexidade alto**. Para uma única aplicação, um monolito modesto, ou uma equipe pequena sem necessidade real de escala elástica, K8s costuma ser **overkill** — você passa mais tempo operando o cluster do que entregando valor. Alternativas mais simples (Azure App Service, Azure Container Apps, AWS App Runner, ou até uma VM com Docker Compose) podem ser a escolha certa. Adote Kubernetes quando o problema é genuinamente o que ele resolve: **muitos serviços, escala variável, deploys frequentes, alta disponibilidade**. Escolher a ferramenta proporcional ao problema — isso você, com 10+ anos de estrada, já sabe melhor que ninguém.
