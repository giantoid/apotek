import 'package:dio/dio.dart';

/// Kesalahan yang sudah diterjemahkan menjadi pesan ramah pengguna
/// (Bahasa Indonesia). Seluruh repository hanya melempar tipe ini ke
/// lapisan presentasi.
class ApiException implements Exception {
  const ApiException(
    this.message, {
    this.statusCode,
    this.fieldErrors = const {},
  });

  /// Memetakan [DioException] menjadi [ApiException].
  factory ApiException.fromDio(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.transformTimeout:
        return const ApiException(
          'Koneksi ke server terlalu lama. Silakan coba lagi.',
        );
      case DioExceptionType.connectionError:
        return const ApiException(
          'Tidak dapat terhubung ke server. Periksa koneksi internet Anda.',
        );
      case DioExceptionType.cancel:
        return const ApiException('Permintaan dibatalkan.');
      case DioExceptionType.badCertificate:
        return const ApiException('Sertifikat keamanan server tidak valid.');
      case DioExceptionType.badResponse:
        return ApiException.fromResponse(
          error.response?.statusCode,
          error.response?.data,
        );
      case DioExceptionType.unknown:
        return const ApiException(
          'Terjadi kesalahan jaringan. Silakan coba lagi.',
        );
    }
  }

  /// Memetakan respons error HTTP sesuai kontrak API:
  /// `{ "message": "...", "errors": { "field": ["pesan"] } }`.
  factory ApiException.fromResponse(int? statusCode, Object? body) {
    String? serverMessage;
    final fieldErrors = <String, List<String>>{};

    if (body is Map) {
      final message = body['message'];
      if (message is String && message.trim().isNotEmpty) {
        serverMessage = message;
      }
      final errors = body['errors'];
      if (errors is Map) {
        errors.forEach((key, value) {
          if (value is List) {
            fieldErrors[key.toString()] =
                value.map((e) => e.toString()).toList();
          } else if (value != null) {
            fieldErrors[key.toString()] = [value.toString()];
          }
        });
      }
    }

    final String message;
    switch (statusCode) {
      case 401:
        message = serverMessage ?? 'Sesi Anda telah berakhir. Silakan masuk kembali.';
      case 403:
        message = 'Anda tidak memiliki akses untuk melakukan aksi ini.';
      case 404:
        message = 'Data tidak ditemukan.';
      case 409:
        message = serverMessage ?? 'Terjadi konflik data. Silakan muat ulang.';
      case 422:
        final firstFieldError = fieldErrors.values
            .expand((messages) => messages)
            .cast<String?>()
            .firstWhere((m) => m != null && m.isNotEmpty, orElse: () => null);
        message = firstFieldError ?? serverMessage ?? 'Data yang dikirim tidak valid.';
      case 429:
        message = 'Terlalu banyak permintaan. Tunggu sebentar lalu coba lagi.';
      default:
        if (statusCode != null && statusCode >= 500) {
          message = 'Terjadi kesalahan pada server. Silakan coba beberapa saat lagi.';
        } else {
          message = serverMessage ?? 'Terjadi kesalahan. Silakan coba lagi.';
        }
    }

    return ApiException(
      message,
      statusCode: statusCode,
      fieldErrors: fieldErrors,
    );
  }

  final String message;
  final int? statusCode;
  final Map<String, List<String>> fieldErrors;

  bool get isUnauthorized => statusCode == 401;
  bool get isValidationError => statusCode == 422;

  @override
  String toString() => 'ApiException($statusCode): $message';
}

/// Menjalankan [request] dan menerjemahkan semua error jaringan menjadi
/// [ApiException].
Future<T> guardRequest<T>(Future<T> Function() request) async {
  try {
    return await request();
  } on DioException catch (e) {
    final inner = e.error;
    if (inner is ApiException) throw inner;
    throw ApiException.fromDio(e);
  } on ApiException {
    rethrow;
  } on FormatException {
    throw const ApiException('Format data dari server tidak dikenali.');
  } on TypeError {
    throw const ApiException('Format data dari server tidak dikenali.');
  }
}

/// Pesan ramah pengguna untuk error apa pun (dipakai di `AsyncValue.when`).
String describeError(Object error) => error is ApiException
    ? error.message
    : 'Terjadi kesalahan tak terduga. Silakan coba lagi.';
