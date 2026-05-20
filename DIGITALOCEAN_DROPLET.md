# DigitalOcean - Como Fazer Deploy de Verdade

## ⚠️ Problema: DigitalOcean App Platform

App Platform do DigitalOcean **não suporta bem docker-compose com múltiplos serviços** como você está vendo.

## ✅ Solução: Usar Droplet + Docker Compose (RECOMENDADO)

Muito simples e funciona 100%:

---

## 🚀 Setup Correto (20 min)

### Passo 1: Criar Droplet

1. **DigitalOcean → Droplets → Create**
   - Image: **Ubuntu 22.04**
   - Size: **$5/mês** (1 vCPU, 1GB RAM)
   - Region: Perto de você
   - **IMPORTANTE:** Adicione sua SSH key
   - Hostname: helpdesk-backend

2. **Aguarde criar** (~1 min)

### Passo 2: SSH na Máquina

```bash
# SSH (substitua seu IP)
ssh root@seu-droplet-ip

# Deve conectar sem pedir senha (se adicionou SSH key)
```

### Passo 3: Instalar Docker

```bash
# Update sistema
apt update && apt upgrade -y

# Instalar Docker (copia e cola tudo de uma vez)
curl -fsSL https://get.docker.com -o get-docker.sh
sh get-docker.sh
apt install docker-compose -y

# Verificar
docker --version
docker-compose --version
```

### Passo 4: Clonar Seu Repositório

```bash
# Clonar
git clone https://github.com/seu-usuario/helpdesk-system.git
cd helpdesk-system

# Verificar arquivos
ls -la
docker-compose ps  # Mostra status
```

### Passo 5: Criar .env

```bash
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
FRONTEND_API_URL=https://seu-dominio.com
EOF
```

### Passo 6: Iniciar Aplicação

```bash
# Iniciar todos os serviços em background
docker-compose up -d

# Esperar ~30s para Java services iniciarem

# Verificar status
docker-compose ps

# Ver logs em tempo real
docker-compose logs -f

# Ctrl+C para sair dos logs
```

### Passo 7: Verificar Acesso

```bash
# Testar API Gateway
curl http://localhost:8080/actuator/health

# Testar Ticket Service
curl http://localhost:8081/actuator/health

# Testar User Service
curl http://localhost:8082/actuator/health
```

### Passo 8: Configurar Nginx + SSL

```bash
# Instalar Nginx
apt install nginx certbot python3-certbot-nginx -y

# Criar arquivo de config
cat > /etc/nginx/sites-available/helpdesk << 'EOF'
server {
    listen 80;
    server_name seu-dominio.com www.seu-dominio.com;

    # Frontend React
    location / {
        proxy_pass http://localhost:5173;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }

    # API Gateway
    location /api {
        proxy_pass http://localhost:8080;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }
}
EOF

# Ativar
ln -s /etc/nginx/sites-available/helpdesk /etc/nginx/sites-enabled/
rm /etc/nginx/sites-enabled/default 2>/dev/null || true

# Testar config
nginx -t

# Reiniciar
systemctl restart nginx

# SSL automático (Let's Encrypt)
certbot --nginx -d seu-dominio.com -d www.seu-dominio.com

# Aceitar termos e fornecer email quando pedir
```

### Passo 9: Configurar Domínio

1. **Namecheap (ou outro registrador):**
   - Registrar domínio com crédito grátis Student Pack
   - Ir em **Manage Domain → Advanced DNS**
   - Adicionar registro:
     ```
     Type: A
     Host: @
     Value: seu-droplet-ip
     TTL: 3600
     ```
   - Adicionar:
     ```
     Type: CNAME
     Host: www
     Value: seu-dominio.com
     TTL: 3600
     ```

2. **Aguardar DNS propagar** (~5-30 min)

3. **Testar:**
   ```bash
   # Na sua máquina local (não no Droplet)
   curl https://seu-dominio.com
   curl https://seu-dominio.com/api/actuator/health
   ```

---

## 🔄 Auto-Deploy (GitHub Actions → Droplet)

Para fazer deploy automático quando você faz push:

### Passo 1: Gerar SSH Key no Droplet

```bash
# No Droplet
ssh-keygen -t ed25519 -f /root/.ssh/id_deployment -N ""
cat /root/.ssh/id_deployment
# Copie a chave privada
```

### Passo 2: Adicionar Secret no GitHub

1. Repositório → Settings → Secrets
2. New secret: `DEPLOY_KEY`
3. Colar a chave privada

### Passo 3: Criar GitHub Actions Workflow

```yaml
name: Deploy to DigitalOcean

on:
  push:
    branches: [master]

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      
      - name: Deploy to Droplet
        uses: appleboy/ssh-action@master
        with:
          host: ${{ secrets.DROPLET_IP }}
          username: root
          key: ${{ secrets.DEPLOY_KEY }}
          script: |
            cd /root/helpdesk-system
            git pull origin master
            docker-compose down
            docker-compose up -d
            docker-compose logs -f
```

---

## 📊 URLs Finais (Após tudo pronto)

```
Frontend:    https://seu-dominio.com
API Gateway: https://seu-dominio.com/api
Swagger:     https://seu-dominio.com/api/swagger-ui.html
Tickets:     https://seu-dominio.com/ticket-service
Users:       https://seu-dominio.com/user-service
MongoDB:     localhost:27017 (interno, não exposto)
```

---

## 🛠️ Comandos Úteis (No Droplet)

```bash
# Status de todos os containers
docker-compose ps

# Ver logs
docker-compose logs
docker-compose logs -f api-gateway  # Seguir logs em tempo real

# Reiniciar um serviço
docker-compose restart api-gateway

# Parar tudo
docker-compose down

# Rebuild da imagem (se mudou Dockerfile)
docker-compose build api-gateway
docker-compose up -d api-gateway

# Entrar em um container
docker-compose exec api-gateway bash

# Verificar uso de recursos
docker stats

# Limpeza de imagens/containers não usados
docker system prune -a
```

---

## 🚨 Troubleshooting

### "Connection refused" ao acessar

```bash
# 1. Verificar se containers estão rodando
docker-compose ps

# 2. Ver logs
docker-compose logs api-gateway

# 3. Testar localmente
curl http://localhost:8080/actuator/health

# 4. Verificar firewall
ufw allow 22
ufw allow 80
ufw allow 443
```

### "Out of memory"

```bash
# Verificar uso
docker stats

# Reduzir JAVA_OPTS em .env
# De: -Xmx256m -Xms128m
# Para: -Xmx128m -Xms64m

# Reconstruir
docker-compose down
docker-compose up -d
```

### MongoDB não conecta

```bash
# Verificar se MongoDB está saudável
docker-compose logs mongodb

# Pode levar tempo para iniciar
docker-compose restart mongodb
```

---

## 💾 Backup de Dados

```bash
# Backup MongoDB
docker-compose exec mongodb mongodump --out /dump

# Backup arquivos
tar -czf backup.tar.gz /opt/helpdesk-system
```

---

## ✅ Checklist Final

- [ ] Droplet criado ($5/mês)
- [ ] SSH funcionando
- [ ] Docker instalado
- [ ] Repositório clonado
- [ ] .env criado
- [ ] docker-compose up -d rodando
- [ ] Nginx configurado
- [ ] SSL com Let's Encrypt
- [ ] Domínio apontando
- [ ] Acessar https://seu-dominio.com ✅

