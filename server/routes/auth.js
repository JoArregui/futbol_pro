const express = require('express');
const pool = require('../db');
const bcrypt = require('bcrypt'); // 🔑 Importamos bcrypt
const {
  signToken,
  signRefreshToken,
  hashToken,
  verifyRefreshToken,
  requireAuth,
} = require('../middleware/auth');
const { authLimiter } = require('../middleware/rateLimit');
const router = express.Router();

// Anti-fuerza bruta en todos los endpoints públicos de auth.
router.use(authLimiter);

const saltRounds = 10; // Factor de costo para el hasheo
const REFRESH_DAYS = parseInt(process.env.JWT_REFRESH_DAYS || '30', 10);

/** Emite par access+refresh y persiste el refresh hasheado. */
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
  return { token, refreshToken };
}

// ===================================
// RUTA: POST /api/v1/auth/register
// ===================================
router.post('/register', async (req, res) => {
    const { email, password, nickname, name } = req.body;
    if (!email || !email.includes('@')) return res.status(400).json({ message: 'Email inválido' });
    if (!password || password.length < 6) return res.status(400).json({ message: 'Contraseña debe tener al menos 6 caracteres' });
    if (!nickname || nickname.trim().length < 2) return res.status(400).json({ message: 'Nickname requerido (mín 2 caracteres)' });
    let connection;
    try {
        const hashedPassword = await bcrypt.hash(password, saltRounds);
        
        connection = await pool.getConnection();
        await connection.beginTransaction(); 

        // 2. Insertar en AUTH (guardamos el hash, no la contraseña original)
        const [authResult] = await connection.execute(
            "INSERT INTO auth (email, password) VALUES (?, ?)", 
            [email, hashedPassword] // ¡Usamos hashedPassword!
        );
        const newAuthId = authResult.insertId;

        // 3. Insertar en PERFILES
        const profileSql = `
            INSERT INTO perfiles (uid, email, apodo, nombre, partidos_jugados, victorias, rating, fecha_creacion)
            VALUES (?, ?, ?, ?, 0, 0, 0.00, NOW())
        `;
        await connection.execute(profileSql, [newAuthId, email, nickname, name || '']);
        await connection.commit(); 

        // 4. Respuesta con par JWT (nunca anónima)
        const { token, refreshToken } = await issueTokenPair(
          newAuthId,
          email,
          'player'
        );
        res.status(201).json({
            user: {
                id: newAuthId.toString(),
                name: name || 'Usuario',
                nickname: nickname,
                rating: 0.0,
                role: 'player',
                profileImageUrl: 'https://placehold.co/100x100/3A86FF/000?text=New'
            },
            token,
            refreshToken,
            role: 'player',
        });

    } catch (error) {
        if (connection) await connection.rollback();
        if (error.code === 'ER_DUP_ENTRY' || (error.message && error.message.includes('UNIQUE constraint failed')) || (error.message && error.message.includes('UNIQUE'))) {
            return res.status(409).json({ message: 'El email o apodo ya están registrados.' });
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
    const { email, password } = req.body;

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
        // Rotación: revocar el usado y emitir par nuevo.
        await pool.execute('UPDATE refresh_tokens SET revoked = 1 WHERE id = ?', [row.id]);
        const [authRows] = await pool.execute(
            'SELECT id_auth, email, role FROM auth WHERE id_auth = ?',
            [row.user_id]
        );
        if (authRows.length === 0) {
            return res.status(401).json({ message: 'Usuario no existe.' });
        }
        const { email, role } = authRows[0];
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

module.exports = router;
