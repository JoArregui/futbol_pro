# Futbol Pro ⚽

App social para futbolistas amateurs: partidos, ligas, canchas, chat en tiempo real y panel superadmin. Flutter 3 + BLoC + Node/Express + SQLite + Firebase + Socket.IO.

## Requisitos

- Flutter stable 3.x (`flutter --version`)
- Node 20 + npm
- Android Studio / Xcode para móvil
- Móvil con depuración USB o misma WiFi que el PC

## Puesta en marcha en 5 minutos

```powershell
# 1. Dependencias
flutter pub get
cd server; npm install; cd ..

# 2. Backend (terminal 1)
cd server
copy .env.example .env   # edita JWT_SECRET y SUPERADMIN_*
npm run dev              # http://localhost:3000 + GET /health

# 3. App (terminal 2) — elige UNA según tu caso:
# Emulador Android:
flutter run --dart-define=FLAVOR=dev --dart-define=API_URL=http://10.0.2.2:3000/api/v1
# Móvil físico por USB (recomendado):
adb reverse tcp:3000 tcp:3000
flutter run --dart-define=FLAVOR=dev --dart-define=API_URL=http://127.0.0.1:3000/api/v1
# Móvil físico por WiFi (misma red):
flutter run --dart-define=FLAVOR=dev --dart-define=API_URL=http://192.168.3.53:3000/api/v1
# Windows / Web:
flutter run -d windows --dart-define=FLAVOR=dev
```

> `API_URL` es compile-time: tras cambiarlo hay que hacer `flutter run` de cero (no vale hot-reload). `10.0.2.2` solo funciona en emulador; en móvil físico usa USB reverse o la IP LAN de tu PC.

Seed superadmin: `admin@futbolpro.com / Admin123!` (o lo que pongas en `.env`).

## Flavors

| Flavor | Uso | API por defecto |
|---|---|---|
| `dev` | desarrollo local | `http://10.0.2.2:3000/api/v1` |
| `staging` | pre-producción | `https://staging.futbolpro.com/api/v1` |
| `prod` | producción | `https://api.futbolpro.com/api/v1` |

`--dart-define=API_URL=...` siempre tiene prioridad. En VS Code tienes configuraciones listas (`.vscode/launch.json`).

## Estructura

```
lib/
  core/config/app_config.dart   # flavors dev/staging/prod
  core/theme/                   # AppTheme, AppColors (deportivo premium)
  core/widgets/                 # AppButton (píldora), AppCard, HeroBackground
  features/admin/               # panel superadmin + auditoría
  features/match_scheduling/    # amistosos, marcador con doble validación
  features/auth/                # login + huella opcional
  routes/                       # GoRouter + guard superadmin
server/
  routes/admin.js               # CRUD equipos/plantilla/campos/árbitros + /audit
  services/audit.js             # log no bloqueante de acciones superadmin
  db.js                         # SQLite (migración a Postgres: última fase, con visto bueno)
.github/workflows/ci.yml        # analyze + format + test + coverage
```

## Panel superadmin (`/admin`, rol superadmin)

Equipos (crear/renombrar/borrar + plantilla añadir/quitar), Jugadores y cuentas, Campos (añadir/quitar/switch), Árbitros (añadir/suspender/quitar), Ligas, Amistosos (cancelado masivo), Torneos, Finanzas y Actividad reciente (audit log).

## Calidad

```powershell
flutter analyze --no-pub
dart format --set-exit-if-changed lib test
flutter test --coverage
cd server; npm test
```

CI en cada push/PR a `main`/`develop`.

## Notas

- Marcador: lo registra un jugador y lo valida otro compañero (anti-errores).
- Huella: opcional, apagada por defecto. Solo desbloqueo rápido tras un login con email + contraseña. Se activa en Perfil.
- DB: SQLite local. La migración a Postgres será la última fase, tras visto bueno del cliente.
