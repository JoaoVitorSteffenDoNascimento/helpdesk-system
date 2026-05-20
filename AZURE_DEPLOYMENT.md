# Deploy no Azure

## 🚀 Opções de Deploy

### 1. **Azure Container Instances (ACI)** - Mais Simples
- Sem gerenciamento de VMs
- Pague pelo que usar
- Bom para aplicações pequenas/médias
- ~$0.015/vCPU/hora

### 2. **Azure App Service** - Mais Fácil
- PaaS completo
- Auto-scaling
- CI/CD integrado
- ~$15-60/mês

### 3. **Azure Container Apps** - Recomendado para Microserviços
- Serverless containers
- Auto-scaling automático
- Suporte nativo a múltiplos containers
- ~$0.000347/vCPU/segundo

### 4. **Azure Kubernetes Service (AKS)** - Mais Completo
- Kubernetes gerenciado
- Auto-healing
- Multi-region
- ~$0.10/vCPU/hora

---

## 📋 Setup Passo a Passo: Azure Container Apps (Recomendado)

### Pré-requisitos
```bash
# Instalar Azure CLI
# macOS/Linux:
brew install azure-cli

# Windows:
# Download em https://aka.ms/installazurecliwindows
```

### Passo 1: Login no Azure
```bash
az login
# Abre navegador para autenticar

# Listar subscriptions
az account list --output table

# Selecionar subscription (se tiver múltiplas)
az account set --subscription "ID_DA_SUBSCRIPTION"
```

### Passo 2: Criar Resource Group
```bash
# Resource Group é um container lógico no Azure

az group create \
  --name helpdesk-rg \
  --location eastus
```

### Passo 3: Criar Azure Container Registry (ACR)
```bash
# Seu registro privado de imagens Docker

az acr create \
  --resource-group helpdesk-rg \
  --name helpdeskregistry \
  --sku Basic

# Nota: Nomes devem ser únicos globalmente (tente adicionar sua initial)
# Ex: johelpdeskregistry, v2helpdeskregistry
```

### Passo 4: Fazer Push das Imagens
```bash
# Login no ACR
az acr login --name helpdeskregistry

# Tag suas imagens
docker tag helpdesk-ticket-service helpdeskregistry.azurecr.io/ticket-service:latest
docker tag helpdesk-user-service helpdeskregistry.azurecr.io/user-service:latest
docker tag helpdesk-api-gateway helpdeskregistry.azurecr.io/api-gateway:latest
docker tag helpdesk-frontend helpdeskregistry.azurecr.io/frontend:latest

# Push para ACR
docker push helpdeskregistry.azurecr.io/ticket-service:latest
docker push helpdeskregistry.azurecr.io/user-service:latest
docker push helpdeskregistry.azurecr.io/api-gateway:latest
docker push helpdeskregistry.azurecr.io/frontend:latest

# Verificar imagens
az acr repository list --name helpdeskregistry
```

### Passo 5: Criar Container App Environment
```bash
az containerapp env create \
  --name helpdesk-env \
  --resource-group helpdesk-rg \
  --location eastus
```

### Passo 6: Criar MongoDB com Azure Cosmos DB
```bash
# Opção A: MongoDB no Cosmos DB (recomendado)
az cosmosdb create \
  --name helpdesk-mongodb \
  --resource-group helpdesk-rg \
  --kind MongoDB \
  --locations regionName=eastus

# Opção B: Container MongoDB simples
az container create \
  --resource-group helpdesk-rg \
  --name helpdesk-mongodb \
  --image mongo:7 \
  --cpu 1 \
  --memory 1 \
  --ports 27017
```

### Passo 7: Deploy dos Microserviços

**Ticket Service:**
```bash
az containerapp create \
  --name helpdesk-ticket-service \
  --resource-group helpdesk-rg \
  --environment helpdesk-env \
  --image helpdeskregistry.azurecr.io/ticket-service:latest \
  --target-port 8081 \
  --registry-server helpdeskregistry.azurecr.io \
  --registry-username helpdeskregistry \
  --registry-password $(az acr credential show --name helpdeskregistry --query passwords[0].value -o tsv) \
  --env-vars \
    SPRING_DATA_MONGODB_URI="mongodb://helpdesk-mongodb:27017/helpdesk_tickets" \
    SERVER_PORT=8081 \
    JAVA_OPTS="-Xmx512m -Xms256m" \
  --cpu 0.5 \
  --memory 1Gi \
  --min-replicas 1 \
  --max-replicas 3
```

**User Service:**
```bash
az containerapp create \
  --name helpdesk-user-service \
  --resource-group helpdesk-rg \
  --environment helpdesk-env \
  --image helpdeskregistry.azurecr.io/user-service:latest \
  --target-port 8082 \
  --registry-server helpdeskregistry.azurecr.io \
  --registry-username helpdeskregistry \
  --registry-password $(az acr credential show --name helpdeskregistry --query passwords[0].value -o tsv) \
  --env-vars \
    SPRING_DATA_MONGODB_URI="mongodb://helpdesk-mongodb:27017/helpdesk_users" \
    SERVER_PORT=8082 \
    JAVA_OPTS="-Xmx512m -Xms256m" \
  --cpu 0.5 \
  --memory 1Gi \
  --min-replicas 1 \
  --max-replicas 3
```

