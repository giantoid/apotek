import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

/// Formatter tampilan (Rupiah, tanggal) dengan locale Indonesia.
abstract final class Formatters {
  static final NumberFormat _rupiah = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp',
    decimalDigits: 0,
  );
  static final NumberFormat _number = NumberFormat.decimalPattern('id_ID');

  /// `12000` → `Rp12.000`, `-5000` → `-Rp5.000`.
  static String rupiah(num value) => _rupiah.format(value);

  /// `12000` → `12.000`.
  static String number(num value) => _number.format(value);

  /// `31 Agu 2027`.
  static String date(DateTime value) =>
      DateFormat('d MMM yyyy', 'id_ID').format(value.toLocal());

  /// `Kamis, 12 November 2026`.
  static String longDate(DateTime value) =>
      DateFormat('EEEE, d MMMM yyyy', 'id_ID').format(value.toLocal());

  /// `12 Nov 2026, 13.30`.
  static String dateTime(DateTime value) =>
      DateFormat('d MMM yyyy, HH.mm', 'id_ID').format(value.toLocal());

  /// `13.30`.
  static String time(DateTime value) =>
      DateFormat('HH.mm', 'id_ID').format(value.toLocal());

  /// Format tanggal untuk query API: `2026-11-12`.
  static String apiDate(DateTime value) =>
      DateFormat('yyyy-MM-dd').format(value);

  /// Mengambil angka dari teks berformat (`"50.000"` → `50000`).
  static int parseDigits(String text) {
    final digits = text.replaceAll(RegExp(r'[^0-9]'), '');
    return digits.isEmpty ? 0 : int.parse(digits);
  }
}

/// Input formatter yang menampilkan pemisah ribuan saat pengguna mengetik
/// nominal uang (`50000` → `50.000`).
class ThousandsSeparatorInputFormatter extends TextInputFormatter {
  static const _maxDigits = 12;

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    var digits = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) return const TextEditingValue();
    if (digits.length > _maxDigits) return oldValue;
    digits = digits.replaceFirst(RegExp(r'^0+(?=\d)'), '');
    final formatted = Formatters.number(int.parse(digits));
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
