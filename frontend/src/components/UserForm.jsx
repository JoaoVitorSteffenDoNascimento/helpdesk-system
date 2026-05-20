import { useState } from 'react';

const initialForm = {
  name: '',
  email: '',
  role: 'CUSTOMER',
};

function UserForm({ onCreate }) {
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
          <span>Name</span>
          <input
            required
            value={form.name}
            onChange={(event) => setForm({ ...form, name: event.target.value })}
            placeholder="Alex Johnson"
          />
        </label>

        <label>
          <span>Email</span>
          <input
            required
            type="email"
            value={form.email}
            onChange={(event) => setForm({ ...form, email: event.target.value })}
            placeholder="alex@example.com"
          />
        </label>

        <label>
          <span>Role</span>
          <select
            value={form.role}
            onChange={(event) => setForm({ ...form, role: event.target.value })}
          >
            <option value="CUSTOMER">CUSTOMER</option>
            <option value="AGENT">AGENT</option>
            <option value="ADMIN">ADMIN</option>
          </select>
        </label>
      </div>

      <button type="submit" className="button button--primary" disabled={isSubmitting}>
        Create User
      </button>
    </form>
  );
}

export default UserForm;
