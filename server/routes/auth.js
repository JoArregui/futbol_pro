const express = require('express');
const pool = require('../db');
const bcrypt = require('bcryptjs');
const crypto = require('crypto');
const { Resend } = require('resend');
const {
  signToken,
  signRefreshToken,
  hashToken,
  verifyRefreshToken,
  requireAuth,
} = require('../middleware/auth');
const { authLimiter, sessionLimiter } = require('../middleware/rateLimit');
const router = express.Router();

// Resend client (solo si hay API key configurada)
const resend = process.env.RESEND_API_KEY ? new Resend(process.env.RESEND_API_KEY) : null;

// Email de restablecimiento de contraseña
async function sendPasswordResetEmail(email, resetToken) {
  if (!resend) {
    console.log('⚠️ RESEND_API_KEY no configurado. Token de reset (solo dev):', resetToken);
    return;
  }
  const resetUrl = `${process.env.FRONTEND_URL || 'http://localhost:3000'}/reset-password?token=${resetToken}`;
  const fromEmail = process.env.RESEND_FROM_EMAIL || 'Futbol Pro <noreply@tudominio.com>';

  try {
    await resend.emails.send({
      from: fromEmail,
      to: email,
      subject: 'Restablece tu contraseña - Futbol Pro',
      html: `
        <!DOCTYPE html>
        <html>
        <head>
          <meta charset="utf-8">
          <meta name="viewport" content="width=device-width, initial-scale=1.0">
        </head>
        <body style="font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; line-height: 1.6; color: #1f2937; max-width: 600px; margin: 0 auto; padding: 20px;">
          <div style="background: linear-gradient(135deg, #84cc16 0%, #65a30d 100%); border-radius: 16px 16px 0 0; padding: 32px; text-align: center;">
            <h1 style="margin: 0; color: #000; font-size: 28px; font-weight: 900;">⚽ Futbol Pro</h1>
            <p style="margin: 8px 0 0; color: #166534; font-weight: 600;">Recuperación de contraseña</p>
          </div>
          <div style="background: #fff; border: 1px solid #e5e7eb; border-top: none; border-radius: 0 0 16px 16px; padding: 32px;">
            <p style="font-size: 16px; margin-top: 0;">Hola,</p>
            <p style="font-size: 16px;">Has solicitado restablecer tu contraseña. Pulsa el botón de abajo para crear una nueva:</p>
            <div style="text-align: center; margin: 32px 0;">
              <a href="${resetUrl}" style="display: inline-block; background: #84cc16; color: #000; padding: 16px 32px; border-radius: 12px; text-decoration: none; font-weight: 800; font-size: 16px; box-shadow: 0 4px 14px rgba(132, 204, 22, 0.4);">
                Restablecer contraseña
              </a>
            </div>
            <p style="font-size: 14px; color: #6b7280;">O copia este enlace en tu navegador:</p>
            <p style="font-size: 12px; color: #9ca3af; word-break: break-all; background: #f9fafb; padding: 12px; border-radius: 8px;">${resetUrl}</p>
            <div style="margin-top: 24px; padding: 16px; background: #fef3c7; border-radius: 8px; border-left: 4px solid #f59e0b;">
              <p style="margin: 0; font-size: 13px; color: #92400e;"><strong>⏱ Expira en 1 hora.</strong> Si no fuiste tú, ignora este email y tu contraseña seguirá siendo la misma.</p>
            </div>
          </div>
          <p style="text-align: center; font-size: 12px; color: #9ca3af; margin-top: 24px;">Futbol Pro — Tu club, tus partidos, tu nivel</p>
        </body>
        </html>
      `,
    });
    console.log(`📧 Email de reset enviado a ${email} via Resend`);
  } catch (err) {
    console.error('❌ Error enviando email con Resend:', err.message);
    // Fail-open: no bloquear la request si falla el email
  }
}

// Anti-fuerza bruta SOLO en login/register. me/refresh/logout usan sessionLimiter.
router.post('/login', authLimiter, (req, res, next) => next());
router.post('/register', authLimiter, (req, res, next) => next());
router.use('/refresh', sessionLimiter);
router.use('/me', sessionLimiter);
router.use('/logout', sessionLimiter);

