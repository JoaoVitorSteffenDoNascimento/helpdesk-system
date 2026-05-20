package com.helpdesk.ticket.dto;

import com.helpdesk.ticket.model.TicketStatus;
import jakarta.validation.constraints.NotNull;

public record StatusUpdateRequest(
        @NotNull(message = "Status is required")
        TicketStatus status
) {
}
