package com.helpdesk.ticket.model;

import java.time.Instant;

public class Comment {

    private String author;
    private String message;
    private Instant createdAt;

    public Comment() {
    }

    public Comment(String author, String message, Instant createdAt) {
        this.author = author;
        this.message = message;
        this.createdAt = createdAt;
    }

    public String getAuthor() {
        return author;
    }

    public void setAuthor(String author) {
        this.author = author;
    }

    public String getMessage() {
        return message;
    }

    public void setMessage(String message) {
        this.message = message;
    }

    public Instant getCreatedAt() {
        return createdAt;
    }

    public void setCreatedAt(Instant createdAt) {
        this.createdAt = createdAt;
    }
}
