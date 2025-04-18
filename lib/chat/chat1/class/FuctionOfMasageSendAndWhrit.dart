// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
//
// import '../../../widget/TextFormFiled.dart';
// import '../Getx/GetXaddImageAndVideo.dart';
// import '../Getx/GetxSendMassage.dart';
//
// class Fuctionofmasagesendandwhrit extends StatelessWidget {
//   Fuctionofmasagesendandwhrit(
//       {super.key, required this.Maseage, required this.uid});
//
//   TextEditingController Maseage = TextEditingController();
//   String uid;
//   Offset stared = Offset(0, 0);
//   Offset current = Offset(0, 0);
//   FocusNode focusNode = FocusNode();
//
//
//   @override
//   Widget build(BuildContext context) {
//     double hi = MediaQuery
//         .of(context)
//         .size
//         .height;
//     double wi = MediaQuery
//         .of(context)
//         .size
//         .width;
//     return GetBuilder<Getxsendmassage>(
//         init: Getxsendmassage(Maseage: Maseage, uid: uid),builder: (logic1) {
//       return Container(
//
//         child: Column(
//           children: [
//             Container(
//
//
//               width: wi,
//               height: hi / 19,
//               decoration: BoxDecoration(
//                 color: !logic1.isRecord ? Colors.black12 :Colors.black26,
//                 border: Border(top: BorderSide(color: Colors.black87,width: 0.5)),
//
//               ),
//               child: Padding(
//                 padding: const EdgeInsets.symmetric(horizontal: 15),
//                 child: Row(
//                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                   children: [
//
//
//                     !logic1.isRecord ?
//                     GetBuilder<Getxsendmassage>(
//                         init: Getxsendmassage(Maseage: Maseage, uid: uid),
//                         builder: (logic) {
//                           return SingleChildScrollView(
//                             child: TextFormFiled2(controller: logic.Maseage,
//                                 borderRadius: 20,
//                                 fontSize: wi / 29,
//                                 textInputType: TextInputType.multiline,
//                                  // focusNode: focusNode,
//                                 label: '',
//                                 onChange: (val) {
//                                   if (val != null) {
//                                     logic.update();
//
//                                   }
//                                 },
//                                 obscure: false,
//                                 width: wi / 1.5,
//                                 height: hi / 20),
//                           );
//                         }):Container(),
//
//                      logic1.isRecord?Container(): SizedBox(width: 2,),
//
//                     // ============================================================
//                     // ============================================================
//                     // ============================================================
//
//
//
//                     !logic1.isRecord ?
//                     GetBuilder<GetxAddImageAndVideo>(
//                         init: GetxAddImageAndVideo(uid: uid), builder: (val) {
//                       return GestureDetector(onTap: () {
//                         val.addImageAndVideo(hi, wi, context);
//                       },
//                         child: Container(decoration: BoxDecoration(
//                           color: Colors.black12,
//                           borderRadius: BorderRadius.circular(19),
//                         ),
//                             width: wi / 11, height: hi / 25,
//                             child: Icon(Icons.add, size: wi / 12,)),
//                       );
//                     }):Container(),
//
//
//                     SizedBox(width: 5,),
//
//                     GetBuilder<Getxsendmassage>(
//                         init: Getxsendmassage(Maseage: Maseage, uid: uid,context: context),
//                         builder: (logic) {
//                           return GestureDetector(
//                             onTap: () {
//
//
//                               logic.sendMessage2();
//
//
//                             },
//
//
//                             onLongPressEnd:(val)=> logic1.stopRecord(val,wi),
//
//                             onLongPressStart:(val) {
//
//
//                               if (logic.TheTimeOfMessage == 0) {
//                                 logic1.AudioRecored(val,wi,context);
//
//
//
//
//                               }
//                             } ,
//                             onLongPressMoveUpdate:(val)=> logic1.update1(val,wi),
//
//
//
//
//
//
//
//                             child: logic.Maseage.text.isEmpty ? Container(
//
//                               decoration: BoxDecoration(
//                                 color: logic.isRecord == true
//                                     ? Colors.transparent
//                                     : Colors.black38,
//                                 borderRadius: BorderRadius.circular(19),
//
//                               ),
//                               width:
//                               logic1.isRecord? wi/1.5 :
//                               wi / 11,
//                               height:
//                               logic1.isRecord? hi / 20:
//                               hi / 25,
//                               child: logic1.isRecord? Row(
//                                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                                 children: [
//                                   Container(
//                                     width: wi/10,
//                                   ),
//                                   Container(
//                                     child: logic1.isdelete == true ? Container(): Icon(Icons.delete_forever
//                                       ,color:
//                                       logic1.isGren == true && logic1.isyellow == false ?
//                                       Colors.green
//                                           : logic1.isGren == false && logic1.isyellow == true ?
//                                     Colors.yellow :Colors.green
//                                       ,size: wi/13,),
//                                   ),
//                                   Container(
//                                     width: wi/70,
//                                   ),
//
//                                       Text('تمرير للالغاء',style: TextStyle(fontSize: wi/33),),
//                                       Container(
//                                         width: wi/30,
//                                       ),
//                                       Text('<',style: TextStyle(fontSize: wi/20),),
//                                       Container(
//                                         width: wi/40,
//                                       ),
//                                       Text('<',style: TextStyle(fontSize: wi/25),),
//                                   Container(
//                                     width:  hi / 18,height:  hi / 20,
//                                     decoration: BoxDecoration(
//                                         borderRadius: BorderRadius.circular(19),
//
//                                         color: logic1.isRecord  ? Colors.redAccent : Colors.blueAccent
//                                     ),
//
//
//                                     child: Center(
//                                         child: Icon(
//                                           Icons.mic, color: Colors.white,)),
//                                   ),
//                                 ],
//                               ): Container(
//                                 width:  wi / 20,height:  hi / 25,
//                                 decoration: BoxDecoration(
//                                     borderRadius: BorderRadius.circular(19),
//
//                                     color:  Colors.blueAccent
//                                 ),
//
//
//                                 child: Center(
//                                     child: logic.isSending? CircularProgressIndicator() : Icon(
//                                       Icons.mic, color: Colors.white,)),
//                               ),) :
//
//
//
//                             //     =======================================================
//                             //     =======================================================
//                             //     =======================================================
//
//
//
//                             Container(decoration: BoxDecoration(
//                               color: Colors.blueAccent,
//                               borderRadius: BorderRadius.circular(19),
//
//                             ),
//                               width: wi / 11, height: hi / 25,
//                               child: Center(
//                                   child: Icon(
//
//                                     Icons.send_rounded, color: Colors.white,size: wi/21,)),),
//                           );
//                         })
//
//                   ],
//                 ),
//               ),
//             ),
//
//             Container(height: logic1.isKeyboardVisible?0: hi/60,)
//           ],
//         ),
//       );
//     });
//   }
// }























