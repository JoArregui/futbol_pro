import 'package:dartz/dartz.dart';
import 'package:futbol_pro/core/errors/exceptions.dart';
import 'package:futbol_pro/core/errors/failures.dart';
import 'dart:async'; // Necesario para la manipulación de streams
import '../../domain/repositories/chat_repository.dart';
import '../../domain/entities/message.dart';
import '../../domain/entities/chat_room.dart';
import '../datasources/chat_datasource.dart';


class ChatRepositoryImpl implements ChatRepository {
  final ChatRemoteDataSource remoteDataSource;

  ChatRepositoryImpl({required this.remoteDataSource});

  @override
  Stream<Either<Failure, List<Message>>> getMessagesStream(String roomId) {
    // Escuchamos el stream crudo del DataSource
    final stream = remoteDataSource.getMessagesStream(roomId);

    // Mapeamos el stream: List<MessageModel> a Stream<Either<Failure, List<Message>>>
    return stream.map((messageModels) {
      try {
        // Mapeamos los modelos a entidades de dominio
        final entities = messageModels.map<Message>((model) => model as Message).toList();
        return Right(entities);
      } on Exception {
        // Si hay un error durante el mapeo o la deserialización
        return const Left(ServerFailure('Error al procesar los mensajes recibidos.'));
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
      return const Left(ServerFailure('Error desconocido al enviar el mensaje.'));
    }
  }

  @override
  Future<Either<Failure, void>> markMessagesAsRead(
      String roomId, String userId) async {
    try {
      await remoteDataSource.markMessagesAsRead(roomId, userId);
      return const Right(null);
    } on Exception {
      return const Left(CacheFailure('No se pudo actualizar el estado de lectura.'));
    }
  }

  @override
  Stream<Either<Failure, List<ChatRoom>>> getChatRooms() {
    // La fuente de datos devuelve un Future (no reactivo).
    final futureRooms = remoteDataSource.getChatRooms('user-001'); // 💡 Se asume ID fijo temporal

    // Convertimos el Future<List<ChatRoomModel>> a Stream<Either<Failure, List<ChatRoom>>>
    return Stream.fromFuture(futureRooms)
      .map<Either<Failure, List<ChatRoom>>>((roomModels) {
        // En caso de éxito del Future
        return Right(roomModels);
      })
      // 💡 CORREGIDO: Usamos el método .handleError() del Stream para capturar el error.
      // Cuando se usa .handleError, el Stream se cierra después de emitir el error,
      // a menos que se devuelva un Stream que continúe. Para este caso estático, es suficiente.
      .handleError((error, stackTrace) {
        // Creamos un nuevo Stream que solo emite el error y se cierra.
        // Dado que Stream.fromFuture solo emite un valor, el error es el fin del Stream.
        if (error is ServerException) {
            throw Left(ServerFailure(error.message));
        }
        throw const Left(ServerFailure('Error al obtener la lista de salas de chat.'));
      })
      // El error se lanza como una entidad Left, pero el método map espera un Right.
      // El enfoque más limpio es usar un StreamController o un paquete externo, 
      // pero para evitar la dependencia, mapeamos el error antes de que se propague.
      .transform(StreamTransformer.fromHandlers(
        handleData: (data, sink) => sink.add(data), // Si hay datos, los pasamos.
        handleError: (error, stackTrace, sink) {
          // El error que lanzamos en handleError es capturado aquí
          if (error is Left<Failure, dynamic>) {
            sink.add(error as Left<Failure, List<ChatRoom>>);
          } else {
            // Error de mapeo o inesperado
            sink.add(const Left(ServerFailure('Error inesperado al obtener salas.')));
          }
          sink.close();
        },
      ));
  }
}