import 'package:apotek_mobile/core/network/api_exception.dart';
import 'package:apotek_mobile/core/storage/token_storage.dart';
import 'package:apotek_mobile/core/theme/app_theme.dart';
import 'package:apotek_mobile/features/auth/data/auth_repository.dart';
import 'package:apotek_mobile/features/auth/data/user.dart';
import 'package:apotek_mobile/features/auth/presentation/auth_controller.dart';
import 'package:apotek_mobile/features/auth/presentation/login_screen.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FakeAuthRepository extends AuthRepository {
  FakeAuthRepository(this.prefs, {this.shouldFail = false})
      : super(Dio(), TokenStorage(prefs));

  final SharedPreferences prefs;
  final bool shouldFail;
  String? lastEmail;
  String? lastPassword;

  @override
  bool get hasToken => false;

  @override
  Future<User> login({required String email, required String password}) async {
    lastEmail = email;
    lastPassword = password;
    if (shouldFail) {
      throw const ApiException('Email atau password salah.', statusCode: 422);
    }
    return const User(
      id: 2,
      name: 'Kasir Demo',
      email: 'kasir@apotek.test',
      role: UserRole.kasir,
    );
  }
}

void main() {
  testWidgets('Validasi form login dan kirim kredensial ke repository',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final fakeRepo = FakeAuthRepository(prefs);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          authRepositoryProvider.overrideWithValue(fakeRepo),
        ],
        child: MaterialApp(
          theme: AppTheme.light(),
          home: const LoginScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Submit kosong memicu validator email & kata sandi.
    await tester.ensureVisible(find.byKey(const Key('login_submit')));
    await tester.tap(find.byKey(const Key('login_submit')));
    await tester.pump();

    expect(find.text('Email wajib diisi'), findsOneWidget);
    expect(find.text('Kata sandi wajib diisi'), findsOneWidget);
    expect(fakeRepo.lastEmail, isNull);

    // Format email salah.
    await tester.enterText(find.byKey(const Key('login_email')), 'bukan-email');
    await tester.tap(find.byKey(const Key('login_submit')));
    await tester.pump();
    expect(find.text('Format email tidak valid'), findsOneWidget);

    // Klik akun demo Kasir lalu submit.
    await tester.ensureVisible(find.text('kasir@apotek.test'));
    await tester.tap(find.text('kasir@apotek.test'));
    await tester.pump();

    await tester.ensureVisible(find.byKey(const Key('login_submit')));
    await tester.tap(find.byKey(const Key('login_submit')));
    await tester.pumpAndSettle();

    expect(fakeRepo.lastEmail, 'kasir@apotek.test');
    expect(fakeRepo.lastPassword, 'password');
  });

  testWidgets('Menampilkan pesan error server saat login ditolak',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final fakeRepo = FakeAuthRepository(prefs, shouldFail: true);

    late ProviderContainer container;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          authRepositoryProvider.overrideWithValue(fakeRepo),
        ],
        child: Consumer(
          builder: (context, ref, _) {
            container = ProviderScope.containerOf(context);
            return MaterialApp(
              theme: AppTheme.light(),
              home: const LoginScreen(),
            );
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('login_email')),
      'kasir@apotek.test',
    );
    await tester.enterText(
      find.byKey(const Key('login_password')),
      'salah',
    );
    await tester.ensureVisible(find.byKey(const Key('login_submit')));
    await tester.tap(find.byKey(const Key('login_submit')));
    await tester.pumpAndSettle();

    expect(find.text('Email atau password salah.'), findsOneWidget);
    expect(container.read(authControllerProvider).value, isNull);
  });
}
