const express = require('express');
const pool = require('../db');
const { requireAuth, requireSuperAdmin } = require('../middleware/auth');
const router = express.Router();

// Seguridad: nunca anónimo — todo acceso requiere JWT válido.
router.use(requireAuth);

function leagueRow(r, registeredTeams) {
  return {
    id: String(r.id_liga),
    name: r.nombre,
    description: r.descripcion || '',
    startDate:
      r.fecha_inicio instanceof Date
        ? r.fecha_inicio.toISOString()
        : r.fecha_inicio,
    maxTeams: r.max_equipos ?? 12,
    registeredTeams: registeredTeams ?? 0,
    status: r.estado === 'open' ? 'open' : 'closed',
    rawStatus: r.estado,
  };
}

// ===================================
// POST /api/v1/leagues (crear liga, solo superadmin)
// ===================================
router.post('/', requireSuperAdmin, async (req, res) => {
    const { nombre, name, descripcion, description, fecha_inicio, startDate, max_equipos, maxTeams } =
      req.body || {};
    const finalName = (nombre || name || '').toString().trim();
    if (!finalName) return res.status(400).json({ message: 'nombre requerido.' });
    const max = Math.min(Math.max(parseInt(max_equipos ?? maxTeams ?? 12, 10) || 12, 2), 64);
    try {
      const [r] = await pool.execute(
        `INSERT INTO ligas (nombre, descripcion, fecha_inicio, max_equipos, estado, created_by)
         VALUES (?, ?, ?, ?, 'open', ?)`,
        [
          finalName,
          (descripcion ?? description ?? '').toString(),
          (fecha_inicio ?? startDate ?? new Date().toISOString()).toString(),
          max,
          req.user.sub,
        ]
      );
      res.status(201).json({ id: String(r.insertId), name: finalName });
    } catch (e) {
      res.status(500).json({ message: 'Error interno.' });
    }
  });

// ===================================
// GET /api/v1/leagues (lista real)
// ===================================
router.get('/', async (req, res) => {
  try {
    const [ligas] = await pool.execute(
      `SELECT * FROM ligas WHERE estado != 'finalizada' ORDER BY fecha_inicio ASC LIMIT 50`
    );
    const out = [];
    for (const l of ligas) {
      const [[c]] = await pool.execute(
        'SELECT COUNT(*) AS n FROM liga_equipos WHERE id_liga_fk = ?',
        [l.id_liga]
      );
      out.push(leagueRow(l, c.n));
    }
    // Sin ligas reales: lista vacía (ya no hay mocks).
    res.status(200).json(out);
  } catch (error) {
    console.error('Error al listar ligas:', error);
    res.status(500).json({ message: 'Error interno.' });
  }
});

// ===================================
// POST /api/v1/leagues/:leagueId/teams (inscribir equipo con plantilla)
// body: { nombre | teamName, plantilla?: [userIds] }
// ===================================
router.post('/:leagueId/teams', async (req, res) => {
  const { leagueId } = req.params;
  const body = req.body || {};
  const nombre = (body.nombre ?? body.teamName ?? '').toString().trim();
  if (!nombre) return res.status(400).json({ message: 'nombre requerido.' });
  try {
    const [ligas] = await pool.execute('SELECT * FROM ligas WHERE id_liga = ?', [leagueId]);
    if (ligas.length === 0) return res.status(404).json({ message: 'Liga no encontrada.' });
    const liga = ligas[0];
    if (liga.estado !== 'open') {
      return res.status(409).json({ message: 'La liga ya no acepta inscripciones.' });
    }
    const [[c]] = await pool.execute(
      'SELECT COUNT(*) AS n FROM liga_equipos WHERE id_liga_fk = ?', [leagueId]
    );
    if (c.n >= (liga.max_equipos ?? 12)) {
      return res.status(409).json({ message: 'Cupo lleno.' });
    }
    let plantilla = [];
    if (Array.isArray(body.plantilla)) {
      plantilla = [...new Set(body.plantilla.map(String))].slice(0, 30);
    }
    // El capitán siempre integra su propia plantilla.
    if (!plantilla.includes(String(req.user.sub))) plantilla.push(String(req.user.sub));
    try {
      const [r] = await pool.execute(
        `INSERT INTO liga_equipos (id_liga_fk, nombre, capitan_id, plantilla)
         VALUES (?, ?, ?, ?)`,
        [leagueId, nombre, req.user.sub, JSON.stringify(plantilla)]
      );
      res.status(201).json({
        id: String(r.insertId),
        leagueId: String(leagueId),
        nombre,
        teamName: nombre,
        plantilla,
      });
    } catch (e) {
      if (e.message && e.message.includes('UNIQUE')) {
        return res.status(409).json({ message: 'Ya existe un equipo con ese nombre.' });
      }
      throw e;
    }
  } catch (error) {
    console.error('Error al inscribir equipo:', error);
    res.status(500).json({ message: 'Error interno.' });
  }
});

