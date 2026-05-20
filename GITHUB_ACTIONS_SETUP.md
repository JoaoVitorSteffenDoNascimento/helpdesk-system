# GitHub Actions + Docker - Setup Rápido

## 🚀 O que foi criado

Arquivo: `.github/workflows/docker-hub.yml`

Workflow automático que:
- ✅ Bilda as 4 imagens Docker quando você faz push
- ✅ Faz push para **GitHub Container Registry (GHCR)** automaticamente
- ✅ Opcionalmente, também faz push para **Docker Hub** (se configurar secrets)
- ✅ Roda testes em Pull Requests
- ✅ Cache inteligente para builds mais rápidos

---

## 📋 Setup (Escolha uma opção)

### **Opção 1: Automática (Recomendado para começar)**

Nada para fazer! GitHub Container Registry já funciona automaticamente:

```bash
git add .
git commit -m "Add GitHub Actions CI/CD"
git push origin main
```

As imagens aparecerão em: `ghcr.io/seu-usuario/helpdesk-system/ticket-service:latest`

---

### **Opção 2: Docker Hub (Adicional)**

Se quiser também publicar no Docker Hub:

#### Passo 1: Criar token no Docker Hub
1. Acesse https://hub.docker.com/settings/security
2. Clique em "New Access Token"
3. Nome: `github-actions`
4. Permissões: Read & Write
5. Copie o token (não será mostrado novamente!)

#### Passo 2: Configurar secrets no GitHub
1. Vá ao seu repositório
2. Settings → Secrets and variables → Actions
3. "New repository secret"
4. Crie:
   - Nome: `DOCKER_HUB_USERNAME`
   - Valor: seu username do Docker Hub
5. Crie:
   - Nome: `DOCKER_HUB_TOKEN`
   - Valor: o token que você copiou

#### Passo 3: Fazer push
```bash
git push origin main
```

Pronto! Agora as imagens também aparecerão em: `docker.io/seu-username/helpdesk-ticket-service:latest`

---

## 📊 Ver os builds

1. Vá ao seu repositório GitHub
2. Aba "Actions"
3. Veja o workflow rodando em tempo real
4. Clique no job para ver logs detalhados

---

## 🐳 Usar as imagens em outro lugar

### Do GitHub Container Registry
```bash
docker pull ghcr.io/seu-usuario/helpdesk-system/ticket-service:latest
```

### Do Docker Hub (se configurado)
```bash
docker pull seu-username/helpdesk-ticket-service:latest
```

---

## 🔄 Deploy local com as imagens buildadas

Crie um `docker-compose.remote.yml`:

```yaml
version: '3.8'

services:
  ticket-service:
    image: ghcr.io/seu-usuario/helpdesk-system/ticket-service:latest
    # resto das configs...

  user-service:
    image: ghcr.io/seu-usuario/helpdesk-system/user-service:latest
    # resto das configs...
```

Depois rode:
```bash
docker compose -f docker-compose.yml -f docker-compose.remote.yml up
```

---

## ⚠️ Troubleshooting

### "Workflow failed" - Logs dizem "failed to authenticate"
→ Os secrets não estão configurados corretamente. Verifique:
- Settings → Secrets → Os nomes exatos são `DOCKER_HUB_USERNAME` e `DOCKER_HUB_TOKEN`?
- O token do Docker Hub ainda é válido?

### "Failed to push image"
→ Provavelmente permissões. No Docker Hub, regera o token com permissões "Read & Write"

### "Build cancelled after 360 minutes"
→ Muito lento. Isso significa que o build está demorando demais. Considere:
- Usar menos layers no Dockerfile
- Usar imagens base menores (alpine)
- Otimizar a cache

---

## 📈 Próximas melhorias

1. **Scan de segurança**: Adicione Trivy para detectar vulnerabilidades nas imagens
2. **Deploy automático**: Integre com Render/Vercel para deploy automático após build bem-sucedido
3. **Versioning semântico**: Use tags `v1.0.0` para versionar releases
4. **Notificações**: Configure Slack ou Discord para avisar quando builds falham

