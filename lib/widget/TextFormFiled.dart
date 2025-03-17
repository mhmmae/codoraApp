


import 'package:flutter/material.dart';

class TextFormFiled2 extends StatelessWidget {
   const TextFormFiled2({super.key, required this.controller,required this.borderRadius,
    this.validator, required this.label, required this.obscure, required this.wight, required this.height,
  this.textInputType2, required this.fontSize, this.OnChange, this.focusNode,this.color1,this.hintColor}) ;


 final TextEditingController  controller;
 final String? Function(String?)? validator;
 final String label;
 final double borderRadius;
 final bool obscure;
 final double wight;
 final double height;
 final TextInputType? textInputType2;
 final double fontSize;
 final ValueChanged?  OnChange;
 final FocusNode? focusNode;
 final Color? color1;
 final Color? hintColor;





  @override
  Widget build(BuildContext context) {
    return Container(
      
      alignment: Alignment.center,
      width: wight,
      height: height,
      padding: const EdgeInsets.symmetric(horizontal: 2),

      decoration: BoxDecoration(
        color: color1 ?? Colors.white70,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(color: Colors.black87)
      ),

        child: TextFormField(

          focusNode: focusNode,
          onEditingComplete: () {
            // منطق للإكمال
            // FocusScope.of(context).unfocus();

            print('zzzzzzzzzzzzzzzzzzzzzzzz');
          },


          textAlign: TextAlign.end,
          style: TextStyle(fontSize:fontSize),


          maxLines: 1,


          
          keyboardType: textInputType2,
          obscureText: obscure,
          onChanged: OnChange ,




          controller: controller ,
          validator: validator,

          decoration: InputDecoration(

            border: OutlineInputBorder(

              borderRadius: BorderRadius.circular(18),
              borderSide:  BorderSide.none
            ),





            hintText: label,


            hintStyle:  TextStyle(fontSize: fontSize,color: hintColor ?? Colors.black87,fontWeight: FontWeight.bold )
          ),


        ),

    );
  }
}