**API Gateway:**
```bash
az containerapp create \
  --name helpdesk-api-gateway \
  --resource-group helpdesk-rg \
  --environment helpdesk-env \
  --image helpdeskregistry.azurecr.io/api-gateway:latest \
  --target-port 8080 \
  --ingress external \
  --registry-server helpdeskregistry.azurecr.io \
  --registry-username helpdeskregistry \
  --registry-password $(az acr credential show --name helpdeskregistry --query passwords[0].value -o tsv) \
  --env-vars \
    TICKET_SERVICE_URL="http://helpdesk-ticket-service" \
    USER_SERVICE_URL="http://helpdesk-user-service" \
    SERVER_PORT=8080 \
    JAVA_OPTS="-Xmx512m -Xms256m" \
  --cpu 0.5 \
  --memory 1Gi \
  --min-replicas 1 \
  --max-replicas 3
```

**Frontend:**
```bash
az containerapp create \
  --name helpdesk-frontend \
  --resource-group helpdesk-rg \
  --environment helpdesk-env \
  --image helpdeskregistry.azurecr.io/frontend:latest \
  --target-port 80 \
  --ingress external \
  --registry-server helpdeskregistry.azurecr.io \
  --registry-username helpdeskregistry \
  --registry-password $(az acr credential show --name helpdeskregistry --query passwords[0].value -o tsv) \
  --env-vars \
    VITE_API_BASE_URL="https://helpdesk-api-gateway.region.azurecontainerapps.io" \
  --cpu 0.25 \
  --memory 0.5Gi \
  --min-replicas 1 \
  --max-replicas 3
```

---

## 🤖 Setup Automático: GitHub Actions + Azure

### Passo 1: Criar Service Principal
```bash
az ad sp create-for-rbac \
  --name "github-helpdesk" \
  --role contributor \
  --scopes /subscriptions/SUBSCRIPTION_ID/resourceGroups/helpdesk-rg \
  --json-auth
```

Output será JSON. Copie tudo.

### Passo 2: Adicionar Secret no GitHub
1. Repositório → Settings → Secrets
2. Crie `AZURE_CREDENTIALS` → Cole o JSON inteiro

Crie também:
- `AZURE_REGISTRY_NAME` → helpdeskregistry
- `AZURE_REGISTRY_USERNAME` → (do `az acr credential show`)
- `AZURE_REGISTRY_PASSWORD` → (do `az acr credential show`)
- `AZURE_RESOURCE_GROUP` → helpdesk-rg

### Passo 3: Push para Trigger Deploy
```bash
git push origin master
# ✅ GitHub Actions automaticamente:
# 1. Bilda imagens
# 2. Faz push para ACR
# 3. Deploy no Azure
```

---

## 📊 URLs de Acesso

Depois de deployar:

```bash
# Obter URLs dos serviços
az containerapp show \
  --resource-group helpdesk-rg \
  --name helpdesk-api-gateway \
  --query properties.configuration.ingress.fqdn

az containerapp show \
  --resource-group helpdesk-rg \
  --name helpdesk-frontend \
  --query properties.configuration.ingress.fqdn
```

URLs finais:
```
Frontend:     https://helpdesk-frontend.region.azurecontainerapps.io
API Gateway:  https://helpdesk-api-gateway.region.azurecontainerapps.io
Ticket API:   http://helpdesk-ticket-service (interno)
User API:     http://helpdesk-user-service (interno)
```

---

## 💰 Custo Estimado

**Azure Container Apps:**
- 5 containers × 0.5 vCPU = 2.5 vCPU
- ~$0.000347/vCPU/segundo
- ~$0.25/hora = ~$180/mês

**Se usar Cosmos DB:**
- +$40/mês (free tier com limitações)

**Total: ~$220-260/mês**

**Otimizações:**
- Reduzir `--cpu` para 0.25
- Usar `--min-replicas 0` (scale to zero)
- Usar MongoDB externo (Atlas) em vez de Cosmos

---

## 🔍 Monitorar e Debugar

```bash
# Ver logs
az containerapp logs show \
  --resource-group helpdesk-rg \
  --name helpdesk-api-gateway \
  --follow

# Ver status
az containerapp list \
  --resource-group helpdesk-rg \
  --query "[].{name:name, state:properties.provisioningState, replicas:properties.template.scale.minReplicas}"

# Escalar manualmente
az containerapp update \
  --resource-group helpdesk-rg \
  --name helpdesk-api-gateway \
  --min-replicas 2 \
  --max-replicas 5

# Atualizar imagem
az containerapp update \
  --resource-group helpdesk-rg \
  --name helpdesk-api-gateway \
  --image helpdeskregistry.azurecr.io/api-gateway:v2.0
```

---

## 🗑️ Limpar Recursos

```bash
# Deletar tudo
az group delete \
  --name helpdesk-rg \
  --yes

# Ou deletar individual
az containerapp delete \
  --resource-group helpdesk-rg \
  --name helpdesk-api-gateway \
  --yes
```

---

## 📚 Referências Úteis

- Azure Container Apps: https://learn.microsoft.com/en-us/azure/container-apps/
- Azure CLI: https://learn.microsoft.com/en-us/cli/azure/
- Preços: https://azure.microsoft.com/en-us/pricing/details/container-apps/

