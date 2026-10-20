# 3. AWS Fundamentos: IAM, VPC e EC2

> **Origem:** Pós-Tech FIAP, Arquitetura de Sistemas .NET, Fase 4, disciplina **AWS**.
>
> **Aulas cobertas:**
>
> 1. Aula 01: Introdução ao IAM (Identity and Access Management)
> 2. Aula 02: Explorando a VPC
> 3. Aula 03: Explorando a EC2
>
> **Como ler este material:** o texto corrido reproduz o conteúdo dos PDFs das aulas. Os blocos marcados com
> **💡 Complemento** são acréscimos meus (esclarecimentos, atualizações, boas práticas, custos). Eles não fazem parte
> do material oficial. Boa parte da demonstração prática (criação de Roles, Policies, VPC, Subnets, instância EC2)
> acontece nos **vídeos** das aulas; os PDFs trazem o texto de apoio ("Saiba mais"), e os complementos cobrem esses
> tópicos práticos para o estudo ficar completo.

---

## Aula 1 - Introdução ao IAM (Identity and Access Management)

### O que vem por aí?

Nesta aula você aprenderá mais sobre o IAM, o serviço responsável pelo controle de usuários e permissões da AWS, além
de aprender como funciona a segurança na cloud.

Usaremos como exemplo a AWS e demonstraremos algumas boas práticas para aplicar na cloud, garantindo uma melhor
segurança para nossas aplicações e serviços.

Além disso, entenderemos melhor como funciona o modelo de responsabilidade compartilhada da AWS e seus principais
serviços de segurança, além da importância do uso do MFA.

### Hands on

Nesta aula entenderemos melhor a segurança da cloud com AWS IAM e realizaremos a criação de Roles e Policies
utilizando o AWS IAM.

Também entenderemos melhor o conceito por trás do AccessKey e SecretKey e o acesso programático da AWS, além de
analisar a importância do uso de Roles em vez de AccessKey.

> **💡 Complemento: os blocos do IAM (o que o vídeo pratica).**
>
> - **Root user:** a identidade criada com a conta (e-mail + senha). Tem acesso irrestrito e não pode ser limitada por
>   policies IAM comuns. Use-a só para tarefas que exigem root (ex.: alterar plano de suporte, fechar a conta),
>   ative MFA nela e não crie access keys para ela.
> - **User (usuário IAM):** identidade de longo prazo para uma pessoa ou aplicação. Pode ter senha de console e/ou
>   access keys.
> - **Group:** conjunto de usuários; as policies anexadas ao grupo valem para todos os membros. Grupo não é
>   "principal": não dá para referenciá-lo em trust policy.
> - **Role:** identidade **sem credenciais permanentes**. Quem "assume" a role (um serviço AWS, um usuário, outra conta,
>   um provedor OIDC/SAML) recebe credenciais **temporárias** via AWS STS. Toda role tem duas partes: a **trust
>   policy** (quem pode assumi-la) e as **permission policies** (o que ela pode fazer).
> - **Policy:** documento JSON que concede (`Allow`) ou nega (`Deny`) ações em recursos. Tipos principais:
>   *AWS managed* (mantidas pela AWS, ex.: `ReadOnlyAccess`), *customer managed* (criadas por você, reutilizáveis) e
>   *inline* (embutidas em uma única identidade).

> **💡 Complemento: anatomia de uma policy de identidade.** Exemplo de policy *customer managed* que permite apenas
> leitura em um bucket S3 específico (exemplo meu, não do PDF):
>
> ```json
> {
>   "Version": "2012-10-17",
>   "Statement": [
>     {
>       "Sid": "LeituraBucketRelatorios",
>       "Effect": "Allow",
>       "Action": ["s3:GetObject", "s3:ListBucket"],
>       "Resource": [
>         "arn:aws:s3:::meu-bucket-relatorios",
>         "arn:aws:s3:::meu-bucket-relatorios/*"
>       ]
>     }
>   ]
> }
> ```
>
> - `Version` deve ser `"2012-10-17"` (versão atual da linguagem de policy, não é uma data a ser trocada).
> - `Effect`, `Action`, `Resource` e opcionalmente `Condition` formam cada statement.
> - **Lógica de avaliação:** por padrão tudo é negado (*implicit deny*); um `Allow` libera; um `Deny` explícito
>   **sempre vence** qualquer `Allow`.

> **💡 Complemento: trust policy de uma role para EC2.** É assim que uma instância EC2 recebe permissões sem access key
> (via *instance profile*):
>
> ```json
> {
>   "Version": "2012-10-17",
>   "Statement": [
>     {
>       "Effect": "Allow",
>       "Principal": { "Service": "ec2.amazonaws.com" },
>       "Action": "sts:AssumeRole"
>     }
>   ]
> }
> ```
>
> Com o AWS CLI, o fluxo equivalente ao que se faz no console seria (os arquivos JSON contêm as policies acima):
>
> ```bash
> aws iam create-role --role-name app-ec2-role --assume-role-policy-document file://trust-ec2.json
> aws iam put-role-policy --role-name app-ec2-role --policy-name leitura-s3 --policy-document file://leitura-s3.json
> aws iam create-instance-profile --instance-profile-name app-ec2-profile
> aws iam add-role-to-instance-profile --instance-profile-name app-ec2-profile --role-name app-ec2-role
> ```

> **💡 Complemento: AccessKey/SecretKey vs Roles.** Um par *Access Key ID* + *Secret Access Key* é uma credencial
> **de longo prazo** de um usuário IAM, usada para acesso programático (CLI, SDKs). O risco: ela não expira sozinha,
> vaza com facilidade (commit no Git, variável de ambiente em log, imagem Docker) e quem a obtém age como o usuário.
> Roles entregam credenciais temporárias (expiram em minutos/horas) e rotacionadas automaticamente. Regra prática:
>
> - Código rodando **na AWS** (EC2, Lambda, ECS, EKS): use role (instance profile, execution role, IRSA/Pod Identity).
> - **CI/CD externo** (GitHub Actions, GitLab): use federação **OIDC** com `sts:AssumeRoleWithWebIdentity`, sem
>   guardar access key no repositório.
> - **Pessoas:** use **AWS IAM Identity Center** (antigo AWS SSO) com credenciais temporárias, em vez de usuários IAM
>   com access keys. Se precisar de access key, rotacione e monitore o uso (`aws iam get-access-key-last-used`).

### Saiba mais: o que é o IAM

O IAM é um serviço essencial que permite gerenciar de forma segura o acesso aos recursos da AWS. Com ele, você pode
controlar quem é **autenticado** (conectado) e **autorizado** (tem permissões) para usar os recursos dentro do ambiente
AWS. Ele oferece uma infraestrutura robusta para criar e gerenciar usuários, grupos e permissões, assegurando que apenas
pessoas ou sistemas autorizados possam acessar os recursos críticos de sua organização.

Mas não é responsabilidade somente da AWS garantir a segurança na cloud: ela precisa vir de ambas as partes e,
pensando nisso, podemos citar como funciona a responsabilidade compartilhada que a AWS tem. Somos nós que criamos os
usuários no IAM e a AWS garante o pleno funcionamento. Por outro lado, a garantia da segurança do acesso criado não
fica com a AWS, já que ela não tem controle de como as credenciais de segurança são armazenadas e compartilhadas.

> **💡 Complemento:** o IAM é um serviço **global** (não pertence a uma região) e **não tem custo**. Usuários, roles e
> policies criados valem para todas as regiões da conta.

### Modelo de responsabilidade compartilhada

O modelo de responsabilidade compartilhada é essencial para entender como a segurança funciona na nuvem. Ele define
claramente as responsabilidades de segurança entre a AWS, como provedora de infraestrutura em nuvem, e os clientes,
que utilizam os serviços da AWS.

#### Responsabilidades da AWS ("segurança **da** nuvem")

A AWS é responsável pela segurança da infraestrutura global que suporta os serviços em nuvem. Isso inclui a segurança
física dos data centers, a segurança da rede que conecta esses data centers e a segurança dos sistemas de hardware e
software que constituem a infraestrutura da AWS:

- **Segurança física:** a AWS implementa medidas robustas de segurança física para proteger seus data centers contra
  acesso não autorizado, danos ambientais e intrusões físicas. Isso inclui controles de acesso rigorosos, sistemas de
  vigilância por vídeo, detecção de intrusão, sistemas de alarme e muito mais.
- **Segurança da rede:** a AWS gerencia uma rede global altamente segura que conecta seus data centers e permite a
  comunicação entre os serviços em nuvem. Isso inclui firewalls, sistemas de prevenção contra intrusões (IPS),
  filtragem de tráfego e outras medidas para proteger contra ameaças de rede.
- **Segurança do hardware e software:** a AWS é responsável por garantir a segurança do hardware subjacente (como
  servidores, roteadores e dispositivos de armazenamento) e do software (como o hypervisor utilizado para
  virtualização). Isso envolve implementar patches de segurança, gerenciamento de vulnerabilidades e proteção contra
  ameaças cibernéticas.

#### Responsabilidades do cliente ("segurança **na** nuvem")

Os clientes da AWS também têm responsabilidades claras em termos de segurança. Embora a AWS forneça uma base segura,
eles são responsáveis por configurar adequadamente seus recursos na nuvem, proteger seus dados e aplicativos e
implementar controles de segurança apropriados:

- **Controle de Acesso e Identidade (IAM):** clientes devem gerenciar de forma segura as identidades e os acessos dos
  usuários aos recursos da AWS. Isso envolve configurar políticas de acesso granulares, usar autenticação multifatorial
  (MFA) e auditar e monitorar o acesso dos usuários.