const saltRounds = 10; // Factor de costo para el hasheo
const _parsedDays = parseInt(process.env.JWT_REFRESH_DAYS || '30', 10);
const REFRESH_DAYS = Number.isInteger(_parsedDays) && _parsedDays >= 1 && _parsedDays <= 90
  ? _parsedDays
  : 30;

function validPassword(pw) {
  if (typeof pw !== 'string') return 'Contraseña requerida.';
  if (pw.length < 8) return 'La contraseña debe tener al menos 8 caracteres.';
  if (Buffer.byteLength(pw, 'utf8') > 72) return 'La contraseña es demasiado larga (máx 72 bytes).';
  return null;
}

/** Emite par access+refresh, purga expirados y topa a 10 sesiones por usuario. */
async function issueTokenPair(userId, email, role) {
  const token = signToken({ id: userId, email, role });
  const refreshToken = signRefreshToken({ id: userId });
  const expiresAt = new Date(
    Date.now() + REFRESH_DAYS * 24 * 60 * 60 * 1000
  ).toISOString();
  await pool.execute(
    'INSERT INTO refresh_tokens (user_id, token_hash, expires_at) VALUES (?, ?, ?)',
    [userId, hashToken(refreshToken), expiresAt]
  );
  try {
    await pool.execute(
      "DELETE FROM refresh_tokens WHERE expires_at < datetime('now') OR revoked = 1"
    );
    await pool.execute(
      `DELETE FROM refresh_tokens WHERE user_id = ? AND id NOT IN
       (SELECT id FROM refresh_tokens WHERE user_id = ? ORDER BY id DESC LIMIT 10)`,
      [userId, userId]
    );
  } catch (_) {}
  return { token, refreshToken };
}

// ===================================
// RUTA: POST /api/v1/auth/register
// ===================================
router.post('/register', async (req, res) => {
    let { email, password, nickname, name } = req.body || {};
    email = (email || '').toString().trim().toLowerCase();
    nickname = (nickname || '').toString().trim();
    if (!email || !email.includes('@')) return res.status(400).json({ message: 'Email inválido' });
    const pwErr = validPassword(password);
    if (pwErr) return res.status(400).json({ message: pwErr });
    if (!nickname || nickname.length < 2) return res.status(400).json({ message: 'Nickname requerido (mín 2 caracteres)' });
    let connection;
    try {
        const hashedPassword = await bcrypt.hash(password, saltRounds);
        
        connection = await pool.getConnection();
        await connection.beginTransaction(); 

        // 1. Buscar si ya existe un perfil manual con ese nickname que esté en un equipo
        // (jugador creado por admin sin cuenta, que ahora quiere registrarse)
        // SQLite: plantilla es JSON array tipo '["1","2"]', usamos LIKE para buscar el uid
        const [existingProfiles] = await connection.execute(
            `SELECT p.uid, p.apodo, p.nombre, p.email, p.partidos_jugados, p.victorias, p.rating
             FROM perfiles p
             JOIN liga_equipos le ON le.plantilla LIKE '%' || '"' || CAST(p.uid AS TEXT) || '"' || '%'
             WHERE p.apodo = ? AND (p.email LIKE 'manual_%@futbolpro.local' OR p.email IS NULL OR p.email = '')
             LIMIT 1`,
            [nickname]
        );

        let newAuthId;
        let isExistingPlayer = false;

        if (existingProfiles.length > 0) {
            // Existe un jugador manual con ese nickname en un equipo
            // Vamos a "reclamar" ese perfil: actualizar auth y perfil
            const existingProfile = existingProfiles[0];
            newAuthId = existingProfile.uid;

            // Actualizar auth con el email real y password
            await connection.execute(
                'UPDATE auth SET email = ?, password = ? WHERE id_auth = ?',
                [email, hashedPassword, newAuthId]
            );

            // Actualizar perfil con email real y nombre si se proporciona
            await connection.execute(
                'UPDATE perfiles SET email = ?, nombre = COALESCE(?, nombre) WHERE uid = ?',
                [email, name || null, newAuthId]
            );
            isExistingPlayer = true;
        } else {
            // 2. Insertar en AUTH (nuevo usuario)
            const [authResult] = await connection.execute(
                "INSERT INTO auth (email, password) VALUES (?, ?)", 
                [email, hashedPassword]
            );
            newAuthId = authResult.insertId;

            // 3. Insertar en PERFILES (nuevo perfil)
            const profileSql = `
                INSERT INTO perfiles (uid, email, apodo, nombre, partidos_jugados, victorias, rating, fecha_creacion)
                VALUES (?, ?, ?, ?, 0, 0, 0.00, NOW())
            `;
            await connection.execute(profileSql, [newAuthId, email, nickname, name || '']);
        }

        await connection.commit(); 

        // 4. Respuesta con par JWT
        const { token, refreshToken } = await issueTokenPair(
          newAuthId,
          email,
          'player'
        );
        
        // Obtener datos del perfil para la respuesta
        const [profileRows] = await pool.execute(
            `SELECT uid AS id, nombre AS name, apodo AS nickname, url_avatar AS profileImageUrl, rating
             FROM perfiles WHERE uid = ?`,
            [newAuthId]
        );
        const profile = profileRows[0] || {
            id: newAuthId.toString(),
            name: name || 'Usuario',
            nickname: nickname,
            profileImageUrl: 'https://placehold.co/100x100/3A86FF/000?text=New',
            rating: 0.0
        };

        res.status(201).json({
            user: {
                id: profile.id.toString(),
                name: profile.name,
                nickname: profile.nickname,
                profileImageUrl: profile.profileImageUrl,
                rating: profile.rating,
                role: 'player',
                reclaimed: isExistingPlayer // Indica si recuperó un jugador manual existente
            },
            token,
            refreshToken,
            role: 'player',
        });

    } catch (error) {
        if (connection) await connection.rollback();
        if (error.code === 'ER_DUP_ENTRY' || (error.message && error.message.includes('UNIQUE constraint failed')) || (error.message && error.message.includes('UNIQUE'))) {
            return res.status(409).json({ message: 'El email ya está registrado.' });
        }
        console.error("Error en el registro:", error);
        res.status(500).json({ message: 'Error interno del servidor.' });
    } finally {
        if (connection) connection.release();
    }
});


