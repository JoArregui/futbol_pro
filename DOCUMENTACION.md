# Futbol Pro — Documentación Completa

> **Proyecto:** Futbol Pro `1.0.0+1` — Flutter 3.x + Node.js/Express + MySQL + Firebase + Socket.IO + PayPal  
> **Fecha:** 29/09/2026  
> **Autor:** Equipo Futbol Pro / Auditoría Muse Spark  
> **Incluye:** 8 correcciones de arquitectura + Chat Full WhatsApp Clone (Socket.IO, ticks, grupos) + Integración PayPal

---

## Índice
1. [Visión General](#visión-general)
2. [Stack Tecnológico](#stack-tecnológico)
3. [Estructura del Proyecto](#estructura-del-proyecto)
4. [Arquitectura Clean + BLoC](#arquitectura-clean--bloc)
5. [Instalación y Configuración](#instalación-y-configuración)
6. [Variables de Entorno](#variables-de-entorno)
7. [Backend REST + Socket.IO](#backend-rest--socketio)
8. [API Reference](#api-reference)
9. [Base de Datos MySQL](#base-de-datos-mysql)
10. [Chat WhatsApp Clone — Especificación](#chat-whatsapp-clone--especificación)
11. [Frontend — Features y Navegación](#frontend--features-y-navegación)
12. [Autenticación y Persistencia](#autenticación-y-persistencia)
13. [Notificaciones](#notificaciones)
14. [Configuración por Plataforma](#configuración-por-plataforma)
15. [Testing](#testing)
16. [Análisis Estático y Calidad](#análisis-estático-y-calidad)
17. [Git y Secretos](#git-y-secretos)
18. [Roadmap y Troubleshooting](#roadmap-y-troubleshooting)

---

## Visión General

Futbol Pro es una app social para futbolistas amateurs: perfil, partidos amistosos y de liga, reserva de canchas, tabla de posiciones, y **chat en tiempo real estilo WhatsApp/Telegram**. 

**Estado tras auditoría (sep-2026):**
- `lib/` 6.9k LOC Dart, ~200 archivos modificados consolidados, `flutter analyze` 0 errores
- Backend migrado de `lib/backend/` → `server/` (Node + MySQL, no Firestore directo)
- Sesión persistente con `flutter_secure_storage`, `AuthBloc` conectado a casos de uso reales (antes mock)
- `AppConsts.baseUrl` centralizado con `--dart-define=API_URL`
- `NotificationService` real con `firebase_messaging + flutter_local_notifications`
- Android `namespace` corregido `com.masai.futbol_pro`
- 11 tests `flutter test` pass

---

## Stack Tecnológico

| Capa | Tecnología | Versión | Notas |
|------|------------|---------|-------|
| **App** | Flutter / Dart | 3.41.9 / 3.11.5 | `sdk >=3.0.0 <4.0.0` |
| Estado | `flutter_bloc` | 9.1.1 | + `equatable` 2.0.5, `dartz` 0.10.1 |
| DI | `get_it` | 9.1.0 | `injection_container.dart` |
| Nav | `go_router` | 17.0.0 | + `GoRouterRefreshStream` |
| HTTP | `http` | 1.2.1 | Todos los datasources |
| Storage seguro | `flutter_secure_storage` | 9.2.4 | Sesión |
| Realtime | `socket_io_client` | 3.1.6 | Chat |
| Media | `image_picker` 1.2.1, `cached_network_image` 3.4.1 | — | Avatares / adjuntos |
| Firebase | `firebase_core` 4.2.1, `firebase_messaging` 16.0.4, `cloud_firestore` 6.1.0, `firebase_storage` 13.0.4 | — | Iniciado en `main.dart` |
| Notif local | `flutter_local_notifications` | 19.5.0 | Canal `futbol_pro_default` |
| Formato | `intl` 0.20.2 | — | `HH:mm`, fechas |
| **Backend** | Node 20+, Express 4.21.2, `helmet`, `bcryptjs` 5.0.1, `cors`, `dotenv`, `stripe` SDK, `paypal` SDK | — | `server/`; `engines.node>=20` en package.json; node --check en CI |
| Tests | `bloc_test` 10.0.0, `mocktail` 1.0.5 | — | 39 npm tests (7 suites); 23 flutter tests |

---

## Estructura del Proyecto

```
futbol_pro/
├─ lib/
│  ├─ main.dart                          # Bootstrap Firebase + DI + MultiBlocProvider
│  ├─ firebase_options.dart              # masai-app (4 plataformas) — ignorado en git
│  ├─ core/
│  │  ├─ consts.dart                     # AppConsts.baseUrl (String.fromEnvironment)
│  │  ├─ injection_container.dart        # GetIt: 7 features + Core services
│  │  ├─ errors/{exceptions,failures}.dart
│  │  ├─ usecases/{usecase,stream_usecase}.dart
│  │  ├─ services/{notification_service,socket_service}.dart
│  │  ├─ routing/go_router_refresh_stream.dart
│  │  └─ storage/secure_storage_service.dart
│  ├─ features/
│  │  ├─ auth/{data,domain,presentation} # login, register, logout, getAuthenticatedPlayer
│  │  ├─ profile/                        # fetch/create/update
│  │  ├─ chat/                           # ★ WhatsApp clone (ver §10)
│  │  ├─ match_scheduling/               # 6 usecases, MatchBloc
│  │  ├─ field_management/               # getAvailable/reserve
│  │  ├─ league_management/              # standings
│  │  └─ main_page/                      # HomePage
│  ├─ presentation/widgets/{main_scaffold,draggable_floating_chat_button}.dart
│  └─ routes/{app_router,app_routes}.dart
├─ server/                               # ★ Movido de lib/backend/
│  ├─ server.js                          # Express + Socket.IO + CORS + /health
│  ├─ db.js                              # mysql2 pool via dotenv
│  ├─ package.json
│  ├─ .env.example
│  └─ routes/{auth,chats,fields,leagues,matches,users}.js
├─ android/app/src/main/kotlin/com/masai/futbol_pro/MainActivity.kt # namespace corregido
├─ test/{core,features/auth,chat,match_scheduling,widget_test}.dart
├─ pubspec.yaml
├─ analysis_options.yaml                 # exclude: server/**, lib/backend/**
└─ firebase.json
```

---

## Arquitectura Clean + BLoC

```
Presentation (Bloc, Pages, Widgets)
      ↓ event / state
Domain (Entities, Repository interface, UseCases → Either<Failure,T>)
      ↓
Data (Models, DataSources HTTP, RepositoryImpl → map Exception→Failure)
      ↓
Core (Consts, Errors, Storage, Socket, Notification)
```

- **UseCase** `Future<Either<Failure,T>> call(Params)` — puro, testeable
- **RepositoryImpl** captura `ServerException` → `Left(ServerFailure)`
- **Bloc** sin lógica de red, solo `fold` y `emit`; `AuthRepository.getCurrentUserId()` lazy (no snapshot en `GetIt`)
- **DI** `sl.registerLazySingleton` para `http.Client`, `SecureStorageService`, `SocketService`, `NotificationService`; `registerFactory` para Blocs

---

## Instalación y Configuración

### Requisitos
- Flutter 3.41.9 (`flutter --version`)
- Node 18+ / npm
- MySQL 8 (DB `futbol_pro`)
- Android Studio / Xcode (para móvil)

### Pasos

```powershell
# 1) Clonar e instalar
git clone <repo> futbol_pro; cd futbol_pro
flutter pub get

# 2) Firebase (no se commitea)
# Colocar: android/app/google-services.json , ios/Runner/GoogleService-Info.plist , lib/firebase_options.dart
# Están en .gitignore — pedir al owner o regenerar con `flutterfire configure --project=masai-app`

# 3) Backend
cd server
cp .env.example .env   # editar DB_HOST/USER/PASSWORD/PORT
npm install
npm run dev            # http://localhost:3000 + Socket.IO

# 4) App (elige URL según entorno)
# Emulador Android:
flutter run --dart-define=API_URL=http://10.0.2.2:3000/api/v1
# Dispositivo físico en misma LAN:
flutter run --dart-define=API_URL=http://192.168.1.10:3000/api/v1
# Otras plataformas / prod:
flutter run --dart-define=API_URL=https://api.futbolpro.com/api/v1

# 5) Tests
flutter analyze --no-pub
flutter test
```

---

## Variables de Entorno

**App (compile-time):**
- `API_URL` — `String.fromEnvironment` en `AppConsts.baseUrl`, default `http://10.0.2.2:3000/api/v1`

**Server (`server/.env`, nunca commitear):**
```
DB_HOST=localhost
DB_USER=root
DB_PASSWORD=****
DB_NAME=futbol_pro
DB_PORT=3306
DB_CONNECTION_LIMIT=10
PORT=3000
STRIPE_PUBLIC_KEY=pk_test_******************
STRIPE_SECRET_KEY=sk_test_******************
PAYPAL_CLIENT_ID=AfZ...  # nunca commitear valor secreto real
```

---

## Backend REST + Socket.IO

`server/server.js` crea `http.createServer(app)` + `new Server(server, {cors:{origin:'*'}})` y expone `app.set('io', io)`.

**Eventos socket (cliente `SocketService`):**
- `emit: join_user(userId)` → `socket.join('user_<id>')`
- `emit: join_room(roomId)` / `leave_room`
- `emit: typing {roomId,userId,isTyping}` → `broadcast to room_<id>`
- `on: new_message {id,senderId,senderName,text,timestamp,roomId}` (al enviar `POST /:roomId/messages`)
- `on: chat_updated {roomId,lastMessage}` (a cada miembro)
- `on: chat_created {id,title,type,memberIds}` (a cada miembro)

**Health:** `GET /health → {status:'ok', uptime}`

---

## API Reference

Base: `AppConsts.baseUrl` = `…/api/v1`

### Auth `server/routes/auth.js`
- `POST /auth/register` `{email,password,nickname,name}` → 201 `{id,name,nickname,rating,profileImageUrl}` + `INSERT auth (bcrypt) + perfiles`; 409 si duplicado
- `POST /auth/login` `{email,password}` → 200 `perfiles` filtrado; `bcrypt.compare`; 401/404

### Users `server/routes/users.js`
- `GET /users/:uid/profile` → 200 perfil | 404
- `PUT /users/:uid/profile` `{nombre,apodo,bio,url_avatar...}` → 200 | 400 si vacío
- `GET /users/search?q=&excludeUid=` → 200 `[ {id,nombre,apodo,url_avatar,email} ]` limit 20 (para `NewChatPage`)

### Chats `server/routes/chats.js`
- `GET /chats/:userId/chats` → 200 `[ChatRoom]` con `memberIds[], lastMessage, lastActive, unreadCount` (cuenta `mensajes.timestamp > ultimo_leido_timestamp AND id_emisor_fk != userId`)
  - Alias `GET /chats/users/:userId/chats` compat
- `GET /chats/:roomId/messages` → 200 `[Message]` order `timestamp DESC LIMIT 50`
- `POST /chats/:roomId/messages` `{senderId,senderName,text}` → 201 `{id}` + `UPDATE chats ultimo_mensaje/ultima_actividad` + emit socket
- `PUT /chats/:roomId/read/:userId` → 200 | 404
- `POST /chats` `{title,type:'private'|'general'|'match'|'league', memberIds[], relatedEntityId?}` → 201 `{id,title,type,memberIds}` ; deduplica privado 1-1 (2 miembros) → 200 `{id,existed:true}` + emit `chat_created`
- `GET /chats/:roomId/members` → 200 `[{id,nombre,apodo,url_avatar}]`

### Partidos `server/routes/matches.js` — `POST /matches`, `GET /matches/upcoming`, `POST /matches/:id/join`, `GET /matches/:id`, `PUT /matches/:id/teams` (usa `AppConsts.baseUrl` en datasource)
### Canchas `fields.js` — `GET /fields/available?start&end`, `POST /fields/:id/reserve`
### Ligas `leagues.js` — `GET /leagues/:id/standings`

---

## Base de Datos MySQL

Esquema inferido de `server/routes/*.js`:

```sql
-- auth
CREATE TABLE auth (id_auth BIGINT AUTO_INCREMENT PK, email VARCHAR(255) UNIQUE, password VARCHAR(255) /*bcrypt*/ );
-- perfiles
CREATE TABLE perfiles (uid BIGINT PK FK→auth.id_auth, email VARCHAR, apodo VARCHAR, nombre VARCHAR, url_avatar VARCHAR, bio TEXT, rating DOUBLE, partidos_jugados INT, victorias INT, fecha_creacion DATETIME);
-- chats
CREATE TABLE chats (id_chat BIGINT AUTO_INCREMENT PK, nombre VARCHAR, tipo ENUM('private','general','match','league','group'), related_entity_id VARCHAR NULL, ultimo_mensaje JSON NULL, ultima_actividad DATETIME);
CREATE TABLE chats_miembros (id_chat_fk BIGINT, id_miembro_fk BIGINT, ultimo_leido_timestamp DATETIME, PRIMARY KEY(id_chat_fk,id_miembro_fk));
-- mensajes
CREATE TABLE mensajes (id_mensaje VARCHAR(36) PK /*randomUUID*/, id_chat_fk BIGINT, id_emisor_fk BIGINT, nombre_emisor VARCHAR, texto TEXT, timestamp DATETIME, INDEX(id_chat_fk, timestamp));
```

**Migración recomendada para chat mejorado:**
```sql
ALTER TABLE chats ADD COLUMN avatar_url VARCHAR(512) NULL AFTER nombre;
-- asegurar índice para búsqueda usuarios:
CREATE INDEX idx_perfiles_busqueda ON perfiles(nombre, apodo, email);
```

---

## Chat WhatsApp Clone — Especificación

### Entidades (`lib/features/chat/domain/entities/`)

**Message** `message.dart`
```dart
enum MessageStatus { sending, sent, delivered, read, failed }
enum MessageType { text, image, system }
class Message { id, senderId, senderName, text, timestamp, status, type, replyToId, imageUrl }
```

**ChatRoom** `chat_room.dart`
```dart
enum ChatRoomType { general, league, match, private }
class ChatRoom { id, type, title, memberIds, lastMessage, relatedEntityId, avatarUrl, unreadCount, lastActive, isMuted, isPinned; bool get isGroup }
```

**Modelos** tolerantes a `timestamp` int/string/Timestamp, `texto` vs `text`, `id_mensaje` vs `id`, etc. (`message_model.dart`, `chat_room_model.dart`)

### Flujo Cliente (`lib/core/services/socket_service.dart` + `lib/features/chat/presentation/bloc/chat_bloc.dart`)

- **DI:** `SocketService` lazySingleton; `ChatBloc` recibe `GetMessages, SendMessage, MarkAsRead, GetChatRooms, CreateChat, SearchUsers, AuthRepository, SocketService`
- **Init:** `socketService.connect(userId)` + listeners `new_message/chat_updated/chat_created/typing`
- **Eventos:** `ChatRoomsSubscriptionRequested`, `ChatRoomSelected` (+ `joinRoom`), `ChatMessagesSubscriptionRequested`, `ChatMessageSent`, `ChatMarkAsRead`, `ChatCreateRequested`, `ChatSearchRequested`, `ChatTypingChanged` (debounce 2s), `ChatSocketMessageReceived`, `ChatSocketTypingReceived`
- **Estados:** `ChatInitial, ChatLoading, ChatError, ChatRoomsLoaded, ChatRoomSelectedState(messages,isSending,isTyping,typingUserId), ChatSearchState(users,isSearching)`
- **Ticks:** `MessageBubble._tick` mapea `status → Icons.check/done_all` (read azul `#53BDEB`)

### UI (`lib/features/chat/presentation/`)

- **chat_list_page.dart** — `AppBar #075E54`, título "Futbol Pro" / `TextField` búsqueda, `TabBar Todos/No leídos/Grupos` (filtra `isGroup`, `unreadCount>0`, query en `title/lastMessage`), `FloatingActionButton #25D366` → `/chat/new`, `ChatTile` por fila, `RefreshIndicator`, estados `Loading/Error/Empty`
- **chat_tile.dart** — `CircleAvatar` persona/grupo, `lastActive` relativo (`HH:mm/ayer/EEE/dd/MM`), preview 32c + `✓✓` si `lastMessage.senderId`, badge `unreadCount` verde o `volume_off`
- **chat_room_page.dart** — `AppBar #075E54` con avatar, nombre, subtítulo `escribiendo.../${N} miembros/en línea`, fondo `#E5DDD5`, `MessageList` + `ChatInput`
- **message_list.dart** — `ListView reverse`, chips fecha `HOY/AYER/dd MMM yyyy`, `MessageBubble` por mensaje, `_TypingIndicator` animado 3 puntos
- **message_bubble.dart** — `#005C4B` mío / blanco otro, `SenderName` coloreado en grupo, `Stack` texto + hora 11sp + tick a la derecha
- **chat_input.dart** — contenedor `#F0F0F0`, campo blanco redondo `Radius 24` con `emoji/attach/camera`, botón circular `send/mic` `#25D366`, dispara `ChatTypingChanged`
- **new_chat_page.dart** — toggle `Nuevo chat / Nuevo grupo`, `TextField` búsqueda → `ChatSearchRequested`, selección horizontal de miembros, `Crear grupo` diálogo → `ChatCreateRequested(title,type,memberIds)`
- **draggable_floating_chat_button.dart** — usado en `MainScaffold` (fuera de chat)

### Ruteo (`lib/routes/app_router.dart`)
```dart
GoRoute(path:'/chat', builder:ChatListPage, routes:[
  GoRoute(path:'new', builder:NewChatPage),
  GoRoute(path:':roomId', builder:ChatRoomPage), // if roomId=='new' → NewChatPage
])
// hideBottomBar si matchedLocation contiene 'room' o '/chat/new'
```

---

## Frontend — Features y Navegación

| Ruta | Página | Bloc | Notas |
|------|--------|------|-------|
| `/home` | `HomePage` | — | Entry |
| `/matches` + `match_detail/:matchId` | `MatchListPage, MatchDetailPage` | `MatchBloc` | 6 usecases |
| `/standings` | `StandingsPage` | `LeagueBloc` | `default_league_id` |
| `/fields` | `FieldSearchPage` | `FieldBloc` | reserva |
| `/chat`, `/chat/new`, `/chat/:roomId` | ver arriba | `ChatBloc` | Shell con `MainScaffold` |
| `/profile` | `ProfilePage` | `ProfileBloc` | lazy `AuthRepository` |
| `/login`, `/register` | `LoginPage, RegisterPage` | `AuthBloc` | redirect `GoRouter` si no auth |

`lib/main.dart` — `Firebase.initializeApp`, `NotificationServiceImpl.initialize`, `di.init`, `MultiBlocProvider` con `AuthBloc.value` + `Profile/Chat/Match/Field/League`, `BlocBuilder<AuthBloc>` switch `AuthInitial→AuthInitializer` vs `MaterialApp.router`

---

## Autenticación y Persistencia

- **Datasource** `lib/features/auth/data/datasources/auth_remote_datasource.dart` — `http POST /auth/login|/register` (`AppConsts.baseUrl/auth`), persiste `Player` vía `SecureStorageService` (`flutter_secure_storage` keys `auth_user_id/name/json`), `getAuthenticatedPlayer()` carga de storage, fallback `GET /users/:id/profile`, `logout()` clear
- **Repository** mapea `ServerException → ServerFailure`
- **Bloc** `lib/features/auth/presentation/bloc/auth_bloc.dart` — `AppStarted → getAuthenticatedPlayer`, `LoginRequested → loginUser`, `RegisterRequested → registerUser (con name)`, `LogoutRequested → logout`; emite `AuthAuthenticated(userId)` / `AuthUnauthenticated` / `AuthError`
- **DI fix:** `ProfileBloc` y `ChatBloc` ya no capturan `getCurrentUserId()` al registrarse, sino getter lazy `authRepository.getCurrentUserId()`
- **Storage** `lib/core/storage/secure_storage_service.dart` — `persistUser, getUserId/Name/Json, clear`

---

## Notificaciones

`lib/core/services/notification_service.dart` — `FirebaseMessaging` + `FlutterLocalNotifications`
- `initialize()` crea canal `futbol_pro_default` `#E1F2FA` importancia high, `requestPermission`, `onMessage` → `_local.show` + `_onMessageCtrl`
- `subscribeToTopic(sanitized)`, `unsubscribe`, `getToken`, streams `onMessage/onMessageOpenedApp`, background handler top-level

---

## Configuración por Plataforma

- **Android** `android/app/build.gradle.kts` — `namespace/applicationId com.masai.futbol_pro`, `compileSdk flutter.compileSdkVersion`, `Java 21 + desugaring 2.1.4`, `firebase-messaging-ktx:24.0.0`; `MainActivity.kt` en `com/masai/futbol_pro/MainActivity.kt` (`package com.masai.futbol_pro`). `minSdk 23` (requiere `network_security_config` + `local_auth`). `key.properties` para firma release (nunca commitear).
- **iOS/macOS** `Runner.xcodeproj/project.pbxproj` — 6 apps con `com.masai.futbolPro`, 3 test entries aún `com.example` (pendiente Xcode fix). bundle IDs unificadas.
- **Firebase** proyecto `masai-app` `1011658046972` (5 plataformas en `firebase_options.dart`). `GoogleService-Info.plist` pendiente en disco — `flutterfire configure --ios-bundle-id=com.masai.futbolPro` para generar.
- **Windows/Linux/macOS** bundle IDs todos `com.masai.futbolPro` (consistencia cross-platform).
- **Analysis** `analysis_options.yaml` incluye `package:flutter_lints/flutter.yaml` y excluye `server/**`, `lib/backend/**`

---

## Testing

```powershell
flutter test
# 23 tests: test/core/consts_test, auth_bloc_test (12 casos AppStarted/login/register/logout/refresh),
#           chat_bloc_test (initial + send/message/image), match_bloc_test (initial),
#           league_detail_test (3 parse), widget_test placeholder
flutter analyze --no-pub # 0 errors, 9 informaciones previas (unnecessary_underscores, unused_field, etc.)
```

39 npm tests (7 suites): auth, pagos, admin, matches, leagues, chat_images, health. Todos pass en CI.

Nuevos tests mockean `SocketService.connect` para evitar conexión real.

BlocTest upgrades: `bloc_test` 10.0.0 compatible con `flutter_bloc 9.1.1`.
```

---

## Git y Secretos

`.gitignore` ignora:
```
.dart_tool/, .pub-cache/, /build/
lib/firebase_options.dart
android/app/google-services.json
ios/Runner/GoogleService-Info.plist
server/node_modules/, server/.env, server/*.log
lib/backend/  # legacy, ahora server/
.env
```

Tras auditoría se ejecutó `git rm --cached -r lib/backend` y `git rm --cached android/app/google-services.json` — quedan en disco pero fuera del índice; si se commitea la eliminación, los colaboradores deben colocar sus propios archivos locales (o usar `flutterfire configure`).

---

## Roadmap y Troubleshooting

**Hecho en auditoría (8):** AuthBloc real, DI lazy, `AppConsts` con dart-define, mover backend a `server/` + `dotenv/cors`, `NotificationService` real, fix namespace Android, `SecureStorage` + `bloc_test`, limpieza git.

**Hecho en auditoría (3ra ronda):** `AdminError` con `prev`, `friendlies` derivado de `matches`, `notification_service` tópicos sanitizados, `AdminLoaded` sin `friendlies` duplicado, `profile_state` `updatedAt`, `server` bcryptjs+helmet+STRIPE, `admin.js` LIKE escape, CSV injection, `no-show` UNIQUE+dedup, `users` profile whitelist, `chats` senderName DB, `available` excluye cancel/error_pago, `reserve` pre-check provider, `refresh_tokens` atomic tx BEGIN IMMEDIATE + límite 10, `fields` disponibilidad, `matches` teams authz+overlap, `acta.csv` neutralizer, `socket` join con auth estricto, `post /users/bulk-delete` proxy-safe.

**Chat implementado:** entidades extendidas, socket.io server+client, datasource `createChat/searchUsers`, bloc typing/socket, UI WhatsApp completa, ruteo `/chat/new`.

**PayPal:** integración en `server/services/paypal.js`, rutas `server/routes/admin.js`, flujo de pagos en dashboard.

**Próximos:** adjuntos imagen (usar `image_picker` + `firebase_storage` → `imageUrl` en `Message`), notas de voz, cifrado, paginación `LIMIT 50` → infinite scroll, `intl` locale `es_ES` inicializar en `main.dart`, iOS test bundle IDs `com.example→com.masai`, `key.properties` release, `DOCUMENTACION.md` actualización.

**Troubleshooting:**
- `10.0.2.2` solo funciona en emulador; en físico usar `192.168.x.x` y `--dart-define`
- `firebase_options.dart` no existe tras clone → `flutterfire configure`
- `chat_updated` no llega → verificar `server.listen` (ahora HTTP+Socket, no `app.listen`) y `SocketService` connect con `userId` no vacío
- `flutter pub get` falla `bloc_test` → usar `bloc_test: ^10.0.0` (compatible con `flutter_bloc 9.1.1` que usa `bloc 9.0.0`)
- `flutter analyze` `include_file_not_found` → `flutter pub get` pendiente
- `GoogleService-Info.plist` faltante → `flutterfire configure --ios-bundle-id=com.masai.futbolPro`
- `project.pbxproj` 3 test entries `com.example` → actualizar a `com.masai.futbolPro` (Xcode manual)
- `server/.env` `STRIPE_SECRET_KEY` vacío → agregar `sk_test_...` local, nunca commitear

---

## Licencia y Contacto

Privado — `publish_to: none`. Dudas: abrir issue en repo interno o contactar owner `masai-app` Firebase.