- **Segurança dos dados e aplicações:** os clientes devem garantir a segurança dos dados que armazenam e processam na
  AWS. Isso inclui criptografar dados sensíveis, configurar corretamente as permissões de acesso (IAM), implementar
  firewalls de aplicativos e proteger contra malware e outras ameaças.
- **Configurações de segurança:** os clientes devem configurar corretamente os serviços da AWS para garantir a
  segurança. Isso inclui ajustar as configurações de firewall (grupos de segurança), habilitar registros de auditoria
  (logs), realizar atualizações de segurança e seguir as práticas recomendadas da AWS.

*Figura 1 - Modelo de Responsabilidade Compartilhada (Fonte: AWS, 2021): diagrama que separa a responsabilidade do
cliente (dados, identidades, aplicações, configuração de SO/rede/firewall, criptografia) da responsabilidade da AWS
(computação, armazenamento, banco de dados, rede, regiões, AZs e edge locations).*

O modelo de responsabilidade compartilhada é fundamental em todas as principais plataformas de nuvem, incluindo Azure,
AWS e GCP. Entender as responsabilidades de segurança de cada parte (provedor de nuvem e cliente) é essencial para
garantir a segurança dos dados e aplicativos na nuvem. Ao seguir as práticas recomendadas e implementar controles de
segurança adequados, as organizações podem aproveitar os benefícios da nuvem de forma segura e confiável.

Quando ocorre um vazamento de dados por parte de um cliente na Amazon Web Services, a abordagem da AWS para lidar com
essa situação geralmente envolve uma combinação de medidas de resposta e suporte ao cliente. Assim, a AWS tem
procedimentos e recursos estabelecidos para ajudar os clientes a lidarem com incidentes de segurança e vazamentos de
dados.

> **💡 Complemento:** a fronteira da responsabilidade **muda conforme o tipo de serviço**. Em IaaS (EC2) o cliente
> cuida do sistema operacional, patches, firewall do SO e da aplicação. Em serviços gerenciados (RDS, EKS control
> plane) a AWS assume o SO e o motor; em serverless (Lambda, Fargate) assume ainda mais. Em **todos** os casos,
> dados, identidades/permissões e configuração de acesso continuam sendo do cliente: um bucket S3 público por engano
> é responsabilidade sua, não da AWS.

### Principais serviços de segurança da AWS

Temos uma lista grande de serviços e, a cada ano, a AWS lança novos para compor seu catálogo e disponibilizar para seus
clientes.

A seguir, listamos em imagens os principais serviços e suas funções. Eles estão disponíveis para os usuários, mas vale
ressaltar a importância de checar a região em que os serviços estão localizados, pois a disponibilidade varia conforme
a região.

- *Figura 2 - Gerenciamento de identidade e acesso (Fonte: AWS, 2023).*
- *Figura 3 - Detecção e resposta (Fonte: AWS, 2023).*
- *Figura 4 - Proteção da rede e das aplicações (Fonte: AWS, 2023).*
- *Figura 5 - Proteção de dados (Fonte: AWS, 2023).*
- *Figura 6 - Conformidade (Fonte: AWS, 2023).*

*As figuras são cartões da página "Segurança, identidade e conformidade na AWS", com o nome de cada serviço e sua
função em cada categoria.*

> **💡 Complemento: o que aparece em cada categoria** (conforme a página de produtos de segurança da AWS; a lista
> exata das imagens não pôde ser transcrita do PDF):
>
> | Categoria | Serviços principais |
> |---|---|
> | Identidade e acesso | IAM, IAM Identity Center, AWS Organizations, Amazon Cognito, AWS Directory Service, AWS RAM, Amazon Verified Permissions |
> | Detecção e resposta | Amazon GuardDuty, AWS Security Hub, Amazon Inspector, Amazon Detective, AWS Config, AWS CloudTrail, Amazon Security Lake |
> | Proteção de rede e aplicações | AWS WAF, AWS Shield, AWS Network Firewall, AWS Firewall Manager, Amazon VPC (Security Groups/NACLs) |
> | Proteção de dados | AWS KMS, AWS Secrets Manager, AWS Certificate Manager (ACM), Amazon Macie, AWS CloudHSM, AWS Private CA |
> | Conformidade | AWS Artifact, AWS Audit Manager |

### Autenticação Multifator (MFA)

Ainda no quesito segurança, podemos falar sobre a Autenticação Multifator (MFA) da AWS, que adiciona uma camada extra de
proteção além das senhas convencionais. A MFA exige que usuários forneçam duas ou mais formas de identificação para
acessar recursos e realizar operações sensíveis, o que ajuda a prevenir acesso não autorizado, mesmo que as senhas
sejam comprometidas.

#### O que é Autenticação Multifator (MFA)?

A MFA é um método de autenticação que requer a apresentação de dois ou mais elementos de verificação. Esses elementos
são geralmente classificados em três categorias:

- **Algo que você sabe:** senhas ou PINs.
- **Algo que você tem:** dispositivos físicos como tokens de hardware ou aplicativos móveis autenticadores.
- **Algo que você é:** características biométricas como impressões digitais ou reconhecimento facial.

Na AWS, a MFA pode ser implementada para adicionar uma camada extra de segurança às contas de usuários, garantindo que
mesmo se um nome de usuário e senha forem comprometidos, um invasor não poderá acessar os recursos sem o segundo fator
de autenticação.

#### Tipos de dispositivos MFA suportados pela AWS

A AWS suporta vários tipos de dispositivos MFA, incluindo:

- **Aplicativos de Autenticação Virtual:** aplicativos como Google Authenticator, Authy e Microsoft Authenticator podem
  ser usados para gerar códigos de autenticação temporários baseados em tempo (TOTP).
- **Tokens de Hardware MFA:** dispositivos físicos que geram códigos de verificação. A AWS suporta tokens de hardware
  TOTP compatíveis, como aqueles fornecidos pela Gemalto.
- **Autenticação FIDO U2F (Universal 2nd Factor):** dispositivos que suportam o protocolo U2F, como YubiKey, que
  fornecem uma autenticação segura através de uma chave USB ou NFC.
- **Passkey (Chave de Acesso):** o Passkey é uma solução de autenticação moderna e segura, introduzida pela AWS para
  simplificar e fortalecer o processo de login. As passkeys são chaves criptográficas baseadas em padrões como WebAuthn
  e FIDO2, que eliminam a necessidade de senhas, utilizando métodos de autenticação biométrica ou dispositivos físicos.
  As passkeys são armazenadas em dispositivos confiáveis, como smartphones ou laptops, e permitem um login rápido e
  seguro, protegendo contra ataques de phishing e outros métodos de comprometimento de contas.

A Autenticação Multifator (MFA) é uma medida de segurança vital para proteger contas e recursos na AWS. Ao exigir uma
segunda forma de verificação além da senha, o MFA reduz significativamente o risco de acesso não autorizado,
fortalecendo a postura de segurança da organização. Implementar a MFA para contas raiz, usuários privilegiados e outros
pontos críticos é uma prática recomendada que ajuda a garantir a integridade e a segurança das operações na nuvem.

> **💡 Complemento (atualização):** desde 2024 a AWS passou a **exigir MFA para o root user** no login do console
> (implantação gradual por tipo de conta), e permite registrar **até 8 dispositivos MFA** por usuário (root ou IAM).
> Na AWS, o "FIDO U2F" e as passkeys são hoje tratados juntos como **chaves de segurança FIDO / passkeys**. Observação:
> MFA protege o **login**; access keys usadas pela CLI não pedem MFA, a menos que a policy exija
> (`"Condition": {"Bool": {"aws:MultiFactorAuthPresent": "true"}}`) e você obtenha credenciais via
> `aws sts get-session-token --serial-number ... --token-code ...`.

> **💡 Complemento: checklist de boas práticas de IAM.**
>
> 1. **Não use o root** no dia a dia; ative MFA nele e não crie access keys para ele.
> 2. **Least privilege:** comece com o mínimo e amplie conforme necessidade. Use o **IAM Access Analyzer** para gerar
>    policies a partir da atividade registrada no CloudTrail e para achar acessos externos não intencionais.
> 3. **Prefira roles e credenciais temporárias** a access keys (pessoas via Identity Center; workloads via roles;
>    CI via OIDC).
> 4. **Permissões por grupo**, não por usuário individual.
> 5. **Habilite o CloudTrail** (auditoria de quem fez o quê) e revise credenciais sem uso (*credential report*,
>    *last accessed*).
> 6. Em ambientes com várias contas, use **AWS Organizations** + **SCPs** (Service Control Policies) como guarda-corpo.
> 7. Nunca coloque segredos no código: use **Secrets Manager** ou **SSM Parameter Store**.

### O que você viu nesta aula?

Você viu nesta aula como funciona a segurança na cloud. Utilizamos o AWS IAM para demonstrar algumas boas práticas para
aplicar na cloud e conseguimos entender como funcionam as Roles e Policies, além de compreendermos melhor o papel das
Roles em comparação com AccessKey.

Também aprendemos sobre o modelo de responsabilidade compartilhada que a AWS descreve antes de iniciar o uso na cloud e
entendemos a importância do MFA.

**Palavras-chave da aula:** Segurança, AWS, Conformidade, Responsabilidade, MFA.

### Referências da aula

- AWS. *Modelo de Segurança Compartilhada*, 2021. <https://maturitymodel.security.aws.dev/pt/0.-introduction/2.-shared-responsibility-model/>
- AWS. *O que é o IAM?*, 2024. <https://docs.aws.amazon.com/pt_br/IAM/latest/UserGuide/introduction.html>
- AWS. *Segurança, identidade e conformidade na AWS*, 2023. <https://aws.amazon.com/pt/products/security/>
- AWS. *Uso de autenticação multifator (MFA) na AWS*, 2024. <https://docs.aws.amazon.com/pt_br/IAM/latest/UserGuide/id_credentials_mfa.html>

