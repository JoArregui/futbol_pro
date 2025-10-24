import 'package:get_it/get_it.dart';
import 'package:http/http.dart' as http; // Necesitas este import

// Dependencias de Core y Errores (Asegúrate de que existan)
// import 'package:internet_connection_checker/internet_connection_checker.dart'; // Si lo vas a usar

// Match Scheduling Feature
import '../features/match_scheduling/data/datasources/match_remote_data_source.dart';
import '../features/match_scheduling/data/datasources/match_remote_data_source_impl.dart';
import '../features/match_scheduling/data/repositories/match_repository_impl.dart';
import '../features/match_scheduling/domain/repositories/match_repository.dart';
import '../features/match_scheduling/domain/usecases/schedule_friendly_match.dart';
import '../features/match_scheduling/domain/usecases/join_match.dart'; // ¡NUEVO!
import '../features/match_scheduling/presentation/bloc/match_bloc.dart'; // Necesitas este import
import '../features/field_management/data/datasources/field_remote_data_source.dart';
import '../features/field_management/data/datasources/field_remote_data_source_impl.dart';
import '../features/field_management/data/repositories/field_repository_impl.dart';
import '../features/field_management/domain/repositories/field_repository.dart';
import '../features/field_management/domain/usecases/get_available_fields.dart';

final sl = GetIt.instance; // sl = Service Locator

void init() {
  // ===========================================
  // Feature - Match Scheduling
  // ===========================================

  // 1. Presentation (BLoC) - Registrado como Factory para obtener nuevas instancias
  sl.registerFactory(() => MatchBloc(
        scheduleMatch: sl(),
        joinMatch: sl(), // ¡INYECCIÓN DEL NUEVO USE CASE!
        // ... otros Use Cases
      ));

  // 2. Domain (Use Cases) - Registrado como LazySingleton
  sl.registerLazySingleton(() => ScheduleFriendlyMatch(sl()));
  sl.registerLazySingleton(() => JoinMatch(sl())); // ¡NUEVO USE CASE REGISTRADO!

  // 3. Data (Repositories) - Registrado como LazySingleton
  // MatchRepositoryImpl ahora depende de MatchRemoteDataSource
  sl.registerLazySingleton<MatchRepository>(
      () => MatchRepositoryImpl(remoteDataSource: sl()));

  // 4. Data Sources (Remote, Local) - Registrado como LazySingleton
  // MatchRemoteDataSourceImpl ahora depende de http.Client
  sl.registerLazySingleton<MatchRemoteDataSource>(
      () => MatchRemoteDataSourceImpl(client: sl()));

  // ===========================================
  // Feature - Field Management (NUEVO)
  // ===========================================

  // 1. Presentation (BLoC) 
  // sl.registerFactory(() => FieldBloc(getAvailableFields: sl(), reserveField: sl()));

  // 2. Domain (Use Cases)
  sl.registerLazySingleton(() => GetAvailableFields(sl())); 
  // sl.registerLazySingleton(() => ReserveField(sl())); // El Use Case de reserva

  // 3. Data (Repositories)
  sl.registerLazySingleton<FieldRepository>(
      () => FieldRepositoryImpl(remoteDataSource: sl()));

  // 4. Data Sources
  sl.registerLazySingleton<FieldRemoteDataSource>(
      () => FieldRemoteDataSourceImpl(client: sl()));

  // ===========================================
  // Core (External)
  // ===========================================

  // 5. Dependencias Externas (Cliente HTTP, Verificador de Red) - Registrado como LazySingleton
  sl.registerLazySingleton(() => http.Client());
  // sl.registerLazySingleton(() => InternetConnectionChecker());

  // ===========================================
  // Feature - Match Scheduling (ACTUALIZADO)
  // ===========================================

  // 1. Presentation (BLoC)
  sl.registerFactory(() => MatchBloc(
        scheduleMatch: sl(),
        joinMatch: sl(),
        generateBalancedTeams: sl(), // ¡INYECCIÓN DEL NUEVO USE CASE!
      ));

  // 2. Domain (Use Cases)
  sl.registerLazySingleton(() => ScheduleFriendlyMatch(sl()));
  sl.registerLazySingleton(() => JoinMatch(sl()));
  sl.registerLazySingleton(() => GenerateBalancedTeams()); // ¡NUEVO USE CASE REGISTRADO!

  // 3. Data (Repositories) - sin cambios si el Use Case no llama al Repo

  // ... (resto de registros)
}
}