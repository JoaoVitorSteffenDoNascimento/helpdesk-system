import { useState } from 'react';

const statusOptions = ['OPEN', 'IN_PROGRESS', 'RESOLVED', 'CLOSED'];

function TicketCard({ ticket, onStatusChange, onAddComment, onDelete }) {
  const [comment, setComment] = useState({ author: '', message: '' });
  const [isCommenting, setIsCommenting] = useState(false);

  async function handleCommentSubmit(event) {
    event.preventDefault();
    if (!comment.author.trim() || !comment.message.trim()) {
      return;
    }

    setIsCommenting(true);
    await onAddComment(ticket.id, comment);
    setComment({ author: '', message: '' });
    setIsCommenting(false);
  }

  return (
    <article className="ticket-card">
      <div className="ticket-card__header">
        <div>
          <p className="eyebrow">{ticket.priority}</p>
          <h3>{ticket.title}</h3>
        </div>
        <span className={`status-pill status-pill--${ticket.status.toLowerCase()}`}>
          {ticket.status.replace('_', ' ')}
        </span>
      </div>

      <p className="ticket-description">{ticket.description}</p>
      <dl className="meta-grid">
        <div>
          <dt>User ID</dt>
          <dd>{ticket.userId}</dd>
        </div>
        <div>
          <dt>Created</dt>
          <dd>{new Date(ticket.createdAt).toLocaleString()}</dd>
        </div>
      </dl>

      <div className="ticket-actions">
        <label>
          <span>Status</span>
          <select
            value={ticket.status}
            onChange={(event) => onStatusChange(ticket.id, event.target.value)}
          >
            {statusOptions.map((status) => (
              <option key={status} value={status}>
                {status.replace('_', ' ')}
              </option>
            ))}
          </select>
        </label>
        <button type="button" className="button button--danger" onClick={() => onDelete(ticket.id)}>
          Delete
        </button>
      </div>

      <div className="comments">
        <h4>Comments</h4>
        {ticket.comments?.length ? (
          <ul>
            {ticket.comments.map((item, index) => (
              <li key={`${item.createdAt}-${index}`}>
                <strong>{item.author}</strong>
                <span>{item.message}</span>
              </li>
            ))}
          </ul>
        ) : (
          <p className="empty-note">No comments yet.</p>
        )}
      </div>

      <form className="inline-form" onSubmit={handleCommentSubmit}>
        <input
          aria-label="Comment author"
          placeholder="Author"
          value={comment.author}
          onChange={(event) => setComment({ ...comment, author: event.target.value })}
        />
        <input
          aria-label="Comment message"
          placeholder="Comment"
          value={comment.message}
          onChange={(event) => setComment({ ...comment, message: event.target.value })}
        />
        <button type="submit" className="button" disabled={isCommenting}>
          Add
        </button>
      </form>
    </article>
  );
}

export default TicketCard;
