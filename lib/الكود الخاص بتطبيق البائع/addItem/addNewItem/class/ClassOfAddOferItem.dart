import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../TextFormFiled.dart';
import '../../Chose-The-Type-Of-Itemxx.dart';
import '../../video/chooseVideo.dart';
import 'addManyImage.dart';

class ClassOfAddOfferItem extends StatelessWidget {

  final Getinformationofitem1 controller;

  const ClassOfAddOfferItem({
    super.key,
    required this.controller, // جعله مطلوباً

  });

  // final Uint8List uint8list1; // صورة المنتج
  // final String TypeItem; // نوع المنتج
  //
  // // المفتاح لتحديد حالة النموذج
  // final GlobalKey<FormState> globalKey = GlobalKey<FormState>();
  //
  // // المتحكمات الخاصة بالحقول
  // final TextEditingController nameOfItem = TextEditingController();
  // final TextEditingController priceOfItem = TextEditingController();
  // final TextEditingController descriptionOfItem = TextEditingController();
  // final TextEditingController rate = TextEditingController();
  // final TextEditingController oldPrice = TextEditingController();

  @override
  Widget build(BuildContext context) {
    double hi = MediaQuery.of(context).size.height; // ارتفاع الشاشة
    double wi = MediaQuery.of(context).size.width; // عرض الشاشة

    return Scaffold(
      body: ListView(
        shrinkWrap: true,
        children: [
          Form(
            key: controller.globalKey,
            child: Column(
              children: [
                SizedBox(height: hi / 10), // مساحة فارغة أعلى الشاشة

                // الحقول النصية
                _buildTextFormField(
                  controller: controller.nameOfItem,
                  label: 'اسم المنتج',
                  validator: (val) {
                    if (val == null || val.isEmpty) {
                      return 'اكتب اسم المنتج';
                    }
                    return null;
                  },
                  keyboardType: TextInputType.text,
                  height: hi / 15,
                ),
                SizedBox(height: hi / 40),
                _buildTextFormField(
                  controller: controller.descriptionOfItem,
                  label: 'وصف المنتج',
                  validator: (val) {
                    if (val == null || val.isEmpty) {
                      return 'اكتب وصف المنتج';
                    }
                    return null;
                  },
                  keyboardType: TextInputType.text,
                  height: hi / 15,
                ),
                SizedBox(height: hi / 40),
                _buildTextFormField(
                  controller: controller.oldPrice,
                  label: 'سعر المنتج القديم',
                  validator: (val) {
                    if (val == null || val.isEmpty) {
                      return 'اكتب سعر المنتج القديم';
                    }
                    return null;
                  },
                  keyboardType: TextInputType.number,
                  height: hi / 15,
                ),
                SizedBox(height: hi / 40),
                _buildTextFormField(
                  controller: controller.priceOfItem,
                  label: 'سعر المنتج الجديد',
                  validator: (val) {
                    if (val == null || val.isEmpty) {
                      return 'اكتب سعر المنتج الجديد';
                    }
                    return null;
                  },
                  keyboardType: TextInputType.number,
                  height: hi / 15,
                ),
                SizedBox(height: hi / 40),
                _buildTextFormField(
                  controller: controller.rate,
                  label: 'نسبة التخفيض',
                  validator: (val) {
                    if (val == null || val.isEmpty) {
                      return 'اكتب نسبة التخفيض';
                    }
                    return null;
                  },
                  keyboardType: TextInputType.number,
                  height: hi / 15,
                ),
                SizedBox(height: hi / 40),
                
                // حقل كمية المنتج
                _buildTextFormField(
                  controller: controller.productQuantity,
                  label: 'كمية المنتج',
                  validator: (val) {
                    if (val == null || val.isEmpty) {
                      return 'يجب إدخال كمية المنتج';
                    }
                    final quantity = int.tryParse(val);
                    if (quantity == null) return "أدخل كمية صحيحة (أرقام فقط)";
                    if (quantity <= 0) return "الكمية يجب أن تكون أكبر من صفر";
                    if (quantity > 100000) return "الكمية كبيرة جداً";
                    return null;
                  },
                  keyboardType: TextInputType.number,
                  height: hi / 15,
                ),
                SizedBox(height: hi / 40),
                
                // حقل كمية المنتج في الكارتونة - يظهر فقط للبائع الجملة
                Obx(() {
                  if (controller.sellerTypeAssociatedWithProduct.value == 'wholesale') {
                    return Column(
                      children: [
                        _buildTextFormField(
                          controller: controller.quantityPerCarton,
                          label: 'كمية المنتج في الكارتونة الواحدة',
                          validator: (val) {
                            if (val == null || val.isEmpty) {
                              return 'يجب إدخال كمية المنتج في الكارتونة';
                            }
                            final quantity = int.tryParse(val);
                            if (quantity == null) return "أدخل كمية صحيحة (أرقام فقط)";
                            if (quantity <= 0) return "الكمية يجب أن تكون أكبر من صفر";
                            if (quantity > 1000) return "الكمية في الكارتونة كبيرة جداً";
                            return null;
                          },
                          keyboardType: TextInputType.number,
                          height: hi / 15,
                        ),
                        SizedBox(height: hi / 40),
                        // إضافة نص توضيحي
                        Container(
                          margin: EdgeInsets.symmetric(horizontal: 16),
                          padding: EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.blue.shade200),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.info_outline, color: Colors.blue.shade600, size: 20),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  "هذه المعلومة ستساعد البائع المفرد في طلب كارتونة كاملة مباشرة",
                                  style: TextStyle(
                                    color: Colors.blue.shade700,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: hi / 40),
                      ],
                    );
                  } else {
                    return SizedBox.shrink(); // لا يظهر شيء للبائع المفرد
                  }
                                 }),
                 
                 // حقل السعر المقترح للبائع المفرد - يظهر فقط للبائع الجملة
                 Obx(() {
                   if (controller.sellerTypeAssociatedWithProduct.value == 'wholesale') {
                     return Column(
                       children: [
                         _buildTextFormField(
                           controller: controller.suggestedRetailPrice,
                           label: 'السعر المقترح للبائع المفرد',
                           validator: (val) {
                             if (val == null || val.isEmpty) {
                               return 'يجب إدخال السعر المقترح للبائع المفرد';
                             }
                             final suggestedPrice = double.tryParse(val);
                             if (suggestedPrice == null) return "أدخل سعراً صحيحاً (أرقام)";
                             if (suggestedPrice <= 0) return "السعر يجب أن يكون أكبر من صفر";
                             
                             // التحقق من أن السعر المقترح أكبر من سعر العرض
                             final offerPriceText = controller.priceOfItem.text;
                             if (offerPriceText.isNotEmpty) {
                               final offerPrice = double.tryParse(offerPriceText);
                               if (offerPrice != null && suggestedPrice <= offerPrice) {
                                 return "السعر المقترح للمفرد يجب أن يكون أكبر من سعر العرض (${offerPrice.toStringAsFixed(2)})";
                               }
                             }
                             
                             return null;
                           },
                           keyboardType: TextInputType.number,
                           height: hi / 15,
                         ),
                         SizedBox(height: hi / 40),
                         // إضافة نص توضيحي
                         Container(
                           margin: EdgeInsets.symmetric(horizontal: 16),
                           padding: EdgeInsets.all(12),
                           decoration: BoxDecoration(
                             color: Colors.amber.shade50,
                             borderRadius: BorderRadius.circular(8),
                             border: Border.all(color: Colors.amber.shade200),
                           ),
                           child: Row(
                             children: [
                               Icon(Icons.price_check, color: Colors.amber.shade700, size: 20),
                               SizedBox(width: 8),
                               Expanded(
                                 child: Text(
                                   "هذا السعر سيساعد البائع المفرد في تحديد سعر البيع المناسب مع ضمان هامش ربح مناسب",
                                   style: TextStyle(
                                     color: Colors.amber.shade800,
                                     fontSize: 12,
                                     fontWeight: FontWeight.w500,
                                   ),
                                 ),
                               ),
                             ],
                           ),
                         ),
                         SizedBox(height: hi / 40),
                       ],
                     );
                   } else {
                     return SizedBox.shrink(); // لا يظهر شيء للبائع المفرد
                   }
                 }),
                SizedBox(height: hi / 30),

                // اختيار الفيديو
                ChooseVideo(),
                SizedBox(height: hi / 30),

                // إضافة الصور
                AddManyImage(),
                SizedBox(height: hi / 30),

                // أزرار الإجراءات
                _buildActionButtons(context, controller,hi, wi), // الدالة المعزولة للأزرار
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// ويدجت مخصصة لإنشاء الحقول النصية
  Widget _buildTextFormField({
    required TextEditingController controller,
    required String label,
    required String? Function(String?) validator,
    required TextInputType keyboardType,
    required double height,
  }) {
    return TextFormFiled(
      controller: controller,
      borderRadius: 15,
      fontSize: 18,
      label: label,
      obscure: false,
      width: double.infinity,
      height: height,
      validator: validator,
      textInputType: keyboardType,
    );
  }

  // /// دالة لإنشاء أزرار الإجراءات
  // Widget _buildActionButtons(BuildContext context, double hi, double wi) {
  //   return Row(
  //     mainAxisAlignment: MainAxisAlignment.spaceBetween,
  //     children: [
  //       // زر العودة للخلف
  //       GestureDetector(
  //         onTap: () => Navigator.pop(context),
  //         child: Container(
  //           height: hi / 12,
  //           width: wi / 5,
  //           decoration: BoxDecoration(
  //             border: Border.all(color: Colors.red, width: 2),
  //             color: Colors.white70,
  //             borderRadius: BorderRadius.circular(10),
  //           ),
  //           child: const Icon(
  //             Icons.keyboard_backspace_sharp,
  //             size: 45,
  //             color: Colors.red,
  //           ),
  //         ),
  //       ),
  //
  //       // زر الإرسال والحفظ
  //       GetBuilder<Getinformationofitem>(init: Getinformationofitem(
  //         rate: rate,
  //         oldPrice: oldPrice,
  //
  //         uint8list: uint8list1,
  //         TypeItem: TypeItem,
  //         descriptionOfItem: descriptionOfItem,
  //         nameOfItem: nameOfItem,
  //         priceOfItem: priceOfItem,
  //         globalKey: globalKey,
  //
  //       ),builder: (logic){
  //         return         GetBuilder<GetChooseVideo>(
  //           init: GetChooseVideo(),
  //           builder: (logic1) {
  //             return GestureDetector(
  //               onTap: () async{
  //                 if(globalKey.currentState!.validate()){
  //                   logic.isSend.value = true;
  //
  //                   logic.update();
  //                   if(logic1.videoUrl !=null){
  //                     await GetAddManyImage.saveManyImage(GetAddManyImage.allBytes);
  //
  //                     await logic1.saveVideoToFirebase();
  //
  //
  //                     await  logic.saveData(logic1.uploadedVideoUrl!,context);
  //                     GetAddManyImage.allBytes.clear();
  //                     logic1.deleteVideo();
  //                   }else{
  //                     await GetAddManyImage.saveManyImage(GetAddManyImage.allBytes);
  //                     GetAddManyImage.allBytes.clear();
  //
  //                     logic.saveData('noVideo',context);
  //
  //                   }
  //                 }
  //
  //
  //               },
  //               child: logic.isSend.value == false  ? Container(
  //                 height: hi / 12,
  //                 width: wi / 5,
  //                 decoration: BoxDecoration(
  //                   color: Colors.white70,
  //                   border: Border.all(color: Colors.blueAccent, width: 2),
  //                   borderRadius: BorderRadius.circular(10),
  //                 ),
  //                 child: const Icon(
  //                   Icons.send,
  //                   size: 45,
  //                   color: Colors.blueAccent,
  //                 ),
  //               ):CircularProgressIndicator(),
  //             );
  //           },
  //         );
  //       })
  //
  //     ],
  //   );
  // }





  Widget _buildActionButtons(BuildContext context, Getinformationofitem1 controller, double hi, double wi) {
    // تأكد أن GetChooseVideo مُسجل قبل هذا! (هذا تعليق لك، لا يمكنني إضافة Get.find هنا مباشرة بدون التأكد من التسجيل)
    // final GetChooseVideo videoController = Get.find<GetChooseVideo>(); 

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 15.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // زر إلغاء / رجوع
          ElevatedButton.icon(
            icon: const Icon(Icons.cancel_outlined),
            label: const Text("إلغاء"),
            onPressed: () {
              // من الأفضل تجنب Get.delete<Getinformationofitem1>() هنا 
              // إذا كان الـ controller يُستخدم في أماكن أخرى أو إذا كان يتم تمريره من شاشة سابقة.
              // عادةً ما يتم حذف الـ controller عندما يتم إغلاق الشاشة التي أنشأته.
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.grey.shade200,
              foregroundColor: Colors.grey.shade800,
              minimumSize: Size(wi / 3, hi / 15),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),

          // زر الإرسال والحفظ - استخدام Obx
          Obx(() => ElevatedButton.icon( // <--- استخدام Obx هنا
                icon: controller.isSend.value
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.save_alt_rounded),
                label: Text(controller.isSend.value ? "جاري الحفظ..." : "حفظ العرض"),
                onPressed: controller.isSend.value ? null : () async {
                  if (controller.globalKey.currentState?.validate() ?? false) { // استخدام ؟. للحماية الإضافية
                    // لا حاجة لاستخدام videoController هنا إذا كانت saveData تتعامل مع كل شيء
                    await controller.saveData(context); 
                  } else {
                    debugPrint("Form validation failed in action button (Offer)");
                    Get.rawSnackbar(message: "يرجى ملء جميع الحقول المطلوبة بشكل صحيح.");
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                  minimumSize: Size(wi / 2.5, hi / 15),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  elevation: 3,
                ),
              )),
        ],
      ),
    );
  }



}
