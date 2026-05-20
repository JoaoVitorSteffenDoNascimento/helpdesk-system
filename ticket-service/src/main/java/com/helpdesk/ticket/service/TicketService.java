package com.helpdesk.ticket.service;

import com.helpdesk.ticket.dto.CommentRequest;
import com.helpdesk.ticket.dto.CommentResponse;
import com.helpdesk.ticket.dto.StatusUpdateRequest;
import com.helpdesk.ticket.dto.TicketRequest;
import com.helpdesk.ticket.dto.TicketResponse;
import com.helpdesk.ticket.exception.ResourceNotFoundException;
import com.helpdesk.ticket.model.Comment;
import com.helpdesk.ticket.model.Ticket;
import com.helpdesk.ticket.model.TicketStatus;
import com.helpdesk.ticket.repository.TicketRepository;
import java.time.Instant;
import java.util.ArrayList;
import java.util.List;
import org.springframework.stereotype.Service;

@Service
public class TicketService {

    private final TicketRepository ticketRepository;

    public TicketService(TicketRepository ticketRepository) {
        this.ticketRepository = ticketRepository;
    }

    public TicketResponse createTicket(TicketRequest request) {
        Ticket ticket = new Ticket();
        ticket.setTitle(request.title());
        ticket.setDescription(request.description());
        ticket.setPriority(request.priority());
        ticket.setStatus(TicketStatus.OPEN);
        ticket.setUserId(request.userId());
        ticket.setCreatedAt(Instant.now());
        ticket.setComments(new ArrayList<>());

        return toResponse(ticketRepository.save(ticket));
    }

    public List<TicketResponse> getTickets() {
        return ticketRepository.findAll()
                .stream()
                .map(this::toResponse)
                .toList();
    }

    public TicketResponse getTicketById(String id) {
        return toResponse(findTicket(id));
    }

    public TicketResponse updateStatus(String id, StatusUpdateRequest request) {
        Ticket ticket = findTicket(id);
        ticket.setStatus(request.status());
        return toResponse(ticketRepository.save(ticket));
    }

    public TicketResponse addComment(String id, CommentRequest request) {
        Ticket ticket = findTicket(id);
        List<Comment> comments = ticket.getComments();
        if (comments == null) {
            comments = new ArrayList<>();
            ticket.setComments(comments);
        }

        comments.add(new Comment(request.author(), request.message(), Instant.now()));
        return toResponse(ticketRepository.save(ticket));
    }

    public void deleteTicket(String id) {
        Ticket ticket = findTicket(id);
        ticketRepository.delete(ticket);
    }

    private Ticket findTicket(String id) {
        return ticketRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Ticket not found: " + id));
    }

    private TicketResponse toResponse(Ticket ticket) {
        List<CommentResponse> comments = ticket.getComments() == null
                ? List.of()
                : ticket.getComments()
                        .stream()
                        .map(comment -> new CommentResponse(
                                comment.getAuthor(),
                                comment.getMessage(),
                                comment.getCreatedAt()
                        ))
                        .toList();

        return new TicketResponse(
                ticket.getId(),
                ticket.getTitle(),
                ticket.getDescription(),
                ticket.getPriority(),
                ticket.getStatus(),
                ticket.getUserId(),
                ticket.getCreatedAt(),
                comments
        );
    }
}
