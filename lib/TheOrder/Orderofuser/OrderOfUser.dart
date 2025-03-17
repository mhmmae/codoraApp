import 'package:flutter/material.dart';

import '../../bottonBar/botonBar.dart';
import 'class/SfBarcodeGenerator.dart';
import 'class/StreamOrderOfUser.dart';

class Orderofuser extends StatelessWidget {
  String uid;

  Orderofuser({super.key, required this.uid});

  @override
  Widget build(BuildContext context) {
    double hi = MediaQuery.of(context).size.height;
    double wi = MediaQuery.of(context).size.width;
    return Scaffold(
      appBar: AppBar(
        leading: GestureDetector(
          onTap: () {
            Navigator.pushAndRemoveUntil( context,
                MaterialPageRoute(
                    builder: (context) => bottonBar(
                      theIndex: 2,
                    )), (rule)=>false);
          },
          child: SizedBox(
              height: hi / 28,
              width: wi / 9,
              child: Icon(
                Icons.backspace,
                size: wi / 18,
                color: Colors.blueAccent,
              )),
        ),
      ),
      body: ListView(
        children: [
          Streamorderofuser(
            uid: uid,
          ),
          SizedBox(
            height: hi / 25,
          ),
          SfBarcodeGenerator2(
            uid: uid,
          )
        ],
      ),
    );
  }
}