### Pontos-chave

- IAM controla **autenticação** (quem é você) e **autorização** (o que pode fazer); é global e gratuito.
- Responsabilidade compartilhada: a AWS protege **a** nuvem (físico, rede, hardware, hypervisor); o cliente protege o
  que coloca **na** nuvem (identidades, dados, configurações, Security Groups, logs).
- Roles entregam credenciais temporárias via STS e devem ser preferidas a AccessKey/SecretKey fixas.
- Policies são JSON com `Effect`/`Action`/`Resource`; `Deny` explícito sempre vence; o padrão é negar.
- MFA combina fatores (sabe/tem/é); a AWS aceita apps TOTP, tokens de hardware, chaves FIDO e passkeys.
- MFA é obrigatória na prática para root e usuários privilegiados.
- A disponibilidade de serviços de segurança varia por região: sempre conferir.

---

## Aula 2 - Explorando a VPC

### O que vem por aí?

Nesta aula você aprenderá como as redes são definidas em uma visão pela AWS e como cada funcionalidade do serviço AWS
VPC funciona.

Além disso, vamos criar nossa própria rede, definir um range de IPs para ela e separar esse range em pequenos grupos
para isolar nossas aplicações em diferentes Subnets.

Também exploraremos o modelo OSI e suas camadas de forma detalhada, além de aprender sobre o modelo TCP/IP.

### Hands on

Nesta primeira aula vamos entender como a rede da AWS funciona e criar nossa rede personalizada, a fim de aplicarmos
todo o conhecimento voltado para a rede da AWS. Além disso, vamos criar uma VPC com range de IP diferente e separar essa
rede em Subnets para isolar nossas aplicações entre Subnets Privadas e Subnets Públicas.

> **💡 Complemento: componentes da VPC citados na aula** (Subnets, Route Table, Internet Gateway, NAT Gateway,
> Security Groups, ACL, VPN, Transit Gateway).
>
> | Componente | O que é | Observação |
> |---|---|---|
> | **VPC** | Rede virtual isolada logicamente, em **uma região**, com um bloco CIDR IPv4 (de `/16` a `/28`) e opcionalmente IPv6 | Use faixas privadas RFC 1918 (`10.0.0.0/8`, `172.16.0.0/12`, `192.168.0.0/16`) sem sobreposição com outras redes que vá conectar |
> | **Subnet** | Fatia do CIDR da VPC, presa a **uma única AZ** | Alta disponibilidade = subnets em 2+ AZs |
> | **Route Table** | Regras de "para onde vai o tráfego com destino X" | Toda subnet está associada a exatamente uma route table; a rota `local` (dentro da VPC) existe sempre |
> | **Internet Gateway (IGW)** | Porta de saída/entrada da VPC para a internet | Gratuito em si; uma VPC tem no máximo um IGW |
> | **NAT Gateway** | Permite que recursos em subnet **privada** iniciem conexões para a internet sem serem alcançáveis de fora | Fica em subnet pública; é zonal (um por AZ para HA) |
> | **Security Group (SG)** | Firewall **stateful** no nível da interface (ENI/instância) | Só regras de *allow*; resposta ao tráfego permitido volta automaticamente; pode referenciar outro SG como origem |
> | **Network ACL (NACL)** | Firewall **stateless** no nível da subnet | Regras de *allow* e *deny*, avaliadas por número; precisa liberar o tráfego de retorno (portas efêmeras 1024-65535) |
> | **Site-to-Site VPN** | Túnel IPsec entre a VPC e uma rede on-premises | Alternativa dedicada: Direct Connect |
> | **Transit Gateway** | Hub regional que interliga muitas VPCs e VPNs | Evita a malha de muitos VPC Peerings |
>
> **O que torna uma subnet "pública"?** Não é um checkbox: é a sua route table ter a rota `0.0.0.0/0 -> igw-...`.
> Subnet **privada** não tem rota para o IGW; para sair à internet usa `0.0.0.0/0 -> nat-...`.

> **💡 Complemento: CIDR e cálculo de subnets.** Em `10.0.0.0/16` os 16 primeiros bits são a rede, sobrando
> 16 bits = 65.536 endereços. Dividindo em `/24`, cada subnet tem 256 endereços. Exemplo de desenho:
>
> | Subnet | AZ | CIDR | Tipo |
> |---|---|---|---|
> | public-a | us-east-1a | `10.0.1.0/24` | pública (rota para IGW) |
> | public-b | us-east-1b | `10.0.2.0/24` | pública |
> | private-a | us-east-1a | `10.0.11.0/24` | privada (rota para NAT) |
> | private-b | us-east-1b | `10.0.12.0/24` | privada |
>
> **Armadilha:** a AWS reserva **5 IPs** em cada subnet (o endereço de rede, `.1` roteador da VPC, `.2` DNS, `.3`
> reservado para uso futuro e o broadcast). Uma `/24` tem portanto 251 IPs utilizáveis. Em EKS isso pesa, porque
> com o VPC CNI cada pod consome um IP da subnet: dimensione subnets privadas com folga (ex.: `/20` ou `/19`).
>
> Fluxo equivalente ao hands on pelo AWS CLI (simplificado):
>
> ```bash
> aws ec2 create-vpc --cidr-block 10.0.0.0/16
> aws ec2 create-subnet --vpc-id vpc-xxxx --cidr-block 10.0.1.0/24 --availability-zone us-east-1a
> aws ec2 create-internet-gateway
> aws ec2 attach-internet-gateway --internet-gateway-id igw-xxxx --vpc-id vpc-xxxx
> aws ec2 create-route-table --vpc-id vpc-xxxx
> aws ec2 create-route --route-table-id rtb-xxxx --destination-cidr-block 0.0.0.0/0 --gateway-id igw-xxxx
> aws ec2 associate-route-table --route-table-id rtb-xxxx --subnet-id subnet-xxxx
> ```
>
> No console, o assistente **"VPC and more"** cria VPC, subnets públicas/privadas em várias AZs, route tables, IGW e
> (opcionalmente) NAT Gateways de uma vez, e mostra um diagrama de pré-visualização.

> **💡 Complemento: custos que pegam iniciantes.**
>
> - **NAT Gateway** cobra **por hora** em que existe **e por GB processado** (em `us-east-1`, na ordem de
>   US$ 0,045/h + US$ 0,045/GB; confira a página de preços da sua região). Um NAT por AZ esquecido ligado em conta de
>   estudo vira algumas dezenas de dólares por mês. Apague ao terminar o laboratório, ou use **VPC endpoints**
>   (Gateway endpoints de S3/DynamoDB são gratuitos) para reduzir tráfego pelo NAT.
> - **IPv4 público:** desde fevereiro de 2024 a AWS cobra **todo endereço IPv4 público** (inclusive Elastic IP
>   associado e IP público automático de instância), cerca de US$ 0,005 por hora por IP. Verifique as regras atuais do
>   Free Tier, que mudaram em 2025.
> - VPC, subnets, route tables, IGW, SGs e NACLs **não têm custo** por si.

### Saiba mais: modelos de referência de rede

Ao abordar o tema de redes utilizando o AWS VPC, é necessário entender como a rede funciona de fato. Uma rede pode ser
representada por dois modelos que se dividem em camadas para detalhar onde cada etapa de uma comunicação via rede se
define; pensando nisso, temos dois modelos mais utilizados para representar esse detalhamento. O primeiro é o modelo de
referência **OSI** e outro é chamado de modelo de referência **TCP/IP**. Ambos tentam representar de maneira objetiva
todas as camadas da rede.

Na AWS, o modelo de referência OSI é fundamental para a construção e gestão de redes na nuvem, particularmente quando se
trata da Amazon Virtual Private Cloud (VPC). A VPC da AWS permite criar redes virtuais isoladas em que é possível lançar
recursos da AWS em uma rede definida por você. Compreender o modelo OSI ajuda a desenhar e implementar redes VPC
robustas e seguras, garantindo que cada camada da rede esteja configurada adequadamente para suportar suas necessidades
de aplicação e negócios. Mas o que é o modelo OSI e o que significa?

### Modelo OSI

O modelo de referência OSI (Open Systems Interconnection) é um framework teórico utilizado para entender e implementar
redes de computadores e a comunicação entre sistemas. Desenvolvido pela International Organization for Standardization
(ISO) em 1984, o modelo OSI divide a comunicação de rede em sete camadas distintas, cada uma com funções específicas.
Essa segmentação ajuda a padronizar a comunicação e permite que diferentes sistemas e tecnologias de rede possam
interoperar eficientemente.

#### Camada de Aplicação (Layer 7)

- **Função:** a camada de aplicação é a mais próxima do usuário final. Ela fornece interfaces e protocolos que permitem
  a aplicações utilizarem os serviços de rede.
- **Protocolos:** HTTP (Hypertext Transfer Protocol), FTP (File Transfer Protocol), SMTP (Simple Mail Transfer Protocol)
  e DNS (Domain Name System).

#### Camada de Apresentação (Layer 6)

- **Função:** a camada de apresentação traduz dados entre o formato usado pela aplicação e o formato de rede. É
  responsável por criptografia, compressão e conversão de dados.
- **Serviços:** conversão de código de caracteres, compressão de dados, criptografia e decriptografia.

#### Camada de Sessão (Layer 5)

- **Função:** a camada de sessão gerencia e controla as conexões entre computadores. Estabelece, mantém e termina
  sessões entre aplicações que estão se comunicando.
- **Serviços:** sincronização de diálogos, gerenciamento de sessões e controle de troca de dados.

#### Camada de Transporte (Layer 4)

