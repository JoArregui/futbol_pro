/** Health con chequeo de DB y 404 JSON. */
const fs = require('fs');
const os = require('os');
const path = require('path');

const tmpDb = path.join(
  fs.mkdtempSync(path.join(os.tmpdir(), 'futbol-pro-health-')),
  'test.db'
);
process.env.SQLITE_PATH = tmpDb;
process.env.JWT_SECRET = 'test-secret-health';

const request = require('supertest');
const app = require('../app');

describe('platform', () => {
  test('GET /health responde ok + db up', async () => {
    const res = await request(app).get('/health');
    expect(res.status).toBe(200);
    expect(res.body.status).toBe('ok');
    expect(res.body.db).toBe('up');
  });

  test('ruta inexistente -> 404 JSON', async () => {
    const res = await request(app).get('/api/v1/no-existe');
    expect(res.status).toBe(404);
    expect(res.body.message).toBeTruthy();
  });
});
