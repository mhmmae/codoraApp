import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../../XXX/XXXFirebase.dart';
import '../../../video/Getx/GetChooseVideo.dart';
import '../../../video/chooseVideo.dart';
import '../../../widget/TextFormFiled.dart';

class Classofadditem extends StatelessWidget {
  Classofadditem({
    super.key,
    required this.TypeItem,
    required this.uint8list1,
  });

  Uint8List uint8list1;
  String TypeItem;
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
    return Form(
      key: globalKey,
      child: SafeArea(
        child: ListView(
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
              wight: wi,
              height: hi / 15,
              validator: (val) {
                if (val == null) {
                  return 'اكتب اسم المنتج ';
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
              controller: priceOfItem,
              textInputType2: TextInputType.number,
              borderRadius: 15,
              fontSize: wi / 22,
              label: 'سعر المنتج',
              obscure: false,
              wight: wi,
              height: hi / 15,
              validator: (val) {
                if (val == null) {
                  return ' اكتب سعر المنتج';
                }
                return null;
              },
            ),
            SizedBox(
              height: hi / 40,
            ),

            // Container(

            GetBuilder<Getinformationofitem>(
                init: Getinformationofitem(
                    rate: rate,
                    oldPrice: oldPrice,

                    uint8list: uint8list1,
                    TypeItem: TypeItem,
                    descriptionOfItem: descriptionOfItem,
                    nameOfItem: nameOfItem,
                    priceOfItem: priceOfItem,
                    globalKey: globalKey),
                assignId: true,
                builder: (logic) {
                  return DropdownButton12 == false
                      ? GestureDetector(
                    onTap: () {
                      DropdownButton12 = true;
                      logic.update();
                    },
                    child: Container(
                      width: double.infinity,
                      height: hi / 15,
                      decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.black)),
                      child: Row(
                        children: [
                          SizedBox(
                            width: wi / 40,
                          ),
                          Text(
                            arbicTheChosen == ''
                                ? 'اختر نوع الاضافة'
                                : arbicTheChosen!,
                            style: TextStyle(
                                color: Colors.black,
                                fontSize: wi / 23,
                                fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                  )
                      : Container(
                      height: hi / 2.5,
                      decoration: const BoxDecoration(
                          color: Colors.white38,
                          border: Border.symmetric(
                              horizontal: BorderSide(color: Colors.black))),
                      child: ListView.builder(
                          itemCount: logic.TheWher.length,
                          shrinkWrap: true,
                          scrollDirection: Axis.vertical,
                          itemBuilder: (context, index) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 30),
                              child: GestureDetector(
                                  onTap: () {
                                    logic.TheChosen = logic.TheWher[index];
                                    arbicTheChosen = logic.text[index];
                                    DropdownButton12 = false;
                                    logic.update();
                                  },
                                  child: Column(
                                    children: [
                                      SizedBox(
                                        height: hi / 70,
                                      ),
                                      Container(

                                        decoration: BoxDecoration(
                                            color: logic.TheChosen !=
                                                logic.TheWher[index]
                                                ? Colors.black12
                                                : Colors
                                                .deepPurpleAccent,
                                            borderRadius:
                                            BorderRadius.circular(
                                                16),
                                            border: Border.all(
                                                color: Colors.black)),
                                        width: wi / 1.3,
                                        height: hi / 20,
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 20),
                                          child: Row(
                                            mainAxisAlignment:
                                            MainAxisAlignment
                                                .spaceBetween,
                                            children: [
                                              logic.icon[index],
                                              SizedBox(
                                                width: wi / 80,
                                              ),
                                              Container(
                                                  color: Colors.transparent,
                                                  child: Text(logic.text[index],
                                                    style: TextStyle(
                                                        fontSize: wi / 30),)),
                                            ],
                                          ),
                                        ),
                                      ),

                                    ],
                                  )),
                            );
                          })
                  );
                }),
            SizedBox(
              height: hi / 30,
            ),


            Choosevideo(),

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
                        Navigator.pop(context);
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

                    return GetBuilder<Getinformationofitem>(
                      init: Getinformationofitem(
                        rate: rate,
                        globalKey: globalKey,
                        oldPrice: oldPrice,

                        uint8list: uint8list1,
                        TypeItem: TypeItem,
                        descriptionOfItem: descriptionOfItem,
                        nameOfItem: nameOfItem,
                        priceOfItem: priceOfItem,
                      ),
                      builder: (logic) {

                          return GestureDetector(
                            onTap: () async{
                              if(logic1.url !=null){
                              await  logic1.save1();
                               await logic.saveData(logic1.imgUrl!,context);
                              }else{
                              await  logic.saveData('noVideo',context);
                              }

                            },
                            child: Container(
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
                                )),
                          );
                        });
                      })
                ],
              ),
            ),


          ],
        ),
      ),
    );
  }
}