- **Função:** a camada de transporte garante a entrega confiável dos dados entre sistemas finais. Ela proporciona
  controle de fluxo, segmentação e remontagem de dados e controle de erros de ponta a ponta.
- **Protocolos:** TCP (Transmission Control Protocol) e UDP (User Datagram Protocol).

#### Camada de Rede (Layer 3)

- **Função:** a camada de rede é responsável pelo roteamento de pacotes entre redes diferentes. Ela determina o melhor
  caminho para os dados viajarem do remetente ao destinatário.
- **Componentes:** roteadores e gateways.
- **Protocolos:** IP (Internet Protocol), ICMP (Internet Control Message Protocol) e ARP (Address Resolution Protocol).

#### Camada de Enlace de Dados (Layer 2)

- **Função:** a camada de enlace de dados assegura uma transferência de dados livre de erros entre dois nós conectados
  diretamente. É responsável pela detecção e correção de erros que possam ocorrer na camada física.
- **Componentes:** switches, bridges e adaptadores de rede (NICs).
- **Subcamadas:**
  - **LLC (Logical Link Control):** gerencia o controle de fluxo e a multiplexação de protocolos de rede.
  - **MAC (Media Access Control):** controla o acesso ao meio físico e endereçamento físico (endereços MAC).

#### Camada Física (Layer 1)

- **Função:** a camada física é responsável pela transmissão e recepção dos dados em forma de bits através de um meio
  físico, como cabos, fibras ópticas ou ondas de rádio.
- **Componentes:** inclui hardware como hubs, repetidores, cabos e conectores.
- **Protocolos:** define as especificações elétricas e mecânicas para dispositivos e meios de transmissão.

*Figura 1 - Modelo OSI (Fonte: elaborado pelo autor, 2024): pilha das sete camadas, da Física (1) à Aplicação (7), com
a função e exemplos de cada uma.*

| # | Camada OSI | Unidade de dados | Exemplos |
|---|---|---|---|
| 7 | Aplicação | dados | HTTP, FTP, SMTP, DNS |
| 6 | Apresentação | dados | conversão de caracteres, compressão, criptografia |
| 5 | Sessão | dados | controle de sessões e diálogos |
| 4 | Transporte | segmento (TCP) / datagrama (UDP) | TCP, UDP |
| 3 | Rede | pacote | IP, ICMP, ARP; roteadores |
| 2 | Enlace | quadro (frame) | switches, bridges, NICs; LLC e MAC |
| 1 | Física | bits | cabos, fibra, rádio, hubs, repetidores |

*(Tabela-resumo montada a partir do texto da aula; a coluna "unidade de dados" é um acréscimo meu.)*

O modelo OSI é uma ferramenta fundamental para entender e projetar redes de computadores. Ele proporciona uma estrutura
clara para desenvolvimento, implementação e solução de problemas em redes. Cada camada tem responsabilidades distintas,
desde a transmissão física de bits até a interface do usuário, garantindo uma comunicação eficiente e padronizada entre
sistemas diversos, assim como o modelo a seguir, que define sua referência pelo protocolo TCP/IP.

> **💡 Complemento: onde cada componente AWS "mora" no OSI.** Security Groups e NACLs filtram por IP/porta/protocolo
> (camadas 3-4); o **NLB** trabalha na camada 4; o **ALB** e o **AWS WAF** na camada 7 (enxergam caminho, cabeçalho,
> método HTTP); o **GWLB** na camada 3. Saber a camada ajuda no troubleshooting: "connection timeout" costuma ser
> SG/NACL/rota (L3-L4); "403/502" costuma ser L7 (WAF, ALB, aplicação). Curiosidade: o ARP é frequentemente
> classificado entre as camadas 2 e 3, e numa VPC ele é emulado pela própria AWS.

### Modelo TCP/IP

O TCP/IP (Protocolo de Controle de Transmissão/Protocolo de Internet), por sua vez, é um conjunto de protocolos de
comunicação que possibilita a comunicação entre computadores e servidores, formando a Internet. Ele combina o Protocolo
de Controle de Transmissão (TCP), responsável pela transmissão de dados, com o Protocolo de Internet (IP), que
identifica os computadores e servidores.

O conjunto de protocolos TCP/IP foi desenvolvido em 1969, no Departamento de Defesa dos Estados Unidos, como parte do
projeto conhecido como ARPANET. O objetivo era criar uma tecnologia de comunicação capaz de transmitir grandes volumes
de dados em alta velocidade. Ele funciona por meio de camadas, que trabalham em conjunto para garantir a transmissão, a
integridade e a segurança dos dados conforme eles viajam pela web. O grupo é dividido em quatro camadas: **aplicação,
transporte, rede e interface**.

> **💡 Complemento (precisão histórica):** a ARPANET começou em 1969, mas usava o protocolo NCP. O TCP/IP foi
> especificado ao longo dos anos 1970 (Cerf e Kahn, 1974) e adotado oficialmente pela ARPANET em 1º de janeiro de 1983.

*Figura 2 - Modelo OSI vs Modelo TCP/IP (Fonte: elaborado pelo autor, 2024): comparação lado a lado; as camadas 7, 6 e
5 do OSI correspondem à Aplicação do TCP/IP; Transporte corresponde a Transporte; Rede corresponde a Rede/Internet; e
Enlace + Física correspondem à Interface (Link), que na versão atualizada aparece separada em Data Link e Física.*

#### Camada de Aplicação

A Camada de Aplicação é a camada mais alta do modelo TCP/IP e do modelo OSI, atuando como um intermediário crucial
entre as aplicações de usuário e os processos de rede subjacentes. Como o próprio nome deixa claro, a Camada de
Aplicação é responsável por prover as aplicações que usamos no dia a dia. Ela permite que pessoas leigas possam utilizar
a grande rede para uma infinidade de usos, como pesquisa, conversas em chat, redes sociais, pagamento de contas, acessar
bancos etc.

A camada de aplicação desempenha um papel fundamental na arquitetura de rede, permitindo a comunicação entre aplicativos
em diferentes dispositivos. Ela oferece uma variedade de serviços e funcionalidades, garantindo a transferência
eficiente de dados na internet.

#### Camada de Transporte

A Camada de Transporte é uma das camadas fundamentais do modelo de rede TCP/IP. Ela é responsável pela transferência de
dados entre duas máquinas, independentemente da aplicação usada e do tipo, topologia ou configuração das redes físicas
existentes entre elas.

Os dois protocolos principais desta camada são o UDP (User Datagram Protocol) e o TCP (Transmission Control Protocol).
Cada um tem características e usos específicos.

- **TCP (Transmission Control Protocol):** é um protocolo orientado à conexão, o que significa que ele estabelece uma
  conexão entre o remetente e o destinatário antes de enviar os dados. Ele é confiável porque garante a entrega dos
  dados ao destinatário. Se algum pacote for perdido durante a transmissão, o TCP retransmite o pacote. Isso o torna
  ideal para aplicações que requerem alta confiabilidade, mas não são sensíveis ao tempo, como navegação na web, email e
  transferência de arquivos.
- **UDP (User Datagram Protocol):** ao contrário do TCP, o UDP é um protocolo sem conexão. Ele não estabelece uma
  conexão antes de enviar dados e não tem mecanismos para garantir que os dados enviados sejam recebidos pelo
  destinatário. Isso significa que o UDP é menos confiável, mas também é mais rápido e eficiente em termos de recursos
  do que o TCP. O UDP é usado em aplicações que são sensíveis ao tempo, como streaming de vídeo e jogos online, em que a
  perda de alguns pacotes de dados não é tão crítica quanto a entrega rápida.

A camada de transporte oferece para o nível de aplicação um conjunto de funções e procedimentos para acesso ao sistema
de comunicação, permitindo a criação e utilização de aplicações de forma independente da implementação da rede.

Em resumo, a camada de transporte desempenha um papel crucial na comunicação de rede, fornecendo mecanismos para a
transferência de dados confiável (TCP) ou rápida (UDP) entre dispositivos.

> **💡 Complemento:** o TCP estabelece a conexão com o *three-way handshake* (SYN, SYN-ACK, ACK). Em Security Groups
> você libera por protocolo + porta (ex.: TCP 443 para HTTPS, TCP 5432 para PostgreSQL, UDP 53 para DNS). O HTTP/3
> (QUIC) roda sobre UDP, mostrando que "UDP = não confiável" é sobre o protocolo em si: a confiabilidade pode ser
> implementada na camada acima.

#### Camada de Rede (Internet)

A Camada de Rede, também conhecida como Camada de Internet, é a terceira camada no Modelo OSI e a segunda camada no
modelo TCP/IP. Ela é responsável por várias funções cruciais na comunicação de dados na internet. A seguir estão alguns
detalhes sobre a Camada de Rede:

- **Conexões de Rede:** a Camada de Rede é responsável por estabelecer conexões entre diferentes redes, enviando
  pacotes de dados entre elas. Isso torna a internet possível, pois permite que os computadores se conectem a outros
  computadores próximos e distantes.
- **Protocolo de Internet (IP):** o Protocolo de Internet (IP) é um dos principais protocolos usados nesta camada, junto
  com vários outros protocolos de roteamento, teste e criptografia. O IP é responsável pelo encaminhamento dos pacotes
  para o seu destino, utilizando endereços IP.
- **Pacotes de Dados:** todos os dados enviados pela internet são divididos em pedaços menores chamados "pacotes". Um
  pacote tem duas partes: o cabeçalho, que contém informações sobre o próprio pacote, e o corpo, que são os dados reais
  sendo enviados. Na Camada de Rede, o software de rede anexa um cabeçalho a cada pacote quando ele é enviado pela
  internet.
- **Roteamento:** a Camada de Rede é responsável por configurar as rotas que os pacotes de dados vão seguir, verificar
  se um servidor em outra rede está funcionando e endereçar e receber pacotes de IP de outras redes.
