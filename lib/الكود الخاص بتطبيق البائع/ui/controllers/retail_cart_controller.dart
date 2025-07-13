import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../Model/SellerModel.dart';

class RetailCartController extends GetxController {
  static RetailCartController get instance => Get.find();

  final GetStorage _storage = GetStorage();

  // خريطة للمتاجر وسلالها المنفصلة
  final RxMap<String, List<CartItem>> storesCarts =
      <String, List<CartItem>>{}.obs;

  // معرف المتجر النشط حالياً
  final RxString activeStoreId = ''.obs;

  // معلومات المتاجر
  final RxMap<String, SellerModel> storesInfo = <String, SellerModel>{}.obs;

  final RxDouble totalAmount = 0.0.obs;
  final RxBool isLoading = false.obs;

  // معلومات المتجر الحالي النشط
  SellerModel? get currentStore => storesInfo[activeStoreId.value];

  // العناصر في السلة للمتجر النشط
  List<CartItem> get cartItems => storesCarts[activeStoreId.value] ?? [];

  // جميع المتاجر التي لديها منتجات في السلة
  List<SellerModel> get storesWithItems =>
      storesInfo.values
          .where((store) => (storesCarts[store.uid] ?? []).isNotEmpty)
          .toList();

  @override
  void onInit() {
    super.onInit();
    _loadCartsFromStorage();

    // مراقبة التغييرات في السلال
    ever(storesCarts, (_) => _calculateActiveStoreTotal());
    ever(activeStoreId, (_) => _calculateActiveStoreTotal());
  }

  /// تحديد المتجر النشط
  void setActiveStore(String storeId) {
    if (storeId.isEmpty) return;

    debugPrint('🏪 تغيير المتجر النشط إلى: $storeId');
    activeStoreId.value = storeId;
    _calculateActiveStoreTotal();

    // إجبار تحديث جميع الـ widgets المرتبطة بالسلة
    storesCarts.refresh();
    update();

    // تحديث widgets محددة للمنتجات في هذا المتجر
    if (storesCarts.containsKey(storeId)) {
      final storeCart = storesCarts[storeId]!;
      for (final item in storeCart) {
        update(['cart_${item.productId}']);
      }
    }

    debugPrint('✅ تم تحديث المتجر النشط والـ UI');
  }