// Compat legacy: POST /:leagueId/register { teamName }
router.post('/:leagueId/register', async (req, res) => {
  req.body = { ...(req.body || {}), nombre: (req.body || {}).teamName };
  // Re-dispatch interno simple
  const { leagueId } = req.params;
  const nombre = (req.body.nombre || '').toString().trim();
  if (!nombre) return res.status(400).json({ message: 'Falta teamName.' });
  try {
    const [ligas] = await pool.execute('SELECT * FROM ligas WHERE id_liga = ?', [leagueId]);
    if (ligas.length === 0) return res.status(404).json({ message: 'Liga no encontrada.' });
    if (ligas[0].estado !== 'open') {
      return res.status(409).json({ message: 'La liga ya no acepta inscripciones.' });
    }
    const [[c]] = await pool.execute(
      'SELECT COUNT(*) AS n FROM liga_equipos WHERE id_liga_fk = ?', [leagueId]
    );
    if (c.n >= (ligas[0].max_equipos ?? 12)) {
      return res.status(409).json({ message: 'Cupo lleno.' });
    }
    try {
      await pool.execute(
        `INSERT INTO liga_equipos (id_liga_fk, nombre, capitan_id, plantilla)
         VALUES (?, ?, ?, ?)`,
        [leagueId, nombre, req.user.sub, JSON.stringify([String(req.user.sub)])]
      );
    } catch (e) {
      if (e.message && e.message.includes('UNIQUE')) {
        return res.status(409).json({ message: 'Equipo ya inscrito o cupo lleno.' });
      }
      throw e;
    }
    return res.status(201).json({ ok: true, leagueId, teamName: nombre });
  } catch (error) {
    res.status(500).json({ message: 'Error interno.' });
  }
});

// ===================================
// GET /api/v1/leagues/:leagueId/teams
// ===================================
router.get('/:leagueId/teams', async (req, res) => {
  try {
    const [rows] = await pool.execute(
      'SELECT id_equipo AS id, nombre, capitan_id AS capitanId, plantilla FROM liga_equipos WHERE id_liga_fk = ? ORDER BY nombre ASC',
      [req.params.leagueId]
    );
    res.status(200).json(
      rows.map((r) => {
        let plantilla = [];
        try { plantilla = JSON.parse(r.plantilla || '[]'); } catch (_) {}
        return { id: String(r.id), nombre: r.nombre, capitanId: String(r.capitanId), plantilla };
      })
    );
  } catch (e) {
    res.status(500).json({ message: 'Error interno.' });
  }
});

// Round-robin (circle method). Con impar, un equipo descansa por jornada.
function roundRobin(ids) {
  const teams = [...ids];
  if (teams.length % 2 === 1) teams.push(null);
  const n = teams.length;
  const jornadas = [];
  const arr = [...teams];
  for (let j = 0; j < n - 1; j++) {
    const pairs = [];
    for (let i = 0; i < n / 2; i++) {
      const a = arr[i];
      const b = arr[n - 1 - i];
      if (a != null && b != null) pairs.push([a, b]);
    }
    jornadas.push(pairs);
    arr.splice(1, 0, arr.pop());
  }
  return jornadas;
}

