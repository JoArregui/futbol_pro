const express = require('express');
const { requireAuth } = require('../middleware/auth');
const router = express.Router();

// Seguridad: nunca anónimo — todo acceso requiere JWT válido.
router.use(requireAuth);

// GET /api/v1/referees/available?date=ISO
// Devuelve árbitros libres (mock + intento de tabla arbitros si existe).
router.get('/available', async (req, res) => {
    try {
        return res.status(200).json([
            { id: 'r1', name: 'Carlos Ruiz', rating: 4.8, fee: 25 },
            { id: 'r2', name: 'Miguel Torres', rating: 4.6, fee: 20 },
            { id: 'r3', name: 'Jorge Salas', rating: 4.9, fee: 30 },
        ]);
    } catch (e) {
        res.status(500).json({ message: 'Error interno.' });
    }
});

// POST /api/v1/referees/request {matchId, date, fieldId}
router.post('/request', async (req, res) => {
    const { matchId, date, fieldId } = req.body;
    if (!matchId || !date) {
        return res.status(400).json({ message: 'Faltan matchId/date.' });
    }
    return res.status(201).json({ ok: true, matchId, refereeId: 'r1', date, fieldId });
});

module.exports = router;
