
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../Model/ModelUser.dart';
import '../../XXX/XXXFirebase.dart';

class Streamofinformtionofuser extends StatelessWidget {
   Streamofinformtionofuser({super.key});
  CollectionReference users = FirebaseFirestore.instance.collection(FirebaseX.collectionApp);


  @override
  Widget build(BuildContext context) {
    double hi = MediaQuery.of(context).size.height;
    double wi = MediaQuery.of(context).size.width;
    return   FutureBuilder<DocumentSnapshot>(
      future: users.doc(FirebaseAuth.instance.currentUser!.uid).get(),
      builder: (BuildContext context,
          AsyncSnapshot<DocumentSnapshot> snapshot) {
        if (snapshot.hasError) {
          return Text("Something went wrong");
        }

        if (snapshot.hasData && !snapshot.data!.exists) {
          return Text("Document does not exist");
        }

        if (snapshot.connectionState == ConnectionState.done) {
          ModelUser UserData =ModelUser.fromMap(snapshot.data!.data() as Map<String, dynamic>);

          return Column(
            children: [
              SizedBox(height: hi / 25),
              Row(
                children: [
                  Row(
                    children: [
                      SizedBox(
                        width: wi / 50,
                      ),
                      Container(
                        height: hi / 4,
                        width: wi / 2,
                        decoration: BoxDecoration(
                            color: Colors.black12,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: Colors.black),
                            image: DecorationImage(
                                fit: BoxFit.cover,
                                image: NetworkImage(UserData.url))),
                      ),
                    ],
                  ),
                  SizedBox(
                    width: wi / 30,
                  ),
                  Column(
                    children: [
                      Container(
                        width: wi / 2.5,
                        decoration: BoxDecoration(
                            color: Colors.black12,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.black)),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Center(
                                child: Text(
                                  'اسم المستخدم',
                                  style: TextStyle(fontSize: wi / 40),
                                )),
                            Center(
                                child: Text(UserData.name,
                                    style: TextStyle(fontSize: wi / 40))),
                            SizedBox(
                              height: hi / 100,
                            )
                          ],
                        ),
                      ),
                      SizedBox(
                        height: hi / 100,
                      ),
                      Container(
                        width: wi / 2.5,
                        decoration: BoxDecoration(
                            color: Colors.black12,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.black)),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Center(
                                child: Text(
                                  'ايميل المستخدم',
                                  style: TextStyle(fontSize: wi / 40),
                                )),
                            Center(
                                child: Text(UserData.email,
                                    style: TextStyle(fontSize: wi / 50))),
                            SizedBox(
                              height: hi / 100,
                            )
                          ],
                        ),
                      ),
                      SizedBox(
                        height: hi / 100,
                      ),
                      Container(
                        width: wi / 2.5,
                        decoration: BoxDecoration(
                            color: Colors.black12,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.black)),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Center(
                                child: Text(
                                  'رقم هاتف المستخدم',
                                  style: TextStyle(fontSize: wi / 40),
                                )),
                            Center(
                                child: Text(UserData.phneNumber,
                                    style: TextStyle(fontSize: wi / 50))),
                            SizedBox(
                              height: hi / 100,
                            )
                          ],
                        ),
                      ),
                    ],
                  )
                ],
              ),
            ],
          );
        }

        return const Align(alignment: Alignment.bottomCenter,
            child: Center(child: CircularProgressIndicator()));
      },
    );
  }
}