import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../widget/TextFormFiled.dart';
import '../Getx/GetXaddImageAndVideo.dart';
import '../Getx/GetxSendMassage.dart';

class FunctionOfMessagesSendAndWrite extends StatelessWidget {
  final TextEditingController messageController;
  final String uid;
  final FocusNode focusNode = FocusNode();

  FunctionOfMessagesSendAndWrite({super.key, required this.messageController, required this.uid});

  @override
  Widget build(BuildContext context) {
    final double screenHeight = MediaQuery.of(context).size.height;
    final double screenWidth = MediaQuery.of(context).size.width;

    return GetBuilder<GetxSendMessage>(
      init: GetxSendMessage(messageController: messageController, uid: uid),
      builder: (logic1) {
        return Column(
          children: [
            // الحقل السفلي لإرسال الرسائل والصور والفيديوهات
            Container(
              width: screenWidth,
              height: screenHeight / 19,
              decoration: BoxDecoration(
                color: logic1.isRecord ? Colors.black26 : Colors.black12,
                border: const Border(top: BorderSide(color: Colors.black87, width: 0.5)),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 15),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // حقل إدخال النص
                    if (!logic1.isRecord)
                      GetBuilder<GetxSendMessage>(
                        builder: (logic) {
                          return TextFormFiled2(
                            controller: logic.messageController,
                            borderRadius: 20,
                            fontSize: screenWidth / 29,
                            textInputType: TextInputType.multiline,
                            label: '',
                            onChange: (val) {
                              logic.update();
                            },
                            obscure: false,
                            width: screenWidth / 1.5,
                            height: screenHeight / 20,
                          );
                        },
                      ),

                    const SizedBox(width: 5),

                    // زر إضافة صورة أو فيديو
                    if (!logic1.isRecord)
                      GetBuilder<GetxAddImageAndVideo>(
                        init: GetxAddImageAndVideo(uid: uid),
                        builder: (val) {
                          return GestureDetector(
                            onTap: () => val.showMediaOptions(screenHeight, screenWidth, context),
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.black12,
                                borderRadius: BorderRadius.circular(19),
                              ),
                              width: screenWidth / 11,
                              height: screenHeight / 25,
                              child: Icon(Icons.add, size: screenWidth / 12),
                            ),
                          );
                        },
                      ),

                    const SizedBox(width: 5),

                    // زر الإرسال أو تسجيل الصوت
                    GestureDetector(
                      onTap: logic1.isRecord
                          ? null
                          : () {
                        logic1.sendMessage();
                      },
                      onLongPressStart: (val) {
                        if (logic1.elapsedTime == 0) {
                          logic1.startRecording(val, screenWidth, context);
                        }
                      },

                      onLongPressEnd: (val) => logic1.stopRecording(val, screenWidth),
                      onLongPressMoveUpdate: (val) => logic1.updateOnMove(val, screenWidth),
                      child: _buildActionButton(logic1, screenWidth, screenHeight),
                    ),
                  ],
                ),
              ),
            ),
            // إضافة مساحة فارغة أسفل عند إخفاء لوحة المفاتيح
            Container(height: logic1.isKeyboardVisible ? 0 : screenHeight / 60),
          ],
        );
      },
    );
  }

  /// إنشاء زر الإجراءات: إرسال أو تسجيل الصوت
  Widget _buildActionButton(GetxSendMessage logic, double screenWidth, double screenHeight) {
    return Container(
      decoration: BoxDecoration(
        color: logic.isRecord ? Colors.transparent : Colors.blueAccent,
        borderRadius: BorderRadius.circular(19),
      ),
      width: logic.isRecord ? screenWidth / 1.5 : screenWidth / 11,
      height: logic.isRecord ? screenHeight / 20 : screenHeight / 25,
      child: logic.isRecord
          ? Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const SizedBox(width: 20),
          logic.isDelete  ==true
              ? Container()
              : Icon(
            Icons.delete_forever,
            color: logic.isGreen ? Colors.green : Colors.yellow,
            size: screenWidth / 13,
          ),
          Text('تمرير للإلغاء', style: TextStyle(fontSize: screenWidth / 33)),
          Icon(Icons.mic, color: Colors.redAccent, size: screenWidth / 10),
        ],
      )
          : Center(
        child: logic.messageController.text.isEmpty
            ? logic.isSending?CircularProgressIndicator(): Icon(Icons.mic, color: Colors.white)
            : Icon(Icons.send_rounded, color: Colors.white, size: screenWidth / 21),
      ),
    );
  }
}

