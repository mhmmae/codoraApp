import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../TheOrder/ViewOeder/GetX/GetGoTOMapDilyvery.dart';
import '../bottonBar/botonBar.dart';
import 'class/StreamMapIsDilivery.dart';
import 'class/StreamMapIsNotDilivery.dart';

class googleMap extends StatelessWidget {
  bool idDilivery;
  double latitude;
  double longitude;

  googleMap({super.key,
    required this.idDilivery,
    required this.longitude,
    required this.latitude,
    this.markerUser,
    this.markerDelivery});

  Uint8List? markerUser;
  Uint8List? markerDelivery;

  @override
  Widget build(BuildContext context) {
    double hi = MediaQuery
        .of(context)
        .size
        .height;
    double wi = MediaQuery
        .of(context)
        .size
        .width;
    return Scaffold(
        body: Stack(
          children: [
            idDilivery
            // ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
            // ---------------------------------------------------------------------------------------------------------------
            // ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
                ? Streammapisdilivery(
                isdilivery: idDilivery,
                latitude: latitude,
                longitude: longitude,
                markerUser: markerUser,
                markerDelivery: markerDelivery)
            // ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
            // ---------------------------------------------------------------------------------------------------------------
            // ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
                : StreammapisNotdilivery(
                isdilivery: idDilivery,
                latitude: latitude,
                longitude: longitude,
                markerUser: markerUser,
                markerDelivery: markerDelivery),

            // ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
            // ---------------------------------------------------------------------------------------------------------------
            // ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
            Positioned(
                top: hi / 17,
                left: wi / 20,
                child: GetBuilder<Getgotomapdilyvery>(init: Getgotomapdilyvery(),builder: (logic) {
                  return GestureDetector(
                    onTap: () {
                      logic.isloding= false;
                      Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(
                              builder: (context) =>
                                  bottonBar(
                                    theIndex: idDilivery ? 2 : 3,
                                  )), (rute) => false);
                    },
                    child: Container(
                      width: wi / 4,
                      height: hi / 22,
                      decoration: BoxDecoration(
                          border: Border.all(color: Colors.black),
                          borderRadius: BorderRadius.only(
                              topRight: Radius.circular(15),
                              bottomRight: Radius.circular(15),
                              topLeft: Radius.circular(200),
                              bottomLeft: Radius.circular(200)),
                          color: Colors.red),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Icon(
                              Icons.home,
                              size: wi / 17,
                            ),
                            Icon(
                              Icons.arrow_back,
                              size: wi / 13,
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                })),
          ],
        ));
  }
}
