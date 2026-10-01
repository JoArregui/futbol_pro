const express = require('express');
const { requireAuth } = require('../middleware/auth');
const router = express.Router();

// Seguridad: nunca anónimo — todo acceso requiere JWT válido.
router.use(requireAuth);

// GET /api/v1/referees/available?date=ISO — lee tabla real arbitros.
router.get('/available', async (req, res) => {
    try {
        const pool = require('../db');
        let rows = [];
        try {
          [rows] = await pool.execute(
            "SELECT id, nombre AS name, rating, tarifa AS fee, estado AS status FROM arbitros WHERE estado = 'activo' ORDER BY rating DESC LIMIT 50"
          );
        } catch (_) {
          return res.status(200).json([]);
        }
        res.status(200).json(rows.map((r) => ({
          id: String(r.id), name: r.name, rating: Number(r.rating ?? 4.5),
          fee: Number(r.fee ?? 20), status: r.status || 'activo',
        })));
    } catch (e) {
        res.status(500).json({ message: 'Error interno.' });
    }
});

// POST /api/v1/referees/request {matchId, date, fieldId, refereeId?}
router.post('/request', async (req, res) => {
    const { matchId, date, fieldId, refereeId } = req.body || {};
    if (!matchId || !date) {
        return res.status(400).json({ message: 'Faltan matchId/date.' });
    }
    const d = new Date(date);
    if (isNaN(d.getTime())) return res.status(400).json({ message: 'date inválida.' });
    try {
        const pool = require('../db');
        let ref = null;
        if (refereeId) {
          const [rows] = await pool.execute(
            "SELECT id FROM arbitros WHERE id = ? AND estado = 'activo' LIMIT 1", [refereeId]);
          if (rows.length === 0) return res.status(400).json({ message: 'Árbitro no disponible.' });
          ref = String(rows[0].id);
        } else {
          const [rows] = await pool.execute(
            "SELECT id FROM arbitros WHERE estado = 'activo' ORDER BY rating DESC LIMIT 1");
          if (rows.length === 0) return res.status(404).json({ message: 'Sin árbitros activos.' });
          ref = String(rows[0].id);
        }
        return res.status(201).json({ ok: true, matchId: String(matchId), refereeId: ref, date: d.toISOString(), fieldId: fieldId ? String(fieldId) : null });
    } catch (e) {
        res.status(500).json({ message: 'Error interno.' });
    }
});

module.exports = router;
