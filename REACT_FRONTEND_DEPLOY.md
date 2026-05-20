# React + Vite no GitHub Pages & Alternativas

## ⚠️ Problema: GitHub Pages + React/Vite

GitHub Pages **SÓ serve arquivos estáticos** - funciona com React, mas com limitações:

### Limitações:
- ❌ Rota-raiz problemática (`/helpdesk-system/` vs `/`)
- ❌ Refresh na página quebra routing
- ❌ Precisa `BrowserRouter` → `HashRouter`
- ❌ Mais complicado de configurar

### Solução (3 Opções)

---

## ✅ Opção 1: DigitalOcean para Frontend + Backend (RECOMENDADO)

**Por quê?**
- ✅ Mesma VM para tudo
- ✅ Sem complicação de GitHub Pages
- ✅ Seu React roda como SPA normal
- ✅ Seus $200 cobrem tudo
- ✅ Mais simples

**Custo:** $5/mês (seus créditos DigitalOcean cobrem)

**Setup:**
```bash
# Já no seu Dockerfile, o frontend está em /dist
# Nginx serve em porta 80

# URL final:
https://seu-dominio.com → Frontend React (port 80)
https://seu-dominio.com/api → API Gateway (port 8080)
```

### Como Configurar Nginx

```bash
# SSH na VPS
ssh root@seu-ip

# Criar config Nginx
cat > /etc/nginx/sites-available/helpdesk << 'EOF'
server {
    listen 80;
    server_name seu-dominio.com www.seu-dominio.com;

    # Frontend React (SPA)
    location / {
        root /var/www/helpdesk/frontend/dist;
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

    # Ticket Service (interno)
    location /ticket-service {
        proxy_pass http://localhost:8081;
    }

    # User Service (interno)
    location /user-service {
        proxy_pass http://localhost:8082;
    }
}
EOF

# Ativar
ln -s /etc/nginx/sites-available/helpdesk /etc/nginx/sites-enabled/
rm /etc/nginx/sites-enabled/default 2>/dev/null || true
nginx -t
systemctl restart nginx
```

**Vantagens vs GitHub Pages:**
- Sem problemas de routing
- React funciona normalmente
- API + Frontend na mesma origem
- Sem CORS complications

---

## 🔧 Opção 2: GitHub Pages + React (Se Insistir)

Se REALMENTE quiser GitHub Pages, precisa:

### Step 1: Configurar Vite para GitHub Pages

```javascript
// vite.config.js
import react from '@vitejs/plugin-react'
import { defineConfig } from 'vite'

export default defineConfig({
  plugins: [react()],
  base: '/helpdesk-system/', // ⚠️ IMPORTANTE: seu repo name
  build: {
    outDir: 'dist',
  },
})
```

### Step 2: Mudar Router para HashRouter

```jsx
// src/main.jsx
import { HashRouter } from 'react-router-dom'

ReactDOM.createRoot(document.getElementById('root')).render(
  <HashRouter>
    <App />
  </HashRouter>,
)
```

Isso faz URLs fica assim: `/#/tickets` em vez de `/tickets`

### Step 3: Deploy Script

```bash
#!/bin/bash

# Build
npm run build

# Criar branch gh-pages
git checkout --orphan gh-pages
git rm -rf .

# Copiar dist
cp -r dist/* .
echo "Compilado em: $(date)" > .timestamp

git add .
git commit -m "Deploy frontend"
git push origin gh-pages -f

# Voltar para master
git checkout master
```

**Desvantagens:**
- ❌ URLs feias com `#`
- ❌ SEO ruim
- ❌ Não é "real" SPA
- ❌ API precisa ter CORS
- ❌ Mais complexo

---

## 🌟 Opção 3: Vercel (Melhor que GitHub Pages)

**Se não quiser DigitalOcean e quiser algo gerenciado:**

```bash
# Instalar Vercel CLI
npm i -g vercel

# Deploy
vercel
```

**Vantagens:**
- ✅ React native (sem config)
- ✅ Grátis para hobby
- ✅ Deploy automático via Git
- ✅ Custom domain grátis
- ✅ SSL automático

**Desvantagem:**
- ❌ Usa seus créditos? Não, é grátis!

---

## 📊 Comparação: Frontend Deploy

| Opção | Custo | Facilidade | Ideal Para |
|-------|-------|-----------|----------|
| **DigitalOcean** | $5/mês (grátis com crédito) | ⭐⭐⭐ Médio | Tudo junto |
| **GitHub Pages** | $0 | ⭐⭐ Complicado | Projetos simples |
| **Vercel** | $0 (free tier) | ⭐⭐⭐⭐ Muito fácil | React SPA |

---

## 🎯 MEU RECOMENDADO (Rank)

### 1️⃣ **DigitalOcean ($5/mês)**
```
Frontend + Backend na mesma VM
React roda 100% normal
Simples, sem complicações
Seus $200 cobrem 40 meses
👉 MELHOR OPÇÃO
```

### 2️⃣ **Vercel (Grátis)**
```
Frontend automático
Zero config para React
Mas backend fica separado em DigitalOcean
Funciona bem
```

### 3️⃣ **GitHub Pages (Grátis)**
```
React com HashRouter
URLs feias (#)
CORS problems
Complicado
Não recomendo
```

---

## 🚀 Setup Final (DigitalOcean)

### Arquivo docker-compose atualizado:

Seu `docker-compose.yml` atual já está bom!

```yaml
frontend:
  build:
    context: ./frontend
    dockerfile: Dockerfile
  ports:
    - "80:80"  # Nginx serve HTTP
  environment:
    VITE_API_BASE_URL: http://localhost:8080
```

Quando você faz `docker compose up`:
- Frontend (React) compila e Nginx serve em `:80`
- API Gateway em `:8080`
- MongoDB em `:27017`

### No Nginx, roteamento:

```
http://seu-dominio.com → :80 → Frontend React
http://seu-dominio.com/api → :8080 → API Gateway
```

**Perfeitamente alinhado!**

---

## ✅ Checklist: DigitalOcean (Recomendado)

- [ ] Criar Droplet $5/mês no DigitalOcean
- [ ] SSH e rodar `setup-digitalocean.sh`
- [ ] `docker compose up -d`
- [ ] Registrar domínio Namecheap
- [ ] Nginx + SSL (certbot)
- [ ] Domínio apontando para VPS
- [ ] Acessar: https://seu-dominio.com ✅

---

## 🔗 URLs Finais (DigitalOcean)

```
Frontend React:  https://seu-dominio.com/
API Gateway:     https://seu-dominio.com/api
Tickets API:     https://seu-dominio.com/ticket-service
Users API:       https://seu-dominio.com/user-service
MongoDB:         localhost:27017 (interno)
```

Todo tráfego passa por Nginx → fácil de gerenciar, cache, SSL, etc.

