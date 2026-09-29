const express = require('express');
const pool = require('../db');
const { requireAuth } = require('../middleware/auth');
const router = express.Router();

// Seguridad: nunca anónimo — todo acceso requiere JWT válido.
router.use(requireAuth);

// Helper para transformar el formato de TeamModel de Flutter a SQL
const transformTeamModel = (team) => {
    return {
        id_equipo: team.id,
        nombre: team.name,
        miembros: JSON.stringify(team.playerIds), // Guardar IDs de jugadores como JSON string
        // Si hay otros campos, se mapean aquí
    };
};

// ===================================
// RUTA 1: POST /api/v1/matches
// ===================================
// Agendar un nuevo partido amistoso.
// Acepta: equipos completos o jugadores sueltos + árbitro opcional.
router.post('/', async (req, res) => {
    const {
        time,
        scheduledTime,
        fieldId,
        title = 'Amistoso',
        mode = 'open',
        needsReferee = false,
        description = null,
        organizerTeam = null,
        opponentTeam = null,
        maxPlayers = null,
        costeTotal = null,
        totalCost = null,
    } = req.body;
    const when = scheduledTime || time;
    const cost = Number(costeTotal ?? totalCost);
    const finalCost = Number.isFinite(cost) && cost >= 0 ? cost : null;
    let connection;

    try {
        connection = await pool.getConnection();
        await connection.beginTransaction();

        const now = new Date();

        // 1. Insertar el partido en la tabla 'partidos'
        const insertMatchSql = `
            INSERT INTO partidos (id_campo_fk, hora_inicio, fecha_creacion, estado, tipo, coste_total)
            VALUES (?, ?, ?, 'PENDIENTE', 'AMISTOSO', ?);
        `;
        const [result] = await connection.execute(insertMatchSql, [fieldId, when, now, finalCost]);
        const newMatchId = result.insertId;

        // El creador queda apuntado automáticamente.
        try {
            await connection.execute(
                "INSERT INTO participantes (id_partido_fk, id_jugador_fk, fecha_registro) VALUES (?, ?, datetime('now'))",
                [newMatchId, req.user.sub]
            );
        } catch (_) { /* noop */ }

        await connection.commit();

        // Devolver en formato compatible con MatchModel (Flutter)
        res.status(201).json({
            id: newMatchId.toString(),
            title,
            scheduledTime: new Date(when).toISOString(),
            time: new Date(when).toISOString(),
            fieldId: fieldId?.toString(),
            type: 'friendly',
            mode,
            needsReferee: !!needsReferee,
            description,
            organizerTeam,
            opponentTeam,
            maxPlayers,
            status: 'PENDIENTE',
            costeTotal: finalCost,
            totalCost: finalCost,
            playerIds: [String(req.user.sub)],
            participants: [],
            teamA: null,
            teamB: null,
        });

    } catch (error) {
        if (connection) await connection.rollback(); 
        console.error("Error al agendar partido:", error);
        res.status(500).json({ message: 'Error interno del servidor.' });
    } finally {
        if (connection) connection.release();
    }
});


// ===================================
// RUTA 2: GET /api/v1/matches/upcoming
// ===================================
router.get('/upcoming', async (req, res) => {
    try {
        const nowIso = new Date().toISOString();
        const sql = `
            SELECT 
                p.id_partido AS id, 
                p.id_campo_fk AS fieldId, 
                p.hora_inicio AS time,
                p.estado AS status
            FROM 
                partidos p
            WHERE 
                p.hora_inicio > ? AND p.estado IN ('PENDIENTE', 'ACTIVO')
            ORDER BY 
                p.hora_inicio ASC;
        `;
        const [rows] = await pool.execute(sql, [nowIso]);

        // Compatible con MatchModel.fromJson
        const matches = rows.map(row => ({
            id: row.id.toString(),
            title: row.titulo || 'Amistoso',
            scheduledTime: row.time instanceof Date ? row.time.toISOString() : row.time,
            time: row.time instanceof Date ? row.time.toISOString() : row.time,
            fieldId: row.fieldId?.toString(),
            type: 'friendly',
            mode: 'open',
            needsReferee: false,
            playerIds: [],
            participants: [],
            teamA: null,
            teamB: null,
            status: row.status,
        }));

        res.status(200).json(matches); 

    } catch (error) {
        console.error("Error al obtener partidos próximos:", error);
        res.status(500).json({ message: 'Error interno del servidor.' });
    }
});


