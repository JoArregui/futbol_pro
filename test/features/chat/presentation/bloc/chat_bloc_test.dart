import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:futbol_pro/core/services/socket_service.dart';
import 'package:futbol_pro/features/chat/domain/repositories/chat_repository.dart';
import 'package:futbol_pro/features/chat/domain/usecases/create_chat.dart';
import 'package:futbol_pro/features/chat/domain/usecases/get_chat_rooms.dart';
import 'package:futbol_pro/features/chat/domain/usecases/get_messages.dart';
import 'package:futbol_pro/features/chat/domain/usecases/mark_as_read.dart';
import 'package:futbol_pro/features/chat/domain/usecases/search_users.dart';
import 'package:futbol_pro/features/chat/domain/usecases/send_message.dart';
import 'package:futbol_pro/features/chat/presentation/bloc/chat_bloc.dart';
import 'package:futbol_pro/features/auth/domain/repositories/auth_repository.dart';

class MockChatRepo extends Mock implements ChatRepository {}
class MockAuthRepo extends Mock implements AuthRepository {}
class MockSocket extends Mock implements SocketService {}

void main() {
  test('ChatBloc initial state is ChatInitial', () {
    final chatRepo = MockChatRepo();
    final authRepo = MockAuthRepo();
    final socket = MockSocket();
    when(() => authRepo.getCurrentUserId()).thenReturn('uid-1');
    when(() => authRepo.getCurrentUserName()).thenReturn('Tester');
    when(() => socket.connect(userId: any(named: 'userId'))).thenReturn(null);
    final bloc = ChatBloc(
      getMessages: GetMessages(chatRepo),
      sendMessage: SendMessage(chatRepo),
      markAsRead: MarkAsRead(chatRepo),
      getChatRooms: GetChatRooms(chatRepo),
      createChat: CreateChat(chatRepo),
      searchUsers: SearchUsers(chatRepo),
      authRepository: authRepo,
      socketService: socket,
    );
    expect(bloc.state, isA<ChatInitial>());
    bloc.close();
  });
}
