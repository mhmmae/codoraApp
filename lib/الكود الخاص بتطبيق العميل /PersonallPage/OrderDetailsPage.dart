import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

// استيراداتك
// import '../../Model/model_order.dart'; // المسار القديم
// import '../../TheOrder/ViewOeder/GetX/GetGoTOMapDilyvery.dart';
// import '../../XXX/xxx_firebase.dart';
// import '../../googleMap/googleMap.dart';
import '../../Model/model_order.dart';
import '../../XXX/xxx_firebase.dart';
import '../TheOrder/ViewOeder/GetX/GetGoTOMapDilyvery.dart'; // افترض وجود هذا المسار
import '../googleMap/googleMap.dart'; // افترض وجود هذا المسار


// يمكنك إنشاء شاشة منفصلة لعرض تفاصيل الطلب
class OrderDetailsPage extends StatelessWidget {
  final OrderModel order;
  const OrderDetailsPage({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('تفاصيل الطلب رقم ${order.numberOfOrder}')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('حالة الطلب: تم التسليم بنجاح'),
              Text('إجمالي السعر: ${order.totalPriceOfOrder} ${FirebaseX.currency}'),
              // أضف المزيد من تفاصيل الطلب هنا
            ],
          ),
        ),
      ),
    );
  }
}


class UserOrderStream extends StatelessWidget {
  const UserOrderStream({super.key});

  @override
  Widget build(BuildContext context) {
    final double hi = MediaQuery.of(context).size.height;
    final double wi = MediaQuery.of(context).size.width;
    final User? currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      return const Center(child: Text("المستخدم غير مسجل الدخول لعرض الطلبات."));
    }

    final CollectionReference orders =
    FirebaseFirestore.instance.collection(FirebaseX.ordersCollection); // استخدام من FirebaseX

    // استخدام StreamBuilder لتحديثات حية لحالة الطلب
    return StreamBuilder<DocumentSnapshot>(
      stream: orders.doc(currentUser.uid).snapshots(),
      builder: (BuildContext context, AsyncSnapshot<DocumentSnapshot> snapshot) {
        if (snapshot.hasError) {
          return const Center(
            child: Text(
              "حدث خطأ أثناء جلب حالة الطلب. الرجاء المحاولة مرة أخرى.",
              textAlign: TextAlign.center,
            ),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator.adaptive());
        }

        if (!snapshot.hasData || !snapshot.data!.exists) {
          return const Center(
            child: Text("لا توجد طلبات حالياً."),
          );
        }

        try {
          final OrderModel order =
          OrderModel.fromMap(snapshot.data!.data() as Map<String, dynamic>);

          return Container(
            // تم تعديل الارتفاع ليكون أكثر ديناميكية بناءً على حالة الطلب والنصوص
            // height: order.delivery ? hi / 3.3 : hi / 4.3,
            padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
            width: wi,
            color: Colors.transparent, // يمكن إزالتها إذا لم يكن هناك لون مقصود
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start, // لمحاذاة العناصر للأعلى
              children: [
                Expanded(child: OrderStatusLeftSection(order: order, hi: hi, wi: wi)),
                const SizedBox(width: 8), // فاصل بين القسمين
                Expanded(child: OrderStatusRightSection(order: order, hi: hi, wi: wi)),
              ],
            ),
          );
        } catch (e) {
          debugPrint("Error parsing order data: $e");
          debugPrint("Snapshot data: ${snapshot.data?.data()}");
          return Center(
            child: Text(
              "حدث خطأ أثناء معالجة بيانات الطلب: $e",
              textAlign: TextAlign.center,
            ),
          );
        }
      },
    );
  }
}

class OrderStatusLeftSection extends StatelessWidget {
  final OrderModel order;
  final double hi;
  final double wi;

  const OrderStatusLeftSection({
    super.key,
    required this.order,
    required this.hi,
    required this.wi,
  });

  @override
  Widget build(BuildContext context) {
    Color borderColor = order.requestAccept ? Colors.green.shade600 : Colors.red.shade400;
    if (order.doneDelivery) borderColor = Colors.blue.shade600;
    if (order.delivery && !order.doneDelivery) borderColor = Colors.orange.shade600;


    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: borderColor, width: 1.5),
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.2),
              spreadRadius: 1,
              blurRadius: 3,
              offset: const Offset(0, 1),
            )
          ]
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min, // لجعل العمود يأخذ أقل مساحة ممكنة
        children: [
          Container(
            width: double.infinity, // لجعل الصورة تملأ العرض المتاح داخل Expanded
            height: hi / 7, // ارتفاع مناسب للصورة
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(6),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(5),
              child: CachedNetworkImage(
                imageUrl: ImageX.imageofColok, // يفترض أن تكون هذه صورة عامة لحالة التجهيز
                fit: BoxFit.cover,
                placeholder: (context, url) => const Center(child: CircularProgressIndicator.adaptive()),
                errorWidget: (context, url, error) => const Icon(Icons.image_not_supported, color: Colors.grey),
              ),
            ),
          ),
          const SizedBox(height: 8),
          _buildOrderProcessingText(context),
        ],
      ),
    );
  }

  Widget _buildOrderProcessingText(BuildContext context) {
    String text;
    Color textColor = Colors.black87;
    FontWeight fontWeight = FontWeight.normal;

    if (order.doneDelivery) {
      text = 'تمت عملية التسليم بنجاح';
      textColor = Colors.green.shade700;
      fontWeight = FontWeight.bold;
    } else if (order.delivery) {
      text = 'الطلب في طريقه إليك';
      textColor = Colors.orange.shade700;
      fontWeight = FontWeight.w600;
    } else if (order.requestAccept) {
      text = 'يتم الآن تجهيز طلبك';
      textColor = Colors.blue.shade700;
      fontWeight = FontWeight.w600;
    } else {
      text = 'بانتظار قبول الطلب...';
      textColor = Colors.red.shade700;
      fontWeight = FontWeight.w500;
    }

    return FittedBox( // يضمن أن النص يناسب المساحة المتاحة
      fit: BoxFit.scaleDown, // يصغر النص إذا كان كبيرًا جدًا
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4.0),
        child: Text(
          text,
          style: TextStyle(fontSize: wi / 28, color: textColor, fontWeight: fontWeight),
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }
}