// ===================================
// RUTA 3: POST /api/v1/matches/:matchId/join
// ===================================
// Añadir un jugador a un partido (tabla participantes).
router.post('/:matchId/join', async (req, res) => {
    const { matchId } = req.params;
    // Seguridad: solo puedes apuntarte a ti mismo (o superadmin gestionando).
    const requested = req.body.playerId != null ? String(req.body.playerId) : String(req.user.sub);
    if (requested !== String(req.user.sub) && req.user.role !== 'superadmin') {
        return res.status(403).json({ message: 'Solo puedes unirte tú mismo.' });
    }
    const playerId = requested;
    let connection;

    try {
        connection = await pool.getConnection();
        
        // 1. Verificar si el jugador ya está en el partido
        const checkSql = "SELECT COUNT(*) as count FROM participantes WHERE id_partido_fk = ? AND id_jugador_fk = ?";
        const [checkResult] = await connection.execute(checkSql, [matchId, playerId]);

        if (checkResult[0].count > 0) {
            return res.status(409).json({ message: 'El jugador ya está en este partido.' }); // 409 Conflict
        }
        
        // 2. Insertar al nuevo participante
        const insertSql = "INSERT INTO participantes (id_partido_fk, id_jugador_fk, fecha_registro) VALUES (?, ?, NOW())";
        await connection.execute(insertSql, [matchId, playerId]);
        
        // 3. Obtener el partido actualizado (se omite la lógica de fetch por simplicidad)
        // Normalmente llamarías a getMatchById aquí para devolver el MatchModel actualizado
        
        res.status(200).json({ 
             message: 'Jugador añadido exitosamente.', 
             id: matchId, 
             // ... devolver MatchModel completo
        });

    } catch (error) {
        console.error("Error al añadir jugador al partido:", error);
        res.status(500).json({ message: 'Error interno del servidor.' });
    } finally {
        if (connection) connection.release();
    }
});


// ===================================
// RUTA 4: GET /api/v1/matches/:matchId
// ===================================
// Obtener un partido por ID.
router.get('/:matchId', async (req, res) => {
    const { matchId } = req.params;

    try {
        // Consulta para obtener el partido principal
        const matchSql = `
            SELECT
                id_partido AS id,
                id_campo_fk AS fieldId,
                hora_inicio AS time,
                estado AS status,
                goles_local AS golesA,
                goles_visitante AS golesB,
                mvp_id AS mvpId,
                coste_total AS costeTotal
            FROM
                partidos
            WHERE
                id_partido = ?;
        `;
        const [matchRows] = await pool.execute(matchSql, [matchId]);

        if (matchRows.length === 0) {
            return res.status(404).json({ message: 'Partido no encontrado.' });
        }

        const matchData = matchRows[0];

        const [partRows] = await pool.execute(
            `SELECT p.uid AS id, p.nombre AS name, p.apodo AS nickname,
                    p.url_avatar AS profileImageUrl, p.partidos_jugados AS played,
                    p.victorias AS wins, p.mvp_count AS mvpCount,
                    p.no_show_count AS noShows
             FROM participantes pa JOIN perfiles p ON p.uid = pa.id_jugador_fk
             WHERE pa.id_partido_fk = ?`,
            [matchId]
        );
        const [resRows] = await pool.execute(
            'SELECT * FROM resultados WHERE match_id = ?', [matchId]
        );

        const detailedMatch = {
            id: matchData.id.toString(),
            fieldId: matchData.fieldId == null ? null : String(matchData.fieldId),
            time: matchData.time instanceof Date ? matchData.time.toISOString() : matchData.time,
            status: matchData.status,
            golesA: matchData.golesA,
            golesB: matchData.golesB,
            mvpId: matchData.mvpId == null ? null : String(matchData.mvpId),
            costeTotal: matchData.costeTotal,
            totalCost: matchData.costeTotal,
            teams: { teamA: null, teamB: null },
            participants: partRows.map(r => ({ ...r, id: String(r.id) })),
            playerIds: partRows.map(r => String(r.id)),
            result: rowToResult(resRows[0] || null),
        };

        res.status(200).json(detailedMatch);

    } catch (error) {
        console.error("Error al obtener partido por ID:", error);
        res.status(500).json({ message: 'Error interno del servidor.' });
    }
});


