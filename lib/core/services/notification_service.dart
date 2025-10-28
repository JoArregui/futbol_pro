import 'package:firebase_messaging/firebase_messaging.dart';
// Asume que necesitas importar Firestore para guardar el token
// Importa según tu setup de Firestore (ej. cloud_firestore)
// import 'package:cloud_firestore/cloud_firestore.dart'; 

/// Define la interfaz para el servicio de notificaciones, ideal para DI.
abstract class NotificationService {
  /// Inicializa los permisos y la escucha de notificaciones.
  Future<void> initializeNotifications();
  
  /// Obtiene el token de registro de FCM.
  Future<String?> getFCMToken();

  /// Se suscribe a un tema específico.
  Future<void> subscribeToTopic(String topic);

  /// Se desuscribe de un tema específico.
  Future<void> unsubscribeFromTopic(String topic);
  
  /// Stream para escuchar mensajes en primer plano (foreground).
  Stream<RemoteMessage> get onMessageReceived;
}

/// Implementación concreta del servicio de notificaciones usando Firebase Messaging.
class NotificationServiceImpl implements NotificationService {
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  // final FirebaseFirestore _firestore = FirebaseFirestore.instance; // Si usas Firestore

  // Función dummy para simular el guardado del token (necesitarás implementar tu lógica real)
  Future<void> _saveTokenToDatabase(String token) async {
    // ⚠️ TODO: Implementar lógica real para guardar el token
    print('Token recibido y guardado (dummy): $token');
    // Ejemplo si usaras Firestore:
    // await _firestore.collection('user_tokens').doc(userId).set({
    //   'token': token,
    //   'createdAt': FieldValue.serverTimestamp(),
    // });
  }

  // Función dummy para mostrar una notificación local (si usas flutter_local_notifications)
  void _showLocalNotification(RemoteMessage message) {
     print('Mensaje recibido en Foreground: ${message.notification?.title}');
     // ⚠️ TODO: Aquí invocarías tu paquete de notificaciones locales 
     // para mostrar un banner o alerta al usuario.
  }

  @override
  Future<void> initializeNotifications() async {
    // 1. Solicitar permisos (necesario para iOS y Web)
    await _fcm.requestPermission(
      alert: true, badge: true, sound: true,
    );
    
    // 2. Obtener y guardar el token
    String? token = await getFCMToken();
    if (token != null) {
      print('FCM Token obtenido: $token');
      await _saveTokenToDatabase(token);
    }

    // 3. Escuchar mensajes en primer plano (foreground)
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      _showLocalNotification(message);
    });
    
    // 4. CRÍTICO: Configurar el Background Handler (DEBE ser una función de nivel superior, 
    // pero la llamada a la configuración se haría aquí o en main.dart)
    // FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    
    // 5. Manejar clics en notificaciones (app en background/terminada)
    // FirebaseMessaging.onMessageOpenedApp.listen(_handleMessage);
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
