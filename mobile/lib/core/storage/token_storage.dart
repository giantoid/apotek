import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Di-override di `main()` setelah [SharedPreferences.getInstance] selesai.
final sharedPreferencesProvider = Provider<SharedPreferences>(
  (ref) => throw UnimplementedError('sharedPreferencesProvider belum di-override'),
);

final tokenStorageProvider = Provider<TokenStorage>(
  (ref) => TokenStorage(ref.watch(sharedPreferencesProvider)),
);

/// Penyimpanan token Sanctum. Memakai `shared_preferences` agar berjalan
/// di Android, iOS, maupun web.
class TokenStorage {
  TokenStorage(this._prefs);

  static const _tokenKey = 'auth_token';

  final SharedPreferences _prefs;

  String? get token => _prefs.getString(_tokenKey);

  bool get hasToken => (token ?? '').isNotEmpty;

  Future<void> save(String token) => _prefs.setString(_tokenKey, token);

  Future<void> clear() => _prefs.remove(_tokenKey);
}