// ===================================
// Helpers Fase 2: resultados y reputación
// ===================================
async function isParticipant(matchId, userId) {
    const [rows] = await pool.execute(
        'SELECT 1 FROM participantes WHERE id_partido_fk = ? AND id_jugador_fk = ? LIMIT 1',
        [matchId, userId]
    );
    return rows.length > 0;
}

async function getParticipantIds(matchId) {
    const [rows] = await pool.execute(
        'SELECT id_jugador_fk AS id FROM participantes WHERE id_partido_fk = ?',
        [matchId]
    );
    return rows.map(r => String(r.id));
}

function parseIds(value) {
    if (!Array.isArray(value)) return [];
    return [...new Set(value.map(v => String(v)).filter(s => s.length > 0))].slice(0, 60);
}

function rowToResult(row) {
    if (!row) return null;
    let goleadores = [];
    let teamA = [];
    let teamB = [];
    try { goleadores = JSON.parse(row.goleadores || '[]'); } catch (_) {}
    try { teamA = JSON.parse(row.team_a_ids || '[]'); } catch (_) {}
    try { teamB = JSON.parse(row.team_b_ids || '[]'); } catch (_) {}
    return {
        matchId: String(row.match_id),
        golesA: row.goles_a,
        golesB: row.goles_b,
        ganador: row.ganador,
        goleadores,
        teamAIds: teamA,
        teamBIds: teamB,
        mvpId: row.mvp_id == null ? null : String(row.mvp_id),
        propuestoPor: String(row.propuesto_por),
        estado: row.estado,
        confirmedAt: row.confirmed_at,
    };
}

// ===================================
// RUTA 6: POST /api/v1/matches/:matchId/result (proponer resultado)
// Solo participantes. body: { golesA, golesB, ganador?, goleadores?,
// teamAIds?, teamBIds?, mvpId? }
// ===================================
router.post('/:matchId/result', async (req, res) => {
    const { matchId } = req.params;
    const me = String(req.user.sub);
    try {
        const [matchRows] = await pool.execute(
            'SELECT id_partido FROM partidos WHERE id_partido = ?', [matchId]
        );
        if (matchRows.length === 0) {
            return res.status(404).json({ message: 'Partido no encontrado.' });
        }
        if (!(await isParticipant(matchId, me))) {
            return res.status(403).json({ message: 'Solo los participantes pueden proponer el resultado.' });
        }
        const [existing] = await pool.execute(
            'SELECT * FROM resultados WHERE match_id = ?', [matchId]
        );
        if (existing.length > 0 && existing[0].estado === 'confirmado') {
            return res.status(409).json({ message: 'El resultado ya está confirmado.' });
        }

        const golesA = Number(req.body.golesA);
        const golesB = Number(req.body.golesB);
        if (!Number.isInteger(golesA) || !Number.isInteger(golesB) || golesA < 0 || golesB > 99 || golesA > 99 || golesB < 0) {
            return res.status(400).json({ message: 'golesA/golesB deben ser enteros 0-99.' });
        }
        const ganador = ['A', 'B', 'empate'].includes(req.body.ganador) ? req.body.ganador : 'empate';
        const participantIds = await getParticipantIds(matchId);
        const inSquad = (id) => participantIds.includes(String(id));

        const teamAIds = parseIds(req.body.teamAIds).filter(inSquad);
        const teamBIds = parseIds(req.body.teamBIds).filter(inSquad);

        let mvpId = null;
        if (req.body.mvpId != null && String(req.body.mvpId).length > 0) {
            if (!inSquad(req.body.mvpId)) {
                return res.status(400).json({ message: 'El MVP debe ser participante del partido.' });
            }
            mvpId = String(req.body.mvpId);
        }

        let goleadores = [];
        if (req.body.goleadores != null) {
            if (!Array.isArray(req.body.goleadores) || req.body.goleadores.length > 60) {
                return res.status(400).json({ message: 'goleadores inválido.' });
            }
            for (const g of req.body.goleadores) {
                const pid = String(g.playerId ?? '');
                const goles = Number(g.goles);
                if (!inSquad(pid) || !Number.isInteger(goles) || goles < 1 || goles > 99) {
                    return res.status(400).json({ message: 'Goleador inválido (debe ser participante, goles 1-99).' });
                }
                goleadores.push({ playerId: pid, goles });
            }
        }

        if (existing.length > 0) {
            await pool.execute(
                `UPDATE resultados SET goles_a = ?, goles_b = ?, ganador = ?, goleadores = ?,
                 team_a_ids = ?, team_b_ids = ?, mvp_id = ?, propuesto_por = ?, estado = 'propuesta',
                 created_at = datetime('now'), confirmed_at = NULL WHERE match_id = ?`,
                [golesA, golesB, ganador, JSON.stringify(goleadores),
                 JSON.stringify(teamAIds), JSON.stringify(teamBIds), mvpId, me, matchId]
            );
        } else {
            await pool.execute(
                `INSERT INTO resultados (match_id, goles_a, goles_b, ganador, goleadores,
                 team_a_ids, team_b_ids, mvp_id, propuesto_por, estado)
                 VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, 'propuesta')`,
                [matchId, golesA, golesB, ganador, JSON.stringify(goleadores),
                 JSON.stringify(teamAIds), JSON.stringify(teamBIds), mvpId, me]
            );
        }
        await pool.execute(
            "UPDATE partidos SET estado = 'RESULTADO_PROPUESTO' WHERE id_partido = ?",
            [matchId]
        );
        const [rows] = await pool.execute('SELECT * FROM resultados WHERE match_id = ?', [matchId]);
        res.status(200).json(rowToResult(rows[0]));
    } catch (e) {
        console.error('Error al proponer resultado:', e);
        res.status(500).json({ message: 'Error interno.' });
    }
});

