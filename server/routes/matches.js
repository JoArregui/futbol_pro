const express = require('express');
const pool = require('../db'); 
const router = express.Router();

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
router.post('/', async (req, res) => {
    const { time, fieldId } = req.body;
    let connection;

    try {
        connection = await pool.getConnection();
        await connection.beginTransaction(); 

        const now = new Date();

        // 1. Insertar el partido en la tabla 'partidos'
        const insertMatchSql = `
            INSERT INTO partidos (id_campo_fk, hora_inicio, fecha_creacion, estado, tipo)
            VALUES (?, ?, ?, 'PENDIENTE', 'AMISTOSO');
        `;
        const [result] = await connection.execute(insertMatchSql, [fieldId, time, now]);
        const newMatchId = result.insertId;

        // 2. Insertar el creador como primer participante si fuera necesario (Opcional, depende de la lógica)

        await connection.commit(); 

        // 3. Devolver el nuevo partido (con solo los datos esenciales)
        res.status(201).json({ 
            id: newMatchId.toString(),
            time: time,
            fieldId: fieldId,
            status: 'PENDIENTE',
            teams: { teamA: null, teamB: null }, // Equipos inicialmente vacíos
            participants: [], // Lista de jugadores vacía
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
// Obtener la lista de partidos próximos.
router.get('/upcoming', async (req, res) => {
    try {
        const sql = `
            SELECT 
                p.id_partido AS id, 
                p.id_campo_fk AS fieldId, 
                p.hora_inicio AS time,
                p.estado AS status
                -- Se necesitaría más lógica para obtener teams y participants
            FROM 
                partidos p
            WHERE 
                p.hora_inicio > NOW() AND p.estado IN ('PENDIENTE', 'ACTIVO')
            ORDER BY 
                p.hora_inicio ASC;
        `;
        
        const [rows] = await pool.execute(sql); 

        // Nota: Para ser 100% fiel a MatchModel, deberías obtener y adjuntar
        // los datos de participantes y equipos. Aquí devolvemos una simplificación.
        const matches = rows.map(row => ({
            ...row,
            teams: { teamA: null, teamB: null }, 
            participants: [],
            id: row.id.toString(),
            time: row.time.toISOString(),
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
    const { playerId } = req.body;
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
                estado AS status
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
        
        // Simulación: Adjuntar equipos y participantes (debes implementar la lógica de JOIN real)
        const detailedMatch = {
            id: matchData.id.toString(),
            fieldId: matchData.fieldId,
            time: matchData.time.toISOString(),
            status: matchData.status,
            teams: { teamA: null, teamB: null }, // Placeholder
            participants: [], // Placeholder
        };

        res.status(200).json(detailedMatch);

    } catch (error) {
        console.error("Error al obtener partido por ID:", error);
        res.status(500).json({ message: 'Error interno del servidor.' });
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