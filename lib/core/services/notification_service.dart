import 'package:firebase_messaging/firebase_messaging.dart';

abstract class NotificationService {
  Future<String?> getFCMToken();
  Future<void> initializeNotifications();
  Future<void> subscribeToTopic(String topic);
  Future<void> unsubscribeFromTopic(String topic);
  
  // Opcional: Stream para escuchar mensajes en primer plano
  Stream<RemoteMessage> get onMessageReceived;
}

class NotificationServiceImpl implements NotificationService {
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;

  @override
  Future<void> initializeNotifications() async {
    // 1. Solicitar permisos (solo iOS/Web)
    // ✅ CORREGIDO: Se llama a la función sin asignar el resultado a una variable local no utilizada.
    await _fcm.requestPermission(
      alert: true, badge: true, sound: true,
    );
    
    // 2. Manejar la recepción de notificaciones cuando la app está abierta (foreground)
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print("Got a message whilst in the foreground!");
      // Aquí podrías mostrar un banner o actualizar la UI
    });
    
    // 3. Manejar clics en notificaciones cuando la app está en background/terminada
    // FirebaseMessaging.onMessageOpenedApp.listen(_handleMessage);

    // 4. Inicializar manejo de notificaciones en background (requiere función top-level)
    // FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  }

  @override
  Future<String?> getFCMToken() => _fcm.getToken();

  @override
  Future<void> subscribeToTopic(String topic) => _fcm.subscribeToTopic(topic);

  @override
  Future<void> unsubscribeFromTopic(String topic) => _fcm.unsubscribeFromTopic(topic);

  @override
  Stream<RemoteMessage> get onMessageReceived => FirebaseMessaging.onMessage;
}
