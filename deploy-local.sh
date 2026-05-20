#!/bin/bash

# Script para fazer pull e rodar as imagens do Docker Hub
# Uso: ./deploy-local.sh <docker-hub-username> [tag]

set -e

if [ -z "$1" ]; then
    echo "Uso: $0 <docker-hub-username> [tag]"
    echo "Exemplo: $0 joaovitor latest"
    exit 1
fi

DOCKER_USERNAME=$1
TAG=${2:-latest}
REGISTRY=docker.io

echo "🐳 Fazendo pull das imagens do Docker Hub..."
echo "   Username: $DOCKER_USERNAME"
echo "   Tag: $TAG"

SERVICES=("ticket-service" "user-service" "api-gateway" "frontend")

for service in "${SERVICES[@]}"; do
    IMAGE="$REGISTRY/$DOCKER_USERNAME/helpdesk-$service:$TAG"
    echo ""
    echo "▶️  Puxando $IMAGE..."
    docker pull "$IMAGE"
done

echo ""
echo "⏹️  Parando containers antigos..."
docker compose down 2>/dev/null || true

echo ""
echo "📝 Atualizando docker-compose.override.yml com as imagens..."

cat > docker-compose.override.yml <<EOF
# Override para usar imagens do Docker Hub
# Gerado automaticamente por deploy-local.sh

services:
  ticket-service:
    image: $REGISTRY/$DOCKER_USERNAME/helpdesk-ticket-service:$TAG

  user-service:
    image: $REGISTRY/$DOCKER_USERNAME/helpdesk-user-service:$TAG

  api-gateway:
    image: $REGISTRY/$DOCKER_USERNAME/helpdesk-api-gateway:$TAG

  frontend:
    image: $REGISTRY/$DOCKER_USERNAME/helpdesk-frontend:$TAG
EOF

echo ""
echo "🚀 Iniciando containers..."
docker compose up -d

echo ""
echo "✅ Deploy completo!"
echo ""
docker compose ps

echo ""
echo "Acessar:"
echo "  Frontend:   http://localhost:5173"
echo "  API Gateway: http://localhost:8080"
echo "  Ticket Service: http://localhost:8081"
echo "  User Service: http://localhost:8082"
echo "  MongoDB: localhost:27017"
