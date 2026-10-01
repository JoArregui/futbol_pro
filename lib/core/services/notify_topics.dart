import '../injection_container.dart';
import 'notification_service.dart';

/// Topics FCM por partido y equipo (+ global `futbolpro_all`).
/// Transporte actual: el servidor emite por Socket.IO (ver
/// server/services/notify.js); estos topics dejan lista la app para
/// cuando el backend publique también vía FCM (FCM_ENABLED).
/// Reglas de nombre: solo [a-zA-Z0-9-_.~%], sin barras.
class NotifyTopics {
  NotifyTopics._();

  static String matchTopic(String matchId) => 'match_$matchId';
  static String teamTopic(String teamId) => 'team_$teamId';
  static String userTopic(String userId) => 'user_$userId';

  static String _safe(String topic) =>
      topic.replaceAll(RegExp(r'[^a-zA-Z0-9-_.~%]'), '_');

  static Future<void> join(String topic) async {
    try {
      await sl<NotificationService>().subscribeToTopic(_safe(topic));
    } catch (_) {}
  }

  static Future<void> leave(String topic) async {
    try {
      await sl<NotificationService>().unsubscribeFromTopic(_safe(topic));
    } catch (_) {}
  }

  static Future<void> joinMatch(String matchId) => join(matchTopic(matchId));
  static Future<void> leaveMatch(String matchId) => leave(matchTopic(matchId));
  static Future<void> joinTeam(String teamId) => join(teamTopic(teamId));
  static Future<void> leaveTeam(String teamId) => leave(teamTopic(teamId));
}
