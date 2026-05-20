# GitHub Student Pack - Deploy Otimizado

## 📋 Seu Melhor Setup (Grátis/Quase Grátis)

### Recomendação Final:
```
Frontend:     GitHub Pages (grátis)
Backend:      DigitalOcean VPS ($5/mês, seus $200 cobrem 40 meses)
Desenvolvimento: GitHub Codespaces (60h/mês grátis)
Domínio:      Namecheap (1 ano grátis)
CI/CD:        GitHub Actions (grátis)
```

**Custo Total:** $0 pelos próximos 3 anos 🎉

---

## 🚀 Setup 1: GitHub Pages Frontend + DigitalOcean Backend

### Passo 1: Deploy Frontend no GitHub Pages

```bash
# Suas imagens já estão buildadas em docker-compose
# Vamos fazer deploy estático

# 1. Build da aplicação Vue
cd frontend
npm run build

# 2. Criar branch gh-pages
git checkout --orphan gh-pages
git rm -rf .

# 3. Copiar arquivos buildados
cp -r dist/* .
git add .
git commit -m "Deploy frontend"
git push origin gh-pages

# 4. Configurar no GitHub
# Repositório Settings → Pages → Source: gh-pages
# Sua app estará em: https://seu-usuario.github.io/helpdesk-system
```

### Passo 2: Deploy Backend no DigitalOcean

#### Criar Droplet (VPS)

```bash
# 1. Acessar https://www.digitalocean.com
# 2. Usar crédito do Student Pack ($200)
# 3. Create → Droplets

# Configuração:
# - Image: Ubuntu 22.04
# - Size: $5/mês (1 vCPU, 1GB RAM)
# - Region: Escolher mais perto (ex: Brazil, New York)
# - Add SSH key (para segurança)
# - Hostname: helpdesk-backend
```

#### SSH na VPS

```bash
# SSH
ssh root@seu-droplet-ip

# Atualizar sistema
apt update && apt upgrade -y

# Instalar Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sh get-docker.sh

# Instalar Docker Compose
apt install docker-compose -y

# Adicionar seu usuário ao grupo docker
usermod -aG docker root
```

#### Deploy Sua Aplicação

```bash
# Clonar seu repositório
git clone https://github.com/seu-usuario/helpdesk-system.git
cd helpdesk-system

# Criar .env com variáveis de produção
cat > .env.prod << EOF
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

# Iniciar aplicação
docker compose up -d

# Verificar status
docker compose ps
```

#### Configurar Nginx como Reverse Proxy

```bash
# Instalar Nginx
apt install nginx -y

# Criar configuração
cat > /etc/nginx/sites-available/helpdesk << 'EOF'
server {
    listen 80;
    server_name seu-dominio.com www.seu-dominio.com;

    location /api {
        proxy_pass http://localhost:8080;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }

    location / {
        # Se quiser servir frontend daqui também
        # proxy_pass http://localhost:5173;
        
        # Ou redirecionar para GitHub Pages
        return 301 https://seu-usuario.github.io/helpdesk-system;
    }
}
EOF

# Ativar
ln -s /etc/nginx/sites-available/helpdesk /etc/nginx/sites-enabled/
nginx -t
systemctl restart nginx
```

#### Configurar HTTPS (SSL Grátis)

```bash
# Instalar Certbot (Let's Encrypt)
apt install certbot python3-certbot-nginx -y

# Gerar certificado
certbot --nginx -d seu-dominio.com

# Auto-renew
systemctl enable certbot.timer
```

### Passo 3: Configurar Domínio Customizado

1. **Namecheap** (crédito grátis do Student Pack):
   - Registrar domínio grátis por 1 ano
   - Configurar DNS apontando para DigitalOcean

2. **DigitalOcean Networking:**
   - Manage → Networking → Domains
   - Adicionar domínio
   - Criar registros:
     ```
     A record: seu-dominio.com → seu-droplet-ip
     CNAME: www → seu-dominio.com
     ```

3. **Atualizar URLs:**
   - Frontend (GitHub Pages): Código HTML aponta para https://seu-dominio.com/api
   - Backend: Certificado SSL automático

---

## 🔧 Setup 2: GitHub Codespaces para Desenvolvimento

### Usar Codespaces (Dev Local)

```bash
# 1. GitHub → Code → Create codespace on master
# 2. VS Code abre no navegador
# 3. Terminal aberto:

docker compose up -d

# 4. Portas são compartilhadas automaticamente
# 5. Compartilhar URL com seu time

# Máquina: 4 vCPU, 16GB RAM - poderosa demais!
# Grátis: 60h/mês
```

---

## 💳 Usando Outros Créditos (Se Quiser)

### Opção: Azure $100

```bash
# Se preferir Azure para backend:
az login
az webapp up --name helpdesk --sku B1
# Custa ~$15/mês mas você tem $100
```

### Opção: AWS $100-150

```bash
# EC2 t2.micro (free tier) + RDS MySQL
# Costo similar ao DigitalOcean
```

### Opção: Heroku $50/mês

```bash
# Deploy super simples:
heroku create helpdesk-backend
git push heroku main
# Mas consome mais crédito que DigitalOcean
```

---

## 📊 Comparação: Seu Student Pack

| Cenário | Custo Total | Duração | O que Usar |
|---------|------------|---------|-----------|
| **DigitalOcean** | $0 | 3+ anos | ⭐⭐⭐ Recomendado |
| **Azure** | $0 (depois caro) | 12 meses | ⭐⭐ Se quiser Azure |
| **AWS** | $0 (depois caro) | 12 meses | ⭐⭐ Enterprise |
| **Heroku** | Consome rápido | 12 meses | ❌ Não recomendo |
| **GitHub Pages** | Grátis | Infinito | ✅ Para frontend |

---

## 🎯 Meu Recomendado (3 Anos Grátis)

### Stack Final:
```
Frontend:     GitHub Pages
Backend:      DigitalOcean VPS ($5/mês, crédito $200)
Domínio:      Namecheap (grátis primeiro ano)
Dev:          GitHub Codespaces (60h/mês)
CI/CD:        GitHub Actions (grátis)
```

### Custo Real:
- **Ano 1:** $0 (tudo grátis)
- **Ano 2:** $0 (DigitalOcean coberto)
- **Ano 3:** $0 (DigitalOcean coberto)
- **Ano 4:** $5/mês + $9-10/ano domínio = ~$70/ano

---

## ✅ Próximas Steps

1. **Frontend (5 min):**
   ```bash
   cd frontend && npm run build
   # Deploy em GitHub Pages
   ```

2. **Domínio (5 min):**
   - Namecheap: Registrar com crédito grátis
   - Aponta para seu IP

3. **Backend (15 min):**
   - DigitalOcean: Criar droplet $5/mês
   - SSH + Docker Compose
   - Nginx + SSL

4. **CI/CD (automático):**
   - GitHub Actions já buildando imagens
   - Setup webhook para redeploy

---

## 🚀 Checklist Final

- [ ] Usar GitHub Codespaces para dev (60h/mês)
- [ ] Deploy frontend GitHub Pages
- [ ] Registrar domínio Namecheap
- [ ] Criar VPS DigitalOcean
- [ ] Docker Compose no DigitalOcean
- [ ] Nginx + SSL
- [ ] CI/CD GitHub Actions
- [ ] Apresentar para professor com URL real!

