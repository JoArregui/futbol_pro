import 'package:flutter/foundation.dart'
    show kIsWeb, defaultTargetPlatform, TargetPlatform;

/// Flavors de la app. Se elige en compile-time:
/// `flutter run --dart-define=FLAVOR=dev`
/// `flutter run --dart-define=FLAVOR=staging --dart-define=API_URL=https://staging.futbolpro.com/api/v1`
/// `flutter run --dart-define=FLAVOR=prod --dart-define=API_URL=https://api.futbolpro.com/api/v1`
enum AppFlavor { dev, staging, prod }

class AppConfig {
  AppConfig._();

  static const _flavorRaw =
      String.fromEnvironment('FLAVOR', defaultValue: 'dev');

  static AppFlavor get flavor {
    switch (_flavorRaw.toLowerCase()) {
      case 'staging':
      case 'stage':
        return AppFlavor.staging;
      case 'prod':
      case 'production':
        return AppFlavor.prod;
      case 'dev':
      default:
        return AppFlavor.dev;
    }
  }

  static bool get isDev => flavor == AppFlavor.dev;
  static bool get isStaging => flavor == AppFlavor.staging;
  static bool get isProd => flavor == AppFlavor.prod;

  static String get appName {
    switch (flavor) {
      case AppFlavor.staging:
        return 'Futbol Pro STG';
      case AppFlavor.prod:
        return 'Futbol Pro';
      case AppFlavor.dev:
        return 'Futbol Pro DEV';
    }
  }

  /// URL por defecto según flavor (API_URL siempre tiene prioridad).
  static String get _defaultApiUrl {
    const override = String.fromEnvironment('API_URL', defaultValue: '');
    if (override.isNotEmpty) return override;
    switch (flavor) {
      case AppFlavor.staging:
        return 'https://staging.futbolpro.com/api/v1';
      case AppFlavor.prod:
        return 'https://api.futbolpro.com/api/v1';
      case AppFlavor.dev:
        return 'http://10.0.2.2:3000/api/v1';
    }
  }

  /// URL efectiva: respeta override runtime, API_URL, y auto-localhost en web/desktop.
  /// En móvil físico usa siempre --dart-define=API_URL con la IP de tu PC
  /// o `adb reverse tcp:3000 tcp:3000` + http://127.0.0.1:3000/api/v1.
  static String apiUrl({String? runtimeOverride}) {
    if (runtimeOverride != null && runtimeOverride.isNotEmpty) {
      return runtimeOverride;
    }
    const override = String.fromEnvironment('API_URL', defaultValue: '');
    if (override.isNotEmpty) return override;
    if (kIsWeb) return 'http://localhost:3000/api/v1';
    if (defaultTargetPlatform == TargetPlatform.windows ||
        defaultTargetPlatform == TargetPlatform.macOS ||
        defaultTargetPlatform == TargetPlatform.linux) {
      return 'http://localhost:3000/api/v1';
    }
    return _defaultApiUrl;
  }

  static double get sentryTracesSampleRate {
    switch (flavor) {
      case AppFlavor.prod:
        return 0.2;
      case AppFlavor.staging:
        return 0.5;
      case AppFlavor.dev:
        return 0.0;
    }
  }

  static bool get logNetwork => !isProd;
}
