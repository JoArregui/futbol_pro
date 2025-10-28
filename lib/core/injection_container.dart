import 'package:get_it/get_it.dart';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart'; 

// Auth Feature
import '../features/auth/data/datasources/auth_remote_dataSource.dart';
import '../features/auth/data/repositories/auth_repository_impl.dart';
import '../features/auth/domain/repositories/auth_repository.dart';
import '../features/auth/domain/usecases/login_user.dart';
import '../features/auth/domain/usecases/register_user.dart';
import '../features/auth/domain/usecases/subscribe_to_notifications.dart';
import '../features/auth/presentation/bloc/auth_bloc.dart';

// Profile Feature
import '../features/chat/data/datasources/chat_datasource.dart';
import '../features/profile/data/datasources/profile_remote_datasource.dart';
import '../features/profile/data/repositories/profile_repository_impl.dart';
import '../features/profile/domain/repositories/profile_repository.dart';
import '../features/profile/domain/usecases/get_profile.dart';
import '../features/profile/domain/usecases/update_profile.dart';
import '../features/profile/presentation/bloc/profile_bloc.dart'; 

// Chat Feature 💬
import '../features/chat/data/repositories/chat_repository_impl.dart';
import '../features/chat/domain/repositories/chat_repository.dart';
import '../features/chat/domain/usecases/get_messages_stream.dart'; 
import '../features/chat/domain/usecases/send_message.dart';
import '../features/chat/domain/usecases/mark_as_read.dart'; 
import '../features/chat/domain/usecases/get_chat_rooms_stream.dart'; 
import '../features/chat/presentation/bloc/chat_bloc.dart';

// Core Services
import '../core/services/notification_service.dart';

// Field Management Feature
import '../features/field_management/data/datasources/field_remote_datasource.dart';
import '../features/field_management/data/repositories/field_repository_impl.dart';
import '../features/field_management/domain/repositories/field_repository.dart';
import '../features/field_management/domain/usecases/get_available_fields.dart';
import '../features/field_management/domain/usecases/reserve_field.dart';
import '../features/field_management/presentation/bloc/field_bloc.dart';

// League Management Feature
import '../features/league_management/data/datasources/league_remote_datasource.dart';
import '../features/league_management/data/repositories/league_repository_impl.dart';
import '../features/league_management/domain/repositories/league_repository.dart';
import '../features/league_management/domain/usecases/get_league_standings.dart';
import '../features/league_management/presentation/bloc/league_bloc.dart';

// Match Scheduling Feature
import '../features/match_scheduling/data/datasources/match_remote_datasource.dart';
import '../features/match_scheduling/data/repositories/match_repository_impl.dart';
import '../features/match_scheduling/domain/repositories/match_repository.dart';
import '../features/match_scheduling/domain/usecases/get_match_details.dart';
import '../features/match_scheduling/domain/usecases/schedule_friendly_match.dart';
import '../features/match_scheduling/domain/usecases/join_match.dart';
import '../features/match_scheduling/domain/usecases/generate_balanced_teams.dart';
import '../features/match_scheduling/domain/usecases/update_match_with_teams.dart';
import '../features/match_scheduling/presentation/bloc/match_bloc.dart';


final sl = GetIt.instance; // sl = Service Locator

