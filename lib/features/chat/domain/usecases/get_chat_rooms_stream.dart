import 'dart:async';
import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:futbol_pro/core/errors/failures.dart';
import '../../../../core/usecases/stream_usecase.dart';
import '../entities/chat_room.dart';
import '../repositories/chat_repository.dart';

// 🟢 CORRECCIÓN: Se usa UserIdParams para pasar el ID del usuario
class GetChatRoomsStream implements StreamUseCase<List<ChatRoom>, UserIdParams> { 
  final ChatRepository repository;

  GetChatRoomsStream(this.repository);

  @override
  Stream<Either<Failure, List<ChatRoom>>> call(UserIdParams params) {
    // 🟢 CORRECCIÓN: Llama al nuevo método del repositorio
    return repository.getChatRoomsStream(params.userId); 
  }
}

class UserIdParams extends Equatable {
  final String userId;

  const UserIdParams({required this.userId});
  
  @override
  List<Object> get props => [userId];
}