- **Redes e Sub-redes:** uma rede é um grupo de dois ou mais dispositivos de computação conectados. Uma rede também pode
  incluir sub-redes ou subdivisões menores da rede. Sub-redes são como redes muito grandes, como as fornecidas por
  provedores, capazes de gerenciar milhares de endereços de IP e dispositivos conectados.

> **💡 Complemento:** é nesta camada que vivem a **VPC** (bloco CIDR), as **subnets** e as **route tables**. O
> roteador implícito da VPC encaminha pacotes conforme a rota mais específica (*longest prefix match*): `10.0.0.0/16
> -> local` vence `0.0.0.0/0 -> igw` para destinos internos.

#### Camada de Interface (Acesso à Rede)

A Camada de Interface, também conhecida como Camada de Acesso à Rede, é a primeira camada no modelo TCP/IP. Ela é
responsável por várias funções cruciais na comunicação de dados na internet. Alguns detalhes sobre a Camada de
Interface:

- **Funções da Camada de Interface:** a Camada de Interface é responsável, entre outros aspectos, por definir como os
  dados serão transmitidos, seja por uma conexão cabeada (como Ethernet, por exemplo) ou sem fios (como uma rede Wi-Fi).
  Ela é a camada que interage diretamente com o hardware de rede do dispositivo, como a placa de rede.
- **Formatação de Datagramas IP:** a Camada de Interface de Rede TCP/IP formata os datagramas IP na camada de Rede em
  pacotes que as tecnologias de rede específicas podem entender e transmitir. Isso significa que ela é responsável por
  converter os pacotes de dados em um formato que possa ser transmitido pela rede física.
- **Transmissão de Dados:** uma vez que os pacotes de dados são formatados corretamente, a Camada de Interface é
  responsável por transmitir esses pacotes pela rede física. Isso pode envolver a conversão dos pacotes de dados em
  sinais elétricos, ópticos ou de rádio, dependendo do tipo de rede física.
- **Recepção de Dados:** da mesma forma, quando os pacotes de dados são recebidos, a Camada de Interface é responsável
  por converter os sinais de volta em pacotes de dados que podem ser processados pelo dispositivo.

#### TCP/IP atualizado (cinco camadas)

Como podemos notar na figura 2, o modelo TCP/IP teve uma atualização e adicionou uma nova camada, deixando-o com cinco
camadas. Temos a camada adicional que segrega a última, antes chamada de Link, englobando a camada física como um todo;
mas devido aos avanços e complexidade gerada por novas tecnologias, a atualização segregou essa última em duas: a camada
de Data Link e a camada física. Ela basicamente ficou idêntica ao modelo OSI, que já cobria esses avanços na
tecnologia.

Dessa maneira os modelos OSI e TCP/IP acabam ficando similares, com o mesmo propósito de facilitar o entendimento sobre
as camadas que compõem uma rede.

| OSI | TCP/IP (4 camadas) | TCP/IP atualizado (5 camadas) |
|---|---|---|
| 7 Aplicação / 6 Apresentação / 5 Sessão | Aplicação | Aplicação |
| 4 Transporte | Transporte | Transporte |
| 3 Rede | Rede (Internet) | Rede |
| 2 Enlace | Interface (Link / Acesso à Rede) | Data Link |
| 1 Física | Interface (Link / Acesso à Rede) | Física |

### Casos de uso: Subnet Pública vs Subnet Privada

Vimos nos vídeos sobre o uso de Subnet Pública e Subnet Privada, mas quando podemos usar uma e outra e quais tipos de
serviços ficam em cada uma, com base nas boas práticas de segurança?

#### Subnet Privada

Primeiro, vamos tratar sobre Subnet Privada: quais tipos de serviços devem estar nessas Subnets?

**Bancos de dados e servidores de aplicativos, aplicações backend, processadores de dados, ambiente de desenvolvimento e
testes:** esses tipos de serviços e aplicações devem estar em uma subnet privada, sem acesso direto à internet, já que
isso pode impactar e deixar dados sensíveis expostos. Todo recurso que contenha dado sensível deve estar restrito dentro
da própria rede/empresa, e outros serviços expostos na internet devem se conectar a esses recursos privados de forma
interna, ou seja, na mesma rede.

#### Subnet Pública

Já a Subnet Pública deve abrigar serviços e aplicações que, de fato, devem estar acessíveis na internet, como, por
exemplo, servidores e aplicativos frontend (Web), Load Balancers, CDNs e APIs. Aqui vale ressaltar que muitas vezes não
se deve expor uma API toda, mas sim rotas dela que pessoas externas poderão bater para consultar algo e alguns métodos,
como o GET. É comum deixarmos só o método GET disponível para consultas e, em outros casos, o POST; agora, DELETE e
outros devem estar restritos internamente para garantir a integridade dos dados.

#### Comunicação entre subnets públicas e privadas

Para garantir a comunicação entre Subnets Públicas e Subnets Privadas podemos utilizar outros serviços, por exemplo a
**API Gateway**. Ela expõe uma URL/Endpoint na internet, mas faz a comunicação de forma interna, já que a API deve
estar na mesma rede ou ter acesso a ela.

Todo desenho de arquitetura deve mostrar esse tipo de segregação e definição do que deve e pode ou não ser público.
Esse tipo de abordagem é essencial para manter todo serviço/aplicação seguro na internet.

#### Exemplo de arquitetura com Subnet Privada

Na figura 3, vemos uma arquitetura que utiliza Subnet Privada, em que temos um **Cluster EKS** com seus **PODs**, outra
subnet privada exclusiva para um **banco de dados** e toda comunicação feita via **API Gateway**, utilizando outros
serviços para conseguir realizar a comunicação entre a internet e a rede privada, sem precisar expor os serviços na
internet.

*Figura 3 - Arquitetura Subnet Privada (Fonte: elaborado pelo autor, 2024): usuários acessam o API Gateway; a partir
dele o tráfego chega de forma privada ao cluster EKS (pods) em subnet privada, que por sua vez acessa o banco de dados em
outra subnet privada dedicada.*

> **💡 Complemento:** o "API Gateway fala com recursos privados" se faz, na prática, com **VPC Link**: na REST API o
> VPC Link aponta para um **NLB interno**; na HTTP API ele pode apontar para ALB/NLB internos ou Cloud Map. No EKS, o
> NLB/ALB interno costuma ser criado pelo **AWS Load Balancer Controller** a partir de um `Service`/`Ingress`.

#### Exemplo de arquitetura com Subnet Pública

Já na Subnet Pública, como vimos anteriormente, alocamos serviços e aplicações públicas que precisam ter acesso direto à
internet. No exemplo a seguir, temos a CDN utilizando o **CloudFront** da AWS, que faz o trabalho de servir nosso
conteúdo estático de forma segura, não expondo a origem real de onde o conteúdo está. Depois temos os **Load Balancers**
em Subnets Públicas, pois os balanceadores de carga recebem tráfego vindo da internet, neste caso, vindo do CloudFront,
para fazer o trabalho dele, que é distribuir o tráfego entre diferentes endpoints.

*Figura 4 - Arquitetura Subnet Pública (Fonte: elaborado pelo autor, 2024): usuários -> CloudFront -> AWS WAF -> Load
Balancers em subnets públicas, que distribuem o tráfego para os destinos da aplicação.*

Notem que temos um **WAF** depois do CloudFront. Esse é um serviço de Firewall da AWS que nos permite definir regras de
acesso e entrega de conteúdo; nele, podemos colocar regras do tipo "somente acessos vindos do Brasil estarão
disponíveis". Neste caso, quaisquer acessos vindos de fora do Brasil serão negados. Podemos até mesmo criar uma lista de
negação, adicionando IPs e redes que serão bloqueadas para acessar nosso site/conteúdo.

Com ele podemos definir diversas regras a fim de limitar o acesso e entregar a destinos específicos. Esse é um serviço
fundamental para controlar a segurança de nossas aplicações públicas.

Cada Subnet tem seu papel fundamental na segurança da rede e das aplicações e é muito importante entender e saber
diferenciar um serviço/aplicação que deve ser público ou privado para não comprometer a segurança da infraestrutura.

> **💡 Complemento: boas práticas de rede.**
>
> - Coloque em subnet pública **apenas** o que precisa receber tráfego da internet (ALB/NLB internet-facing, NAT
>   Gateway, eventualmente bastion). Aplicações, workers e bancos ficam em subnets privadas.
> - Em vez de bastion com SSH aberto, use **SSM Session Manager** (sem porta 22 aberta).
> - Encadeie Security Groups: o SG da aplicação aceita tráfego **só do SG do ALB**; o SG do banco aceita **só do SG da
>   aplicação**. Evite `0.0.0.0/0` em portas que não sejam 80/443 do load balancer.
> - Restringir métodos HTTP (GET público, DELETE interno) se faz em camada 7: rotas do API Gateway, regras do WAF ou do
>   ALB, e autorização na própria API. Security Group não enxerga método HTTP.
> - Para a origem do CloudFront em S3, use **OAC (Origin Access Control)**, mantendo o bucket privado.
> - Habilite **VPC Flow Logs** para investigar tráfego aceito/rejeitado.

### O que você viu nesta aula?

Você viu nesta aula como as redes são definidas na AWS utilizando o serviço chamado VPC e aprendeu sobre as principais
funcionalidades que fazem parte dos serviços VPC, como Subnets, Route Table, Internet Gateway e NAT Gateway.

Você aprendeu também sobre a segurança na rede com Security Groups e ACL, VPN e Transit Gateway, sobre o modelo OSI e
suas camadas de forma detalhada e, por fim, sobre o modelo TCP/IP, que atualmente está mais parecido com o modelo OSI.