void init() {
  // ===========================================
  // 1. Core (External)
  // ===========================================
  sl.registerLazySingleton(() => http.Client());
  sl.registerLazySingleton(() => FirebaseFirestore.instance); 

  // Core (Services)
  sl.registerLazySingleton<NotificationService>(
    () => NotificationServiceImpl(), 
  );

  // ===========================================
  // 2. Feature - Auth
  // ===========================================

  // Data Sources
  sl.registerLazySingleton<AuthRemoteDataSource>(
    () => AuthRemoteDataSourceImpl(), 
  );

  // Data (Repositories)
  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(remoteDataSource: sl()),
  );
  
  // Domain (Use Cases)
  sl.registerLazySingleton(() => SubscribeToNotifications(sl()));
  sl.registerLazySingleton(() => LoginUser(sl()));
  sl.registerLazySingleton(() => RegisterUser(sl())); 

  // Presentation (BLoC)
  sl.registerFactory(
    () => AuthBloc(
      loginUser: sl(),
      registerUser: sl(), 
      repository: sl(), // Requerido por el AuthBloc
    ),
  );

  // ===========================================
  // 3. Feature - Profile Management
  // ===========================================
  
  // Data Sources
  sl.registerLazySingleton<ProfileRemoteDataSource>(
    () => ProfileRemoteDataSourceImpl(firestore: sl()),
  );

  // Data (Repositories)
  sl.registerLazySingleton<ProfileRepository>(
    () => ProfileRepositoryImpl(remoteDataSource: sl()),
  );

  // Domain (Use Cases)
  sl.registerLazySingleton(() => GetProfile(sl()));
  sl.registerLazySingleton(() => UpdateProfile(sl()));

  // Presentation (BLoC)
  sl.registerFactory(
    () => ProfileBloc(
      getProfile: sl(),
      updateProfile: sl(),
      // ⚠️ ASUMO que AuthRepository tiene el método getCurrentUserId()
      currentUserId: sl<AuthRepository>().getCurrentUserId(),
    ),
  );

  // ===========================================
  // 4. Feature - Chat Management 💬
  // ===========================================
  
  // Data Sources
  sl.registerLazySingleton<ChatRemoteDataSource>(
    // 🟢 CORREGIDO: Usando constructor sin argumentos para el Mock
    () => ChatRemoteDataSourceImpl(), 
  );
  
  // Data (Repositories)
  sl.registerLazySingleton<ChatRepository>(
    () => ChatRepositoryImpl(remoteDataSource: sl()),
  );

  // Domain (Use Cases)
  sl.registerLazySingleton(() => GetMessagesStream(sl()));
  sl.registerLazySingleton(() => SendMessage(sl()));
  sl.registerLazySingleton(() => MarkAsRead(sl()));
  sl.registerLazySingleton(() => GetChatRoomsStream(sl()));

  // Presentation (BLoC)
  sl.registerFactory(
    () => ChatBloc(
      getMessagesStream: sl(),
      sendMessage: sl(),
      markAsRead: sl(),
      getChatRoomsStream: sl(),
      currentUserId: sl<AuthRepository>().getCurrentUserId(),
    ),
  );

  // ===========================================
  // 5. Feature - Match Scheduling
  // ===========================================

  // Data Sources
  sl.registerLazySingleton<MatchRemoteDataSource>(
    () => MatchRemoteDataSourceImpl(client: sl()),
  );

  // Data (Repositories)
  sl.registerLazySingleton<MatchRepository>(
    () => MatchRepositoryImpl(remoteDataSource: sl()),
  );

  // Domain (Use Cases)
  sl.registerLazySingleton(() => ScheduleFriendlyMatch(sl()));
  sl.registerLazySingleton(() => JoinMatch(sl()));
  sl.registerLazySingleton(() => GenerateBalancedTeams());
  sl.registerLazySingleton(() => GetMatchDetails(sl()));
  sl.registerLazySingleton(() => UpdateMatchWithTeams(sl()));

  // Presentation (BLoC)
  sl.registerFactory(
    () => MatchBloc(
      scheduleFriendlyMatch: sl(), 
      joinMatch: sl(),
      generateBalancedTeams: sl(), 
      getMatchDetails: sl(),
      updateMatchWithTeams: sl(),
    ),
  );

  // ===========================================
  // 6. Feature - Field Management
  // ===========================================

  // Data Sources
  sl.registerLazySingleton<FieldRemoteDataSource>(
    () => FieldRemoteDataSourceImpl(client: sl()), 
  );

  // Data (Repositories)
  sl.registerLazySingleton<FieldRepository>(
    () => FieldRepositoryImpl(remoteDataSource: sl()),
  );

  // Domain (Use Cases)
  sl.registerLazySingleton(() => GetAvailableFields(sl()));
  sl.registerLazySingleton(
    () => ReserveField(sl()),
  );

  // Presentation (BLoC)
  sl.registerFactory(
    () => FieldBloc(
      getAvailableFields: sl(),
      reserveField: sl(), 
    ),
  );

  // ===========================================
  // 7. Feature - League Management
  // ===========================================

  // Data Sources
  sl.registerLazySingleton<LeagueRemoteDataSource>(
    () => LeagueRemoteDataSourceImpl(client: sl()), 
  );

  // Data (Repositories)
  sl.registerLazySingleton<LeagueRepository>(
    () => LeagueRepositoryImpl(remoteDataSource: sl()),
  );

  // Domain (Use Cases)
  sl.registerLazySingleton(() => GetLeagueStandings(sl()));
  
  // Presentation (BLoC)
  sl.registerFactory(() => LeagueBloc(getLeagueStandings: sl()));
}
