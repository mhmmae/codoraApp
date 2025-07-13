import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:printing/printing.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';

import '../../../../Model/model_item.dart';

class MainBarcodePrintController extends GetxController {
  final TextEditingController searchController = TextEditingController();
  final TextEditingController quantityController = TextEditingController(text: '1');
  
  final RxList<ItemModel> products = <ItemModel>[].obs;
  final RxList<ItemModel> allProducts = <ItemModel>[].obs;
  final RxBool isLoading = false.obs;
  final RxBool isSearching = false.obs;
  final RxBool isPrinting = false.obs;
  
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String? userId = FirebaseAuth.instance.currentUser?.uid;

  @override
  void onInit() {
    super.onInit();
    loadProducts();
  }

  @override
  void onClose() {
    searchController.dispose();
    quantityController.dispose();
    super.onClose();
  }

  Future<void> loadProducts() async {
    if (userId == null) return;
    
    try {
      isLoading.value = true;
      
      final QuerySnapshot snapshot = await _firestore
          .collection('Item')
          .where('uidAdd', isEqualTo: userId)
          .get();

      allProducts.clear();
      products.clear();
      
      for (var doc in snapshot.docs) {
        try {
          final data = doc.data() as Map<String, dynamic>;
          final product = ItemModel.fromMap(data, doc.id);
          
          // فقط المنتجات التي لها باركود رئيسي
          if (product.mainProductBarcode != null && product.mainProductBarcode!.isNotEmpty) {
            allProducts.add(product);
            products.add(product);
          }
        } catch (e) {
          print('خطأ في تحويل المنتج: $e');
        }
      }
    } catch (e) {
      Get.snackbar(
        'خطأ',
        'فشل في تحميل المنتجات: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  void onSearchChanged(String query) {
    isSearching.value = true;
    
    if (query.isEmpty) {
      products.assignAll(allProducts);
    } else {
      products.assignAll(
        allProducts.where((product) => 
          product.name.toLowerCase().contains(query.toLowerCase()) ||
          (product.mainProductBarcode?.contains(query) ?? false)
        ).toList(),
      );
    }
    
    isSearching.value = false;
  }

  void clearSearch() {
    searchController.clear();
    products.assignAll(allProducts);
  }

  Future<void> printMainBarcode(ItemModel product) async {
    final quantityText = quantityController.text.trim();
    int copies = 1;
    
    if (quantityText.isNotEmpty) {
      final parsedCopies = int.tryParse(quantityText);
      if (parsedCopies == null || parsedCopies <= 0) {
        Get.snackbar(
          'خطأ',
          'يرجى إدخال عدد صحيح وأكبر من صفر',
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        return;
      }
      
      if (parsedCopies > 100) {
        Get.snackbar(
          'خطأ',
          'العدد الأقصى هو 100 نسخة',
          backgroundColor: Colors.orange,
          colorText: Colors.white,
        );
        return;
      }
      
      copies = parsedCopies;
    }

    if (product.mainProductBarcode == null || product.mainProductBarcode!.isEmpty) {
      Get.snackbar(
        'خطأ',
        'هذا المنتج ليس له باركود رئيسي',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    try {
      isPrinting.value = true;
      
      await _printMainBarcode(product, copies);
      
      Get.back();
      quantityController.text = '1';
      
      Get.snackbar(
        'نجح',
        'تم طباعة الباركود الرئيسي بنجاح ($copies نسخة)',
        backgroundColor: Colors.green,
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );
      
    } catch (e) {
      Get.snackbar(
        'خطأ',
        'فشلت العملية: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isPrinting.value = false;
    }
  }

  Future<void> _printMainBarcode(ItemModel product, int copies) async {
    try {
      final pdf = pw.Document();
      
      const int barcodesPerPage = 6;
      final int totalPages = (copies / barcodesPerPage).ceil();
      
      for (int page = 0; page < totalPages; page++) {
        final int startIndex = page * barcodesPerPage;
        final int endIndex = (startIndex + barcodesPerPage > copies) 
            ? copies 
            : startIndex + barcodesPerPage;
        
        final int pageCopies = endIndex - startIndex;
        
        pdf.addPage(
          pw.Page(
            pageFormat: PdfPageFormat.a4,
            margin: const pw.EdgeInsets.all(20),
            build: (pw.Context context) {
              return pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  // معلومات المنتج
                  pw.Container(
                    width: double.infinity,
                    padding: const pw.EdgeInsets.all(15),
                    decoration: pw.BoxDecoration(
                      border: pw.Border.all(width: 2),
                      borderRadius: pw.BorderRadius.circular(8),
                      color: PdfColors.grey100,
                    ),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'المنتج: ${product.name}',
                          style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
                        ),
                        pw.SizedBox(height: 6),
                        pw.Text('السعر: ${product.price.toStringAsFixed(2)} د.ل', style: const pw.TextStyle(fontSize: 12)),
                        pw.Text('الباركود الرئيسي: ${product.mainProductBarcode}', style: const pw.TextStyle(fontSize: 12)),
                        pw.Text('الصفحة: ${page + 1} من $totalPages', style: const pw.TextStyle(fontSize: 10)),
                        pw.Text('التاريخ: ${DateTime.now().toString().substring(0, 19)}', style: const pw.TextStyle(fontSize: 10)),
                      ],
                    ),
                  ),
                  
                  pw.SizedBox(height: 30),
                  
                  // الباركودات في شبكة
                  pw.Wrap(
                    spacing: 15,
                    runSpacing: 20,
                    children: List.generate(pageCopies, (index) {
                      return pw.Container(
                        width: 250,
                        height: 120,
                        decoration: pw.BoxDecoration(
                          border: pw.Border.all(width: 2),
                          borderRadius: pw.BorderRadius.circular(8),
                        ),
                        child: pw.Column(
                          mainAxisAlignment: pw.MainAxisAlignment.center,
                          children: [
                            pw.Text(
                              product.name,
                              style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
                              textAlign: pw.TextAlign.center,
                            ),
                            pw.SizedBox(height: 8),
                            // باركود
                            pw.BarcodeWidget(
                              barcode: pw.Barcode.code128(),
                              data: product.mainProductBarcode!,
                              width: 220,
                              height: 60,
                            ),
                            pw.SizedBox(height: 6),
                            // رقم الباركود
                            pw.Text(
                              product.mainProductBarcode!,
                              style: const pw.TextStyle(fontSize: 11),
                            ),
                            pw.Text(
                              '${product.price.toStringAsFixed(2)} د.ل',
                              style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
                            ),
                          ],
                        ),
                      );
                    }),
                  ),
                ],
              );
            },
          ),
        );
      }
      
      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdf.save(),
        name: 'باركود_رئيسي_${product.name}_${DateTime.now().millisecondsSinceEpoch}',
      );
      
    } catch (e) {
      throw 'فشل في إنشاء أو طباعة PDF: $e';
    }
  }
}