// ===================================
// RUTA: POST /api/v1/auth/login
// ===================================
router.post('/login', async (req, res) => {
    const rawEmail = (req.body || {}).email;
    const password = (req.body || {}).password;
    const email = (rawEmail || '').toString().trim().toLowerCase();
    if (!email || !email.includes('@') || !password) {
      return res.status(400).json({ message: 'Email y contraseña requeridos.' });
    }

    try {
        // 1. Buscar credenciales en AUTH (incluye rol)
        const [authRows] = await pool.execute(
            "SELECT id_auth, password, role FROM auth WHERE email = ?",
            [email]
        );

        if (authRows.length === 0) {
            return res.status(401).json({ message: "Credenciales inválidas" });
        }

        const userData = authRows[0];
        
        // 2. COMPARAR HASH: Comparamos la contraseña de texto plano (password) con el hash almacenado
        const match = await bcrypt.compare(password, userData.password);

        if (!match) { // Si no coinciden
            return res.status(401).json({ message: "Credenciales inválidas" });
        }

        const userId = userData.id_auth;
        
        // 3. Consultar el perfil del usuario (si el hash es válido)
        const [playerRows] = await pool.execute(
            `
            SELECT uid AS id, nombre AS name, apodo AS nickname, url_avatar AS profileImageUrl, rating
            FROM perfiles 
            WHERE uid = ?
            `, 
            [userId]
        );

        if (playerRows.length > 0) {
            // 4. Respuesta exitosa con par JWT (nunca anónima)
            const role = userData.role || 'player';
            const { token, refreshToken } = await issueTokenPair(
              userId,
              email,
              role
            );
            const profile = playerRows[0];
            res.status(200).json({
                user: {
                    id: profile.id.toString(),
                    name: profile.name,
                    nickname: profile.nickname,
                    profileImageUrl: profile.profileImageUrl,
                    rating: profile.rating,
                    role,
                },
                token,
                refreshToken,
                role,
                // Compat legacy: campos planos
                id: profile.id.toString(),
                name: profile.name,
                nickname: profile.nickname,
                profileImageUrl: profile.profileImageUrl,
                rating: profile.rating,
            });
        } else {
            res.status(404).json({ message: "Perfil de usuario no encontrado" });
        }

    } catch (error) {
        console.error("Error en el login:", error);
        res.status(500).json({ message: 'Error interno del servidor.' });
    }
});