**Palavras-chave da aula:** Rede, OSI, TCP/IP, VPC, AWS.

### Referências da aula

- AWS. *O que são redes de computadores?*, 2023. <https://aws.amazon.com/pt/what-is/computer-networking/>
- FORTINET. *O que é um modelo TCP/IP de protocolo de controle de transmissão?*, 2024. <https://www.fortinet.com/br/resources/cyberglossary/tcp-ip>
- MATHEUS, Y. *Como calcular máscaras de sub-rede de forma simples*. Alura, 2023. <https://www.alura.com.br/artigos/como-calcular-mascaras-de-sub-rede>
- MATHEUS, Y. *Saiba o que é o modelo OSI e quais são suas camadas*. Alura, 2023. <https://www.alura.com.br/artigos/conhecendo-o-modelo-osi>

### Pontos-chave

- VPC é a rede virtual isolada, regional, definida por um bloco CIDR; subnets são fatias desse bloco, cada uma em uma AZ.
- Subnet pública = route table com rota `0.0.0.0/0` para o Internet Gateway; privada sai (se precisar) via NAT Gateway.
- Security Group é stateful e por instância; NACL é stateless e por subnet.
- OSI tem 7 camadas (Física, Enlace, Rede, Transporte, Sessão, Apresentação, Aplicação); TCP/IP tem 4 (ou 5 na versão
  atualizada).
- TCP é orientado à conexão e confiável; UDP é sem conexão, mais rápido e usado em streaming e jogos.
- Bancos, backends e ambientes de dev/teste ficam em subnets privadas; LBs, CDN e frontends voltados à internet ficam na
  borda pública.
- API Gateway, CloudFront e WAF permitem expor apenas o necessário e filtrar acessos (ex.: bloqueio geográfico).
- NAT Gateway e IPv4 públicos geram custo contínuo: apague recursos de laboratório.

---

## Aula 3 - Explorando a EC2

### O que vem por aí?

Nesta aula, vamos entender melhor como o AWS EC2 funciona, suas arquiteturas e tipos de distribuições disponíveis para a
criação de uma máquina virtual na AWS, além de toda gama de funcionalidades que cobrem o AWS EC2, incluindo EBS, AMIs,
Snapshots, Key Pairs, Auto Scaling etc.

Depois, vamos compreender o que são e cada opção de pagamentos de uma EC2, entendendo melhor sobre Instâncias Spot,
Savings Plans, Instâncias Reservadas e Dedicadas. Com essas informações, criaremos nossa primeira instância na AWS.

### Hands on

Nesta aula vamos entender tudo sobre o AWS EC2 e criar nossa primeira instância a partir do conhecimento adquirido.
Além disso, vamos realizar a criação de EBS, Key Pairs e Elastic IPs para garantir o pleno funcionamento de nossa
instância.

> **💡 Complemento: os blocos da EC2 (tratados no vídeo).**
>
> - **Instância:** máquina virtual. O **tipo** define CPU/memória/rede, no padrão `família + geração + atributos .
>   tamanho`, ex.: `t3.micro`, `m7g.large` (`g` = Graviton/ARM), `c7i.xlarge` (`i` = Intel). Famílias: **T**
>   (burstable, uso geral com créditos de CPU), **M** (uso geral), **C** (computação), **R/X** (memória),
>   **I/D** (armazenamento), **P/G** (GPU).
> - **Arquiteturas:** `x86_64` (Intel/AMD) e `arm64` (AWS Graviton, geralmente melhor custo/benefício; exige imagem
>   compatível, o que importa para containers multi-arch).
> - **AMI (Amazon Machine Image):** o "molde" da instância (SO + software + mapeamento de discos). Exemplos de
>   distribuições: Amazon Linux 2023, Ubuntu, Red Hat, SUSE, Debian, Windows Server, macOS (em hosts dedicados Mac).
> - **EBS (Elastic Block Store):** disco de bloco em rede, **preso a uma AZ**. Tipos: `gp3` (SSD padrão recomendado,
>   desempenho configurável independente do tamanho), `gp2` (legado), `io1/io2` (IOPS provisionado), `st1`/`sc1`
>   (HDD). **Instance store** é disco local efêmero: perde os dados ao parar/encerrar.
> - **Snapshot:** backup incremental de um volume EBS, armazenado de forma regional (no S3 gerenciado pela AWS); pode
>   ser copiado entre regiões e usado para criar AMIs ou volumes em outra AZ.
> - **Key Pair:** par de chaves para SSH (Linux) ou para descriptografar a senha de administrador (Windows). A AWS
>   guarda só a chave pública; a privada (`.pem`) é baixada **uma única vez**.
> - **Elastic IP:** IPv4 público estático, que você pode remapear entre instâncias.
> - **User data:** script executado no primeiro boot (via cloud-init) para instalar e configurar software.
> - **Auto Scaling Group (ASG):** mantém N instâncias saudáveis a partir de um **Launch Template**, escalando por
>   métricas (ex.: CPU média de 50%) e substituindo instâncias que falham.

> **💡 Complemento: criando a primeira instância (equivalente ao hands on).**
>
> Passos no console (*Launch instance*): nome/tags; AMI; tipo de instância; key pair; rede (VPC, subnet, IP público
> automático, Security Group); armazenamento (volume raiz EBS `gp3`); em *Advanced details*, IAM instance profile,
> **metadata version = V2 only** e user data. Pelo CLI:
>
> ```bash
> aws ec2 create-key-pair --key-name minha-chave --query 'KeyMaterial' --output text > minha-chave.pem
> chmod 400 minha-chave.pem
> aws ec2 run-instances \
>   --image-id ami-xxxxxxxx \
>   --instance-type t3.micro \
>   --key-name minha-chave \
>   --subnet-id subnet-xxxx \
>   --security-group-ids sg-xxxx \
>   --iam-instance-profile Name=app-ec2-profile \
>   --metadata-options HttpTokens=required,HttpEndpoint=enabled \
>   --block-device-mappings '[{"DeviceName":"/dev/xvda","Ebs":{"VolumeSize":8,"VolumeType":"gp3"}}]'
> aws ec2 allocate-address --domain vpc
> aws ec2 associate-address --instance-id i-xxxx --allocation-id eipalloc-xxxx
> ssh -i minha-chave.pem ec2-user@<ip-publico>
> ```
>
> O usuário SSH depende da AMI: `ec2-user` (Amazon Linux), `ubuntu` (Ubuntu), `admin` (Debian).

> **💡 Complemento (atualização): IMDSv2.** O *Instance Metadata Service* (`169.254.169.254`) entrega à instância
> dados como ID, região e as **credenciais temporárias da role**. A versão 1 respondia a qualquer GET e foi explorada
> em ataques de SSRF (o vazamento da Capital One em 2019 é o caso clássico). A **IMDSv2** exige um token de sessão
> obtido via `PUT`; novas AMIs e contas já vêm configuradas para exigir v2 em muitos casos, mas confira sempre
> `HttpTokens=required`:
>
> ```bash
> TOKEN=$(curl -s -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600")
> curl -s -H "X-aws-ec2-metadata-token: $TOKEN" http://169.254.169.254/latest/meta-data/instance-id
> ```

> **💡 Complemento: ciclo de vida e o que é cobrado.**
>
> | Estado | Cobra computação? | Cobra EBS? |
> |---|---|---|
> | `running` | sim (por segundo para Linux, mínimo de 60 s) | sim |
> | `stopped` | não | **sim** (volumes continuam existindo) |
> | `terminated` | não | volume raiz é apagado se `DeleteOnTermination=true`; volumes extras podem ficar órfãos e cobrando |
>
> Armadilhas: Elastic IP e IPv4 público são cobrados por hora; snapshots esquecidos acumulam custo; e, ao parar e
> iniciar, a instância normalmente muda de host físico e o IP público automático muda (o Elastic IP não).

> **💡 Complemento: opções de compra de EC2.**
>
> | Modelo | Como funciona | Quando usar |
> |---|---|---|
> | **On-Demand** | Paga pelo uso, sem compromisso | Cargas imprevisíveis, testes |
> | **Savings Plans** | Compromisso de US$/hora por 1 ou 3 anos; *Compute Savings Plans* valem para EC2, Fargate e Lambda, independente de família/região | Base estável de consumo; a opção mais flexível de desconto |
> | **Reserved Instances** | Compromisso de 1 ou 3 anos em tipo/região (Standard ou Convertible) | Cargas estáveis; hoje a AWS recomenda Savings Plans na maioria dos casos |
> | **Spot** | Capacidade ociosa com grande desconto (até cerca de 90%), mas pode ser **interrompida com aviso de 2 minutos** | Workloads tolerantes a falha: batch, CI, nodes stateless de EKS |
> | **Dedicated Instances / Dedicated Hosts** | Hardware não compartilhado com outros clientes; Host dá visibilidade de sockets/cores | Licenciamento por núcleo (BYOL), compliance |
> | **Capacity Reservations** | Reserva capacidade numa AZ, pagando On-Demand | Garantir capacidade para eventos |
>
> **Free Tier (verificar):** historicamente eram 750 h/mês de `t2.micro`/`t3.micro` por 12 meses. Para contas criadas
> a partir de 15/07/2025 a AWS mudou o modelo para créditos (plano gratuito com prazo e valor limitados). Confira a
> página oficial do Free Tier antes de contar com gratuidade.

### Saiba mais: EC2 com Elastic Load Balancing

A construção de aplicações escaláveis e altamente disponíveis é um desafio comum para arquitetos(as) de TI e
desenvolvedores(as). A Amazon Web Services (AWS) fornece soluções robustas para enfrentar esse desafio e entre elas está
o **Elastic Load Balancing (ELB)** e o **Amazon Elastic Compute Cloud (EC2)**. A combinação dessas tecnologias permite
a criação de arquiteturas resilientes, capazes de gerenciar e distribuir automaticamente o tráfego de rede entre várias
instâncias, garantindo desempenho, disponibilidade e segurança.

