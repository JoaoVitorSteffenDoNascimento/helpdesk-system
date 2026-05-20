package com.helpdesk.ticket.dto;

import com.helpdesk.ticket.model.Priority;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;

public record TicketRequest(
        @NotBlank(message = "Title is required")
        String title,

        @NotBlank(message = "Description is required")
        String description,

        @NotNull(message = "Priority is required")
        Priority priority,

        @NotBlank(message = "User id is required")
        String userId
) {
}
