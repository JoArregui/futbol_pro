const express = require('express');
const pool = require('../db'); 
const router = express.Router();

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


// ===================================
// RUTA 2: PUT /api/v1/users/:uid/profile
// ===================================
// Actualizar campos específicos del perfil.
router.put('/:uid/profile', async (req, res) => {
    const { uid } = req.params;
    const data = req.body;
    
    // Construir la consulta de actualización dinámicamente
    const fields = [];
    const values = [];

    // Iterar sobre los datos recibidos (e.g., nombre, apodo, bio, url_avatar)
    for (const key in data) {
        // Mapea las claves de Flutter (camelCase) a las de MySQL (snake_case) si es necesario
        let dbKey = key; 
        if (key === 'urlAvatar') dbKey = 'url_avatar';
        if (key === 'fechaCreacion') dbKey = 'fecha_creacion'; 

        fields.push(`${dbKey} = ?`);
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
// La ruta POST createProfileInitial no es estrictamente necesaria aquí, ya que 
// el AuthRemoteDataSource.register() ya inserta el perfil.

module.exports = router;