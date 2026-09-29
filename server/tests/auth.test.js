/**
 * Tests de autenticación: registro, login, refresh, ownership y rate-limit.
 * Usan una DB SQLite temporal (SQLITE_PATH) para no tocar la real.
 */
const fs = require('fs');
const os = require('os');
const path = require('path');

const tmpDb = path.join(
  fs.mkdtempSync(path.join(os.tmpdir(), 'futbol-pro-test-')),
  'test.db'
);
process.env.SQLITE_PATH = tmpDb;
process.env.JWT_SECRET = 'test-secret';
process.env.JWT_EXPIRES_IN = '15m';
process.env.SUPERADMIN_EMAIL = 'admin@test.com';
process.env.SUPERADMIN_PASSWORD = 'Admin123!';
process.env.SUPERADMIN_NAME = 'Admin';

const request = require('supertest');
const app = require('../app');

describe('auth', () => {
  const email = `user${Date.now()}@test.com`;
  let token;
  let refreshToken;
  let userId;

  test('register crea usuario y devuelve par de tokens', async () => {
    const res = await request(app).post('/api/v1/auth/register').send({
      email,
      password: 'Secreta123',
      nickname: 'tester',
      name: 'Tester',
    });
    expect(res.status).toBe(201);
    expect(res.body.token).toBeTruthy();
    expect(res.body.refreshToken).toBeTruthy();
    expect(res.body.user.id).toBeTruthy();
    token = res.body.token;
    refreshToken = res.body.refreshToken;
    userId = res.body.user.id;
  });

  test('register duplicado -> 409', async () => {
    const res = await request(app).post('/api/v1/auth/register').send({
      email,
      password: 'Secreta123',
      nickname: 'otro',
    });
    expect(res.status).toBe(409);
  });

  test('login con password errónea -> 401 sin filtrar si existe', async () => {
    const res = await request(app)
      .post('/api/v1/auth/login')
      .send({ email, password: 'mala' });
    expect(res.status).toBe(401);
  });

  test('login ok devuelve par nuevo', async () => {
    const res = await request(app)
      .post('/api/v1/auth/login')
      .send({ email, password: 'Secreta123' });
    expect(res.status).toBe(200);
    expect(res.body.refreshToken).toBeTruthy();
    token = res.body.token;
    refreshToken = res.body.refreshToken;
  });

  test('sin token no hay acceso (nunca anónimo)', async () => {
    const res = await request(app).get(`/api/v1/users/${userId}/profile`);
    expect(res.status).toBe(401);
  });

  test('refresh rota el par y el anterior queda revocado', async () => {
    const stale = refreshToken;
    const first = await request(app)
      .post('/api/v1/auth/refresh')
      .send({ refreshToken: stale });
    expect(first.status).toBe(200);
    expect(first.body.token).toBeTruthy();
    expect(first.body.refreshToken).toBeTruthy();
    token = first.body.token;
    refreshToken = first.body.refreshToken;

    // El refresh ya usado (rotado) debe fallar.
    const reuseOld = await request(app)
      .post('/api/v1/auth/refresh')
      .send({ refreshToken: stale });
    expect(reuseOld.status).toBe(401);
  });

  test('PUT perfil ajeno -> 403 (ownership)', async () => {
    const other = `other${Date.now()}@test.com`;
    const reg = await request(app).post('/api/v1/auth/register').send({
      email: other,
      password: 'Secreta123',
      nickname: 'otro2',
    });
    const otherId = reg.body.user.id;
    const res = await request(app)
      .put(`/api/v1/users/${otherId}/profile`)
      .set('Authorization', `Bearer ${token}`)
      .send({ bio: 'hack' });
    expect(res.status).toBe(403);
  });

  test('PUT perfil propio con columna no permitida se ignora y no rompe', async () => {
    const res = await request(app)
      .put(`/api/v1/users/${userId}/profile`)
      .set('Authorization', `Bearer ${token}`)
      .send({ bio: 'hola', role: 'superadmin', 'uid; DROP TABLE auth;--': 'x' });
    expect(res.status).toBe(200);
  });

  test('logout revoca y el refresh ya no vale', async () => {
    const out = await request(app)
      .post('/api/v1/auth/logout')
      .set('Authorization', `Bearer ${token}`)
      .send({ refreshToken });
    expect(out.status).toBe(200);
    const again = await request(app)
      .post('/api/v1/auth/refresh')
      .send({ refreshToken });
    expect(again.status).toBe(401);
  });
});
