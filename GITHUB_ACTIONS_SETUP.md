# Configurar GitHub Actions com Docker

Dois workflows foram criados para CI/CD com Docker:

## 1️⃣ **GitHub Container Registry (Recomendado)**

Arquivo: `.github/workflows/docker-build.yml`

**Vantagens:**
- Integrado nativamente ao GitHub
- Sem custo de armazenamento
- Tokens automáticos
- Privado por padrão

**Setup:**
1. Nada para configurar! O workflow usa `GITHUB_TOKEN` automaticamente
2. Faz push para `ghcr.io/seu-usuario/seu-repositorio/service:tag`

**Como usar:**
```bash
# Fazer push para main ou develop (automático)
git push origin main

# Ou criar tag para versão
git tag v1.0.0
git push origin v1.0.0
```

---

## 2️⃣ **Docker Hub**

Arquivo: `.github/workflows/docker-hub.yml`

**Vantagens:**
- Popular e bem documentado
- Integra com Docker Desktop
- Webhook support

**Setup obrigatório:**
1. Crie uma conta em [hub.docker.com](https://hub.docker.com)
2. Gere um Personal Access Token:
   - Vá em Account Settings → Security → Personal Access Tokens
   - Crie token com permissões `read:repo_self` e `write:repo_self`
3. No GitHub, vá em Settings → Secrets and variables → Actions
   - Crie `DOCKER_HUB_USERNAME` com seu username
   - Crie `DOCKER_HUB_TOKEN` com o token gerado

**Como usar:**
```bash
# Fazer push para main (automático)
git push origin main

# Ou criar release tagged (para versionar)
git tag v1.0.0
git push origin v1.0.0
```

Imagens aparecem em: `hub.docker.com/r/seu-username/helpdesk-ticket-service`

---

## 🔄 **Workflow de PR (Testes)**

Ambos os workflows rodam testes em Pull Requests:
- Buildx cache para build mais rápido
- Valida que as imagens buildão sem erros
- Não faz push (apenas em main)

---

## 🚀 **Deploy Local com Pull de Imagens**

Depois que as imagens são buildadas no GitHub Actions, você pode rodá-las localmente:

```bash
# Usar GHCR (GitHub Container Registry)
docker pull ghcr.io/seu-usuario/seu-repo/ticket-service:latest
docker compose up -d

# Ou usar Docker Hub (se configurado)
chmod +x deploy-local.sh
./deploy-local.sh seu-docker-username latest
```

---

## 📊 **Status dos Builds**

Ver histórico de builds:
- GitHub Actions: Abra seu repositório → Actions
- Logs: Clique no workflow → Clique no job → Ver logs detalhados

---

## ⚡ **Melhorias Futuras**

1. **Scan de vulnerabilidades**
   ```yaml
   - name: Run Trivy vulnerability scanner
     uses: aquasecurity/trivy-action@master
   ```

2. **Push para Render/Vercel** (se usar)
   - Adicionar deploy stage após build bem-sucedido

3. **Notificações** (Slack, Discord)
   - Avisar quando build falhar

4. **Auto-tag** semântica
   - Usar commit messages para version bumps
