import 'dart:async';
import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/stream_usecase.dart'; 
import '../../../../core/usecases/usecase.dart';
import '../entities/chat_room.dart';
import '../repositories/chat_repository.dart';

/// Define el caso de uso para obtener un Stream de todas las salas de chat.
class GetChatRoomsStream implements StreamUseCase<List<ChatRoom>, NoParams> {
  final ChatRepository repository;

  GetChatRoomsStream(this.repository);

  // El método ya no tiene errores porque ChatRepository.getChatRooms()
  // ahora devuelve Stream<Either<...>> y no requiere argumentos.
  @override
  Stream<Either<Failure, List<ChatRoom>>> call(NoParams params) {
    // 💡 CORREGIDO IMPLÍCITAMENTE: La firma del repositorio coincide, y se llama sin argumentos.
    return repository.getChatRooms(); 
  }
}