import { useState } from 'react';

const initialForm = {
  title: '',
  description: '',
  priority: 'MEDIUM',
  userId: '',
};

function TicketForm({ users, onCreate }) {
  const [form, setForm] = useState(initialForm);
  const [isSubmitting, setIsSubmitting] = useState(false);

  async function handleSubmit(event) {
    event.preventDefault();
    setIsSubmitting(true);
    await onCreate(form);
    setForm(initialForm);
    setIsSubmitting(false);
  }

  return (
    <form className="form-panel" onSubmit={handleSubmit}>
      <div className="form-grid">
        <label>
          <span>Title</span>
          <input
            required
            value={form.title}
            onChange={(event) => setForm({ ...form, title: event.target.value })}
            placeholder="Cannot access account"
          />
        </label>

        <label>
          <span>Priority</span>
          <select
            value={form.priority}
            onChange={(event) => setForm({ ...form, priority: event.target.value })}
          >
            <option value="LOW">LOW</option>
            <option value="MEDIUM">MEDIUM</option>
            <option value="HIGH">HIGH</option>
            <option value="URGENT">URGENT</option>
          </select>
        </label>

        <label className="span-2">
          <span>Description</span>
          <textarea
            required
            value={form.description}
            onChange={(event) => setForm({ ...form, description: event.target.value })}
            placeholder="Describe the request"
            rows="4"
          />
        </label>

        <label className="span-2">
          <span>User</span>
          <select
            required
            value={form.userId}
            onChange={(event) => setForm({ ...form, userId: event.target.value })}
          >
            <option value="">Select a user</option>
            {users.map((user) => (
              <option key={user.id} value={user.id}>
                {user.name} ({user.email})
              </option>
            ))}
          </select>
        </label>
      </div>

      <button type="submit" className="button button--primary" disabled={isSubmitting}>
        Create Ticket
      </button>
    </form>
  );
}

export default TicketForm;
