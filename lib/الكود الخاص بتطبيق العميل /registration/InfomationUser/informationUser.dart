



import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../XXX/xxx_firebase.dart';
import '../../widget/TextFormFiled.dart';
import 'Getx/GetxInformtionUser.dart';

class InformationUser extends StatelessWidget {
  InformationUser({
    super.key,
    required this.email,
    required this.password,
    required this.passwordAndEmail,
  });

  final bool passwordAndEmail;
  final String email;
  final String password;
  final TextEditingController phone = TextEditingController();
  final TextEditingController nameController = TextEditingController();
  final GlobalKey<FormState> globalKey = GlobalKey<FormState>();
  final GetxInformationUser getxController = Get.put(GetxInformationUser(
    // password: '',
    passwordAndEmail: false,
    // phoneController: phone.text,
    // email: '',
    // formKey: globalKey,
    // nameController: TextEditingController(),
  ));

  @override
  Widget build(BuildContext context) {
    double hi = MediaQuery.of(context).size.height;
    double wi = MediaQuery.of(context).size.width;

    return Scaffold(
      body: Form(
        key: globalKey,
        child: Stack(
          children: [
            // الخلفية
            Image.asset(
              ImageX.ImageOfSignUp,
              width: wi,
              height: hi,
              fit: BoxFit.cover,
            ),

            // المحتوى
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: SingleChildScrollView(
                child: SafeArea(
                  child: Column(
                    children: [
                      SizedBox(height: hi / 13),

                      // اختيار الصورة
                      GestureDetector(
                        onTap: () {
                          showModalBottomSheet(
                            context: context,
                            builder: (BuildContext context) {
                              return SizedBox(
                                width: wi,
                                height: hi / 4,
                                child: Column(
                                  children: [
                                    ListTile(
                                      leading: const Icon(Icons.camera),
                                      title: const Text('كاميرا'),
                                      onTap: () {
                                        getxController.pickFromCamera();
                                        Navigator.pop(context);
                                      },
                                    ),
                                    const Divider(),
                                    ListTile(
                                      leading: const Icon(Icons.photo),
                                      title: const Text('المحفوظة'),
                                      onTap: () {
                                        getxController.pickFromGallery();
                                        Navigator.pop(context);
                                      },
                                    ),
                                  ],
                                ),
                              );
                            },
                          );
                        },
                        child:Obx(() {
                          if (getxController.isLoading.value) {
                            return const Center(
                              child: CircularProgressIndicator(), // مؤشر تحميل
                            );
                          }

                          if (getxController.imagesView2.value == null) {
                            return Container(
                              width: wi / 2.75,
                              height: hi / 5.5,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(15),
                                image:  DecorationImage(

                                  image: NetworkImage(ImageX.ImageOfPerson),
                                    fit: BoxFit.cover// الصورة الافتراضية
                                ),
                              ),
                            );
                          } else {
                            return Container(
                              width: wi / 2.75,
                              height: hi / 5.5,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(15),
                                image: DecorationImage(
                                  image: MemoryImage(getxController.imagesView2.value!),
                                  fit: BoxFit.cover,
                                ),
                              ),
                            );
                          }
                        })

                      ),
                      SizedBox(height: hi / 30),

                      // إدخال الاسم
                      TextFormFiled2(
                        fontSize: wi / 22,
                        validator: (val) {
                          if (val!.isEmpty) {
                            return 'الرجاء اكتب الاسم';
                          } else if (val.length < 5) {
                            return 'الاسم قصير';
                          }
                          return null;
                        },
                        controller: nameController,
                        borderRadius: 15,
                        label: 'الاسم',
                        obscure: false,
                        width: wi,
                        height: hi / 12,
                      ),
                      SizedBox(height: hi / 50),

                      // إدخال رقم الهاتف
                      Container(
                        alignment: Alignment.center,
                        width: wi,
                        height: hi / 12,
                        padding: const EdgeInsets.symmetric(horizontal: 5),
                        decoration: BoxDecoration(
                          color: Colors.white70,
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(color: Colors.black87),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: wi / 6,
                              height: hi / 20,
                              alignment: Alignment.center,
                              child: Obx(() {
                                return Text(
                                  getxController.intrNumber.value,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: wi / 22,
                                  ),
                                );
                              }),
                            ),
                            Expanded(
                              child: TextFormField(
                                keyboardType: TextInputType.number,
                                obscureText: false,
                                controller: phone,
                                validator: (val) {
                                  if (val!.length != 10) {
                                    getxController.showPhoneNumberError(context);
                                    return null; // لا تعيد نص في الـ validator
                                  }
                                  return null;
                                },
                                decoration: InputDecoration(
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(15),
                                    borderSide: BorderSide.none,
                                  ),
                                  hintText: 'رقم الهاتف',
                                  hintStyle: TextStyle(
                                    fontSize: wi / 22,
                                    color: Colors.black87,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: hi / 3.5),

                      // زر التالي
                      GestureDetector(
                        onTap: () async {
                          await getxController.goToNextPage(context,globalKey,phone,nameController,email,password);
                        },
                        child: Container(
                          width: wi,
                          height: hi / 12,
                          decoration: BoxDecoration(
                            color: Colors.white60,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.black),
                          ),
                          child: Center(
                            child: Text(
                              'التالي',
                              style: TextStyle(fontSize: wi / 22),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
