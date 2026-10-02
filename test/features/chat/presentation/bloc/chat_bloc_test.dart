import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:futbol_pro/core/services/socket_service.dart';
import 'package:futbol_pro/features/chat/domain/entities/chat_room.dart';
import 'package:futbol_pro/features/chat/domain/entities/message.dart';
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

const _room = ChatRoom(
  id: 'room-1',
  type: ChatRoomType.private,
  title: 'Partido',
  memberIds: ['uid-1', 'uid-2'],
);

void main() {
  setUpAll(() {
    registerFallbackValue(const UserIdParams(userId: 'uid-1'));
    registerFallbackValue(const MessagesParams(roomId: 'room-1'));
    registerFallbackValue(
      const MarkAsReadParams(roomId: 'room-1', userId: 'uid-1'),
    );
    registerFallbackValue(
      const SendParams(
        roomId: 'room-1',
        senderId: 'uid-1',
        content: 'hola',
        senderName: 'Tester',
      ),
    );
  });

  late MockChatRepo chatRepo;
  late MockAuthRepo authRepo;
  late MockSocket socket;

  setUp(() {
    chatRepo = MockChatRepo();
    authRepo = MockAuthRepo();
    socket = MockSocket();
    when(() => authRepo.getCurrentUserId()).thenReturn('uid-1');
    when(() => authRepo.getCurrentUserName()).thenReturn('Tester');
    when(() => authRepo.getAuthToken()).thenAnswer((_) async => null);
    when(
      () => socket.connect(
        userId: any(named: 'userId'),
        token: any(named: 'token'),
      ),
    ).thenReturn(null);
    when(() => socket.joinRoom(any())).thenReturn(null);
    when(() => socket.leaveRoom(any())).thenReturn(null);
    when(
      () => chatRepo.getChatRooms(any()),
    ).thenAnswer((_) async => const Right([_room]));
    when(
      () => chatRepo.getMessages(any()),
    ).thenAnswer((_) async => const Right(<Message>[]));
    when(
      () => chatRepo.markMessagesAsRead(any(), any()),
    ).thenAnswer((_) async => const Right(null));
  });

  ChatBloc buildBloc() => ChatBloc(
    getMessages: GetMessages(chatRepo),
    sendMessage: SendMessage(chatRepo),
    markAsRead: MarkAsRead(chatRepo),
    getChatRooms: GetChatRooms(chatRepo),
    createChat: CreateChat(chatRepo),
    searchUsers: SearchUsers(chatRepo),
    authRepository: authRepo,
    socketService: socket,
  );

  Future<void> openRoom(ChatBloc bloc) async {
    bloc.add(ChatRoomsSubscriptionRequested());
    await bloc.stream.firstWhere((s) => s is ChatRoomsLoaded);
    bloc.add(const ChatRoomSelected('room-1'));
    await bloc.stream.firstWhere((s) => s is ChatRoomSelectedState);
  }

  test('ChatBloc initial state is ChatInitial', () async {
    final bloc = buildBloc();
    expect(bloc.state, isA<ChatInitial>());
    await bloc.close();
  });

  test('eco de socket sin roomId no saca de la sala abierta', () async {
    final bloc = buildBloc();
    await openRoom(bloc);

    bloc.add(
      ChatSocketMessageReceived(
        message: Message(
          id: 'm1',
          senderId: 'uid-2',
          senderName: 'Otro',
          text: 'hola',
          timestamp: DateTime.fromMillisecondsSinceEpoch(1),
        ),
        roomId: '',
      ),
    );
    await Future<void>.delayed(const Duration(milliseconds: 50));
    expect(bloc.state, isA<ChatRoomSelectedState>());
    expect((bloc.state as ChatRoomSelectedState).room.id, 'room-1');
    await bloc.close();
  });

  test('mensaje de socket de la sala se añade sin ChatLoading', () async {
    final bloc = buildBloc();
    await openRoom(bloc);

    bloc.add(
      ChatSocketMessageReceived(
        message: Message(
          id: 'm2',
          senderId: 'uid-2',
          senderName: 'Otro',
          text: 'nuevo',
          timestamp: DateTime.fromMillisecondsSinceEpoch(2),
        ),
        roomId: 'room-1',
      ),
    );
    final next = await bloc.stream.firstWhere(
      (s) =>
          s is ChatRoomSelectedState &&
          (s).messages.any((m) => m.id == 'm2'),
    );
    final selected = next as ChatRoomSelectedState;
    expect(selected.messages.any((m) => m.id == 'm2'), isTrue);
    expect(bloc.state, isNot(isA<ChatLoading>()));
    expect(bloc.state, isNot(isA<ChatRoomsLoaded>()));
    await bloc.close();
  });

  test('al salir de la sala vuelve la lista cacheada', () async {
    final bloc = buildBloc();
    await openRoom(bloc);
    bloc.add(const ChatRoomLeft('room-1'));
    final next = await bloc.stream.firstWhere((s) => s is ChatRoomsLoaded);
    expect((next as ChatRoomsLoaded).rooms, isNotEmpty);
    await bloc.close();
  });
}
