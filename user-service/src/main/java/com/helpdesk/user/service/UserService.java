package com.helpdesk.user.service;

import com.helpdesk.user.dto.UserRequest;
import com.helpdesk.user.dto.UserResponse;
import com.helpdesk.user.exception.DuplicateEmailException;
import com.helpdesk.user.exception.ResourceNotFoundException;
import com.helpdesk.user.model.User;
import com.helpdesk.user.repository.UserRepository;
import java.util.List;
import org.springframework.stereotype.Service;

@Service
public class UserService {

    private final UserRepository userRepository;

    public UserService(UserRepository userRepository) {
        this.userRepository = userRepository;
    }

    public UserResponse createUser(UserRequest request) {
        if (userRepository.existsByEmailIgnoreCase(request.email())) {
            throw new DuplicateEmailException("Email is already registered: " + request.email());
        }

        User user = new User();
        user.setName(request.name());
        user.setEmail(request.email());
        user.setRole(request.role());

        return toResponse(userRepository.save(user));
    }

    public List<UserResponse> getUsers() {
        return userRepository.findAll()
                .stream()
                .map(this::toResponse)
                .toList();
    }

    public UserResponse getUserById(String id) {
        return toResponse(findUser(id));
    }

    private User findUser(String id) {
        return userRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("User not found: " + id));
    }

    private UserResponse toResponse(User user) {
        return new UserResponse(
                user.getId(),
                user.getName(),
                user.getEmail(),
                user.getRole()
        );
    }
}
