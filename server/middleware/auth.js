const jwt = require('jsonwebtoken');
const crypto = require('crypto');

const SECRET = process.env.JWT_SECRET || 'dev-secret-cambiar-en-produccion';
const ACCESS_EXPIRES_IN = process.env.JWT_EXPIRES_IN || '15m';
const REFRESH_EXPIRES_IN = process.env.JWT_REFRESH_EXPIRES_IN || '30d';

/** Token corto de acceso (type: access). */
function signToken({ id, email, role }) {
  return jwt.sign(
    { sub: String(id), email, role: role || 'player', type: 'access' },
    SECRET,
    { expiresIn: ACCESS_EXPIRES_IN }
  );
}

/**
 * Token largo de refresco (type: refresh). Se guarda hasheado en DB.
 * Incluye `jti` aleatorio para que dos emisiones en el mismo segundo
 * nunca colisionen en la columna UNIQUE(token_hash).
 */
function signRefreshToken({ id }) {
  return jwt.sign(
    { sub: String(id), type: 'refresh', jti: crypto.randomUUID() },
    SECRET,
    { expiresIn: REFRESH_EXPIRES_IN }
  );
}

/** Hash SHA-256 para guardar refresh tokens sin exponerlos. */
function hashToken(token) {
  return crypto.createHash('sha256').update(token).digest('hex');
}

function requireAuth(req, res, next) {
  const h = req.headers.authorization || '';
  const token = h.startsWith('Bearer ') ? h.slice(7) : null;
  if (!token) return res.status(401).json({ message: 'Token requerido.' });
  try {
    const payload = jwt.verify(token, SECRET);
    if (payload.type && payload.type !== 'access') {
      return res.status(401).json({ message: 'Token inválido o expirado.' });
    }
    req.user = payload;
    return next();
  } catch (_) {
    return res.status(401).json({ message: 'Token inválido o expirado.' });
  }
}

/** Verifica un refresh token y devuelve su payload o null. */
function verifyRefreshToken(token) {
  try {
    const payload = jwt.verify(token, SECRET);
    if (payload.type !== 'refresh') return null;
    return payload;
  } catch (_) {
    return null;
  }
}

function requireSuperAdmin(req, res, next) {
  requireAuth(req, res, () => {
    if (req.user && req.user.role === 'superadmin') return next();
    return res.status(403).json({ message: 'Solo superadmin.' });
  });
}

/**
 * Solo el dueño del recurso o un superadmin.
 * Uso: requireOwnerOrAdmin((req) => req.params.uid)
 */
function requireOwnerOrAdmin(getOwnerId) {
  return (req, res, next) => {
    requireAuth(req, res, () => {
      const owner = String(getOwnerId(req));
      const me = String(req.user.sub);
      if (me === owner || req.user.role === 'superadmin') return next();
      return res.status(403).json({ message: 'No tienes permiso.' });
    });
  };
}

module.exports = {
  signToken,
  signRefreshToken,
  hashToken,
  verifyRefreshToken,
  requireAuth,
  requireSuperAdmin,
  requireOwnerOrAdmin,
};
