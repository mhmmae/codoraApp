import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

import '../../../../Model/model_item.dart';
import '../../../../XXX/xxx_firebase.dart';
import '../models/sequential_barcode_model.dart';
import '../services/barcode_generator_service.dart';
import '../services/printing_service.dart';

class AddQuantityController extends GetxController {
  final ItemModel product;
  final VoidCallback? onSuccess;
  
  AddQuantityController({
    required this.product,
    this.onSuccess,
  });
  
  // Controllers
  final TextEditingController quantityController = TextEditingController();
  
  // Observable variables
  final RxBool isLoading = false.obs;
  final RxInt addedQuantity = 0.obs;
  final RxBool generateSequentialBarcodes = false.obs;
  final RxBool printMainBarcode = false.obs;
  final RxInt mainBarcodePrintCount = 1.obs;
  
  // Services
  final BarcodeGeneratorService _barcodeService = BarcodeGeneratorService();
  final PrintingService _printingService = PrintingService();
  
  @override
  void onInit() {
    super.onInit();
    quantityController.text = '1';
    addedQuantity.value = 1;
    
    // إضافة listener لحقل الكمية
    quantityController.addListener(() {
      final value = int.tryParse(quantityController.text) ?? 0;
      addedQuantity.value = value;
      mainBarcodePrintCount.value = value;
    });
  }
  
  @override
  void onClose() {
    quantityController.dispose();
    super.onClose();
  }
  
  /// تحديث قيمة الكمية
  void updateQuantity(String value) {
    final intValue = int.tryParse(value) ?? 0;
    if (intValue >= 0) {
      addedQuantity.value = intValue;
      if (printMainBarcode.value) {
        mainBarcodePrintCount.value = intValue;
      }
    }
  }
  
  /// تحديث خيار إنتاج الباركود التسلسلي
  void toggleSequentialBarcodes(bool value) {
    generateSequentialBarcodes.value = value;
  }
  
  /// تحديث خيار طباعة الباركود الرئيسي
  void toggleMainBarcodePrinting(bool value) {
    printMainBarcode.value = value;
    if (value) {
      mainBarcodePrintCount.value = addedQuantity.value;
    }
  }
  
  /// تحديث عدد طبعات الباركود الرئيسي
  void updateMainBarcodePrintCount(int count) {
    if (count > 0) {
      mainBarcodePrintCount.value = count;
    }
  }
  
