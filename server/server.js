const app = require('./app');

const PORT = process.env.PORT || 3000;

const http = require('http');
const { Server } = require('socket.io');
const server = http.createServer(app);
const FRONTEND = (process.env.FRONTEND_ORIGIN || '')
  .split(',')
  .map((s) => s.trim())
  .filter(Boolean);
const io = new Server(server, {
  cors: { origin: FRONTEND.length > 0 ? FRONTEND : '*', methods: ['GET', 'POST', 'PUT'] }
});

// Socket.IO: salas por chat
io.on('connection', (socket) => {
  // cliente envía userId para unirse a sus chats
  socket.on('join_user', (userId) => {
    socket.join(`user_${userId}`);
    socket.data.userId = userId;
  });
  socket.on('join_room', (roomId) => {
    socket.join(`room_${roomId}`);
  });
  socket.on('leave_room', (roomId) => {
    socket.leave(`room_${roomId}`);
  });
  socket.on('typing', ({ roomId, userId, isTyping }) => {
    socket.to(`room_${roomId}`).emit('typing', { roomId, userId, isTyping });
  });
  socket.on('disconnect', () => {});
});

// Exponer io para que chats.js pueda emitir
app.set('io', io);

if (require.main === module) {
  server.listen(PORT, '0.0.0.0', () => {
    console.log(`Servidor (HTTP+Socket.IO) corriendo en http://localhost:${PORT}`);
  });
}

module.exports = { app, server, io };
