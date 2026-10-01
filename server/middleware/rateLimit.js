const rateLimit = require('express-rate-limit');

// Anti-fuerza bruta SOLO en login/register: 20 intentos / 15 min por IP.
// /me, /refresh y /logout llevan limiter laxo aparte (no bloquean sesión).
const authLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 20,
  standardHeaders: true,
  legacyHeaders: false,
  skipSuccessfulRequests: true,
  message: { message: 'Demasiados intentos. Espera 15 minutos.' },
});

// Límite laxo para refresh/me/logout: 120 / 15 min por IP.
const sessionLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 120,
  standardHeaders: true,
  legacyHeaders: false,
  message: { message: 'Demasiados intentos. Espera unos minutos.' },
});

// Límite general de API: 600 req / min por IP (protege scraping masivo).
const apiLimiter = rateLimit({
  windowMs: 60 * 1000,
  max: 600,
  standardHeaders: true,
  legacyHeaders: false,
  message: { message: 'Límite de peticiones excedido.' },
});

module.exports = { authLimiter, sessionLimiter, apiLimiter };
