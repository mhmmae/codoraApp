
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';
import '../../../../XXX/xxx_firebase.dart';
import '../../../controler/local-notification-onroller.dart';
import 'UploadVoisMessage.dart';

class GetxSendMessage extends GetxController {
  final TextEditingController messageController;
  TextEditingController TheMesage =TextEditingController();
  final String uid;
  BuildContext? context;
  bool isKeyboardVisible = false;
  bool isRecord = false;
  bool isSending = false;

  // التحكم بحالة الحذف أو الإلغاء
  bool isGreen = true;
  bool isYellow = false;
  bool isDelete = false;

  String? filePath;
  int elapsedTime = 0; // الوقت المنقضي
  int minutes = 0;
  int seconds = 0;

  Offset startOffset = Offset.zero;
  Offset currentOffset = Offset.zero;

  Timer? timer;

  final AudioRecorder recorder = AudioRecorder();

  GetxSendMessage({required this.messageController, required this.uid, this.context});

  /// التحقق من صلاحيات التسجيل الصوتي
  Future<bool> _checkMicrophonePermission() async {
    if (!await Permission.microphone.isGranted) {
      final status = await Permission.microphone.request();
      return status == PermissionStatus.granted;
    }
    return true;
  }

  /// تحديث الوضع أثناء السحب
  void updateOnMove(LongPressMoveUpdateDetails details, double width) {
    if (messageController.text.isEmpty) {
      currentOffset = details.globalPosition;

      if (currentOffset.dx - startOffset.dx < -width / 6) {
        isDelete = true;
        isGreen = false;
        isYellow = false;
      } else if (currentOffset.dx - startOffset.dx < -width / 8 &&
          currentOffset.dx - startOffset.dx > -width / 6) {
        isDelete = false;
        isGreen = false;
        isYellow = true;
      } else if (currentOffset.dx - startOffset.dx < -width / 10 &&
          currentOffset.dx - startOffset.dx > -width / 8) {
        isGreen = true;
        isYellow = false;
      }
      update();
    }
  }

  /// إيقاف التسجيل الصوتي
  Future<void> stopRecording(LongPressEndDetails details, double width) async {
    if (messageController.text.isEmpty) {
      if (currentOffset.dx == 0.0) {

        _finalizeRecording();
      }
         if (currentOffset.dx - startOffset.dx < -width / 1000000000) {
     if (currentOffset.dx - startOffset.dx > -width / 6) {
       _finalizeRecording();

     }}
       if  (currentOffset.dx - startOffset.dx < -width / 6 &&
             currentOffset.dx != 0.0) {

           // إلغاء التسجيل
        timer?.cancel();
        elapsedTime = 0;
        isDelete = false;
        minutes = 0;
        seconds = 0;
        await recorder.stop();
        isRecord = false;
        update();
      }
    }
  }




  /// بدء التسجيل الصوتي
  Future<void> startRecording(LongPressStartDetails details, double width, BuildContext context) async {
    try {
      startOffset = details.globalPosition;

      if (messageController.text.isEmpty) {
        final hasPermission = await _checkMicrophonePermission();
        if (!hasPermission) {
          Get.defaultDialog(
            title: 'الرجاء إعطاء الإذن لاستخدام الصوت',
            textCancel: 'إلغاء',
            onCancel: () => Navigator.pop(context),
            textConfirm: 'موافق',
            onConfirm: () => Permission.microphone.request(),
          );
          return;
        }

        if (elapsedTime == 0) {
          timer = Timer.periodic(const Duration(seconds: 1), (timer) {
            elapsedTime++;
            seconds++;
            if (seconds == 60) {
              minutes++;
              seconds = 0;
            }
            update();
          });
        }

        final path = await getApplicationDocumentsDirectory();
        filePath = '${path.path}/audio_record.aac';

        await recorder.start(
          RecordConfig(),
          path: filePath!,
        );

        isRecord = true;
        isDelete = false;
        update();
      }
    } catch (e) {
      debugPrint('Error starting recording: $e');
    }
  }

  /// إنهاء التسجيل الصوتي
  Future<void> _finalizeRecording() async {
    try {
      timer?.cancel();

      minutes = 0;
      seconds = 0;
      await recorder.stop();
      isRecord = false;
      update();

      if (elapsedTime > 0) {
        isSending = true;
        await uplodeVoisMessage().upLodeMessageVoisToFirebse(uid, filePath!);
        elapsedTime = 0;
        isSending = false;
        update();
      }
    } catch (e) {
      debugPrint('Error finalizing recording: $e');
    }
  }

  /// إرسال رسالة نصية
  Future<void> sendMessage() async {
    try {
      if (messageController.text.isNotEmpty) {
        final messageText = messageController.text;
        messageController.clear();

        final messageId = Uuid().v1();

        // إرسال الرسالة إلى Firestore

        final Map<String, dynamic> messageData = {
          'sender':  FirebaseAuth.instance.currentUser!.uid,
          'resiveID':uid,
          'message': messageText,
          'uidMassege': messageId,
          'type': 'text',
          'time': DateTime.now(),
          'isRead' :false,
          'messageId':messageId
        };


        final Map<String, dynamic> messageData2 = {
          'sender': uid,
          'resiveID': FirebaseAuth.instance.currentUser!.uid,
          'message': messageText,
          'uidMassege': messageId,
          'type': 'text',
          'time': DateTime.now(),
          'isRead' :false,
          'messageId':messageId
        };

        await FirebaseFirestore.instance.collection('Chat')
              .doc(FirebaseAuth.instance.currentUser!.uid).collection('chat')
              .doc(uid).collection('messages').doc(messageId).set(messageData).then((value) => FirebaseFirestore.instance.collection('Chat')
              .doc(FirebaseAuth.instance.currentUser!.uid).collection('chat')
              .doc(uid).set(messageData2));





          await FirebaseFirestore.instance.collection('Chat')
              .doc(uid).collection('chat')
              .doc(FirebaseAuth.instance.currentUser!.uid).collection('messages').doc(messageId).set(messageData).then((value) => FirebaseFirestore.instance.collection('Chat')
              .doc(uid).collection('chat')
              .doc(FirebaseAuth.instance.currentUser!.uid).set(messageData));


        // إرسال إشعار
        FirebaseFirestore.instance.collection(FirebaseX.collectionApp).doc(FirebaseAuth.instance.currentUser!.uid).get().then((name) async {
          FirebaseFirestore.instance.collection(FirebaseX.collectionApp).doc(uid).get().then((receiver) async {
            await LocalNotification.sendNotificationMessageToUser(
              to: receiver.get('token'),
              title: name.get('name'),
              body: 'لديك رسالة نصية جديدة',
              uid: uid,
              type: 'text',
              image: '',
            );
          });
        });
      }
    } catch (e) {
      debugPrint('Error sending message: $e');
    }
  }

  @override
  void onInit() {
    KeyboardVisibilityController().onChange.listen((bool visible) {
      isKeyboardVisible = visible;
      update();
    });
    super.onInit();
  }
}