Quando uma aplicação é implantada utilizando instâncias EC2 por trás de um ELB, o ELB atua como um ponto de entrada
único para todo o tráfego de rede que chega à aplicação. Ele distribui automaticamente as solicitações recebidas para as
instâncias EC2 registradas em seus grupos de destino. Essa distribuição pode ser configurada de acordo com diferentes
políticas e requisitos, como balanceamento baseado em round-robin, roteamento baseado em conteúdo ou balanceamento de
carga com baixa latência.

#### Benefícios de utilizar um ELB na frente de uma EC2

- **Alta Disponibilidade:** o ELB distribui o tráfego de entrada entre várias instâncias EC2 localizadas em diferentes
  zonas de disponibilidade (AZs). Se uma instância ou uma AZ falhar, o ELB redireciona automaticamente o tráfego para
  instâncias saudáveis em outras zonas, garantindo que a aplicação continue operando sem interrupções.
- **Escalabilidade Automática:** o ELB trabalha em conjunto com o Auto Scaling, permitindo que o número de instâncias
  EC2 aumente ou diminua automaticamente com base na demanda do tráfego. Durante picos de tráfego o Auto Scaling pode
  lançar novas instâncias EC2 e durante períodos de baixa utilização pode encerrar instâncias ociosas, otimizando
  custos.
- **Distribuição Inteligente do Tráfego:** o ELB realiza verificações de saúde nas instâncias EC2 para garantir que
  apenas instâncias saudáveis recebam tráfego. Isso melhora a resiliência da aplicação, pois instâncias problemáticas
  são automaticamente excluídas da distribuição de tráfego até que estejam saudáveis novamente.
- **Segurança e Gerenciamento de Certificados:** o ELB pode ser configurado para usar certificados SSL/TLS,
  proporcionando criptografia de ponta a ponta para tráfego HTTP/HTTPS. Com a integração com o AWS Certificate Manager
  (ACM), o gerenciamento de certificados é simplificado, permitindo a fácil criação e renovação de certificados
  SSL/TLS.
- **Roteamento Avançado:** usando um Application Load Balancer (ALB), as solicitações podem ser roteadas para diferentes
  grupos de destino com base em regras específicas, como cabeçalhos HTTP, caminhos de URL ou parâmetros de consulta.
  Isso é especialmente útil para arquiteturas de microsserviços ou aplicações que servem diferentes tipos de conteúdo ou
  serviços.
- **Facilidade de Integração:** o ELB se integra perfeitamente com outros serviços da AWS, como Amazon Route 53 (para
  DNS), AWS WAF (para firewall de aplicações web) e AWS CloudTrail (para auditoria e conformidade), proporcionando uma
  infraestrutura segura e bem monitorada.

> **💡 Complemento:** um **target group** pode ter como destino instâncias, **IPs** (usado com pods do EKS em modo
> `ip`) ou funções Lambda (ALB). O health check é configurável (caminho, ex.: `/health`, intervalo, limiares). Quando
> o TLS termina no ALB, o tráfego até o destino pode seguir em HTTP dentro da VPC ou ser recriptografado; "ponta a
> ponta" de verdade exige HTTPS também no target. Um ALB também é cobrado por hora + LCU, mesmo sem tráfego.

### Tipos de Load Balancers da AWS

Os load balancers são componentes essenciais para distribuir o tráfego de rede ou de aplicações entre vários servidores,
garantindo alta disponibilidade e escalabilidade. A AWS oferecia quatro tipos diferentes de load balancers como parte do
Elastic Load Balancing (ELB):

- Classic Load Balancer (CLB).
- Application Load Balancer (ALB).
- Network Load Balancer (NLB).
- Gateway Load Balancer (GWLB).

Cada um desses load balancers foi projetado para atender a diferentes tipos de aplicações e requisitos de rede.

#### 1. Classic Load Balancer (CLB)

O CLB é a primeira geração de load balancers oferecidos pela AWS. Ele opera tanto na camada 4 (transporte) quanto na
camada 7 (aplicação) do modelo OSI, embora ofereça menos funcionalidades avançadas em comparação com ALB e NLB. O CLB
era mais adequado para aplicações legadas, sendo capaz de balancear cargas HTTP, HTTPS, TCP e SSL.

Porém, o Classic Load Balancer deixou de ter suporte e atualmente é utilizado somente no EKS quando um Service é do tipo
Load Balancer; ele deixará de ser utilizado em breve para essa finalidade.

> **💡 Complemento (atualização/precisão):** o CLB é **legado** (a AWS recomenda migrar para ALB/NLB; ainda é possível
> criá-lo em VPC, mas não recebe recursos novos), e não é que só o EKS o use. No EKS, um `Service` do tipo
> `LoadBalancer` sem anotações cai no controlador *in-tree* do Kubernetes, que historicamente criava um CLB. A
> recomendação atual é instalar o **AWS Load Balancer Controller**, que cria **NLB** para `Service`
> (`service.beta.kubernetes.io/aws-load-balancer-type: external`) e **ALB** para `Ingress`. No **EKS Auto Mode** essa
> capacidade já vem embutida.

#### 2. Application Load Balancer (ALB)

O ALB opera na camada 7 do modelo OSI (camada de aplicação) e é ideal para balanceamento de carga de tráfego HTTP e
HTTPS. O ALB oferece roteamento avançado baseado em conteúdo, o que significa que pode rotear solicitações para
diferentes instâncias de backend com base no conteúdo da solicitação.

**Casos de uso do ALB:**

- **Aplicações Web com Roteamento Avançado:** quando se tem uma aplicação web complexa que requer roteamento baseado em
  URLs, cabeçalhos ou métodos HTTP, o ALB é a escolha ideal. Por exemplo: uma aplicação de e-commerce que precisa rotear
  solicitações para diferentes microsserviços com base no caminho da URL (`/checkout`, `/products`, `/cart`) pode usar
  ALB para esse propósito.
- **Ambientes Multi-tenant:** em cenários nos quais múltiplos inquilinos (clientes) compartilham a mesma
  infraestrutura, o ALB pode rotear solicitações de acordo com os domínios ou subdomínios para diferentes conjuntos de
  instâncias de backend. Isso é comum em soluções SaaS (Software as a Service).
- **Contêineres e Microsserviços:** para aplicações que utilizam contêineres (como com Amazon ECS ou Kubernetes), o ALB
  pode distribuir o tráfego entre várias tarefas ou pods, fornecendo resiliência e balanceamento de carga eficiente.

#### 3. Network Load Balancer (NLB)

Já o NLB opera na camada 4 do modelo OSI (camada de transporte) e é projetado para lidar com grandes volumes de tráfego,
proporcionando baixa latência. Ele é capaz de balancear tráfego TCP, UDP e TLS (Transport Layer Security) e é ideal para
aplicativos que exigem alta performance.

**Casos de uso do NLB:**

- **Aplicações em Tempo Real:** aplicações que requerem alta taxa de transferência e baixa latência, como jogos online,
  sistemas de trading financeiro e plataformas de comunicação em tempo real, beneficiam-se do uso do NLB.
- **Serviços de Banco de Dados:** o NLB é ideal para balancear a carga de serviços de banco de dados que utilizam
  conexões TCP/UDP, como clusters de banco de dados MySQL ou PostgreSQL, proporcionando alta disponibilidade e
  desempenho.
- **IoT (Internet das Coisas):** para arquiteturas de IoT que demandam alta taxa de entrada e saída de dados, o NLB pode
  gerenciar eficientemente grandes volumes de tráfego de dispositivos conectados, assegurando uma conectividade estável
  e rápida.

> **💡 Complemento:** o NLB oferece **IP estático por AZ** (pode usar Elastic IP), preserva o IP de origem do cliente e
> desde 2023 suporta Security Groups. É o destino típico do **VPC Link** da REST API do API Gateway. Para bancos
> gerenciados (RDS/Aurora) normalmente não se usa NLB: o próprio serviço fornece endpoints (writer/reader) e o
> **RDS Proxy** cuida de pooling.

#### 4. Gateway Load Balancer (GWLB)

Por fim, temos o GWLB, que combina a capacidade de um gateway de rede com a capacidade de um load balancer, operando
principalmente na camada 3 do modelo OSI (camada de rede). Ele é projetado para balancear tráfego entre dispositivos
virtuais de rede (como firewalls e sistemas de detecção de intrusão) de maneira transparente.

**Casos de uso do GWLB:**

- **Segurança e Monitoramento:** em infraestruturas que requerem inspeção profunda de pacotes, detecção de intrusão ou
  firewalls de próxima geração, o GWLB pode distribuir o tráfego entre várias instâncias de dispositivos de segurança,
  garantindo que a inspeção de pacotes não se torne um gargalo.
- **Gerenciamento de Tráfego em Redes Corporativas:** para grandes redes corporativas que utilizam múltiplos
  dispositivos de gerenciamento de tráfego, o GWLB pode distribuir o tráfego de entrada e saída entre esses
  dispositivos, assegurando resiliência e desempenho.
- **Integração de Serviços de Terceiros:** empresas que utilizam serviços de segurança ou monitoramento de terceiros
  podem integrar esses serviços em sua infraestrutura AWS usando o GWLB, balanceando a carga entre várias instâncias
  desses serviços.

