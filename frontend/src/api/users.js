import api from './client.js';

export async function getUsers() {
  const response = await api.get('/users');
  return response.data;
}

export async function createUser(user) {
  const response = await api.post('/users', user);
  return response.data;
}
