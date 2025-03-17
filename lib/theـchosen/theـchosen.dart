import 'package:flutter/material.dart';

import 'class/SendAndTotalPrice.dart';
import 'class/StreamListOfItem.dart';

class theChosen extends StatelessWidget {
   theChosen({super.key,required this.uid});
   String uid;

  @override
  Widget build(BuildContext context) {
    double hi = MediaQuery.of(context).size.height;
    double wi = MediaQuery.of(context).size.width;

    return Scaffold(
        extendBodyBehindAppBar: true,
        body: Column(children: [
          Container(
            height: hi / 8,
            color: Colors.white10,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  SizedBox(
                    height: hi / 20,
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          SizedBox(
                            width: wi / 18,
                          ),
                          Text(
                            'card',
                            style: TextStyle(fontSize: wi / 20),
                          )
                        ],
                      ),
                      Icon(
                        Icons.dehaze_rounded,
                        size: wi / 14,
                      )
                    ],
                  ),
                ],
              ),
            ),
          ),
          Container(
              decoration: BoxDecoration(
                  border: Border.all(color: Colors.black),
                  color: Colors.black12,
                  borderRadius: BorderRadius.circular(15)),
              height: hi / 1.70,
              child: ListView(
                shrinkWrap: true,
                primary: true,
                children: [

                  Streamlistofitem()

                ],
              )),
          // ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^--------------------^^^^^^^^^^^^^^^^^^^^^^
          // ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^--------------------^^^^^^^^^^^^^^^^^^^^^^
          // ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^--------------------^^^^^^^^^^^^^^^^^^^^^^
          Sendandtotalprice(uid: uid,)
        ]));
  }
}
