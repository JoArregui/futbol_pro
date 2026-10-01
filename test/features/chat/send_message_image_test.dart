import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:futbol_pro/features/chat/domain/repositories/chat_repository.dart';
import 'package:futbol_pro/features/chat/domain/usecases/send_message.dart';

class MockChatRepo extends Mock implements ChatRepository {}

void main() {
  late MockChatRepo repo;
  late SendMessage usecase;

  setUp(() {
    repo = MockChatRepo();
    usecase = SendMessage(repo);
  });

  test('permite mensaje solo con imagen (sin texto)', () async {
    when(
      () => repo.sendMessage(
        roomId: any(named: 'roomId'),
        senderId: any(named: 'senderId'),
        senderName: any(named: 'senderName'),
        text: any(named: 'text'),
        imageUrl: any(named: 'imageUrl'),
      ),
    ).thenAnswer((_) async => const Right(null));

    final res = await usecase(
      const SendParams(
        roomId: 'r1',
        senderId: 'u1',
        content: '',
        senderName: 'Tester',
        imageUrl: 'https://x.com/foto.jpg',
      ),
    );

    expect(res.isRight(), isTrue);
    verify(
      () => repo.sendMessage(
        roomId: 'r1',
        senderId: 'u1',
        senderName: 'Tester',
        text: '',
        imageUrl: 'https://x.com/foto.jpg',
      ),
    ).called(1);
  });

  test('rechaza vacío total (sin texto ni imagen)', () async {
    final res = await usecase(
      const SendParams(
        roomId: 'r1',
        senderId: 'u1',
        content: '   ',
        senderName: 'Tester',
      ),
    );
    expect(res.isLeft(), isTrue);
    verifyNever(
      () => repo.sendMessage(
        roomId: any(named: 'roomId'),
        senderId: any(named: 'senderId'),
        senderName: any(named: 'senderName'),
        text: any(named: 'text'),
        imageUrl: any(named: 'imageUrl'),
      ),
    );
  });
}
