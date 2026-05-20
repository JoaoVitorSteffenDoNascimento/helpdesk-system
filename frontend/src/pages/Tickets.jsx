import { useEffect, useState } from 'react';
import {
  addTicketComment,
  createTicket,
  deleteTicket,
  getTickets,
  updateTicketStatus,
} from '../api/tickets.js';
import { getUsers } from '../api/users.js';
import TicketCard from '../components/TicketCard.jsx';
import TicketForm from '../components/TicketForm.jsx';

function Tickets() {
  const [tickets, setTickets] = useState([]);
  const [users, setUsers] = useState([]);
  const [isLoading, setIsLoading] = useState(true);
  const [error, setError] = useState('');

  async function loadData() {
    setIsLoading(true);
    setError('');
    try {
      const [ticketData, userData] = await Promise.all([getTickets(), getUsers()]);
      setTickets(ticketData);
      setUsers(userData);
    } catch (exception) {
      setError(exception.response?.data?.message || 'Unable to load tickets.');
    } finally {
      setIsLoading(false);
    }
  }

  useEffect(() => {
    loadData();
  }, []);

  async function handleCreate(ticket) {
    try {
      const created = await createTicket(ticket);
      setTickets((current) => [created, ...current]);
      setError('');
    } catch (exception) {
      setError(exception.response?.data?.message || 'Unable to create ticket.');
    }
  }

  async function handleStatusChange(id, status) {
    try {
      const updated = await updateTicketStatus(id, status);
      setTickets((current) => current.map((ticket) => (ticket.id === id ? updated : ticket)));
      setError('');
    } catch (exception) {
      setError(exception.response?.data?.message || 'Unable to update ticket status.');
    }
  }

  async function handleAddComment(id, comment) {
    try {
      const updated = await addTicketComment(id, comment);
      setTickets((current) => current.map((ticket) => (ticket.id === id ? updated : ticket)));
      setError('');
    } catch (exception) {
      setError(exception.response?.data?.message || 'Unable to add comment.');
    }
  }

  async function handleDelete(id) {
    try {
      await deleteTicket(id);
      setTickets((current) => current.filter((ticket) => ticket.id !== id));
      setError('');
    } catch (exception) {
      setError(exception.response?.data?.message || 'Unable to delete ticket.');
    }
  }

  return (
    <section className="page">
      <div className="page-heading">
        <div>
          <p className="eyebrow">Queue</p>
          <h1>Tickets</h1>
        </div>
        <button className="button" type="button" onClick={loadData}>
          Refresh
        </button>
      </div>

      {error && <p className="alert">{error}</p>}

      <TicketForm users={users} onCreate={handleCreate} />

      {isLoading ? (
        <p className="empty-state">Loading tickets...</p>
      ) : tickets.length ? (
        <div className="ticket-list">
          {tickets.map((ticket) => (
            <TicketCard
              key={ticket.id}
              ticket={ticket}
              onStatusChange={handleStatusChange}
              onAddComment={handleAddComment}
              onDelete={handleDelete}
            />
          ))}
        </div>
      ) : (
        <p className="empty-state">No tickets found.</p>
      )}
    </section>
  );
}

export default Tickets;
