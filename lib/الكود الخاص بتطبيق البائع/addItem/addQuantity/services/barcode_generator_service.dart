import 'dart:math';

/// خدمة توليد الباركودات التسلسلية
class BarcodeGeneratorService {
  final Random _random = Random();

  /// توليد باركود تسلسلي فريد
  String generateSequentialBarcode({
    required String productId,
    required int sequenceNumber,
  }) {
    // إنشاء timestamp
    final String timestamp = DateTime.now().millisecondsSinceEpoch.toString();

    // أخذ آخر 8 أرقام من timestamp كـ base code
    final String baseCode = timestamp.substring(timestamp.length - 8);

    // تحويل معرف المنتج إلى كود قصير
    final String productCode = _generateProductCode(productId);

    // إنشاء رقم تسلسلي مع padding
    final String sequentialNumber = sequenceNumber.toString().padLeft(4, '0');

    // إضافة رقم عشوائي للتفرد
    final String randomPart = _random.nextInt(99).toString().padLeft(2, '0');

    // دمج كل الأجزاء لتكوين الباركود النهائي
    return '$productCode$baseCode$sequentialNumber$randomPart';
  }

  /// توليد باركود تسلسلي بمعايير أبسط (للتوافق مع الكود الموجود)
  String generateSequentialBarcodeSimple(String productName, int index) {
    // إنشاء timestamp
    final String timestamp = DateTime.now().millisecondsSinceEpoch.toString();

    // أخذ آخر 8 أرقام من timestamp كـ base code
    final String baseCode = timestamp.substring(timestamp.length - 8);

    // تحويل اسم المنتج إلى كود قصير
    final String productCode = _generateProductCode(productName);

    // إنشاء رقم تسلسلي مع padding
    final String sequentialNumber = index.toString().padLeft(4, '0');

    // إضافة رقم عشوائي للتفرد
    final String randomPart = _random.nextInt(99).toString().padLeft(2, '0');

    // دمج كل الأجزاء لتكوين الباركود النهائي
    return '$productCode$baseCode$sequentialNumber$randomPart';
  }

  /// توليد باركود تسلسلي بدون معاملات (للاستخدام العام)
  String generateSimpleSequentialBarcode() {
    final String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
    final String baseCode = timestamp.substring(timestamp.length - 8);
    final String randomPart = _random.nextInt(9999).toString().padLeft(4, '0');

    return '$baseCode$randomPart';
  }

  /// توليد كود المنتج من اسم المنتج أو معرفه
  String _generateProductCode(String input) {
    if (input.isEmpty) return 'PRD';

    // تنظيف النص من المسافات والرموز
    final String cleanInput =
        input
            .replaceAll(' ', '')
            .replaceAll(RegExp(r'[^\w\u0600-\u06FF]'), '')
            .toUpperCase();

    if (cleanInput.isEmpty) return 'PRD';

    // أخذ أول 3 أحرف أو أرقام من النص
    final String code =
        cleanInput.length >= 3
            ? cleanInput.substring(0, 3)
            : cleanInput.padRight(3, 'X');

    return code;
  }

  /// توليد باركود رئيسي للمنتج
  String generateMainBarcode(String productName) {
    final String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
    final String productCode = _generateProductCode(productName);
    final String timeCode = timestamp.substring(timestamp.length - 6);
    final String randomCode = _random.nextInt(999).toString().padLeft(3, '0');

    return 'MAIN$productCode$timeCode$randomCode';
  }

  /// توليد مجموعة من الباركودات التسلسلية
  List<String> generateMultipleSequentialBarcodes(
    String productName,
    int quantity,
  ) {
    final List<String> barcodes = [];

    for (int i = 1; i <= quantity; i++) {
      barcodes.add(generateSequentialBarcodeSimple(productName, i));
    }

    return barcodes;
  }

  /// التحقق من صحة تنسيق الباركود
  bool isValidBarcode(String barcode) {
    if (barcode.isEmpty) return false;

    // التحقق من الطول الأدنى
    if (barcode.length < 8) return false;

    // التحقق من أن الباركود يحتوي على أرقام وحروف فقط
    final RegExp validPattern = RegExp(r'^[A-Z0-9]+$');
    return validPattern.hasMatch(barcode.toUpperCase());
  }

  /// استخراج معلومات من الباركود التسلسلي
  Map<String, String> extractBarcodeInfo(String barcode) {
    if (!isValidBarcode(barcode) || barcode.length < 15) {
      return {'error': 'باركود غير صالح'};
    }

    try {
      final String productCode = barcode.substring(0, 3);
      final String timestamp = barcode.substring(3, 11);
      final String sequentialNumber = barcode.substring(11, 15);
      final String randomPart = barcode.substring(15);

      return {
        'productCode': productCode,
        'timestamp': timestamp,
        'sequentialNumber': sequentialNumber,
        'randomPart': randomPart,
        'isSequential': 'true',
      };
    } catch (e) {
      return {'error': 'فشل في تحليل الباركود'};
    }
  }

  /// توليد باركود مع معايير مخصصة
  String generateCustomBarcode({
    required String prefix,
    required String productId,
    int? sequenceNumber,
    String? suffix,
  }) {
    final String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
    final String timeCode = timestamp.substring(timestamp.length - 6);
    final String productCode = _generateProductCode(productId);

    String barcode = '$prefix$productCode$timeCode';

    if (sequenceNumber != null) {
      barcode += sequenceNumber.toString().padLeft(4, '0');
    }

    if (suffix != null) {
      barcode += suffix;
    } else {
      barcode += _random.nextInt(999).toString().padLeft(3, '0');
    }

    return barcode;
  }

  /// توليد QR Code data للمنتج
  String generateQRCodeData({
    required String productId,
    required String productName,
    String? price,
    String? storeId,
  }) {
    final Map<String, String> qrData = {
      'type': 'product',
      'id': productId,
      'name': productName,
      'timestamp': DateTime.now().millisecondsSinceEpoch.toString(),
    };

    if (price != null) qrData['price'] = price;
    if (storeId != null) qrData['store'] = storeId;

    // تحويل البيانات إلى نص مرمز
    return qrData.entries.map((e) => '${e.key}:${e.value}').join('|');
  }
}