// ===================================
// POST /api/v1/leagues/:leagueId/fixture (generar, solo superadmin)
// body: { fechaInicio?, diasEntreJornadas?, horaFija? }
// ===================================
router.post('/:leagueId/fixture', requireSuperAdmin, async (req, res) => {
  const { leagueId } = req.params;
  const {
    fechaInicio = new Date(Date.now() + 7 * 86400000).toISOString(),
    diasEntreJornadas = 7,
  } = req.body || {};
  let connection;
  try {
    const [ligas] = await pool.execute('SELECT * FROM ligas WHERE id_liga = ?', [leagueId]);
    if (ligas.length === 0) return res.status(404).json({ message: 'Liga no encontrada.' });
    const [teams] = await pool.execute(
      'SELECT id_equipo, nombre, plantilla FROM liga_equipos WHERE id_liga_fk = ? ORDER BY id_equipo ASC',
      [leagueId]
    );
    if (teams.length < 2) {
      return res.status(400).json({ message: 'Se necesitan al menos 2 equipos.' });
    }
    const [prev] = await pool.execute(
      'SELECT COUNT(*) AS n FROM liga_fixture WHERE id_liga_fk = ?', [leagueId]
    );
    if (prev[0].n > 0) {
      return res.status(409).json({ message: 'El fixture ya fue generado.' });
    }

    const jornadas = roundRobin(teams.map((t) => String(t.id_equipo)));
    const byId = Object.fromEntries(teams.map((t) => [String(t.id_equipo), t]));
    const stepDays = Math.max(1, Math.min(30, parseInt(diasEntreJornadas, 10) || 7));
    const base = new Date(fechaInicio).getTime() || Date.now();

    connection = await pool.getConnection();
    await connection.beginTransaction();
    let created = 0;
    for (let j = 0; j < jornadas.length; j++) {
      const when = new Date(base + j * stepDays * 86400000);
      for (const [aId, bId] of jornadas[j]) {
        const [m] = await connection.execute(
          `INSERT INTO partidos (id_campo_fk, hora_inicio, fecha_creacion, estado, tipo, id_liga_fk, equipo_a_id, equipo_b_id, jornada)
           VALUES (NULL, ?, datetime('now'), 'PENDIENTE', 'LIGA', ?, ?, ?, ?)`,
          [when.toISOString(), leagueId, aId, bId, j + 1]
        );
        const matchId = m.insertId;
        // Participantes = unión de plantillas (pueden proponer/confirmar resultado).
        const squad = [
          ...new Set([
            ...JSON.parse(byId[aId].plantilla || '[]').map(String),
            ...JSON.parse(byId[bId].plantilla || '[]').map(String),
          ]),
        ];
        for (const pid of squad) {
          try {
            await connection.execute(
              'INSERT INTO participantes (id_partido_fk, id_jugador_fk, fecha_registro) VALUES (?, ?, datetime(\'now\'))',
              [matchId, pid]
            );
          } catch (_) { /* duplicado: noop */ }
        }
        await connection.execute(
          'INSERT INTO liga_fixture (id_liga_fk, jornada, equipo_a_id, equipo_b_id, match_id) VALUES (?, ?, ?, ?, ?)',
          [leagueId, j + 1, aId, bId, matchId]
        );
        created++;
      }
    }
    await connection.execute("UPDATE ligas SET estado = 'en_curso' WHERE id_liga = ?", [leagueId]);
    await connection.commit();
    res.status(201).json({ ok: true, jornadas: jornadas.length, partidos: created });
  } catch (e) {
    if (connection) await connection.rollback();
    console.error('Error al generar fixture:', e);
    res.status(500).json({ message: 'Error interno.' });
  } finally {
    if (connection) connection.release();
  }
});

// ===================================
// GET /api/v1/leagues/:leagueId/fixture
// ===================================
router.get('/:leagueId/fixture', async (req, res) => {
  try {
    const [rows] = await pool.execute(
      `SELECT f.jornada, f.equipo_a_id AS equipoA, f.equipo_b_id AS equipoB,
              f.match_id AS matchId, p.estado AS status,
              p.goles_local AS golesA, p.goles_visitante AS golesB,
              ea.nombre AS nombreA, eb.nombre AS nombreB,
              r.estado AS resultEstado
       FROM liga_fixture f
       JOIN liga_equipos ea ON ea.id_equipo = f.equipo_a_id
       JOIN liga_equipos eb ON eb.id_equipo = f.equipo_b_id
       LEFT JOIN partidos p ON p.id_partido = f.match_id
       LEFT JOIN resultados r ON r.match_id = f.match_id
       WHERE f.id_liga_fk = ?
       ORDER BY f.jornada ASC, f.id ASC`,
      [req.params.leagueId]
    );
    res.status(200).json(
      rows.map((r) => ({
        jornada: r.jornada,
        equipoA: { id: String(r.equipoA), nombre: r.nombreA },
        equipoB: { id: String(r.equipoB), nombre: r.nombreB },
        matchId: r.matchId == null ? null : String(r.matchId),
        status: r.status,
        golesA: r.golesA,
        golesB: r.golesB,
        resultEstado: r.resultEstado,
      }))
    );
  } catch (e) {
    res.status(500).json({ message: 'Error interno.' });
  }
});

