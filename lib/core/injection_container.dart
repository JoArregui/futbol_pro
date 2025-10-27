import 'package:get_it/get_it.dart';
import 'package:http/http.dart' as http;

// Auth Feature
import '../features/auth/data/datasources/auth_remote_dataSource.dart';
import '../features/auth/data/repositories/auth_repository_impl.dart';
import '../features/auth/domain/repositories/auth_repository.dart';
import '../features/auth/domain/usecases/login_user.dart';
import '../features/auth/domain/usecases/register_user.dart'; // ✅ Agregado: Use Case de registro
import '../features/auth/domain/usecases/subscribe_to_notifications.dart';
import '../features/auth/presentation/bloc/auth_bloc.dart';

// Core Services (Notificaciones)
import '../core/services/notification_service.dart';

// Match Scheduling Feature
import '../features/field_management/data/datasources/field_remote_datasource.dart';
import '../features/field_management/data/repositories/field_repository_impl.dart';
import '../features/field_management/domain/repositories/field_repository.dart';
import '../features/field_management/domain/usecases/get_available_fields.dart';
import '../features/field_management/domain/usecases/reserve_field.dart';
import '../features/field_management/presentation/bloc/field_bloc.dart';

import '../features/league_management/data/datasources/league_remote_datasource.dart';
import '../features/league_management/data/repositories/league_repository_impl.dart';
import '../features/league_management/domain/repositories/league_repository.dart';
import '../features/league_management/domain/usecases/get_league_standings.dart';
import '../features/league_management/presentation/bloc/league_bloc.dart';

import '../features/match_scheduling/data/datasources/match_remote_datasource.dart';
import '../features/match_scheduling/data/repositories/match_repository_impl.dart';
import '../features/match_scheduling/domain/repositories/match_repository.dart';
import '../features/match_scheduling/domain/usecases/schedule_friendly_match.dart';
import '../features/match_scheduling/domain/usecases/join_match.dart';
import '../features/match_scheduling/domain/usecases/generate_balanced_teams.dart';
import '../features/match_scheduling/presentation/bloc/match_bloc.dart';

final sl = GetIt.instance; // sl = Service Locator

void init() {
  // ===========================================
  // 1. Feature - Match Scheduling
  // ===========================================

  // Presentation (BLoC)
  sl.registerFactory(
    () => MatchBloc(
      // ✅ CORREGIDO: Usando 'scheduleFriendlyMatch' y 'joinMatch'
      scheduleFriendlyMatch: sl(), 
      joinMatch: sl(),
      generateBalancedTeams: sl(), 
    ),
  );

  // Domain (Use Cases)
  sl.registerLazySingleton(() => ScheduleFriendlyMatch(sl()));
  sl.registerLazySingleton(() => JoinMatch(sl()));
  sl.registerLazySingleton(() => GenerateBalancedTeams());

  // Data (Repositories)
  sl.registerLazySingleton<MatchRepository>(
    () => MatchRepositoryImpl(remoteDataSource: sl()),
  );

  // Data Sources
  sl.registerLazySingleton<MatchRemoteDataSource>(
    // ✅ CORREGIDO: 'MatchRemoteDataSourceImpl' ahora acepta 'client'
    () => MatchRemoteDataSourceImpl(client: sl()),
  );

  // ===========================================
  // 2. Feature - Field Management
  // ===========================================

  // Presentation (BLoC)
  sl.registerFactory(
    () => FieldBloc(
      getAvailableFields: sl(),
      // ✅ CORREGIDO: Se habilita y se inyecta el Use Case
      reserveField: sl(), 
    ),
  );

  // Domain (Use Cases)
  sl.registerLazySingleton(() => GetAvailableFields(sl()));
  sl.registerLazySingleton(
    () => ReserveField(sl()),
  );

  // Data (Repositories)
  sl.registerLazySingleton<FieldRepository>(
    () => FieldRepositoryImpl(remoteDataSource: sl()),
  );

  // Data Sources
  sl.registerLazySingleton<FieldRemoteDataSource>(
    // ✅ CORREGIDO: 'FieldRemoteDataSourceImpl' ahora acepta 'client'
    () => FieldRemoteDataSourceImpl(client: sl()), 
  );

  // ===========================================
  // 3. Feature - Auth/Core Notifications
  // ===========================================

  // Presentation (BLoC)
  sl.registerFactory(
    () => AuthBloc(
      loginUser: sl(),
      // ✅ Agregado: Inyección del Use Case de registro
      registerUser: sl(), 
      repository: sl(), 
    ),
  );

  // Domain (Use Cases)
  sl.registerLazySingleton(() => SubscribeToNotifications(sl()));
  sl.registerLazySingleton(() => LoginUser(sl()));
  // ✅ Nuevo: Use Case de Registro
  sl.registerLazySingleton(() => RegisterUser(sl())); 

  // Data (Repositories)
  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(remoteDataSource: sl()),
  );

  // Data Sources
  sl.registerLazySingleton<AuthRemoteDataSource>(
    // ✅ CORREGIDO: AuthRemoteDataSourceImpl ahora acepta 'client'
    () => AuthRemoteDataSourceImpl(), 
  );
  
  // Core (Services)
  sl.registerLazySingleton<NotificationService>(
    // ✅ CORREGIDO: Usamos la implementación concreta
    () => NotificationServiceImpl(), 
  );

  // ===========================================
  // 4. Feature - League Management
  // ===========================================

  // Presentation (BLoC)
  sl.registerFactory(() => LeagueBloc(getLeagueStandings: sl()));

  // Domain (Use Cases)
  sl.registerLazySingleton(() => GetLeagueStandings(sl()));

  // Data (Repositories)
  sl.registerLazySingleton<LeagueRepository>(
    () => LeagueRepositoryImpl(remoteDataSource: sl()),
  );

  // Data Sources
  sl.registerLazySingleton<LeagueRemoteDataSource>(
    // ✅ CORREGIDO: 'LeagueRemoteDataSourceImpl' ahora acepta 'client'
    () => LeagueRemoteDataSourceImpl(client: sl()), 
  );

  // ===========================================
  // 5. Core (External)
  // ===========================================

  // Dependencias Externas (Cliente HTTP, Verificador de Red)
  sl.registerLazySingleton(() => http.Client());

  // ===========================================
  // 6. Inicialización
  // ===========================================

  // Al iniciar la app, dispara la verificación de autenticación
  // Nota: Esto asume que tienes un evento AppStarted en tu AuthBloc
  // sl<AuthBloc>().add(AppStarted()); 
  // sl<NotificationService>().initializeNotifications();
}
