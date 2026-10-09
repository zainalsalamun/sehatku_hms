import 'package:intl/intl.dart';

/// Standar Tunggal Pemformatan Mata Uang Rupiah (IDR) untuk SehatKu HMS
class CurrencyFormatter {
  static final NumberFormat _idrFormat = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  /// Format nominal lengkap: "Rp 350.000"
  static String format(num? amount) {
    if (amount == null) return 'Rp 0';
    return _idrFormat.format(amount);
  }

  /// Format nominal dengan pembulatan desimal opsional (misal: "Rp 350.000,50")
  static String formatWithDecimals(num? amount, {int decimalDigits = 2}) {
    if (amount == null) return 'Rp 0';
    final customFormat = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: decimalDigits,
    );
    return customFormat.format(amount);
  }

  /// Format nominal ringkas dashboard/stat card: "Rp 12,5 Jt" atau "Rp 1,2 M"
  static String formatCompact(num? amount) {
    if (amount == null || amount == 0) return 'Rp 0';
    final abs = amount.abs();
    if (abs >= 1000000000) {
      final val = (amount / 1000000000).toStringAsFixed(1).replaceAll('.0', '');
      return 'Rp $val M';
    }
    if (abs >= 1000000) {
      final val = (amount / 1000000).toStringAsFixed(1).replaceAll('.0', '');
      return 'Rp $val Jt';
    }
    if (abs >= 1000) {
      final val = (amount / 1000).toStringAsFixed(0);
      return 'Rp $val Rb';
    }
    return format(amount);
  }

  /// Helper untuk membersihkan string input teks menjadi angka numerik murni
  static double parse(String? text) {
    if (text == null || text.trim().isEmpty) return 0.0;
    final clean = text.replaceAll(RegExp(r'[^0-9.]'), '');
    return double.tryParse(clean) ?? 0.0;
  }
}
