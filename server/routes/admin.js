const express = require('express');
const pool = require('../db');
const crypto = require('crypto');
const { requireSuperAdmin } = require('../middleware/auth');
const { logAudit } = require('../services/audit');
const notify = require('../services/notify');

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
function parseLimitOffset(qs, defLimit = 50, maxLimit = 200) {
  let limit = parseInt(qs.limit || String(defLimit), 10);
  let offset = parseInt(qs.offset || '0', 10);
  if (!Number.isInteger(limit) || limit < 1) limit = defLimit;
  if (!Number.isInteger(offset) || offset < 0) offset = 0;
  limit = Math.min(limit, maxLimit);
  return { limit, offset };
}
function escapeLike(s) {
  return String(s).replace(/[\\%_]/g, (m) => `\\${m}`);
}
router.get('/users', async (req, res) => {
  const q = (req.query.q || '').toString().trim().slice(0, 100);
  const { limit, offset } = parseLimitOffset(req.query, 50, 200);
  try {
    let rows;
    if (q) {
      const like = `%${escapeLike(q)}%`;
      [rows] = await pool.execute(
        `SELECT a.id_auth AS id, a.email, a.role, p.apodo AS nickname, p.nombre AS name
         FROM auth a LEFT JOIN perfiles p ON p.uid = a.id_auth
         WHERE a.email LIKE ? ESCAPE '\\' OR p.apodo LIKE ? ESCAPE '\\' OR p.nombre LIKE ? ESCAPE '\\'
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
    await logAudit(req, 'bulk-role', 'users', null, { ids, role });
    res.json({ ok: true, updated: r.affectedRows ?? r.changes ?? ids.length });
  } catch (e) {
    res.status(500).json({ message: 'Error bulk-role.' });
  }
});

// DELETE /api/v1/admin/users/bulk {ids:[]}
async function handleBulkDelete(req, res) {
  const { ids } = req.body || {};
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
    await logAudit(req, 'bulk-delete', 'users', null, { ids: filtered });
    res.json({ ok: true, deleted: r.affectedRows ?? r.changes ?? filtered.length });
  } catch (e) {
    res.status(500).json({ message: 'Error bulk-delete.' });
  }
}
// DELETE clásico + POST alias (proxies/CDN suelen stripear body en DELETE).
router.delete('/users/bulk', handleBulkDelete);
router.post('/users/bulk-delete', handleBulkDelete);

// GET /api/v1/admin/matches?status=PENDIENTE&limit=50
router.get('/matches', async (req, res) => {
  const allowedStatus = new Set(['PENDIENTE', 'ACTIVO', 'CANCELADO', 'FINALIZADO', '']);
  let status = (req.query.status || '').toString().slice(0, 20);
  if (!allowedStatus.has(status)) return res.status(400).json({ message: 'status inválido.' });
  const { limit } = parseLimitOffset(req.query, 50, 200);
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
    await logAudit(req, 'bulk-cancel', 'matches', null, { ids });
    res.json({ ok: true, updated: r.affectedRows ?? r.changes ?? ids.length });
  } catch (e) {
    res.status(500).json({ message: 'Error bulk-cancel.' });
  }
});

// POST /api/v1/admin/announce {text} -> mensaje sistema real en cada chat.
router.post('/announce', async (req, res) => {
  const { text } = req.body || {};
  if (!text || !String(text).trim()) return res.status(400).json({ message: 'text requerido.' });
  const clean = String(text).trim().slice(0, 1000);
  try {
    const [chats] = await pool.execute('SELECT id_chat AS id FROM chats LIMIT 500');
    const crypto = require('crypto');
    const now = new Date();
    let connection;
    try {
      connection = await pool.getConnection();
      await connection.beginTransaction();
      for (const c of chats) {
        const mid = crypto.randomUUID();
        await connection.execute(
          'INSERT INTO mensajes (id_mensaje, id_chat_fk, id_emisor_fk, nombre_emisor, texto, timestamp) VALUES (?, ?, ?, ?, ?, ?)',
          [mid, c.id, req.user.sub, 'Futbol Pro', clean, now]
        );
        await connection.execute(
          'UPDATE chats SET ultimo_mensaje = ?, ultima_actividad = ? WHERE id_chat = ?',
          [JSON.stringify({ text: clean, senderName: 'Futbol Pro', timestamp: now.getTime() }), now, c.id]
        );
      }
      await connection.commit();
    } catch (e) {
      if (connection) await connection.rollback();
      throw e;
    } finally {
      if (connection) connection.release();
    }
    await logAudit(req, 'announce', 'chats', null, { text: clean, chats: chats.length });
    try {
      const io = req.app.get('io');
      if (io) for (const c of chats) io.to(`room_${c.id}`).emit('new_message', { roomId: String(c.id), text: clean, senderName: 'Futbol Pro', timestamp: now.getTime() });
    } catch (_) {}
    res.json({ ok: true, chats: chats.length, text: clean });
  } catch (e) {
    res.status(500).json({ message: 'Error announce.' });
  }
});

// ---------- Gestión completa superadmin ----------

async function ensureAdminTables() {
  try {
    const db = require('../db').getDb ? await require('../db').getDb() : null;
    if (db) {
      await db.exec(`
        CREATE TABLE IF NOT EXISTS arbitros (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          nombre TEXT NOT NULL,
          rating REAL DEFAULT 4.5,
          tarifa REAL DEFAULT 20,
          estado TEXT DEFAULT 'activo'
        );
        CREATE TABLE IF NOT EXISTS torneos (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          nombre TEXT NOT NULL,
          fase TEXT DEFAULT 'Grupos',
          equipos INTEGER DEFAULT 8,
          estado TEXT DEFAULT 'activo'
        );
      `);
      try {
        const cols = await db.all('PRAGMA table_info(campos)');
        if (!cols.some((c) => c.name === 'estado')) {
          await db.exec("ALTER TABLE campos ADD COLUMN estado TEXT DEFAULT 'disponible'");
        }
      } catch (_) {}
      // ELIMINADO: seed hardcoded de árbitros y torneos
      // Ahora se crean manualmente desde el panel admin
    }
  } catch (_) {}
}

// GET /api/v1/admin/teams
router.get('/teams', async (req, res) => {
  await ensureAdminTables();
  try {
    const [rows] = await pool.execute(
      `SELECT id_equipo AS id, nombre, capitan_id AS captain,
              plantilla FROM liga_equipos ORDER BY nombre ASC LIMIT 100`
    );
    res.json(rows.map((r) => {
      let players = 0;
      try { players = JSON.parse(r.plantilla || '[]').length; } catch (_) {}
      return { id: String(r.id), nombre: r.nombre, league: '', players, captain: r.captain == null ? '' : String(r.captain) };
    }));
  } catch (e) {
    res.json([]);
  }
});

// POST /api/v1/admin/teams {nombre, liga}
router.post('/teams', async (req, res) => {
  await ensureAdminTables();
  const nombre = ((req.body || {}).nombre || '').toString().trim();
  if (!nombre) return res.status(400).json({ message: 'nombre requerido.' });
  try {
    const [ligas] = await pool.execute('SELECT id_liga FROM ligas ORDER BY id_liga ASC LIMIT 1');
    const ligaId = ligas.length > 0 ? ligas[0].id_liga : null;
    if (ligaId == null) {
      const [l] = await pool.execute(
        "INSERT INTO ligas (nombre, estado) VALUES ('Liga General', 'open')");
      await pool.execute(
        'INSERT INTO liga_equipos (id_liga_fk, nombre, capitan_id, plantilla) VALUES (?, ?, ?, ?)',
        [l.insertId, nombre, req.user.sub, JSON.stringify([])]);
      return res.status(201).json({ ok: true });
    }
    await pool.execute(
      'INSERT INTO liga_equipos (id_liga_fk, nombre, capitan_id, plantilla) VALUES (?, ?, ?, ?)',
      [ligaId, nombre, req.user.sub, JSON.stringify([])]);
    await logAudit(req, 'create', 'team', null, { nombre });
    res.status(201).json({ ok: true });
  } catch (e) {
    res.status(500).json({ message: 'Error crear equipo.' });
  }
});

// GET /api/v1/admin/players?q=
router.get('/players', async (req, res) => {
  const q = ((req.query.q || '')).toString().trim().slice(0, 60);
  try {
    let rows;
    if (q) {
      const like = `%${escapeLike(q)}%`;
      [rows] = await pool.execute(
        `SELECT uid AS id, nombre AS name, apodo AS nickname FROM perfiles
         WHERE nombre LIKE ? ESCAPE '\\' OR apodo LIKE ? ESCAPE '\\' OR email LIKE ? ESCAPE '\\' LIMIT 100`,
        [like, like, like]);
    } else {
      [rows] = await pool.execute(
        'SELECT uid AS id, nombre AS name, apodo AS nickname FROM perfiles ORDER BY uid DESC LIMIT 100');
    }
    res.json(rows.map((r) => ({
      id: String(r.id), name: r.name || '', nickname: r.nickname || '',
      team: '', goals: 0, rating: 4.5,
    })));
  } catch (e) {
    res.json([]);
  }
});

// POST /api/v1/admin/players — crear jugador manual (sin cuenta auth)
router.post('/players', async (req, res) => {
  const { nombre, apodo, email } = req.body || {};
  const nick = (apodo || '').toString().trim();
  const nom = (nombre || '').toString().trim();
  const em = (email || '').toString().trim().toLowerCase();
  
  if (!nick) return res.status(400).json({ message: 'Apodo (nickname) requerido.' });
  if (nick.length < 2) return res.status(400).json({ message: 'Apodo demasiado corto (mín 2).' });
  
  // Si se proporciona email, verificar que no exista en auth
  if (em && em.includes('@')) {
    const [exAuth] = await pool.execute('SELECT id_auth FROM auth WHERE email = ?', [em]);
    if (exAuth.length > 0) {
      return res.status(409).json({ message: 'Ese email ya tiene cuenta en la app.' });
    }
    const [exPerfil] = await pool.execute('SELECT uid FROM perfiles WHERE email = ?', [em]);
    if (exPerfil.length > 0) {
      return res.status(409).json({ message: 'Ese email ya tiene perfil.' });
    }
  }
  
  try {
    // Crear entrada en perfiles SIN auth (uid = null o 0, pero SQLite no permite FK null en PK)
    // Usamos un uid negativo temporal o creamos un auth "fantasma"
    // Mejor: creamos un auth con password aleatorio (nunca se usará) y rol 'player'
    const bcrypt = require('bcryptjs');
    const fakePass = await bcrypt.hash(crypto.randomBytes(32).toString('hex'), 10);
    const [authResult] = await pool.execute(
      'INSERT INTO auth (email, password, role) VALUES (?, ?, ?)',
      [em || `manual_${nick}_${Date.now()}@futbolpro.local`, fakePass, 'player']
    );
    const uid = authResult.insertId;
    
    await pool.execute(
      `INSERT INTO perfiles (uid, email, apodo, nombre, partidos_jugados, victorias, rating, fecha_creacion)
       VALUES (?, ?, ?, ?, 0, 0, 0, datetime('now'))`,
      [uid, em || `manual_${uid}@futbolpro.local`, nick, nom]
    );
    
    await logAudit(req, 'create-manual-player', 'player', String(uid), { apodo: nick, nombre: nom, email: em });
    
    res.status(201).json({ 
      ok: true, 
      id: String(uid), 
      name: nom, 
      nickname: nick,
      email: em,
      manual: true 
    });
  } catch (e) {
    console.error('Error creando jugador manual:', e);
    res.status(500).json({ message: 'Error creando jugador.' });
  }
});

// GET /api/v1/admin/fields
router.get('/fields', async (req, res) => {
  await ensureAdminTables();
  try {
    const [rows] = await pool.execute(
      'SELECT id_campo AS id, nombre AS name, tarifa_horaria AS price, capacidad AS capacity FROM campos LIMIT 100');
    // Intentar leer estado si la columna existe
    let withEstado = rows;
    try {
      const [rows2] = await pool.execute(
        'SELECT id_campo AS id, nombre AS name, tarifa_horaria AS price, capacidad AS capacity, estado AS status FROM campos LIMIT 100');
      withEstado = rows2;
    } catch (_) {}
    res.json(withEstado.map((r) => ({
      id: String(r.id), nombre: r.name, name: r.name,
      price: Number(r.price ?? 50), tarifa: Number(r.price ?? 50),
      capacity: r.capacity ?? 0, capacidad: r.capacity ?? 0,
      status: r.status || 'disponible', estado: r.status || 'disponible',
    })));
  } catch (e) {
    res.json([]);
  }
});

// PUT /api/v1/admin/fields/:id {estado}
router.put('/fields/:id', async (req, res) => {
  await ensureAdminTables();
  const allowed = new Set(['disponible', 'mantenimiento', 'cerrado']);
  const estado = ((req.body || {}).estado || '').toString();
  if (!allowed.has(estado)) return res.status(400).json({ message: 'estado inválido.' });
  try {
    const [r] = await pool.execute('UPDATE campos SET estado = ? WHERE id_campo = ?', [estado, req.params.id]);
    if ((r.affectedRows ?? r.changes ?? 0) === 0) return res.status(404).json({ message: 'Campo no encontrado.' });
    await logAudit(req, 'update-field', 'field', String(req.params.id), { estado });
    res.json({ ok: true });
  } catch (e) {
    res.status(500).json({ message: 'Error actualizar campo.' });
  }
});

// GET /api/v1/admin/referees
router.get('/referees', async (req, res) => {
  await ensureAdminTables();
  try {
    const [rows] = await pool.execute('SELECT id, nombre AS name, rating, tarifa AS fee, estado AS status FROM arbitros LIMIT 100');
    res.json(rows.map((r) => ({
      id: String(r.id), name: r.name, rating: Number(r.rating ?? 4.5),
      fee: Number(r.fee ?? 20), status: r.status || 'activo',
    })));
  } catch (e) {
    res.json([]);
  }
});

// GET /api/v1/admin/leagues
router.get('/leagues', async (req, res) => {
  try {
    const [rows] = await pool.execute('SELECT id_liga AS id, nombre AS name, estado AS status FROM ligas LIMIT 50');
    const out = [];
    for (const l of rows) {
      try {
        const [[c]] = await pool.execute('SELECT COUNT(*) AS n FROM liga_equipos WHERE id_liga_fk = ?', [l.id]);
        out.push({ id: String(l.id), name: l.name, teams: c.n, status: l.status });
      } catch (_) {
        out.push({ id: String(l.id), name: l.name, teams: 0, status: l.status });
      }
    }
    res.json(out);
  } catch (e) {
    res.json([]);
  }
});

// POST /api/v1/admin/leagues {nombre}
router.post('/leagues', async (req, res) => {
  const nombre = ((req.body || {}).nombre || '').toString().trim();
  if (!nombre) return res.status(400).json({ message: 'nombre requerido.' });
  try {
    await pool.execute(
      "INSERT INTO ligas (nombre, estado) VALUES (?, 'open')", [nombre]);
    res.status(201).json({ ok: true });
  } catch (e) {
    res.status(500).json({ message: 'Error crear liga.' });
  }
});

// GET /api/v1/admin/tournaments
router.get('/tournaments', async (req, res) => {
  await ensureAdminTables();
  try {
    const [rows] = await pool.execute('SELECT id, nombre AS name, fase AS phase, equipos AS teams FROM torneos LIMIT 50');
    res.json(rows.map((r) => ({
      id: String(r.id), name: r.name, phase: r.phase || 'Grupos', teams: r.teams ?? 8,
    })));
  } catch (e) {
    res.json([]);
  }
});

// GET /api/v1/admin/finance
router.get('/finance', async (req, res) => {
  try {
    let total = 0;
    let month = 0;
    let pending = 0;
    try {
      const [[t]] = await pool.execute("SELECT COALESCE(SUM(monto),0) AS s FROM pagos WHERE estado = 'confirmado'");
      total = Number(t.s ?? 0);
    } catch (_) {}
    try {
      const [[m]] = await pool.execute(
        "SELECT COALESCE(SUM(monto),0) AS s FROM pagos WHERE estado = 'confirmado' AND created_at >= date('now','-30 days')");
      month = Number(m.s ?? 0);
    } catch (_) {}
    try {
      const [[p]] = await pool.execute("SELECT COALESCE(SUM(monto),0) AS s FROM pagos WHERE estado = 'pendiente'");
      pending = Number(p.s ?? 0);
    } catch (_) {}
    res.json({ total, month, pending,
      byMonth: [
        { label: 'Total', value: total },
        { label: 'Mes', value: month },
        { label: 'Pend.', value: pending },
      ] });
  } catch (e) {
    res.status(500).json({ message: 'Error finanzas.' });
  }
});

// PUT /api/v1/admin/teams/:id {nombre} — renombrar equipo
router.put('/teams/:id', async (req, res) => {
  const nombre = ((req.body || {}).nombre || '').toString().trim();
  if (!nombre) return res.status(400).json({ message: 'nombre requerido.' });
  try {
    const [r] = await pool.execute(
      'UPDATE liga_equipos SET nombre = ? WHERE id_equipo = ?', [nombre, req.params.id]);
    if ((r.affectedRows ?? r.changes ?? 0) === 0) {
      return res.status(404).json({ message: 'Equipo no encontrado.' });
    }
    await logAudit(req, 'rename', 'team', req.params.id, { nombre });
    res.json({ ok: true });
  } catch (e) {
    if (e.message && e.message.includes('UNIQUE')) {
      return res.status(409).json({ message: 'Ya existe un equipo con ese nombre.' });
    }
    res.status(500).json({ message: 'Error actualizar equipo.' });
  }
});

// DELETE /api/v1/admin/teams/:id — borrar equipo
router.delete('/teams/:id', async (req, res) => {
  try {
    const [r] = await pool.execute(
      'DELETE FROM liga_equipos WHERE id_equipo = ?', [req.params.id]);
    if ((r.affectedRows ?? r.changes ?? 0) === 0) {
      return res.status(404).json({ message: 'Equipo no encontrado.' });
    }
    await logAudit(req, 'delete', 'team', req.params.id, null);
    res.json({ ok: true });
  } catch (e) {
    res.status(500).json({ message: 'Error borrar equipo.' });
  }
});

// GET /api/v1/admin/teams/:id/players — plantilla detallada
router.get('/teams/:id/players', async (req, res) => {
  try {
    const [rows] = await pool.execute(
      'SELECT plantilla FROM liga_equipos WHERE id_equipo = ?', [req.params.id]);
    if (rows.length === 0) return res.status(404).json({ message: 'Equipo no encontrado.' });
    let ids = [];
    try { ids = JSON.parse(rows[0].plantilla || '[]').map(String); } catch (_) {}
    if (ids.length === 0) return res.json([]);
    const ph = ids.map(() => '?').join(',');
    const [perfiles] = await pool.execute(
      `SELECT uid AS id, nombre AS name, apodo AS nickname FROM perfiles WHERE uid IN (${ph})`, ids);
    res.json(perfiles.map((p) => ({
      id: String(p.id), name: p.name || '', nickname: p.nickname || '',
      team: '', goals: 0, rating: 4.5,
    })));
  } catch (e) {
    res.status(500).json({ message: 'Error plantilla.' });
  }
});

// POST /api/v1/admin/teams/:id/players {playerId} — añadir jugador
router.post('/teams/:id/players', async (req, res) => {
  const playerId = ((req.body || {}).playerId || '').toString().trim();
  if (!playerId) return res.status(400).json({ message: 'playerId requerido.' });
  try {
    const [rows] = await pool.execute(
      'SELECT plantilla FROM liga_equipos WHERE id_equipo = ?', [req.params.id]);
    if (rows.length === 0) return res.status(404).json({ message: 'Equipo no encontrado.' });
    const [ex] = await pool.execute('SELECT uid FROM perfiles WHERE uid = ?', [playerId]);
    if (ex.length === 0) return res.status(404).json({ message: 'Jugador no existe.' });
    
    // Verificar si el jugador ya está en OTRO equipo
    const [otherTeams] = await pool.execute(
      `SELECT id_equipo, nombre FROM liga_equipos 
       WHERE plantilla LIKE ? AND id_equipo != ?`,
      [`%${playerId}%`, req.params.id]
    );
    if (otherTeams.length > 0) {
      return res.status(409).json({ 
        message: `El jugador ya está en el equipo "${otherTeams[0].nombre}" (ID: ${otherTeams[0].id_equipo}). Un jugador solo puede estar en un equipo.`,
        equipoExistente: otherTeams[0].nombre
      });
    }
    
    let ids = [];
    try { ids = JSON.parse(rows[0].plantilla || '[]').map(String); } catch (_) {}
    if (!ids.includes(playerId)) {
      ids.push(playerId);
      if (ids.length > 30) return res.status(400).json({ message: 'Plantilla llena (30).' });
      await pool.execute('UPDATE liga_equipos SET plantilla = ? WHERE id_equipo = ?',
        [JSON.stringify(ids), req.params.id]);
    }
    await logAudit(req, 'add-player', 'team', req.params.id, { playerId });
    notify.squadAdded(req, req.params.id, playerId);
    res.status(201).json({ ok: true, total: ids.length });
  } catch (e) {
    res.status(500).json({ message: 'Error añadir jugador.' });
  }
});

// DELETE /api/v1/admin/teams/:id/players/:playerId — quitar jugador
router.delete('/teams/:id/players/:playerId', async (req, res) => {
  try {
    const [rows] = await pool.execute(
      'SELECT plantilla FROM liga_equipos WHERE id_equipo = ?', [req.params.id]);
    if (rows.length === 0) return res.status(404).json({ message: 'Equipo no encontrado.' });
    let ids = [];
    try { ids = JSON.parse(rows[0].plantilla || '[]').map(String); } catch (_) {}
    ids = ids.filter((x) => x !== String(req.params.playerId));
    await pool.execute('UPDATE liga_equipos SET plantilla = ? WHERE id_equipo = ?',
      [JSON.stringify(ids), req.params.id]);
    await logAudit(req, 'remove-player', 'team', req.params.id, { playerId: req.params.playerId });
    res.json({ ok: true, total: ids.length });
  } catch (e) {
    res.status(500).json({ message: 'Error quitar jugador.' });
  }
});

// POST /api/v1/admin/fields {nombre, tarifa, capacidad}
router.post('/fields', async (req, res) => {
  await ensureAdminTables();
  const nombre = ((req.body || {}).nombre || '').toString().trim();
  const tarifa = Number((req.body || {}).tarifa ?? (req.body || {}).price ?? 50);
  const capacidad = parseInt((req.body || {}).capacidad ?? (req.body || {}).capacity ?? 14, 10);
  if (!nombre) return res.status(400).json({ message: 'nombre requerido.' });
  try {
    const [r] = await pool.execute(
      'INSERT INTO campos (nombre, tarifa_horaria, capacidad) VALUES (?, ?, ?)',
      [nombre, Number.isFinite(tarifa) ? tarifa : 50, Number.isFinite(capacidad) ? capacidad : 14]);
    try {
      await pool.execute("UPDATE campos SET estado = 'disponible' WHERE id_campo = ?", [r.insertId]);
    } catch (_) {}
    await logAudit(req, 'create', 'field', r.insertId, { nombre });
    res.status(201).json({ ok: true, id: String(r.insertId) });
  } catch (e) {
    res.status(500).json({ message: 'Error crear campo.' });
  }
});

// DELETE /api/v1/admin/fields/:id — quitar campo
router.delete('/fields/:id', async (req, res) => {
  try {
    const [[c]] = await pool.execute(
      'SELECT COUNT(*) AS n FROM reservas WHERE id_campo_fk = ?', [req.params.id]);
    if (c && Number(c.n) > 0) {
      return res.status(409).json({ message: 'El campo tiene reservas y no se puede borrar. Márcalo en mantenimiento.' });
    }
    const [r] = await pool.execute('DELETE FROM campos WHERE id_campo = ?', [req.params.id]);
    if ((r.affectedRows ?? r.changes ?? 0) === 0) {
      return res.status(404).json({ message: 'Campo no encontrado.' });
    }
    await logAudit(req, 'delete', 'field', req.params.id, null);
    res.json({ ok: true });
  } catch (e) {
    res.status(500).json({ message: 'Error borrar campo.' });
  }
});

// POST /api/v1/admin/referees {nombre, tarifa}
router.post('/referees', async (req, res) => {
  await ensureAdminTables();
  const nombre = ((req.body || {}).nombre || '').toString().trim();
  const tarifa = Number((req.body || {}).tarifa ?? (req.body || {}).fee ?? 20);
  if (!nombre) return res.status(400).json({ message: 'nombre requerido.' });
  try {
    const [r] = await pool.execute(
      "INSERT INTO arbitros (nombre, rating, tarifa, estado) VALUES (?, 4.5, ?, 'activo')",
      [nombre, Number.isFinite(tarifa) ? tarifa : 20]);
    await logAudit(req, 'create', 'referee', r.insertId, { nombre });
    res.status(201).json({ ok: true, id: String(r.insertId) });
  } catch (e) {
    res.status(500).json({ message: 'Error crear árbitro.' });
  }
});

// PUT /api/v1/admin/referees/:id {nombre?, tarifa?, estado?}
router.put('/referees/:id', async (req, res) => {
  await ensureAdminTables();
  const b = req.body || {};
  try {
    const [rows] = await pool.execute('SELECT * FROM arbitros WHERE id = ?', [req.params.id]);
    if (rows.length === 0) return res.status(404).json({ message: 'Árbitro no encontrado.' });
    const cur = rows[0];
    const nombre = (b.nombre ?? cur.nombre).toString();
    const tarifa = Number(b.tarifa ?? b.fee ?? cur.tarifa ?? 20);
    const estado = (b.estado ?? b.status ?? cur.estado ?? 'activo').toString();
    if (!['activo', 'suspendido'].includes(estado)) {
      return res.status(400).json({ message: 'estado inválido (activo|suspendido).' });
    }
    await pool.execute('UPDATE arbitros SET nombre = ?, tarifa = ?, estado = ? WHERE id = ?',
      [nombre, Number.isFinite(tarifa) ? tarifa : 20, estado, req.params.id]);
    await logAudit(req, 'update', 'referee', req.params.id, { nombre, estado });
    res.json({ ok: true });
  } catch (e) {
    res.status(500).json({ message: 'Error actualizar árbitro.' });
  }
});

// DELETE /api/v1/admin/referees/:id — quitar árbitro
router.delete('/referees/:id', async (req, res) => {
  await ensureAdminTables();
  try {
    const [r] = await pool.execute('DELETE FROM arbitros WHERE id = ?', [req.params.id]);
    if ((r.affectedRows ?? r.changes ?? 0) === 0) {
      return res.status(404).json({ message: 'Árbitro no encontrado.' });
    }
    await logAudit(req, 'delete', 'referee', req.params.id, null);
    res.json({ ok: true });
  } catch (e) {
    res.status(500).json({ message: 'Error borrar árbitro.' });
  }
});

// GET /api/v1/admin/audit?limit=50 — últimas acciones superadmin
router.get('/audit', async (req, res) => {
  const { limit } = parseLimitOffset(req.query, 50, 200);
  try {
    const [rows] = await pool.execute(
      `SELECT id, actor_id AS actorId, actor_email AS actorEmail, accion AS action,
              entidad AS entity, entidad_id AS entityId, detalle AS detail,
              created_at AS createdAt
       FROM audit_log ORDER BY id DESC LIMIT ${limit}`
    );
    res.json(rows.map((r) => ({ ...r, id: String(r.id) })));
  } catch (e) {
    res.json([]);
  }
});

// GET /api/v1/admin/finance.csv — export para contabilidad (requiere JWT superadmin)
router.get('/finance.csv', async (req, res) => {
  try {
    const [rows] = await pool.execute(
      `SELECT p.id AS id, p.reserva_id AS reserva, p.monto AS monto,
              p.concepto AS concepto, p.estado AS estado, p.provider AS proveedor,
              p.created_at AS fecha
       FROM pagos p ORDER BY p.id DESC LIMIT 1000`
    );
    const esc = (v) => {
      let s = v == null ? '' : String(v);
      if (/^[=+\-@]/.test(s)) s = `'${s}`;
      return /[",\n;]/.test(s) ? `"${s.replace(/"/g, '""')}"` : s;
    };
    const lines = ['id;reserva;monto;concepto;estado;proveedor;fecha'];
    for (const r of rows) {
      lines.push(
        [r.id, r.reserva, r.monto, r.concepto, r.estado, r.proveedor, r.fecha]
          .map(esc)
          .join(';')
      );
    }
    await logAudit(req, 'export', 'finance', null, { rows: rows.length });
    res.setHeader('Content-Type', 'text/csv; charset=utf-8');
    res.setHeader('Content-Disposition', 'attachment; filename="finanzas.csv"');
    res.send(`\uFEFF${lines.join('\n')}`);
  } catch (e) {
    res.status(500).json({ message: 'Error export.' });
  }
});

// Stats extendidas con teams/leagues/referees/revenue
router.get('/stats-extended', async (req, res) => {
  await ensureAdminTables();
  try {
    const [[u]] = await pool.execute('SELECT COUNT(*) AS c FROM auth');
    const [[m]] = await pool.execute('SELECT COUNT(*) AS c FROM partidos');
    const [[f]] = await pool.execute('SELECT COUNT(*) AS c FROM campos');
    const [[r]] = await pool.execute('SELECT COUNT(*) AS c FROM reservas');
    const [[c]] = await pool.execute('SELECT COUNT(*) AS c FROM chats');
    let teams = 0, leagues = 0, referees = 0, revenue = 0;
    try { const [[t]] = await pool.execute('SELECT COUNT(*) AS c FROM liga_equipos'); teams = t.c; } catch (_) {}
    try { const [[l]] = await pool.execute('SELECT COUNT(*) AS c FROM ligas'); leagues = l.c; } catch (_) {}
    try { const [[a]] = await pool.execute('SELECT COUNT(*) AS c FROM arbitros'); referees = a.c; } catch (_) {}
    try { const [[p]] = await pool.execute("SELECT COALESCE(SUM(monto),0) AS s FROM pagos WHERE estado='confirmado'"); revenue = Number(p.s ?? 0); } catch (_) {}
    res.json({ users: u.c, matches: m.c, fields: f.c, bookings: r.c, chats: c.c, teams, leagues, referees, revenue });
  } catch (e) {
    res.status(500).json({ message: 'Error stats.' });
  }
});

module.exports = router;
