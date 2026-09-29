/**
 * Tests del panel superadmin: guard de rol y operaciones masivas.
 * Reutiliza la DB temporal de este proceso jest (mismo SQLITE_PATH por
 * archivo; cada archivo usa su propia DB temporal).
 */
const fs = require('fs');
const os = require('os');
const path = require('path');

const tmpDb = path.join(
  fs.mkdtempSync(path.join(os.tmpdir(), 'futbol-pro-admin-')),
  'test.db'
);
process.env.SQLITE_PATH = tmpDb;
process.env.JWT_SECRET = 'test-secret-admin';
process.env.JWT_EXPIRES_IN = '15m';
process.env.SUPERADMIN_EMAIL = 'root@test.com';
process.env.SUPERADMIN_PASSWORD = 'Admin123!';
process.env.SUPERADMIN_NAME = 'Root';

const request = require('supertest');
const app = require('../app');

async function register(email, nickname) {
  const res = await request(app).post('/api/v1/auth/register').send({
    email,
    password: 'Secreta123',
    nickname,
  });
  if (res.status !== 201) throw new Error(`register failed: ${res.status}`);
  return res.body;
}

describe('admin', () => {
  let adminToken;
  let playerToken;

  beforeAll(async () => {
    // El seed crea el superadmin al arrancar (db.js).
    const login = await request(app).post('/api/v1/auth/login').send({
      email: 'root@test.com',
      password: 'Admin123!',
    });
    expect(login.status).toBe(200);
    expect(login.body.role).toBe('superadmin');
    adminToken = login.body.token;

    const p = await register(`p${Date.now()}@test.com`, 'player1');
    playerToken = p.token;
  });

  test('player no entra a /admin (403)', async () => {
    const res = await request(app)
      .get('/api/v1/admin/stats')
      .set('Authorization', `Bearer ${playerToken}`);
    expect(res.status).toBe(403);
  });

  test('sin token no entra (401)', async () => {
    const res = await request(app).get('/api/v1/admin/stats');
    expect(res.status).toBe(401);
  });

  test('superadmin ve stats', async () => {
    const res = await request(app)
      .get('/api/v1/admin/stats')
      .set('Authorization', `Bearer ${adminToken}`);
    expect(res.status).toBe(200);
    expect(res.body).toHaveProperty('users');
    expect(res.body).toHaveProperty('matches');
  });

  test('bulk-role cambia rol y valida valores', async () => {
    const p = await register(`bulk${Date.now()}@test.com`, 'bulkuser');
    const bad = await request(app)
      .put('/api/v1/admin/users/bulk-role')
      .set('Authorization', `Bearer ${adminToken}`)
      .send({ ids: [p.user.id], role: 'dios' });
    expect(bad.status).toBe(400);

    const ok = await request(app)
      .put('/api/v1/admin/users/bulk-role')
      .set('Authorization', `Bearer ${adminToken}`)
      .send({ ids: [p.user.id], role: 'admin' });
    expect(ok.status).toBe(200);
    expect(ok.body.updated).toBeGreaterThanOrEqual(1);
  });

  test('superadmin no puede auto-eliminarse', async () => {
    const me = await request(app)
      .get('/api/v1/auth/me')
      .set('Authorization', `Bearer ${adminToken}`);
    const res = await request(app)
      .delete('/api/v1/admin/users/bulk')
      .set('Authorization', `Bearer ${adminToken}`)
      .send({ ids: [me.body.id] });
    expect(res.status).toBe(400);
  });
});
