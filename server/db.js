require('dotenv').config();
const sqlite3 = require('sqlite3');
const { open } = require('sqlite');
const path = require('path');

const DB_PATH = process.env.SQLITE_PATH || path.join(__dirname, 'futbol_pro.db');

let dbPromise = null;

function getDb() {
  if (!dbPromise) {
    dbPromise = (async () => {
      const db = await open({ filename: DB_PATH, driver: sqlite3.Database });
      await db.exec('PRAGMA foreign_keys = ON;');
      await db.exec('PRAGMA journal_mode = WAL;');

      // === SCHEMA ===
      await db.exec(`
        CREATE TABLE IF NOT EXISTS auth (
          id_auth INTEGER PRIMARY KEY AUTOINCREMENT,
          email TEXT UNIQUE NOT NULL,
          password TEXT NOT NULL,
          role TEXT DEFAULT 'player'
        );
        CREATE TABLE IF NOT EXISTS perfiles (
          uid INTEGER PRIMARY KEY,
          email TEXT NOT NULL,
          apodo TEXT,
          nombre TEXT,
          url_avatar TEXT,
          bio TEXT,
          partidos_jugados INTEGER DEFAULT 0,
          victorias INTEGER DEFAULT 0,
          rating REAL DEFAULT 0,
          fecha_creacion TEXT,
          FOREIGN KEY(uid) REFERENCES auth(id_auth) ON DELETE CASCADE
        );
        CREATE TABLE IF NOT EXISTS chats (
          id_chat INTEGER PRIMARY KEY AUTOINCREMENT,
          nombre TEXT NOT NULL,
          tipo TEXT DEFAULT 'private',
          related_entity_id TEXT,
          ultimo_mensaje TEXT,
          ultima_actividad TEXT
        );
        CREATE TABLE IF NOT EXISTS chats_miembros (
          id_chat_fk INTEGER NOT NULL,
          id_miembro_fk INTEGER NOT NULL,
          ultimo_leido_timestamp TEXT,
          PRIMARY KEY(id_chat_fk, id_miembro_fk),
          FOREIGN KEY(id_chat_fk) REFERENCES chats(id_chat) ON DELETE CASCADE,
          FOREIGN KEY(id_miembro_fk) REFERENCES auth(id_auth) ON DELETE CASCADE
        );
        CREATE TABLE IF NOT EXISTS mensajes (
          id_mensaje TEXT PRIMARY KEY,
          id_chat_fk INTEGER NOT NULL,
          id_emisor_fk INTEGER NOT NULL,
          nombre_emisor TEXT,
          texto TEXT NOT NULL,
          timestamp TEXT NOT NULL,
          FOREIGN KEY(id_chat_fk) REFERENCES chats(id_chat) ON DELETE CASCADE
        );
        CREATE INDEX IF NOT EXISTS idx_mensajes_chat ON mensajes(id_chat_fk, timestamp);
        CREATE TABLE IF NOT EXISTS campos (
          id_campo INTEGER PRIMARY KEY AUTOINCREMENT,
          nombre TEXT NOT NULL,
          tarifa_horaria REAL DEFAULT 50,
          capacidad INTEGER DEFAULT 22
        );
        CREATE TABLE IF NOT EXISTS reservas (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          id_campo_fk INTEGER NOT NULL,
          id_usuario_fk INTEGER NOT NULL,
          hora_inicio TEXT NOT NULL,
          hora_fin TEXT NOT NULL,
          coste_total REAL,
          fecha_reserva TEXT,
          FOREIGN KEY(id_campo_fk) REFERENCES campos(id_campo),
          FOREIGN KEY(id_usuario_fk) REFERENCES auth(id_auth)
        );
        CREATE TABLE IF NOT EXISTS partidos (
          id_partido INTEGER PRIMARY KEY AUTOINCREMENT,
          id_campo_fk INTEGER,
          hora_inicio TEXT,
          fecha_creacion TEXT,
          estado TEXT DEFAULT 'PENDIENTE',
          tipo TEXT DEFAULT 'AMISTOSO'
        );
        CREATE TABLE IF NOT EXISTS participantes (
          id_partido_fk INTEGER NOT NULL,
          id_jugador_fk INTEGER NOT NULL,
          fecha_registro TEXT,
          PRIMARY KEY(id_partido_fk, id_jugador_fk),
          FOREIGN KEY(id_partido_fk) REFERENCES partidos(id_partido) ON DELETE CASCADE
        );
        CREATE TABLE IF NOT EXISTS equipos (
          id_equipo INTEGER PRIMARY KEY AUTOINCREMENT,
          nombre TEXT,
          id_liga_fk INTEGER
        );
        CREATE TABLE IF NOT EXISTS resultados_partidos (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          id_liga_fk INTEGER,
          id_equipo_local INTEGER,
          id_equipo_visitante INTEGER,
          resultado_local INTEGER,
          resultado_visitante INTEGER
        );
        -- Resultado propuesto/confirmado de un partido amistoso
        CREATE TABLE IF NOT EXISTS resultados (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          match_id INTEGER UNIQUE NOT NULL,
          goles_a INTEGER NOT NULL DEFAULT 0,
          goles_b INTEGER NOT NULL DEFAULT 0,
          ganador TEXT NOT NULL DEFAULT 'empate',
          goleadores TEXT NOT NULL DEFAULT '[]',
          team_a_ids TEXT NOT NULL DEFAULT '[]',
          team_b_ids TEXT NOT NULL DEFAULT '[]',
          mvp_id INTEGER NULL,
          propuesto_por INTEGER NOT NULL,
          estado TEXT NOT NULL DEFAULT 'propuesta',
          created_at TEXT DEFAULT (datetime('now')),
          confirmed_at TEXT NULL,
          FOREIGN KEY(match_id) REFERENCES partidos(id_partido) ON DELETE CASCADE
        );
        -- Fase 3: ligas reales (adiós mocks)
        CREATE TABLE IF NOT EXISTS ligas (
          id_liga INTEGER PRIMARY KEY AUTOINCREMENT,
          nombre TEXT NOT NULL,
          descripcion TEXT DEFAULT '',
          fecha_inicio TEXT,
          max_equipos INTEGER DEFAULT 12,
          estado TEXT DEFAULT 'open',
          created_by INTEGER NULL,
          fecha_creacion TEXT DEFAULT (datetime('now'))
        );
        CREATE TABLE IF NOT EXISTS liga_equipos (
          id_equipo INTEGER PRIMARY KEY AUTOINCREMENT,
          id_liga_fk INTEGER NOT NULL,
          nombre TEXT NOT NULL,
          capitan_id INTEGER NULL,
          plantilla TEXT NOT NULL DEFAULT '[]',
          fecha TEXT DEFAULT (datetime('now')),
          UNIQUE(id_liga_fk, nombre),
          FOREIGN KEY(id_liga_fk) REFERENCES ligas(id_liga) ON DELETE CASCADE
        );
        CREATE TABLE IF NOT EXISTS liga_fixture (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          id_liga_fk INTEGER NOT NULL,
          jornada INTEGER NOT NULL,
          equipo_a_id INTEGER NOT NULL,
          equipo_b_id INTEGER NOT NULL,
          match_id INTEGER NULL,
          FOREIGN KEY(id_liga_fk) REFERENCES ligas(id_liga) ON DELETE CASCADE,
          FOREIGN KEY(match_id) REFERENCES partidos(id_partido) ON DELETE SET NULL
        );
        -- Pagos de reservas; la confirmación se valida contra el proveedor.
        CREATE TABLE IF NOT EXISTS pagos (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          reserva_id INTEGER NOT NULL,
          monto REAL NOT NULL,
          concepto TEXT NOT NULL DEFAULT 'sena',
          estado TEXT NOT NULL DEFAULT 'pendiente',
          provider TEXT NOT NULL DEFAULT 'paypal',
          provider_ref TEXT NULL,
          approval_url TEXT NULL,
          created_at TEXT DEFAULT (datetime('now')),
          confirmed_at TEXT NULL,
          FOREIGN KEY(reserva_id) REFERENCES reservas(id) ON DELETE CASCADE
        );
        CREATE TABLE IF NOT EXISTS refresh_tokens (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          user_id INTEGER NOT NULL,
          token_hash TEXT UNIQUE NOT NULL,
          expires_at TEXT NOT NULL,
          revoked INTEGER DEFAULT 0,
          created_at TEXT DEFAULT (datetime('now')),
          FOREIGN KEY(user_id) REFERENCES auth(id_auth) ON DELETE CASCADE
        );
        CREATE INDEX IF NOT EXISTS idx_refresh_user ON refresh_tokens(user_id);
        -- Auditoría superadmin: quién hizo qué y cuándo (SQLite, sin migración externa).
        CREATE TABLE IF NOT EXISTS audit_log (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          actor_id INTEGER NULL,
          actor_email TEXT NULL,
          accion TEXT NOT NULL,
          entidad TEXT NOT NULL,
          entidad_id TEXT NULL,
          detalle TEXT NULL,
          created_at TEXT DEFAULT (datetime('now'))
        );
        CREATE INDEX IF NOT EXISTS idx_audit_fecha ON audit_log(created_at);
        CREATE INDEX IF NOT EXISTS idx_audit_entidad ON audit_log(entidad, entidad_id);
      `);

      // Migración de instalaciones existentes.
      try {
        const paymentCols = await db.all('PRAGMA table_info(pagos)');
        if (!paymentCols.some(c => c.name === 'approval_url')) {
          await db.exec('ALTER TABLE pagos ADD COLUMN approval_url TEXT NULL');
        }
      } catch (_) { /* schema ya actualizado */ }

      // Migración: columna role si la DB ya existía sin ella
      try {
        const cols = await db.all("PRAGMA table_info(auth)");
        if (!cols.some(c => c.name === 'role')) {
          await db.exec("ALTER TABLE auth ADD COLUMN role TEXT DEFAULT 'player'");
        }
      } catch (_) { /* noop */ }

      // Migración Fase 2: marcador en partidos, reputación en perfiles,
      // adjuntos en mensajes (tablas ya existentes no se recrean).
      try {
        const ensure = async (table, col, ddl) => {
          const cols = await db.all(`PRAGMA table_info(${table})`);
          if (!cols.some(c => c.name === col)) {
            await db.exec(`ALTER TABLE ${table} ADD COLUMN ${ddl}`);
          }
        };
        await ensure('partidos', 'goles_local', "goles_local INTEGER NULL");
        await ensure('partidos', 'goles_visitante', "goles_visitante INTEGER NULL");
        await ensure('partidos', 'mvp_id', "mvp_id INTEGER NULL");
        await ensure('partidos', 'id_liga_fk', "id_liga_fk INTEGER NULL");
        await ensure('partidos', 'equipo_a_id', "equipo_a_id INTEGER NULL");
        await ensure('partidos', 'equipo_b_id', "equipo_b_id INTEGER NULL");
        await ensure('partidos', 'jornada', "jornada INTEGER NULL");
        await ensure('partidos', 'coste_total', "coste_total REAL NULL");
        await ensure('reservas', 'estado', "estado TEXT DEFAULT 'pendiente'");
        await ensure('reservas', 'sena_monto', "sena_monto REAL NULL");
        await ensure('perfiles', 'mvp_count', "mvp_count INTEGER DEFAULT 0");
        await ensure('perfiles', 'no_show_count', "no_show_count INTEGER DEFAULT 0");
        await ensure('perfiles', 'posicion', "posicion TEXT NULL");
        await ensure('perfiles', 'pierna', "pierna TEXT NULL");
        await ensure('perfiles', 'disponible', "disponible INTEGER DEFAULT 1");
        await ensure('mensajes', 'image_url', "image_url TEXT NULL");
      } catch (_) { /* noop */ }

      // Seed campos si vacío
      const row = await db.get('SELECT COUNT(*) as c FROM campos');
      if (row.c === 0) {
        await db.exec(`INSERT INTO campos (nombre, tarifa_horaria, capacidad) VALUES
          ('Campo Central', 50, 22),
          ('Campo Norte', 45, 14),
          ('Campo Sur - 7', 30, 14),
          ('Cancha Techada', 60, 10)`);
        console.log('🌱 Seed: campos insertados');
      }

      // Seed superadmin solo si .env lo define explícitamente (sin default).
      try {
        const adminEmail = (process.env.SUPERADMIN_EMAIL || '').trim();
        const adminPass = process.env.SUPERADMIN_PASSWORD || '';
        const adminName = process.env.SUPERADMIN_NAME || 'SuperAdmin';
        if (!adminEmail || !adminPass) {
          if (process.env.NODE_ENV === 'production') {
            console.warn('⚠️ Sin SUPERADMIN_* en prod: no se crea superadmin seed.');
          }
        } else {
        const existing = await db.get('SELECT id_auth FROM auth WHERE email = ?', [adminEmail]);
        if (!existing) {
          const bcrypt = require('bcryptjs');
          const hash = await bcrypt.hash(adminPass, 10);
          const r = await db.run('INSERT INTO auth (email, password, role) VALUES (?, ?, ?)', [adminEmail, hash, 'superadmin']);
          await db.run(
            "INSERT INTO perfiles (uid, email, apodo, nombre, partidos_jugados, victorias, rating, fecha_creacion) VALUES (?, ?, ?, ?, 0, 0, 0, datetime('now'))",
            [r.lastID, adminEmail, 'admin', adminName]
          );
          console.log(`🌱 Seed: superadmin ${adminEmail} creado`);
        }
        }
      } catch (e) {
        console.error('⚠️ No se pudo crear superadmin seed:', e.message);
      }

      console.log(`✅ SQLite conectado: ${DB_PATH}`);
      return db;
    })();
  }
  return dbPromise;
}

