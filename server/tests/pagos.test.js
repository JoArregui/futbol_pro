/**
 * Tests Fase 3: economía de reservas — coste servidor, seña, confirmación,
 * mis-reservas y división de cuenta.
 */
const fs = require('fs');
const os = require('os');
const path = require('path');

const tmpDb = path.join(
  fs.mkdtempSync(path.join(os.tmpdir(), 'futbol-pro-pagos-')),
  'test.db'
);
process.env.SQLITE_PATH = tmpDb;
process.env.JWT_SECRET = 'test-secret-pagos';
process.env.JWT_EXPIRES_IN = '15m';
process.env.SUPERADMIN_EMAIL = 'rootp@test.com';
process.env.SUPERADMIN_PASSWORD = 'Admin123!';
process.env.SUPERADMIN_NAME = 'Root';
process.env.PAYPAL_CLIENT_ID = 'test-client';
process.env.PAYPAL_CLIENT_SECRET = 'test-secret';
process.env.PAYPAL_ENVIRONMENT = 'sandbox';

const paypalOrders = new Map();
let nextOrder = 1;
global.fetch = jest.fn(async (url, options = {}) => {
  if (url.endsWith('/v1/oauth2/token')) {
    return { ok: true, status: 200, json: async () => ({ access_token: 'test-token' }) };
  }
  if (url.endsWith('/v2/checkout/orders')) {
    const payload = JSON.parse(options.body);
    const id = `TEST-ORDER-${nextOrder++}`;
    paypalOrders.set(id, payload);
    return { ok: true, status: 201, json: async () => ({
      id,
      links: [{ rel: 'approve', href: `https://www.sandbox.paypal.com/checkoutnow?token=${id}` }],
    }) };
  }
  if (url.includes('/capture')) {
    const id = url.split('/').slice(-2, -1)[0];
    const payload = paypalOrders.get(id);
    return { ok: true, status: 201, json: async () => ({
      id, status: 'COMPLETED', purchase_units: [{
        reference_id: payload.purchase_units[0].reference_id,
        payments: { captures: [{ status: 'COMPLETED', amount: payload.purchase_units[0].amount }] },
      }],
    }) };
  }
  return { ok: false, status: 404, json: async () => ({}) };
});

const request = require('supertest');
const app = require('../app');

const stamp = Date.now();

describe('pagos', () => {
  let token; let userId;

  beforeAll(async () => {
    const r = await request(app).post('/api/v1/auth/register').send({
      email: `pg${stamp}@t.com`, password: 'Secreta123', nickname: 'pagador',
    });
    token = r.body.token;
    userId = r.body.user.id;
  });

  test('reserva calcula coste en servidor e ignora total del cliente', async () => {
    const start = new Date(Date.now() + 86400000).toISOString();
    const end = new Date(Date.now() + 2 * 86400000).toISOString();
    const res = await request(app)
      .post('/api/v1/fields/1/reserve')
      .set('Authorization', `Bearer ${token}`)
      .send({ startTime: start, endTime: end, totalCost: 1 });
    // Campo Central: 50/h × 24h = 1200 (no 1)
    expect(res.status).toBe(201);
    expect(res.body.total).toBe(1200);
    expect(res.body.sena).toBe(240);
    expect(res.body.estado).toBe('pendiente');
    expect(res.body.pago.providerRef).toMatch(/^TEST-ORDER-/);
  });

  test('solapamiento -> 409', async () => {
    const start = new Date(Date.now() + 86400000).toISOString();
    const end = new Date(Date.now() + 2 * 86400000).toISOString();
    const res = await request(app)
      .post('/api/v1/fields/1/reserve')
      .set('Authorization', `Bearer ${token}`)
      .send({ startTime: start, endTime: end });
    expect(res.status).toBe(409);
  });

  test('confirmar seña pasa a senada (idempotente)', async () => {
    const start = new Date(Date.now() + 3 * 86400000).toISOString();
    const end = new Date(Date.now() + 3 * 86400000 + 3600000).toISOString();
    const r = await request(app)
      .post('/api/v1/fields/2/reserve')
      .set('Authorization', `Bearer ${token}`)
      .send({ startTime: start, endTime: end });
    const pagoId = r.body.pago.id;

    const c1 = await request(app)
      .post(`/api/v1/fields/pagos/${pagoId}/confirm`)
      .set('Authorization', `Bearer ${token}`)
      .send({ orderId: r.body.pago.providerRef });
    expect(c1.status).toBe(200);
    expect(c1.body.estado).toBe('senada');

    const c2 = await request(app)
      .post(`/api/v1/fields/pagos/${pagoId}/confirm`)
      .set('Authorization', `Bearer ${token}`)
      .send({ orderId: r.body.pago.providerRef });
    expect(c2.body.yaConfirmado).toBe(true);
  });

  test('otro usuario no confirma mi pago (403)', async () => {
    const other = await request(app).post('/api/v1/auth/register').send({
      email: `pg2${stamp}@t.com`, password: 'Secreta123', nickname: 'otro',
    });
    const start = new Date(Date.now() + 4 * 86400000).toISOString();
    const end = new Date(Date.now() + 4 * 86400000 + 3600000).toISOString();
    const r = await request(app)
      .post('/api/v1/fields/3/reserve')
      .set('Authorization', `Bearer ${token}`)
      .send({ startTime: start, endTime: end });
    const res = await request(app)
      .post(`/api/v1/fields/pagos/${r.body.pago.id}/confirm`)
      .set('Authorization', `Bearer ${other.body.token}`)
      .send({ orderId: r.body.pago.providerRef });
    expect(res.status).toBe(403);
  });

  test('mis-reservas lista las mías', async () => {
    const res = await request(app)
      .get('/api/v1/fields/mis-reservas')
      .set('Authorization', `Bearer ${token}`);
    expect(res.status).toBe(200);
    expect(res.body.length).toBeGreaterThanOrEqual(3);
    expect(res.body[0]).toHaveProperty('pagoEstado');
  });

  test('split divide el coste del partido', async () => {
    const created = await request(app)
      .post('/api/v1/matches')
      .set('Authorization', `Bearer ${token}`)
      .send({
        fieldId: 1,
        scheduledTime: new Date(Date.now() + 86400000).toISOString(),
        costeTotal: 100,
      });
    const other = await request(app).post('/api/v1/auth/register').send({
      email: `pg3${stamp}@t.com`, password: 'Secreta123', nickname: 'tercero',
    });
    await request(app)
      .post(`/api/v1/matches/${created.body.id}/join`)
      .set('Authorization', `Bearer ${other.body.token}`)
      .send({});
    const split = await request(app)
      .get(`/api/v1/matches/${created.body.id}/split`)
      .set('Authorization', `Bearer ${token}`);
    expect(split.status).toBe(200);
    expect(split.body.total).toBe(100);
    expect(split.body.perPerson).toBe(50);
    expect(split.body.participants).toBe(2);
    void userId;
  });
});
