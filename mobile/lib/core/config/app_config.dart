/// Konfigurasi aplikasi yang dapat diatur saat build/run.
///
/// Contoh:
/// ```
/// flutter run --dart-define=API_BASE_URL=http://192.168.1.10:8000/api/v1
/// ```
abstract final class AppConfig {
  /// Base URL REST API. Default `10.0.2.2` adalah alamat host dari
  /// dalam emulator Android.
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:8000/api/v1',
  );

  static const String appName = 'Apotek';

  static const Duration connectTimeout = Duration(seconds: 15);
  static const Duration receiveTimeout = Duration(seconds: 20);

  /// Jeda sebelum pencarian dikirim ke server saat pengguna mengetik.
  static const Duration searchDebounce = Duration(milliseconds: 400);
}
