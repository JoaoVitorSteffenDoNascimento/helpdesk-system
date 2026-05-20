# Deploy Automático no Render

## 🚀 Setup Passo a Passo

### Pré-requisitos
- Conta no [render.com](https://render.com) (criar se não tiver)
- GitHub conectado ao Render
- Este repositório conectado ao Render

---

## 📋 Opção 1: Deploy Manual (Recomendado para começar)

### Passo 1: Conectar Repositório ao Render
1. Acesse [dashboard.render.com](https://dashboard.render.com)
2. Clique em "New +"
3. Selecione "Web Service"
4. Conecte seu GitHub (`JoaoVitorSteffenDoNascimento/helpdesk-system`)
5. Selecione branch `master`

### Passo 2: Criar MongoDB
1. Clique "New +"
2. Selecione "PostgreSQL" (ou "MongoDB")
   - **Nome:** `helpdesk-mongodb`
   - **Plano:** Free (para testes)
3. Copie a URL de conexão

### Passo 3: Criar cada serviço

#### Ticket Service
```
Nome: helpdesk-ticket-service
Tipo: Web Service
Repo: JoaoVitorSteffenDoNascimento/helpdesk-system
Branch: master
Runtime: Docker
Dockerfile: ./ticket-service/Dockerfile
```

**Environment Variables:**
```
SPRING_DATA_MONGODB_URI=mongodb://mongodb_url_do_render
SERVER_PORT=8081
JAVA_OPTS=-Xmx512m -Xms256m
```

**Health Check:**
```
Path: /actuator/health
Port: 8081
```

#### User Service
Repita o mesmo para `user-service`, porta 8082

#### API Gateway
```
Nome: helpdesk-api-gateway
...
TICKET_SERVICE_URL=https://helpdesk-ticket-service.onrender.com
USER_SERVICE_URL=https://helpdesk-user-service.onrender.com
```

#### Frontend
```
Nome: helpdesk-frontend
Runtime: Docker
Dockerfile: ./frontend/Dockerfile
Build Command: npm run build
```

**Environment Variables:**
```
VITE_API_BASE_URL=https://helpdesk-api-gateway.onrender.com
```

---

## 🤖 Opção 2: Deploy Automático com GitHub Actions

### Passo 1: Gerar Deploy Hooks no Render

Para cada serviço, gere um "Deploy Hook":

1. Abra o serviço no Render
2. Settings → Deploy Hook
3. Copie o URL (algo como: `https://api.render.com/deploy/srv-xxxxx`)
4. **Repita para todos os 5 serviços**

### Passo 2: Adicionar Secrets no GitHub

1. Vá ao seu repositório
2. Settings → Secrets and variables → Actions
3. Crie cada secret:
   - `RENDER_DEPLOY_HOOK_MONGODB` → URL do MongoDB
   - `RENDER_DEPLOY_HOOK_TICKET_SERVICE` → URL do Ticket Service
   - `RENDER_DEPLOY_HOOK_USER_SERVICE` → URL do User Service
   - `RENDER_DEPLOY_HOOK_API_GATEWAY` → URL do API Gateway
   - `RENDER_DEPLOY_HOOK_FRONTEND` → URL do Frontend

### Passo 3: Push para Trigger Deploy

```bash
git add .
git commit -m "Trigger Render deployment"
git push origin master
```

GitHub Actions automaticamente:
1. Bilda as imagens
2. Faz push para GHCR
3. Chama os deploy hooks do Render
4. Render puxa o código e rebuilda

---

## ⚙️ Configuração Recomendada no Render

### Plans (Free é OK para MVP)
- **Free Plan:** Bom para desenvolvimento/testes
  - Desce após 15 min de inatividade
  - Rebuilda em ~2-5 min
  - Sem custo

- **Starter Plan:** Recomendado para produção
  - Sempre ligado
  - Rebuilda em ~1-2 min
  - ~$7/mês por serviço

### Database Options
1. **PostgreSQL/MySQL** (mais fácil no Render)
   - Gratuito: 1 instância, 256MB
   - Render gerencia backups

2. **MongoDB Atlas** (recomendado)
   - Nuvem dedicada
   - Gratuito: 512MB storage
   - Melhor para microserviços

### Environment Variables por Serviço

**Ticket Service:**
```
SPRING_DATA_MONGODB_URI=mongodb+srv://user:pass@cluster.mongodb.net/helpdesk_tickets
SERVER_PORT=8081
JAVA_OPTS=-Xmx512m -Xms256m
```

**User Service:**
```
SPRING_DATA_MONGODB_URI=mongodb+srv://user:pass@cluster.mongodb.net/helpdesk_users
SERVER_PORT=8082
JAVA_OPTS=-Xmx512m -Xms256m
```

**API Gateway:**
```
TICKET_SERVICE_URL=https://helpdesk-ticket-service.onrender.com
USER_SERVICE_URL=https://helpdesk-user-service.onrender.com
SERVER_PORT=8080
JAVA_OPTS=-Xmx512m -Xms256m
```

**Frontend:**
```
VITE_API_BASE_URL=https://helpdesk-api-gateway.onrender.com
```

---

## 🔗 URLs Finais

Depois de deployar no Render, seus serviços estarão em:

```
Frontend:     https://helpdesk-frontend.onrender.com
API Gateway:  https://helpdesk-api-gateway.onrender.com
Ticket API:   https://helpdesk-ticket-service.onrender.com
User API:     https://helpdesk-user-service.onrender.com
```

---

## 🐛 Troubleshooting

### "Deploy failed: Dockerfile not found"
→ Verifique o caminho do Dockerfile em Settings → Build Command

### "Health check failing"
→ Espere 2-3 min. Aplicação Java demora para warm up
→ Aumente `start_period` no healthcheck

### "502 Bad Gateway"
→ API Gateway não consegue comunicar com serviços
→ Verifique URLs das env vars (use .onrender.com)

### "MongoDB connection timeout"
→ Whitelist IP no MongoDB Atlas
→ Ou use conexão local na VPC do Render

---

## 📊 Monitorando Deployments

1. **Render Dashboard:** https://dashboard.render.com
   - Ver logs em tempo real
   - Status de cada serviço
   - Histórico de deployments

2. **GitHub Actions:** Actions tab do seu repositório
   - Ver qual serviço foi deployado
   - Ver logs do deploy hook

3. **Health Checks:**
   ```bash
   curl https://helpdesk-api-gateway.onrender.com/actuator/health
   ```

---

## 🚀 Próximas Melhorias

1. **CI/CD Pipeline Completo:**
   - Testes automáticos antes de deploy
   - Scan de vulnerabilidades
   - Deploy canário (trafego gradual)

2. **Database Backups:**
   - Configurar backup automático no MongoDB
   - Retenção de dados

3. **CDN para Frontend:**
   - Render oferece CDN integrado
   - Cache de assets estáticos

4. **Custom Domain:**
   - Adicionar seu próprio domínio
   - SSL automático

5. **Monitoring & Alerts:**
   - Prometheus + Grafana
   - Alertas via Slack/Discord quando serviço cai

