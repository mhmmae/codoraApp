

import 'package:flutter/material.dart';
import 'package:get/get.dart';

class GetStreamBuildOfItem extends GetxController{
  final FocusNode focusNode = FocusNode();
  

  @override
  void onInit() {

    // if(initialized){
    //   print('////////////////////////////////////////////////////');
    //   print('/////////////////////////////////////s///////////////');
    //   print('/////////////////////////////qw///////////////////////');
    //   FlutterNativeSplash.remove();
    //
    // }

    focusNode.addListener(() {
      if (!focusNode.hasFocus) {
        // تنفيذ أي منطق عند فقدان التركيز
        print('9999999999999999999999999999999');
        print('99999999999999999999999929999999');
        print('999999999999999999999999459999999');

      }
    });
    // TODO: implement onInit
    super.onInit();
  }
  


}