class OrderStatusRightSection extends StatelessWidget {
  final OrderModel order;
  final double hi;
  final double wi;

  const OrderStatusRightSection({
    super.key,
    required this.order,
    required this.hi,
    required this.wi,
  });

  @override
  Widget build(BuildContext context) {
    final GetGoToMapDelivery mapLogic = Get.find<GetGoToMapDelivery>(); // طريقة أخرى للحصول على الـ Controller
    Color borderColor = order.requestAccept ? Colors.green.shade600 : Colors.red.shade400;
    if (order.doneDelivery) borderColor = Colors.blue.shade600;
    if (order.delivery && !order.doneDelivery) borderColor = Colors.orange.shade600;

    return GestureDetector(
      onTap: () async {
        try {
          if (order.doneDelivery) {
            // عرض تفاصيل الفاتورة/الطلب
            Get.to(() => OrderDetailsPage(order: order));
          } else if (order.delivery && !order.doneDelivery) {
            if (mapLogic.isLoading) return; // منع النقرات المتعددة
            mapLogic.isLoading = true; //  لإظهار مؤشر تحميل إذا لزم الأمر في ال Controller
            //  تأكد من أن loadMarkers يعمل كما هو متوقع
            // await mapLogic.loadMarkers(); // هذا يجب أن يتم استدعاؤه ربما مرة واحدة عند التهيئة أو عند الحاجة
            // سأفترض أن Markers موجودة في controller بالفعل
            mapLogic.isLoading = false;

            Get.to(() => GoogleMapView(
              isDelivery: false, //  لماذا false هنا؟ هل يجب أن تكون true أو تعتمد على شيء آخر؟
              longitude: order.longitude,
              latitude: order.latitude,
              markerDelivery: mapLogic.markerDelivery, // من GetX Controller
              markerUser: mapLogic.markerUser,        // من GetX Controller
            ));
          }
          // لا يوجد إجراء للنقرات الأخرى حاليًا
        } catch (e) {
          mapLogic.isLoading = false; // تأكد من إعادة تعيين حالة التحميل
          Get.snackbar(
            'خطأ',
            'حدث خطأ: $e',
            backgroundColor: Colors.redAccent,
            colorText: Colors.white,
            snackPosition: SnackPosition.BOTTOM,
          );
        }
      },
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: borderColor, width: 1.5),
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.2),
                spreadRadius: 1,
                blurRadius: 3,
                offset: const Offset(0, 1),
              )
            ]
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: double.infinity,
              height: hi / 7,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(6),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(5),
                child: CachedNetworkImage(
                  imageUrl: order.doneDelivery
                      ? ImageX.imageofDiliveryDone
                      : ImageX.imageofdilivery,
                  fit: BoxFit.cover,
                  placeholder: (context, url) =>
                  const Center(child: CircularProgressIndicator.adaptive()),
                  errorWidget: (context, url, error) =>
                  const Icon(Icons.local_shipping, color: Colors.grey),
                ),
              ),
            ),
            const SizedBox(height: 8),
            _buildDeliveryStatusText(context),
          ],
        ),
      ),
    );
  }

  Widget _buildDeliveryStatusText(BuildContext context) {
    String text;
    Color textColor = Colors.black87;
    FontWeight fontWeight = FontWeight.normal;

    if (order.doneDelivery) {
      text = 'عرض تفاصيل الطلب';
      textColor = Colors.blue.shade700;
      fontWeight = FontWeight.bold;
    } else if (order.delivery) {
      text = 'تتبع الطلب (اضغط لعرض الخريطة)';
      textColor = Colors.orange.shade700;
      fontWeight = FontWeight.w600;
    } else if (order.requestAccept) {
      text = 'طلبك قيد التجهيز حالياً';
      textColor = Colors.blueGrey.shade700;
      fontWeight = FontWeight.w500;
    } else {
      text = 'بانتظار الموافقة على الطلب';
      textColor = Colors.grey.shade600;
      fontWeight = FontWeight.w500;
    }
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4.0),
        child: Text(
          text,
          style: TextStyle(fontSize: wi / 28, color: textColor, fontWeight: fontWeight),
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }
}