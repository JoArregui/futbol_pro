import 'package:dartz/dartz.dart';
import 'package:futbol_pro/core/errors/exceptions.dart';
import 'package:futbol_pro/core/errors/failures.dart';
import 'dart:async';
import '../../domain/repositories/chat_repository.dart';
import '../../domain/entities/message.dart';
import '../../domain/entities/chat_room.dart';
import '../datasources/chat_datasource.dart';

class ChatRepositoryImpl implements ChatRepository {
  final ChatRemoteDataSource remoteDataSource;

  ChatRepositoryImpl({required this.remoteDataSource});

  // ===============================================
  // 🔄 CORREGIDO: De Stream a Future para API REST
  // ===============================================
  @override
  Future<Either<Failure, List<Message>>> getMessages(String roomId) async {
    try {
      // 1. Llama al nuevo método Future
      final messageModels = await remoteDataSource.getMessages(roomId);

      // 2. Mapea los modelos a entidades
      final entities = messageModels.map<Message>((model) => model).toList();

      return Right(entities);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return const Left(
          ServerFailure('Error desconocido al obtener los mensajes.'));
    }
  }

  @override
  Future<Either<Failure, void>> sendMessage({
    required String roomId,
    required String senderId,
    required String senderName,
    required String text,
  }) async {
    try {
      await remoteDataSource.sendMessage(
        roomId: roomId,
        senderId: senderId,
        senderName: senderName,
        text: text,
      );
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return const Left(
          ServerFailure('Error desconocido al enviar el mensaje.'));
    }
  }

  @override
  Future<Either<Failure, void>> markMessagesAsRead(
      String roomId, String userId) async {
    try {
      await remoteDataSource.markMessagesAsRead(roomId, userId);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on Exception {
      // Cambiado de CacheFailure, ya que ahora es una llamada a la API
      return const Left(
          ServerFailure('No se pudo actualizar el estado de lectura.'));
    }
  }

  // ===============================================
  // 🔄 CORREGIDO: De Stream a Future para API REST
  // ===============================================
  @override
  Future<Either<Failure, List<ChatRoom>>> getChatRooms(String userId) async {
    try {
      // 1. Llama al nuevo método Future
      final roomModels = await remoteDataSource.getChatRooms(userId);

      // 2. Mapea los modelos a entidades
      final entities = roomModels.map<ChatRoom>((model) => model).toList();

      return Right(entities);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return const Left(
          ServerFailure('Error desconocido al obtener las salas de chat.'));
    }
  }
}
