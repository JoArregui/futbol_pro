import 'dart:async';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Interfaz para el servicio de gestión de notificaciones.
abstract class NotificationService {
  Future<void> initialize();
  Future<void> subscribeToTopic(String topic);
  Future<void> unsubscribeFromTopic(String topic);
  Future<String?> getToken();
  Stream<RemoteMessage> get onMessage;
  Stream<RemoteMessage> get onMessageOpenedApp;

  /// Notificación local inmediata (p. ej. mensaje de otra sala por socket).
  Future<void> showLocal({required String title, required String body});
}

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Background handler debe ser top-level
  // ignore: avoid_print
  print('🔔 [BG] Mensaje recibido: ${message.messageId}');
}

/// Implementación real con Firebase Messaging + local notifications.
class NotificationServiceImpl implements NotificationService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _local =
      FlutterLocalNotificationsPlugin();

  final StreamController<RemoteMessage> _onMessageCtrl =
      StreamController<RemoteMessage>.broadcast();

  bool _initialized = false;

  @override
  Stream<RemoteMessage> get onMessage => _onMessageCtrl.stream;

  @override
  Stream<RemoteMessage> get onMessageOpenedApp =>
      FirebaseMessaging.onMessageOpenedApp;

  @override
  Future<void> initialize() async {
    if (_initialized) return;
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );
    await _local.initialize(initSettings);

    const channel = AndroidNotificationChannel(
      'futbol_pro_default',
      'Futbol Pro',
      description: 'Notificaciones generales',
      importance: Importance.high,
    );
    await _local
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );
    // ignore: avoid_print
    print('🔔 Permiso notificaciones: ${settings.authorizationStatus}');

    FirebaseMessaging.onMessage.listen((message) async {
      _onMessageCtrl.add(message);
      final notification = message.notification;
      if (notification != null) {
        await _local.show(
          notification.hashCode,
          notification.title,
          notification.body,
          NotificationDetails(
            android: AndroidNotificationDetails(
              channel.id,
              channel.name,
              channelDescription: channel.description,
              importance: Importance.high,
              priority: Priority.high,
            ),
            iOS: const DarwinNotificationDetails(),
          ),
        );
      }
    });

    _initialized = true;
    // ignore: avoid_print
    print('✅ NotificationService: Inicializado.');
  }

  @override
  Future<void> subscribeToTopic(String topic) async {
    if (topic.isEmpty) {
      // ignore: avoid_print
      print('⚠️ NotificationService: Tópico vacío, omitiendo.');
      return;
    }
    final sanitized = topic.replaceAll(RegExp(r'[^a-zA-Z0-9-_.~%]'), '_');
    await _messaging.subscribeToTopic(sanitized);
    // ignore: avoid_print
    print('✅ NotificationService: Suscrito a "$sanitized".');
  }

  @override
  Future<void> unsubscribeFromTopic(String topic) async {
    if (topic.isEmpty) return;
    await _messaging.unsubscribeFromTopic(topic);
  }

  @override
  Future<String?> getToken() => _messaging.getToken();

  @override
  Future<void> showLocal({required String title, required String body}) async {
    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        'futbol_pro_default',
        'Futbol Pro',
        channelDescription: 'Notificaciones generales',
        importance: Importance.high,
        priority: Priority.high,
      ),
      iOS: DarwinNotificationDetails(),
    );
    await _local.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      details,
    );
  }

  void dispose() => _onMessageCtrl.close();
}
