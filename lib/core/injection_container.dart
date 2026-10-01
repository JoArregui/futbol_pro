import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'storage/secure_storage_service.dart';
import 'network/authenticated_client.dart';
import 'services/file_download_service.dart';
import 'db/isar_service.dart';
import 'sync/outbox_service.dart';
import '../features/chat/data/datasources/chat_local_datasource.dart';

// Auth Feature
import '../features/auth/data/datasources/auth_remote_datasource.dart';
import '../features/auth/data/repositories/auth_repository_impl.dart';
import '../features/auth/domain/repositories/auth_repository.dart';
import '../features/auth/domain/usecases/login_user.dart';
import '../features/auth/domain/usecases/register_user.dart';
import '../features/auth/domain/usecases/subscribe_to_notifications.dart';
import '../features/auth/presentation/bloc/auth_bloc.dart';

// Profile Feature
import '../features/chat/data/datasources/chat_datasource.dart';
import '../features/match_scheduling/domain/usecases/get_upcoming_matches.dart';
import '../features/profile/data/datasources/profile_remote_datasource.dart';
import '../features/profile/data/repositories/profile_repository_impl.dart';
import '../features/profile/domain/repositories/profile_repository.dart';
import '../features/profile/domain/usecases/create_profile.dart';
import '../features/profile/domain/usecases/get_profile.dart';
import '../features/profile/domain/usecases/update_profile.dart';
import '../features/profile/presentation/bloc/profile_bloc.dart';

// Chat Feature 💬
import '../features/chat/data/repositories/chat_repository_impl.dart';
import '../features/chat/domain/repositories/chat_repository.dart';
import '../features/chat/domain/usecases/get_messages.dart';
import '../features/chat/domain/usecases/send_message.dart';
import '../features/chat/domain/usecases/mark_as_read.dart';
import '../features/chat/domain/usecases/get_chat_rooms.dart';
import '../features/chat/domain/usecases/create_chat.dart';
import '../features/chat/domain/usecases/search_users.dart';
import '../features/chat/presentation/bloc/chat_bloc.dart';
import 'services/socket_service.dart';

// Core Services
// Asegúrate de tener una implementación llamada NotificationServiceImpl
import '../core/services/notification_service.dart';

// Field Management Feature
import '../features/field_management/data/datasources/field_remote_datasource.dart';
import '../features/field_management/data/repositories/field_repository_impl.dart';
import '../features/field_management/domain/repositories/field_repository.dart';
import '../features/field_management/domain/usecases/get_available_fields.dart';
import '../features/field_management/domain/usecases/reserve_field.dart';
import '../features/field_management/domain/usecases/confirm_pago.dart';
import '../features/field_management/domain/usecases/get_mis_reservas.dart';
import '../features/field_management/presentation/bloc/field_bloc.dart';

// League Management Feature
import '../features/league_management/data/datasources/league_remote_datasource.dart';
import '../features/league_management/data/repositories/league_repository_impl.dart';
import '../features/league_management/domain/repositories/league_repository.dart';
import '../features/league_management/domain/usecases/get_league_standings.dart';
import '../features/league_management/domain/usecases/get_tournaments.dart';
import '../features/league_management/domain/usecases/register_team.dart';
import '../features/league_management/domain/usecases/create_league.dart';
import '../features/league_management/domain/usecases/get_league_detail.dart';
import '../features/league_management/domain/usecases/generate_fixture.dart';
import '../features/league_management/presentation/bloc/league_bloc.dart';

// Match Scheduling Feature
import '../features/match_scheduling/data/datasources/match_remote_datasource.dart';
import '../features/match_scheduling/data/datasources/referee_remote_datasource.dart';
import '../features/match_scheduling/data/repositories/match_repository_impl.dart';
import '../features/match_scheduling/domain/repositories/match_repository.dart';
import '../features/match_scheduling/domain/usecases/get_match_details.dart';
import '../features/match_scheduling/domain/usecases/schedule_friendly_match.dart';
import '../features/match_scheduling/domain/usecases/join_match.dart';
import '../features/match_scheduling/domain/usecases/generate_balanced_teams.dart';
import '../features/match_scheduling/domain/usecases/update_match_with_teams.dart';
import '../features/match_scheduling/domain/usecases/submit_match_result.dart';
import '../features/match_scheduling/domain/usecases/confirm_match_result.dart';
import '../features/match_scheduling/domain/usecases/report_no_show.dart';
import '../features/match_scheduling/domain/usecases/get_match_split.dart';
import '../features/match_scheduling/domain/usecases/get_match_acta.dart';
import '../features/match_scheduling/presentation/bloc/match_bloc.dart';
import '../features/match_scheduling/presentation/bloc/match_detail_bloc.dart';

