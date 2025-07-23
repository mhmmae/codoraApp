// stream_list_of_item.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../XXX/xxx_firebase.dart';
import '../GetXController/GetAddAndRemove.dart';
import 'BosAddAndRemove.dart';

/// ودجة لعرض العناصر في السلة (البطاقة) باستخدام Stream من Firestore.
/// تقوم الودجة بالاستماع إلى تغييرات المستندات في مجموعة السلة لجلب بيانات كل منتج،
/// ثم تعرض تفاصيل المنتج مع أزرار لتعديل الكمية (زيادة/نقصان) وحذف المنتج.
class StreamListOfItem extends StatefulWidget {
  const StreamListOfItem({super.key});

  @override
  State<StreamListOfItem> createState() => _StreamListOfItemState();
}

class _StreamListOfItemState extends State<StreamListOfItem>
    with TickerProviderStateMixin {
  late AnimationController _listAnimationController;
  final List<AnimationController> _itemControllers = [];

  // Stream لجلب بيانات المنتجات الموجودة في السلة (the-chosen).
  final Stream<QuerySnapshot> cardItemStream =
      FirebaseFirestore.instance
          .collection('the-chosen')
          .doc(FirebaseAuth.instance.currentUser!.uid)
          .collection(FirebaseX.appName)
          .snapshots();

  @override
  void initState() {
    super.initState();
    _listAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _listAnimationController.forward();
  }

  @override
  void dispose() {
    _listAnimationController.dispose();
    for (var controller in _itemControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  /// دالة لاسترجاع بيانات المنتج من مجموعة "Item" باستخدام معرف المنتج.
  Future<DocumentSnapshot> fetchItem(String itemUid) {
    return FirebaseFirestore.instance
        .collection(FirebaseX.itemsCollection)
        .doc(itemUid)
        .get();
  }

  /// دالة لاسترجاع بيانات المنتج من مجموعة "Itemoffer" باستخدام معرف المنتج.
  Future<DocumentSnapshot> fetchItemOffer(String itemUid) {
    return FirebaseFirestore.instance
        .collection(FirebaseX.offersCollection)
        .doc(itemUid)
        .get();
  }

  /// دالة لحذف عنصر من السلة باستخدام معرف المستند.
  Future<void> deleteCartItem(String uidDoc) async {
    await FirebaseFirestore.instance
        .collection('the-chosen')
        .doc(FirebaseAuth.instance.currentUser!.uid)
        .collection(FirebaseX.appName)
        .doc(uidDoc)
        .delete();
  }

  @override
  Widget build(BuildContext context) {
    final double hi = MediaQuery.of(context).size.height;
    final double wi = MediaQuery.of(context).size.width;

    return StreamBuilder<QuerySnapshot>(
      stream: cardItemStream,
      builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
        // معالجة الخطأ أثناء جلب البيانات.
        if (snapshot.hasError) {
          return _buildErrorState();
        }
        // عرض حالة الانتظار أثناء التحميل.
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingState();
        }
        // التحقق من وجود مستندات.
        if (snapshot.data == null || snapshot.data!.docs.isEmpty) {
          return _buildEmptyState();
        }

        // تنظيف controllers القديمة وإنشاء جديدة
        for (var controller in _itemControllers) {
          controller.dispose();
        }
        _itemControllers.clear();

        // إنشاء controllers جديدة لكل عنصر
        for (int i = 0; i < snapshot.data!.docs.length; i++) {
          final controller = AnimationController(
            duration: Duration(milliseconds: 600 + (i * 100)),
            vsync: this,
          );
          _itemControllers.add(controller);
          // بدء الأنيميشن مع تأخير متدرج
          Future.delayed(Duration(milliseconds: i * 150), () {
            if (mounted) controller.forward();
          });
        }

        // بناء قائمة العناصر باستخدام بيانات المستندات مع أنيميشن
        return AnimatedBuilder(
          animation: _listAnimationController,
          builder: (context, child) {
            return ListView.separated(
              padding: const EdgeInsets.all(12),
              itemCount: snapshot.data!.docs.length,
              separatorBuilder:
                  (context, index) =>
                      SizedBox(height: 12 * _listAnimationController.value),
              itemBuilder: (context, index) {
                final document = snapshot.data!.docs[index];
                return _buildAnimatedCartItem(document, hi, wi, index);
              },
            );
          },
        );
      },
    );
  }

  /// بناء عنصر السلة مع أنيميشن
  Widget _buildAnimatedCartItem(
    DocumentSnapshot document,
    double hi,
    double wi,
    int index,
  ) {
    if (index >= _itemControllers.length) return const SizedBox();

    final controller = _itemControllers[index];

    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0.3, 0),
            end: Offset.zero,
          ).animate(
            CurvedAnimation(parent: controller, curve: Curves.easeOutBack),
          ),
          child: FadeTransition(
            opacity: CurvedAnimation(
              parent: controller,
              curve: Curves.easeInOut,
            ),
            child: Transform.scale(
              scale:
                  Tween<double>(begin: 0.8, end: 1.0)
                      .animate(
                        CurvedAnimation(
                          parent: controller,
                          curve: Curves.elasticOut,
                        ),
                      )
                      .value,
              child: _buildCartItem(document, hi, wi, index),
            ),
          ),
        );
      },
    );
  }

  /// بناء عنصر واحد في السلة بتصميم محسن
  Widget _buildCartItem(
    DocumentSnapshot document,
    double hi,
    double wi,
    int index,
  ) {
    // تحويل بيانات المستند إلى خريطة مع التحقق من null-safety.
    final dataMap = document.data() as Map<String, dynamic>?;
    if (dataMap == null) {
      return const SizedBox();
    }

    // استخراج الحقول الأساسية مع تحديد القيم الافتراضية.
    final bool isOffer = dataMap['isOfer'] as bool? ?? false;
    final String uidItem = dataMap['uidItem'] as String? ?? "";
    final String uidOfDoc = dataMap['uidOfDoc'] as String? ?? "";
    final int number = dataMap['number'] as int? ?? 0;
    final String uidAdd = dataMap['uidAdd'] as String? ?? "";

    // تحديد الدالة المناسبة لاسترجاع بيانات المنتج (عادية أو عرض).
    Future<DocumentSnapshot> productFuture =
        isOffer ? fetchItemOffer(uidItem) : fetchItem(uidItem);

    return FutureBuilder<DocumentSnapshot>(
      future: productFuture,
      builder: (
        BuildContext context,
        AsyncSnapshot<DocumentSnapshot> productSnapshot,
      ) {
        if (productSnapshot.hasError) {
          return _buildProductErrorCard();
        }
        if (productSnapshot.connectionState == ConnectionState.waiting) {
          return _buildProductLoadingCard(hi, wi);
        }
        if (!productSnapshot.hasData || !productSnapshot.data!.exists) {
          return _buildProductNotFoundCard();
        }

        // استخراج بيانات المنتج مع التحقق من null.
        final productData =
            productSnapshot.data!.data() as Map<String, dynamic>?;
        if (productData == null) return const SizedBox();

        final String imageUrl = productData['url'] as String? ?? "";
        final String nameOfItem = productData['nameOfItem'] as String? ?? "";
        // استخدام suggestedRetailPrice أولاً ثم priceOfItem كبديل
        final dynamic suggestedPriceDynamic =
            productData['suggestedRetailPrice'];
        final dynamic priceDynamic = productData['priceOfItem'];
        final String priceOfItemStr =
            suggestedPriceDynamic != null
                ? suggestedPriceDynamic.toString()
                : (priceDynamic != null ? priceDynamic.toString() : "");

        return _buildModernCartItem(
          imageUrl,
          nameOfItem,
          priceOfItemStr,
          number,
          uidItem,
          uidOfDoc,
          isOffer,
          hi,
          wi,
          uidAdd,
        );
      },
    );
  }

  /// بناء عنصر السلة بتصميم حديث مع أنيميشن تفاعلي
  Widget _buildModernCartItem(
    String imageUrl,
    String nameOfItem,
    String priceOfItemStr,
    int number,
    String uidItem,
    String uidOfDoc,
    bool isOffer,
    double hi,
    double wi,
    String uidAdd,
  ) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.white, Colors.grey[50]!.withOpacity(0.8)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            spreadRadius: 2,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: const Color(0xFF667EEA).withOpacity(0.1),
            blurRadius: 20,
            spreadRadius: -5,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            // تأثير تفاعلي عند الضغط
          },
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Row(
              children: [
                // صورة المنتج المحسنة مع أنيميشن
                _buildAnimatedProductImage(imageUrl, hi, wi, isOffer),
                // تفاصيل المنتج
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // اسم المنتج مع أنيميشن
                        AnimatedDefaultTextStyle(
                          duration: const Duration(milliseconds: 300),
                          style: TextStyle(
                            fontSize: wi / 26,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[800]!,
                          ),
                          child: Text(
                            nameOfItem,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(height: 4),
                        // السعر مع أنيميشن
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 400),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [
                                      Color(0xFF667EEA),
                                      Color(0xFF764BA2),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  priceOfItemStr,
                                  style: TextStyle(
                                    fontSize: wi / 32,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'IQ',
                                style: TextStyle(
                                  fontSize: wi / 36,
                                  color: Colors.green,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        // أزرار التحكم مع أنيميشن
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // أزرار الكمية
                            _buildAnimatedQuantityControls(
                              uidItem,
                              uidOfDoc,
                              isOffer,
                              number,
                              uidAdd,
                            ),
                            // زر الحذف
                            _buildAnimatedDeleteButton(uidOfDoc),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// بناء صورة المنتج المحسنة مع أنيميشن
  Widget _buildAnimatedProductImage(
    String imageUrl,
    double hi,
    double wi,
    bool isOffer,
  ) {
    return SizedBox(
      width: wi / 4,
      height: hi / 9,
      child: Stack(
        children: [
          Container(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                bottomLeft: Radius.circular(16),
              ),
              image: DecorationImage(
                fit: BoxFit.cover,
                image: NetworkImage(imageUrl),
              ),
            ),
          ),
          // شارة العرض إذا كان المنتج عرض
          if (isOffer)
            Positioned(
              top: 4,
              right: 4,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'عرض',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: wi / 40,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// بناء أزرار التحكم في الكمية مع أنيميشن
  Widget _buildAnimatedQuantityControls(
    String uidItem,
    String uidOfDoc,
    bool isOffer,
    int number,
    String uidAdd,
  ) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [Colors.grey[100]!, Colors.grey[50]!]),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AddAndRemove(
            uidItem: uidItem,
            uidOfDoc: uidOfDoc,
            isOfer: isOffer,
            number: number,
            uidAdd: uidAdd,
          ),
        ],
      ),
    );
  }

  /// بناء زر الحذف المحسن مع أنيميشن
  Widget _buildAnimatedDeleteButton(String uidOfDoc) {
    return GetBuilder<GetAddAndRemove>(
      builder: (logic) {
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: () async {
                try {
                  await deleteCartItem(uidOfDoc);
                  // إعادة حساب الأسعار بعد الحذف
                  await logic.refreshTotals();
                } catch (e) {
                  Get.snackbar(
                    'خطأ',
                    'حدث خطأ أثناء حذف المنتج: $e',
                    backgroundColor: Colors.red,
                    colorText: Colors.white,
                  );
                }
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.red.withOpacity(0.1),
                      Colors.red.withOpacity(0.05),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.red.withOpacity(0.2),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.delete_outline,
                  color: Colors.red,
                  size: 20,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  /// حالة الخطأ
  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          const Text(
            'حدث خطأ أثناء جلب البيانات',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: () {
              // إعادة تحميل البيانات
            },
            child: const Text('إعادة المحاولة'),
          ),
        ],
      ),
    );
  }

  /// حالة التحميل
  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('جار التحميل...'),
        ],
      ),
    );
  }

  /// حالة السلة الفارغة
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.shopping_cart_outlined,
              size: 64,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'سلة التسوق فارغة',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'ابدأ بإضافة منتجات لسلة التسوق',
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  /// كارد خطأ المنتج
  Widget _buildProductErrorCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red[200]!),
      ),
      child: const Text(
        "حدث خطأ أثناء جلب تفاصيل المنتج",
        style: TextStyle(color: Colors.red),
      ),
    );
  }

  /// كارد تحميل المنتج
  Widget _buildProductLoadingCard(double hi, double wi) {
    return Container(
      height: hi / 9,
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Center(child: CircularProgressIndicator()),
    );
  }

  /// كارد المنتج غير موجود
  Widget _buildProductNotFoundCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.orange[200]!),
      ),
      child: const Text(
        "المنتج غير موجود",
        style: TextStyle(color: Colors.orange),
      ),
    );
  }
}
