package com.helpdesk.ticket.dto;

import java.time.Instant;

public record CommentResponse(
        String author,
        String message,
        Instant createdAt
) {
}