// ===================================
// RUTA 7: POST /api/v1/matches/:matchId/result/confirm
// Solo un participante DISTINTO al proponente (o superadmin).
// Aplica reputación: jugados a todos, victorias al ganador, MVP+1.
// ===================================
router.post('/:matchId/result/confirm', async (req, res) => {
    const { matchId } = req.params;
    const me = String(req.user.sub);
    const isAdmin = req.user.role === 'superadmin';
    let connection;
    try {
        const [rows] = await pool.execute('SELECT * FROM resultados WHERE match_id = ?', [matchId]);
        if (rows.length === 0) {
            return res.status(404).json({ message: 'No hay resultado propuesto.' });
        }
        const current = rows[0];
        if (current.estado === 'confirmado') {
            return res.status(200).json(rowToResult(current));
        }
        if (!isAdmin) {
            if (!(await isParticipant(matchId, me))) {
                return res.status(403).json({ message: 'Solo los participantes pueden confirmar.' });
            }
            if (String(current.propuesto_por) === me) {
                return res.status(403).json({ message: 'Otro participante debe confirmar el resultado.' });
            }
        }

        connection = await pool.getConnection();
        await connection.beginTransaction();

        await connection.execute(
            "UPDATE resultados SET estado = 'confirmado', confirmed_at = datetime('now') WHERE match_id = ?",
            [matchId]
        );
        await connection.execute(
            'UPDATE partidos SET estado = ?, goles_local = ?, goles_visitante = ?, mvp_id = ? WHERE id_partido = ?',
            ['FINALIZADO', current.goles_a, current.goles_b, current.mvp_id, matchId]
        );

        const participantIds = await getParticipantIds(matchId);
        for (const pid of participantIds) {
            await connection.execute(
                'UPDATE perfiles SET partidos_jugados = partidos_jugados + 1 WHERE uid = ?',
                [pid]
            );
        }
        // Victorias según ganador + equipos informados (si los hay).
        let winners = [];
        try {
            const teamA = JSON.parse(current.team_a_ids || '[]');
            const teamB = JSON.parse(current.team_b_ids || '[]');
            if (current.ganador === 'A') winners = teamA;
            else if (current.ganador === 'B') winners = teamB;
        } catch (_) {}
        for (const pid of winners.map(String)) {
            await connection.execute(
                'UPDATE perfiles SET victorias = victorias + 1 WHERE uid = ?',
                [pid]
            );
        }
        if (current.mvp_id != null) {
            await connection.execute(
                'UPDATE perfiles SET mvp_count = mvp_count + 1 WHERE uid = ?',
                [String(current.mvp_id)]
            );
        }

        await connection.commit();
        const [fresh] = await pool.execute('SELECT * FROM resultados WHERE match_id = ?', [matchId]);
        res.status(200).json(rowToResult(fresh[0]));
    } catch (e) {
        if (connection) await connection.rollback();
        console.error('Error al confirmar resultado:', e);
        res.status(500).json({ message: 'Error interno.' });
    } finally {
        if (connection) connection.release();
    }
});