// ===================================
// RUTA: GET /api/v1/auth/me (validar token, sin anonimato)
// ===================================
router.get('/me', requireAuth, async (req, res) => {
    try {
        const [rows] = await pool.execute(
            `SELECT uid AS id, nombre AS name, apodo AS nickname, url_avatar AS profileImageUrl, rating
             FROM perfiles WHERE uid = ?`,
            [req.user.sub]
        );
        if (rows.length === 0) return res.status(404).json({ message: 'Perfil no encontrado' });
        const p = rows[0];
        res.status(200).json({
            id: p.id.toString(),
            name: p.name,
            nickname: p.nickname,
            profileImageUrl: p.profileImageUrl,
            rating: p.rating,
            role: req.user.role,
            email: req.user.email,
        });
    } catch (e) {
        res.status(500).json({ message: 'Error interno.' });
    }
});

// ===================================
// RUTA: POST /api/v1/auth/refresh (rotación de tokens)
// body: { refreshToken }
// ===================================
router.post('/refresh', async (req, res) => {
    const { refreshToken } = req.body || {};
    if (!refreshToken) {
        return res.status(400).json({ message: 'refreshToken requerido.' });
    }
    try {
        const payload = verifyRefreshToken(refreshToken);
        if (!payload) {
            return res.status(401).json({ message: 'Refresh inválido o expirado.' });
        }
        const [rows] = await pool.execute(
            "SELECT id, user_id, expires_at, revoked FROM refresh_tokens WHERE token_hash = ?",
            [hashToken(refreshToken)]
        );
        const row = rows[0];
        if (!row || row.revoked || new Date(row.expires_at).getTime() < Date.now()) {
            return res.status(401).json({ message: 'Refresh inválido o expirado.' });
        }
        // Rotación atómica: el UPDATE condicional solo revoca si sigue vigente.
        // Con el mutex global + BEGIN IMMEDIATE, dos refresh concurrentes con
        // el mismo token no pueden pasar los dos (el segundo ve changes=0).
        const connection = await pool.getConnection();
        let authed = null;
        try {
          await connection.beginTransaction();
          const [r] = await connection.execute(
            'UPDATE refresh_tokens SET revoked = 1 WHERE id = ? AND revoked = 0',
            [row.id]
          );
          if ((r.affectedRows ?? r.changes ?? 0) === 0) {
            await connection.rollback();
            return res.status(401).json({ message: 'Refresh ya usado o revocado.' });
          }
          const [authRows] = await connection.execute(
              'SELECT id_auth, email, role FROM auth WHERE id_auth = ?',
              [row.user_id]
          );
          if (authRows.length === 0) {
              await connection.rollback();
              return res.status(401).json({ message: 'Usuario no existe.' });
          }
          await connection.commit();
          authed = authRows[0];
        } catch (txErr) {
          try { await connection.rollback(); } catch (_) {}
          throw txErr;
        } finally {
          connection.release();
        }
        const { email, role } = authed;
        const pair = await issueTokenPair(row.user_id, email, role || 'player');
        res.status(200).json({ ...pair, role: role || 'player' });
    } catch (e) {
        res.status(500).json({ message: 'Error interno.' });
    }
});

// ===================================
// RUTA: POST /api/v1/auth/logout (revoca refresh)
// body opcional: { refreshToken } — sin él, revoca TODOS del usuario.
// Requiere access token válido.
// ===================================
router.post('/logout', requireAuth, async (req, res) => {
    try {
        const { refreshToken } = req.body || {};
        if (refreshToken) {
            await pool.execute(
                'UPDATE refresh_tokens SET revoked = 1 WHERE token_hash = ? AND user_id = ?',
                [hashToken(refreshToken), req.user.sub]
            );
        } else {
            await pool.execute(
                'UPDATE refresh_tokens SET revoked = 1 WHERE user_id = ?',
                [req.user.sub]
            );
        }
        res.status(200).json({ ok: true });
    } catch (e) {
        res.status(500).json({ message: 'Error interno.' });
    }
});

