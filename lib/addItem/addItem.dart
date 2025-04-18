
//
// import 'dart:typed_data';
//
// import 'package:firebase_storage/firebase_storage.dart';
// import 'package:flutter/material.dart';
// import 'package:image_picker/image_picker.dart';
// // import 'package:flutter_image_compress/flutter_image_compress.dart';
// // import 'package:image_picker/image_picker.dart';
//
// import '../bottonBar/botonBar.dart';
// import 'addNewItem/addNewItem.dart';
//
// class addItem extends StatefulWidget {
//   const addItem({super.key});
//
//   @override
//   State<addItem> createState() => _addItemState();
// }
//
// class _addItemState extends State<addItem> {
//
//   takeImage(ImageSource source) async {
//     final ImagePicker imagePicker = ImagePicker();
//
//     final XFile? imagex =await imagePicker.pickImage(source:source ,);
//
//      if(imagex != null){
//       return imagex.readAsBytes();
//      }
//
//
//   }
//
//   Uint8List? images2;
//
//   void take() async {
//     Uint8List img = await takeImage(ImageSource.camera);
//     setState(() {
//       images2 = img;
//
//     });
//
//
//   }
//
//   void takeCamera(String type2) async {
//     Uint8List img = await takeImage(ImageSource.camera);
//     if(img != null){
//       // Uint8List result = await FlutterImageCompress.compressWithList(
//       //   img,
//       //   minHeight: 1024,
//       //   minWidth: 720,
//       //   quality: 10,
//       //   rotate: 0,
//       // );
//       Navigator.push(context, MaterialPageRoute(builder: (context)=>viewImage(uint8list: img,TypeItem: type2 ,)));
//     }
//
//
//   }
//
//   void takeGallery(String type2) async {
//     Uint8List img = await takeImage(
//       ImageSource.gallery
//     );
//
//     if (img != null) {
//       // Uint8List result = await FlutterImageCompress.compressWithList(
//       //   img,
//       //   minHeight: 1024,
//       //   minWidth: 720,
//       //   quality: 50,
//       //   rotate: 0,
//       // );
//
//
//       Navigator.push(context, MaterialPageRoute(builder: (context) =>
//           viewImage(uint8list: img, TypeItem: type2,)));
//     }
//   }
//
//
//
//
//
//
//
//
//   @override
//   Widget build(BuildContext context) {
//     double hi = MediaQuery.of(context).size.height;
//     double wi = MediaQuery.of(context).size.width;
//
//     return   Scaffold(
//       backgroundColor: Colors.white,
//       extendBodyBehindAppBar:true,
//       appBar: AppBar(
//         leading: GestureDetector(onTap: (){ Navigator.push(context, MaterialPageRoute(builder: (context)=>BottomBar(theIndex: 2,)));},child: Container(
//           child: const Icon(Icons.backspace),
//         ),),
//       ),
//       body: Column(
//         children: [
//           SizedBox(height: hi/7,),
//           Padding(
//             padding:  EdgeInsets.symmetric(horizontal: wi/20),
//             child: Column(
//               children: [
//                 ElevatedButton(
//                   style: ElevatedButton.styleFrom(
//
//                   backgroundColor: Colors.white12
//
//                   ),
//                   onPressed: (){
//                     showModalBottomSheet<ImageSource>(context: context, builder: (BuildContext context)
//                     {
//                     return  Container(
//                       height: hi/4,
//                       child: Column(
//                           children: [
//                             ListTile(
//                               leading: Icon(Icons.camera),
//                               title: Text('كامرة'),
//                               onTap: ()=>takeCamera('Item')
//                             ),
//                              Divider(),
//                             ListTile(
//                                 leading: Icon(Icons.photo),
//                                 title: Text('المحفوظة'),
//                                 onTap: ()=>takeGallery('Item')
//                             )
//                           ],
//
//                       ),
//                     );
//                   });
//                     },
//                   child: Row(
//                     children: [
//                       Icon(Icons.add),
//                       Text('اضافة منتج')
//                     ],
//                   )
//                 ),
//
//                 ElevatedButton(
//                     style: ElevatedButton.styleFrom(
//
//                         backgroundColor: Colors.white12
//
//                     ),
//                     onPressed: (){showModalBottomSheet(context: context, builder: (BuildContext context){
//                       return SizedBox(
//                         height: hi/4,
//                         child: Column(
//                           children: [
//                             ListTile(
//                                 leading: Icon(Icons.camera),
//                                 title: Text('كامرة'),
//                                 onTap: ()=> takeCamera('Itemoffer')
//                             ),
//                             Divider(),
//                             ListTile(
//                                 leading: Icon(Icons.photo),
//                                 title: Text('المحفوظة'),
//                                 onTap: (){
//                                   takeGallery('Itemoffer');
//
//                                 }
//                             )
//                           ],
//
//                         ),
//                       );
//                     });},
//                     child: Row(
//                       children: [
//                         Icon(Icons.add),
//                         Text('اضافة منتج عليه عرض')
//                       ],
//                     )
//                 ),
//               ],
//             ),
//           )
//
//       ],
//     )
//     );
//   }
// }
























