/**
 * Tests Fase 2: mensajes con imagen en el chat.
 */
const fs = require('fs');
const os = require('os');
const path = require('path');

const tmpDb = path.join(
  fs.mkdtempSync(path.join(os.tmpdir(), 'futbol-pro-chatimg-')),
  'test.db'
);
process.env.SQLITE_PATH = tmpDb;
process.env.JWT_SECRET = 'test-secret-chatimg';
process.env.JWT_EXPIRES_IN = '15m';
process.env.SUPERADMIN_EMAIL = 'rootc@test.com';
process.env.SUPERADMIN_PASSWORD = 'Admin123!';
process.env.SUPERADMIN_NAME = 'Root';

const request = require('supertest');
const app = require('../app');

const stamp = Date.now();

describe('chat images', () => {
  let u1; let u2; let roomId;

  beforeAll(async () => {
    const r1 = await request(app).post('/api/v1/auth/register').send({
      email: `c1${stamp}@t.com`, password: 'Secreta123', nickname: 'chat1',
    });
    const r2 = await request(app).post('/api/v1/auth/register').send({
      email: `c2${stamp}@t.com`, password: 'Secreta123', nickname: 'chat2',
    });
    u1 = r1.body; u2 = r2.body;
    const room = await request(app)
      .post('/api/v1/chats')
      .set('Authorization', `Bearer ${u1.token}`)
      .send({ title: 'Sala foto', type: 'private', memberIds: [u1.user.id, u2.user.id] });
    expect(room.status).toBe(201);
    roomId = room.body.id;
  });

  test('mensaje sin contenido -> 400', async () => {
    const res = await request(app)
      .post(`/api/v1/chats/${roomId}/messages`)
      .set('Authorization', `Bearer ${u1.token}`)
      .send({ senderId: u1.user.id, senderName: 'chat1' });
    expect(res.status).toBe(400);
  });

  test('mensaje con imagen se guarda y se lee con imageUrl', async () => {
    const sent = await request(app)
      .post(`/api/v1/chats/${roomId}/messages`)
      .set('Authorization', `Bearer ${u1.token}`)
      .send({
        senderId: u1.user.id,
        senderName: 'chat1',
        text: 'mira la jugada',
        imageUrl: 'https://example.com/foto.jpg',
      });
    expect(sent.status).toBe(201);

    const list = await request(app)
      .get(`/api/v1/chats/${roomId}/messages`)
      .set('Authorization', `Bearer ${u1.token}`);
    expect(list.status).toBe(200);
    const found = list.body.find((m) => m.id === sent.body.id);
    expect(found).toBeTruthy();
    expect(found.imageUrl).toBe('https://example.com/foto.jpg');
  });
});
