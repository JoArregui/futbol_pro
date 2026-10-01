const express = require('express');
const pool = require('../db');
const { requireAuth } = require('../middleware/auth');
const paypal = require('../services/paypal');
const stripe = require('../services/stripe');
const notify = require('../services/notify');
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
    const { start, end } = req.query;
    
    if (!start || !end) {
        return res.status(400).json({ message: 'Faltan los parámetros de tiempo (start y end).' });
    }
    const s = new Date(start);
    const e = new Date(end);
    if (isNaN(s.getTime()) || isNaN(e.getTime()) || e <= s) {
        return res.status(400).json({ message: 'Rango start/end inválido.' });
    }
    const startIso = s.toISOString();
    const endIso = e.toISOString();

    try {
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
                        AND estado NOT IN ('cancelada', 'error_pago')
                );
        `;
        
        const [rows] = await pool.execute(sql, [endIso, startIso]); 

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


// Porcentaje de seña configurable (20% por defecto, validado anti-NaN).
const _senaRaw = parseFloat(process.env.SENA_PCT || '0.2');
const SENA_PCT = Number.isFinite(_senaRaw) ? Math.min(Math.max(_senaRaw, 0), 1) : 0.2;

// ===================================
// RUTA 2: POST /api/v1/fields/:fieldId/reserve
// ===================================
// Crea una reserva en estado 'pendiente' y una orden PayPal.
// El coste se calcula EN SERVIDOR desde tarifa_horaria (no se confía
// en el total que envía el cliente). userId = el del JWT (salvo superadmin).
router.post('/:fieldId/reserve', async (req, res) => {
    const { fieldId } = req.params;
    const { startTime, endTime, paymentMethod = 'paypal' } = req.body || {};
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
        if (!['paypal', 'stripe'].includes(paymentMethod)) {
            return res.status(400).json({ message: 'Método de pago no soportado.' });
        }
        // Pre-check ANTES de la tx: no crear reservas que bloqueen si el
        // provider no está configurado.
        if (paymentMethod === 'paypal' && !paypal.configured()) {
            return res.status(503).json({ message: 'PayPal no está configurado.' });
        }
        if (paymentMethod === 'stripe' && !stripe.configured()) {
            return res.status(503).json({ message: 'Stripe no está configurado.' });
        }
        const fieldNum = Number(fieldId);
        if (!Number.isInteger(fieldNum) || fieldNum <= 0) {
            return res.status(400).json({ message: 'fieldId inválido.' });
        }
        const start = new Date(startTime);
        const end = new Date(endTime);
        if (isNaN(start.getTime()) || isNaN(end.getTime()) || end <= start) {
            return res.status(400).json({ message: 'Rango de tiempo inválido.' });
        }
        if (start.getTime() <= Date.now()) {
            return res.status(400).json({ message: 'La reserva debe ser futura.' });
        }
        const hours = (end - start) / 3600000;
        if (hours > 24) {
            return res.status(400).json({ message: 'Reserva máxima 24h.' });
        }
        const startIso = start.toISOString();
        const endIso = end.toISOString();

        connection = await pool.getConnection();
        await connection.beginTransaction();

        // 1. Tarifa real del campo
        const [fields] = await connection.execute(
            'SELECT tarifa_horaria AS rate, nombre AS name FROM campos WHERE id_campo = ?',
            [fieldNum]
        );
        if (fields.length === 0) {
            await connection.rollback();
            return res.status(404).json({ message: 'Campo no encontrado.' });
        }
        const rate = Number(fields[0].rate ?? 50);

        // 2. Solapamiento con ISO normalizado (prevención de concurrencia)
        const overlapSql = `
            SELECT
                COUNT(*) as count
            FROM
                reservas
            WHERE
                id_campo_fk = ? AND (hora_fin > ?) AND (hora_inicio < ?) AND estado NOT IN ('cancelada', 'error_pago')
        `;
        const [overlapResult] = await connection.execute(overlapSql, [fieldNum, startIso, endIso]);

        if (overlapResult[0].count > 0) {
            await connection.rollback();
            return res.status(409).json({ message: 'El campo ya está reservado en ese horario.' });
        }

        // 3. Coste servidor + seña (tx corta: solo reserva+pago pendiente)
        const total = Math.round(rate * hours * 100) / 100;
        const sena = Math.round(total * SENA_PCT * 100) / 100;

        const [ins] = await connection.execute(
            `INSERT INTO reservas (id_campo_fk, id_usuario_fk, hora_inicio, hora_fin, coste_total, fecha_reserva, estado, sena_monto)
             VALUES (?, ?, ?, ?, ?, datetime('now'), 'pendiente', ?)`,
            [fieldNum, userId, startIso, endIso, total, sena]
        );
        const reservaId = ins.insertId;
        const [pago] = await connection.execute(
            `INSERT INTO pagos (reserva_id, monto, concepto, estado, provider, provider_ref, approval_url)
             VALUES (?, ?, 'sena', 'pendiente', ?, '', '')`,
            [reservaId, sena, paymentMethod]
        );
        await connection.commit();
        connection.release();
        connection = null;

        // 4. Orden de pago FUERA de la transacción (no bloquea SQLite).
        let order;
        try {
          order = paymentMethod === 'stripe'
            ? await stripe.createCheckoutSession({ amount: sena, reservationId: reservaId, fieldName: fields[0].name, userId })
            : await paypal.createOrder({ amount: sena, reservationId: reservaId, fieldName: fields[0].name, userId });
        } catch (payErr) {
          if (payErr.code === 'PAYPAL_NOT_CONFIGURED') return res.status(503).json({ message: 'PayPal no está configurado.', reservaId: String(reservaId) });
          if (payErr.code === 'STRIPE_NOT_CONFIGURED') return res.status(503).json({ message: 'Stripe no está configurado.', reservaId: String(reservaId) });
          await pool.execute(
            "UPDATE reservas SET estado = 'error_pago' WHERE id = ?", [reservaId]);
          return res.status(502).json({ message: `No se pudo crear la orden con ${paymentMethod}.`, reservaId: String(reservaId) });
        }
        await pool.execute(
          'UPDATE pagos SET provider_ref = ?, approval_url = ? WHERE id = ?',
          [order.id, order.approvalUrl, pago.insertId]
        );

        notify.bookingCreated(req, reservaId, fields[0].name);

        res.status(201).json({
            message: 'Reserva creada. Pendiente de seña.',
            reservaId: String(reservaId),
            fieldId: String(fieldNum),
            fieldName: fields[0].name,
            total,
            sena,
            senaPct: SENA_PCT,
            estado: 'pendiente',
            pago: {
                id: String(pago.insertId), monto: sena, provider: paymentMethod,
                providerRef: order.id, approvalUrl: order.approvalUrl,
            },
        });

    } catch (error) {
        if (connection) {
          try { await connection.rollback(); } catch (_) {}
        }
        console.error("Error al crear la reserva:", error);
        res.status(500).json({ message: 'Error interno al crear reserva.' });
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
    // 1. Lectura fuera de tx (sin lock).
    const [rows] = await pool.execute('SELECT * FROM pagos WHERE id = ?', [pagoId]);
    if (rows.length === 0) {
        return res.status(404).json({ message: 'Pago no encontrado.' });
    }
    const pago = rows[0];
    const [resRows] = await pool.execute(
        'SELECT id_usuario_fk AS owner FROM reservas WHERE id = ?', [pago.reserva_id]
    );
    if (resRows.length === 0) {
        return res.status(404).json({ message: 'Reserva no encontrada.' });
    }
    if (String(resRows[0].owner) !== String(req.user.sub) && req.user.role !== 'superadmin') {
        return res.status(403).json({ message: 'No tienes permiso.' });
    }
    if (pago.estado === 'confirmado') {
        return res.status(200).json({ ok: true, yaConfirmado: true, reservaId: String(pago.reserva_id) });
    }
    if (!['paypal', 'stripe'].includes(pago.provider) || !orderId || String(orderId) !== String(pago.provider_ref)) {
        return res.status(400).json({ message: `La orden ${pago.provider} no coincide con el pago.` });
    }
    // 2. Captura/verificación FUERA de transacción (red, hasta 8s).
    let verified = false;
    try {
      if (pago.provider === 'stripe') {
          const session = await stripe.getCheckoutSession(orderId);
          verified = stripe.verifyPaidSession(session, {
              amount: pago.monto,
              reservationId: pago.reserva_id,
          });
      } else {
          let paypalOrder;
          try {
              paypalOrder = await paypal.captureOrder(orderId);
          } catch (captureError) {
              if (captureError.status === 422) paypalOrder = await paypal.getOrder(orderId);
              else throw captureError;
          }
          const unit = paypalOrder.purchase_units?.[0];
          const capture = unit?.payments?.captures?.[0];
          const capturedAmount = capture?.amount?.value;
          const capturedCurrency = capture?.amount?.currency_code;
          const expected = Number(pago.monto).toFixed(2);
          verified = paypalOrder.status === 'COMPLETED' && capture?.status === 'COMPLETED' &&
              capturedCurrency === paypal.currency && capturedAmount === expected &&
              unit.reference_id === String(pago.reserva_id);
      }
    } catch (e) {
        if (e.code === 'PAYPAL_NOT_CONFIGURED') return res.status(503).json({ message: 'PayPal no está configurado.' });
        if (e.code === 'STRIPE_NOT_CONFIGURED') return res.status(503).json({ message: 'Stripe no está configurado.' });
        console.error('Error al confirmar pago:', e);
        return res.status(502).json({ message: 'No se pudo verificar el pago.' });
    }
    if (!verified) {
        return res.status(402).json({ message: `${pago.provider} no confirmó el importe esperado.` });
    }
    // 3. Tx corta solo para UPDATE + re-chequeo idempotente.
    let connection;
    try {
        connection = await pool.getConnection();
        await connection.beginTransaction();
        const [cur] = await connection.execute('SELECT estado FROM pagos WHERE id = ?', [pagoId]);
        if (cur.length > 0 && cur[0].estado === 'confirmado') {
            await connection.commit();
            return res.status(200).json({ ok: true, yaConfirmado: true, reservaId: String(pago.reserva_id) });
        }
        await connection.execute(
            "UPDATE pagos SET estado = 'confirmado', confirmed_at = datetime('now') WHERE id = ? AND estado != 'confirmado'",
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
        console.error('Error al confirmar pago:', e);
        res.status(500).json({ message: 'Error interno al confirmar.' });
    } finally {
        if (connection) connection.release();
    }
});

// ===================================
// RUTA 4: DELETE /api/v1/fields/reservas/:id (cancelar pendiente/error_pago)
// Libera el slot: pendiente/error_pago -> cancelada (dueño o superadmin).
// ===================================
router.delete('/reservas/:id', async (req, res) => {
    try {
        const [rows] = await pool.execute(
          'SELECT id, id_usuario_fk AS owner, estado FROM reservas WHERE id = ? LIMIT 1',
          [req.params.id]
        );
        if (rows.length === 0) return res.status(404).json({ message: 'Reserva no encontrada.' });
        if (String(rows[0].owner) !== String(req.user.sub) && req.user.role !== 'superadmin') {
            return res.status(403).json({ message: 'No tienes permiso.' });
        }
        if (!['pendiente', 'error_pago'].includes(rows[0].estado)) {
            return res.status(409).json({ message: 'Solo se pueden cancelar reservas pendientes.' });
        }
        await pool.execute("UPDATE reservas SET estado = 'cancelada' WHERE id = ?", [req.params.id]);
        res.status(200).json({ ok: true, id: String(req.params.id), estado: 'cancelada' });
    } catch (e) {
        res.status(500).json({ message: 'Error interno.' });
    }
});

// ===================================
// RUTA 5: GET /api/v1/fields/mis-reservas
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
                    (SELECT p.provider FROM pagos p WHERE p.reserva_id = r.id ORDER BY p.id DESC LIMIT 1) AS provider,
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
            provider: r.provider == null ? null : String(r.provider),
            approvalUrl: r.approvalUrl == null ? null : String(r.approvalUrl),
        })));
    } catch (e) {
        res.status(500).json({ message: 'Error interno.' });
    }
});

module.exports = router;
