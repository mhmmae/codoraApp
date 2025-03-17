


import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class TextFomeFildeCodePhone extends StatelessWidget {

  bool first;
  bool correct;
  bool last;
  TextEditingController codePhone;
  VoidCallback? sendcode;

   TextFomeFildeCodePhone({super.key,required this.first,required this.last,required this.codePhone,required this.correct,this.sendcode});

  @override
  Widget build(BuildContext context) {
    double hi = MediaQuery.of(context).size.height;
    double wi = MediaQuery.of(context).size.width;
    return Container(
    decoration: BoxDecoration(
    color: Colors.black12,
    border: Border.all(color: correct ?Colors.greenAccent:Colors.red, width: 2),
    borderRadius: BorderRadius.circular(15)),
    child: TextFormField(
      controller: codePhone,
      onChanged: (val){
        if(val.isNotEmpty && last == false){
          FocusScope.of(context).nextFocus();

        }else if(val.isEmpty && first ==false){
          FocusScope.of(context).previousFocus();
        }else if(val.isNotEmpty && first ==false && last ==true){
          sendcode!();

        }
      },
    style: TextStyle(fontSize: wi/16),
    inputFormatters: [LengthLimitingTextInputFormatter(1)],
    textAlign: TextAlign.center,
    decoration: InputDecoration(
    border: InputBorder.none,
    constraints: BoxConstraints(
    maxWidth: wi/7,
    maxHeight: hi/9),

),

keyboardType: TextInputType.number,

),
);
  }
}
