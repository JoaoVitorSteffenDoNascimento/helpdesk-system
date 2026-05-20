# GitHub Student Pack - Deploy Otimizado para React

## 📋 Seu Melhor Setup (Grátis/Quase Grátis)

### Recomendação Final:
```
Frontend + Backend: DigitalOcean VPS ($5/mês, seus $200 cobrem 40 meses)
Desenvolvimento:    GitHub Codespaces (60h/mês grátis)
Domínio:            Namecheap (1 ano grátis)
CI/CD:              GitHub Actions (grátis)
```

**Por quê DigitalOcean para ambos?**
- ✅ React/Vite roda normalmente (sem GitHub Pages problems)
- ✅ Frontend + Backend na mesma VM
- ✅ Nginx reverse proxy integrado
- ✅ Seus $200 cobrem 40+ meses
- ✅ MUITO mais simples

**Custo Total:** $0 pelos próximos 3 anos 🎉

---

## 🚀 Setup: Frontend + Backend no DigitalOcean

Tudo roda junto em uma VM ($5/mês):

```
Cliente (navegador)
    ↓
Nginx (porta 80/443)
    ├→ / → React Frontend (dist/)
    └→ /api → API Gateway (porta 8080)
```

### Passo 1: Criar Droplet DigitalOcean

```bash
# 1. https://www.digitalocean.com
# 2. Usar crédito Student Pack ($200)
# 3. Droplets → Create → Ubuntu 22.04
# 4. Size: $5/mês (1vCPU, 1GB RAM)
# 5. Region: Perto de você (ex: Brazil, São Paulo)
# 6. Add SSH key (segurança)
# 7. Create
```

### Passo 2: Deploy da Aplicação

```bash
# SSH na VPS
ssh root@seu-droplet-ip

# Atualizar sistema
apt update && apt upgrade -y

# Instalar Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sh get-docker.sh
apt install docker-compose -y

# Clonar seu repositório
git clone https://github.com/seu-usuario/helpdesk-system.git
cd helpdesk-system

# Criar .env
cat > .env << 'EOF'
MONGODB_VERSION=7
MONGODB_PORT=27017
MONGODB_DATABASE=helpdesk
TICKET_SERVICE_PORT=8081
USER_SERVICE_PORT=8082
API_GATEWAY_PORT=8080
FRONTEND_PORT=5173
JAVA_OPTS=-Xmx256m -Xms128m
APP_ENV=production
FRONTEND_API_URL=https://seu-dominio.com
EOF

# Iniciar
docker compose up -d

# Verificar
docker compose ps
```

### Passo 3: Configurar Nginx + Domínio

Ver arquivo `REACT_FRONTEND_DEPLOY.md` para config completa do Nginx.

Resumo:
```bash
# Instalar Nginx
apt install nginx certbot python3-certbot-nginx -y

# Copiar sua config
cat > /etc/nginx/sites-available/helpdesk << 'EOF'
server {
    listen 80;
    server_name seu-dominio.com www.seu-dominio.com;

    # Frontend React (SPA)
    location / {
        root /opt/helpdesk-system/frontend/dist;
        try_files $uri $uri/ /index.html;
    }

    # API Gateway
    location /api {
        proxy_pass http://localhost:8080;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
EOF

# Ativar
ln -s /etc/nginx/sites-available/helpdesk /etc/nginx/sites-enabled/
nginx -t
systemctl restart nginx

# SSL automático
certbot --nginx -d seu-dominio.com
```

### Passo 4: Registrar Domínio

1. **Namecheap:**
   - https://www.namecheap.com
   - Registrar domínio com crédito grátis Student Pack ($9)
   - Configurar DNS:
     ```
     A record: seu-dominio.com → seu-droplet-ip
     CNAME: www → seu-dominio.com
     ```

2. **Pronto!** Acessar:
   ```
   https://seu-dominio.com → Frontend React
   https://seu-dominio.com/api → API Gateway
   ```

---

## 💡 Alternativas para Frontend (Se Quiser Separar)

### Opção: Vercel (React puro, grátis)

Se quiser frontend separado:

```bash
# Instalar Vercel CLI
npm i -g vercel

# Deploy
cd frontend
vercel
```

**Vantagens:**
- ✅ React 100% nativo
- ✅ Grátis forever
- ✅ Deploy automático

**Desvantagens:**
- ❌ Frontend separado do backend
- ❌ Precisa CORS
- ❌ Mais complicado integrar

**Recomendação:** Manter ambos no DigitalOcean (simples demais!)

---

## 🔄 GitHub Codespaces para Desenvolvimento

Usar Codespaces (60h/mês grátis) para dev local:

```bash
# 1. GitHub → Code → Create codespace on master
# 2. VS Code abre no navegador
# 3. Terminal:

docker compose up -d

# 4. Portas compartilhadas automaticamente
# 5. Compartilhar URL com seu time
```

**Máquina:** 4 vCPU, 16GB RAM - Excelente para desenvolvimento!

---

## 📊 Comparação: Deploy Options

| Cenário | Custo | Facilidade | React | Recomendado |
|---------|-------|-----------|-------|------------|
| **DigitalOcean (FE+BE)** | $0 (crédito) | ⭐⭐⭐ | ✅ Nativo | ⭐⭐⭐⭐⭐ |
| **GitHub Pages** | Grátis | ⭐⭐ | ⚠️ Limitado | ❌ |
| **Vercel (frontend)** | Grátis | ⭐⭐⭐⭐ | ✅ Nativo | ⭐⭐ (só FE) |
| **Azure App Service** | $0 | ⭐⭐⭐ | ✅ | ⭐⭐ (mais caro) |

---

## 🎯 Meu Recomendado (3+ Anos Grátis)

### Stack Final:
```
Frontend:     React/Vite no DigitalOcean ($5/mês)
Backend:      Docker Compose no DigitalOcean (mesmo VPS)
Database:     MongoDB (incluso no VPS)
Domínio:      Namecheap (grátis primeiro ano)
Dev:          GitHub Codespaces (60h/mês)
CI/CD:        GitHub Actions (grátis)
```

### Custo Real:
- **Ano 1-2:** $0 (DigitalOcean $200 cobrem tudo)
- **Ano 3:** $0 (DigitalOcean $200 cobrem tudo)
- **Ano 4:** $5/mês + $9-10/ano domínio = ~$70/ano

---

## ✅ Próximas Steps

1. **DigitalOcean (5 min):**
   ```bash
   # Criar Droplet $5/mês
   # Usar crédito Student Pack ($200)
   ```

2. **SSH e Deploy (10 min):**
   ```bash
   ssh root@seu-ip
   bash < setup-digitalocean.sh
   docker compose up -d
   ```

3. **Domínio (5 min):**
   - Namecheap: Registrar com crédito grátis
   - Apontar DNS para seu IP DigitalOcean

4. **Nginx + SSL (5 min):**
   - Certbot auto-renew
   - Pronto!

---

## 🚀 Checklist Final

- [ ] Usar GitHub Codespaces para dev (60h/mês)
- [ ] Registrar domínio Namecheap (grátis)
- [ ] Criar Droplet DigitalOcean ($5/mês)
- [ ] SSH e rodar setup-digitalocean.sh
- [ ] Docker Compose up
- [ ] Nginx config + SSL
- [ ] Apontar domínio
- [ ] Pronto! Apresentar para professor com URL real!