function translateSql(sql) {
  // MySQL -> SQLite compat
  return sql
    .replace(/NOW\(\)/g, "datetime('now')")
    .replace(/`([^`]+)`/g, '"$1"'); // backticks to quotes if any
}

function normalizeParams(params) {
  return params.map(v => v instanceof Date ? v.toISOString() : v);
}
const pool = {
  async execute(sql, params = []) {
    const db = await getDb();
    const t = translateSql(sql).trim();
    const p = normalizeParams(params);
    const isSelect = /^\s*(SELECT|WITH)\b/i.test(t);
    if (isSelect) {
      const rows = await db.all(t, p);
      return [rows];
    } else {
      const result = await db.run(t, p);
      return [{ insertId: result.lastID, affectedRows: result.changes, changes: result.changes }];
    }
  },
  // Mutex global: sqlite tiene un solo handle; serializa begin/commit.
  // BEGIN IMMEDIATE toma el lock de escritura al empezar y evita
  // que dos reservas lean count=0 a la vez (doble reserva).
  async getConnection() {
    const db = await getDb();
    if (!pool._txMutex) pool._txMutex = Promise.resolve();
    let inTx = false;
    const conn = {
      async execute(sql, params = []) {
        const t = translateSql(sql).trim();
        const p = normalizeParams(params);
        const isSelect = /^\s*(SELECT|WITH)\b/i.test(t);
        if (isSelect) {
          const rows = await db.all(t, p);
          return [rows];
        } else {
          const result = await db.run(t, p);
          return [{ insertId: result.lastID, affectedRows: result.changes, changes: result.changes }];
        }
      },
      async beginTransaction() {
        if (inTx) return;
        let release;
        const gate = new Promise((r) => { release = r; });
        const prev = pool._txMutex;
        pool._txMutex = prev.then(() => gate);
        await prev;
        conn._releaseTx = release;
        await db.exec('BEGIN IMMEDIATE TRANSACTION');
        inTx = true;
      },
      async commit() {
        if (inTx) { await db.exec('COMMIT'); inTx = false; }
        if (conn._releaseTx) { conn._releaseTx(); conn._releaseTx = null; }
      },
      async rollback() {
        if (inTx) { try { await db.exec('ROLLBACK'); } catch (_) {} inTx = false; }
        if (conn._releaseTx) { conn._releaseTx(); conn._releaseTx = null; }
      },
      release() {
        if (conn._releaseTx) { conn._releaseTx(); conn._releaseTx = null; }
      },
    };
    return conn;
  },
};

module.exports = pool;
module.exports.getDb = getDb;
