import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:math';
import 'package:printing/printing.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';

import '../../../../Model/model_item.dart';

class SequentialBarcodePrintController extends GetxController {
  final TextEditingController searchController = TextEditingController();
  final TextEditingController quantityController = TextEditingController();
  
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
          allProducts.add(product);
          products.add(product);
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

  Future<void> printSequentialBarcodes(ItemModel product) async {
    final quantityText = quantityController.text.trim();
    
    if (quantityText.isEmpty) {
      Get.snackbar(
        'خطأ',
        'يرجى إدخال عدد الباركودات',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    final quantity = int.tryParse(quantityText);
    if (quantity == null || quantity <= 0) {
      Get.snackbar(
        'خطأ',
        'يرجى إدخال عدد صحيح وأكبر من صفر',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    if (quantity > 500) {
      Get.snackbar(
        'خطأ',
        'العدد الأقصى هو 500 باركود',
        backgroundColor: Colors.orange,
        colorText: Colors.white,
      );
      return;
    }

    try {
      isPrinting.value = true;
      
      // 1. إنشاء الباركودات التسلسلية
      final List<String> sequentialBarcodes = _generateSequentialBarcodes(product, quantity);
      
      // 2. طباعة الباركودات
      await _printBarcodes(product, sequentialBarcodes);
      
      // 3. حفظ الباركودات في Firebase
      await _saveBarcodeToFirebase(product, sequentialBarcodes);
      
      // 4. إشعار النجاح
      Get.back();
      quantityController.clear();
      
      Get.snackbar(
        'نجح',
        'تم إنشاء وطباعة وحفظ ${sequentialBarcodes.length} باركود بنجاح',
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

  List<String> _generateSequentialBarcodes(ItemModel product, int quantity) {
    final List<String> barcodes = [];
    final Random random = Random();
    
    final String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
    final String baseCode = timestamp.substring(timestamp.length - 8);
    
    for (int i = 1; i <= quantity; i++) {
      final String sequentialBarcode = '$baseCode${i.toString().padLeft(4, '0')}${random.nextInt(99).toString().padLeft(2, '0')}';
      barcodes.add(sequentialBarcode);
    }
    
    return barcodes;
  }

  Future<void> _printBarcodes(ItemModel product, List<String> barcodes) async {
    try {
      final pdf = pw.Document();
      
      const int barcodesPerPage = 8;
      final int totalPages = (barcodes.length / barcodesPerPage).ceil();
      
      for (int page = 0; page < totalPages; page++) {
        final int startIndex = page * barcodesPerPage;
        final int endIndex = (startIndex + barcodesPerPage > barcodes.length) 
            ? barcodes.length 
            : startIndex + barcodesPerPage;
        
        final List<String> pageBarcodes = barcodes.sublist(startIndex, endIndex);
        
        pdf.addPage(
          pw.Page(
            pageFormat: PdfPageFormat.a4,
            margin: const pw.EdgeInsets.all(20),
            build: (pw.Context context) {
              return pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Container(
                    width: double.infinity,
                    padding: const pw.EdgeInsets.all(10),
                    decoration: pw.BoxDecoration(
                      border: pw.Border.all(),
                      borderRadius: pw.BorderRadius.circular(5),
                    ),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'المنتج: ${product.name}',
                          style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
                        ),
                        pw.SizedBox(height: 4),
                        pw.Text('السعر: ${product.price.toStringAsFixed(2)} د.ل'),
                        pw.Text('الصفحة: ${page + 1} من $totalPages'),
                        pw.Text('التاريخ: ${DateTime.now().toString().substring(0, 19)}'),
                      ],
                    ),
                  ),
                  
                  pw.SizedBox(height: 20),
                  
                  pw.Wrap(
                    spacing: 10,
                    runSpacing: 15,
                    children: pageBarcodes.map((barcode) {
                      return pw.Container(
                        width: 180,
                        height: 80,
                        decoration: pw.BoxDecoration(
                          border: pw.Border.all(),
                          borderRadius: pw.BorderRadius.circular(5),
                        ),
                        child: pw.Column(
                          mainAxisAlignment: pw.MainAxisAlignment.center,
                          children: [
                            pw.BarcodeWidget(
                              barcode: pw.Barcode.code128(),
                              data: barcode,
                              width: 160,
                              height: 50,
                            ),
                            pw.SizedBox(height: 4),
                            pw.Text(
                              barcode,
                              style: const pw.TextStyle(fontSize: 10),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ],
              );
            },
          ),
        );
      }
      
      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdf.save(),
        name: 'باركودات_تسلسلية_${product.name}_${DateTime.now().millisecondsSinceEpoch}',
      );
      
    } catch (e) {
      throw 'فشل في إنشاء أو طباعة PDF: $e';
    }
  }

  Future<void> _saveBarcodeToFirebase(ItemModel product, List<String> barcodes) async {
    try {
      final batch = _firestore.batch();
      
      for (String barcode in barcodes) {
        final barcodeDoc = _firestore
            .collection('الباركودات_التسلسلية')
            .doc(barcode);
        
        batch.set(barcodeDoc, {
          'barcode': barcode,
          'productId': product.id,
          'productName': product.name,
          'userId': userId,
          'createdAt': FieldValue.serverTimestamp(),
          'isUsed': false,
          'printedAt': FieldValue.serverTimestamp(),
        });
      }
      
      final productDoc = _firestore.collection('Item').doc(product.id);
      batch.update(productDoc, {
        'sequentialBarcodes': FieldValue.arrayUnion(barcodes),
        'totalSequentialBarcodes': FieldValue.increment(barcodes.length),
        'lastBarcodeGeneration': FieldValue.serverTimestamp(),
      });
      
      await batch.commit();
      
    } catch (e) {
      throw 'فشل في حفظ البيانات: $e';
    }
  }
}
