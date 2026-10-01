const express = require('express');
const pool = require('../db');
const { requireAuth } = require('../middleware/auth');
const router = express.Router();

// Seguridad: nunca anónimo — todo acceso requiere JWT válido.
router.use(requireAuth);

async function isMember(roomId, userId) {
  try {
    const [rows] = await pool.execute(
      'SELECT 1 FROM chats_miembros WHERE id_chat_fk = ? AND id_miembro_fk = ? LIMIT 1',
      [roomId, userId]
    );
    return rows.length > 0;
  } catch (_) {
    return false;
  }
}
function canAccessUser(paramUserId, req) {
  if (req.user.role === 'superadmin') return true;
  return String(paramUserId) === String(req.user.sub);
}
function safeParseLastMessage(v) {
  if (v == null) return null;
  if (typeof v === 'object') return v;
  try {
    return JSON.parse(v);
  } catch (_) {
    return null;
  }
}
function isValidImageUrl(u) {
  if (typeof u !== 'string' || u.length > 2048) return false;
  return /^https?:\/\//i.test(u);
}

// ===================================
// RUTA 1: GET /api/v1/users/:userId/chats
// ===================================
// Obtiene todas las salas de chat de un usuario.
router.get('/:userId/chats', async (req, res) => {
    const { userId } = req.params;
    if (!canAccessUser(userId, req)) {
      return res.status(403).json({ message: 'No tienes permiso.' });
    }

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

        if (rows.length === 0) {
            // Devolver un array vacío en lugar de 404 si no hay chats.
            return res.status(200).json([]);
        }
        // Batch: miembros de todas las salas en 1 query + unread en 1 query.
        const ids = rows.map((r) => r.id);
        const placeholders = ids.map(() => '?').join(',');
        const [allMembers] = await pool.execute(
          `SELECT id_chat_fk, id_miembro_fk FROM chats_miembros WHERE id_chat_fk IN (${placeholders})`,
          ids
        );
        const byChat = new Map();
        for (const m of allMembers) {
          const k = String(m.id_chat_fk);
          if (!byChat.has(k)) byChat.set(k, []);
          byChat.get(k).push(String(m.id_miembro_fk));
        }
        let unreadByChat = new Map();
        try {
          const [unreads] = await pool.execute(
            `SELECT m.id_chat_fk AS chatId, COUNT(*) AS cnt FROM mensajes m
             JOIN chats_miembros cm ON cm.id_chat_fk = m.id_chat_fk AND cm.id_miembro_fk = ?
             WHERE m.id_chat_fk IN (${placeholders})
               AND m.timestamp > COALESCE(cm.ultimo_leido_timestamp, '1970-01-01T00:00:00.000Z')
               AND m.id_emisor_fk != ?
             GROUP BY m.id_chat_fk`,
            [userId, ...ids, userId]
          );
          for (const u of unreads) unreadByChat.set(String(u.chatId), Number(u.cnt ?? 0));
        } catch (_) {}
        const chatRoomsWithMembers = rows.map((row) => ({
            id: row.id.toString(),
            type: row.type,
            title: row.title,
            memberIds: byChat.get(String(row.id)) || [],
            relatedEntityId: row.relatedEntityId,
            lastMessage: safeParseLastMessage(row.lastMessage),
            lastActive: row.lastActive,
            unreadCount: unreadByChat.get(String(row.id)) || 0,
        }));

        res.status(200).json(chatRoomsWithMembers);

    } catch (error) {
        console.error("Error al obtener salas de chat:", error);
        res.status(500).json({ message: 'Error interno del servidor.' });
    }
});

// NOTA: eliminado alias GET /users/:userId/chats (montaba /chats/users/...,
// inalcanzable; el cliente usa GET /:userId/chats y /users/search).

// ----------------------------------

