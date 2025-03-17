

import 'dart:typed_data';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
// import 'package:flutter_image_compress/flutter_image_compress.dart';
// import 'package:image_picker/image_picker.dart';

import '../bottonBar/botonBar.dart';
import 'addNewItem/addNewItem.dart';

class addItem extends StatefulWidget {
  const addItem({super.key});

  @override
  State<addItem> createState() => _addItemState();
}

class _addItemState extends State<addItem> {

  takeImage(ImageSource source) async {
    final ImagePicker imagePicker = ImagePicker();

    final XFile? imagex =await imagePicker.pickImage(source:source ,);

     if(imagex != null){
      return imagex.readAsBytes();
     }


  }

  Uint8List? images2;

  void take() async {
    Uint8List img = await takeImage(ImageSource.camera);
    setState(() {
      images2 = img;

    });


  }

  void takeCamera(String type2) async {
    Uint8List img = await takeImage(ImageSource.camera);
    if(img != null){
      // Uint8List result = await FlutterImageCompress.compressWithList(
      //   img,
      //   minHeight: 1024,
      //   minWidth: 720,
      //   quality: 10,
      //   rotate: 0,
      // );
      Navigator.push(context, MaterialPageRoute(builder: (context)=>viewImage(uint8list: img,TypeItem: type2 ,)));
    }


  }

  void takeGallery(String type2) async {
    Uint8List img = await takeImage(
      ImageSource.gallery
    );

    if (img != null) {
      // Uint8List result = await FlutterImageCompress.compressWithList(
      //   img,
      //   minHeight: 1024,
      //   minWidth: 720,
      //   quality: 50,
      //   rotate: 0,
      // );


      Navigator.push(context, MaterialPageRoute(builder: (context) =>
          viewImage(uint8list: img, TypeItem: type2,)));
    }
  }


  Future<void> save11() async {
    Reference storage = FirebaseStorage.instance.ref().child(
        'StoreImage${DateTime.now()}');
    UploadTask uploadTask = storage.putData(images2!);
    TaskSnapshot snapshot = await uploadTask;
    String imgUrl = await snapshot.ref.getDownloadURL();
    print(imgUrl);
  }

  Future<void> removeImage1() async {
    // final ImagePicker imagePicker = ImagePicker();

    // final XFile? imagex2 =await imagePicker.pickImage(source:ImageSource.gallery );
    //
    //
    // if(imagex2 != null){
    //   setState(() {
    //
    //   });


  // }


}



  @override
  Widget build(BuildContext context) {
    double hi = MediaQuery.of(context).size.height;
    double wi = MediaQuery.of(context).size.width;

    return   Scaffold(
      backgroundColor: Colors.white,
      extendBodyBehindAppBar:true,
      appBar: AppBar(
        leading: GestureDetector(onTap: (){ Navigator.push(context, MaterialPageRoute(builder: (context)=>bottonBar(theIndex: 2,)));},child: Container(
          child: const Icon(Icons.backspace),
        ),),
      ),
      body: Column(
        children: [
          SizedBox(height: hi/7,),
          Padding(
            padding:  EdgeInsets.symmetric(horizontal: wi/20),
            child: Column(
              children: [
                ElevatedButton(
                  style: ElevatedButton.styleFrom(

                  backgroundColor: Colors.white12

                  ),
                  onPressed: (){
                    showModalBottomSheet<ImageSource>(context: context, builder: (BuildContext context)
                    {
                    return  Container(
                      height: hi/4,
                      child: Column(
                          children: [
                            ListTile(
                              leading: Icon(Icons.camera),
                              title: Text('كامرة'),
                              onTap: ()=>takeCamera('Item')
                            ),
                             Divider(),
                            ListTile(
                                leading: Icon(Icons.photo),
                                title: Text('المحفوظة'),
                                onTap: ()=>takeGallery('Item')
                            )
                          ],

                      ),
                    );
                  });
                    },
                  child: Row(
                    children: [
                      Icon(Icons.add),
                      Text('اضافة منتج')
                    ],
                  )
                ),

                ElevatedButton(
                    style: ElevatedButton.styleFrom(

                        backgroundColor: Colors.white12

                    ),
                    onPressed: (){showModalBottomSheet(context: context, builder: (BuildContext context){
                      return SizedBox(
                        height: hi/4,
                        child: Column(
                          children: [
                            ListTile(
                                leading: Icon(Icons.camera),
                                title: Text('كامرة'),
                                onTap: (){}
                                    // takeCamera('Itemoffer')
                            ),
                            Divider(),
                            ListTile(
                                leading: Icon(Icons.photo),
                                title: Text('المحفوظة'),
                                onTap: (){
                                  takeGallery('Itemoffer');

                                }
                            )
                          ],

                        ),
                      );
                    });},
                    child: Row(
                      children: [
                        Icon(Icons.add),
                        Text('اضافة منتج عليه عرض')
                      ],
                    )
                ),
              ],
            ),
          )

      ],
    )
    );
  }
}
