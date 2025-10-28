import 'dart:async';
import 'package:flutter/foundation.dart';

/// Un 'Listenable' que convierte un Stream<T> en una notificación de cambio,
/// ideal para usar con el parámetro 'refreshListenable' de GoRouter.
class GoRouterRefreshStream extends ChangeNotifier {
  late final StreamSubscription<dynamic> _subscription;

  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    // Escucha el stream de forma permanente y notifica a GoRouter cuando cambia.
    _subscription = stream.asBroadcastStream().listen(
      (dynamic _) => notifyListeners(),
    );
  }

  @override
  void dispose() {
    _subscription.cancel(); // Asegura que la suscripción se cancele correctamente.
    super.dispose();
  }
}
