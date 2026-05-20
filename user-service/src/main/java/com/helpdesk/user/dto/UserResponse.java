package com.helpdesk.user.dto;

import com.helpdesk.user.model.UserRole;

public record UserResponse(
        String id,
        String name,
        String email,
        UserRole role
) {
}
