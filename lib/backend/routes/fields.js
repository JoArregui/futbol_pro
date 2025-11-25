const express = require('express');
const pool = require('../db'); 
const router = express.Router();

// ===================================
// RUTA 1: GET /api/v1/fields/available
// ===================================
// Busca campos disponibles en un rango de tiempo.
router.get('/available', async (req, res) => {
    const { start, end } = req.query; // Recibe start/end time de la app Flutter
    
    if (!start || !end) {
        return res.status(400).json({ message: 'Faltan los parámetros de tiempo (start y end).' });
    }

    try {
        // SQL para encontrar campos que *no* tienen reservas que se solapen
        // Lógica de solapamiento: (A.End > B.Start) AND (A.Start < B.End)
        const sql = `
            SELECT 
                c.id_campo AS id, 
                c.nombre AS name, 
                c.tarifa_horaria AS hourlyRate, 
                c.capacidad AS capacity
            FROM 
                campos c
            WHERE 
                c.id_campo NOT IN (
                    SELECT 
                        id_campo_fk 
                    FROM 
                        reservas 
                    WHERE 
                        (hora_fin > ?) AND (hora_inicio < ?)
                );
        `;
        
        // Ejecutamos la consulta usando los parámetros de tiempo
        const [rows] = await pool.execute(sql, [end, start]); 

        if (rows.length > 0) {
            // Devolvemos la lista de campos disponibles
            res.status(200).json(rows);
        } else {
            // 404 si no hay campos disponibles en ese horario
            res.status(404).json({ message: 'No hay campos disponibles en este horario.' });
        }

    } catch (error) {
        console.error("Error al obtener campos disponibles:", error);
        res.status(500).json({ message: 'Error interno del servidor al consultar campos.' });
    }
});


// ===================================
// RUTA 2: POST /api/v1/fields/:fieldId/reserve
// ===================================
// Crea una nueva reserva para un campo específico.
router.post('/:fieldId/reserve', async (req, res) => {
    const { fieldId } = req.params;
    const { startTime, endTime, userId, totalCost } = req.body;
    let connection;

    try {
        if (!startTime || !endTime || !userId || !totalCost) {
            return res.status(400).json({ message: 'Faltan parámetros necesarios para la reserva.' });
        }

        connection = await pool.getConnection();
        await connection.beginTransaction(); 

        // 1. Verificar si ya existe una reserva que se solape (prevención de concurrencia)
        const overlapSql = `
            SELECT 
                COUNT(*) as count 
            FROM 
                reservas 
            WHERE 
                id_campo_fk = ? AND (hora_fin > ?) AND (hora_inicio < ?)
        `;
        const [overlapResult] = await connection.execute(overlapSql, [fieldId, startTime, endTime]);

        if (overlapResult[0].count > 0) {
            await connection.rollback();
            return res.status(409).json({ message: 'El campo ya está reservado en ese horario.' }); // 409 Conflict
        }

        // 2. Insertar la nueva reserva
        const insertSql = `
            INSERT INTO reservas (id_campo_fk, id_usuario_fk, hora_inicio, hora_fin, coste_total, fecha_reserva)
            VALUES (?, ?, ?, ?, ?, NOW())
        `;
        await connection.execute(insertSql, [fieldId, userId, startTime, endTime, totalCost]);
        
        await connection.commit(); 

        // 3. Respuesta de éxito
        res.status(201).json({ message: 'Reserva creada exitosamente.' });

    } catch (error) {
        if (connection) await connection.rollback(); 
        console.error("Error al crear la reserva:", error);
        res.status(500).json({ message: 'Error interno del servidor al procesar la reserva.' });
    } finally {
        if (connection) connection.release();
    }
});

module.exports = router;