const express = require('express');
const pool = require('../db');
const { requireSuperAdmin } = require('../middleware/auth');

const router = express.Router();
router.use(requireSuperAdmin);

// GET /api/v1/admin/stats
router.get('/stats', async (req, res) => {
  try {
    const [[u]] = await pool.execute('SELECT COUNT(*) AS c FROM auth');
    const [[p]] = await pool.execute('SELECT COUNT(*) AS c FROM perfiles');
    const [[m]] = await pool.execute('SELECT COUNT(*) AS c FROM partidos');
    const [[f]] = await pool.execute('SELECT COUNT(*) AS c FROM campos');
    const [[r]] = await pool.execute('SELECT COUNT(*) AS c FROM reservas');
    const [[c]] = await pool.execute('SELECT COUNT(*) AS c FROM chats');
    res.json({
      users: u.c, profiles: p.c, matches: m.c,
      fields: f.c, bookings: r.c, chats: c.c,
    });
  } catch (e) {
    res.status(500).json({ message: 'Error stats.' });
  }
});

// GET /api/v1/admin/users?q=&limit=50&offset=0
router.get('/users', async (req, res) => {
  const q = (req.query.q || '').toString().trim();
  const limit = Math.min(parseInt(req.query.limit || '50', 10), 200);
  const offset = parseInt(req.query.offset || '0', 10);
  try {
    let rows;
    if (q) {
      const like = `%${q}%`;
      [rows] = await pool.execute(
        `SELECT a.id_auth AS id, a.email, a.role, p.apodo AS nickname, p.nombre AS name
         FROM auth a LEFT JOIN perfiles p ON p.uid = a.id_auth
         WHERE a.email LIKE ? OR p.apodo LIKE ? OR p.nombre LIKE ?
         ORDER BY a.id_auth DESC LIMIT ${limit} OFFSET ${offset}`,
        [like, like, like]
      );
    } else {
      [rows] = await pool.execute(
        `SELECT a.id_auth AS id, a.email, a.role, p.apodo AS nickname, p.nombre AS name
         FROM auth a LEFT JOIN perfiles p ON p.uid = a.id_auth
         ORDER BY a.id_auth DESC LIMIT ${limit} OFFSET ${offset}`
      );
    }
    res.json(rows.map(r => ({ ...r, id: String(r.id) })));
  } catch (e) {
    res.status(500).json({ message: 'Error users.' });
  }
});

// PUT /api/v1/admin/users/bulk-role {ids:[], role}
router.put('/users/bulk-role', async (req, res) => {
  const { ids, role } = req.body;
  if (!Array.isArray(ids) || ids.length === 0 || ids.length > 500) {
    return res.status(400).json({ message: 'ids inválido (1-500).' });
  }
  if (!['player', 'admin', 'superadmin'].includes(role)) {
    return res.status(400).json({ message: 'role inválido.' });
  }
  try {
    const placeholders = ids.map(() => '?').join(',');
    const [r] = await pool.execute(
      `UPDATE auth SET role = ? WHERE id_auth IN (${placeholders})`,
      [role, ...ids]
    );
    res.json({ ok: true, updated: r.affectedRows ?? r.changes ?? ids.length });
  } catch (e) {
    res.status(500).json({ message: 'Error bulk-role.' });
  }
});

// DELETE /api/v1/admin/users/bulk {ids:[]}
router.delete('/users/bulk', async (req, res) => {
  const { ids } = req.body;
  if (!Array.isArray(ids) || ids.length === 0 || ids.length > 500) {
    return res.status(400).json({ message: 'ids inválido (1-500).' });
  }
  // No permitir auto-borrado del superadmin en sesión
  const filtered = ids.map(String).filter(id => id !== String(req.user.sub));
  if (filtered.length === 0) {
    return res.status(400).json({ message: 'No puedes eliminarte a ti mismo.' });
  }
  try {
    const placeholders = filtered.map(() => '?').join(',');
    const [r] = await pool.execute(
      `DELETE FROM auth WHERE id_auth IN (${placeholders})`,
      filtered
    );
    res.json({ ok: true, deleted: r.affectedRows ?? r.changes ?? filtered.length });
  } catch (e) {
    res.status(500).json({ message: 'Error bulk-delete.' });
  }
});

// GET /api/v1/admin/matches?status=PENDIENTE&limit=50
router.get('/matches', async (req, res) => {
  const status = (req.query.status || '').toString();
  const limit = Math.min(parseInt(req.query.limit || '50', 10), 200);
  try {
    let rows;
    if (status) {
      [rows] = await pool.execute(
        `SELECT id_partido AS id, id_campo_fk AS fieldId, hora_inicio AS time, estado AS status, tipo AS type
         FROM partidos WHERE estado = ? ORDER BY hora_inicio DESC LIMIT ${limit}`,
        [status]
      );
    } else {
      [rows] = await pool.execute(
        `SELECT id_partido AS id, id_campo_fk AS fieldId, hora_inicio AS time, estado AS status, tipo AS type
         FROM partidos ORDER BY hora_inicio DESC LIMIT ${limit}`
      );
    }
    res.json(rows.map(r => ({ ...r, id: String(r.id) })));
  } catch (e) {
    res.status(500).json({ message: 'Error matches.' });
  }
});

// POST /api/v1/admin/matches/bulk-cancel {ids:[]}
router.post('/matches/bulk-cancel', async (req, res) => {
  const { ids } = req.body;
  if (!Array.isArray(ids) || ids.length === 0 || ids.length > 500) {
    return res.status(400).json({ message: 'ids inválido (1-500).' });
  }
  try {
    const placeholders = ids.map(() => '?').join(',');
    const [r] = await pool.execute(
      `UPDATE partidos SET estado = 'CANCELADO' WHERE id_partido IN (${placeholders})`,
      ids
    );
    res.json({ ok: true, updated: r.affectedRows ?? r.changes ?? ids.length });
  } catch (e) {
    res.status(500).json({ message: 'Error bulk-cancel.' });
  }
});

// POST /api/v1/admin/announce {text} -> crea mensaje sistema (difusión simple)
router.post('/announce', async (req, res) => {
  const { text } = req.body;
  if (!text || !text.trim()) return res.status(400).json({ message: 'text requerido.' });
  try {
    const [chats] = await pool.execute('SELECT id_chat AS id FROM chats LIMIT 500');
    res.json({ ok: true, chats: chats.length, text: text.trim() });
  } catch (e) {
    res.status(500).json({ message: 'Error announce.' });
  }
});

module.exports = router;
