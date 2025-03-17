
import 'package:flutter/material.dart';

import '../../../addItem/addItem.dart';
import '../../statistics/statistics.dart';


class Drawer2 extends StatelessWidget {
   const Drawer2({super.key});

  @override
  Widget build(BuildContext context) {
    double hi = MediaQuery.of(context).size.height;
    double wi = MediaQuery.of(context).size.width;
    return Drawer(
      backgroundColor: Colors.white,
      width: wi/1.4,

      child: Padding(
        padding: const EdgeInsets.all(5.0),
        child: ListView(
          children: [
            SizedBox(height: hi/40,),
            GestureDetector(
              onTap: (){
                Navigator.push(context, MaterialPageRoute(builder: (context)=>const addItem()));
              },
              child: Container(
                decoration: BoxDecoration(
                    color: Colors.blueAccent,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.black)
                ),
                height: hi/20,

                child: Center(
                  child: Text('اضافة منتجات',style: TextStyle(fontSize: wi/26),),
                ),
              ),
            ),
            SizedBox(height: hi/55,),
            GestureDetector(
              onTap: (){
                Navigator.push(context, MaterialPageRoute(builder: (context)=>const statistics()));
              },
              child: Container(
                decoration: BoxDecoration(
                    color: Colors.blueAccent,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.black)
                ),
                height: hi/20,

                child: Center(
                  child: Text('احصائيات',style: TextStyle(fontSize: wi/26),),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}
