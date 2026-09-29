const express = require('express');
const pool = require('../db');
const { requireAuth } = require('../middleware/auth');
const router = express.Router();

// Seguridad: nunca anónimo — todo acceso requiere JWT válido.
router.use(requireAuth);

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

        const chatRoomsWithMembers = await Promise.all(rows.map(async (row) => {
            const [memberRows] = await pool.execute('SELECT id_miembro_fk FROM chats_miembros WHERE id_chat_fk = ?', [row.id]);
            const memberIds = memberRows.map(m => m.id_miembro_fk.toString());
            // unread count
            let unreadCount = 0;
            try {
                const [cnt] = await pool.execute(`
                    SELECT COUNT(*) as cnt FROM mensajes
                    WHERE id_chat_fk = ? AND timestamp > (
                        SELECT ultimo_leido_timestamp FROM chats_miembros WHERE id_chat_fk = ? AND id_miembro_fk = ? LIMIT 1
                    ) AND id_emisor_fk != ?
                `, [row.id, row.id, userId, userId]);
                unreadCount = cnt[0]?.cnt ?? 0;
            } catch (_) {}
            return {
                id: row.id.toString(),
                type: row.type,
                title: row.title,
                memberIds,
                relatedEntityId: row.relatedEntityId,
                lastMessage: row.lastMessage ? JSON.parse(row.lastMessage) : null,
                lastActive: row.lastActive,
                unreadCount,
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

// Alias para compatibilidad con cliente antiguo que llama /users/:id/chats
router.get('/users/:userId/chats', async (req, res) => {
    req.params.userId = req.params.userId;
    // Reusar lógica: redirigir internamente
    const { userId } = req.params;
    try {
        const sql = `SELECT c.id_chat AS id, c.nombre AS title, c.tipo AS type, c.related_entity_id AS relatedEntityId, c.ultimo_mensaje AS lastMessage, c.ultima_actividad AS lastActive FROM chats c INNER JOIN chats_miembros cm ON c.id_chat = cm.id_chat_fk WHERE cm.id_miembro_fk = ? ORDER BY c.ultima_actividad DESC;`;
        const [rows] = await pool.execute(sql, [userId]);
        const chatRoomsWithMembers = await Promise.all(rows.map(async (row) => {
            const [memberRows] = await pool.execute('SELECT id_miembro_fk FROM chats_miembros WHERE id_chat_fk = ?', [row.id]);
            const memberIds = memberRows.map(m => m.id_miembro_fk.toString());
            let unreadCount = 0;
            try {
                const [cnt] = await pool.execute(`SELECT COUNT(*) as cnt FROM mensajes WHERE id_chat_fk = ? AND timestamp > (SELECT ultimo_leido_timestamp FROM chats_miembros WHERE id_chat_fk = ? AND id_miembro_fk = ? LIMIT 1) AND id_emisor_fk != ?`, [row.id, row.id, userId, userId]);
                unreadCount = cnt[0]?.cnt ?? 0;
            } catch (_) {}
            return { id: row.id.toString(), type: row.type, title: row.title, memberIds, relatedEntityId: row.relatedEntityId, lastMessage: row.lastMessage ? JSON.parse(row.lastMessage) : null, lastActive: row.lastActive, unreadCount };
        }));
        res.status(200).json(chatRoomsWithMembers);
    } catch (error) {
        console.error(error);
        res.status(500).json({ message: 'Error' });
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
                image_url AS imageUrl,
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
    const { senderId, senderName, text = '', imageUrl = null } = req.body;
    let connection;

    // Validación básica (texto y/o imagen)
    if (!senderId || (!text && !imageUrl)) {
        return res.status(400).json({ message: 'Faltan senderId o contenido (text/imageUrl).' });
    }
    if (imageUrl && (typeof imageUrl !== 'string' || imageUrl.length > 2048)) {
        return res.status(400).json({ message: 'imageUrl inválida.' });
    }

    try {
        connection = await pool.getConnection();
        await connection.beginTransaction();

        const now = new Date();
        // Generamos un ID de forma manual para incluirlo en el lastMessage
        const messageId = require('crypto').randomUUID();

        // 1. Insertar el mensaje
        const insertMsgSql = `
            INSERT INTO mensajes (id_mensaje, id_chat_fk, id_emisor_fk, nombre_emisor, texto, timestamp, image_url)
            VALUES (?, ?, ?, ?, ?, ?, ?);
        `;
        await connection.execute(insertMsgSql, [messageId, roomId, senderId, senderName, text, now, imageUrl]);
        
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
            imageUrl,
            // Usamos getTime() para que Dart lo reconozca como int
            timestamp: now.getTime(),
        });
        await connection.execute(updateChatSql, [lastMessageData, now, roomId]);

        await connection.commit();
        // Emitir por Socket.IO a la sala
        try {
            const io = req.app.get('io');
            if (io) {
                io.to(`room_${roomId}`).emit('new_message', {
                    id: messageId,
                    senderId,
                    senderName,
                    text,
                    imageUrl,
                    timestamp: now.getTime(),
                    roomId,
                });
                // Notificar lista de chats para actualizar lastMessage
                const [members] = await pool.execute(`SELECT id_miembro_fk FROM chats_miembros WHERE id_chat_fk = ?`, [roomId]);
                for (const m of members) {
                    io.to(`user_${m.id_miembro_fk}`).emit('chat_updated', { roomId, lastMessage: { id: messageId, senderId, senderName, text, imageUrl, timestamp: now.getTime() } });
                }
            }
        } catch (_) {}
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
router.put('/:roomId/read/:userId', async (req, res) => {
    const { roomId, userId } = req.params;
    try {
        const sql = `UPDATE chats_miembros SET ultimo_leido_timestamp = NOW() WHERE id_chat_fk = ? AND id_miembro_fk = ?;`;
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

// ===================================
// RUTA 5: POST /api/v1/chats  (crear chat privado o grupal)
// body: { title, type: 'private'|'group'|'match', memberIds: [uid,...], relatedEntityId? }
// ===================================
router.post('/', async (req, res) => {
    const { title, type = 'private', memberIds = [], relatedEntityId } = req.body;
    let connection;
    if (!title || !Array.isArray(memberIds) || memberIds.length < 1) {
        return res.status(400).json({ message: 'title y memberIds requeridos' });
    }
    // Para privado, verificar si ya existe chat 1-1
    if (type === 'private' && memberIds.length === 2) {
        try {
            const [existing] = await pool.execute(`
                SELECT c.id_chat FROM chats c
                JOIN chats_miembros cm1 ON c.id_chat = cm1.id_chat_fk AND cm1.id_miembro_fk = ?
                JOIN chats_miembros cm2 ON c.id_chat = cm2.id_chat_fk AND cm2.id_miembro_fk = ?
                WHERE c.tipo = 'private' AND (SELECT COUNT(*) FROM chats_miembros WHERE id_chat_fk = c.id_chat) = 2
                LIMIT 1
            `, [memberIds[0], memberIds[1]]);
            if (existing.length > 0) {
                return res.status(200).json({ id: existing[0].id_chat.toString(), existed: true });
            }
        } catch (e) { /* ignore */ }
    }
    try {
        connection = await pool.getConnection();
        await connection.beginTransaction();
        const now = new Date();
        const [chatResult] = await connection.execute(
            `INSERT INTO chats (nombre, tipo, related_entity_id, ultimo_mensaje, ultima_actividad) VALUES (?, ?, ?, NULL, ?)`,
            [title, type, relatedEntityId || null, now]
        );
        const chatId = chatResult.insertId;
        for (const uid of memberIds) {
            await connection.execute(`INSERT INTO chats_miembros (id_chat_fk, id_miembro_fk, ultimo_leido_timestamp) VALUES (?, ?, ?)`, [chatId, uid, now]);
        }
        await connection.commit();
        // Emitir a cada miembro
        try {
            const io = req.app.get('io');
            if (io) {
                for (const uid of memberIds) {
                    io.to(`user_${uid}`).emit('chat_created', { id: chatId.toString(), title, type, memberIds });
                }
            }
        } catch (_) {}
        res.status(201).json({ id: chatId.toString(), title, type, memberIds });
    } catch (error) {
        if (connection) await connection.rollback();
        console.error('Error al crear chat:', error);
        res.status(500).json({ message: 'Error interno' });
    } finally { if (connection) connection.release(); }
});

// ===================================
// RUTA 6: GET /api/v1/chats/:roomId/members  (listar miembros con perfil)
// ===================================
router.get('/:roomId/members', async (req, res) => {
    const { roomId } = req.params;
    try {
        const [rows] = await pool.execute(`
            SELECT p.uid as id, p.nombre, p.apodo, p.url_avatar
            FROM chats_miembros cm JOIN perfiles p ON p.uid = cm.id_miembro_fk
            WHERE cm.id_chat_fk = ?
        `, [roomId]);
        res.status(200).json(rows);
    } catch (e) {
        console.error(e);
        res.status(500).json({ message: 'Error' });
    }
});

module.exports = router;