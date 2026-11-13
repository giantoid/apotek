import 'package:dio/dio.dart';

import '../storage/token_storage.dart';

/// Menambahkan header `Authorization: Bearer` dan memberi tahu aplikasi
/// ketika server membalas 401 (token kedaluwarsa / dicabut).
class AuthInterceptor extends Interceptor {
  AuthInterceptor({
    required this.tokenStorage,
    required this.onUnauthorized,
  });

  final TokenStorage tokenStorage;
  final void Function() onUnauthorized;

  static const _loginPath = '/auth/login';

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final token = tokenStorage.token;
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final isLoginRequest = err.requestOptions.path.endsWith(_loginPath);
    if (err.response?.statusCode == 401 && !isLoginRequest) {
      await tokenStorage.clear();
      onUnauthorized();
    }
    handler.next(err);
  }
}
