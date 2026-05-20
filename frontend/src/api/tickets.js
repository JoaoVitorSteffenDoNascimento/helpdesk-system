import api from './client.js';

export async function getTickets() {
  const response = await api.get('/tickets');
  return response.data;
}

export async function createTicket(ticket) {
  const response = await api.post('/tickets', ticket);
  return response.data;
}

export async function updateTicketStatus(id, status) {
  const response = await api.patch(`/tickets/${id}/status`, { status });
  return response.data;
}

export async function addTicketComment(id, comment) {
  const response = await api.post(`/tickets/${id}/comments`, comment);
  return response.data;
}

export async function deleteTicket(id) {
  await api.delete(`/tickets/${id}`);
}
