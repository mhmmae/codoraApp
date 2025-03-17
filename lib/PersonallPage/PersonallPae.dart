
import 'package:flutter/material.dart';

import 'class/ClassOfSetingOfPeronall.dart';
import 'class/StreamOfOrderOfUser.dart';
import 'class/StreamOfiNformtionOfUSER.dart';

class personallPage extends StatelessWidget {
  const personallPage({super.key});

  @override
  Widget build(BuildContext context) {
    double hi = MediaQuery.of(context).size.height;
    double wi = MediaQuery.of(context).size.width;
    return Scaffold(
      body: ListView(
        shrinkWrap: true,
        children: [
          Streamofinformtionofuser(),
          SizedBox(height: hi / 70,),
          Divider(),
          Streamoforderofuser(),
          Classofsetingofperonall()
        ],
      ),
    );
  }
}
