const express = require('express');
const pool = require('../db');
const { requireAuth } = require('../middleware/auth');
const router = express.Router();

// Seguridad: nunca anónimo — todo acceso requiere JWT válido.
router.use(requireAuth);

// ===================================
// RUTA 1: GET /api/v1/users/:uid/profile
// ===================================
// Obtener el perfil completo de un usuario por su UID.
router.get('/:uid/profile', async (req, res) => {
    const { uid } = req.params;

    try {
        // La tabla 'perfiles' tiene todos los datos del UserProfile
        const sql = `
            SELECT
                uid, email, apodo, nombre, url_avatar, bio, fecha_creacion,
                posicion, pierna, disponible
            FROM
                perfiles
            WHERE
                uid = ?;
        `;
        
        const [rows] = await pool.execute(sql, [uid]); 

        if (rows.length > 0) {
            // Devolvemos el primer resultado (debería ser único)
            res.status(200).json(rows[0]);
        } else {
            // 404 si el perfil no existe
            res.status(404).json({ message: 'Perfil no encontrado.' });
        }

    } catch (error) {
        console.error("Error al obtener perfil:", error);
        res.status(500).json({ message: 'Error interno del servidor.' });
    }
});


// Columnas editables por el usuario (whitelist: evita inyección por nombre
// de columna y evita tocar uid/email/role desde aquí).
function isValidImageUrl(u) {
  return typeof u === 'string' && u.length <= 2048 && /^https?:\/\//i.test(u);
}
const PROFILE_EDITABLE = new Set([
  'nombre', 'apodo', 'bio', 'url_avatar',
  'posicion', 'pierna', 'disponible',
]);
// Mapeo camelCase Flutter -> snake_case DB (solo claves permitidas).
function mapProfileKey(key) {
  if (key === 'urlAvatar') return 'url_avatar';
  if (key === 'name') return 'nombre';
  if (key === 'nickname') return 'apodo';
  if (key === 'bio') return 'bio';
  if (key === 'position') return 'posicion';
  if (key === 'foot') return 'pierna';
  if (key === 'availability' || key === 'available') return 'disponible';
  if (['nombre', 'apodo', 'url_avatar', 'posicion', 'pierna', 'disponible'].includes(key)) return key;
  return null; // no permitido
}

const POSICIONES = new Set(['Portero', 'Defensa', 'Medio', 'Delantero']);
const PIERNAS = new Set(['diestro', 'zurdo', 'ambidiestro']);

// ===================================
// RUTA 2: PUT /api/v1/users/:uid/profile
// Solo el dueño o superadmin. Columnas con whitelist.
// ===================================
router.put('/:uid/profile', async (req, res) => {
    const { uid } = req.params;
    const me = String(req.user.sub);
    if (me !== String(uid) && req.user.role !== 'superadmin') {
        return res.status(403).json({ message: 'No tienes permiso.' });
    }
    const data = req.body || {};

    // Construir la consulta de actualización dinámicamente (solo whitelist)
    const fields = [];
    const values = [];

    for (const key in data) {
        const dbKey = mapProfileKey(key);
        if (!dbKey || !PROFILE_EDITABLE.has(dbKey)) continue;
        let value = data[key];
        if ((dbKey === 'nombre' || dbKey === 'apodo') && value != null) {
          value = String(value).slice(0, 80);
          if (!value.trim()) return res.status(400).json({ message: `${dbKey} vacío.` });
        }
        if (dbKey === 'bio' && value != null) {
          value = String(value).slice(0, 500);
        }
        if (dbKey === 'url_avatar' && value != null && value !== '') {
          if (!isValidImageUrl(String(value))) {
            return res.status(400).json({ message: 'url_avatar inválida (solo https).' });
          }
        }
        if (dbKey === 'posicion' && value != null && value !== '') {
          if (!POSICIONES.has(String(value))) {
            return res.status(400).json({ message: 'posicion inválida.' });
          }
        }
        if (dbKey === 'pierna' && value != null && value !== '') {
          if (!PIERNAS.has(String(value))) {
            return res.status(400).json({ message: 'pierna inválida.' });
          }
        }
        if (dbKey === 'disponible') {
          value = value === true || value === 1 || value === '1' ? 1 : 0;
        }
        fields.push(`"${dbKey}" = ?`);
        values.push(value);
    }
    
    if (fields.length === 0) {
        return res.status(400).json({ message: 'No se proporcionaron datos para actualizar.' });
    }

    // Agregar el UID al final para la cláusula WHERE
    values.push(uid);

    try {
        const sql = `UPDATE perfiles SET ${fields.join(', ')} WHERE uid = ?`;
        
        const [result] = await pool.execute(sql, values); 

        if (result.affectedRows === 0) {
            return res.status(404).json({ message: 'Perfil no encontrado para actualizar.' });
        }

        res.status(200).json({ message: 'Perfil actualizado exitosamente.' });

    } catch (error) {
        console.error("Error al actualizar perfil:", error);
        res.status(500).json({ message: 'Error interno del servidor.' });
    }
});
// ===================================
// RUTA 3: GET /api/v1/users/search?q=&excludeUid=
// ===================================
function escapeLike(s) {
  return String(s).replace(/[\\%_]/g, (m) => `\\${m}`);
}
async function handleSearch(req, res) {
    const { q = '', excludeUid } = req.query;
    try {
        // No exponer email a no-admins (anti-enumeración).
        const isAdmin = req.user.role === 'superadmin';
        const cols = isAdmin
          ? 'uid as id, nombre, apodo, url_avatar, email'
          : 'uid as id, nombre, apodo, url_avatar';
        let sql = `SELECT ${cols} FROM perfiles WHERE 1=1`;
        const params = [];
        if (q) {
            const like = `%${escapeLike(q).slice(0, 60)}%`;
            sql += ` AND (nombre LIKE ? ESCAPE '\\' OR apodo LIKE ? ESCAPE '\\'${isAdmin ? " OR email LIKE ? ESCAPE '\\'" : ''})`;
            params.push(like, like);
            if (isAdmin) params.push(like);
        }
        if (excludeUid) {
            sql += ` AND uid != ?`;
            params.push(String(excludeUid).slice(0, 32));
        }
        sql += ` LIMIT 20`;
        const [rows] = await pool.execute(sql, params);
        res.status(200).json(rows);
    } catch (e) {
        console.error(e);
        res.status(500).json({ message: 'Error' });
    }
}
router.get('/search/all', handleSearch);

router.get('/search', handleSearch);

module.exports = router;
