import { useEffect, useState } from 'react';
import { createUser, getUsers } from '../api/users.js';
import UserForm from '../components/UserForm.jsx';

function Users() {
  const [users, setUsers] = useState([]);
  const [isLoading, setIsLoading] = useState(true);
  const [error, setError] = useState('');

  async function loadUsers() {
    setIsLoading(true);
    setError('');
    try {
      setUsers(await getUsers());
    } catch (exception) {
      setError(exception.response?.data?.message || 'Unable to load users.');
    } finally {
      setIsLoading(false);
    }
  }

  useEffect(() => {
    loadUsers();
  }, []);

  async function handleCreate(user) {
    try {
      const created = await createUser(user);
      setUsers((current) => [created, ...current]);
      setError('');
    } catch (exception) {
      setError(exception.response?.data?.message || 'Unable to create user.');
    }
  }

  return (
    <section className="page">
      <div className="page-heading">
        <div>
          <p className="eyebrow">Directory</p>
          <h1>Users</h1>
        </div>
        <button className="button" type="button" onClick={loadUsers}>
          Refresh
        </button>
      </div>

      {error && <p className="alert">{error}</p>}

      <UserForm onCreate={handleCreate} />

      {isLoading ? (
        <p className="empty-state">Loading users...</p>
      ) : users.length ? (
        <div className="table-wrap">
          <table>
            <thead>
              <tr>
                <th>Name</th>
                <th>Email</th>
                <th>Role</th>
                <th>ID</th>
              </tr>
            </thead>
            <tbody>
              {users.map((user) => (
                <tr key={user.id}>
                  <td>{user.name}</td>
                  <td>{user.email}</td>
                  <td>
                    <span className="role-pill">{user.role}</span>
                  </td>
                  <td className="mono">{user.id}</td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      ) : (
        <p className="empty-state">No users found.</p>
      )}
    </section>
  );
}

export default Users;
