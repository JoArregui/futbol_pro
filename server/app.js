require('dotenv').config();
const express = require('express');
const cors = require('cors');
const morgan = require('morgan');

const authRoutes = require('./routes/auth');
const fieldRoutes = require('./routes/fields');
const leagueRoutes = require('./routes/leagues');
const userRoutes = require('./routes/users');
const chatRoutes = require('./routes/chats');
const matchRoutes = require('./routes/matches');
const refereeRoutes = require('./routes/referees');
const adminRoutes = require('./routes/admin');
const { apiLimiter } = require('./middleware/rateLimit');

const app = express();

// CORS restringido: solo el/los orígenes configurados.
// FRONTEND_ORIGIN="https://app.futbolpro.com,http://localhost:8080"
// Por defecto (dev) se permite localhost en cualquier puerto.
const configured = (process.env.FRONTEND_ORIGIN || '')
  .split(',')
  .map((s) => s.trim())
  .filter(Boolean);
const corsOptions = {
  origin: (origin, cb) => {
    // Peticiones sin Origin (curl, tests, apps móviles) se permiten;
    // el control real lo hace el JWT.
    if (!origin) return cb(null, true);
    if (configured.length === 0) {
      try {
        const u = new URL(origin);
        const host = u.hostname;
        if (host === 'localhost' || host === '127.0.0.1') {
          return cb(null, true);
        }
      } catch (_) {
        // origin inválido -> rechazar
      }
      return cb(new Error('Origen no permitido por CORS.'));
    }
    if (configured.includes(origin)) return cb(null, true);
    return cb(new Error('Origen no permitido por CORS.'));
  },
};

app.use(cors(corsOptions));
app.use(express.json({ limit: '256kb' }));
// Logs HTTP estructurados (método, URL, estado, tiempo).
app.use(morgan(process.env.NODE_ENV === 'production' ? 'combined' : 'dev'));

// Health extendido: verifica que SQLite responde.
app.get('/health', async (req, res) => {
  try {
    const pool = require('./db');
    await pool.execute('SELECT 1 AS ok');
    res.json({ status: 'ok', uptime: process.uptime(), db: 'up' });
  } catch (_) {
    res.status(503).json({ status: 'degraded', db: 'down' });
  }
});

// Límite general anti-scraping en toda la API.
app.use('/api/v1/', apiLimiter);

app.use('/api/v1/auth', authRoutes);
app.use('/api/v1/fields', fieldRoutes);
app.use('/api/v1/leagues', leagueRoutes);
app.use('/api/v1/users', userRoutes);
app.use('/api/v1/chats', chatRoutes);
app.use('/api/v1/matches', matchRoutes);
app.use('/api/v1/referees', refereeRoutes);
app.use('/api/v1/admin', adminRoutes);

// 404 handler
app.use((req, res) => res.status(404).json({ message: 'Ruta no encontrada' }));

// Manejador central de errores (incluye rechazos CORS).
// eslint-disable-next-line no-unused-vars
app.use((err, req, res, next) => {
  if (err && err.message && err.message.includes('CORS')) {
    return res.status(403).json({ message: err.message });
  }
  // eslint-disable-next-line no-console
  console.error('Unhandled error:', err);
  res.status(500).json({ message: 'Error interno del servidor.' });
});

module.exports = app;
