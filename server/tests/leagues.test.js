/**
 * Tests Fase 3: ligas reales — creación, equipos, fixture, tabla, goleadores.
 */
const fs = require('fs');
const os = require('os');
const path = require('path');

const tmpDb = path.join(
  fs.mkdtempSync(path.join(os.tmpdir(), 'futbol-pro-leagues-')),
  'test.db'
);
process.env.SQLITE_PATH = tmpDb;
process.env.JWT_SECRET = 'test-secret-leagues';
process.env.JWT_EXPIRES_IN = '15m';
process.env.SUPERADMIN_EMAIL = 'rootl@test.com';
process.env.SUPERADMIN_PASSWORD = 'Admin123!';
process.env.SUPERADMIN_NAME = 'Root';

const request = require('supertest');
const app = require('../app');

const stamp = Date.now();
async function register(email, nickname) {
  const res = await request(app).post('/api/v1/auth/register').send({
    email, password: 'Secreta123', nickname,
  });
  if (res.status !== 201) throw new Error(`register ${email}: ${res.status}`);
  return res.body;
}

describe('leagues', () => {
  let adminToken; let p1; let p2; let leagueId;

  beforeAll(async () => {
    const login = await request(app).post('/api/v1/auth/login').send({
      email: 'rootl@test.com', password: 'Admin123!',
    });
    expect(login.status).toBe(200);
    adminToken = login.body.token;
    p1 = await register(`l1${stamp}@t.com`, 'cap1');
    p2 = await register(`l2${stamp}@t.com`, 'cap2');
  });

  test('player no puede crear liga (403)', async () => {
    const res = await request(app)
      .post('/api/v1/leagues')
      .set('Authorization', `Bearer ${p1.token}`)
      .send({ nombre: 'Liga X' });
    expect(res.status).toBe(403);
  });

  test('superadmin crea liga', async () => {
    const res = await request(app)
      .post('/api/v1/leagues')
      .set('Authorization', `Bearer ${adminToken}`)
      .send({ nombre: 'Apertura Test', max_equipos: 4 });
    expect(res.status).toBe(201);
    leagueId = res.body.id;
  });

  test('inscribe 2 equipos con plantilla', async () => {
    for (const [p, name] of [[p1, 'Tigres'], [p2, 'Leones']]) {
      const res = await request(app)
        .post(`/api/v1/leagues/${leagueId}/teams`)
        .set('Authorization', `Bearer ${p.token}`)
        .send({ nombre: name });
      expect(res.status).toBe(201);
      expect(res.body.plantilla).toContain(p.user.id);
    }
    const dup = await request(app)
      .post(`/api/v1/leagues/${leagueId}/teams`)
      .set('Authorization', `Bearer ${p1.token}`)
      .send({ nombre: 'Tigres' });
    expect(dup.status).toBe(409);
  });

  test('fixture requiere 2+ equipos y lo genera el admin', async () => {
    const forbidden = await request(app)
      .post(`/api/v1/leagues/${leagueId}/fixture`)
      .set('Authorization', `Bearer ${p1.token}`)
      .send({});
    expect(forbidden.status).toBe(403);

    const ok = await request(app)
      .post(`/api/v1/leagues/${leagueId}/fixture`)
      .set('Authorization', `Bearer ${adminToken}`)
      .send({ diasEntreJornadas: 7 });
    expect(ok.status).toBe(201);
    expect(ok.body.partidos).toBe(1); // 2 equipos = 1 partido
    expect(ok.body.jornadas).toBe(1);

    const again = await request(app)
      .post(`/api/v1/leagues/${leagueId}/fixture`)
      .set('Authorization', `Bearer ${adminToken}`)
      .send({});
    expect(again.status).toBe(409);
  });

  test('tabla vacía (0 PJ) y goleadores vacíos antes de jugar', async () => {
    const t = await request(app)
      .get(`/api/v1/leagues/${leagueId}/standings`)
      .set('Authorization', `Bearer ${p1.token}`);
    expect(t.status).toBe(200);
    expect(t.body.length).toBe(2);
    expect(t.body[0].gamesPlayed).toBe(0);

    const s = await request(app)
      .get(`/api/v1/leagues/${leagueId}/scorers`)
      .set('Authorization', `Bearer ${p1.token}`);
    expect(s.status).toBe(200);
    expect(s.body).toEqual([]);
  });

  test('resultado en partido de liga alimenta tabla y goleadores', async () => {
    const fx = await request(app)
      .get(`/api/v1/leagues/${leagueId}/fixture`)
      .set('Authorization', `Bearer ${p1.token}`);
    const matchId = fx.body[0].matchId;
    expect(matchId).toBeTruthy();

    const prop = await request(app)
      .post(`/api/v1/matches/${matchId}/result`)
      .set('Authorization', `Bearer ${p1.token}`)
      .send({
        golesA: 2, golesB: 2, ganador: 'empate', mvpId: p1.user.id,
        goleadores: [{ playerId: p1.user.id, goles: 2 }],
      });
    expect(prop.status).toBe(200);

    const conf = await request(app)
      .post(`/api/v1/matches/${matchId}/result/confirm`)
      .set('Authorization', `Bearer ${p2.token}`)
      .send({});
    expect(conf.status).toBe(200);

    const t = await request(app)
      .get(`/api/v1/leagues/${leagueId}/standings`)
      .set('Authorization', `Bearer ${p1.token}`);
    expect(t.body.every((r) => r.points === 1 && r.draws === 1)).toBe(true);

    const s = await request(app)
      .get(`/api/v1/leagues/${leagueId}/scorers`)
      .set('Authorization', `Bearer ${p1.token}`);
    expect(s.body[0].goles).toBe(2);
  });
});
