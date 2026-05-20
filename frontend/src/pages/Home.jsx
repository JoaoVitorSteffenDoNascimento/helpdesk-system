import { useEffect, useState } from 'react';
import { Link } from 'react-router-dom';
import { getTickets } from '../api/tickets.js';
import { getUsers } from '../api/users.js';

function Home() {
  const [summary, setSummary] = useState({
    tickets: 0,
    openTickets: 0,
    users: 0,
  });
  const [error, setError] = useState('');

  useEffect(() => {
    async function loadSummary() {
      try {
        const [tickets, users] = await Promise.all([getTickets(), getUsers()]);
        setSummary({
          tickets: tickets.length,
          openTickets: tickets.filter((ticket) => ticket.status === 'OPEN').length,
          users: users.length,
        });
      } catch (exception) {
        setError(exception.response?.data?.message || 'Unable to load dashboard data.');
      }
    }

    loadSummary();
  }, []);

  return (
    <section className="page">
      <div className="page-heading">
        <div>
          <p className="eyebrow">Operations</p>
          <h1>Help Desk Dashboard</h1>
        </div>
        <Link className="button button--primary" to="/tickets">
          New Ticket
        </Link>
      </div>

      {error && <p className="alert">{error}</p>}

      <div className="summary-grid">
        <article className="summary-card">
          <span>Total Tickets</span>
          <strong>{summary.tickets}</strong>
        </article>
        <article className="summary-card">
          <span>Open Tickets</span>
          <strong>{summary.openTickets}</strong>
        </article>
        <article className="summary-card">
          <span>Users</span>
          <strong>{summary.users}</strong>
        </article>
      </div>
    </section>
  );
}

export default Home;
