import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'Getx/GetCodePhoneNumber.dart';
import 'TextFomeFildeCodePhone.dart';

class codePhone extends StatelessWidget {
  codePhone({super.key,
    required this.phneNumber,
    required this.imageUser,
    required this.Name,
    required this.Email,
    required this.password,
    required this.pssworAndEmail});

  String phneNumber;
  Uint8List imageUser;
  String Name;
  String Email;
  String password;
  bool pssworAndEmail;
  TextEditingController c1 = TextEditingController();
  TextEditingController c2 = TextEditingController();
  TextEditingController c3 = TextEditingController();
  TextEditingController c4 = TextEditingController();
  TextEditingController c5 = TextEditingController();
  TextEditingController c6 = TextEditingController();

  @override
  Widget build(BuildContext context) {
    double hi = MediaQuery.of(context).size.height;
    double wi = MediaQuery.of(context).size.width;
    return Scaffold(
      body: SingleChildScrollView(
        child: GetBuilder<Getcodephonenumber>(init: Getcodephonenumber(password: password,
          phneNumber: phneNumber,pssworAndEmail: pssworAndEmail,Name: Name,imageUser: imageUser,Email: Email,
          c1: c1,c2: c2,c3: c3,c4: c4,c5: c5,c6: c6,),builder: (logic) {
          return Column(
            children: [
              SizedBox(
                height: hi / 4.5,
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    TextFomeFildeCodePhone(
                      first: true,
                      last: false,
                      codePhone: c1,
                      correct: logic.correct1,
                    ),
                    TextFomeFildeCodePhone(
                      first: false,
                      last: false,
                      codePhone: c2,
                      correct: logic.correct1,
                    ),
                    TextFomeFildeCodePhone(
                      first: false,
                      last: false,
                      codePhone: c3,
                      correct: logic.correct1,
                    ),
                    TextFomeFildeCodePhone(
                      first: false,
                      last: false,
                      codePhone: c4,
                      correct: logic.correct1,
                    ),
                    TextFomeFildeCodePhone(
                      first: false,
                      last: false,
                      codePhone: c5,
                      correct: logic.correct1,
                    ),
                    TextFomeFildeCodePhone(
                      first: false,
                      last: true,
                      codePhone: c6,
                      correct: logic.correct1,
                      sendcode: () {
                        print('000000000000000000000000000000');

                        logic.sentCode(context);
                      },
                    ),
                  ],
                ),
              ),
              SizedBox(
                height: hi / 10,
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 15),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    GestureDetector(
                      onTap: () {
                        logic.phoneAuthCode();
                      },
                      child: Container(
                          padding: EdgeInsets.symmetric(horizontal: 8),
                          decoration: BoxDecoration(
                              border: Border.all(color: Colors.blueAccent),
                              borderRadius: BorderRadius.circular(15),
                              color: Colors.black12),
                          child: Text('اعد ارسال الكود',
                              style: TextStyle(
                                  color: Colors.blueAccent,
                                  fontSize: wi / 19,
                                  fontWeight: FontWeight.w900))),
                    ),
                    Text(
                      logic.connter.toString(),
                      style: TextStyle(color: Colors.black, fontSize: wi / 15),
                    ),
                  ],
                ),
              ),
              Center(
                child: logic.isLoding ? CircularProgressIndicator() : null,
              ),
            ],
          );
        }),
      ),
    );
  }
}
