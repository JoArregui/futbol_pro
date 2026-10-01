import 'config/app_config.dart';

class AppConsts {
  /// URL base cruda (compile-time). Sobrescribe con:
  /// `flutter run --dart-define=API_URL=http://192.168.1.10:3000/api/v1`
  /// `flutter run -d windows --dart-define=API_URL=http://localhost:3000/api/v1`
  /// Ver [AppConfig] para flavors dev/staging/prod.
  static const String baseUrl = String.fromEnvironment(
    'API_URL',
    defaultValue: 'http://10.0.2.2:3000/api/v1',
  );

  static String? overrideUrl;

  /// URL efectiva delegada en AppConfig (override runtime > dart-define > flavor).
  static String get effectiveBaseUrl =>
      AppConfig.apiUrl(runtimeOverride: overrideUrl);

  static Duration get httpTimeout => const Duration(seconds: 10);
}
