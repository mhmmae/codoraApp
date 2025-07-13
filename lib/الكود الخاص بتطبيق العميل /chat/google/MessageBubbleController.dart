// message_bubble_controller.dart
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'ChatController.dart'; // لـ setQuotedMessage
import 'Message.dart';      // لـ Message object

class MessageBubbleController extends GetxController with GetSingleTickerProviderStateMixin {
  final Message message;
  final String chatPartnerId; // نحتاجه لنجد الـ ChatController الصحيح

  // Rx Variables لحالة السحب
  final RxDouble dragExtent = 0.0.obs;
  final RxBool canReply = false.obs;

  // Animation Controller للعودة السلسة
  late AnimationController slideAnimationController;
  late Animation<Offset> slideAnimation;

  // العتبات (يمكن جعلها قابلة للتعديل إذا أردت)
  final double replyThreshold = 60.0;
  final double maxDragExtentForIcon = 70.0; // المسافة القصوى التي تتحرك فيها الفقاعة لرؤية الأيقونة بشكل كامل

  // معرفة اتجاه السحب الصحيح بناءً على isMe
  bool get _shouldDragLeft => message.isMe; // إذا كانت رسالتي، أسحبها لليسار

  MessageBubbleController({required this.message, required this.chatPartnerId});

  @override
  void onInit() {
    super.onInit();
    slideAnimationController = AnimationController(
      vsync: this, // GetSingleTickerProviderStateMixin
      duration: const Duration(milliseconds: 200), // مدة الأنيميشن
    );
    // نهيئ الأنيميشن مبدئيًا ولكن سيتم تحديثها عند انتهاء السحب
    slideAnimation = Tween<Offset>(begin: Offset.zero, end: Offset.zero).animate(
        CurvedAnimation(parent: slideAnimationController, curve: Curves.easeOut));

    slideAnimationController.addStatusListener(_onSlideAnimationStatusChanged);
  }

  void _onSlideAnimationStatusChanged(AnimationStatus status) {
    if (status == AnimationStatus.completed) {
      // بعد اكتمال الأنيميشن، أعد تعيين حالة السحب
      dragExtent.value = 0.0;
      canReply.value = false;
      // slideAnimationController.reset(); // ليس ضروريًا دائمًا، Forward(from:0) يعيد ضبطه
    }
  }

  void handleDragUpdate(DragUpdateDetails details) {
    double currentDrag = dragExtent.value;
    double delta = 0;

    if (_shouldDragLeft) {
      if (details.delta.dx < 0) {
        delta = details.delta.dx;
      } else if (details.delta.dx > 0 && currentDrag < 0) delta = details.delta.dx;
    } else {
      if (details.delta.dx > 0) {
        delta = details.delta.dx;
      } else if (details.delta.dx < 0 && currentDrag > 0) delta = details.delta.dx;
    }

    // اسمح بالسحب أبعد قليلاً من عتبة ظهور الأيقونة لإعطاء إحساس طبيعي أكثر
    final double maxAllowedDrag = maxDragExtentForIcon * 1.3;
    currentDrag += delta;

    if (_shouldDragLeft) {
      dragExtent.value = currentDrag.clamp(-maxAllowedDrag, 0);
    } else {
      dragExtent.value = currentDrag.clamp(0, maxAllowedDrag);
    }
    canReply.value = dragExtent.value.abs() >= replyThreshold;
  }


  void handleDragEnd(DragEndDetails details) {
    if (canReply.value) {
      // مهم: ابحث عن ChatController باستخدام Tag لضمان أنك تستدعي المتحكم الصحيح
      final ChatController chatController = Get.find<ChatController>(tag: chatPartnerId);
      if (kDebugMode) debugPrint("Swipe to reply by GetX Controller for message: ${message.messageId}");
      chatController.setQuotedMessage(message);
    }

    final currentOffsetPixels = dragExtent.value;
    slideAnimation = Tween<Offset>(begin: Offset(currentOffsetPixels, 0), end: Offset.zero)
        .animate(CurvedAnimation(parent: slideAnimationController, curve: Curves.easeOutQuart));
    slideAnimationController.forward(from: 0.0);
  }

  void handleDragCancel() {
    if (dragExtent.value != 0) {
      final currentOffsetPixels = dragExtent.value;
      slideAnimation = Tween<Offset>(begin: Offset(currentOffsetPixels, 0), end: Offset.zero)
          .animate(CurvedAnimation(parent: slideAnimationController, curve: Curves.easeOutQuart));
      slideAnimationController.forward(from: 0.0);
    } else {
      canReply.value = false;
    }
  }


  double get visualDragOffsetForBubble {
    // الحد من إزاحة الفقاعة المرئية إلى _maxDragExtentForIcon لإبقاء أيقونة الرد ظاهرة
    if (_shouldDragLeft) {
      return dragExtent.value.clamp(-maxDragExtentForIcon, 0.0);
    } else {
      return dragExtent.value.clamp(0.0, maxDragExtentForIcon);
    }
  }

  // الشفافية وحجم أيقونة الرد
  double get replyIconOpacity => (dragExtent.value.abs() / replyThreshold).clamp(0.2, 0.8);
  double get replyIconSize => 22 + (dragExtent.value.abs() / replyThreshold * 8).clamp(0, 8);
  // لتوفير الإزاحة المرئية الصحيحة بناءً على اتجاه السحب
  // هذا قد لا يكون ضروريًا إذا كان SlideTransition سيتولى كل التحريك
  // ولكننا نستخدم Transform.translate مبدئيًا للسحب اليدوي
  double get visualDragOffset {
    // هذه الدالة تعكس _dragExtent لرسائلي (isMe) لأننا نحسب _dragExtent ليكون
    // موجبًا دائمًا للسحب لليمين (رسائل الآخرين) وسالبًا دائمًا للسحب لليسار (رسائلي).
    // لكن Transform.translate يتوقع قيمًا حيث السالب لليسار والموجب لليمين.
    // في handleDragUpdate:
    // dragExtent.value بالفعل سيكون سالبًا لرسائلي، وموجبًا لرسائل الآخرين
    return dragExtent.value;
  }


  @override
  void onClose() {
    slideAnimationController.removeStatusListener(_onSlideAnimationStatusChanged);
    slideAnimationController.dispose();
     if (kDebugMode) debugPrint("MessageBubbleController for ${message.messageId} closed.");
    super.onClose();
  }
}