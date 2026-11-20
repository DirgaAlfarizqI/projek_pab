import 'package:intl/intl.dart';

class AppFormatters {
  static final NumberFormat _currencyFormatter = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp',
    decimalDigits: 0,
  );

  static final NumberFormat _decimalFormatter = NumberFormat(
    '#,##0.##',
    'id_ID',
  );
  static final DateFormat _dateFormatter = DateFormat('dd MMM yyyy', 'id_ID');
  static final DateFormat _shortDateFormatter = DateFormat('dd/MM/yyyy');

  static String currency(num value) {
    // Gunakan pembulatan presisi terdekat untuk mata uang Rupiah
    return _currencyFormatter.format(value.round());
  }

  static String number(num value) {
    return _decimalFormatter.format(value);
  }

  static String date(DateTime date) {
    try {
      return _dateFormatter.format(date);
    } catch (_) {
      return _shortDateFormatter.format(date);
    }
  }

  static String shortDate(DateTime date) {
    return _shortDateFormatter.format(date);
  }

  /// Konversi luas lahan ke Hektare (ha)
  /// 1 ha = 10.000 m²
  static double toHectares(double area, String unit) {
    if (unit.toLowerCase() == 'm²' || unit.toLowerCase() == 'm2') {
      return area / 10000.0;
    }
    return area;
  }

  /// Konversi luas lahan ke m²
  static double toSquareMeters(double area, String unit) {
    if (unit.toLowerCase() == 'hektare' || unit.toLowerCase() == 'ha') {
      return area * 10000.0;
    }
    return area;
  }

  /// Konversi ton ke kg (1 ton = 1.000 kg)
  static double tonsToKg(double tons) {
    return tons * 1000.0;
  }

  /// Konversi kg ke ton
  static double kgToTons(double kg) {
    return kg / 1000.0;
  }

  /// Parse angka dari input teks (mendukung koma atau titik)
  static double? parsePositiveDouble(String? text, {bool allowZero = false}) {
    if (text == null || text.trim().isEmpty) return null;
    final cleaned = text.trim().replaceAll(',', '.');
    final val = double.tryParse(cleaned);
    if (val == null) return null;
    if (allowZero ? val < 0 : val <= 0) return null;
    return val;
  }
}
