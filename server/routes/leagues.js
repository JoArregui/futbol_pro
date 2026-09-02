const express = require('express');
const pool = require('../db'); 
const router = express.Router();

// ===================================
// RUTA 1: GET /api/v1/leagues/:leagueId/standings
// ===================================
// Calcula y devuelve la clasificación de una liga.
router.get('/:leagueId/standings', async (req, res) => {
    const { leagueId } = req.params;

    try {
        // Esta es una consulta avanzada que CALCULA la clasificación en MySQL.
        // Asume la existencia de las tablas 'equipos' y 'resultados_partidos'.
        // Nota: La lógica real puede ser más compleja, pero esta es la base.
        const standingsSql = `
            WITH TeamResults AS (
                SELECT 
                    CASE 
                        WHEN resultado_local > resultado_visitante THEN id_equipo_local 
                        ELSE id_equipo_visitante 
                    END AS WinnerId,
                    CASE 
                        WHEN resultado_local < resultado_visitante THEN id_equipo_local 
                        ELSE id_equipo_visitante 
                    END AS LoserId,
                    CASE 
                        WHEN resultado_local = resultado_visitante THEN id_equipo_local 
                        WHEN resultado_local = resultado_visitante THEN id_equipo_visitante 
                    END AS DrawId,
                    id_equipo_local, 
                    id_equipo_visitante
                FROM resultados_partidos rp
                WHERE rp.id_liga_fk = ?
            )
            SELECT
                e.nombre AS teamName,
                SUM(CASE 
                    WHEN e.id_equipo = tr.WinnerId THEN 3 
                    WHEN e.id_equipo = tr.DrawId THEN 1 
                    ELSE 0 
                END) AS points,
                SUM(CASE WHEN e.id_equipo = tr.WinnerId THEN 1 ELSE 0 END) AS wins,
                SUM(CASE WHEN e.id_equipo = tr.LoserId THEN 1 ELSE 0 END) AS losses,
                SUM(CASE WHEN e.id_equipo = tr.DrawId THEN 1 ELSE 0 END) / 2 AS draws_count
            FROM 
                equipos e
            LEFT JOIN TeamResults tr ON e.id_equipo = tr.id_equipo_local OR e.id_equipo = tr.id_equipo_visitante
            WHERE e.id_liga_fk = ?
            GROUP BY 
                e.id_equipo, e.nombre
            ORDER BY 
                points DESC, wins DESC;
        `;
        
        // Ejecutamos la consulta
        const [rows] = await pool.execute(standingsSql, [leagueId, leagueId]); 

        if (rows.length > 0) {
            // Devolvemos la clasificación
            res.status(200).json(rows);
        } else {
            // 404 si la liga no tiene datos o no existe
            res.status(404).json({ message: 'Clasificación no disponible para esta liga.' });
        }

    } catch (error) {
        console.error("Error al obtener clasificación:", error);
        res.status(500).json({ message: 'Error interno del servidor al calcular la clasificación.' });
    }
});

module.exports = router;