import 'package:flutter/material.dart';

import '../../features/auth/domain/repositories/auth_repository.dart';
import '../injection_container.dart';
import '../services/notification_service.dart';
import '../services/notify_topics.dart';
import '../services/socket_service.dart';

/// Escucha los 6 eventos deportivos del servidor (server/services/notify.js)
/// y los muestra como notificación local. Sin nuevas dependencias.
class AppEventListener extends StatefulWidget {
  final Widget child;
  const AppEventListener({super.key, required this.child});

  @override
  State<AppEventListener> createState() => _AppEventListenerState();
}

class _AppEventListenerState extends State<AppEventListener> {
  bool _wired = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_wired) return;
    _wired = true;
    try {
      final socket = sl<SocketService>();
      final notif = sl<NotificationService>();
      // Topic personal para avisos directos (convocatorias, reservas).
      try {
        final uid = sl<AuthRepository>().getCurrentUserId();
        if (uid.isNotEmpty) NotifyTopics.join(NotifyTopics.userTopic(uid));
      } catch (_) {}
      for (final e in const [
        'match_created',
        'match_updated',
        'match_result',
        'booking',
        'booking_created',
        'squad'
      ]) {
        socket.onAppEvent(e, (data) {
          final title = (data['title'] ?? 'Futbol Pro').toString();
          final body = (data['body'] ?? '').toString();
          if (body.isEmpty) return;
          notif.showLocal(title: title, body: body);
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('$title: $body')),
          );
        });
      }
    } catch (_) {
      // DI aún no listo en algún test/widget aislado: noop.
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
