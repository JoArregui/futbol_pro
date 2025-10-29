import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:futbol_pro/core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart'; 
import '../repositories/chat_repository.dart';

class MarkAsRead implements UseCase<void, MarkAsReadParams> {
  final ChatRepository repository;

  const MarkAsRead(this.repository);

  @override
  Future<Either<Failure, void>> call(MarkAsReadParams params) async {
    // Llama al repositorio para marcar los mensajes como leídos usando
    // el ID de la sala del parámetro y el ID del usuario actual inyectado.
    return await repository.markMessagesAsRead(
      params.roomId, 
      params.userId,
    );
  }
}

class MarkAsReadParams extends Equatable {
  final String roomId;
  final String userId;

  const MarkAsReadParams({required this.roomId, required this.userId});

  @override
  List<Object> get props => [roomId, userId];
}