import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

import 'addNewItem/addNewItem.dart';

class ImageController extends GetxController {
  Rx<Uint8List?> selectedImage = Rx<Uint8List?>(null); // الصورة القابلة للمراقبة
  RxBool isAnimating = false.obs; // للتحكم بالانميشن
  void handleImage(ImageSource source, String type) async {
    final ImagePicker imagePicker = ImagePicker();
    final XFile? imageX = await imagePicker.pickImage(source: source);

    if (imageX != null) {
      selectedImage.value = await imageX.readAsBytes(); // تعيين الصورة المختارة
      isAnimating.value = true; // تفعيل الانميشن

      // الانتقال إلى الصفحة الجديدة مع الصورة
      Get.to(() => ViewImage(uint8list: selectedImage.value!, TypeItem: type,));
    } else {
      Get.snackbar(
        "خطأ",
        "لم يتم اختيار صورة!",
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }



  void resetSelection() {
    selectedImage.value = null; // إعادة تعيين الصورة
    isAnimating.value = false; // إيقاف الانميشن
  }
}





class AddItem extends StatelessWidget {
  const AddItem({super.key});

  @override
  Widget build(BuildContext context) {
    final ImageController controller = Get.put(ImageController());
    final double hi = MediaQuery.of(context).size.height;
    final double wi = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: AppBar(
        leading: GestureDetector(
          onTap: () => resetImageOnBack(context),
          child: const Icon(Icons.arrow_back),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: hi / 7),
          Flexible(
            child: Column(
              children: [
                ElevatedButton(
                  onPressed: () => _showImagePickerSheet(controller, "Item", hi),
                  child: const Text("إضافة منتج"),
                ),
                ElevatedButton(
                  onPressed: () => _showImagePickerSheet(controller, "ItemOffer", hi),
                  child: const Text("إضافة منتج عليه عرض"),
                ),


              ],
            ),
          ),
        ],
      ),
    );
  }

  void resetImageOnBack(BuildContext context) {
    Navigator.pop(context);
    Get.find<ImageController>().resetSelection();
  }

  void _showImagePickerSheet(ImageController controller, String type, double hi) {
    showModalBottomSheet(
      context: Get.context!,
      builder: (context) {
        return Container(
          height: hi / 4,
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.camera),
                title: const Text("كاميرا"),
                onTap: () {
                  Navigator.pop(context);
                  controller.handleImage(ImageSource.camera, type);
                },
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.photo),
                title: const Text("المحفوظة"),
                onTap: () {
                  Navigator.pop(context);
                  controller.handleImage(ImageSource.gallery, type);
                },
              ),
            ],
          ),
        );
      },
    );
  }






}


