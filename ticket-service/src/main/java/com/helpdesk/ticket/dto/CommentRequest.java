package com.helpdesk.ticket.dto;

import jakarta.validation.constraints.NotBlank;

public record CommentRequest(
        @NotBlank(message = "Author is required")
        String author,

        @NotBlank(message = "Message is required")
        String message
) {
}
