// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_storage/firebase_storage.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:get/get.dart';
//
// import '../../../HomePage/class/Chose-The-Type-Of-ItemxxXX.dart';
// import '../../../XXX/XXXFirebase.dart';
// import '../../../video/Getx/GetChooseVideo.dart';
// import '../../../video/chooseVideo.dart';
// import '../../../widget/TextFormFiled.dart';
// import 'addManyImage.dart';
// import 'getAddManyImage.dart';
//
// class Classofaddoferitem extends StatelessWidget {
//   Classofaddoferitem(
//       {super.key, required this.TypeItem, required this.uint8list1});
//
//   Uint8List uint8list1;
//   String TypeItem;
//
//   // ===========================================
//   GlobalKey<FormState> globalKey = GlobalKey<FormState>();
//
//   TextEditingController nameOfItem = TextEditingController();
//   TextEditingController priceOfItem = TextEditingController();
//   TextEditingController descriptionOfItem = TextEditingController();
//   TextEditingController rate = TextEditingController();
//   TextEditingController oldPrice = TextEditingController();
//   FirebaseFirestore firestore = FirebaseFirestore.instance;
//   FirebaseStorage firebaseStorage = FirebaseStorage.instance;
//
//   // ---------------------------------
//   String TheChosen = '';
//   String? arbicTheChosen = '';
//   bool DropdownButton12 = false;
//
//   @override
//   Widget build(BuildContext context) {
//     double hi = MediaQuery.of(context).size.height;
//     double wi = MediaQuery.of(context).size.width;
//     return Scaffold(
//       body: ListView(
//         shrinkWrap: true,
//
//         children: [
//           Form(
//             key: globalKey,
//             child: Column(
//               children: [
//                 SizedBox(
//                   height: hi / 10,
//                 ),
//                 TextFormFiled2(
//                   controller: nameOfItem,
//                   borderRadius: 15,
//                   fontSize: wi / 22,
//                   label: 'اسم المنتج',
//                   obscure: false,
//                   width: double.infinity,
//                   height: hi / 15,
//                   validator: (val) {
//                     if (val == null) {
//                       return ' اكتب اسم المنتج';
//                     }
//                     return null;
//                   },
//                 ),
//                 SizedBox(
//                   height: hi / 40,
//                 ),
//                 TextFormFiled2(
//                   controller: descriptionOfItem,
//                   borderRadius: 15,
//                   fontSize: wi / 22,
//                   label: 'وصف للمنتج',
//                   obscure: false,
//                   width: wi,
//                   height: hi / 15,
//                   validator: (val) {
//                     if (val == null) {
//                       return 'اكتب وصف للمنتج';
//                     }
//                     return null;
//                   },
//                 ),
//                 SizedBox(
//                   height: hi / 40,
//                 ),
//                 TextFormFiled2(
//                   controller: oldPrice,
//                   textInputType: TextInputType.number,
//                   borderRadius: 15,
//                   fontSize: wi / 22,
//                   label: 'سعر المنتج القديم',
//                   obscure: false,
//                   width: wi,
//                   height: hi / 15,
//                   validator: (val) {
//                     if (val == null) {
//                       return 'اكتب سعر المنتج';
//                     }
//                     return null;
//                   },
//                 ),
//                 SizedBox(
//                   height: hi / 40,
//                 ),
//                 TextFormFiled2(
//                   controller: priceOfItem,
//                   borderRadius: 15,
//                   fontSize: wi / 22,
//                   textInputType: TextInputType.number,
//                   label: 'سعر المنتج الجديد',
//                   obscure: false,
//                   width: wi,
//                   height: hi / 15,
//                   validator: (val) {
//                     if (val == null) {
//                       return 'اكتب سعر للمنتج';
//                     }
//                     return null;
//                   },
//                 ),
//                 SizedBox(
//                   height: hi / 40,
//                 ),
//                 TextFormFiled2(
//                   controller: rate,
//                   borderRadius: 15,
//                   fontSize: wi / 22,
//                   textInputType: TextInputType.number,
//                   label: 'نسبة التخفيض  ',
//                   obscure: false,
//                   width: wi,
//                   height: hi / 15,
//                   validator: (val) {
//                     if (val == null) {
//                       return 'اكتب نسبة التخفيض ';
//                     }
//                     return null;
//                   },
//                 ),
//                 SizedBox(
//                   height: hi / 30,
//                 ),
//
//                 ChooseVideo(),
//                 SizedBox(
//                   height: hi / 30,
//                 ),
//                 addManyImage(),
//
//                 SizedBox(
//                   height: hi / 30,
//                 ),
//                 Padding(
//                   padding: const EdgeInsets.symmetric(horizontal: 10),
//                   child: Row(
//                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                     children: [
//                       GestureDetector(
//                           onTap: () {
//                             // saveData();
//                           },
//                           child: Container(
//                               height: hi / 12,
//                               width: wi / 5,
//                               decoration: BoxDecoration(
//                                   border: Border.all(color: Colors.red, width: 2),
//                                   color: Colors.white70,
//                                   borderRadius: BorderRadius.circular(10)),
//                               child: Icon(
//                                 Icons.keyboard_backspace_sharp,
//                                 size: 45,
//                                 color: Colors.red,
//                               ))),
//                       GetBuilder<GetChooseVideo>(init: GetChooseVideo(),builder: (logic1) {
//                         return  GetBuilder<Getinformationofitem>(
//                           init: Getinformationofitem(
//
//
//
//                             rate: rate,
//                               oldPrice: oldPrice,
//
//                               uint8list: uint8list1,
//                               TypeItem: TypeItem,
//                               descriptionOfItem: descriptionOfItem,
//                               nameOfItem: nameOfItem,
//                               priceOfItem: priceOfItem,
//                               globalKey: globalKey,

