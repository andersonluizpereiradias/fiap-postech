# 2. Serverless Apps

> Categoria 2 de 5 — Classificação dos resumos em PDF da pasta `resumos-fase-3`.
> Disciplina de origem: **Serverless Apps** (Fase 3 do PósTech FIAP em Arquitetura de Sistemas .NET).

## Resumo funcional das aulas relacionadas

### Aula 1 — Fundamentos de Serverless
- **Objetivo:** introduzir o modelo de computação sem servidor (pay-per-use, sem provisionamento manual de infraestrutura).
- **Conceitos-chave:** AWS Lambda e Azure Functions; arquitetura orientada a eventos (API Gateway → Functions → banco de dados); exemplos reais (app ToDo 100% serverless na AWS com Cognito, API Gateway, Lambdas e DynamoDB); cenários de uso: processamento de eventos em tempo real, APIs/microsserviços, integração de sistemas, automação de tarefas agendadas, backends web/mobile.
- **Mercado:** Netflix usa AWS Lambda para escalar automaticamente sem gerenciar servidores.

### Aula 2 — Desenvolvimento de Funções Serverless (ambiente local com LocalStack)
- **Objetivo:** configurar um ambiente local que simula os serviços da AWS (Lambda, S3, DynamoDB, SQS, API Gateway) sem custos de nuvem.
- **Conceitos-chave:** instalação do LocalStack via Docker, configuração de um profile `localstack` no AWS CLI, criação de bucket S3 local e publicação de um site estático como exemplo prático.
- **Aplicação prática:** permite desenvolver e testar aplicações serverless AWS localmente antes de subir para produção, reduzindo custo e risco.

### Aula 3 — Desenvolvimento de Funções Serverless AWS
- **Objetivo:** criar e executar Lambda Functions reais na AWS, entendendo os principais *triggers*.
- **Conceitos-chave:** integração Lambda + API Gateway (exposição como endpoints REST/GraphQL), Lambda + S3 (processamento automático de arquivos via eventos `ObjectCreated`/`ObjectRemoved` — ex.: geração de thumbnails), exemplo prático de função `HelloWorldFunction` em Node.js.
- **Mercado:** Netflix usa Lambda para processamento de logs, monitoramento de dados e configuração dinâmica de recursos.

### Aula 4 — Desenvolvimento de Funções Serverless Azure
- **Objetivo:** primeiros passos com o Azure Functions.
- **Conceitos-chave:** criação de function com HTTP Trigger via portal Azure (JavaScript e C#); exemplo evoluído que consulta uma API externa (CoinGecko) para retornar o preço do Bitcoin em BRL usando `HttpClient` e `Newtonsoft.Json`.
- **Tendências:** Durable Functions para workflows com estado; integração nativa com o ecossistema Microsoft (Office 365, Power BI, Azure DevOps).

### Aula 5 — Monitoramento e Segurança em Serverless
- **Objetivo:** monitorar aplicações serverless usando as ferramentas nativas de cada nuvem.
- **Conceitos-chave:** **Azure Monitor** (Insights, Detection/Triage/Diagnosis, Log Analytics, painéis customizados) e **AWS CloudWatch** (execuções, duração, erros, timeouts, consumo de memória de Lambdas, dashboards e alarmes).
- **Aplicação prática:** exemplo de alarme para notificar a equipe quando o número de erros de uma Lambda de processamento de pedidos ultrapassa um limite — base para práticas de SRE/DevOps.

### Aula 6 — AWS Step Functions com .NET
- **Objetivo:** orquestrar workflows compostos por várias funções/serviços com controle, rastreabilidade e tratamento de erros.
- **Conceitos-chave:** *State Machine* (conjunto de *states* que descrevem o fluxo completo); integração nativa com Lambda, DynamoDB, S3, SQS/SNS, ECS/Fargate, API Gateway, Glue, SageMaker, EventBridge; SDK `AWSSDK.StepFunctions` para .NET; exemplo de fluxo de cadastro de cliente com 7 etapas orquestradas (validação → checagem de CPF → criação → e-mail → contrato PDF → S3 → notificação de vendas).
- **Tendências:** Workflow Studio (low-code visual), orquestração multi-cloud via chamadas HTTP, integração com IA/ML (SageMaker) e EventBridge.

---

## Resumo funcional da categoria

Esta trilha cobre o ciclo completo de uma aplicação **Serverless**: (1) entender o modelo de execução sob demanda e seus benefícios de custo/escala; (2) desenvolver e testar funções localmente (LocalStack) antes de publicar; (3) implementar funções reais na AWS (Lambda) e no Azure (Azure Functions), integrando-as a gatilhos como API Gateway e S3; (4) monitorar essas funções com as ferramentas nativas de cada provedor (CloudWatch/Azure Monitor); e (5) orquestrar fluxos de negócio multi-etapa com AWS Step Functions. Essa base é essencial para decidir quando usar Serverless em vez de containers/microsserviços tradicionais dentro do projeto da fase, especialmente em cenários orientados a eventos ou com cargas de trabalho variáveis.