// Admin Feature (superadmin)
import '../features/admin/data/datasources/admin_remote_datasource.dart';
import '../features/admin/data/repositories/admin_repository_impl.dart';
import '../features/admin/domain/repositories/admin_repository.dart';
import '../features/admin/presentation/bloc/admin_bloc.dart';

final sl = GetIt.instance; // sl = Service Locator

Future<void> init() async {
  debugPrint('🚀 Iniciando registro de dependencias...');

  // ===========================================
  // 1. Core (External)
  // ===========================================
  debugPrint('📦 Registrando dependencias Core...');
  sl.registerLazySingleton(() => FirebaseFirestore.instance);
  sl.registerLazySingleton(() => const FlutterSecureStorage());
  sl.registerLazySingleton(() => SecureStorageService(storage: sl()));
  // Cliente HTTP autenticado: inyecta JWT en cada petición (nunca anónimo).
  // Debe ir tras SecureStorageService porque lo lee de forma lazy.
  sl.registerLazySingleton<http.Client>(
    () => AuthenticatedClient(
      inner: http.Client(),
      storage: sl<SecureStorageService>(),
    ),
    dispose: (c) => (c as AuthenticatedClient).close(),
  );
  sl.registerLazySingleton<NotificationService>(
    () => NotificationServiceImpl(),
  );
  sl.registerLazySingleton(() => SocketService());
  sl.registerLazySingleton(() => OutboxService());
  await sl<OutboxService>().init();
  sl.registerLazySingleton(() => FileDownloadService(sl<http.Client>()));
  final isarService = IsarService();
  await isarService.init();
  sl.registerSingleton<IsarService>(isarService);
  sl.registerLazySingleton<ChatLocalDataSource>(
    () => ChatLocalDataSourceImpl(sl<IsarService>()),
  );
  debugPrint('✅ Core registrado correctamente (Isar + Storage + Socket)');

  // ===========================================
  // 2. Feature - Auth
  // ===========================================
  debugPrint('🔐 Registrando Auth Feature...');

  sl.registerLazySingleton<AuthRemoteDataSource>(
    () => AuthRemoteDataSourceImpl(
      client: sl<http.Client>(),
      secureStorage: sl<SecureStorageService>(),
    ),
  );
  debugPrint('  ✅ AuthRemoteDataSource registrado');

  // Data (Repositories)
  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(remoteDataSource: sl<AuthRemoteDataSource>()),
  );
  debugPrint('  ✅ AuthRepository registrado');

  // Domain (Use Cases)
  sl.registerLazySingleton(
    () => SubscribeToNotifications(sl<NotificationService>()),
  );
  sl.registerLazySingleton(() => LoginUser(sl<AuthRepository>()));
  sl.registerLazySingleton(() => RegisterUser(sl<AuthRepository>()));
  debugPrint('  ✅ UseCases registrados');

  // Presentation (BLoC)
  sl.registerFactory(
    () => AuthBloc(
      loginUser: sl<LoginUser>(),
      registerUser: sl<RegisterUser>(),
      repository: sl<AuthRepository>(),
    ),
  );
  debugPrint('  ✅ AuthBloc registrado');

  // ===========================================
  // 3. Feature - Profile Management
  // ===========================================
  debugPrint('👤 Registrando Profile Feature...');

  // Data Sources
  sl.registerLazySingleton<ProfileRemoteDataSource>(
    // 🟢 CORREGIDO: Solo se pasa http.Client
    () => ProfileRemoteDataSourceImpl(client: sl<http.Client>()),
  );
  debugPrint('  ✅ ProfileRemoteDataSource registrado');

  // Data (Repositories)
  sl.registerLazySingleton<ProfileRepository>(
    () =>
        ProfileRepositoryImpl(remoteDataSource: sl<ProfileRemoteDataSource>()),
  );
  debugPrint('  ✅ ProfileRepository registrado');

  // Domain (Use Cases)
  sl.registerLazySingleton(() => GetProfile(sl<ProfileRepository>()));
  sl.registerLazySingleton(() => UpdateProfile(sl<ProfileRepository>()));
  sl.registerLazySingleton(() => CreateProfile(sl<ProfileRepository>()));
  debugPrint('  ✅ UseCases registrados');

  // Presentation (BLoC) — lazy via AuthRepository
  sl.registerFactory(
    () => ProfileBloc(
      getProfile: sl<GetProfile>(),
      updateProfile: sl<UpdateProfile>(),
      createProfile: sl<CreateProfile>(),
      authRepository: sl<AuthRepository>(),
    ),
  );
  debugPrint('✅ Profile Feature registrado');

  // ===========================================
  // 4. Feature - Chat Management 💬
  // ===========================================
  debugPrint('💬 Registrando Chat Feature...');

  // Data Sources
  sl.registerLazySingleton<ChatRemoteDataSource>(
    // 🟢 CORREGIDO: Solo se pasa http.Client
    () => ChatRemoteDataSourceImpl(client: sl<http.Client>()),
  );
  debugPrint('  ✅ ChatRemoteDataSource registrado');

  sl.registerLazySingleton<ChatRepository>(
    () => ChatRepositoryImpl(
      remoteDataSource: sl<ChatRemoteDataSource>(),
      localDataSource: sl<ChatLocalDataSource>(),
    ),
  );
  debugPrint('  ✅ ChatRepository registrado (híbrido Isar+Server)');

  sl.registerLazySingleton(() => GetMessages(sl<ChatRepository>()));
  sl.registerLazySingleton(() => SendMessage(sl<ChatRepository>()));
  sl.registerLazySingleton(() => MarkAsRead(sl<ChatRepository>()));
  sl.registerLazySingleton(() => GetChatRooms(sl<ChatRepository>()));
  sl.registerLazySingleton(() => CreateChat(sl<ChatRepository>()));
  sl.registerLazySingleton(() => SearchUsers(sl<ChatRepository>()));
  debugPrint('  ✅ UseCases registrados');

  sl.registerFactory(
    () => ChatBloc(
      getMessages: sl<GetMessages>(),
      sendMessage: sl<SendMessage>(),
      markAsRead: sl<MarkAsRead>(),
      getChatRooms: sl<GetChatRooms>(),
      createChat: sl<CreateChat>(),
      searchUsers: sl<SearchUsers>(),
      authRepository: sl<AuthRepository>(),
      socketService: sl<SocketService>(),
      notifications: sl<NotificationService>(),
    ),
  );
  debugPrint('✅ Chat Feature registrado');

  // ===========================================
  // 5. Feature - Match Scheduling
  // ===========================================
  debugPrint('⚽ Registrando Match Scheduling Feature...');

  // Data Sources
  sl.registerLazySingleton<MatchRemoteDataSource>(
    () => MatchRemoteDataSourceImpl(client: sl<http.Client>()),
  );
  sl.registerLazySingleton<RefereeRemoteDataSource>(
    () => RefereeRemoteDataSource(client: sl<http.Client>()),
  );
  debugPrint('  ✅ MatchRemoteDataSource registrado');

  // Data (Repositories)
  sl.registerLazySingleton<MatchRepository>(
    () => MatchRepositoryImpl(
      remoteDataSource: sl<MatchRemoteDataSource>(),
      outbox: sl<OutboxService>(),
    ),
  );
  debugPrint('  ✅ MatchRepository registrado');

  // Domain (Use Cases)
  sl.registerLazySingleton(() => ScheduleFriendlyMatch(sl<MatchRepository>()));
  sl.registerLazySingleton(() => JoinMatch(sl<MatchRepository>()));
  sl.registerLazySingleton(
    () => GenerateBalancedTeams(),
  ); // No requiere dependencias
  sl.registerLazySingleton(() => GetMatchDetails(sl<MatchRepository>()));
  sl.registerLazySingleton(() => UpdateMatchWithTeams(sl<MatchRepository>()));
  sl.registerLazySingleton(() => GetUpcomingMatches(sl<MatchRepository>()));
  sl.registerLazySingleton(() => SubmitMatchResult(sl<MatchRepository>()));
  sl.registerLazySingleton(() => ConfirmMatchResult(sl<MatchRepository>()));
  sl.registerLazySingleton(() => ReportNoShow(sl<MatchRepository>()));
  sl.registerLazySingleton(() => GetMatchSplit(sl<MatchRepository>()));
  sl.registerLazySingleton(() => GetMatchActa(sl<MatchRepository>()));
  debugPrint('  ✅ UseCases registrados');

  // Presentation (BLoC)
  sl.registerFactory(
    () => MatchBloc(
      scheduleFriendlyMatch: sl<ScheduleFriendlyMatch>(),
      joinMatch: sl<JoinMatch>(),
      generateBalancedTeams: sl<GenerateBalancedTeams>(),
      getMatchDetails: sl<GetMatchDetails>(),
      updateMatchWithTeams: sl<UpdateMatchWithTeams>(),
      getUpcomingMatches: sl<GetUpcomingMatches>(),
    ),
  );
  sl.registerFactory(
    () => MatchDetailBloc(
      getMatchDetails: sl<GetMatchDetails>(),
      submitMatchResult: sl<SubmitMatchResult>(),
      confirmMatchResult: sl<ConfirmMatchResult>(),
      reportNoShow: sl<ReportNoShow>(),
      getMatchSplit: sl<GetMatchSplit>(),
      getMatchActa: sl<GetMatchActa>(),
      authRepository: sl<AuthRepository>(),
    ),
  );
  debugPrint('✅ Match Scheduling Feature registrado');

  // ===========================================
  // 6. Feature - Field Management
  // ===========================================
  debugPrint('🏟️ Registrando Field Management Feature...');

  // Data Sources
  sl.registerLazySingleton<FieldRemoteDataSource>(
    () => FieldRemoteDataSourceImpl(client: sl<http.Client>()),
  );
  debugPrint('  ✅ FieldRemoteDataSource registrado');

  // Data (Repositories)
  sl.registerLazySingleton<FieldRepository>(
    () => FieldRepositoryImpl(remoteDataSource: sl<FieldRemoteDataSource>()),
  );
  debugPrint('  ✅ FieldRepository registrado');

  // Domain (Use Cases)
  sl.registerLazySingleton(() => GetAvailableFields(sl<FieldRepository>()));
  sl.registerLazySingleton(() => ReserveField(sl<FieldRepository>()));
  sl.registerLazySingleton(() => ConfirmPago(sl<FieldRepository>()));
  sl.registerLazySingleton(() => GetMisReservas(sl<FieldRepository>()));
  debugPrint('  ✅ UseCases registrados');

  // Presentation (BLoC)
  sl.registerFactory(
    () => FieldBloc(
      getAvailableFields: sl<GetAvailableFields>(),
      reserveField: sl<ReserveField>(),
      confirmPago: sl<ConfirmPago>(),
      getMisReservas: sl<GetMisReservas>(),
    ),
  );
  debugPrint('✅ Field Management Feature registrado');

  // ===========================================
  // 7. Feature - League Management
  // ===========================================
  debugPrint('🏆 Registrando League Management Feature...');

  // Data Sources
  sl.registerLazySingleton<LeagueRemoteDataSource>(
    () => LeagueRemoteDataSourceImpl(client: sl<http.Client>()),
  );
  debugPrint('  ✅ LeagueRemoteDataSource registrado');

  // Data (Repositories)
  sl.registerLazySingleton<LeagueRepository>(
    () => LeagueRepositoryImpl(remoteDataSource: sl<LeagueRemoteDataSource>()),
  );
  debugPrint('  ✅ LeagueRepository registrado');

  // Domain (Use Cases)
  sl.registerLazySingleton(() => GetLeagueStandings(sl<LeagueRepository>()));
  sl.registerLazySingleton(() => GetTournaments(sl<LeagueRepository>()));
  sl.registerLazySingleton(() => RegisterTeam(sl<LeagueRepository>()));
  sl.registerLazySingleton(() => CreateLeague(sl<LeagueRepository>()));
  sl.registerLazySingleton(() => GetLeagueDetail(sl<LeagueRepository>()));
  sl.registerLazySingleton(() => GenerateFixture(sl<LeagueRepository>()));
  debugPrint('  ✅ UseCases registrados');

  // Presentation (BLoC)
  sl.registerFactory(
    () => LeagueBloc(
      getLeagueStandings: sl<GetLeagueStandings>(),
      getTournaments: sl<GetTournaments>(),
      registerTeam: sl<RegisterTeam>(),
      createLeague: sl<CreateLeague>(),
      getLeagueDetail: sl<GetLeagueDetail>(),
      generateFixture: sl<GenerateFixture>(),
    ),
  );
  debugPrint('✅ League Management Feature registrado');

  // ===========================================
  // 8. Feature - Admin (superadmin)
  // ===========================================
  debugPrint('🛡️ Registrando Admin Feature...');
  sl.registerLazySingleton<AdminRemoteDataSource>(
    () => AdminRemoteDataSource(
      client: sl<http.Client>(),
      authRepository: sl<AuthRepository>(),
    ),
  );
  sl.registerLazySingleton<AdminRepository>(
    () => AdminRepositoryImpl(remote: sl<AdminRemoteDataSource>()),
  );
  sl.registerFactory(() => AdminBloc(repository: sl<AdminRepository>()));
  debugPrint('✅ Admin Feature registrado');

  // Rotación transparente de JWT: ante un 401, el cliente pide un par
  // nuevo con el refresh token y reintenta una vez (sin bucles: el propio
  // AuthenticatedClient excluye /auth/refresh del reintento).
  final authClient = sl<http.Client>();
  if (authClient is AuthenticatedClient) {
    authClient.onUnauthorized = () =>
        sl<AuthRemoteDataSource>().refreshSession();
    debugPrint('✅ Rotación JWT conectada (401 → refresh → retry)');
  }

  debugPrint('🎉 Todas las dependencias registradas exitosamente!');
}
