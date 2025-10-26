import 'package:get_it/get_it.dart';
import 'package:http/http.dart' as http;

// Auth Feature

import '../features/auth/domain/repositories/auth_repository.dart';
import '../features/auth/domain/usecases/login_user.dart';
import '../features/auth/presentation/bloc/auth_bloc.dart';

// Core Services (Notificaciones)
import '../core/services/notification_service.dart';

// Match Scheduling Feature
import '../features/match_scheduling/data/datasources/match_remote_data_source.dart';
import '../features/match_scheduling/data/datasources/match_remote_data_source_impl.dart';
import '../features/match_scheduling/data/repositories/match_repository_impl.dart';
import '../features/match_scheduling/domain/repositories/match_repository.dart';
import '../features/match_scheduling/domain/usecases/schedule_friendly_match.dart';
import '../features/match_scheduling/domain/usecases/join_match.dart';
import '../features/match_scheduling/domain/usecases/generate_balanced_teams.dart';
import '../features/match_scheduling/presentation/bloc/match_bloc.dart';

//League Management

import '../features/league_management/data/repositories/league_repository_impl.dart';
import '../features/league_management/domain/repositories/league_repository.dart';
import '../features/league_management/domain/usecases/get_league_standings.dart';

// Field Management Feature

import '../features/field_management/data/repositories/field_repository_impl.dart';
import '../features/field_management/domain/repositories/field_repository.dart';
import '../features/field_management/domain/usecases/get_available_fields.dart';
import '../features/field_management/domain/usecases/reserve_field.dart';

final sl = GetIt.instance; // sl = Service Locator

void init() {
  // Presentation (BLoC)
  sl.registerFactory(
    () => FieldBloc(
      getAvailableFields: sl(),
      // reserveField: sl(), // Si se implementa
    ),
  );

  // Domain (Use Cases)
  sl.registerLazySingleton(() => GetAvailableFields(sl()));
  // sl.registerLazySingleton(() => ReserveField(sl()));

  // Data (Repositories)
  sl.registerLazySingleton<FieldRepository>(
    () => FieldRepositoryImpl(remoteDataSource: sl()),
  );

  // Data Sources
  sl.registerLazySingleton<FieldRemoteDataSource>(
    () => FieldRemoteDataSourceImpl(client: sl()),
  );

  // ===========================================
  // 1. Feature - Match Scheduling
  // ===========================================

  // Presentation (BLoC)
  // Nota: Si agregas Field Management BLoC en el futuro, inyéctalo aquí.
  sl.registerFactory(
    () => MatchBloc(
      scheduleMatch: sl(),
      joinMatch: sl(),
      generateBalancedTeams: sl(), // Use Case para balancear equipos
    ),
  );

  // Domain (Use Cases)
  sl.registerLazySingleton(() => ScheduleFriendlyMatch(sl()));
  sl.registerLazySingleton(() => JoinMatch(sl()));
  // generateBalancedTeams no necesita el repositorio, pero sí los parámetros.
  sl.registerLazySingleton(() => GenerateBalancedTeams());

  // Data (Repositories)
  sl.registerLazySingleton<MatchRepository>(
    () => MatchRepositoryImpl(remoteDataSource: sl()),
  );

  // Data Sources
  sl.registerLazySingleton<MatchRemoteDataSource>(
    () => MatchRemoteDataSourceImpl(client: sl()),
  );

  // ===========================================
  // 2. Feature - Field Management
  // ===========================================

  // Presentation (BLoC)
  sl.registerFactory(
    () => FieldBloc(
      getAvailableFields: sl(),
      reserveField: sl(), // ¡INYECCIÓN DEL NUEVO USE CASE!
    ),
  );

  // Domain (Use Cases)
  sl.registerLazySingleton(() => GetAvailableFields(sl()));
  sl.registerLazySingleton(
    () => ReserveField(sl()),
  ); // ¡NUEVO USE CASE REGISTRADO!

  // Data (Repositories)
  sl.registerLazySingleton<FieldRepository>(
    () => FieldRepositoryImpl(remoteDataSource: sl()),
  );

  // Data Sources
  sl.registerLazySingleton<FieldRemoteDataSource>(
    () => FieldRemoteDataSourceImpl(client: sl()),
  );

  // ===========================================
  // 3. Feature - Auth/Core Notifications
  // ===========================================

  // Presentation (BLoC)
  sl.registerFactory(
    () => AuthBloc(
      loginUser: sl(),
      repository: sl(), // Inyecta el AuthRepository
    ),
  );

  // Domain (Use Cases)
  sl.registerLazySingleton(() => SubscribeToNotifications(sl()));
  sl.registerLazySingleton(() => LoginUser(sl())); // ¡NUEVO USE CASE!

  // Data (Repositories)
  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(remoteDataSource: sl()),
  ); // ¡NUEVO REPO!

  // Data Sources
  sl.registerLazySingleton<AuthRemoteDataSource>(
    () => AuthRemoteDataSourceImpl(client: sl()),
  ); // ¡NUEVO DS!

  // Core (Services)
  sl.registerLazySingleton<NotificationService>(
    () => NotificationServiceImpl(),
  );

  // ===========================================
  // 4. Feature - League Management
  // ===========================================

  // 1. Presentation (BLoC)
  sl.registerFactory(() => LeagueBloc(getLeagueStandings: sl()));

  // 2. Domain (Use Cases)
  sl.registerLazySingleton(() => GetLeagueStandings(sl()));

  // 3. Data (Repositories)
  sl.registerLazySingleton<LeagueRepository>(
    () => LeagueRepositoryImpl(remoteDataSource: sl()),
  );

  // 4. Data Sources
  sl.registerLazySingleton<LeagueRemoteDataSource>(
    () => LeagueRemoteDataSourceImpl(client: sl()),
  );

  // ===========================================
  // 5. Core (External)
  // ===========================================

  // Dependencias Externas (Cliente HTTP, Verificador de Red)
  sl.registerLazySingleton(() => http.Client());
  // sl.registerLazySingleton(() => InternetConnectionChecker());

  // ===========================================
  // 6. Inicialización
  // ===========================================

  // Al iniciar la app, dispara la verificación de autenticación
  sl<AuthBloc>().add(AppStarted());
  // sl<NotificationService>().initializeNotifications();
}
