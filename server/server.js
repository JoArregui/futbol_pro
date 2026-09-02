require('dotenv').config();
const express = require('express');
const cors = require('cors');
const authRoutes = require('./routes/auth'); 
const fieldRoutes = require('./routes/fields'); 
const leagueRoutes = require('./routes/leagues'); 
const userRoutes = require('./routes/users');
const chatRoutes = require('./routes/chats'); 
const matchRoutes = require('./routes/matches'); 

const app = express();
const PORT = process.env.PORT || 3000;

app.use(cors());
app.use(express.json());

// Health check
app.get('/health', (req, res) => res.json({ status: 'ok', uptime: process.uptime() }));

app.use('/api/v1/auth', authRoutes);
app.use('/api/v1/fields', fieldRoutes); 
app.use('/api/v1/leagues', leagueRoutes); 
app.use('/api/v1/users', userRoutes); 
app.use('/api/v1/chats', chatRoutes); 
app.use('/api/v1/matches', matchRoutes); 

// 404 handler
app.use((req, res) => res.status(404).json({ message: 'Ruta no encontrada' }));

const http = require('http');
const { Server } = require('socket.io');
const server = http.createServer(app);
const io = new Server(server, {
  cors: { origin: '*', methods: ['GET', 'POST', 'PUT'] }
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

server.listen(PORT, '0.0.0.0', () => { 
    console.log(`Servidor (HTTP+Socket.IO) corriendo en http://localhost:${PORT}`);
});