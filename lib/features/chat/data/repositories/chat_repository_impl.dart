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

  @override
  Stream<Either<Failure, List<Message>>> getMessagesStream(String roomId) {
    final stream = remoteDataSource.getMessagesStream(roomId);

    return stream.map((messageModels) {
      try {
        final entities =
            messageModels.map<Message>((model) => model as Message).toList();
        return Right(entities);
      } on Exception {
        return const Left(
            ServerFailure('Error al procesar los mensajes recibidos.'));
      }
    });
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
    } on ServerException catch (e) { // 🟢 CORRECCIÓN: Usar 'catch (e)'
      return Left(ServerFailure(e.message));
    } on Exception {
      return const Left(
          CacheFailure('No se pudo actualizar el estado de lectura.'));
    }
  }

  // 🟢 CORRECCIÓN: Implementación del nuevo método que usa el userId
  @override
  Stream<Either<Failure, List<ChatRoom>>> getChatRoomsStream(String userId) {
    final roomsStream = remoteDataSource.getChatRoomsStream(userId);

    return roomsStream.map<Either<Failure, List<ChatRoom>>>((roomModels) {
      return Right(roomModels);
    }).handleError((error, stackTrace) {
      if (error is ServerException) {
        throw Left(ServerFailure(error.message));
      }
      throw const Left(
          ServerFailure('Error al obtener la lista de salas de chat.'));
    }).transform(StreamTransformer.fromHandlers(
      handleData: (data, sink) => sink.add(data),
      handleError: (error, stackTrace, sink) {
        if (error is Left<Failure, dynamic>) {
          sink.add(error as Left<Failure, List<ChatRoom>>);
        } else {
          sink.add(
              const Left(ServerFailure('Error inesperado al obtener salas.')));
        }
        sink.close();
      },
    ));
  }
}