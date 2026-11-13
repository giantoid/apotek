import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/storage/token_storage.dart';
import 'user.dart';

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepository(ref.watch(dioProvider), ref.watch(tokenStorageProvider)),
);

/// Endpoint autentikasi (`/auth/*`) dan pengelolaan token.
class AuthRepository {
  AuthRepository(this._dio, this._tokenStorage);

  final Dio _dio;
  final TokenStorage _tokenStorage;

  bool get hasToken => _tokenStorage.hasToken;

  /// `POST /auth/login` → `{ data: { token, user } }`.
  Future<User> login({required String email, required String password}) {
    return guardRequest(() async {
      try {
        final response = await _dio.post<Map<String, dynamic>>(
          '/auth/login',
          data: {
            'email': email,
            'password': password,
            'device_name': kIsWeb ? 'apotek-web' : 'apotek-mobile',
          },
        );
        final data = response.data!['data'] as Map<String, dynamic>;
        await _tokenStorage.save(data['token'] as String);
        return User.fromJson(data['user'] as Map<String, dynamic>);
      } on DioException catch (e) {
        if (e.response?.statusCode == 401) {
          throw ApiException.fromResponse(401, {
            'message': 'Email atau kata sandi salah.',
          });
        }
        rethrow;
      }
    });
  }

  /// `GET /auth/me` → `{ data: User }`.
  Future<User> me() {
    return guardRequest(() async {
      final response = await _dio.get<Map<String, dynamic>>('/auth/me');
      return User.fromJson(response.data!['data'] as Map<String, dynamic>);
    });
  }

  /// `POST /auth/logout` → 204. Token lokal selalu dihapus walau request
  /// gagal (mis. offline) agar pengguna tetap bisa keluar.
  Future<void> logout() async {
    try {
      await _dio.post<void>('/auth/logout');
    } on DioException {
      // Diabaikan: sesi lokal tetap dihapus.
    } finally {
      await _tokenStorage.clear();
    }
  }

  Future<void> clearSession() => _tokenStorage.clear();
}
