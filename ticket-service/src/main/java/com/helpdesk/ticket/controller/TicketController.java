package com.helpdesk.ticket.controller;

import com.helpdesk.ticket.dto.CommentRequest;
import com.helpdesk.ticket.dto.StatusUpdateRequest;
import com.helpdesk.ticket.dto.TicketRequest;
import com.helpdesk.ticket.dto.TicketResponse;
import com.helpdesk.ticket.service.TicketService;
import jakarta.validation.Valid;
import java.util.List;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PatchMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/tickets")
public class TicketController {

    private final TicketService ticketService;

    public TicketController(TicketService ticketService) {
        this.ticketService = ticketService;
    }

    @PostMapping
    @ResponseStatus(HttpStatus.CREATED)
    public TicketResponse createTicket(@Valid @RequestBody TicketRequest request) {
        return ticketService.createTicket(request);
    }

    @GetMapping
    public List<TicketResponse> getTickets() {
        return ticketService.getTickets();
    }

    @GetMapping("/{id}")
    public TicketResponse getTicketById(@PathVariable String id) {
        return ticketService.getTicketById(id);
    }

    @PatchMapping("/{id}/status")
    public TicketResponse updateStatus(
            @PathVariable String id,
            @Valid @RequestBody StatusUpdateRequest request
    ) {
        return ticketService.updateStatus(id, request);
    }

    @PostMapping("/{id}/comments")
    @ResponseStatus(HttpStatus.CREATED)
    public TicketResponse addComment(
            @PathVariable String id,
            @Valid @RequestBody CommentRequest request
    ) {
        return ticketService.addComment(id, request);
    }

    @DeleteMapping("/{id}")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void deleteTicket(@PathVariable String id) {
        ticketService.deleteTicket(id);
    }
}
