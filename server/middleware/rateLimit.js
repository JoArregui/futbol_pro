const rateLimit = require('express-rate-limit');

// Anti-fuerza bruta en login/register: 20 intentos / 15 min por IP.
const authLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 20,
  standardHeaders: true,
  legacyHeaders: false,
  message: { message: 'Demasiados intentos. Espera 15 minutos.' },
});

// Límite general de API: 600 req / min por IP (protege scraping masivo).
const apiLimiter = rateLimit({
  windowMs: 60 * 1000,
  max: 600,
  standardHeaders: true,
  legacyHeaders: false,
  message: { message: 'Límite de peticiones excedido.' },
});

module.exports = { authLimiter, apiLimiter };