// ===================================
// GET /api/v1/leagues/:leagueId/standings (cálculo real en JS)
// ===================================
router.get('/:leagueId/standings', async (req, res) => {
  const { leagueId } = req.params;
  try {
    const [teams] = await pool.execute(
      'SELECT id_equipo AS id, nombre FROM liga_equipos WHERE id_liga_fk = ?',
      [leagueId]
    );
    if (teams.length === 0) return res.status(200).json([]);
    const table = Object.fromEntries(
      teams.map((t) => [
        String(t.id),
        {
          teamId: String(t.id),
          teamName: t.nombre,
          points: 0,
          gamesPlayed: 0,
          wins: 0,
          draws: 0,
          losses: 0,
          goalsFor: 0,
          goalsAgainst: 0,
          goalDifference: 0,
        },
      ])
    );
    const [matches] = await pool.execute(
      `SELECT p.equipo_a_id AS a, p.equipo_b_id AS b,
              r.goles_a AS ga, r.goles_b AS gb
       FROM partidos p JOIN resultados r ON r.match_id = p.id_partido
       WHERE p.id_liga_fk = ? AND r.estado = 'confirmado'`,
      [leagueId]
    );
    for (const m of matches) {
      const A = table[String(m.a)];
      const B = table[String(m.b)];
      if (!A || !B) continue;
      A.gamesPlayed++; B.gamesPlayed++;
      A.goalsFor += m.ga; A.goalsAgainst += m.gb;
      B.goalsFor += m.gb; B.goalsAgainst += m.ga;
      if (m.ga > m.gb) { A.wins++; A.points += 3; B.losses++; }
      else if (m.ga < m.gb) { B.wins++; B.points += 3; A.losses++; }
      else { A.draws++; B.draws++; A.points++; B.points++; }
    }
    const out = Object.values(table).map((t) => ({
      ...t,
      goalDifference: t.goalsFor - t.goalsAgainst,
    }));
    out.sort(
      (x, y) =>
        y.points - x.points ||
        y.goalDifference - x.goalDifference ||
        y.goalsFor - x.goalsFor ||
        x.teamName.localeCompare(y.teamName)
    );
    res.status(200).json(out);
  } catch (error) {
    console.error('Error al obtener clasificación:', error);
    res.status(500).json({ message: 'Error interno.' });
  }
});

// ===================================
// GET /api/v1/leagues/:leagueId/scorers (tabla de goleadores)
// ===================================
router.get('/:leagueId/scorers', async (req, res) => {
  try {
    const [rows] = await pool.execute(
      `SELECT r.goleadores AS goleadores
       FROM partidos p JOIN resultados r ON r.match_id = p.id_partido
       WHERE p.id_liga_fk = ? AND r.estado = 'confirmado'`,
      [req.params.leagueId]
    );
    const agg = {};
    for (const row of rows) {
      try {
        const list = JSON.parse(row.goleadores || '[]');
        for (const g of list) {
          const pid = String(g.playerId);
          agg[pid] = (agg[pid] || 0) + (Number(g.goles) || 0);
        }
      } catch (_) {}
    }
    const ids = Object.keys(agg);
    let names = {};
    if (ids.length > 0) {
      const ph = ids.map(() => '?').join(',');
      const [perfiles] = await pool.execute(
        `SELECT uid AS id, apodo AS nickname, nombre AS name FROM perfiles WHERE uid IN (${ph})`,
        ids
      );
      names = Object.fromEntries(
        perfiles.map((p) => [String(p.id), p.nickname || p.name || String(p.id)])
      );
    }
    const out = ids
      .map((id) => ({ playerId: id, name: names[id] || id, goles: agg[id] }))
      .sort((a, b) => b.goles - a.goles)
      .slice(0, 20);
    res.status(200).json(out);
  } catch (e) {
    res.status(500).json({ message: 'Error interno.' });
  }
});

module.exports = router;
