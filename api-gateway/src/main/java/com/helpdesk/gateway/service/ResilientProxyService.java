package com.helpdesk.gateway.service;

import com.helpdesk.gateway.dto.ErrorResponse;
import io.github.resilience4j.circuitbreaker.CircuitBreaker;
import io.github.resilience4j.circuitbreaker.CircuitBreakerRegistry;
import io.github.resilience4j.reactor.circuitbreaker.operator.CircuitBreakerOperator;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpMethod;
import org.springframework.http.ResponseEntity;
import org.springframework.lang.NonNull;
import org.springframework.stereotype.Service;
import org.springframework.web.reactive.function.client.WebClient;
import org.springframework.web.reactive.function.client.WebClientResponseException;
import reactor.core.publisher.Mono;
import java.time.Duration;

@Service
public class ResilientProxyService {

    private final WebClient webClient;
    private final CircuitBreakerRegistry circuitBreakerRegistry;

    @Value("${TICKET_SERVICE_URL:http://localhost:8081}")
    private String ticketServiceUrl;

    @Value("${USER_SERVICE_URL:http://localhost:8082}")
    private String userServiceUrl;

    public ResilientProxyService(WebClient webClient, 
                                 CircuitBreakerRegistry circuitBreakerRegistry) {
        this.webClient = webClient;
        this.circuitBreakerRegistry = circuitBreakerRegistry;
    }

    public Mono<ResponseEntity<Object>> proxyTicketRequest(HttpMethod method,
                                                           String path,
                                                           HttpHeaders headers,
                                                           Mono<String> body) {
        return proxyRequest(ticketServiceUrl, method, path, headers, body, "ticket-service");
    }

    public Mono<ResponseEntity<Object>> proxyUserRequest(HttpMethod method,
                                                          String path,
                                                          HttpHeaders headers,
                                                          Mono<String> body) {
        return proxyRequest(userServiceUrl, method, path, headers, body, "user-service");
    }

    private Mono<ResponseEntity<Object>> proxyRequest(String serviceUrl,
                                                       HttpMethod method,
                                                       String path,
                                                       HttpHeaders headers,
                                                       Mono<String> body,
                                                       String serviceName) {
        String url = buildServiceUrl(serviceUrl, path);

        Mono<ResponseEntity<Object>> responseMono = (requiresBody(method) ? body.defaultIfEmpty("") : Mono.just(""))
                .flatMap(payload -> executeRequest(method, url, headers, payload));

        CircuitBreaker circuitBreaker = getOrCreateCircuitBreaker(serviceName);

        return responseMono
                .retry(2)
                .delayElement(Duration.ofMillis(500))
                .transformDeferred(CircuitBreakerOperator.of(circuitBreaker))
                .onErrorMap(ex -> new Exception("Service error: " + serviceName, ex))
                .onErrorResume(ex -> handleError(ex, serviceName));
    }

    private CircuitBreaker getOrCreateCircuitBreaker(String serviceName) {
        String cbName = serviceName.equals("ticket-service") ? "ticketServiceCircuit" : "userServiceCircuit";
        try {
            return circuitBreakerRegistry.circuitBreaker(cbName);
        } catch (Exception e) {
            return CircuitBreaker.ofDefaults(cbName);
        }
    }

    private Mono<ResponseEntity<Object>> executeRequest(@NonNull HttpMethod method, String url, HttpHeaders headers, String payload) {
        var requestSpec = webClient.method(method)
                .uri(url)
                .headers(httpHeaders -> {
                    if (headers != null && !headers.isEmpty()) {
                        httpHeaders.addAll(headers);
                    }
                });

        if (requiresBody(method) && !payload.isEmpty()) {
            return requestSpec.bodyValue(payload)
                    .exchangeToMono(response -> response.toEntity(Object.class))
                    .map(entity -> ResponseEntity.status(entity.getStatusCode())
                            .headers(entity.getHeaders())
                            .body(entity.getBody()));
        } else {
            return requestSpec.retrieve()
                    .toEntity(Object.class)
                    .map(entity -> ResponseEntity.status(entity.getStatusCode())
                            .headers(entity.getHeaders())
                            .body(entity.getBody()));
        }
    }

    private Mono<ResponseEntity<Object>> handleError(Throwable ex, String serviceName) {
        if (ex instanceof WebClientResponseException webClientEx) {
            ErrorResponse errorResponse = new ErrorResponse(serviceName + "-error", webClientEx.getResponseBodyAsString());
            return Mono.just(ResponseEntity.status(webClientEx.getStatusCode()).body(errorResponse));
        }
        ErrorResponse errorResponse = new ErrorResponse(serviceName + "-unavailable",
                "O serviço está temporariamente indisponível. Tente novamente mais tarde.");
        return Mono.just(ResponseEntity.status(503).body(errorResponse));
    }

    private String buildServiceUrl(String baseUrl, String path) {
        if (path == null || path.isEmpty()) {
            return baseUrl;
        }
        if (path.startsWith("/")) {
            return baseUrl + path;
        }
        return baseUrl + "/" + path;
    }

    private boolean requiresBody(HttpMethod method) {
        return HttpMethod.POST.equals(method)
                || HttpMethod.PUT.equals(method)
                || HttpMethod.PATCH.equals(method);
    }
}
