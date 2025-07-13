import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:barcode/barcode.dart';

import '../models/sequential_barcode_model.dart';

class PrintingService {
  /// طباعة الباركودات التسلسلية
  Future<void> printSequentialBarcodes(List<SequentialBarcodeModel> barcodes) async {
    try {
      // إنشاء PDF للباركودات التسلسلية
      final pdf = await _createSequentialBarcodesPDF(barcodes);
      
      // عرض نافذة الطباعة
      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdf.save(),
        name: 'الباركودات التسلسلية - ${barcodes.first.productName}',
      );
      
      // تحديث حالة الطباعة في القاعدة
      await _markBarcodesAsPrinted(barcodes);
      
    } catch (e) {
      print('خطأ في طباعة الباركودات التسلسلية: $e');
      throw Exception('فشل في طباعة الباركودات التسلسلية: $e');
    }
  }
  
  /// طباعة الباركود الرئيسي
  Future<void> printMainBarcode(String barcode, String productName, int copies) async {
    try {
      // إنشاء PDF للباركود الرئيسي
      final pdf = await _createMainBarcodePDF(barcode, productName, copies);
      
      // عرض نافذة الطباعة
      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdf.save(),
        name: 'الباركود الرئيسي - $productName',
      );
      
    } catch (e) {
      print('خطأ في طباعة الباركود الرئيسي: $e');
      throw Exception('فشل في طباعة الباركود الرئيسي: $e');
    }
  }
  
  /// إنشاء PDF للباركودات التسلسلية
  Future<pw.Document> _createSequentialBarcodesPDF(List<SequentialBarcodeModel> barcodes) async {
    final pdf = pw.Document();
    
    // تقسيم الباركودات إلى صفحات (4 باركودات في كل صفحة)
    const barcodesPerPage = 4;
    final totalPages = (barcodes.length / barcodesPerPage).ceil();
    
    for (int pageIndex = 0; pageIndex < totalPages; pageIndex++) {
      final startIndex = pageIndex * barcodesPerPage;
      final endIndex = (startIndex + barcodesPerPage > barcodes.length) 
          ? barcodes.length 
          : startIndex + barcodesPerPage;
      
      final pageBarcodes = barcodes.sublist(startIndex, endIndex);
      
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(20),
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // عنوان الصفحة
                pw.Header(
                  level: 0,
                  child: pw.Text(
                    'الباركودات التسلسلية - ${pageBarcodes.first.productName}',
                    style: pw.TextStyle(
                      fontSize: 18,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ),
                
                pw.SizedBox(height: 20),
                
                // الباركودات
                pw.Expanded(
                  child: pw.GridView(
                    crossAxisCount: 2,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 15,
                    children: pageBarcodes.map((barcode) => _buildBarcodeWidget(
                      barcode.sequentialBarcode,
                      barcode.productName,
                      isSequential: true,
                    )).toList(),
                  ),
                ),
                
                // معلومات الصفحة
                pw.Footer(
                  title: pw.Text(
                    'صفحة ${pageIndex + 1} من $totalPages - تاريخ الطباعة: ${DateTime.now().toString().split(' ')[0]}',
                    style: const pw.TextStyle(fontSize: 10),
                  ),
                ),
              ],
            );
          },
        ),
      );
    }
    
    return pdf;
  }
  
  /// إنشاء PDF للباركود الرئيسي
  Future<pw.Document> _createMainBarcodePDF(String barcode, String productName, int copies) async {
    final pdf = pw.Document();
    
    // تقسيم النسخ إلى صفحات (6 باركودات في كل صفحة)
    const barcodesPerPage = 6;
    final totalPages = (copies / barcodesPerPage).ceil();
    
    for (int pageIndex = 0; pageIndex < totalPages; pageIndex++) {
      final startIndex = pageIndex * barcodesPerPage;
      final endIndex = (startIndex + barcodesPerPage > copies) 
          ? copies 
          : startIndex + barcodesPerPage;
      
      final pageBarcodesCount = endIndex - startIndex;
      
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(20),
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // عنوان الصفحة
                pw.Header(
                  level: 0,
                  child: pw.Text(
                    'الباركود الرئيسي - $productName',
                    style: pw.TextStyle(
                      fontSize: 18,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ),
                
                pw.SizedBox(height: 20),
                
                // الباركودات
                pw.Expanded(
                  child: pw.GridView(
                    crossAxisCount: 2,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 15,
                    children: List.generate(
                      pageBarcodesCount,
                      (index) => _buildBarcodeWidget(
                        barcode,
                        productName,
                        isSequential: false,
                        copyNumber: startIndex + index + 1,
                      ),
                    ),
                  ),
                ),
                
                // معلومات الصفحة
                pw.Footer(
                  title: pw.Text(
                    'صفحة ${pageIndex + 1} من $totalPages - إجمالي النسخ: $copies - تاريخ الطباعة: ${DateTime.now().toString().split(' ')[0]}',
                    style: const pw.TextStyle(fontSize: 10),
                  ),
                ),
              ],
            );
          },
        ),
      );
    }
    
    return pdf;
  }
  
  /// بناء عنصر الباركود للطباعة
  pw.Widget _buildBarcodeWidget(
    String barcodeData,
    String productName, {
    required bool isSequential,
    int? copyNumber,
  }) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.black, width: 1),
        borderRadius: pw.BorderRadius.circular(5),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          // اسم المنتج
          pw.Text(
            productName,
            style: pw.TextStyle(
              fontSize: 12,
              fontWeight: pw.FontWeight.bold,
            ),
            textAlign: pw.TextAlign.center,
            maxLines: 2,
          ),
          
          pw.SizedBox(height: 8),
          
          // الباركود
          pw.BarcodeWidget(
            barcode: Barcode.code128(),
            data: barcodeData,
            width: 150,
            height: 60,
          ),
          
          pw.SizedBox(height: 5),
          
          // نص الباركود
          pw.Text(
            barcodeData,
            style: const pw.TextStyle(fontSize: 8),
            textAlign: pw.TextAlign.center,
          ),
          
          pw.SizedBox(height: 5),
          
          // معلومات إضافية
          pw.Text(
            isSequential 
                ? 'باركود تسلسلي'
                : 'نسخة ${copyNumber ?? 1}',
            style: pw.TextStyle(
              fontSize: 8,
              fontStyle: pw.FontStyle.italic,
            ),
            textAlign: pw.TextAlign.center,
          ),
        ],
      ),
    );
  }
  
  /// تحديد الباركودات كمطبوعة
  Future<void> _markBarcodesAsPrinted(List<SequentialBarcodeModel> barcodes) async {
    // تحديث حالة الطباعة في قاعدة البيانات
    // هذا يتطلب تطبيق التحديث في Firebase
    for (final barcode in barcodes) {
      // يمكن إضافة كود تحديث Firebase هنا
      print('تم تحديد الباركود ${barcode.sequentialBarcode} كمطبوع');
    }
  }
  
  /// معاينة PDF قبل الطباعة
  Future<void> previewPDF(pw.Document pdf, String title) async {
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: title,
    );
  }
  
  /// طباعة باركود واحد
  Future<void> printSingleBarcode(String barcodeData, String productName) async {
    try {
      final pdf = pw.Document();
      
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(50),
          build: (pw.Context context) {
            return pw.Center(
              child: pw.Container(
                width: 300,
                height: 200,
                padding: const pw.EdgeInsets.all(20),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.black, width: 2),
                  borderRadius: pw.BorderRadius.circular(10),
                ),
                child: pw.Column(
                  mainAxisAlignment: pw.MainAxisAlignment.center,
                  children: [
                    pw.Text(
                      productName,
                      style: pw.TextStyle(
                        fontSize: 16,
                        fontWeight: pw.FontWeight.bold,
                      ),
                      textAlign: pw.TextAlign.center,
                    ),
                    
                    pw.SizedBox(height: 20),
                    
                    pw.BarcodeWidget(
                      barcode: Barcode.code128(),
                      data: barcodeData,
                      width: 200,
                      height: 80,
                    ),
                    
                    pw.SizedBox(height: 10),
                    
                    pw.Text(
                      barcodeData,
                      style: const pw.TextStyle(fontSize: 12),
                      textAlign: pw.TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      );
      
      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdf.save(),
        name: 'باركود - $productName',
      );
      
    } catch (e) {
      print('خطأ في طباعة الباركود الواحد: $e');
      throw Exception('فشل في طباعة الباركود: $e');
    }
  }
} 