const express = require('express');
const pool = require('../db');
const router = express.Router();

// ===================================
// RUTA 1: GET /api/v1/users/:userId/chats
// ===================================
// Obtiene todas las salas de chat de un usuario.
router.get('/:userId/chats', async (req, res) => {
    const { userId } = req.params;

    try {
        // Consulta para obtener todas las salas donde el usuario es miembro.
        const sql = `
            SELECT
                c.id_chat AS id,
                c.nombre AS title,
                c.tipo AS type,
                c.related_entity_id AS relatedEntityId,
                c.ultimo_mensaje AS lastMessage,
                c.ultima_actividad AS lastActive
            FROM
                chats c
            INNER JOIN
                chats_miembros cm ON c.id_chat = cm.id_chat_fk
            WHERE
                cm.id_miembro_fk = ?
            ORDER BY
                c.ultima_actividad DESC;
        `;
        
        const [rows] = await pool.execute(sql, [userId]);

        // Función para obtener todos los memberIds para cada chat
        const chatRoomsWithMembers = await Promise.all(rows.map(async (row) => {
            const [memberRows] = await pool.execute(
                'SELECT id_miembro_fk FROM chats_miembros WHERE id_chat_fk = ?',
                [row.id]
            );
            const memberIds = memberRows.map(m => m.id_miembro_fk.toString());

            return {
                id: row.id.toString(),
                type: row.type, // 'general', 'match', etc.
                title: row.title,
                memberIds: memberIds,
                relatedEntityId: row.relatedEntityId,
                lastMessage: row.lastMessage ? JSON.parse(row.lastMessage) : null,
            };
        }));

        if (chatRoomsWithMembers.length > 0) {
            res.status(200).json(chatRoomsWithMembers);
        } else {
            // Devolver un array vacío en lugar de 404 si no hay chats.
            res.status(200).json([]);
        }

    } catch (error) {
        console.error("Error al obtener salas de chat:", error);
        res.status(500).json({ message: 'Error interno del servidor.' });
    }
});

// ----------------------------------

// ===================================
// RUTA 2: GET /api/v1/chats/:roomId/messages
// ===================================
// Obtiene los mensajes de una sala.
router.get('/:roomId/messages', async (req, res) => {
    const { roomId } = req.params;

    try {
        const sql = `
            SELECT
                id_mensaje AS id,
                id_emisor_fk AS senderId,
                nombre_emisor AS senderName,
                texto AS text,
                timestamp
            FROM
                mensajes
            WHERE
                id_chat_fk = ?
            ORDER BY
                timestamp DESC
            LIMIT 50;
        `;
        
        const [rows] = await pool.execute(sql, [roomId]);

        res.status(200).json(rows);

    } catch (error) {
        console.error("Error al obtener mensajes:", error);
        res.status(500).json({ message: 'Error interno del servidor.' });
    }
});

// ----------------------------------

// ===================================
// RUTA 3: POST /api/v1/chats/:roomId/messages
// ===================================
// Envía un nuevo mensaje, inserta en 'mensajes' y actualiza 'chats'.
router.post('/:roomId/messages', async (req, res) => {
    const { roomId } = req.params;
    const { senderId, senderName, text } = req.body;
    let connection;

    // Validación básica
    if (!senderId || !text) {
        return res.status(400).json({ message: 'Faltan senderId o text.' });
    }

    try {
        connection = await pool.getConnection();
        await connection.beginTransaction();

        const now = new Date();
        // Generamos un ID de forma manual para incluirlo en el lastMessage
        const messageId = require('crypto').randomUUID();

        // 1. Insertar el mensaje
        const insertMsgSql = `
            INSERT INTO mensajes (id_mensaje, id_chat_fk, id_emisor_fk, nombre_emisor, texto, timestamp)
            VALUES (?, ?, ?, ?, ?, ?);
        `;
        await connection.execute(insertMsgSql, [messageId, roomId, senderId, senderName, text, now]);
        
        // 2. Actualizar la sala de chat (último mensaje y actividad)
        const updateChatSql = `
            UPDATE chats
            SET
                ultimo_mensaje = ?,
                ultima_actividad = ?
            WHERE
                id_chat = ?;
        `;
        const lastMessageData = JSON.stringify({
            id: messageId, // Incluimos el ID generado
            senderId,
            senderName,
            text,
            // Usamos getTime() para que Dart lo reconozca como int
            timestamp: now.getTime(),
        });
        await connection.execute(updateChatSql, [lastMessageData, now, roomId]);
        
        await connection.commit();

        res.status(201).json({ message: 'Mensaje enviado exitosamente.', id: messageId });

    } catch (error) {
        if (connection) await connection.rollback();
        console.error("Error al enviar mensaje:", error);
        res.status(500).json({ message: 'Error interno del servidor.' });
    } finally {
        if (connection) connection.release();
    }
});

// ----------------------------------

// ===================================
// RUTA 4: PUT /api/v1/chats/:roomId/read/:userId
// ===================================
// Marca los mensajes como leídos para un usuario actualizando el timestamp del último leído.
router.put('/:roomId/read/:userId', async (req, res) => {
    const { roomId, userId } = req.params;

    try {
        const sql = `
            UPDATE
                chats_miembros
            SET
                ultimo_leido_timestamp = NOW()
            WHERE
                id_chat_fk = ? AND id_miembro_fk = ?;
        `;
        
        const [result] = await pool.execute(sql, [roomId, userId]);

        if (result.affectedRows === 0) {
            return res.status(404).json({ message: 'Miembro o sala de chat no encontrado.' });
        }

        res.status(200).json({ message: 'Mensajes marcados como leídos.' });

    } catch (error) {
        console.error("Error al marcar como leído:", error);
        res.status(500).json({ message: 'Error interno del servidor.' });
    }
});

module.exports = router;