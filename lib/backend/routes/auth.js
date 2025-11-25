const express = require('express');
const pool = require('../db'); 
const bcrypt = require('bcrypt'); // 🔑 Importamos bcrypt
const router = express.Router();

const saltRounds = 10; // Factor de costo para el hasheo

// ===================================
// RUTA: POST /api/v1/auth/register
// ===================================
router.post('/register', async (req, res) => {
    const { email, password, nickname, name } = req.body;
    let connection;

    try {
        // 1. GENERAR HASH: Ciframos la contraseña antes de guardarla
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

        // 4. Respuesta
        res.status(201).json({ 
            id: newAuthId.toString(), 
            name: name || 'Usuario', 
            nickname: nickname,
            rating: 0.0,
            profileImageUrl: 'https://placehold.co/100x100/3A86FF/000?text=New'
        });

    } catch (error) {
        if (connection) await connection.rollback(); 
        console.error("Error en el registro:", error);
        
        if (error.code === 'ER_DUP_ENTRY') {
            return res.status(409).json({ message: 'El email o apodo ya están registrados.' });
        }
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
        // 1. Buscar credenciales en AUTH
        const [authRows] = await pool.execute(
            "SELECT id_auth, password FROM auth WHERE email = ?", 
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
            // 4. Respuesta exitosa
            res.status(200).json(playerRows[0]);
        } else {
            res.status(404).json({ message: "Perfil de usuario no encontrado" });
        }

    } catch (error) {
        console.error("Error en el login:", error);
        res.status(500).json({ message: 'Error interno del servidor.' });
    }
});

module.exports = router;
