#!/bin/bash

# Script para setup inicial no DigitalOcean
# Execute com: ssh root@seu-droplet-ip 'bash -s' < setup-digitalocean.sh

set -e

echo "🚀 Setup DigitalOcean para Helpdesk System"
echo "=========================================="

# Cores
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

# Step 1: Update
echo -e "${BLUE}[1/6]${NC} Atualizando sistema..."
apt update && apt upgrade -y
echo -e "${GREEN}✅ Sistema atualizado${NC}"

# Step 2: Instalar Docker
echo -e "${BLUE}[2/6]${NC} Instalando Docker..."
curl -fsSL https://get.docker.com -o get-docker.sh
sh get-docker.sh
apt install docker-compose -y
usermod -aG docker root
echo -e "${GREEN}✅ Docker instalado${NC}"

# Step 3: Instalar Nginx
echo -e "${BLUE}[3/6]${NC} Instalando Nginx..."
apt install nginx certbot python3-certbot-nginx -y
systemctl enable nginx
echo -e "${GREEN}✅ Nginx instalado${NC}"

# Step 4: Clonar repositório
echo -e "${BLUE}[4/6]${NC} Clonando repositório..."
cd /opt
git clone https://github.com/seu-usuario/helpdesk-system.git
cd helpdesk-system
echo -e "${GREEN}✅ Repositório clonado${NC}"

# Step 5: Criar .env
echo -e "${BLUE}[5/6]${NC} Criando arquivo .env..."
cat > .env << 'EOF'
MONGODB_VERSION=7
MONGODB_PORT=27017
MONGODB_DATABASE=helpdesk
TICKET_SERVICE_PORT=8081
USER_SERVICE_PORT=8082
API_GATEWAY_PORT=8080
FRONTEND_PORT=5173
JAVA_OPTS=-Xmx256m -Xms128m
JAVA_TOOL_OPTIONS=-XX:+UseContainerSupport -XX:MaxRAMPercentage=75.0
APP_ENV=production
FRONTEND_API_URL=https://seu-dominio.com/api
EOF
echo -e "${GREEN}✅ .env criado (ajuste FRONTEND_API_URL depois)${NC}"

# Step 6: Iniciar Docker Compose
echo -e "${BLUE}[6/6]${NC} Iniciando Docker Compose..."
docker compose up -d
docker compose ps
echo -e "${GREEN}✅ Docker Compose rodando${NC}"

# Próximas instruções
echo ""
echo -e "${BLUE}========================================${NC}"
echo -e "${GREEN}✅ Setup Concluído!${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""
echo "Próximas steps:"
echo ""
echo "1. Ajustar arquivo .env:"
echo "   nano /opt/helpdesk-system/.env"
echo "   # Atualizar FRONTEND_API_URL com seu domínio"
echo ""
echo "2. Configurar Nginx:"
echo "   # Ver arquivo nginx-config.sh"
echo ""
echo "3. Configurar SSL:"
echo "   certbot --nginx -d seu-dominio.com"
echo ""
echo "4. Acessar:"
echo "   http://seu-droplet-ip:8080 (API)"
echo "   docker compose logs -f (ver logs)"
echo ""
