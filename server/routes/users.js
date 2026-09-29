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
                uid, email, apodo, nombre, url_avatar, bio, fecha_creacion
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
const PROFILE_EDITABLE = new Set([
  'nombre', 'apodo', 'bio', 'url_avatar', 'nombre_db', 'apodo_db',
]);
// Mapeo camelCase Flutter -> snake_case DB (solo claves permitidas).
function mapProfileKey(key) {
  if (key === 'urlAvatar') return 'url_avatar';
  if (key === 'name') return 'nombre';
  if (key === 'nickname') return 'apodo';
  if (key === 'bio') return 'bio';
  if (['nombre', 'apodo', 'url_avatar'].includes(key)) return key;
  return null; // no permitido
}

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
        fields.push(`"${dbKey}" = ?`);
        values.push(data[key]);
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
router.get('/search/all', async (req, res) => {
    const { q = '', excludeUid } = req.query;
    try {
        let sql = `SELECT uid as id, nombre, apodo, url_avatar, email FROM perfiles WHERE 1=1`;
        const params = [];
        if (q) {
            sql += ` AND (nombre LIKE ? OR apodo LIKE ? OR email LIKE ?)`;
            const like = `%${q}%`;
            params.push(like, like, like);
        }
        if (excludeUid) {
            sql += ` AND uid != ?`;
            params.push(excludeUid);
        }
        sql += ` LIMIT 20`;
        const [rows] = await pool.execute(sql, params);
        res.status(200).json(rows);
    } catch (e) {
        console.error(e);
        res.status(500).json({ message: 'Error' });
    }
});

router.get('/search', async (req, res) => {
    const { q = '', excludeUid } = req.query;
    try {
        let sql = `SELECT uid as id, nombre, apodo, url_avatar, email FROM perfiles WHERE 1=1`;
        const params = [];
        if (q) {
            sql += ` AND (nombre LIKE ? OR apodo LIKE ? OR email LIKE ?)`;
            const like = `%${q}%`;
            params.push(like, like, like);
        }
        if (excludeUid) {
            sql += ` AND uid != ?`;
            params.push(excludeUid);
        }
        sql += ` LIMIT 20`;
        const [rows] = await pool.execute(sql, params);
        res.status(200).json(rows);
    } catch (e) {
        console.error(e);
        res.status(500).json({ message: 'Error' });
    }
});

module.exports = router;
