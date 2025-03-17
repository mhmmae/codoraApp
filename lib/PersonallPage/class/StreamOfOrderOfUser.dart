import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../Model/ModelOrder.dart';
import '../../TheOrder/ViewOeder/GetX/GetGoTOMapDilyvery.dart';
import '../../XXX/XXXFirebase.dart';
import '../../googleMap/googleMap.dart';

class Streamoforderofuser extends StatelessWidget {
  Streamoforderofuser({super.key});

  CollectionReference TheOrder = FirebaseFirestore.instance.collection('order');

  @override
  Widget build(BuildContext context) {
    double hi = MediaQuery.of(context).size.height;
    double wi = MediaQuery.of(context).size.width;
    return FutureBuilder<DocumentSnapshot>(
      future: TheOrder.doc(FirebaseAuth.instance.currentUser!.uid).get(),
      builder:
          (BuildContext context, AsyncSnapshot<DocumentSnapshot> snapshot) {
        if (snapshot.hasError) {
          return Text("Something went wrong");
        }

        if (snapshot.hasData && !snapshot.data!.exists) {
          return Text("");
        }

        if (snapshot.connectionState == ConnectionState.done) {
          ModleOrder order = ModleOrder.fromMap(  snapshot.data!.data() as Map<String, dynamic>);

          return snapshot.data!.exists
              ? Container(
                  height: order.Delivery ? hi / 3.5 : hi / 4.5,
                  width: wi,
                  color: Colors.transparent,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 2),
                        child: Container(
                          decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(5),
                              border: Border.all(
                                  color: order.RequestAccept
                                      ? Colors.green
                                      : Colors.red,
                                  width: 2)),
                          child: Column(
                            children: [

                              Container(
                                  width: wi / 3.20,
                                  height: hi / 6.3,
                                  decoration:  BoxDecoration(
                                      color: Colors.black12,

                                      image: DecorationImage(
                                        fit: BoxFit.cover,
                                          image: AssetImage(ImageX.imageofColok)))),
                              Padding(
                                padding: EdgeInsets.symmetric(horizontal: 2),
                                child: order.Delivery
                                    ? SizedBox(
                                        height: hi / 18,
                                        width: wi / 3.25,
                                        child: Text(
                                          'تم تجهيز الطلب',
                                          style: TextStyle(
                                              fontSize: wi / 30,
                                              color: Colors.green),
                                        ))
                                    : order.RequestAccept
                                        ? SizedBox(
                                            height: hi / 18,
                                            width: wi / 3.25,
                                            child: Text(
                                              'يتم الان تجهيز طلبك',
                                              style:
                                                  TextStyle(fontSize: wi / 37),
                                            ))
                                        : SizedBox(
                                            height: hi / 18,
                                            width: wi / 3.25,
                                            child: Text(
                                                'الرجاء الانتظار يتم قبول الطلب',
                                                style: TextStyle(
                                                    fontSize: wi / 40))),
                              )
                            ],
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 2),
                        child: GetBuilder<Getgotomapdilyvery>(
                            init: Getgotomapdilyvery(),
                            builder: (logic) {
                              return GestureDetector(
                                onTap: () async {
                                  if (order.Delivery == true) {
                                    if (order.doneDelivery == false) {
                                      await logic.IconMarckt();
                                      await Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => googleMap(
                                            idDilivery: false,
                                            longitude: order.longitude,
                                            latitude: order.latitude,
                                            markerDelivery:
                                                logic.markerDelivery,
                                            markerUser: logic.markerUser,
                                          ),
                                        ),
                                      );
                                    }
                                  }
                                },
                                child: Container(
                                  decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(5),
                                      border: Border.all(
                                          color: order.Delivery
                                              ? Colors.green
                                              : Colors.red,
                                          width: 2)),
                                  child: Column(
                                    children: [
                                      Container(
                                          width: wi / 3.25,
                                          height: hi / 6.3,
                                          decoration: BoxDecoration(
                                              color: Colors.black12,
                                              image: DecorationImage(
                                                  fit: BoxFit.cover,

                                                  image: AssetImage(
                                                      ImageX.imageofdilivery)))),
                                      Padding(
                                          padding: EdgeInsets.symmetric(
                                              horizontal: 2),
                                          child: order.doneDelivery
                                              ? SizedBox(
                                                  height: hi / 18,
                                                  width: wi / 3.55,
                                                  child: Text(
                                                    'شكرا لآختيارك متجرنا',
                                                    style: TextStyle(
                                                        fontSize: wi / 37,
                                                        color: Colors.green),
                                                  ))
                                              : order.Delivery
                                                  ? SizedBox(
                                                      height: hi / 15,
                                                      width: wi / 3.25,
                                                      child: Text(
                                                        'الطلب في طريقه اليك (اضغط على الصورة لعرض الخريطة)',
                                                        style: TextStyle(
                                                            fontSize: wi / 50,
                                                            color:
                                                                Colors.green),
                                                      ))
                                                  : order.RequestAccept
                                                      ? SizedBox(
                                                          height: hi / 18,
                                                          width: wi / 3.25,
                                                          child: Text(
                                                            'يتم الان تجهيز طلبك',
                                                            style: TextStyle(
                                                                fontSize:
                                                                    wi / 37),
                                                          ))
                                                      : SizedBox(
                                                          height: hi / 18,
                                                          width: wi / 3.25,
                                                          child: Text(
                                                              'الرجاء الانتظار يتم قبول الطلب',
                                                              style: TextStyle(
                                                                  fontSize: wi /
                                                                      40))))
                                    ],
                                  ),
                                ),
                              );
                            }),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 2),
                        child: Container(
                          decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(5),
                              border: Border.all(
                                  color: order.doneDelivery
                                      ? Colors.green
                                      : Colors.red,
                                  width: 2)),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              Container(
                                  width: wi / 3.40,
                                  height: hi / 6.3,
                                  decoration: BoxDecoration(
                                      color: Colors.black12,
                                      image: DecorationImage(
                                          fit: BoxFit.cover,

                                          image: AssetImage(
                                              ImageX.imageofDiliveryDone)))),
                              Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 2),
                                  child: order.doneDelivery
                                      ? SizedBox(
                                          height: hi / 18,
                                          width: wi / 3.55,
                                          child: Text(
                                            'اضغط لعرض قائمة المشتريات',
                                            style: TextStyle(
                                                color: Colors.green,
                                                fontSize: wi / 37),
                                          ))
                                      : order.Delivery
                                          ? SizedBox(
                                              height: hi / 12,
                                              width: wi / 3.55,
                                              child: Text(
                                                'الطلب في طريقه اليك ',
                                                style: TextStyle(
                                                    fontSize: wi / 30,
                                                    color: Colors.green),
                                              ))
                                          : order.RequestAccept
                                              ? SizedBox(
                                                  height: hi / 18,
                                                  width: wi / 3.55,
                                                  child: Text(
                                                    'يتم الان تجهيز طلبك',
                                                    style: TextStyle(
                                                        fontSize: wi / 37),
                                                  ))
                                              : SizedBox(
                                                  height: hi / 18,
                                                  width: wi / 3.55,
                                                  child: Text(
                                                      'الرجاء الانتظار يتم قبول الطلب',
                                                      style: TextStyle(
                                                          fontSize: wi / 40))))
                            ],
                          ),
                        ),
                      )
                    ],
                  ),
                )
              : Container(
                  height: hi / 3,
                  width: wi,
                  color: Colors.red,
                );
        }

        return Text("");
      },
    );
  }
}
