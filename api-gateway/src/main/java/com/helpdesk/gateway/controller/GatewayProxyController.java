package com.helpdesk.gateway.controller;

import com.helpdesk.gateway.service.ResilientProxyService;
import org.springframework.http.HttpHeaders;
import org.springframework.http.ResponseEntity;
import org.springframework.http.server.reactive.ServerHttpRequest;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestMethod;
import org.springframework.web.bind.annotation.RestController;
import reactor.core.publisher.Mono;

@RestController
public class GatewayProxyController {

    private final ResilientProxyService proxyService;

    public GatewayProxyController(ResilientProxyService proxyService) {
        this.proxyService = proxyService;
    }

    @RequestMapping(path = "/tickets/**", method = {
            RequestMethod.GET,
            RequestMethod.POST,
            RequestMethod.PUT,
            RequestMethod.PATCH,
            RequestMethod.DELETE,
            RequestMethod.OPTIONS
    })
    public Mono<ResponseEntity<Object>> forwardToTicketService(ServerHttpRequest request,
                                                               @RequestBody(required = false) Mono<String> body) {
        String path = extractPath(request.getURI().getRawPath(), "/tickets");
        return proxyService.proxyTicketRequest(request.getMethod(), path, cleanHeaders(request.getHeaders()), body == null ? Mono.empty() : body);
    }

    @RequestMapping(path = "/users/**", method = {
            RequestMethod.GET,
            RequestMethod.POST,
            RequestMethod.PUT,
            RequestMethod.PATCH,
            RequestMethod.DELETE,
            RequestMethod.OPTIONS
    })
    public Mono<ResponseEntity<Object>> forwardToUserService(ServerHttpRequest request,
                                                             @RequestBody(required = false) Mono<String> body) {
        String path = extractPath(request.getURI().getRawPath(), "/users");
        return proxyService.proxyUserRequest(request.getMethod(), path, cleanHeaders(request.getHeaders()), body == null ? Mono.empty() : body);
    }

    private String extractPath(String rawPath, String prefix) {
        if (rawPath == null || rawPath.length() <= prefix.length()) {
            return "";
        }
        return rawPath.substring(prefix.length());
    }

    private HttpHeaders cleanHeaders(HttpHeaders headers) {
        HttpHeaders result = new HttpHeaders();
        result.putAll(headers);
        result.remove("host");
        return result;
    }
}