// ===================================
// RUTA: POST /api/v1/auth/forgot-password
// Solicita restablecimiento de contraseña por email
// ===================================
router.post('/forgot-password', authLimiter, async (req, res) => {
    const email = (req.body?.email || '').toString().trim().toLowerCase();
    if (!email || !email.includes('@')) {
        return res.status(400).json({ message: 'Email inválido.' });
    }

    try {
        // Buscar usuario por email
        const [authRows] = await pool.execute(
            'SELECT id_auth FROM auth WHERE email = ?',
            [email]
        );

        // Por seguridad, siempre respondemos 200 aunque el email no exista
        // (evita enumeración de usuarios)
        if (authRows.length > 0) {
            const userId = authRows[0].id_auth;

            // Generar token de restablecimiento (expira en 1 hora)
            const resetToken = crypto.randomBytes(32).toString('hex');
            const resetTokenHash = crypto.createHash('sha256').update(resetToken).digest('hex');
            const expiresAt = new Date(Date.now() + 60 * 60 * 1000).toISOString();

            // Guardar token hash en BD (crear tabla si no existe)
            await pool.execute(`
                CREATE TABLE IF NOT EXISTS password_resets (
                    id INTEGER PRIMARY KEY AUTOINCREMENT,
                    user_id INTEGER NOT NULL,
                    token_hash TEXT UNIQUE NOT NULL,
                    expires_at TEXT NOT NULL,
                    used INTEGER DEFAULT 0,
                    created_at TEXT DEFAULT (datetime('now')),
                    FOREIGN KEY(user_id) REFERENCES auth(id_auth) ON DELETE CASCADE
                )
            `);

            // Invalidar tokens anteriores del usuario
            await pool.execute(
                'UPDATE password_resets SET used = 1 WHERE user_id = ? AND used = 0',
                [userId]
            );

            // Insertar nuevo token
            await pool.execute(
                'INSERT INTO password_resets (user_id, token_hash, expires_at) VALUES (?, ?, ?)',
                [userId, resetTokenHash, expiresAt]
            );

            // Enviar email con el token de restablecimiento
            await sendPasswordResetEmail(email, resetToken);
        }

        res.status(200).json({ 
            message: 'Si el email existe, recibirás instrucciones para restablecer tu contraseña.' 
        });
    } catch (error) {
        console.error('Error en forgot-password:', error);
        res.status(500).json({ message: 'Error interno del servidor.' });
    }
});

// ===================================
// RUTA: POST /api/v1/auth/reset-password
// Restablece la contraseña usando el token
// ===================================
router.post('/reset-password', authLimiter, async (req, res) => {
    const { token, password } = req.body || {};
    if (!token || !password) {
        return res.status(400).json({ message: 'Token y nueva contraseña requeridos.' });
    }

    const pwErr = validPassword(password);
    if (pwErr) return res.status(400).json({ message: pwErr });

    try {
        const tokenHash = crypto.createHash('sha256').update(token).digest('hex');

        // Buscar token válido
        const [rows] = await pool.execute(
            `SELECT id, user_id, expires_at, used FROM password_resets 
             WHERE token_hash = ?`,
            [tokenHash]
        );

        const resetRow = rows[0];
        if (!resetRow || resetRow.used || new Date(resetRow.expires_at).getTime() < Date.now()) {
            return res.status(400).json({ message: 'Token inválido o expirado.' });
        }

        // Hashear nueva contraseña
        const hashedPassword = await bcrypt.hash(password, 10);

        // Actualizar contraseña en auth
        await pool.execute(
            'UPDATE auth SET password = ? WHERE id_auth = ?',
            [hashedPassword, resetRow.user_id]
        );

        // Marcar token como usado
        await pool.execute(
            'UPDATE password_resets SET used = 1 WHERE id = ?',
            [resetRow.id]
        );

        // Revocar todos los refresh tokens del usuario (forzar re-login)
        await pool.execute(
            'UPDATE refresh_tokens SET revoked = 1 WHERE user_id = ?',
            [resetRow.user_id]
        );

        res.status(200).json({ message: 'Contraseña actualizada correctamente. Ya puedes iniciar sesión.' });
    } catch (error) {
        console.error('Error en reset-password:', error);
        res.status(500).json({ message: 'Error interno del servidor.' });
    }
});

module.exports = router;
