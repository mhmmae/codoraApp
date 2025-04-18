// import 'package:codora/XXX/XXXFirebase.dart';
// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
//
// import 'getAddManyImage.dart';
//
// class addManyImage extends StatelessWidget {
//    addManyImage({super.key});
//
//   @override
//   Widget build(BuildContext context) {
//     double hi = MediaQuery.of(context).size.height;
//     double wi = MediaQuery.of(context).size.width;
//     return GetBuilder<getAddManyImage>(init:getAddManyImage() ,builder: (val){
//       return val.isAddImage == false? GestureDetector(
//         onTap: ()async{
//
//         try {
//           await val.processImages();
//         } catch (e) {
//           print("حدث خطأ أثناء معالجة الصور: $e");
//           // أضف رسالة Toast أو Snackbar لتنبيه المستخدم
//           ScaffoldMessenger.of(context).showSnackBar(
//             SnackBar(content: Text("تعذر تحميل الصور! حاول مرة أخرى.")),
//           );
//         }
//       },
//         child: Container( height:val.isAddImage == true? hi / 9:hi/11,
//             width:val.isAddImage == true? wi / 1.2 : wi / 4,decoration:BoxDecoration(
//           image:DecorationImage(
//             fit: BoxFit.cover,
//             image:AssetImage(ImageX.ImageAddImage)
//           )
//         )),
//       ):Column(
//         children: [
//           GestureDetector(
//             onTap: (){
//               val.isAddImage = false;
//               getAddManyImage.allBytes.clear();
//               val.update();
//             },
//             child: Container(
//               alignment: Alignment.topLeft,
//               child: Icon(Icons.close),
//             ),
//           ),
//           SizedBox(width:wi,height:hi/5,
//           child:getAddManyImage.allBytes.isNotEmpty ? ListView.builder(
//             scrollDirection: Axis.horizontal,
//             itemCount: getAddManyImage.allBytes.length,
//             itemBuilder: (context,index){
//               return   Padding(
//                 padding: const EdgeInsets.all(8.0),
//                 child: Container(
//                   width: wi/4,height: hi/10,
//                     decoration:BoxDecoration(
//                       border:Border.all(color:Colors.black87),
//                         borderRadius:BorderRadius.circular(15),
//                         image:DecorationImage(
//                           fit: BoxFit.cover,
//                             image:MemoryImage(getAddManyImage.allBytes[index])
//                         )
//                     )
//                 ),
//               );
//             },
//
//
//
//           ) :Container()
//           ),
//         ],
//       );
//     },);
//   }
// }










import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../XXX/XXXFirebase.dart';
import 'getAddManyImage.dart';

class AddManyImage extends StatelessWidget {
  AddManyImage({super.key});

  @override
  Widget build(BuildContext context) {
    double hi = MediaQuery.of(context).size.height; // ارتفاع الشاشة
    double wi = MediaQuery.of(context).size.width; // عرض الشاشة

    return GetBuilder<GetAddManyImage>(
      init: GetAddManyImage(),
      builder: (controller) {
        // عرض شريط التقدم إذا كانت العملية جارية
        if (controller.isProcessing) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                CircularProgressIndicator(),
                SizedBox(height: 10),
                Text("جارٍ معالجة الصور، يرجى الانتظار..."),
              ],
            ),
          );
        }

        // حالة عدم إضافة الصور
        if (!controller.isAddImage) {
          return GestureDetector(
            onTap: () async {
              try {
                controller.startProcessing(); // تشغيل شريط التقدم
                await controller.processImages();
                controller.stopProcessing(); // إيقاف شريط التقدم بعد المعالجة
              } catch (e) {
                print("حدث خطأ أثناء معالجة الصور: $e");
                controller.stopProcessing();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("تعذر تحميل الصور! حاول مرة أخرى."),
                  ),
                );
              }
            },
            child: Container(
              height: hi / 11,
              width: wi / 4,
              decoration: BoxDecoration(
                image: DecorationImage(
                  fit: BoxFit.cover,
                  image: NetworkImage(ImageX.ImageAddImage), // صورة افتراضية للإضافة
                ),
              ),
            ),
          );
        }

        // حالة إضافة الصور
        return Column(
          children: [
            // زر إغلاق الصور
            GestureDetector(
              onTap: () {
                controller.isAddImage = false; // إعادة تعيين الحالة
                GetAddManyImage.allBytes.clear(); // حذف الصور المضافة
                controller.update(); // تحديث الحالة
              },
              child: const Align(
                alignment: Alignment.topLeft,
                child: Icon(Icons.close, color: Colors.red),
              ),
            ),
            // عرض الصور المضافة مع خيارات التحرير
            SizedBox(
              width: wi,
              height: hi / 5,
              child: GetAddManyImage.allBytes.isNotEmpty
                  ? ListView.builder(
                scrollDirection: Axis.horizontal, // التمرير الأفقي
                itemCount: GetAddManyImage.allBytes.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Stack(
                      children: [
                        Container(
                          width: wi / 4,
                          height: hi / 10,
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.black87),
                            borderRadius: BorderRadius.circular(15),
                            image: DecorationImage(
                              fit: BoxFit.cover,
                              image: MemoryImage(
                                GetAddManyImage.allBytes[index],
                              ), // عرض الصورة المخزنة
                            ),
                          ),
                        ),
                        // زر حذف الصورة
                        Positioned(
                          top: 5,
                          right: 5,
                          child: GestureDetector(
                            onTap: () {
                              GetAddManyImage.allBytes.removeAt(index); // حذف الصورة
                              controller.update();
                            },
                            child: const Icon(
                              Icons.delete,
                              color: Colors.red,
                              size: 20,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              )
                  : const Center(
                child: Text("لا توجد صور مضافة"),
              ),
            ),
          ],
        );
      },
    );
  }
}

