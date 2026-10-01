// Notificaciones en tiempo real (Socket.IO, sin dependencias nuevas).
// 6 triggers: partido creado, unido, marcador registrado, marcador validado,
// reserva creada y convocatoria a plantilla. El cliente las muestra como
// notificación local (ver NotificationService.showLocal).
// Puente FCM: si FCM_ENABLED=true, además se registra el payload listo para
// publicar en topics (match_<id>, team_<id>, user_<id>, futbolpro_all).
// El envío real requiere firebase-admin + cuenta de servicio (fase con
// visto bueno del cliente); hasta entonces el transporte es Socket.IO.
function fcmBridge(event, payload, topic) {
  if (process.env.FCM_ENABLED === 'true') {
    // eslint-disable-next-line no-console
    console.log(`[FCM:stub] topic=${topic} event=${event}`, payload.title || '');
  }
}

function ioOf(req) {
  try {
    return req && req.app ? req.app.get('io') : null;
  } catch (_) {
    return null;
  }
}

function emit(io, event, payload) {
  try {
    if (io) io.emit(event, payload);
  } catch (e) {
    // eslint-disable-next-line no-console
    console.error('notify emit falló (no bloqueante):', e.message);
  }
}

function toUser(io, userId, event, payload) {
  try {
    if (io) io.to(`user_${userId}`).emit(event, payload);
  } catch (e) {
    // eslint-disable-next-line no-console
    console.error('notify toUser falló (no bloqueante):', e.message);
  }
}

module.exports = {
  matchCreated(req, match) {
    const payload = {
      matchId: String(match.id ?? match.insertId ?? ''),
      title: 'Nuevo partido disponible',
      body: `${match.title || 'Amistoso'} · ${match.time || match.scheduledTime || ''}`,
    };
    // Antes: io.emit global (cualquiera lo veía). Ahora: solo sala del partido si existe,
    // si no, a los usuarios implicados. Sin broadcast global.
    const io = ioOf(req);
    if (io && payload.matchId) {
      io.to(`match_${payload.matchId}`).emit('match_created', payload);
    }
    fcmBridge('match_created', payload, 'futbolpro_all');
  },
  matchJoined(req, matchId, playerId) {
    const io = ioOf(req);
    if (io) {
      io.to(`match_${matchId}`).emit('match_updated', {
        matchId: String(matchId),
        title: 'Nuevo jugador apuntado',
        body: `Jugador ${playerId} se unió al partido ${matchId}`,
      });
    }
  },
  resultProposed(req, matchId, golesA, golesB) {
    const io = ioOf(req);
    if (io) {
      io.to(`match_${matchId}`).emit('match_result', {
        matchId: String(matchId),
        estado: 'pendiente',
        title: 'Marcador pendiente de validación',
        body: `${golesA} - ${golesB} en el partido ${matchId}. Un compañero debe validarlo.`,
      });
    }
  },
  resultConfirmed(req, matchId, golesA, golesB) {
    const payload = {
      matchId: String(matchId),
      estado: 'validado',
      title: 'Marcador validado',
      body: `Resultado final ${golesA} - ${golesB} en el partido ${matchId}.`,
    };
    const io = ioOf(req);
    if (io) io.to(`match_${matchId}`).emit('match_result', payload);
    fcmBridge('match_result', payload, `match_${matchId}`);
  },
  bookingCreated(req, reservaId, fieldName) {
    const io = ioOf(req);
    const me = req && req.user ? String(req.user.sub) : null;
    const payload = {
      reservaId: String(reservaId),
      title: 'Reserva creada',
      body: `${fieldName || 'Campo'}: completa la seña para confirmarla.`,
    };
    if (me) toUser(io, me, 'booking', payload);
    // Sin broadcast global: solo al dueño (arriba). Nada de emit(io,...).
  },
  squadAdded(req, teamId, playerId) {
    const payload = {
      teamId: String(teamId),
      title: 'Te añadieron a un equipo',
      body: `Fuiste convocado al equipo ${teamId}. Revísalo en la app.`,
    };
    toUser(ioOf(req), playerId, 'squad', payload);
    fcmBridge('squad', payload, `user_${playerId}`);
  },
};
