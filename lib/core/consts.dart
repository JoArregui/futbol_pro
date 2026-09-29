import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform, TargetPlatform;

class AppConsts {
  /// URL base cruda (compile-time). Sobrescribe con:
  /// `flutter run --dart-define=API_URL=http://192.168.1.10:3000/api/v1`
  /// `flutter run -d windows --dart-define=API_URL=http://localhost:3000/api/v1`
  static const String baseUrl = String.fromEnvironment(
    'API_URL',
    defaultValue: 'http://10.0.2.2:3000/api/v1',
  );

  static String? overrideUrl;

  /// URL efectiva: override runtime > --dart-define > auto localhost para web/desktop
  static String get effectiveBaseUrl {
    if (overrideUrl != null && overrideUrl!.isNotEmpty) return overrideUrl!;
    const wasOverridden = baseUrl != 'http://10.0.2.2:3000/api/v1';
    if (wasOverridden) return baseUrl;
    if (kIsWeb) return 'http://localhost:3000/api/v1';
    if (defaultTargetPlatform == TargetPlatform.windows ||
        defaultTargetPlatform == TargetPlatform.macOS ||
        defaultTargetPlatform == TargetPlatform.linux) {
      return 'http://localhost:3000/api/v1';
    }
    return baseUrl; // Android/iOS emulador
  }

  static Duration get httpTimeout => const Duration(seconds: 10);
}