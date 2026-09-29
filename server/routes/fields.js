const express = require('express');
const pool = require('../db');
const { requireAuth } = require('../middleware/auth');
const paypal = require('../services/paypal');
const router = express.Router();

// Seguridad: nunca anónimo — todo acceso requiere JWT válido.
router.use(requireAuth);

// Configuración PayPal desde variables de entorno
const PAYPAL_CLIENT_ID = process.env.PAYPAL_CLIENT_ID || '';

// ==========================================
// RUTA: GET /api/v1/fields/paypal/config
// ==========================================
// Obtener configuración del cliente PayPal (solo client ID para SDK front-end)
router.get('/paypal/config', async (req, res) => {
  try {
    if (!paypal.configured()) return res.status(503).json({ message: 'PayPal no está configurado.' });
    res.json({ clientId: PAYPAL_CLIENT_ID, environment: process.env.PAYPAL_ENVIRONMENT || 'sandbox' });
  } catch (e) {
    res.status(500).json({ message: 'Error al obtener configuración PayPal.' });
  }
});

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


// Porcentaje de seña configurable (20% por defecto).
const SENA_PCT = Math.min(Math.max(parseFloat(process.env.SENA_PCT || '0.2'), 0), 1);

// ===================================
// RUTA 2: POST /api/v1/fields/:fieldId/reserve
// ===================================
// Crea una reserva en estado 'pendiente' y una orden PayPal.
// El coste se calcula EN SERVIDOR desde tarifa_horaria (no se confía
// en el total que envía el cliente). userId = el del JWT (salvo superadmin).
router.post('/:fieldId/reserve', async (req, res) => {
    const { fieldId } = req.params;
    const { startTime, endTime } = req.body || {};
    let userId = String(req.user.sub);
    if (req.body.userId != null && String(req.body.userId) !== userId) {
        if (req.user.role !== 'superadmin') {
            return res.status(403).json({ message: 'Solo puedes reservar para ti.' });
        }
        userId = String(req.body.userId);
    }
    let connection;

    try {
        if (!startTime || !endTime) {
            return res.status(400).json({ message: 'Faltan startTime/endTime.' });
        }
        const start = new Date(startTime);
        const end = new Date(endTime);
        if (isNaN(start.getTime()) || isNaN(end.getTime()) || end <= start) {
            return res.status(400).json({ message: 'Rango de tiempo inválido.' });
        }

        connection = await pool.getConnection();
        await connection.beginTransaction();

        // 1. Tarifa real del campo
        const [fields] = await connection.execute(
            'SELECT tarifa_horaria AS rate, nombre AS name FROM campos WHERE id_campo = ?',
            [fieldId]
        );
        if (fields.length === 0) {
            await connection.rollback();
            return res.status(404).json({ message: 'Campo no encontrado.' });
        }
        const rate = Number(fields[0].rate ?? 50);

        // 2. Solapamiento (prevención de concurrencia)
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

        // 3. Coste servidor + seña
        const hours = (end - start) / 3600000;
        const total = Math.round(rate * hours * 100) / 100;
        const sena = Math.round(total * SENA_PCT * 100) / 100;

        const [ins] = await connection.execute(
            `INSERT INTO reservas (id_campo_fk, id_usuario_fk, hora_inicio, hora_fin, coste_total, fecha_reserva, estado, sena_monto)
             VALUES (?, ?, ?, ?, ?, datetime('now'), 'pendiente', ?)`,
            [fieldId, userId, start.toISOString(), end.toISOString(), total, sena]
        );
        const reservaId = ins.insertId;
        const order = await paypal.createOrder({
            amount: sena,
            reservationId: reservaId,
            fieldName: fields[0].name,
            userId,
        });
        const [pago] = await connection.execute(
            `INSERT INTO pagos (reserva_id, monto, concepto, estado, provider, provider_ref, approval_url)
             VALUES (?, ?, 'sena', 'pendiente', 'paypal', ?, ?)`,
            [reservaId, sena, order.id, order.approvalUrl]
        );

        await connection.commit();

        res.status(201).json({
            message: 'Reserva creada. Pendiente de seña.',
            reservaId: String(reservaId),
            fieldId: String(fieldId),
            fieldName: fields[0].name,
            total,
            sena,
            senaPct: SENA_PCT,
            estado: 'pendiente',
            pago: {
                id: String(pago.insertId), monto: sena, provider: 'paypal',
                providerRef: order.id, approvalUrl: order.approvalUrl,
            },
        });

    } catch (error) {
        if (connection) await connection.rollback();
        if (error.code === 'PAYPAL_NOT_CONFIGURED') {
            return res.status(503).json({ message: 'PayPal no está configurado.' });
        }
        console.error("Error al crear la reserva:", error);
        res.status(502).json({ message: 'No se pudo crear la orden de pago con PayPal.' });
    } finally {
        if (connection) connection.release();
    }
});

