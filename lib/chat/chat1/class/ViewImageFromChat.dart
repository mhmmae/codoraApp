

import 'package:flutter/material.dart';


class Viewimagefromchat extends StatelessWidget {
  Viewimagefromchat({super.key,
    required this.uint8list,
    required this.uid,
  });

  String uint8list;
  String uid;

  @override
  Widget build(BuildContext context) {
    double hi = MediaQuery.of(context).size.height;
    double wi = MediaQuery.of(context).size.width;
    return Scaffold(
        body:  Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                  image: DecorationImage(
                      fit: BoxFit.fill,
                      image: NetworkImage(
                        uint8list,
                      ))),
            ),

            Positioned(
                top: hi / 35,
                right: wi / 27,
                child: GestureDetector(onTap: (){
                  Navigator.pop(context);
                },
                  child: Container(
                      height: hi / 17,
                      width: wi / 8.5,
                      decoration: BoxDecoration(
                          border: Border.all(color: Colors.black, width: 2),
                          color: Colors.black87,
                          borderRadius: BorderRadius.circular(100)),
                      child: Icon(
                        Icons.cancel,
                        size: wi/12.5,
                        color: Colors.white,
                      )),
                )),



          ],





        )
    );
  }
}
