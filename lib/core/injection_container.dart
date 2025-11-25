import 'package:get_it/get_it.dart';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart'; // Mantenido por si otras features lo usan

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
import '../features/chat/presentation/bloc/chat_bloc.dart';

// Core Services
// Asegúrate de tener una implementación llamada NotificationServiceImpl
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

Future<void> init() async {
    print('🚀 Iniciando registro de dependencias...');

    // ===========================================
    // 1. Core (External)
    // ===========================================
    print('📦 Registrando dependencias Core...');
    // Instancias externas
    sl.registerLazySingleton(() => http.Client());
    sl.registerLazySingleton(() => FirebaseFirestore.instance);

    // Core (Services)
    // Asumiendo que existe NotificationServiceImpl
    sl.registerLazySingleton<NotificationService>(
        () => NotificationServiceImpl(), 
    );
    print('✅ Core registrado correctamente');

    // ===========================================
    // 2. Feature - Auth
    // ===========================================
    print('🔐 Registrando Auth Feature...');

    // Data Sources
    sl.registerLazySingleton<AuthRemoteDataSource>(
        // 🟢 CORREGIDO: Solo se pasa http.Client
        () => AuthRemoteDataSourceImpl(
            client: sl<http.Client>(),        
        ), 
    );
    print('  ✅ AuthRemoteDataSource registrado');

    // Data (Repositories)
    sl.registerLazySingleton<AuthRepository>(
        () => AuthRepositoryImpl(remoteDataSource: sl<AuthRemoteDataSource>()),
    );
    print('  ✅ AuthRepository registrado');

    // Domain (Use Cases)
    sl.registerLazySingleton(() => SubscribeToNotifications(sl<NotificationService>()));
    sl.registerLazySingleton(() => LoginUser(sl<AuthRepository>()));
    sl.registerLazySingleton(() => RegisterUser(sl<AuthRepository>()));
    print('  ✅ UseCases registrados');

    // Presentation (BLoC)
    sl.registerFactory(
        () => AuthBloc(
            loginUser: sl<LoginUser>(),
            registerUser: sl<RegisterUser>(),
            repository: sl<AuthRepository>(),
        ),
    );
    print('  ✅ AuthBloc registrado');

    // ===========================================
    // 3. Feature - Profile Management
    // ===========================================
    print('👤 Registrando Profile Feature...');

    // Data Sources
    sl.registerLazySingleton<ProfileRemoteDataSource>(
        // 🟢 CORREGIDO: Solo se pasa http.Client
        () => ProfileRemoteDataSourceImpl(
            client: sl<http.Client>(),
        ),
    );
    print('  ✅ ProfileRemoteDataSource registrado');

    // Data (Repositories)
    sl.registerLazySingleton<ProfileRepository>(
        () => ProfileRepositoryImpl(remoteDataSource: sl<ProfileRemoteDataSource>()),
    );
    print('  ✅ ProfileRepository registrado');

    // Domain (Use Cases)
    sl.registerLazySingleton(() => GetProfile(sl<ProfileRepository>()));
    sl.registerLazySingleton(() => UpdateProfile(sl<ProfileRepository>()));
    sl.registerLazySingleton(() => CreateProfile(sl<ProfileRepository>())); 
    print('  ✅ UseCases registrados');

    // Presentation (BLoC)
    // ⚠️ NOTA: Asumo que getCurrentUserId() está disponible en AuthRepository
    sl.registerFactory(
        () => ProfileBloc(
            getProfile: sl<GetProfile>(),
            updateProfile: sl<UpdateProfile>(),
            createProfile: sl<CreateProfile>(),
            currentUserId: sl<AuthRepository>().getCurrentUserId(),
        ),
    );
    print('✅ Profile Feature registrado');

    // ===========================================
    // 4. Feature - Chat Management 💬
    // ===========================================
    print('💬 Registrando Chat Feature...');

    // Data Sources
    sl.registerLazySingleton<ChatRemoteDataSource>(
        // 🟢 CORREGIDO: Solo se pasa http.Client
        () => ChatRemoteDataSourceImpl(
            client: sl<http.Client>(), 
        ), 
    );
    print('  ✅ ChatRemoteDataSource registrado');

    // Data (Repositories)
    sl.registerLazySingleton<ChatRepository>(
        () => ChatRepositoryImpl(remoteDataSource: sl<ChatRemoteDataSource>()),
    );
    print('  ✅ ChatRepository registrado');

    // Domain (Use Cases)
    sl.registerLazySingleton(() => GetMessages(sl<ChatRepository>()));
    sl.registerLazySingleton(() => SendMessage(sl<ChatRepository>()));
    sl.registerLazySingleton(() => MarkAsRead(sl<ChatRepository>()));
    sl.registerLazySingleton(() => GetChatRooms(sl<ChatRepository>()));
    print('  ✅ UseCases registrados');

    // Presentation (BLoC)
    // ⚠️ NOTA: Asumo que getCurrentUserId() y getCurrentUserName() están disponibles en AuthRepository
    sl.registerFactory(
        () => ChatBloc(
            getMessages: sl<GetMessages>(),
            sendMessage: sl<SendMessage>(),
            markAsRead: sl<MarkAsRead>(),
            getChatRooms: sl<GetChatRooms>(),
            currentUserId: sl<AuthRepository>().getCurrentUserId(),
            currentUserName: sl<AuthRepository>().getCurrentUserName(), 
        ),
    );
    print('✅ Chat Feature registrado');

    // ===========================================
    // 5. Feature - Match Scheduling
    // ===========================================
    print('⚽ Registrando Match Scheduling Feature...');

    // Data Sources
    sl.registerLazySingleton<MatchRemoteDataSource>(
        () => MatchRemoteDataSourceImpl(client: sl<http.Client>()),
    );
    print('  ✅ MatchRemoteDataSource registrado');

    // Data (Repositories)
    sl.registerLazySingleton<MatchRepository>(
        () => MatchRepositoryImpl(remoteDataSource: sl<MatchRemoteDataSource>()),
    );
    print('  ✅ MatchRepository registrado');

    // Domain (Use Cases)
    sl.registerLazySingleton(() => ScheduleFriendlyMatch(sl<MatchRepository>()));
    sl.registerLazySingleton(() => JoinMatch(sl<MatchRepository>()));
    sl.registerLazySingleton(() => GenerateBalancedTeams()); // No requiere dependencias
    sl.registerLazySingleton(() => GetMatchDetails(sl<MatchRepository>()));
    sl.registerLazySingleton(() => UpdateMatchWithTeams(sl<MatchRepository>()));
    print('  ✅ UseCases registrados');

    // Presentation (BLoC)
    sl.registerFactory(
        () => MatchBloc(
            scheduleFriendlyMatch: sl<ScheduleFriendlyMatch>(),
            joinMatch: sl<JoinMatch>(),
            generateBalancedTeams: sl<GenerateBalancedTeams>(),
            getMatchDetails: sl<GetMatchDetails>(),
            updateMatchWithTeams: sl<UpdateMatchWithTeams>(),
        ),
    );
    print('✅ Match Scheduling Feature registrado');

    // ===========================================
    // 6. Feature - Field Management
    // ===========================================
    print('🏟️ Registrando Field Management Feature...');

    // Data Sources
    sl.registerLazySingleton<FieldRemoteDataSource>(
        () => FieldRemoteDataSourceImpl(client: sl<http.Client>()),
    );
    print('  ✅ FieldRemoteDataSource registrado');

    // Data (Repositories)
    sl.registerLazySingleton<FieldRepository>(
        () => FieldRepositoryImpl(remoteDataSource: sl<FieldRemoteDataSource>()),
    );
    print('  ✅ FieldRepository registrado');

    // Domain (Use Cases)
    sl.registerLazySingleton(() => GetAvailableFields(sl<FieldRepository>()));
    sl.registerLazySingleton(
        () => ReserveField(sl<FieldRepository>()),
    );
    print('  ✅ UseCases registrados');

    // Presentation (BLoC)
    sl.registerFactory(
        () => FieldBloc(
            getAvailableFields: sl<GetAvailableFields>(),
            reserveField: sl<ReserveField>(),
        ),
    );
    print('✅ Field Management Feature registrado');

    // ===========================================
    // 7. Feature - League Management
    // ===========================================
    print('🏆 Registrando League Management Feature...');

    // Data Sources
    sl.registerLazySingleton<LeagueRemoteDataSource>(
        () => LeagueRemoteDataSourceImpl(client: sl<http.Client>()),
    );
    print('  ✅ LeagueRemoteDataSource registrado');

    // Data (Repositories)
    sl.registerLazySingleton<LeagueRepository>(
        () => LeagueRepositoryImpl(remoteDataSource: sl<LeagueRemoteDataSource>()),
    );
    print('  ✅ LeagueRepository registrado');

    // Domain (Use Cases)
    sl.registerLazySingleton(() => GetLeagueStandings(sl<LeagueRepository>()));
    print('  ✅ UseCases registrados');

    // Presentation (BLoC)
    sl.registerFactory(() => LeagueBloc(getLeagueStandings: sl<GetLeagueStandings>()));
    print('✅ League Management Feature registrado');

    print('🎉 Todas las dependencias registradas exitosamente!');
}