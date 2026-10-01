import 'package:local_auth/local_auth.dart';

/// Huella / Face ID — desbloqueo rápido OPCIONAL, desactivado por defecto.
/// Cuándo se usa:
///  1. Siempre entras primero con email + contraseña (obligatorio).
///  2. Solo si TÚ la activas en Perfil > "Desbloquear con huella",
///     al volver a la app podrás usar la huella en vez de reescribir
///     la contraseña (la sesión JWT ya validada sigue guardada).
/// Nunca sustituye al password en el primer login ni se envía al servidor.
class BiometricAuthService {
  final LocalAuthentication _auth = LocalAuthentication();

  Future<bool> isAvailable() async {
    try {
      final canCheck = await _auth.canCheckBiometrics;
      final isSupported = await _auth.isDeviceSupported();
      return canCheck && isSupported;
    } catch (_) {
      return false;
    }
  }

  Future<List<BiometricType>> availableTypes() async {
    try {
      return await _auth.getAvailableBiometrics();
    } catch (_) {
      return [];
    }
  }

  Future<bool> authenticate({String reason = 'Confirma tu identidad'}) async {
    try {
      return await _auth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
        ),
      );
    } catch (_) {
      return false;
    }
  }
}