| Load Balancer | Camada OSI | Protocolos | Uso típico |
|---|---|---|---|
| CLB (legado) | 4 e 7 | HTTP, HTTPS, TCP, SSL | Aplicações legadas |
| ALB | 7 | HTTP, HTTPS (gRPC, WebSocket) | Web, microsserviços, roteamento por path/host/header |
| NLB | 4 | TCP, UDP, TLS | Alta performance, baixa latência, IP estático |
| GWLB | 3 | IP (encapsulamento GENEVE) | Appliances de segurança (firewall, IDS/IPS) |

*(Tabela-resumo montada a partir do texto da aula; gRPC/WebSocket e GENEVE são acréscimos meus.)*

Agora entendemos que a combinação de instâncias Amazon EC2 com o Elastic Load Balancer oferece uma solução robusta e
eficiente para a construção de aplicações escaláveis, resilientes e de alta disponibilidade. Essa arquitetura permite
distribuir automaticamente o tráfego de rede, assegurando que as aplicações possam lidar com variações de carga e manter
um desempenho consistente e seguro.

> **💡 Complemento: boas práticas de EC2.**
>
> - Instâncias de aplicação em **subnet privada**, atrás de ALB/NLB, num **ASG multi-AZ**.
> - Exija **IMDSv2**, use **instance profile** (role) e nunca grave access keys em `~/.aws/credentials` da instância.
> - Acesso administrativo via **SSM Session Manager**, sem porta 22 aberta para `0.0.0.0/0`.
> - Criptografe EBS por padrão (*EBS encryption by default*, com KMS).
> - Trate instâncias como descartáveis: configure por **user data / AMI própria / IaC**, não manualmente.
> - Patches: SSM Patch Manager ou AMIs renovadas (EC2 Image Builder).

### O que você viu nesta aula?

Você viu detalhadamente como funciona o AWS EC2, além de conhecer mais a fundo sobre o Elastic Load Balancing e como
podemos utilizá-lo com o EC2, entendendo sobre ele e suas funcionalidades principais. A partir de agora, vocês
conseguirão entender e criar suas próprias instâncias na AWS.

**Palavras-chave da aula:** EC2, Spot, ELB, EBS.

### Referências da aula

- AWS. *Amazon EC2*, 2024. <https://aws.amazon.com/pt/ec2/>
- AWS. *Instance Types Amazon EC2*, 2024. <https://aws.amazon.com/pt/ec2/instance-types/>
- AWS. *Preço sob demanda do Amazon EC2*, 2024. <https://aws.amazon.com/pt/ec2/pricing/on-demand/>

### Pontos-chave

- EC2 é a máquina virtual da AWS (IaaS); o cliente é responsável por SO, patches e configuração.
- Os blocos de uma instância: tipo, AMI, EBS (zonal), snapshots, key pair, Security Group, Elastic IP, Auto Scaling.
- Modelos de compra: On-Demand, Savings Plans, Reserved, Spot (interrompível) e Dedicated.
- O ELB é o ponto de entrada único: distribui tráfego entre AZs, faz health checks, integra com ACM, WAF e Route 53.
- ELB + Auto Scaling = alta disponibilidade e elasticidade com custo ajustado à demanda.
- ALB (L7, roteamento por path/host/header), NLB (L4, TCP/UDP/TLS, baixa latência), GWLB (L3, appliances), CLB (legado).
- No EKS, prefira o AWS Load Balancer Controller (ALB para Ingress, NLB para Service) ao CLB padrão.
- Exija IMDSv2 e use roles nas instâncias; recursos parados (EBS, EIP, snapshots) continuam cobrando.

---

## Aplicação no Tech Challenge da Fase 4

O Tech Challenge da Fase 4 leva o **FIAP Cloud Games** para a nuvem, orquestrado com Kubernetes gerenciado (**Amazon
EKS**). Os três fundamentos destas aulas são a base dessa entrega:

### Rede (VPC) para o cluster EKS

- Crie uma VPC dedicada (ex.: `10.0.0.0/16`) com **subnets públicas e privadas em pelo menos 2 AZs**. O EKS exige
  subnets em no mínimo duas AZs para o control plane, e isso também dá alta disponibilidade aos nodes.
- **Subnets privadas:** nodes (managed node group, Karpenter ou Auto Mode) e pods das APIs (usuários, jogos, pagamentos).
  Dimensione com folga (ex.: `/19` ou `/20`), porque com o VPC CNI cada pod recebe um IP da subnet.
- **Subnets públicas:** ALB/NLB internet-facing e NAT Gateway. Marque as subnets com as tags que o AWS Load Balancer
  Controller usa para descobri-las: `kubernetes.io/role/elb = 1` (públicas) e `kubernetes.io/role/internal-elb = 1`
  (privadas).
- Banco de dados (RDS/Aurora) em subnets privadas próprias, com Security Group aceitando só o SG dos nodes/pods.
- **Custo:** para o laboratório, um único NAT Gateway (aceitando perder HA de saída) reduz gasto; use VPC endpoints
  (ECR, S3, Secrets Manager, CloudWatch Logs) para tráfego privado e destrua tudo ao terminar (`terraform destroy`,
  `eksctl delete cluster`).

### IAM: roles em vez de chaves

- **Cluster role** (`AmazonEKSClusterPolicy`) e **node role** (`AmazonEKSWorkerNodePolicy`,
  `AmazonEC2ContainerRegistryReadOnly`, `AmazonEKS_CNI_Policy`; ou, melhor, a policy do CNI via IRSA/Pod Identity).
- **Permissões por pod:** cada microsserviço que acessa AWS (ex.: ler segredo, publicar em SQS) usa sua própria role com
  least privilege, via **EKS Pod Identity** (recomendação atual, com o add-on `eks-pod-identity-agent`) ou **IRSA**
  (IAM Roles for Service Accounts, baseado no OIDC provider do cluster). Assim nenhum pod herda as permissões amplas
  do node.
- Acesso de pessoas ao cluster via **EKS access entries** (substituto moderno do `aws-auth` ConfigMap), mapeando roles
  do IAM Identity Center.

### CI/CD com GitHub Actions via OIDC

- Configure o **OIDC provider** `token.actions.githubusercontent.com` no IAM e uma role com trust policy restrita ao seu
  repositório/branch. O workflow usa `aws-actions/configure-aws-credentials` com `role-to-assume`, sem
  `AWS_ACCESS_KEY_ID` em secrets:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": { "Federated": "arn:aws:iam::<ACCOUNT_ID>:oidc-provider/token.actions.githubusercontent.com" },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringEquals": { "token.actions.githubusercontent.com:aud": "sts.amazonaws.com" },
        "StringLike": { "token.actions.githubusercontent.com:sub": "repo:<org>/<repo>:ref:refs/heads/main" }
      }
    }
  ]
}
```

```yaml
permissions:
  id-token: write
  contents: read
steps:
  - uses: aws-actions/configure-aws-credentials@v4
    with:
      role-to-assume: arn:aws:iam::<ACCOUNT_ID>:role/github-actions-deploy
      aws-region: us-east-1
```

- A role do pipeline recebe só o necessário: push no ECR e acesso ao cluster (access entry) para `kubectl`/Helm.

### Segredos com AWS Secrets Manager

- Connection strings do banco, chaves JWT e credenciais de terceiros ficam no **Secrets Manager** (com rotação
  automática para RDS), nunca em `appsettings.json`, variáveis no repositório ou imagem Docker.
- No cluster, consuma via **Secrets Store CSI Driver + ASCP** ou **External Secrets Operator**, autenticando com a role
  do pod (Pod Identity/IRSA). Em .NET, alternativamente, leia direto com o SDK
  (`AWSSDK.SecretsManager`/`Amazon.Extensions.Configuration.SystemsManager`).

### Por que não rodar os containers manualmente em EC2

- O enunciado **proíbe IaaS isolado**: subir `docker run` em instâncias EC2 avulsas não atende ao requisito de
  orquestração gerenciada.
- Pela responsabilidade compartilhada (Aula 1), em EC2 você assume SO, patches, agendamento de containers, restart em
  falhas, service discovery, balanceamento e escala, tudo manualmente. O EKS (mais o ALB via Load Balancer Controller e
  o HPA/Karpenter) entrega isso de forma declarativa.
- Os nodes do EKS **são** instâncias EC2 (ou Fargate), então o que você aprendeu na Aula 3 (tipos, Spot, Graviton,
  IMDSv2, EBS) continua valendo: só que gerenciado por node groups/Karpenter/Auto Mode, não por você instância a
  instância.

### Glossário

| Termo | Significado |
|---|---|
| **AZ (Availability Zone)** | Um ou mais data centers isolados dentro de uma região |
| **CIDR** | Notação de bloco de IPs (`10.0.0.0/16`); o número após a barra é o tamanho do prefixo de rede |
| **IGW** | Internet Gateway: conecta a VPC à internet |
| **NAT Gateway** | Saída para a internet de subnets privadas, sem entrada; cobrado por hora + GB |
| **Security Group** | Firewall stateful por interface/instância, só regras de allow |
| **NACL** | Firewall stateless por subnet, com allow e deny |
| **Role** | Identidade IAM assumível que gera credenciais temporárias via STS |
| **Trust policy** | Parte da role que diz quem pode assumi-la |
| **Least privilege** | Conceder só as permissões estritamente necessárias |
| **OIDC** | OpenID Connect: federação usada por GitHub Actions e pelo IRSA do EKS |
| **IRSA / Pod Identity** | Mecanismos do EKS para dar uma role IAM a um service account/pod |
| **IMDSv2** | Versão com token de sessão do serviço de metadados da EC2 |
| **AMI** | Imagem usada para criar instâncias EC2 |
| **EBS** | Disco de bloco em rede, zonal, para EC2 |
| **ALB / NLB** | Load balancers de camada 7 / camada 4 |
| **Spot** | Capacidade EC2 com desconto, interrompível com aviso de 2 minutos |
| **EKS** | Kubernetes gerenciado da AWS |
