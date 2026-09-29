/**
 * Tests Fase 2: propuesta/confirmación de resultados, ownership,
 * reputación (jugados/victorias/MVP) y no-shows.
 */
const fs = require('fs');
const os = require('os');
const path = require('path');

const tmpDb = path.join(
  fs.mkdtempSync(path.join(os.tmpdir(), 'futbol-pro-matches-')),
  'test.db'
);
process.env.SQLITE_PATH = tmpDb;
process.env.JWT_SECRET = 'test-secret-matches';
process.env.JWT_EXPIRES_IN = '15m';
process.env.SUPERADMIN_EMAIL = 'rootm@test.com';
process.env.SUPERADMIN_PASSWORD = 'Admin123!';
process.env.SUPERADMIN_NAME = 'Root';

const request = require('supertest');
const app = require('../app');

const stamp = Date.now();
async function register(email, nickname) {
  const res = await request(app).post('/api/v1/auth/register').send({
    email,
    password: 'Secreta123',
    nickname,
  });
  if (res.status !== 201) throw new Error(`register ${email}: ${res.status}`);
  return res.body;
}

describe('match results', () => {
  let a; let b; let outsider;
  let matchId;

  beforeAll(async () => {
    a = await register(`ra${stamp}@t.com`, 'capA');
    b = await register(`rb${stamp}@t.com`, 'capB');
    outsider = await register(`ro${stamp}@t.com`, 'fuera');

    const created = await request(app)
      .post('/api/v1/matches')
      .set('Authorization', `Bearer ${a.token}`)
      .send({ fieldId: 1, scheduledTime: new Date(Date.now() + 86400000).toISOString() });
    expect(created.status).toBe(201);
    matchId = created.body.id;

    // El creador (a) queda apuntado automáticamente al crear el partido.
    const j = await request(app)
      .post(`/api/v1/matches/${matchId}/join`)
      .set('Authorization', `Bearer ${b.token}`)
      .send({ playerId: b.user.id });
    expect(j.status).toBe(200);
  });

  test('no participante no puede proponer (403)', async () => {
    const res = await request(app)
      .post(`/api/v1/matches/${matchId}/result`)
      .set('Authorization', `Bearer ${outsider.token}`)
      .send({ golesA: 1, golesB: 0 });
    expect(res.status).toBe(403);
  });

  test('goles inválidos -> 400', async () => {
    const res = await request(app)
      .post(`/api/v1/matches/${matchId}/result`)
      .set('Authorization', `Bearer ${a.token}`)
      .send({ golesA: -1, golesB: 200 });
    expect(res.status).toBe(400);
  });

  test('MVP no participante -> 400', async () => {
    const res = await request(app)
      .post(`/api/v1/matches/${matchId}/result`)
      .set('Authorization', `Bearer ${a.token}`)
      .send({ golesA: 2, golesB: 1, mvpId: outsider.user.id });
    expect(res.status).toBe(400);
  });

  test('propuesta válida queda en estado propuesta', async () => {
    const res = await request(app)
      .post(`/api/v1/matches/${matchId}/result`)
      .set('Authorization', `Bearer ${a.token}`)
      .send({
        golesA: 3,
        golesB: 1,
        ganador: 'A',
        mvpId: b.user.id,
        teamAIds: [a.user.id],
        teamBIds: [b.user.id],
        goleadores: [{ playerId: a.user.id, goles: 2 }],
      });
    expect(res.status).toBe(200);
    expect(res.body.estado).toBe('propuesta');
    expect(res.body.golesA).toBe(3);
  });

  test('el proponente no puede auto-confirmar (403)', async () => {
    const res = await request(app)
      .post(`/api/v1/matches/${matchId}/result/confirm`)
      .set('Authorization', `Bearer ${a.token}`)
      .send({});
    expect(res.status).toBe(403);
  });

  test('otro participante confirma y aplica reputación', async () => {
    const res = await request(app)
      .post(`/api/v1/matches/${matchId}/result/confirm`)
      .set('Authorization', `Bearer ${b.token}`)
      .send({});
    expect(res.status).toBe(200);
    expect(res.body.estado).toBe('confirmado');

    const detail = await request(app)
      .get(`/api/v1/matches/${matchId}`)
      .set('Authorization', `Bearer ${a.token}`);
    expect(detail.status).toBe(200);
    expect(detail.body.status).toBe('FINALIZADO');
    expect(detail.body.golesA).toBe(3);
    expect(detail.body.participants.length).toBe(2);
    const pa = detail.body.participants.find((p) => p.id === a.user.id);
    expect(pa.played).toBeGreaterThanOrEqual(1);
    expect(pa.wins).toBeGreaterThanOrEqual(1); // ganador A
    const pb = detail.body.participants.find((p) => p.id === b.user.id);
    expect(pb.mvpCount).toBeGreaterThanOrEqual(1);
  });

  test('resultado confirmado no se puede re-proponer (409)', async () => {
    const res = await request(app)
      .post(`/api/v1/matches/${matchId}/result`)
      .set('Authorization', `Bearer ${b.token}`)
      .send({ golesA: 0, golesB: 5 });
    expect(res.status).toBe(409);
  });

  test('no-show suma contador', async () => {
    const res = await request(app)
      .post(`/api/v1/matches/${matchId}/no-show`)
      .set('Authorization', `Bearer ${a.token}`)
      .send({ playerId: b.user.id });
    expect(res.status).toBe(200);
    expect(res.body.noShows).toBeGreaterThanOrEqual(1);
  });

  test('no-show de no participante -> 404', async () => {
    const res = await request(app)
      .post(`/api/v1/matches/${matchId}/no-show`)
      .set('Authorization', `Bearer ${a.token}`)
      .send({ playerId: outsider.user.id });
    expect(res.status).toBe(404);
  });
});
