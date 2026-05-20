package com.helpdesk.ticket.dto;

import com.helpdesk.ticket.model.Priority;
import com.helpdesk.ticket.model.TicketStatus;
import java.time.Instant;
import java.util.List;

public record TicketResponse(
        String id,
        String title,
        String description,
        Priority priority,
        TicketStatus status,
        String userId,
        Instant createdAt,
        List<CommentResponse> comments
) {
}
