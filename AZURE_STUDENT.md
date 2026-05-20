# Azure Student Plan - Deployment Otimizado

## 🎯 Situação Atual

✅ **O que você tem:**
- $100-200 de créditos grátis
- 12 meses de validade
- Precisa usar com sabedoria

❌ **O que é caro demais:**
- Container Apps: consome $50+/mês de crédito
- Container Instances: $0.0015/seg = caro rápido
- VMs: Muito caro

---

## 🚀 Melhor Estratégia: GitHub Codespaces (ZERO CUSTO)

### Por quê GitHub Codespaces?
- ✅ **60 horas/mês grátis** (suficiente para dev + testes)
- ✅ **Máquina poderosa:** 4vCPU + 16GB RAM
- ✅ **Docker instalado**
- ✅ **Git integrado**
- ✅ **IDE no navegador** (VS Code)
- ✅ **Compartilhável** com seu time

### Como Usar (Super Fácil)

1. **Abrir Codespaces:**
   - GitHub → Code → Codespaces
   - Clique "Create codespace on master"

2. **Iniciar sua aplicação:**
   ```bash
   docker compose up -d
   ```

3. **Acessar via URL pública:**
   - Porta 5173 (Frontend): compartilhável
   - Porta 8080 (API): compartilhável

4. **Pausar para não consumir horas:**
   - Codespace pausa automaticamente após 30min inatividade

---

## 💡 Alternativa 1: App Service Free Tier + SQL Database

Se quiser algo 24/7 em Azure (com seus créditos):

### Setup:

```bash
# Login
az login

# Criar Resource Group
az group create --name helpdesk-rg --location eastus

# Criar App Service Plan (FREE)
az appservice plan create \
  --name helpdesk-plan \
  --resource-group helpdesk-rg \
  --sku F1 \
  --is-linux

# Criar App Service
az webapp create \
  --resource-group helpdesk-rg \
  --plan helpdesk-plan \
  --name helpdesk-app \
  --runtime "DOCKER|helpdesk-registry.azurecr.io/api-gateway:latest"

# Configurar variáveis
az webapp config appsettings set \
  --resource-group helpdesk-rg \
  --name helpdesk-app \
  --settings \
    TICKET_SERVICE_URL="http://localhost:8081" \
    USER_SERVICE_URL="http://localhost:8082" \
    DATABASE_URL="mongodb+srv://..."
```

**Custo:** $0 (F1 Free tier)

**Limitações:**
- 1 instância apenas
- 1 GB RAM
- Dorme após 20min inatividade
- Ideal para MVP

---

## 💡 Alternativa 2: Railway + GitHub Pages (CUSTO MÍNIMO)

Separar aplicação em duas partes:

### Frontend: GitHub Pages (GRÁTIS)
```bash
# Deploy automático
cd frontend
npm run build
# Fazer push → GitHub Pages publica automaticamente
```

### Backend: Railway ($5-15/mês)
```bash
# Login
railway login

# Deploy
railway up

# Custo: $5/mês para 512MB RAM
```

**Total:** ~$5-15/mês (pague com seus $100 de créditos)

**Vantagens:**
- ✅ Melhor performance
- ✅ Frontend super rápido (CDN)
- ✅ Backend gerenciado
- ✅ Seus créditos duram ~8-20 meses

---

## 🏆 Minha Recomendação para Você (Ordenada)

### 1️⃣ **GitHub Codespaces** (Melhor Custo-Benefício)
- ✅ **Custo:** ZERO
- ✅ **Horas/mês:** 60 grátis (suficiente)
- ✅ **Performance:** Excelente
- ✅ **Setup:** 1 click

**Recomendado para:**
- Desenvolvimento
- Testes
- Apresentações
- MVP

**Como usar:**
```bash
# 1. GitHub → Code → Create codespace
# 2. Aguardar ambiente carregar
# 3. Terminal: docker compose up -d
# 4. Pronto!
```

---

### 2️⃣ **Railway** (Melhor para Produção)
- ✅ **Custo:** $5-15/mês (seus créditos cobrem 8-20 meses)
- ✅ **Uptime:** 99.9%
- ✅ **Performance:** Ótima
- ✅ **Setup:** 5 minutos

**Como usar:**
```bash
npm install -g @railway/cli
railway login
railway up
```

---

### 3️⃣ **Azure App Service Free** (Se realmente quiser Azure)
- ✅ **Custo:** $0
- ⚠️ **Limitações:** 1GB RAM, dorme após 20min
- ⚠️ **Performance:** Lenta

**Como usar:**
```bash
az webapp up --name helpdesk-app --sku F1
```

---

## ⚡ Setup Rápido: GitHub Codespaces

### Passo 1: Criar Codespace
1. https://github.com/seu-repo
2. Code → Create codespace on master
3. Esperar 2-3 min

### Passo 2: Abrir Terminal
```bash
# Já dentro do VS Code no navegador
docker compose up -d
```

### Passo 3: Acessar Aplicação
- Abrir "Ports" (Bottom left)
- Ver URLs públicas compartilháveis

### Passo 4: Compartilhar Link
- Clique no ícone "globe" em cada porta
- Copie URL
- Compartilhe com seu time

---

## 🔄 GitHub Codespaces vs Outros

| Aspecto | Codespaces | Azure App Service | Railway |
|---------|-----------|------------------|---------|
| **Custo** | $0 (60h/mês) | $0 | $5-15/mês |
| **CPU** | 4 cores | 0.25 cores | 0.5 cores |
| **RAM** | 16GB | 1GB | 512MB-1GB |
| **Always On** | ❌ | ✅ | ✅ |
| **Setup** | 1 click | 10 min | 5 min |
| **Ideal Para** | Dev | MVP | Produção |

---

## 📊 Custo Total por Mês (Plano Student)

### Opção 1: Codespaces Only
- **Custo real:** $0 (incluso no GitHub Student Pack)
- **Créditos Azure gastos:** $0
- **Duração:** Infinita

### Opção 2: Railway Backend + GitHub Pages Frontend
- **Custo real:** $5-15/mês
- **Créditos Azure gastos:** $5-15/mês
- **Duração:** 6-20 meses (seus $100 cobrem)

### Opção 3: Azure App Service Only
- **Custo real:** $0
- **Créditos Azure gastos:** ~$0 (F1 free)
- **Duração:** Infinita
- **Desvantagem:** Muito lento (1GB RAM, dorme)

---

## ✅ Próximas Steps

1. **Para começar HOJE (Grátis):**
   ```bash
   # GitHub Codespaces
   # 1. GitHub → Code → Create codespace
   # 2. Terminal: docker compose up -d
   # 3. Ports → copiar URL do frontend
   # 4. Compartilhar com professor/time
   ```

2. **Para produção (Barato):**
   ```bash
   # Railway
   railway login
   railway up
   ```

3. **Se realmente quiser Azure (Limitado):**
   ```bash
   # App Service Free
   az webapp up --name helpdesk --sku F1
   ```

---

## 🎓 Aproveitando o GitHub Student Pack

✅ **Incluso:**
- Codespaces: 60h/mês grátis
- GitHub Copilot: Grátis
- Domains: Grátis (2 anos)
- Various cloud credits

👉 **Recomendação:** Use Codespaces para tudo de dev. Reserve seus $100 de Azure para quando realmente precisar em produção.