// ===================================
// RUTA 2: GET /api/v1/chats/:roomId/messages
// ===================================
// Obtiene los mensajes de una sala.
router.get('/:roomId/messages', async (req, res) => {
    const { roomId } = req.params;
    if (req.user.role !== 'superadmin' && !(await isMember(roomId, req.user.sub))) {
      return res.status(403).json({ message: 'No eres miembro de esta sala.' });
    }
    let limit = parseInt(req.query.limit || '50', 10);
    if (!Number.isInteger(limit) || limit < 1) limit = 50;
    limit = Math.min(limit, 100);
    const before = (req.query.before || '').toString().slice(0, 40);

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
                id_chat_fk = ?${before ? ' AND timestamp < ?' : ''}
            ORDER BY
                timestamp DESC
            LIMIT ${limit};
        `;

        const [rows] = await pool.execute(sql, before ? [roomId, before] : [roomId]);

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
    // Anti-spoofing: el emisor siempre es el del JWT.
    const senderId = String(req.user.sub);
    const { text = '', imageUrl = null, clientId = null } = req.body || {};
    let connection;

    if (req.user.role !== 'superadmin' && !(await isMember(roomId, senderId))) {
      return res.status(403).json({ message: 'No eres miembro de esta sala.' });
    }
    // Nombre real desde perfiles (el body se ignora: anti-suplantación 'Admin').
    let cleanSender = '';
    try {
      const [prof] = await pool.execute(
        'SELECT apodo, nombre FROM perfiles WHERE uid = ? LIMIT 1', [senderId]);
      cleanSender = String(prof[0]?.apodo || prof[0]?.nombre || '').slice(0, 80);
    } catch (_) {}
    const cleanText = (text || '').toString().slice(0, 2000);
    if ((!cleanText.trim() && !imageUrl)) {
        return res.status(400).json({ message: 'Falta contenido (text/imageUrl).' });
    }
    if (cleanText.length > 2000) {
        return res.status(400).json({ message: 'Texto demasiado largo (máx 2000).' });
    }
    if (imageUrl != null && !isValidImageUrl(imageUrl)) {
        return res.status(400).json({ message: 'imageUrl inválida (solo https, máx 2048).' });
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
        await connection.execute(insertMsgSql, [messageId, roomId, senderId, cleanSender, cleanText, now, imageUrl]);
        
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
            senderName: cleanSender,
            text: cleanText,
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
                    senderName: cleanSender,
                    text: cleanText,
                    imageUrl,
                    timestamp: now.getTime(),
                    roomId,
                    clientId: (typeof clientId === 'string' ? clientId.slice(0, 64) : null),
                });
                // Notificar lista de chats para actualizar lastMessage
                const [members] = await pool.execute(`SELECT id_miembro_fk FROM chats_miembros WHERE id_chat_fk = ?`, [roomId]);
                for (const m of members) {
                    io.to(`user_${m.id_miembro_fk}`).emit('chat_updated', { roomId, lastMessage: { id: messageId, senderId, senderName: cleanSender, text: cleanText, imageUrl, timestamp: now.getTime() } });
                }
            }
        } catch (_) {}
        res.status(201).json({ message: 'Mensaje enviado exitosamente.', id: messageId, clientId: (typeof clientId === 'string' ? clientId.slice(0, 64) : null) });

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
    if (!canAccessUser(userId, req)) {
      return res.status(403).json({ message: 'No tienes permiso.' });
    }
    try {
        // ISO (con T) igual que mensajes.timestamp vía normalizeParams.
        const sql = `UPDATE chats_miembros SET ultimo_leido_timestamp = ? WHERE id_chat_fk = ? AND id_miembro_fk = ?;`;
        const [result] = await pool.execute(sql, [new Date().toISOString(), roomId, userId]);
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
    const { title, type = 'private', memberIds = [], relatedEntityId } = req.body || {};
    let connection;
    if (!title || !String(title).trim() || !Array.isArray(memberIds) || memberIds.length < 1) {
        return res.status(400).json({ message: 'title y memberIds requeridos' });
    }
    if (!['private', 'group', 'match', 'league'].includes(type)) {
        return res.status(400).json({ message: 'type inválido.' });
    }
    const cleanTitle = String(title).trim().slice(0, 80);
    const cleanMembers = [...new Set(memberIds.map((m) => String(m)))].slice(0, 100);
    // El creador debe estar incluido (evita chats donde el creador no es miembro).
    if (!cleanMembers.includes(String(req.user.sub))) {
        cleanMembers.push(String(req.user.sub));
    }
    // Para privado, verificar si ya existe chat 1-1
    if (type === 'private' && cleanMembers.length === 2) {
        try {
            const [existing] = await pool.execute(`
                SELECT c.id_chat FROM chats c
                JOIN chats_miembros cm1 ON c.id_chat = cm1.id_chat_fk AND cm1.id_miembro_fk = ?
                JOIN chats_miembros cm2 ON c.id_chat = cm2.id_chat_fk AND cm2.id_miembro_fk = ?
                WHERE c.tipo = 'private' AND (SELECT COUNT(*) FROM chats_miembros WHERE id_chat_fk = c.id_chat) = 2
                LIMIT 1
            `, [cleanMembers[0], cleanMembers[1]]);
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
            [cleanTitle, type, relatedEntityId || null, now]
        );
        const chatId = chatResult.insertId;
        for (const uid of cleanMembers) {
            await connection.execute(`INSERT INTO chats_miembros (id_chat_fk, id_miembro_fk, ultimo_leido_timestamp) VALUES (?, ?, ?)`, [chatId, uid, now]);
        }
        await connection.commit();
        // Emitir a cada miembro
        try {
            const io = req.app.get('io');
            if (io) {
                for (const uid of cleanMembers) {
                    io.to(`user_${uid}`).emit('chat_created', { id: chatId.toString(), title: cleanTitle, type, memberIds: cleanMembers });
                }
            }
        } catch (_) {}
        res.status(201).json({ id: chatId.toString(), title: cleanTitle, type, memberIds: cleanMembers });
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
    if (req.user.role !== 'superadmin' && !(await isMember(roomId, req.user.sub))) {
      return res.status(403).json({ message: 'No eres miembro de esta sala.' });
    }
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
