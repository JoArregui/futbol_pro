class AppConsts {
  /// URL base de la API. Sobrescribible en compilación con:
  /// `flutter run --dart-define=API_URL=http://192.168.1.10:3000/api/v1`
  /// Default: 10.0.2.2 (alias de localhost para emulador Android).
  /// En dispositivo físico usa tu IP LAN: http://192.168.1.10:3000/api/v1
  static const String baseUrl = String.fromEnvironment(
    'API_URL',
    defaultValue: 'http://10.0.2.2:3000/api/v1',
  );
}