import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dartz/dartz.dart';
import 'package:futbol_pro/core/errors/exceptions.dart';
import 'package:futbol_pro/core/errors/failures.dart';
import '../../domain/repositories/chat_repository.dart';
import '../../domain/entities/message.dart';
import '../../domain/entities/chat_room.dart';
import '../datasources/chat_datasource.dart';
import '../datasources/chat_local_datasource.dart';

class ChatRepositoryImpl implements ChatRepository {
  final ChatRemoteDataSource remoteDataSource;
  final ChatLocalDataSource localDataSource;
  final Connectivity connectivity;

  ChatRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
    Connectivity? connectivity,
  }) : connectivity = connectivity ?? Connectivity();

  Future<bool> get _isOnline async {
    final res = await connectivity.checkConnectivity();
    return res.contains(ConnectivityResult.mobile) ||
        res.contains(ConnectivityResult.wifi) ||
        res.contains(ConnectivityResult.ethernet);
  }

  // ===============================================
  // 🔄 CORREGIDO: De Stream a Future para API REST
  // ===============================================
  @override
  Future<Either<Failure, List<Message>>> getMessages(String roomId) async {
    final online = await _isOnline;
    if (online) {
      try {
        final models = await remoteDataSource.getMessages(roomId);
        final entities = models.map<Message>((m) => m).toList();
        // cache híbrido: guarda en Isar
        await localDataSource.cacheMessages(roomId, entities);
        return Right(entities);
      } on ServerException catch (e) {
        // fallback a caché
        final cached = await localDataSource.getCachedMessages(roomId);
        if (cached.isNotEmpty) return Right(cached);
        return Left(ServerFailure(e.message));
      }
    } else {
      final cached = await localDataSource.getCachedMessages(roomId);
      if (cached.isNotEmpty) return Right(cached);
      return const Left(CacheFailure('Sin conexión y sin mensajes en caché'));
    }
  }

  @override
  Future<Either<Failure, void>> sendMessage({
    required String roomId,
    required String senderId,
    required String senderName,
    required String text,
    String? imageUrl,
    String? clientId,
  }) async {
    final online = await _isOnline;
    final cid = (clientId != null && clientId.isNotEmpty)
        ? clientId
        : 'c${DateTime.now().microsecondsSinceEpoch}-$senderId';
    final tempMsg = Message(
      id: cid,
      senderId: senderId,
      senderName: senderName,
      text: text,
      timestamp: DateTime.now(),
      status: online ? MessageStatus.sent : MessageStatus.sending,
      type: imageUrl != null ? MessageType.image : MessageType.text,
      imageUrl: imageUrl,
    );
    // guarda optimista en Isar
    await localDataSource.cacheMessage(roomId, tempMsg);
    if (!online)
      return const Left(
        CacheFailure('Mensaje guardado offline, se enviará al reconectar'),
      );
    try {
      await remoteDataSource.sendMessage(
        roomId: roomId,
        senderId: senderId,
        senderName: senderName,
        text: text,
        imageUrl: imageUrl,
        clientId: cid,
      );
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return const Left(
        ServerFailure('Error desconocido al enviar el mensaje.'),
      );
    }
  }

  @override
  Future<Either<Failure, void>> markMessagesAsRead(
    String roomId,
    String userId,
  ) async {
    try {
      await remoteDataSource.markMessagesAsRead(roomId, userId);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on Exception {
      // Cambiado de CacheFailure, ya que ahora es una llamada a la API
      return const Left(
        ServerFailure('No se pudo actualizar el estado de lectura.'),
      );
    }
  }

  // ===============================================
  // 🔄 CORREGIDO: De Stream a Future para API REST
  // ===============================================
  @override
  Future<Either<Failure, List<ChatRoom>>> getChatRooms(String userId) async {
    final online = await _isOnline;
    if (online) {
      try {
        final models = await remoteDataSource.getChatRooms(userId);
        final entities = models.map<ChatRoom>((m) => m).toList();
        await localDataSource.cacheChatRooms(userId, entities);
        return Right(entities);
      } on ServerException catch (e) {
        final cached = await localDataSource.getCachedChatRooms(userId);
        if (cached.isNotEmpty) return Right(cached);
        return Left(ServerFailure(e.message));
      }
    } else {
      final cached = await localDataSource.getCachedChatRooms(userId);
      if (cached.isNotEmpty) return Right(cached);
      return const Left(CacheFailure('Sin conexión y sin chats en caché'));
    }
  }

  @override
  Future<Either<Failure, ChatRoom>> createChat({
    required String title,
    required String type,
    required List<String> memberIds,
    String? relatedEntityId,
  }) async {
    try {
      final model = await remoteDataSource.createChat(
        title: title,
        type: type,
        memberIds: memberIds,
        relatedEntityId: relatedEntityId,
      );
      return Right(model);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return const Left(ServerFailure('Error al crear chat.'));
    }
  }

  @override
  Future<Either<Failure, List<Map<String, dynamic>>>> searchUsers({
    required String query,
    required String excludeUid,
  }) async {
    try {
      final res = await remoteDataSource.searchUsers(
        query: query,
        excludeUid: excludeUid,
      );
      return Right(res);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return const Left(ServerFailure('Error búsqueda usuarios.'));
    }
  }
}