// ===================================
// RUTA 8: GET /api/v1/matches/:matchId/result
// ===================================
router.get('/:matchId/result', async (req, res) => {
    const { matchId } = req.params;
    try {
        const [rows] = await pool.execute('SELECT * FROM resultados WHERE match_id = ?', [matchId]);
        if (rows.length === 0) return res.status(404).json({ proposed: false });
        res.status(200).json(rowToResult(rows[0]));
    } catch (e) {
        res.status(500).json({ message: 'Error interno.' });
    }
});

// ===================================
// RUTA 9: POST /api/v1/matches/:matchId/no-show { playerId }
// Reporta inasistencia: solo participantes (o superadmin). Suma no_show_count.
// ===================================
router.post('/:matchId/no-show', async (req, res) => {
    const { matchId } = req.params;
    const me = String(req.user.sub);
    const isAdmin = req.user.role === 'superadmin';
    try {
        const { playerId } = req.body || {};
        if (!playerId) return res.status(400).json({ message: 'playerId requerido.' });
        if (!isAdmin && !(await isParticipant(matchId, me))) {
            return res.status(403).json({ message: 'Solo los participantes pueden reportar.' });
        }
        if (!(await isParticipant(matchId, String(playerId)))) {
            return res.status(404).json({ message: 'El jugador no es participante.' });
        }
        await pool.execute(
            'UPDATE perfiles SET no_show_count = no_show_count + 1 WHERE uid = ?',
            [String(playerId)]
        );
        const [rows] = await pool.execute(
            'SELECT no_show_count AS noShows FROM perfiles WHERE uid = ?',
            [String(playerId)]
        );
        res.status(200).json({ ok: true, playerId: String(playerId), noShows: rows[0]?.noShows ?? null });
    } catch (e) {
        res.status(500).json({ message: 'Error interno.' });
    }
});

// ===================================
// RUTA 5b: GET /api/v1/matches/:matchId/split (división de cuenta)
// ===================================
// Devuelve el coste total y cuánto pone cada participante.
router.get('/:matchId/split', async (req, res) => {
    const { matchId } = req.params;
    try {
        const [[m]] = await pool.execute(
            'SELECT coste_total AS total FROM partidos WHERE id_partido = ?',
            [matchId]
        );
        if (!m) return res.status(404).json({ message: 'Partido no encontrado.' });
        const [parts] = await pool.execute(
            `SELECT p.uid AS id, p.apodo AS nickname, p.nombre AS name
             FROM participantes pa JOIN perfiles p ON p.uid = pa.id_jugador_fk
             WHERE pa.id_partido_fk = ?`,
            [matchId]
        );
        const total = Number(m.total ?? 0);
        const n = Math.max(parts.length, 1);
        const perPerson = Math.round((total / n) * 100) / 100;
        res.status(200).json({
            matchId: String(matchId),
            total,
            hasCost: m.total != null,
            participants: parts.length,
            perPerson,
            detail: parts.map((p) => ({
                id: String(p.id),
                name: p.nickname || p.name || String(p.id),
                amount: perPerson,
            })),
        });
    } catch (e) {
        res.status(500).json({ message: 'Error interno.' });
    }
});

// ===================================
// RUTA 5: PUT /api/v1/matches/:matchId/teams
// ===================================
// Asignar los equipos a un partido.
router.put('/:matchId/teams', async (req, res) => {
    const { matchId } = req.params;
    const { teamA, teamB } = req.body; // Recibe TeamModel JSON

    try {
        // Validación básica
        if (!teamA || !teamB) {
            return res.status(400).json({ message: 'Faltan datos de Team A o Team B.' });
        }
        
        // En una implementación real:
        // 1. Guardar o actualizar TeamA y TeamB en la tabla 'equipos'
        // 2. Actualizar la tabla 'partidos' con el ID del equipo A y B
        
        // Simulación de respuesta exitosa
        res.status(200).json({ 
            id: matchId, 
            message: 'Equipos actualizados exitosamente.',
            teams: { teamA, teamB }
            // ... devolver MatchModel completo
        });

    } catch (error) {
        console.error("Error al actualizar equipos del partido:", error);
        res.status(500).json({ message: 'Error interno del servidor.' });
    }
});

module.exports = router;