package com.helpdesk.gateway.service;

import com.helpdesk.gateway.dto.ErrorResponse;
import io.github.resilience4j.circuitbreaker.annotation.CircuitBreaker;
import io.github.resilience4j.retry.annotation.Retry;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpMethod;
import org.springframework.http.ResponseEntity;
import org.springframework.stereotype.Service;
import org.springframework.web.reactive.function.client.WebClient;
import org.springframework.web.reactive.function.client.WebClientResponseException;
import reactor.core.publisher.Mono;

@Service
public class ResilientProxyService {

    private final WebClient webClient;

    @Value("${TICKET_SERVICE_URL:http://localhost:8081}")
    private String ticketServiceUrl;

    @Value("${USER_SERVICE_URL:http://localhost:8082}")
    private String userServiceUrl;

    public ResilientProxyService(WebClient webClient) {
        this.webClient = webClient;
    }

    @CircuitBreaker(name = "ticketServiceCircuit", fallbackMethod = "ticketFallback")
    @Retry(name = "ticketServiceRetry")
    public Mono<ResponseEntity<Object>> proxyTicketRequest(HttpMethod method,
                                                           String path,
                                                           HttpHeaders headers,
                                                           Mono<String> body) {
        return proxyRequest(ticketServiceUrl, method, path, headers, body, "ticket-service");
    }

    @CircuitBreaker(name = "userServiceCircuit", fallbackMethod = "userFallback")
    @Retry(name = "userServiceRetry")
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

        WebClient.RequestHeadersSpec<?> request = webClient.method(method)
                .uri(url)
                .headers(httpHeaders -> httpHeaders.addAll(headers));

        Mono<ResponseEntity<Object>> responseMono = requiresBody(method)
                ? body.defaultIfEmpty("").flatMap(payload -> request.bodyValue(payload).retrieve().toEntity(String.class))
                : request.retrieve().toEntity(String.class);

        return responseMono.map(responseEntity -> ResponseEntity
                        .status(responseEntity.getStatusCode())
                        .headers(responseEntity.getHeaders())
                        .body(responseEntity.getBody()))
                .onErrorResume(WebClientResponseException.class, ex -> Mono.just(ResponseEntity
                        .status(ex.getStatusCode())
                        .body(new ErrorResponse(serviceName + "-error", ex.getResponseBodyAsString()))));
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

    private Mono<ResponseEntity<Object>> ticketFallback(HttpMethod method,
                                                         String path,
                                                         HttpHeaders headers,
                                                         Mono<String> body,
                                                         Throwable exception) {
        ErrorResponse errorResponse = new ErrorResponse("ticket-service-unavailable",
                "O serviço de tickets está temporariamente indisponível. Tente novamente mais tarde.");
        return Mono.just(ResponseEntity.status(503).body(errorResponse));
    }

    private Mono<ResponseEntity<Object>> userFallback(HttpMethod method,
                                                        String path,
                                                        HttpHeaders headers,
                                                        Mono<String> body,
                                                        Throwable exception) {
        ErrorResponse errorResponse = new ErrorResponse("user-service-unavailable",
                "O serviço de usuários está temporariamente indisponível. Tente novamente mais tarde.");
        return Mono.just(ResponseEntity.status(503).body(errorResponse));
    }
}
