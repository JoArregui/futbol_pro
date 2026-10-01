// Auditoría superadmin (SQLite). Nunca rompe la operación principal:
// si falla el log, solo escribe en consola.
const pool = require('../db');

async function logAudit(req, accion, entidad, entidadId, detalle) {
  try {
    const actorId = req && req.user ? req.user.sub ?? null : null;
    const actorEmail = req && req.user ? req.user.email ?? null : null;
    await pool.execute(
      `INSERT INTO audit_log (actor_id, actor_email, accion, entidad, entidad_id, detalle)
       VALUES (?, ?, ?, ?, ?, ?)`,
      [
        actorId == null ? null : String(actorId),
        actorEmail,
        accion,
        entidad,
        entidadId == null ? null : String(entidadId),
        detalle == null
          ? null
          : typeof detalle === 'string'
            ? detalle.slice(0, 1000)
            : JSON.stringify(detalle).slice(0, 1000),
      ]
    );
  } catch (e) {
    // eslint-disable-next-line no-console
    console.error('audit_log falló (no bloqueante):', e.message);
  }
}

module.exports = { logAudit };