  /// إضافة الكمية للمنتج
  Future<void> addQuantity() async {
    print('🚀 بدء عملية إضافة الكمية...');
    print('🔢 الكمية المراد إضافتها: ${addedQuantity.value}');
    print('📦 معرف المنتج: ${product.id}');
    print('📦 اسم المنتج: ${product.name}');
    print('📦 الكمية الحالية: ${product.quantity}');
    
    if (addedQuantity.value <= 0) {
      print('❌ الكمية غير صحيحة');
      Get.snackbar(
        'خطأ',
        'يجب إدخال كمية صحيحة',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }
    
    try {
      isLoading.value = true;
      print('⏳ بدء التحميل...');
      
      List<SequentialBarcodeModel> sequentialBarcodes = [];
      
      // إنتاج الباركودات التسلسلية إذا كان مطلوباً
      if (generateSequentialBarcodes.value) {
        try {
          print('🏷️ إنتاج الباركودات التسلسلية...');
          sequentialBarcodes = await _generateSequentialBarcodes();
          print('✅ تم إنتاج ${sequentialBarcodes.length} باركود تسلسلي');
        } catch (e) {
          print('⚠️ خطأ في إنتاج الباركودات التسلسلية: $e');
          // نتابع بدون باركودات تسلسلية
          sequentialBarcodes = [];
        }
      }
      
      // التحقق من الاتصال بـ Firebase
      print('🔗 التحقق من الاتصال بـ Firebase...');
      await _checkFirebaseConnection();
      
      // تحديث الكمية في Firebase
      print('💾 تحديث الكمية في Firebase...');
      await _updateProductQuantity();
      print('✅ تم تحديث الكمية بنجاح');
      
      // العملية الأساسية تمت بنجاح - يمكننا الآن العودة
      
      // طباعة الباركودات (اختياري - لا يؤثر على نجاح العملية)
      if (generateSequentialBarcodes.value || printMainBarcode.value) {
        try {
          print('🖨️ بدء طباعة الباركودات...');
          await _handleBarcodePrinting(sequentialBarcodes);
          print('✅ تم الانتهاء من الطباعة');
        } catch (e) {
          print('⚠️ خطأ في الطباعة (لا يؤثر على إضافة الكمية): $e');
          // لا نرفع الخطأ - نتابع العملية
        }
      }
      
      // حفظ الباركودات التسلسلية (اختياري)
      if (sequentialBarcodes.isNotEmpty) {
        try {
          print('💾 حفظ الباركودات التسلسلية...');
          await _saveSequentialBarcodes(sequentialBarcodes);
          print('✅ تم حفظ الباركودات التسلسلية');
        } catch (e) {
          print('⚠️ خطأ في حفظ الباركودات التسلسلية: $e');
          // لا نرفع الخطأ - العملية الأساسية نجحت
        }
      }
      
      print('🎉 تمت العملية بنجاح!');
      
      // إيقاف التحميل أولاً
      isLoading.value = false;
      
      // العودة للصفحة السابقة مع تحديث النتائج فوراً
      print('🔙 العودة للصفحة السابقة...');
      
      // استخدام callback أولاً إذا كان متاحاً
      if (onSuccess != null) {
        print('✅ استخدام callback للعودة');
        onSuccess!();
      } else {
        print('⚠️ لا يوجد callback، استخدام الطرق البديلة');
        _returnToPreviousPage(success: true);
      }
      
      print('✅ تم الانتهاء من العملية والعودة للصفحة السابقة');
      
      // إظهار رسالة النجاح بعد العودة
      await Future.delayed(const Duration(milliseconds: 100));
      Get.snackbar(
        '✅ نجحت العملية',
        'تم إضافة ${addedQuantity.value} قطعة للمنتج بنجاح',
        backgroundColor: Colors.green,
        colorText: Colors.white,
        duration: const Duration(seconds: 2),
        snackPosition: SnackPosition.TOP,
        icon: const Icon(Icons.check_circle, color: Colors.white),
      );
      
    } catch (e) {
      print('❌ خطأ في إضافة الكمية: $e');
      print('❌ تفاصيل الخطأ: ${e.toString()}');
      
      // إيقاف التحميل في حالة الخطأ
      isLoading.value = false;
      
      Get.snackbar(
        'خطأ',
        'حدث خطأ في إضافة الكمية: ${e.toString()}',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        duration: const Duration(seconds: 4),
        snackPosition: SnackPosition.TOP,
      );
    }
  }
  
  /// العودة للصفحة السابقة مع النتيجة
  void _returnToPreviousPage({required bool success}) {
    try {
      print('🔙 محاولة العودة للصفحة السابقة...');
      
      // الطريقة الأولى: استخدام Get.back
      if (Get.isRegistered<AddQuantityController>()) {
        Get.back(result: success);
        print('✅ تم العودة باستخدام Get.back');
        return;
      }
      
      // الطريقة الثانية: استخدام Navigator مباشرة
      if (Get.context != null) {
        Navigator.of(Get.context!).pop(success);
        print('✅ تم العودة باستخدام Navigator');
        return;
      }
      
      // الطريقة الثالثة: محاولة الحصول على BuildContext
      final context = Get.overlayContext;
      if (context != null) {
        Navigator.of(context).pop(success);
        print('✅ تم العودة باستخدام overlayContext');
        return;
      }
      
      print('⚠️ لم يتم العثور على context مناسب للعودة');
      
    } catch (e) {
      print('❌ خطأ في العودة للصفحة السابقة: $e');
    }
  }
  
  /// إنتاج الباركودات التسلسلية
  Future<List<SequentialBarcodeModel>> _generateSequentialBarcodes() async {
    final List<SequentialBarcodeModel> barcodes = [];
    final uuid = const Uuid();
    
    for (int i = 0; i < addedQuantity.value; i++) {
      final sequentialBarcode = _barcodeService.generateSequentialBarcode(
        productId: product.id,
        sequenceNumber: i + 1,
      );
      
      barcodes.add(SequentialBarcodeModel(
        id: uuid.v4(),
        productId: product.id,
        productName: product.name,
        sequentialBarcode: sequentialBarcode,
        mainProductBarcode: product.mainProductBarcode ?? '',
        sellerId: product.uidAdd,
        createdAt: DateTime.now(),
        isPrinted: false,
        isUsed: false,
      ));
    }
    
    return barcodes;
  }
  
  /// التحقق من الاتصال بـ Firebase
  Future<void> _checkFirebaseConnection() async {
    try {
      // محاولة قراءة بسيطة للتأكد من الاتصال
      final testDoc = await FirebaseFirestore.instance
          .collection(FirebaseX.itemsCollection)
          .doc(product.id)
          .get();
      
      if (!testDoc.exists) {
        throw Exception('المنتج غير موجود في قاعدة البيانات');
      }
      
      print('✅ الاتصال بـ Firebase مُحقق');
    } catch (e) {
      print('❌ خطأ في الاتصال بـ Firebase: $e');
      throw Exception('فشل في الاتصال بقاعدة البيانات: $e');
    }
  }

  /// تحديث كمية المنتج في Firebase
  Future<void> _updateProductQuantity() async {
    final currentQuantity = product.quantity ?? 0;
    final newQuantity = currentQuantity + addedQuantity.value;
    
    print('📊 الكمية الحالية: $currentQuantity');
    print('📊 الكمية المضافة: ${addedQuantity.value}');
    print('📊 الكمية الجديدة: $newQuantity');
    print('📊 معرف المستند: ${product.id}');
    print('📊 اسم المجموعة: ${FirebaseX.itemsCollection}');
    
    try {
      await FirebaseFirestore.instance
          .collection(FirebaseX.itemsCollection)
          .doc(product.id)
          .update({
        'quantity': newQuantity,
        'lastQuantityUpdate': FieldValue.serverTimestamp(),
      });
      
      print('✅ تم تحديث Firebase بنجاح');
      
    } catch (e) {
      print('❌ خطأ في تحديث Firebase: $e');
      rethrow;
    }
  }
  
  /// التعامل مع طباعة الباركودات
  Future<void> _handleBarcodePrinting(List<SequentialBarcodeModel> sequentialBarcodes) async {
    List<Future> printingTasks = [];
    
    // طباعة الباركودات التسلسلية
    if (sequentialBarcodes.isNotEmpty) {
      printingTasks.add(_printingService.printSequentialBarcodes(sequentialBarcodes));
    }
    
    // طباعة الباركود الرئيسي
    if (printMainBarcode.value && product.mainProductBarcode != null) {
      printingTasks.add(_printingService.printMainBarcode(
        product.mainProductBarcode!,
        product.name,
        mainBarcodePrintCount.value,
      ));
    }
    
    // تنفيذ جميع مهام الطباعة
    if (printingTasks.isNotEmpty) {
      await Future.wait(printingTasks);
    }
  }
  
  /// حفظ الباركودات التسلسلية في Firebase
  Future<void> _saveSequentialBarcodes(List<SequentialBarcodeModel> barcodes) async {
    final batch = FirebaseFirestore.instance.batch();
    
    for (final barcode in barcodes) {
      final docRef = FirebaseFirestore.instance
          .collection('sequential_barcodes')
          .doc(barcode.id);
      
      batch.set(docRef, barcode.toMap());
    }
    
    await batch.commit();
  }
  
  /// معاينة الباركودات قبل الطباعة
  Future<void> previewBarcodes() async {
    try {
      List<String> barcodesToPreview = [];
      
      // إضافة الباركود الرئيسي للمعاينة
      if (product.mainProductBarcode != null) {
        barcodesToPreview.add(product.mainProductBarcode!);
      }
      
      // إضافة نماذج من الباركودات التسلسلية للمعاينة
      if (generateSequentialBarcodes.value) {
        for (int i = 0; i < math.min(3, addedQuantity.value); i++) {
          final sampleBarcode = _barcodeService.generateSequentialBarcode(
            productId: product.id,
            sequenceNumber: i + 1,
          );
          barcodesToPreview.add(sampleBarcode);
        }
      }
      
      // عرض نافذة المعاينة
      await Get.dialog(
        _BarcodePreviewDialog(
          barcodes: barcodesToPreview,
          productName: product.name,
          totalQuantity: addedQuantity.value,
        ),
      );
      
    } catch (e) {
      print('خطأ في معاينة الباركودات: $e');
      Get.snackbar(
        'خطأ',
        'حدث خطأ في معاينة الباركودات',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }
}

class _BarcodePreviewDialog extends StatelessWidget {
  final List<String> barcodes;
  final String productName;
  final int totalQuantity;
  
  const _BarcodePreviewDialog({
    required this.barcodes,
    required this.productName,
    required this.totalQuantity,
  });
  
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('معاينة الباركودات'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('المنتج: $productName'),
            Text('العدد الإجمالي: $totalQuantity'),
            const SizedBox(height: 16),
            const Text('نماذج من الباركودات:'),
            const SizedBox(height: 8),
            ...barcodes.map((barcode) => Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                barcode,
                style: const TextStyle(fontFamily: 'monospace'),
              ),
            )),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Get.back(),
          child: const Text('إغلاق'),
        ),
      ],
    );
  }
} 