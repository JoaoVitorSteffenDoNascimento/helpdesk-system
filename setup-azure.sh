#!/bin/bash

# Script de setup Azure - Automatiza todo o deploy
# Uso: ./setup-azure.sh <registry-name> <resource-group> <location>
# Exemplo: ./setup-azure.sh myregistry helpdesk-rg eastus

set -e

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Validar argumentos
if [ $# -lt 3 ]; then
    echo -e "${RED}Uso: $0 <registry-name> <resource-group> <location>${NC}"
    echo "Exemplo: $0 myregistry helpdesk-rg eastus"
    exit 1
fi

REGISTRY_NAME=$1
RESOURCE_GROUP=$2
LOCATION=$3
REGISTRY_URL="${REGISTRY_NAME}.azurecr.io"

echo -e "${BLUE}================================${NC}"
echo -e "${BLUE}Azure Helpdesk Deploy Setup${NC}"
echo -e "${BLUE}================================${NC}"
echo ""
echo -e "${YELLOW}Registry: ${NC}${REGISTRY_NAME}"
echo -e "${YELLOW}Resource Group: ${NC}${RESOURCE_GROUP}"
echo -e "${YELLOW}Location: ${NC}${LOCATION}"
echo ""

# Step 1: Verificar Azure CLI
echo -e "${BLUE}[1/8]${NC} Verificando Azure CLI..."
if ! command -v az &> /dev/null; then
    echo -e "${RED}❌ Azure CLI não encontrado${NC}"
    echo "Install: https://docs.microsoft.com/en-us/cli/azure/install-azure-cli"
    exit 1
fi
echo -e "${GREEN}✅ Azure CLI OK${NC}"

# Step 2: Login
echo -e "${BLUE}[2/8]${NC} Login no Azure..."
az account show > /dev/null 2>&1 || az login
echo -e "${GREEN}✅ Login OK${NC}"

# Step 3: Criar Resource Group
echo -e "${BLUE}[3/8]${NC} Criando Resource Group..."
if az group exists --name "${RESOURCE_GROUP}" | grep -q true; then
    echo -e "${YELLOW}⚠️  Resource Group já existe${NC}"
else
    az group create --name "${RESOURCE_GROUP}" --location "${LOCATION}"
    echo -e "${GREEN}✅ Resource Group criado${NC}"
fi

# Step 4: Criar Container Registry
echo -e "${BLUE}[4/8]${NC} Criando Azure Container Registry..."
if az acr show --name "${REGISTRY_NAME}" --resource-group "${RESOURCE_GROUP}" 2>/dev/null; then
    echo -e "${YELLOW}⚠️  Registry já existe${NC}"
else
    az acr create \
        --resource-group "${RESOURCE_GROUP}" \
        --name "${REGISTRY_NAME}" \
        --sku Basic
    echo -e "${GREEN}✅ Registry criado${NC}"
fi

# Step 5: Login no Registry
echo -e "${BLUE}[5/8]${NC} Login no Container Registry..."
az acr login --name "${REGISTRY_NAME}"
echo -e "${GREEN}✅ Login no Registry OK${NC}"

# Step 6: Build e Push das imagens
echo -e "${BLUE}[6/8]${NC} Building e pushing imagens..."

SERVICES=("ticket-service" "user-service" "api-gateway" "frontend")

for service in "${SERVICES[@]}"; do
    echo -e "${YELLOW}▶️  Processando ${service}...${NC}"
    
    # Build
    docker build \
        -t "${REGISTRY_URL}/${service}:latest" \
        -f "${service}/Dockerfile" \
        "${service}/" || {
        echo -e "${RED}❌ Erro ao buildar ${service}${NC}"
        continue
    }
    
    # Push
    docker push "${REGISTRY_URL}/${service}:latest" || {
        echo -e "${RED}❌ Erro ao fazer push de ${service}${NC}"
        continue
    }
    
    echo -e "${GREEN}✅ ${service} OK${NC}"
done

# Step 7: Criar Container App Environment
echo -e "${BLUE}[7/8]${NC} Criando Container App Environment..."
ENV_NAME="helpdesk-env"

if az containerapp env show --name "${ENV_NAME}" --resource-group "${RESOURCE_GROUP}" 2>/dev/null; then
    echo -e "${YELLOW}⚠️  Environment já existe${NC}"
else
    az containerapp env create \
        --name "${ENV_NAME}" \
        --resource-group "${RESOURCE_GROUP}" \
        --location "${LOCATION}"
    echo -e "${GREEN}✅ Environment criado${NC}"
fi

# Step 8: Exibir próximas steps
echo -e "${BLUE}[8/8]${NC} Setup concluído!"
echo ""
echo -e "${GREEN}✅ Deploy Setup Concluído!${NC}"
echo ""
echo -e "${BLUE}Próximas Steps:${NC}"
echo ""
echo "1. Adicionar secrets no GitHub:"
echo "   AZURE_REGISTRY_NAME=${REGISTRY_NAME}"
echo "   AZURE_REGISTRY_USERNAME=$(az acr credential show --name "${REGISTRY_NAME}" --query username -o tsv)"
echo "   AZURE_REGISTRY_PASSWORD=$(az acr credential show --name "${REGISTRY_NAME}" --query passwords[0].value -o tsv)"
echo ""
echo "2. Criar Service Principal para CI/CD:"
echo "   az ad sp create-for-rbac \\"
echo "     --name 'github-helpdesk' \\"
echo "     --role contributor \\"
echo "     --scopes /subscriptions/YOUR_SUBSCRIPTION_ID/resourceGroups/${RESOURCE_GROUP}"
echo ""
echo "3. Adicionar à GitHub Secrets:"
echo "   AZURE_CREDENTIALS=<json-output-do-service-principal>"
echo "   AZURE_RESOURCE_GROUP=${RESOURCE_GROUP}"
echo ""
echo "4. Deploy dos Container Apps:"
echo "   Ver AZURE_DEPLOYMENT.md para comandos de deploy"
echo ""
echo -e "${YELLOW}Registry URLs:${NC}"
echo "  ${REGISTRY_URL}/ticket-service:latest"
echo "  ${REGISTRY_URL}/user-service:latest"
echo "  ${REGISTRY_URL}/api-gateway:latest"
echo "  ${REGISTRY_URL}/frontend:latest"
echo ""
