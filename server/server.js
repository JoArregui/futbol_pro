const app = require('./app');

const PORT = process.env.PORT || 3000;

const http = require('http');
const { Server } = require('socket.io');
const server = http.createServer(app);
const FRONTEND = (process.env.FRONTEND_ORIGIN || '')
  .split(',')
  .map((s) => s.trim())
  .filter(Boolean);
const isProd = process.env.NODE_ENV === 'production';
const io = new Server(server, {
  cors: {
    origin: FRONTEND.length > 0
      ? FRONTEND
      : (isProd ? [] : /localhost|127\.0\.0\.1/),
    methods: ['GET', 'POST', 'PUT'],
  },
});

// Socket.IO con auth JWT: solo user_<sub> propio + rooms verificados vía DB.
// SECRET compartido con middleware/auth (una sola fuente).
const jwt = require('jsonwebtoken');
const { SECRET } = require('./middleware/auth');
function cleanToken(raw) {
  let t = String(raw || '').trim();
  if (t.toLowerCase().startsWith('bearer ')) t = t.slice(7).trim();
  return t;
}
io.use((socket, next) => {
  try {
    const token = cleanToken(socket.handshake?.auth?.token);
    if (!token) return next(); // se permite conectar, pero join verificado abajo
    const payload = jwt.verify(token, SECRET);
    if (payload.type && payload.type !== 'access') return next(new Error('bad token'));
    socket.data.authUser = String(payload.sub);
    socket.data.authRole = payload.role;
    return next();
  } catch (_) {
    return next(); // sin auth: joins restringidos
  }
});

// Socket.IO: salas por chat — sin auth no hay joins (anti-suplantación).
io.on('connection', (socket) => {
  socket.on('join_user', (userId) => {
    const uid = String(userId || '');
    if (!uid) return;
    if (!socket.data.authUser) return;
    if (socket.data.authUser !== uid) return;
    socket.join(`user_${uid}`);
    socket.data.userId = uid;
  });
  socket.on('join_room', async (roomId) => {
    const rid = String(roomId || '');
    if (!rid) return;
    if (!socket.data.authUser) return;
    try {
      const pool = require('./db');
      const me = socket.data.authUser;
      if (!me) return;
      if (socket.data.authRole === 'superadmin') {
        socket.join(`room_${rid}`);
        return;
      }
      const [rows] = await pool.execute(
        'SELECT 1 FROM chats_miembros WHERE id_chat_fk = ? AND id_miembro_fk = ? LIMIT 1',
        [rid, me]
      );
      if (rows.length > 0) socket.join(`room_${rid}`);
    } catch (_) {}
  });
  socket.on('leave_room', (roomId) => {
    socket.leave(`room_${String(roomId || '')}`);
  });
  socket.on('join_match', async (matchId) => {
    const mid = String(matchId || '');
    if (!mid || !socket.data.authUser) return;
    try {
      const pool = require('./db');
      if (socket.data.authRole === 'superadmin') {
        socket.join(`match_${mid}`);
        return;
      }
      const [rows] = await pool.execute(
        'SELECT 1 FROM participantes WHERE id_partido_fk = ? AND id_jugador_fk = ? LIMIT 1',
        [mid, socket.data.authUser]
      );
      if (rows.length > 0) socket.join(`match_${mid}`);
    } catch (_) {}
  });
  socket.on('typing', ({ roomId, userId, isTyping }) => {
    // Anti-spoof: solo authed, userId forzado al propio, y solo en salas unidas.
    if (!socket.data.authUser) return;
    const rid = String(roomId || '');
    if (!rid) return;
    if (!socket.rooms.has(`room_${rid}`)) return;
    const uid = String(socket.data.authUser);
    socket.to(`room_${rid}`).emit('typing', { roomId: rid, userId: uid, isTyping: !!isTyping });
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
