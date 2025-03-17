import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../../XXX/XXXFirebase.dart';
import '../../../video/Getx/GetChooseVideo.dart';
import '../../../video/chooseVideo.dart';
import '../../../widget/TextFormFiled.dart';
import 'addManyImage.dart';
import 'getAddManyImage.dart';

class Classofaddoferitem extends StatelessWidget {
  Classofaddoferitem(
      {super.key, required this.TypeItem, required this.uint8list1});

  Uint8List uint8list1;
  String TypeItem;

  // ===========================================
  GlobalKey<FormState> globalKey = GlobalKey<FormState>();

  TextEditingController nameOfItem = TextEditingController();
  TextEditingController priceOfItem = TextEditingController();
  TextEditingController descriptionOfItem = TextEditingController();
  TextEditingController rate = TextEditingController();
  TextEditingController oldPrice = TextEditingController();
  FirebaseFirestore firestore = FirebaseFirestore.instance;
  FirebaseStorage firebaseStorage = FirebaseStorage.instance;

  // ---------------------------------
  String TheChosen = '';
  String? arbicTheChosen = '';
  bool DropdownButton12 = false;

  @override
  Widget build(BuildContext context) {
    double hi = MediaQuery.of(context).size.height;
    double wi = MediaQuery.of(context).size.width;
    return ListView(
      children: [
        Form(
          key: globalKey,
          child: Column(
            children: [
              SizedBox(
                height: hi / 10,
              ),
              TextFormFiled2(
                controller: nameOfItem,
                borderRadius: 15,
                fontSize: wi / 22,
                label: 'اسم المنتج',
                obscure: false,
                wight: double.infinity,
                height: hi / 15,
                validator: (val) {
                  if (val == null) {
                    return ' اكتب اسم المنتج';
                  }
                  return null;
                },
              ),
              SizedBox(
                height: hi / 40,
              ),
              TextFormFiled2(
                controller: descriptionOfItem,
                borderRadius: 15,
                fontSize: wi / 22,
                label: 'وصف للمنتج',
                obscure: false,
                wight: wi,
                height: hi / 15,
                validator: (val) {
                  if (val == null) {
                    return 'اكتب وصف للمنتج';
                  }
                  return null;
                },
              ),
              SizedBox(
                height: hi / 40,
              ),
              TextFormFiled2(
                controller: oldPrice,
                textInputType2: TextInputType.number,
                borderRadius: 15,
                fontSize: wi / 22,
                label: 'سعر المنتج القديم',
                obscure: false,
                wight: wi,
                height: hi / 15,
                validator: (val) {
                  if (val == null) {
                    return 'اكتب سعر المنتج';
                  }
                  return null;
                },
              ),
              SizedBox(
                height: hi / 40,
              ),
              TextFormFiled2(
                controller: priceOfItem,
                borderRadius: 15,
                fontSize: wi / 22,
                textInputType2: TextInputType.number,
                label: 'سعر المنتج الجديد',
                obscure: false,
                wight: wi,
                height: hi / 15,
                validator: (val) {
                  if (val == null) {
                    return 'اكتب سعر للمنتج';
                  }
                  return null;
                },
              ),
              SizedBox(
                height: hi / 40,
              ),
              TextFormFiled2(
                controller: rate,
                borderRadius: 15,
                fontSize: wi / 22,
                textInputType2: TextInputType.number,
                label: 'نسبة التخفيض  ',
                obscure: false,
                wight: wi,
                height: hi / 15,
                validator: (val) {
                  if (val == null) {
                    return 'اكتب نسبة التخفيض ';
                  }
                  return null;
                },
              ),
              SizedBox(
                height: hi / 30,
              ),

              Choosevideo(),
              SizedBox(
                height: hi / 30,
              ),
              addManyImage(),

              SizedBox(
                height: hi / 30,
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    GestureDetector(
                        onTap: () {
                          // saveData();
                        },
                        child: Container(
                            height: hi / 12,
                            width: wi / 5,
                            decoration: BoxDecoration(
                                border: Border.all(color: Colors.red, width: 2),
                                color: Colors.white70,
                                borderRadius: BorderRadius.circular(10)),
                            child: Icon(
                              Icons.keyboard_backspace_sharp,
                              size: 45,
                              color: Colors.red,
                            ))),
                    GetBuilder<Getchoosevideo>(init: Getchoosevideo(),builder: (logic1) {
                      return  GetBuilder<Getinformationofitem>(
                        init: Getinformationofitem(



                          rate: rate,
                            oldPrice: oldPrice,

                            uint8list: uint8list1,
                            TypeItem: TypeItem,
                            descriptionOfItem: descriptionOfItem,
                            nameOfItem: nameOfItem,
                            priceOfItem: priceOfItem,
                            globalKey: globalKey,







                        ), builder: (logic) {

                        return GestureDetector(
                          onTap: () async{
                            Getinformationofitem.isSend = true;

                            logic1.update();
                            if(logic1.url !=null){
                             await getAddManyImage.saveManyImage(getAddManyImage.allBytes);
                             getAddManyImage.allBytes.clear();


                             await logic1.save1();
                            await  logic.saveData(logic1.imgUrl!,context);
                            }else{
                             await getAddManyImage.saveManyImage(getAddManyImage.allBytes);
                             getAddManyImage.allBytes.clear();
                             logic.saveData('noVideo',context);
                            }

                          },
                          child: Getinformationofitem.isSend == false  ? Container(
                              height: hi / 12,
                              width: wi / 5,
                              decoration: BoxDecoration(
                                  color: Colors.white70,
                                  border: Border.all(
                                      color: Colors.blueAccent, width: 2),
                                  borderRadius: BorderRadius.circular(10)),
                              child: Icon(
                                Icons.send,
                                size: 45,
                                color: Colors.blueAccent,
                              )):CircularProgressIndicator(),
                        );
                      });
                    })
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
