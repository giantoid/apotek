import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../data/auth_repository.dart';
import '../data/user.dart';

final authControllerProvider = AsyncNotifierProvider<AuthController, User?>(
  AuthController.new,
);

/// Sumber kebenaran status login. `null` berarti belum login.
class AuthController extends AsyncNotifier<User?> {
  AuthRepository get _repository => ref.read(authRepositoryProvider);

  /// Saat aplikasi dibuka: pulihkan sesi bila token tersimpan.
  @override
  Future<User?> build() async {
    final repository = ref.watch(authRepositoryProvider);
    if (!repository.hasToken) return null;
    try {
      return await repository.me();
    } on ApiException catch (e) {
      if (e.isUnauthorized) {
        await repository.clearSession();
        return null;
      }
      rethrow;
    }
  }

  /// Melempar [ApiException] bila gagal; layar login menampilkan pesannya.
  Future<void> login({required String email, required String password}) async {
    final user = await _repository.login(email: email, password: password);
    state = AsyncData(user);
  }

  Future<void> logout() async {
    await _repository.logout();
    state = const AsyncData(null);
  }

  /// Dipanggil interceptor ketika server membalas 401.
  void handleUnauthorized() {
    if (state.value != null) {
      state = const AsyncData(null);
    }
  }
}