  /// تحميل جميع السلال من التخزين المحلي
  void _loadCartsFromStorage() {
    try {
      final String? userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) return;

      // تحميل سلال المتاجر
      final Map<String, dynamic>? savedCarts = _storage.read(
        'retail_stores_carts_$userId',
      );
      if (savedCarts != null) {
        storesCarts.clear();
        savedCarts.forEach((storeId, cartData) {
          final List<dynamic> items = cartData['items'] ?? [];
          storesCarts[storeId] =
              items
                  .map((item) => CartItem.fromMap(item as Map<String, dynamic>))
                  .toList();
        });
      }

      // تحميل معلومات المتاجر
      final Map<String, dynamic>? savedStores = _storage.read(
        'retail_stores_info_$userId',
      );
      if (savedStores != null) {
        storesInfo.clear();
        savedStores.forEach((storeId, storeData) {
          storesInfo[storeId] = SellerModel.fromMap(
            storeData as Map<String, dynamic>,
            storeId,
          );
        });
      }

      // تحديد المتجر النشط الأخير
      final String? lastActiveStore = _storage.read(
        'retail_last_active_store_$userId',
      );
      if (lastActiveStore != null && storesCarts.containsKey(lastActiveStore)) {
        activeStoreId.value = lastActiveStore;
      } else if (storesCarts.isNotEmpty) {
        // اختيار أول متجر يحتوي على منتجات
        activeStoreId.value = storesCarts.keys.first;
      }

      _calculateActiveStoreTotal();
    } catch (e) {
      debugPrint('خطأ في تحميل السلال: $e');
    }
  }

  /// حفظ جميع السلال في التخزين المحلي
  void _saveCartsToStorage() {
    try {
      final String? userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) return;

      // حفظ سلال المتاجر
      final Map<String, dynamic> cartsData = {};
      storesCarts.forEach((storeId, items) {
        if (items.isNotEmpty) {
          try {
            final itemsData = items.map((item) => item.toMap()).toList();
            cartsData[storeId] = {
              'items': itemsData,
              'lastUpdated': DateTime.now().toIso8601String(),
            };
          } catch (e) {
            debugPrint('❌ خطأ في معالجة عناصر متجر $storeId: $e');
          }
        }
      });

      try {
        _storage.write('retail_stores_carts_$userId', cartsData);
        debugPrint('✅ تم حفظ سلال المتاجر بنجاح');
      } catch (e) {
        debugPrint('❌ خطأ في حفظ سلال المتاجر: $e');
      }

      // حفظ معلومات المتاجر
      final Map<String, dynamic> storesData = {};
      storesInfo.forEach((storeId, store) {
        try {
          storesData[storeId] = store.toMap();
        } catch (e) {
          debugPrint('❌ خطأ في معالجة بيانات متجر $storeId: $e');
        }
      });

      try {
        _storage.write('retail_stores_info_$userId', storesData);
        debugPrint('✅ تم حفظ معلومات المتاجر بنجاح');
      } catch (e) {
        debugPrint('❌ خطأ في حفظ معلومات المتاجر: $e');
      }

      // حفظ المتجر النشط الأخير
      if (activeStoreId.value.isNotEmpty) {
        try {
          _storage.write(
            'retail_last_active_store_$userId',
            activeStoreId.value,
          );
          debugPrint('✅ تم حفظ المتجر النشط بنجاح');
        } catch (e) {
          debugPrint('❌ خطأ في حفظ المتجر النشط: $e');
        }
      }
    } catch (e) {
      debugPrint('خطأ في حفظ السلال: $e');
    }
  }

  /// إضافة منتج للسلة
  void addToCart(
    Map<String, dynamic> product,
    SellerModel store, {
    int quantity = 1,
  }) {
    try {
      // فحص صحة البيانات المدخلة
      if (product.isEmpty || store.uid.isEmpty) {
        debugPrint('❌ بيانات المنتج أو المتجر غير صحيحة');
        return;
      }

      if (product['id'] == null || product['id'].toString().isEmpty) {
        debugPrint('❌ معرف المنتج مفقود');
        return;
      }

      final storeId = store.uid;

      // إضافة/تحديث معلومات المتجر
      storesInfo[storeId] = store;

      // التأكد من وجود سلة للمتجر
      if (!storesCarts.containsKey(storeId)) {
        storesCarts[storeId] = <CartItem>[];
      }

      final storeCart = storesCarts[storeId]!;

      // البحث عن المنتج في سلة المتجر
      final existingIndex = storeCart.indexWhere(
        (item) => item.productId == product['id'],
      );

      if (existingIndex >= 0) {
        // زيادة الكمية إذا كان المنتج موجود
        storeCart[existingIndex].quantity += quantity;
      } else {
        // إضافة منتج جديد
        debugPrint('🆕 إضافة منتج جديد للسلة: ${product['nameOfItem']}');

        // استخراج صورة المنتج بحماية إضافية
        String productImage = '';
        try {
          productImage = _getFirstImage(product);
          debugPrint('📸 صورة المنتج: $productImage');
        } catch (e) {
          debugPrint('❌ خطأ في استخراج صورة المنتج: $e');
          productImage = ''; // استخدام قيمة افتراضية
        }

        final productName =
            product['nameOfItem']?.toString() ?? 'منتج غير محدد';
        final productPriceString = product['priceOfItem']?.toString() ?? '0';
        final productPrice = double.tryParse(productPriceString) ?? 0.0;

        debugPrint('💰 سعر المنتج: $productPrice');

        // تنظيف بيانات المنتج بحماية إضافية
        Map<String, dynamic> sanitizedData = {};
        try {
          sanitizedData = _sanitizeProductData(product);
          debugPrint('🧹 تم تنظيف بيانات المنتج بنجاح');
        } catch (e) {
          debugPrint('❌ خطأ في تنظيف بيانات المنتج: $e');
          // استخدام بيانات أساسية في حالة الخطأ
          sanitizedData = {
            'id': product['id'] ?? '',
            'nameOfItem': productName,
            'priceOfItem': productPrice,
          };
        }

        final cartItem = CartItem(
          productId: product['id'].toString(),
          productName: productName,
          productPrice: productPrice,
          productImage: productImage,
          quantity: quantity,
          storeId: storeId,
          storeName: store.shopName,
          productData: sanitizedData,
        );

        debugPrint('✅ تم إنشاء CartItem بنجاح');

        storeCart.add(cartItem);
      }

      // تحديث السلة في الخريطة مع إشارة التحديث
      storesCarts[storeId] = List.from(storeCart);
      storesCarts.refresh(); // إجبار تحديث RxMap

      // تحديد المتجر النشط
      setActiveStore(storeId);

      // تحديث الإجماليات
      _calculateActiveStoreTotal();

      _saveCartsToStorage();
      update(); // تحديث GetX
    } catch (e, stackTrace) {
      debugPrint('❌ خطأ في addToCart: $e');
      debugPrint('📍 تفاصيل الخطأ:');
      debugPrint('   - منتج: ${product['nameOfItem'] ?? 'غير محدد'}');
      debugPrint('   - معرف المنتج: ${product['id'] ?? 'غير محدد'}');
      debugPrint('   - متجر: ${store.shopName}');
      debugPrint('📍 Stack trace: $stackTrace');

      // عدم رمي الخطأ مرة أخرى لمنع crash التطبيق
      // rethrow;
    }
  }

  /// إزالة منتج من السلة
  void removeFromCart(String productId) {
    try {
      final storeId = activeStoreId.value;

      if (storeId.isEmpty || !storesCarts.containsKey(storeId)) {
        return;
      }

      final storeCart = storesCarts[storeId]!;
      final removedItem = storeCart.firstWhereOrNull(
        (item) => item.productId == productId,
      );

      if (removedItem != null) {
        debugPrint(
          'إزالة منتج من متجر ${storesInfo[storeId]?.shopName}: ${removedItem.productName}',
        );

        storeCart.removeWhere((item) => item.productId == productId);
        storesCarts[storeId] = List.from(storeCart);
        storesCarts.refresh(); // إجبار تحديث RxMap

        // إذا أصبحت سلة المتجر فارغة، إزالة المتجر من القائمة النشطة
        if (storeCart.isEmpty) {
          storesCarts.remove(storeId);
          storesInfo.remove(storeId);

          // الانتقال لمتجر آخر إذا كان متاحاً
          if (storesCarts.isNotEmpty) {
            setActiveStore(storesCarts.keys.first);
          } else {
            activeStoreId.value = '';
            totalAmount.value = 0.0;
          }
        } else {
          _calculateActiveStoreTotal();
        }

        _saveCartsToStorage();
        update();
      }
    } catch (e) {
      debugPrint('خطأ في إزالة المنتج من السلة: $e');
    }
  }

  /// تحديث كمية منتج
  void updateQuantity(String productId, int newQuantity) {
    try {
      if (newQuantity <= 0) {
        removeFromCart(productId);
        return;
      }

      final storeId = activeStoreId.value;

      if (storeId.isEmpty || !storesCarts.containsKey(storeId)) {
        return;
      }

      final storeCart = storesCarts[storeId]!;
      final index = storeCart.indexWhere((item) => item.productId == productId);

      if (index >= 0) {
        final item = storeCart[index];
        final oldQuantity = item.quantity;
        
        // التحقق من الكمية المتوفرة من بيانات المنتج
        final int originalQuantity = (item.productData['quantity'] as int?) ?? 0;
        final int maxAvailableQuantity = originalQuantity;
        
        // التحقق من عدم تجاوز الكمية المتوفرة
        if (newQuantity > maxAvailableQuantity) {
          // إظهار إشعار تحذيري
          Get.snackbar(
            'تجاوز الكمية المتوفرة',
            'الكمية المتوفرة من ${item.productName} هي $maxAvailableQuantity قطعة فقط',
            backgroundColor: const Color(0xFFEF4444).withOpacity(0.1),
            colorText: const Color(0xFFEF4444),
            icon: Icon(Icons.warning_amber, color: const Color(0xFFEF4444)),
            duration: const Duration(seconds: 3),
            snackPosition: SnackPosition.TOP,
          );
          return; // عدم تحديث الكمية
        }

        storeCart[index].quantity = newQuantity;
        storesCarts[storeId] = List.from(storeCart);
        storesCarts.refresh(); // إجبار تحديث RxMap

        debugPrint(
          'تحديث الكمية في متجر ${storesInfo[storeId]?.shopName} - ${storeCart[index].productName}: $oldQuantity → $newQuantity',
        );

        _calculateActiveStoreTotal();
        _saveCartsToStorage();
        update(); // تحديث GetX
      }
    } catch (e) {
      debugPrint('خطأ في تحديث كمية المنتج: $e');
    }
  }

  /// مسح سلة متجر معين
  void clearStoreCart(String storeId) {
    storesCarts.remove(storeId);
    storesInfo.remove(storeId);

    if (activeStoreId.value == storeId) {
      if (storesCarts.isNotEmpty) {
        setActiveStore(storesCarts.keys.first);
      } else {
        activeStoreId.value = '';
        totalAmount.value = 0.0;
      }
    }

    _saveCartsToStorage();
    update();
  }

  /// مسح جميع السلال
  void clearAllCarts() {
    storesCarts.clear();
    storesInfo.clear();
    activeStoreId.value = '';
    totalAmount.value = 0.0;
    _saveCartsToStorage();
    update();
  }

  /// مسح السلة (للمتجر النشط فقط - للتوافق مع الكود الموجود)
  void clearCart() {
    if (activeStoreId.value.isNotEmpty) {
      clearStoreCart(activeStoreId.value);
    }
  }

  /// الحصول على كمية منتج معين في السلة
  int getProductQuantity(String productId) {
    try {
      final storeId = activeStoreId.value;
      if (storeId.isEmpty || !storesCarts.containsKey(storeId)) return 0;

      final item = storesCarts[storeId]!.firstWhereOrNull(
        (item) => item.productId == productId,
      );
      return item?.quantity ?? 0;
    } catch (e) {
      debugPrint('خطأ في الحصول على كمية المنتج: $e');
      return 0;
    }
  }

  /// حساب المجموع للمتجر النشط
  void _calculateActiveStoreTotal() {
    try {
      final storeId = activeStoreId.value;
      if (storeId.isEmpty || !storesCarts.containsKey(storeId)) {
        totalAmount.value = 0.0;
        return;
      }

      double total = 0.0;
      final storeCart = storesCarts[storeId]!;

      for (final item in storeCart) {
        final itemTotal = item.productPrice * item.quantity;
        total += itemTotal;
      }

      totalAmount.value = double.parse(total.toStringAsFixed(2));
      debugPrint(
        'المجموع الكلي للمتجر ${storesInfo[storeId]?.shopName}: ${totalAmount.value}',
      );
    } catch (e) {
      debugPrint('خطأ في حساب المجموع الكلي: $e');
      totalAmount.value = 0.0;
    }
  }

  /// حساب مجموع متجر معين
  double getStoreTotalAmount(String storeId) {
    try {
      if (!storesCarts.containsKey(storeId)) return 0.0;

      double total = 0.0;
      final storeCart = storesCarts[storeId]!;

      for (final item in storeCart) {
        total += item.productPrice * item.quantity;
      }

      return double.parse(total.toStringAsFixed(2));
    } catch (e) {
      debugPrint('خطأ في حساب مجموع المتجر: $e');
      return 0.0;
    }
  }

  /// الحصول على عدد منتجات متجر معين
  int getStoreItemCount(String storeId) {
    if (!storesCarts.containsKey(storeId)) return 0;
    return storesCarts[storeId]!.fold(0, (sum, item) => sum + item.quantity);
  }

  /// الحصول على أول صورة للمنتج - نسخة محسنة وآمنة
  String _getFirstImage(Map<String, dynamic> product) {
    try {
      // فحص أن product ليس null أو فارغ
      if (product.isEmpty) {
        debugPrint('⚠️ المنتج فارغ - إرجاع نص فارغ للصورة');
        return '';
      }

      // 1. فحص manyImages أولاً (الطريقة الرئيسية)
      try {
        final imagesData = product['manyImages'];
        if (imagesData != null && imagesData is List && imagesData.isNotEmpty) {
          final firstItem = imagesData.first;
          if (firstItem != null) {
            final imageUrl = firstItem.toString();
            if (imageUrl.isNotEmpty && imageUrl != 'null') {
              debugPrint('✅ تم العثور على صورة من manyImages: $imageUrl');
              return imageUrl;
            }
          }
        }
      } catch (e) {
        debugPrint('⚠️ خطأ في فحص manyImages: $e');
      }

      // 2. فحص url كصورة رئيسية
      try {
        final url = product['url']?.toString();
        if (url != null && url.isNotEmpty && url != 'null') {
          debugPrint('✅ تم العثور على صورة من url: $url');
          return url;
        }
      } catch (e) {
        debugPrint('⚠️ خطأ في فحص url: $e');
      }

      // 3. فحص imageUrl
      try {
        final imageUrl = product['imageUrl']?.toString();
        if (imageUrl != null && imageUrl.isNotEmpty && imageUrl != 'null') {
          debugPrint('✅ تم العثور على صورة من imageUrl: $imageUrl');
          return imageUrl;
        }
      } catch (e) {
        debugPrint('⚠️ خطأ في فحص imageUrl: $e');
      }

      // 4. فحص imagesUrls للتوافق مع الإصدارات القديمة
      try {
        final imagesUrlsData = product['imagesUrls'];
        if (imagesUrlsData != null &&
            imagesUrlsData is List &&
            imagesUrlsData.isNotEmpty) {
          final firstItem = imagesUrlsData.first;
          if (firstItem != null) {
            final imageUrlFromList = firstItem.toString();
            if (imageUrlFromList.isNotEmpty && imageUrlFromList != 'null') {
              debugPrint(
                '✅ تم العثور على صورة من imagesUrls: $imageUrlFromList',
              );
              return imageUrlFromList;
            }
          }
        }
      } catch (e) {
        debugPrint('⚠️ خطأ في فحص imagesUrls: $e');
      }

      // 5. آخر محاولة - productImage
      try {
        final productImage = product['productImage']?.toString();
        if (productImage != null &&
            productImage.isNotEmpty &&
            productImage != 'null') {
          debugPrint('✅ تم العثور على صورة من productImage: $productImage');
          return productImage;
        }
      } catch (e) {
        debugPrint('⚠️ خطأ في فحص productImage: $e');
      }

      // إذا لم يتم العثور على صورة، إرجاع نص فارغ
      debugPrint('⚠️ لم يتم العثور على أي صورة للمنتج');
      return '';
    } catch (e) {
      debugPrint('❌ خطأ عام في الحصول على صورة المنتج: $e');
      return '';
    }
  }

  /// تنظيف بيانات المنتج من Timestamp و GeoPoint objects - نسخة محسنة
  Map<String, dynamic> _sanitizeProductData(Map<String, dynamic> product) {
    final Map<String, dynamic> sanitized = <String, dynamic>{};

    try {
      product.forEach((key, value) {
        if (value is Timestamp) {
          // تحويل Timestamp إلى ISO string
          sanitized[key] = value.toDate().toIso8601String();
        } else if (value is GeoPoint) {
          // تحويل GeoPoint إلى Map قابل للتسلسل
          debugPrint('🗺️ تم العثور على GeoPoint في الحقل: $key');
          sanitized[key] = {
            'latitude': value.latitude,
            'longitude': value.longitude,
          };
        } else if (value.toString().contains('DocumentReference')) {
          // تحويل DocumentReference إلى path string
          debugPrint('📄 تم العثور على DocumentReference في الحقل: $key');
          sanitized[key] = value.toString();
        } else if (value.runtimeType.toString().startsWith('_')) {
          // تجاهل أي كائنات Firebase داخلية (تبدأ بـ _)
          debugPrint(
            '⚠️ تجاهل كائن Firebase داخلي في الحقل: $key (${value.runtimeType})',
          );
          sanitized[key] = value.toString();
        } else if (value is List) {
          // تنظيف القوائم - نسخة مبسطة
          sanitized[key] =
              value.map((item) {
                if (item is Timestamp) {
                  return item.toDate().toIso8601String();
                } else if (item is GeoPoint) {
                  debugPrint(
                    '🗺️ تم العثور على GeoPoint في القائمة للحقل: $key',
                  );
                  return {
                    'latitude': item.latitude,
                    'longitude': item.longitude,
                  };
                } else if (item.toString().contains('DocumentReference')) {
                  debugPrint(
                    '📄 تم العثور على DocumentReference في القائمة للحقل: $key',
                  );
                  return item.toString();
                } else if (item.runtimeType.toString().startsWith('_')) {
                  debugPrint(
                    '⚠️ تجاهل كائن Firebase داخلي في القائمة للحقل: $key (${item.runtimeType})',
                  );
                  return item.toString();
                } else if (item is Map<String, dynamic>) {
                  return _sanitizeProductData(item);
                }
                return item;
              }).toList();
        } else if (value is Map<String, dynamic>) {
          // تنظيف الخرائط المتداخلة
          sanitized[key] = _sanitizeProductData(value);
        } else {
          // نسخ القيم العادية مباشرة
          sanitized[key] = value;
        }
      });
    } catch (e) {
      debugPrint('❌ خطأ في تنظيف بيانات المنتج: $e');
      debugPrint('📦 البيانات الأصلية: ${product.keys.toList()}');

      // فحص إذا كان هناك أي GeoPoint في البيانات
      product.forEach((key, value) {
        if (value is GeoPoint) {
          debugPrint('🗺️ تم العثور على GeoPoint غير مُعالج في: $key');
        }
      });

      // في حالة الخطأ، إرجاع البيانات الأساسية فقط
      return {
        'id': product['id'] ?? '',
        'nameOfItem': product['nameOfItem'] ?? '',
        'priceOfItem': product['priceOfItem'] ?? 0,
      };
    }

    return sanitized;
  }

  /// عدد العناصر في السلة (للمتجر النشط)
  int get itemCount => cartItems.fold(0, (sum, item) => sum + item.quantity);

  /// التحقق من وجود منتج في السلة (للمتجر النشط)
  bool isInCart(String productId) {
    return cartItems.any((item) => item.productId == productId);
  }

  /// الحصول على كمية منتج معين (للمتجر النشط)
  int getQuantity(String productId) {
    try {
      // الحصول على الكمية من المتجر النشط
      final storeId = activeStoreId.value;

      if (storeId.isEmpty) {
        return 0;
      }

      if (!storesCarts.containsKey(storeId)) {
        return 0;
      }

      final storeCart = storesCarts[storeId]!;
      final item = storeCart.firstWhereOrNull(
        (item) => item.productId == productId,
      );
      final quantity = item?.quantity ?? 0;

      return quantity;
    } catch (e) {
      debugPrint('❌ خطأ في الحصول على كمية المنتج $productId: $e');
      return 0;
    }
  }

  /// إجمالي عدد المتاجر التي تحتوي على منتجات
  int get totalStoresCount => storesCarts.length;

  /// إجمالي عدد المنتجات في جميع المتاجر
  int get totalItemsCount => storesCarts.values.fold(
    0,
    (sum, storeCart) =>
        sum + storeCart.fold(0, (itemSum, item) => itemSum + item.quantity),
  );
  
  /// التحقق من الكمية المتوفرة لمنتج معين
  int getAvailableQuantity(String productId) {
    try {
      final storeId = activeStoreId.value;
      if (storeId.isEmpty || !storesCarts.containsKey(storeId)) return 0;

      final item = storesCarts[storeId]!.firstWhereOrNull(
        (item) => item.productId == productId,
      );
      
      if (item == null) return 0;
      
      final int originalQuantity = (item.productData['quantity'] as int?) ?? 0;
      final int currentCartQuantity = item.quantity;
      
      return originalQuantity - currentCartQuantity;
    } catch (e) {
      debugPrint('خطأ في الحصول على الكمية المتوفرة: $e');
      return 0;
    }
  }
  
  /// التحقق من إمكانية إضافة كمية معينة من المنتج
  bool canAddQuantity(String productId, int quantityToAdd) {
    try {
      final availableQuantity = getAvailableQuantity(productId);
      return availableQuantity >= quantityToAdd;
    } catch (e) {
      debugPrint('خطأ في التحقق من إمكانية إضافة الكمية: $e');
      return false;
    }
  }
}

/// نموذج عنصر السلة
class CartItem {
  final String productId;
  final String productName;
  final double productPrice;
  final String productImage;
  int quantity;
  final String storeId;
  final String storeName;
  final Map<String, dynamic> productData;

  CartItem({
    required this.productId,
    required this.productName,
    required this.productPrice,
    required this.productImage,
    required this.quantity,
    required this.storeId,
    required this.storeName,
    required this.productData,
  });

  Map<String, dynamic> toMap() {
    return {
      'productId': productId,
      'productName': productName,
      'productPrice': productPrice,
      'productImage': productImage,
      'quantity': quantity,
      'storeId': storeId,
      'storeName': storeName,
      'productData': productData,
    };
  }

  factory CartItem.fromMap(Map<String, dynamic> map) {
    return CartItem(
      productId: map['productId'] ?? '',
      productName: map['productName'] ?? '',
      productPrice: (map['productPrice'] ?? 0.0).toDouble(),
      productImage: map['productImage'] ?? '',
      quantity: map['quantity'] ?? 0,
      storeId: map['storeId'] ?? '',
      storeName: map['storeName'] ?? '',
      productData: Map<String, dynamic>.from(map['productData'] ?? {}),
    );
  }

  double get totalPrice => productPrice * quantity;
}