// ===================================
// RUTA 3: POST /api/v1/fields/pagos/:pagoId/confirm
// ===================================
// Captura y verifica el pago en PayPal antes de marcarlo como confirmado.
router.post('/pagos/:pagoId/confirm', async (req, res) => {
    const { pagoId } = req.params;
    const { orderId } = req.body || {};
    let connection;
    try {
        connection = await pool.getConnection();
        await connection.beginTransaction();
        const [rows] = await connection.execute('SELECT * FROM pagos WHERE id = ?', [pagoId]);
        if (rows.length === 0) {
            await connection.rollback();
            return res.status(404).json({ message: 'Pago no encontrado.' });
        }
        const pago = rows[0];
        const [resRows] = await connection.execute(
            'SELECT id_usuario_fk AS owner FROM reservas WHERE id = ?', [pago.reserva_id]
        );
        if (resRows.length === 0) {
            await connection.rollback();
            return res.status(404).json({ message: 'Reserva no encontrada.' });
        }
        if (String(resRows[0].owner) !== String(req.user.sub) && req.user.role !== 'superadmin') {
            await connection.rollback();
            return res.status(403).json({ message: 'No tienes permiso.' });
        }
        if (pago.estado === 'confirmado') {
            await connection.commit();
            return res.status(200).json({ ok: true, yaConfirmado: true, reservaId: String(pago.reserva_id) });
        }
        if (pago.provider !== 'paypal' || !orderId || String(orderId) !== String(pago.provider_ref)) {
            await connection.rollback();
            return res.status(400).json({ message: 'La orden PayPal no coincide con el pago.' });
        }
        let paypalOrder;
        try {
            paypalOrder = await paypal.captureOrder(orderId);
        } catch (captureError) {
            // Una captura repetida puede devolver un error aunque la orden ya esté completada.
            if (captureError.status === 422) paypalOrder = await paypal.getOrder(orderId);
            else throw captureError;
        }
        const unit = paypalOrder.purchase_units?.[0];
        const capture = unit?.payments?.captures?.[0];
        const capturedAmount = capture?.amount?.value;
        const capturedCurrency = capture?.amount?.currency_code;
        const expected = Number(pago.monto).toFixed(2);
        if (paypalOrder.status !== 'COMPLETED' || capture?.status !== 'COMPLETED' ||
            capturedCurrency !== paypal.currency || capturedAmount !== expected ||
            unit.reference_id !== String(pago.reserva_id)) {
            await connection.rollback();
            return res.status(402).json({ message: 'PayPal no confirmó el importe esperado.' });
        }
        await connection.execute(
            "UPDATE pagos SET estado = 'confirmado', confirmed_at = datetime('now') WHERE id = ?",
            [pagoId]
        );
        await connection.execute(
            "UPDATE reservas SET estado = 'senada' WHERE id = ?",
            [pago.reserva_id]
        );
        await connection.commit();
        res.status(200).json({ ok: true, reservaId: String(pago.reserva_id), estado: 'senada', providerRef: orderId });
    } catch (e) {
        if (connection) await connection.rollback();
        if (e.code === 'PAYPAL_NOT_CONFIGURED') return res.status(503).json({ message: 'PayPal no está configurado.' });
        console.error('Error al confirmar pago PayPal:', e);
        res.status(502).json({ message: 'No se pudo verificar el pago con PayPal.' });
    } finally {
        if (connection) connection.release();
    }
});

// ===================================
// RUTA 4: GET /api/v1/fields/mis-reservas
// ===================================
router.get('/mis-reservas', async (req, res) => {
    try {
        const [rows] = await pool.execute(
            `SELECT r.id AS id, r.id_campo_fk AS fieldId, c.nombre AS fieldName,
                    r.hora_inicio AS start, r.hora_fin AS fin,
                    r.coste_total AS total, r.estado AS estado, r.sena_monto AS sena,
                    (SELECT p.estado FROM pagos p WHERE p.reserva_id = r.id ORDER BY p.id DESC LIMIT 1) AS pagoEstado,
                    (SELECT p.id FROM pagos p WHERE p.reserva_id = r.id ORDER BY p.id DESC LIMIT 1) AS pagoId,
                    (SELECT p.provider_ref FROM pagos p WHERE p.reserva_id = r.id ORDER BY p.id DESC LIMIT 1) AS providerRef,
                    (SELECT p.approval_url FROM pagos p WHERE p.reserva_id = r.id ORDER BY p.id DESC LIMIT 1) AS approvalUrl
             FROM reservas r LEFT JOIN campos c ON c.id_campo = r.id_campo_fk
             WHERE r.id_usuario_fk = ?
             ORDER BY r.hora_inicio DESC LIMIT 50`,
            [req.user.sub]
        );
        res.status(200).json(rows.map((r) => ({
            ...r,
            id: String(r.id),
            fieldId: r.fieldId == null ? null : String(r.fieldId),
            pagoId: r.pagoId == null ? null : String(r.pagoId),
            providerRef: r.providerRef == null ? null : String(r.providerRef),
            approvalUrl: r.approvalUrl == null ? null : String(r.approvalUrl),
        })));
    } catch (e) {
        res.status(500).json({ message: 'Error interno.' });
    }
});

module.exports = router;
