# Arquitetura de Microserviços Resiliente

## 🎯 Objetivo

Garantir que se um microserviço cair, apenas aquele serviço cai — não todo o backend.

## ✅ Melhorias Implementadas

### 1. **Isolamento de Falhas**
- `restart: on-failure:5` em cada serviço
- Cada serviço tem seu próprio ciclo de vida
- MongoDB pode cair sem derrubar os serviços (se tiverem cache/retry)

### 2. **Sem Dependências Rígidas**
**Antes:**
```yaml
api-gateway:
  depends_on:
    - ticket-service  # ❌ API-gateway só inicia se ticket-service está saudável
    - user-service
```

**Agora:**
```yaml
api-gateway:
  # ✅ Inicia independente, trata erros via circuit breaker
```

### 3. **Circuit Breaker (Resilience4j)**
Se `ticket-service` cair:
1. API-gateway tenta chamar → falha
2. Conta as falhas
3. Após 50% de falhas, abre o circuit
4. Retorna erro rapidamente em vez de tentar (evita timeout)
5. Após 10s, tenta novamente (half-open)

Configuração:
```yaml
RESILIENCE4J_CIRCUITBREAKER_ENABLED: "true"
RESILIENCE4J_CIRCUITBREAKER_FAILURE_RATE_THRESHOLD: "50"  # Abre com 50% de falhas
RESILIENCE4J_CIRCUITBREAKER_WAIT_DURATION_IN_OPEN_STATE: "10000"  # Tenta recuperar em 10s
```

### 4. **Retry Automático**
```yaml
RESILIENCE4J_RETRY_MAX_ATTEMPTS: "3"  # Tenta 3 vezes
RESILIENCE4J_RETRY_WAIT_DURATION: "1000"  # Aguarda 1s entre tentativas
```

### 5. **Restart Policy Granular**
```yaml
deploy:
  restart_policy:
    condition: on-failure
    delay: 5s  # Aguarda 5s antes de reiniciar
    max_attempts: 5  # Máximo 5 tentativas
    window: 120s  # Em janela de 120s
```

Isso significa: se o serviço cair 5 vezes em 2 minutos, não tenta mais.

### 6. **Labels para Monitoramento**
```yaml
labels:
  - "app=helpdesk"
  - "service=microservice"
  - "microservice=ticket"
```

Facilita monitorar cada serviço com ferramentas como Prometheus.

---

## 📊 Cenários de Falha

### Cenário 1: Ticket Service cai
1. ❌ `ticket-service` é derrubado
2. ✅ `user-service` continua rodando
3. ✅ `api-gateway` continua rodando
4. 🔄 API-gateway abre circuit breaker para `ticket-service`
5. Frontend consegue acessar user-service, mas não consegue acessar tickets
6. Após 30s, `ticket-service` reinicia (healthcheck + restart policy)
7. ✅ Tudo volta ao normal

### Cenário 2: MongoDB cai
1. ❌ MongoDB é derrubado
2. ✅ Serviços continuam rodando (não dependem de MongoDB sendo saudável)
3. 🔄 Quando um serviço tenta acessar DB, falha
4. Retry + circuit breaker tratam o erro
5. Frontend retorna erro gracioso em vez de derrubar tudo

### Cenário 3: API Gateway cai
1. ❌ `api-gateway` é derrubado
2. ✅ `ticket-service` e `user-service` continuam rodando
3. 🔄 Frontend não consegue acessar endpoints
4. Após ~30s, `api-gateway` reinicia
5. ✅ Comunicação restaurada

---

## 🔧 O que Falta no Código Java

Para 100% de resiliência, o código Java precisa:

### 1. **Adicionar Resilience4j ao POM**
```xml
<dependency>
  <groupId>io.github.resilience4j</groupId>
  <artifactId>resilience4j-spring-boot3</artifactId>
  <version>2.1.0</version>
</dependency>
<dependency>
  <groupId>io.github.resilience4j</groupId>
  <artifactId>resilience4j-circuitbreaker</artifactId>
</dependency>
<dependency>
  <groupId>io.github.resilience4j</groupId>
  <artifactId>resilience4j-retry</artifactId>
</dependency>
```

### 2. **Adicionar Annotations nas chamadas HTTP**
No `api-gateway`, ao chamar `ticket-service`:
```java
@CircuitBreaker(name = "ticket-service", fallbackMethod = "ticketServiceFallback")
@Retry(name = "ticket-service")
public ResponseEntity<?> getTickets() {
    return restTemplate.getForEntity(ticketServiceUrl + "/tickets", Object.class);
}

public ResponseEntity<?> ticketServiceFallback(Exception ex) {
    // Retornar resposta parcial ou cache
    return ResponseEntity.status(503)
        .body(new ErrorResponse("Ticket service temporarily unavailable"));
}
```

### 3. **Adicionar Application Properties**
```properties
resilience4j.circuitbreaker.instances.ticket-service.failure-rate-threshold=50
resilience4j.circuitbreaker.instances.ticket-service.wait-duration-in-open-state=10000
resilience4j.retry.instances.ticket-service.max-attempts=3
resilience4j.retry.instances.ticket-service.wait-duration=1000
```

---

## 🚀 Testando Localmente

```bash
# Terminal 1: Iniciar tudo
docker compose up

# Terminal 2: Derrubar ticket-service
docker stop helpdesk-ticket-service

# Observar:
docker compose ps  # ticket-service está "restarting"
docker logs helpdesk-api-gateway  # Ver circuit breaker em ação

# Aguardar ~30s
docker compose ps  # ticket-service volta a estar "healthy"

# Frontend ainda funciona, ticket-service está recuperado
```

---

## 📈 Próximas Melhorias

1. **Observabilidade:**
   - Adicionar Prometheus/Grafana para monitorar métricas
   - Adicionar Jaeger para distributed tracing

2. **Load Balancing:**
   - Múltiplas instâncias de cada serviço
   - Nginx/HAProxy para balancear

3. **Message Queue:**
   - Adicionar RabbitMQ/Kafka para comunicação assíncrona
   - Desacoplar serviços ainda mais

4. **Health Endpoints:**
   - Melhorar `/actuator/health` para retornar status de dependências
   - Liveness vs Readiness probes

