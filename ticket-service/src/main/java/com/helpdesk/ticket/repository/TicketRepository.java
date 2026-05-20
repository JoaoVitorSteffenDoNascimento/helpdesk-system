package com.helpdesk.ticket.repository;

import com.helpdesk.ticket.model.Ticket;
import org.springframework.data.mongodb.repository.MongoRepository;

public interface TicketRepository extends MongoRepository<Ticket, String> {
}