//
//
//
//
//
//
//                           ), builder: (logic) {
//
//                           return GestureDetector(
//                             onTap: () async{
//                               if(globalKey.currentState!.validate()){
//                                 Getinformationofitem.isSend = true;
//
//                                 logic.update();
//                                 if(logic1.videoUrl !=null){
//                                   await getAddManyImage.saveManyImage(getAddManyImage.allBytes);
//
//                                   await logic1.saveVideoToFirebase();
//
//
//                                   await  logic.saveData(logic1.uploadedVideoUrl!,context);
//                                   getAddManyImage.allBytes.clear();
//                                   logic1.deleteVideo();
//                                 }else{
//                                   await getAddManyImage.saveManyImage(getAddManyImage.allBytes);
//                                   getAddManyImage.allBytes.clear();
//
//                                   logic.saveData('noVideo',context);
//
//                                 }
//                               }
//
//
//                             },
//                             child: Getinformationofitem.isSend == false  ? Container(
//                                 height: hi / 12,
//                                 width: wi / 5,
//                                 decoration: BoxDecoration(
//                                     color: Colors.white70,
//                                     border: Border.all(
//                                         color: Colors.blueAccent, width: 2),
//                                     borderRadius: BorderRadius.circular(10)),
//                                 child: Icon(
//                                   Icons.send,
//                                   size: 45,
//                                   color: Colors.blueAccent,
//                                 )):CircularProgressIndicator(),
//                           );
//                         });
//                       })
//                     ],
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }















import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../HomePage/class/Chose-The-Type-Of-ItemxxXX.dart';
import '../../../video/Getx/GetChooseVideo.dart';
import '../../../video/chooseVideo.dart';
import '../../../widget/TextFormFiled.dart';
import 'addManyImage.dart';
import 'getAddManyImage.dart';

class ClassOfAddOfferItem extends StatelessWidget {
  ClassOfAddOfferItem({
    super.key,
    required this.TypeItem,
    required this.uint8list1,
  });

  final Uint8List uint8list1; // صورة المنتج
  final String TypeItem; // نوع المنتج

  // المفتاح لتحديد حالة النموذج
  final GlobalKey<FormState> globalKey = GlobalKey<FormState>();

  // المتحكمات الخاصة بالحقول
  final TextEditingController nameOfItem = TextEditingController();
  final TextEditingController priceOfItem = TextEditingController();
  final TextEditingController descriptionOfItem = TextEditingController();
  final TextEditingController rate = TextEditingController();
  final TextEditingController oldPrice = TextEditingController();

  @override
  Widget build(BuildContext context) {
    double hi = MediaQuery.of(context).size.height; // ارتفاع الشاشة
    double wi = MediaQuery.of(context).size.width; // عرض الشاشة

    return Scaffold(
      body: ListView(
        shrinkWrap: true,
        children: [
          Form(
            key: globalKey,
            child: Column(
              children: [
                SizedBox(height: hi / 10), // مساحة فارغة أعلى الشاشة

                // الحقول النصية
                _buildTextFormField(
                  controller: nameOfItem,
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
                  controller: descriptionOfItem,
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
                  controller: oldPrice,
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
                  controller: priceOfItem,
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
                  controller: rate,
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
                SizedBox(height: hi / 30),

                // اختيار الفيديو
                ChooseVideo(),
                SizedBox(height: hi / 30),

                // إضافة الصور
                AddManyImage(),
                SizedBox(height: hi / 30),

                // أزرار الإجراءات
                _buildActionButtons(context, hi, wi), // الدالة المعزولة للأزرار
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
    return TextFormFiled2(
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

  /// دالة لإنشاء أزرار الإجراءات
  Widget _buildActionButtons(BuildContext context, double hi, double wi) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // زر العودة للخلف
        GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            height: hi / 12,
            width: wi / 5,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.red, width: 2),
              color: Colors.white70,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.keyboard_backspace_sharp,
              size: 45,
              color: Colors.red,
            ),
          ),
        ),

        // زر الإرسال والحفظ
        GetBuilder<Getinformationofitem>(init: Getinformationofitem(
          rate: rate,
          oldPrice: oldPrice,

          uint8list: uint8list1,
          TypeItem: TypeItem,
          descriptionOfItem: descriptionOfItem,
          nameOfItem: nameOfItem,
          priceOfItem: priceOfItem,
          globalKey: globalKey,

        ),builder: (logic){
          return         GetBuilder<GetChooseVideo>(
            init: GetChooseVideo(),
            builder: (logic1) {
              return GestureDetector(
                onTap: () async{
                  if(globalKey.currentState!.validate()){
                    Getinformationofitem.isSend = true;

                    logic.update();
                    if(logic1.videoUrl !=null){
                      await GetAddManyImage.saveManyImage(GetAddManyImage.allBytes);

                      await logic1.saveVideoToFirebase();


                      await  logic.saveData(logic1.uploadedVideoUrl!,context);
                      GetAddManyImage.allBytes.clear();
                      logic1.deleteVideo();
                    }else{
                      await GetAddManyImage.saveManyImage(GetAddManyImage.allBytes);
                      GetAddManyImage.allBytes.clear();

                      logic.saveData('noVideo',context);

                    }
                  }


                },
                child: Getinformationofitem.isSend == false  ? Container(
                  height: hi / 12,
                  width: wi / 5,
                  decoration: BoxDecoration(
                    color: Colors.white70,
                    border: Border.all(color: Colors.blueAccent, width: 2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.send,
                    size: 45,
                    color: Colors.blueAccent,
                  ),
                ):CircularProgressIndicator(),
              );
            },
          );
        })

      ],
    );
  }
}
