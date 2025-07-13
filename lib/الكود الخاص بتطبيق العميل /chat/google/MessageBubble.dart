import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:get/get.dart';
import 'package:flutter/foundation.dart'; // لـ kDebugMode
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:path/path.dart' as p; // تأكد من وجود الاستيراد
import 'package:url_launcher/url_launcher.dart';

import 'AudioMessageWidget.dart';
import 'ChatController.dart';
import 'FirestoreConstants.dart';
import 'Helpers.dart';
import 'Message.dart';
import 'MessageBubbleController.dart';
import 'MessageStatus.dart';
import 'ViewMediaScreen.dart'; // لـ File للصور المحلية

class MessageBubble extends StatelessWidget {
  // --- استقبال كائن Message بدلاً من Map ---
  final Message message;
  // --- دوال Callback لإعادة المحاولة والتنزيل ---
  final VoidCallback? onRetrySend;
  final VoidCallback? onRetryDownload;
  final VoidCallback? onDownloadMedia; // لبدء التنزيل يدوياً
  final String chatPartnerId;

  const MessageBubble({
    super.key,
    required this.message,
    required this.chatPartnerId, // <-- إلزامي
    this.onRetrySend,
    this.onRetryDownload,
    this.onDownloadMedia,
  });
  EdgeInsets _getBubblePadding() {
    // إذا كانت وسائط، لا تحتاج لحشو كبير، الوسائط ستملأ الفقاعة (تقريبًا)
    if (message.type == FirestoreConstants.typeImage || message.type == FirestoreConstants.typeVideo) {
      return const EdgeInsets.all(3.0); // حشو صغير جدًا للظل والحواف
    } else if (message.type == FirestoreConstants.typeAudio) {
      return const EdgeInsets.symmetric(horizontal: 8, vertical: 6);
    }
    // الحشو الافتراضي للرسائل النصية
    return const EdgeInsets.symmetric(horizontal: 12, vertical: 10);
  }


  @override
  Widget build(BuildContext context) {
    final MessageBubbleController bubbleController = Get.put(
      MessageBubbleController(message: message, chatPartnerId: chatPartnerId),
      tag: message.messageId,
    );

    final isMe = message.isMe;
    final ChatController chatController = Get.find<ChatController>(tag: chatPartnerId);
    final BorderRadius bubbleRadius = BorderRadius.only(
      topLeft: const Radius.circular(12), // حواف أقل حدة قليلاً
      topRight: const Radius.circular(12),
      bottomLeft: isMe ? const Radius.circular(12) : const Radius.circular(4),
      bottomRight: isMe ? const Radius.circular(4) : const Radius.circular(12),
    );
    final EdgeInsets bubbleContentPadding = _getBubblePadding();

    // إذا كانت وسائط، الفقاعة نفسها ستأخذ شكل الوسائط.
    // إذا نص، ستأخذ حجم النص + الحشو.
    final bool isMedia = message.type == FirestoreConstants.typeImage || message.type == FirestoreConstants.typeVideo;
    final EdgeInsets contentPadding = _getContentPadding(message.type);

    Widget messageContentColumn = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        if (message.quotedMessageId != null && message.quotedMessageId!.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 4, 4, 0), // توحيد الحشو للجزء المقتبس
            child: _buildQuotedMessageDisplay(context, chatController),
          ),
        Padding(
          padding: contentPadding, // استخدام الحشو المحدد
          child: _buildMainMessageContent(context),
        ),
        if (message.type == FirestoreConstants.typeText && message.linkPreviewData != null)
          Padding(
            // إضافة حشو حول معاينة الرابط ليفصلها عن النص والوقت
            padding: const EdgeInsets.only(
                left: 10, right: 10, top: 4, bottom: 2),
            child: _buildLinkPreview(context, message.linkPreviewData!), // <--- استدعاء هنا
          ),
        if (message.type == FirestoreConstants.typeText || message.type == FirestoreConstants.typeAudio)
          Padding(
            padding: EdgeInsets.only(
              right: isMe ? 8 : (message.type == FirestoreConstants.typeAudio ? 6 : 10), // تعديل بسيط للحشو ليناسب الصوت
              left: !isMe ? 8 : (message.type == FirestoreConstants.typeAudio ? 6 : 10),
              bottom: 5, // ضبط الهامش السفلي
              top: message.type == FirestoreConstants.typeAudio ? 3 : 0, // مسافة أعلى قليلاً قبل وقت الصوت
            ),
            child: _buildStatusAndTimestampRow(context),
          ),


      ],
    );


    return GestureDetector(
      onHorizontalDragUpdate: bubbleController.handleDragUpdate,
      onHorizontalDragEnd: bubbleController.handleDragEnd,
      onHorizontalDragCancel: bubbleController.handleDragCancel,
      behavior: HitTestBehavior.opaque,
      child: Obx(
            () => Stack(
          alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
          children: [
            // أيقونة الرد
            if ((isMe && bubbleController.dragExtent.value < -5) || (!isMe && bubbleController.dragExtent.value > 5))
              Positioned
                  .fill( // يملأ المساحة ليتمكن المستخدم من النقر عليه بسهولة
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.4),
                    // تعتيم خفيف
                    borderRadius: bubbleRadius,
                  ),
                  child: Center(
                    child: IconButton(
                      icon: const Icon(Icons.refresh_rounded,
                          color: Colors.white),
                      iconSize: 30,
                      tooltip: message.status ==
                          MessageStatus.failed
                          ? 'إعادة محاولة الإرسال'
                          : 'إعادة محاولة التنزيل',
                      onPressed: message.status ==
                          MessageStatus.failed
                          ? onRetrySend // استدعاء callback المرسل
                          : onRetryDownload,
                    ),
                  ),
                ),
              ),

            SlideTransition(
              position: bubbleController.slideAnimation,
              child: Transform.translate(
                offset: Offset(bubbleController.visualDragOffsetForBubble, 0),
                child: Align(
                  alignment: isMe ? Alignment.topRight : Alignment.topLeft, // محاذاة الفقاعة للأعلى
                  child: GestureDetector(
                    onLongPress: () {
                      if (message.type != FirestoreConstants.typeDeleted) { // لا تظهر خيارات لرسالة محذوفة
                        _showMessageOptions(context, message, chatController);
                      }
                    },
                    child: Container(
                      constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.78),
                      margin: const EdgeInsets.symmetric(vertical: 2.5, horizontal: 8),
                      decoration: BoxDecoration(
                        color: _getBubbleColor(context, isMe, message.type), // يمرر النوع لتحديد إذا كانت وسائط
                        borderRadius: bubbleRadius,
                        boxShadow: [
                          BoxShadow(
                            offset: const Offset(0.5, 1.0), // تعديل الظل ليكون أدق
                            blurRadius: 1.0,
                            color: Colors.black.withOpacity(0.18), // زيادة طفيفة في وضوح الظل
                          )
                        ],
                      ),
                      child: isMedia
                          ? ClipRRect(borderRadius: bubbleRadius, child: messageContentColumn) // الوسائط تحتاج ClipRRect على العمود
                          : messageContentColumn, // النص والصوت لا يحتاجان ClipRRect إضافي هنا
                    ),
                  ),
                ),
              ),
            ),

            // وضع الوقت والحالة كـ Overlay فقط إذا كانت وسائط (صور/فيديو)
            if (isMedia)
              Positioned(
                bottom: 6, // ضبط ليكون أقرب للحافة السفلية
                right: isMe ? (bubbleRadius.bottomRight.x > 10 ? 10 : 7) : null, // مراعاة الـ "ذيل"
                left: !isMe ? (bubbleRadius.bottomLeft.x > 10 ? 10 : 7) : null,
                child: _buildStatusAndTimestampRow(context),
              ),

            // زر إعادة المحاولة يجب أن يكون فوق كل شيء
            if (message.status == MessageStatus.failed || message.status == MessageStatus.downloadFailed)
              Positioned
                  .fill( // يملأ المساحة ليتمكن المستخدم من النقر عليه بسهولة
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.4),
                    // تعتيم خفيف
                    borderRadius: bubbleRadius,
                  ),
                  child: Center(
                    child: IconButton(
                      icon: const Icon(Icons.refresh_rounded,
                          color: Colors.white),
                      iconSize: 30,
                      tooltip: message.status ==
                          MessageStatus.failed
                          ? 'إعادة محاولة الإرسال'
                          : 'إعادة محاولة التنزيل',
                      onPressed: message.status ==
                          MessageStatus.failed
                          ? onRetrySend // استدعاء callback المرسل
                          : onRetryDownload,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }


  Color _getBubbleColor(BuildContext context, bool isMe, String messageType) {
    if (messageType == FirestoreConstants.typeImage || messageType == FirestoreConstants.typeVideo) {
      // للوسائط، عادةً لا يكون هناك لون خلفية واضح للفقاعة نفسها،
      // بل الوسيط يملأها. يمكن أن نضع لونًا خفيفًا للظل أو إذا كان هناك إطار.
      return Colors.transparent; // أو لون خفيف جدًا مثل Colors.grey.shade200.withOpacity(0.3);
    }
    // ألوان شبيهة بواتساب
    return isMe ? const Color(0xFFDCF8C6) : Colors.white;
  }


  EdgeInsets _getContentPadding(String messageType) {
    if (messageType == FirestoreConstants.typeImage || messageType == FirestoreConstants.typeVideo) {
      return EdgeInsets.zero; // لا حشو داخلي للوسائط، ستملأ الفقاعة
    } else if (messageType == FirestoreConstants.typeAudio) {
      return const EdgeInsets.only(left: 8, right: 8, top: 7, bottom: 7); // تعديل طفيف
    }
    // الحشو الافتراضي للنص
    return const EdgeInsets.only(left: 10, right: 10, top: 8, bottom: 6);
  }


  // --- إعادة كتابة _buildQuotedMessageDisplay بشكل احترافي وجذاب ---
Widget _buildQuotedMessageDisplay(BuildContext context, ChatController chatController,) {
  // ... (نفس كود _buildQuotedMessageDisplay الذي قمت بتحسينه سابقًا)
  // تأكد من أنه يعتمد على this.message بدلاً من متغير خارجي
  final theme = Theme.of(context);
  final String? quotedSenderId = message.quotedMessageSenderId;
  final String? quotedText = message.quotedMessageText;

  if (quotedSenderId == null || quotedText == null) return const SizedBox.shrink();

  String displayName; Color quotedSenderColor;
  if (quotedSenderId == chatController.currentUserId) {
    displayName = "أنت";
    quotedSenderColor = message.isMe ? Colors.teal.shade700 : Colors.orange.shade700;
  } else if (quotedSenderId == chatController.recipientId) {
    displayName = chatController.recipientName;
    quotedSenderColor = theme.primaryColorDark;
  } else {
    displayName = "مستخدم"; // أو جلب الاسم
    quotedSenderColor = theme.textTheme.bodySmall?.color ?? Colors.grey;
  }

  return GestureDetector(
    onTap: () {
      if (kDebugMode) debugPrint("Tapped quoted part. Quoted Msg ID: ${message.quotedMessageId}");
      // TODO: Implement scroll to original quoted message
      // chatController.scrollToMessage(message.quotedMessageId!);
    },
    child: Container(
      margin: const EdgeInsets.only(bottom: 4.0), // هامش سفلي قبل الرسالة الرئيسية
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: (message.isMe ? Colors.green.shade50 : Theme.of(context).colorScheme.secondaryContainer.withOpacity(0.3)),
        borderRadius: const BorderRadius.all(Radius.circular(10)), // حواف أكثر استدارة للجزء المقتبس
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(width: 3.5, height: 32, decoration: BoxDecoration(color: quotedSenderColor.withOpacity(0.7), borderRadius: BorderRadius.circular(2)), margin: const EdgeInsets.only(right: 8.0)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(displayName, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: quotedSenderColor), maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 1.5),
                Text(quotedText, style: TextStyle(fontSize: 12.5, color: (theme.textTheme.bodySmall?.color ?? Colors.black).withOpacity(0.85)), maxLines: 2, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}


// --- [جديد] دالة لبناء ActionPane للرد مع Slidable ---
  ActionPane _buildReplyActionPane(BuildContext context, ChatController controller, Message message, bool isStartAction) {
    return ActionPane(
      motion: const BehindMotion(), // أو StretchMotion() أو غيرها
      extentRatio: 0.25, // مقدار ما يمكن سحبه (25% من عرض الفقاعة)
      children: [
        SlidableAction(
          onPressed: (context) {
            controller.setQuotedMessage(message);
          },
          backgroundColor: Theme.of(context).primaryColor.withOpacity(0.2),
          foregroundColor: Theme.of(context).primaryColor,
          icon: Icons.reply_rounded,
          // يمكنك إزالة النص إذا كانت الأيقونة كافية
          // label: 'رد',
        ),
      ],
      // لتغيير الاتجاه إذا أردت أيقونة السهم تظهر من الجهة الأخرى
      // openमंत्रaвлез: isStartAction ? ActionPaneOpenedमंत्रaвлез.start : ActionPaneOpenedमंत्रaвлез.end,
    );
  }







// --- [جديد] دالة لبناء الجزء المقتبس في الرسالة التي هي رد ---
  Widget _buildQuotedMessageContent(BuildContext context, Message currentMessage) {
    final theme = Theme.of(context);
    // افترض أن هذه الأسماء موجودة. إذا لا، ستحتاج لجلبها أو تمريرها
    final String quotedSenderName = currentMessage.isMe
        ? "أنت" // إذا كنت ترد على رسالة من الطرف الآخر، فـ quotedMessageSenderId هو الطرف الآخر
        : Get.find<ChatController>(tag: currentMessage.senderId).recipientName; // إذا كان الطرف الآخر يرد على رسالتك.
    // هذا يحتاج لضبط. الأفضل أن يتم تخزين اسم مرسل الرسالة المقتبسة

    // لتحديد اسم مرسل الرسالة *الأصلية المقتبسة*:
    // إذا كانت الرسالة الحالية `currentMessage.isMe == true` (أرسلتها أنا)،
    // و هي رد على رسالة من `currentMessage.quotedMessageSenderId` (وهو الطرف الآخر)،
    // إذن `quotedSenderNameToDisplay` يجب أن يكون اسم الطرف الآخر.
    // إذا كانت `currentMessage.isMe == false` (استلمتها أنا)،
    // وهي رد من الطرف الآخر على رسالة أرسلتها أنا (`currentMessage.quotedMessageSenderId == myId`)
    // إذن `quotedSenderNameToDisplay` يجب أن يكون "أنت".
    // أو إذا رد الطرف الآخر على رسالة أرسلها هو نفسه (نادر ولكن ممكن إذا كان يرد على رسالته هو في مجموعة مثلاً)

    String quotedSenderNameToDisplay = "طرف آخر"; // افتراضي
    final String myUserId = Get.find<ChatController>(tag: currentMessage.isMe ? currentMessage.recipientId : currentMessage.senderId).currentUserId;

    if (currentMessage.quotedMessageSenderId == myUserId) {
      quotedSenderNameToDisplay = "أنت";
    } else if (currentMessage.quotedMessageSenderId == (currentMessage.isMe ? currentMessage.recipientId : currentMessage.senderId) ) {
      // quotedMessageSenderId هو الطرف الآخر
      quotedSenderNameToDisplay = Get.find<ChatController>(tag: currentMessage.isMe ? currentMessage.recipientId : currentMessage.senderId).recipientName;
    }
    // قد تحتاج لمنطق أكثر دقة إذا كنت تجلب أسماء المستخدمين

    String previewText = currentMessage.quotedMessageText ?? "";
    if (previewText.isEmpty) { // إذا لم يتم تخزين نص المعاينة للوسائط
      if (currentMessage.type == FirestoreConstants.typeImage) {
        previewText = '📷 صورة';
      } else if (currentMessage.type == FirestoreConstants.typeVideo) previewText = '📹 فيديو';
      else if (currentMessage.type == FirestoreConstants.typeAudio) previewText = '🎤 رسالة صوتية';
      else previewText = 'رسالة سابقة';
    }


    return Positioned(
      top: 0, left: 0, right: 0,
      child: GestureDetector(
        onTap: () {
          // TODO: تمرير للانتقال إلى الرسالة الأصلية المقتبسة
          // final chatController = Get.find<ChatController>(tag: ...);
          // chatController.scrollToMessage(currentMessage.quotedMessageId!);
          if (kDebugMode) debugPrint("User tapped on quoted message part. ID: ${currentMessage.quotedMessageId}");
        },
        child: Container(
          margin: const EdgeInsets.only(left: 3, right: 3, top: 3, bottom: 0), // هوامش داخلية للفقاعة
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
          decoration: BoxDecoration(
            color: theme.colorScheme.secondary.withOpacity(0.15), // لون خلفية أفتح قليلاً
            borderRadius: const BorderRadius.only( // حواف مستديرة علوية فقط
              topLeft: Radius.circular(12),
              topRight: Radius.circular(12),
            ),
            // يمكنك إضافة خط عمودي هنا إذا أردت
            // border: Border(left: BorderSide(color: theme.primaryColor, width: 3)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // خط عمودي (اختياري)
              Container(width: 3, height: 35, color: currentMessage.isMe ? Colors.green.shade600 : theme.primaryColor, margin: const EdgeInsets.only(right: 6, left: 2)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      quotedSenderNameToDisplay, // اسم مرسل الرسالة المقتبسة
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12.5,
                        color: currentMessage.isMe ? Colors.green.shade700 : theme.primaryColorDark,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      previewText, // جزء من نص الرسالة المقتبسة أو وصف الوسائط
                      style: TextStyle(fontSize: 12, color: theme.textTheme.bodySmall?.color?.withOpacity(0.8)),
                      maxLines: 1, // أو سطرين كحد أقصى
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );}





  Widget _buildMainMessageContent(BuildContext context) {
    Color textColor = message.isMe ? Colors.black.withOpacity(0.87) : Theme.of(context).colorScheme.onSurface;
    // للوسائط، هذا اللون سيستخدم لعناصر التحكم أو الأيقونات فوقها إن وجدت
    if (message.type == FirestoreConstants.typeImage || message.type == FirestoreConstants.typeVideo) {
      textColor = Colors.white;
    }

    if (message.type == FirestoreConstants.typeDeleted) { // <--- [جديد] التعامل مع الرسالة المحذوفة
      return Text(
        FirestoreConstants.deletedMessageContent,
        style: TextStyle(
          fontSize: 14,
          fontStyle: FontStyle.italic,
          color: textColor.withOpacity(0.6),
        ),
      );
    }

    switch (message.type) {
      case FirestoreConstants.typeText:
        return  _buildTextWithLinks(context, message.content, textColor);
      case FirestoreConstants.typeImage:
      return _buildImageContent(context); // يجب أن تكون هذه الدالة مكتملة لديك
      case FirestoreConstants.typeVideo:
      return _buildVideoContent(context); // يجب أن تكون هذه الدالة مكتملة لديك
      case FirestoreConstants.typeAudio:
      // تأكد أن AudioMessageWidget يتناسب مع الألوان الجديدة
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4.0), // تعديل ليتناسب مع الفقاعة
          child: AudioMessageWidget(
            remoteAudioUrl: message.content,
            isMe: message.isMe,
            messageId: message.messageId,
            localAudioFileName: message.localFilePath,
          ),
        );
      default:
        return Text("Unsupported type", style: TextStyle(color: Colors.red.shade300, fontStyle: FontStyle.italic));
    }
  }

// --- [جديد] دالة لبناء النص مع الروابط القابلة للنقر ---
  Widget _buildTextWithLinks(BuildContext context, String text, Color defaultColor) {
    final List<TextSpan> spans = [];
    final theme = Theme.of(context);
    final Color linkColor = theme.primaryColor; // أو Colors.blue

    // تعبير نمطي بسيط لاكتشاف الروابط (يمكن تحسينه ليكون أكثر دقة)
    final RegExp urlRegExp = RegExp(
      r"(?:(?:https?|ftp):\/\/)?[\w/\-?=%.]+\.[\w/\-?=%.]+",
      caseSensitive: false,
    );

    int currentPosition = 0;
    for (final Match match in urlRegExp.allMatches(text)) {
      // النص قبل الرابط
      if (match.start > currentPosition) {
        spans.add(TextSpan(
          text: text.substring(currentPosition, match.start),
          style: TextStyle(fontSize: 15.0, color: defaultColor, height: 1.3),
        ));
      }
      // الرابط نفسه
      final String url = match.group(0)!;
      spans.add(
        TextSpan(
          text: url,
          style: TextStyle(
            fontSize: 15.0,
            color: linkColor, // لون مميز للرابط
            decoration: TextDecoration.underline, // خط سفلي
            decorationColor: linkColor.withOpacity(0.7),
            height: 1.3,
          ),
          recognizer: TapGestureRecognizer()
            ..onTap = () async {
              String launchUrlString = url;
              if (!launchUrlString.startsWith('http://') && !launchUrlString.startsWith('https://')) {
                launchUrlString = 'https://$launchUrlString';
              }
              final uri = Uri.tryParse(launchUrlString);
              if (uri != null) {
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                } else {
                  if (kDebugMode) debugPrint('Could not launch $launchUrlString');
                  Get.snackbar("خطأ", "لا يمكن فتح الرابط: $url", snackPosition: SnackPosition.BOTTOM);
                }
              } else {
                Get.snackbar("خطأ", "رابط غير صالح: $url", snackPosition: SnackPosition.BOTTOM);
              }
            },
        ),
      );
      currentPosition = match.end;
    }
    // النص بعد آخر رابط (إذا وجد)
    if (currentPosition < text.length) {
      spans.add(TextSpan(
        text: text.substring(currentPosition),
        style: TextStyle(fontSize: 15.0, color: defaultColor, height: 1.3),
      ));
    }

    if (spans.isEmpty) { // إذا لم يتم العثور على أي روابط، اعرض النص الأصلي كـ SelectableText
      return SelectableText(
        text,
        style: TextStyle(fontSize: 15.0, color: defaultColor, height: 1.3),
        textAlign: TextAlign.start,
      );
    }

    return RichText(
      text: TextSpan(children: spans),
      textAlign: TextAlign.start, // أو حدد محاذاة مناسبة
    );
  }

  // --- بناء محتوى الرسالة الداخلي ---
  Widget _buildMessageContent(BuildContext context, Color textColor) {
    switch (message.type) {
    // === حالة الصورة ===
      case FirestoreConstants.typeImage:
        return _buildImageContent(context);

    // === حالة الفيديو ===
      case FirestoreConstants.typeVideo:
        return _buildVideoContent(context);

    // === حالة الصوت ===
      case FirestoreConstants.typeAudio:
        return AudioMessageWidget( // استخدام الويدجت المتخصصةش
          remoteAudioUrl: message.content, // URL لا يزال في content للمستقبل قبل التنزيل
          isMe: message.isMe,
          messageId: message.messageId,
          localAudioFileName: message.localFilePath, // مرر المسار المحلي المحفوظ

          // قد تحتاج لتمرير حالة أو مسار محلي إذا عدلت AudioMessageWidget
        );

    // === حالة النص (الافتراضي) ===
      case FirestoreConstants.typeText:
      default:
        return SelectableText(
          message.content,
          style: TextStyle(fontSize: 15, color: textColor),
          // جعل محاذاة النص تعتمد على محتوى النص (يمين للعربي، يسار للإنجليزي) - يتطلب تحليل
          // textAlign: message.isArabic ? TextAlign.right : TextAlign.left, // مثال
          // أو تحديد ثابت
          textAlign: TextAlign.start, // البدء بناءً على لغة الجهاز
          // ترك مساحة إضافية فارغة في نهاية النص لتجنب التداخل مع الوقت
          // هذا أقل أناقة، استخدام Stack/Positioned أفضل
          // + '      ', // حل بسيط (غير محبذ)
        );
    }
  }

  // --- بناء محتوى الصورة مع التحقق من الحالة والمسار المحلي ---
  // --- بناء محتوى الصورة مع التحقق من الحالة والمسار المحلي (النسخة الكاملة والمعدلة) ---
  // --- بناء محتوى الصورة (منقح، يستخدم _buildFullLocalPath و placeholder) ---
  Widget _buildImageContent(BuildContext context) {
    final String? localImageName = message.localFilePath; // اسم الملف المحلي
    final String remoteImageUrl = message.content; // رابط URL (بعد الرفع) أو اسم الملف المحلي (أثناء الرفع)
    final currentStatus = message.status;
    Widget finalWidget;
    Widget overlayWidget = const SizedBox.shrink();

    switch (currentStatus) {
      case MessageStatus.received:
      case MessageStatus.sent:
      case MessageStatus.delivered:
      case MessageStatus.read:
        finalWidget = FutureBuilder<String?>(
          future: _buildFullLocalPath(localImageName), // بناء المسار الكامل للاسم المحلي
          builder: (context, snapshot) {
            final String? fullLocalPath = snapshot.data;
            // عرض المحلي إذا تم بناؤه بنجاح
            if (snapshot.connectionState == ConnectionState.done && fullLocalPath != null) {
              try {
                return Image.file(File(fullLocalPath), key: ValueKey('img_${message.messageId}_local'), fit: BoxFit.cover);
              } catch (e) {
                if (kDebugMode) debugPrint("!!! Error displaying final local image '$fullLocalPath': $e");
                // إذا فشل عرض المحلي، اعرض البعيد أو خطأ
                return _buildRemoteOrPlaceholder(context, remoteImageUrl, isError: true, errorMessage: "خطأ عرض ملف");
              }
            }
            // إذا كان بناء المسار ينتظر أو فشل، أو لا يوجد محلي، اعرض البعيد أو Placeholder
            return _buildRemoteOrPlaceholder(context, remoteImageUrl, isLoading: snapshot.connectionState == ConnectionState.waiting);
          },
        );
        break;
      case MessageStatus.pending:
      case MessageStatus.sending:
        overlayWidget = _buildDownloadIndicator(isUploading: true);
        // اعرض الصورة المحلية مباشرة (يفترض أن المسار المحلي المؤقت تم تخزينه)
        finalWidget = FutureBuilder<String?>(
            future: _buildFullLocalPath(localImageName), // بناء المسار
            builder: (context, snapshot) => _buildImageFromPathOrError(context, snapshot.data)
        );
        break;
      case MessageStatus.downloading:
        overlayWidget = _buildDownloadIndicator();
        finalWidget = _buildRemoteOrPlaceholder(context, remoteImageUrl, isLoading: true);
        break;
      case MessageStatus.downloadFailed:
        overlayWidget = _buildRetryDownloadButton(onRetryDownload);
        finalWidget = _buildRemoteOrPlaceholder(context, remoteImageUrl, isError: true);
        break;
      case MessageStatus.failed:
        overlayWidget = _buildRetrySendButton(onRetrySend);
        finalWidget = FutureBuilder<String?>( // اعرض المحلي كخلفية
            future: _buildFullLocalPath(localImageName),
            builder: (context, snapshot) => _buildImageFromPathOrError(context, snapshot.data)
        );
        break;
      default:
        finalWidget = _buildMediaPlaceholder(context, isError: true, errorMessage: "حالة غير معروفة");
    }

    return GestureDetector(
        onTap: () async => _handleMediaTap(context, localImageName, remoteImageUrl, isVideo: false),
        child: ConstrainedBox(constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.35, minWidth: 150),child:  AspectRatio(
          aspectRatio: 1.0, // نسبة مربعة للصورة افتراضيًا (يمكن تغييرها)
          child: overlayWidget is SizedBox // التحقق إذا كان overlay فارغًا
              ? finalWidget // اعرض الصورة مباشرة
              : Stack( // استخدم Stack لوضع الـ overlay
            fit: StackFit.expand, // جعل الصورة تملأ الـ Stack
            alignment: Alignment.center,
            children: [
              finalWidget, // الصورة (من ملف أو شبكة أو placeholder)
              overlayWidget, // الطبقة العلوية (زر، مؤشر، ...)
            ],
          ),
        ),)
    );
  }





  void _showMessageOptions(BuildContext context, Message message, ChatController chatController) {
    // استخدم showModalBottomSheet أو showMenu
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext bc) {
        List<Widget> options = [];

        // --- خيارات لرسائلي أنا ---
        if (message.isMe) {
          // 1. خيار تعديل الرسالة (فقط للرسائل النصية التي لم يتم حذفها)
          if (message.type == FirestoreConstants.typeText && message.content != FirestoreConstants.deletedMessageContent) {
            options.add(ListTile(
              leading: const Icon(Icons.edit_outlined),
              title: const Text('تعديل'),
              onTap: () {
                Navigator.pop(context); // أغلق الـ bottom sheet
                chatController.startEditMessage(message); // <--- دالة جديدة في ChatController
              },
            ));
          }

          // 2. خيار الرد (موجود بالفعل أو يمكنك إضافته هنا أيضًا)
          options.add(ListTile(
            leading: const Icon(Icons.reply_rounded),
            title: const Text('رد'),
            onTap: () {
              Navigator.pop(context);
              chatController.setQuotedMessage(message);
            },
          ));


          // 3. خيار حذف لدي (متاح دائمًا لرسائلي)
          options.add(ListTile(
            leading: Icon(Icons.delete_outline, color: Theme.of(context).colorScheme.error),
            title: Text('حذف لدي', style: TextStyle(color: Theme.of(context).colorScheme.error)),
            onTap: () {
              Navigator.pop(context);
              _showConfirmDialog(context, "هل تريد بالتأكيد حذف هذه الرسالة لديك فقط؟", () {
                chatController.deleteMessageForMe(message.messageId); // <--- دالة جديدة
              });
            },
          ));

          // 4. خيار حذف لدى الجميع (متاح لرسائلي إذا لم تُحذف بالفعل، وضمن حد زمني معين)
          final Duration timeSinceSent = DateTime.now().difference(message.timestamp.toDate());
          final bool canDeleteForEveryone = timeSinceSent < const Duration(hours: 1); // مثال: ساعة واحدة

          if (message.content != FirestoreConstants.deletedMessageContent && canDeleteForEveryone) {
            options.add(ListTile(
              leading: Icon(Icons.delete_forever_outlined, color: Theme.of(context).colorScheme.error),
              title: Text('حذف لدى الجميع', style: TextStyle(color: Theme.of(context).colorScheme.error)),
              onTap: () {
                Navigator.pop(context);
                _showConfirmDialog(context, "سيتم حذف هذه الرسالة لدى الجميع. هل أنت متأكد؟", () {
                  chatController.deleteMessageForEveryone(message); // <--- دالة جديدة
                });
              },
            ));
          }
        }
        // --- خيارات لرسائل الطرف الآخر ---
        else {
          // 1. خيار الرد
          options.add(ListTile(
            leading: const Icon(Icons.reply_rounded),
            title: const Text('رد'),
            onTap: () {
              Navigator.pop(context);
              chatController.setQuotedMessage(message);
            },
          ));
          // 2. خيار حذف لدي (متاح دائمًا لرسائل الطرف الآخر في صندوقي أنا)
          options.add(ListTile(
            leading: Icon(Icons.delete_outline, color: Theme.of(context).colorScheme.error),
            title: Text('حذف لدي', style: TextStyle(color: Theme.of(context).colorScheme.error)),
            onTap: () {
              Navigator.pop(context);
              _showConfirmDialog(context, "هل تريد بالتأكيد حذف هذه الرسالة لديك فقط؟", () {
                chatController.deleteMessageForMe(message.messageId);
              });
            },
          ));
        }

        return SafeArea(
          child: Wrap(children: options),
        );
      },
    );
  }





  void _showConfirmDialog(BuildContext context, String content, VoidCallback onConfirm) {
    showDialog(
      context: context,
      builder: (BuildContext ctx) {
        return AlertDialog(
          title: const Text('تأكيد'),
          content: Text(content),
          actions: <Widget>[
            TextButton(
              child: const Text('إلغاء'),
              onPressed: () => Navigator.of(ctx).pop(),
            ),
            TextButton(
              style: TextButton.styleFrom(foregroundColor: Theme.of(context).colorScheme.error),
              child: const Text('تأكيد الحذف'),
              onPressed: () {
                Navigator.of(ctx).pop();
                onConfirm();
              },
            ),
          ],
        );
      },
    );
  }










  // --- التعامل الموحد مع نقرة الوسائط ---
  Future<void> _handleMediaTap(BuildContext context, String? localFileName, String remoteUrl, {bool isVideo = false}) async {
    // 1. بناء المسار الكامل ديناميكيًا
    String? fullLocalPath = await _buildFullLocalPath(localFileName);
    // 2. تحديد الأولوية للمحلي
    final bool isSourceActuallyLocal = fullLocalPath != null;
    // 3. تحديد المصدر النهائي
    final String? displaySource = isSourceActuallyLocal ? fullLocalPath : (remoteUrl.isNotEmpty ? remoteUrl : null);

    if (displaySource != null) {
      // 4. الانتقال إلى ViewMediaScreen مع تمرير البيانات الصحيحة
      Get.to(() => ViewMediaScreen(
        imageUrl: isVideo ? null : displaySource,       // مرر null للصورة إذا كان فيديو
        videoUrl: isVideo ? displaySource : null,       // مرر المصدر للفيديو
        isLocalFile: isSourceActuallyLocal,           // حدد نوع المصدر
        // يمكنك إضافة heroTag هنا إذا أردت
        heroTag: message.messageId + (isVideo ? "_video" : "_image"), // Tag مميز
      ));
      }else {
      Get.snackbar("خطأ", "لا يمكن عرض ${isVideo ? 'الفيديو' : 'الصورة'}، الملف أو الرابط غير صالح.", snackPosition: SnackPosition.BOTTOM);
    }
  }


  // --- بناء الصورة من المسار المحلي أو عرض خطأ ---
  Widget _buildImageFromPathOrError(BuildContext context, String? fullPath){
    if(fullPath != null) {
      try{ return Image.file(File(fullPath), key: ValueKey(fullPath), fit: BoxFit.cover); }
      catch(e){ return _buildMediaPlaceholder(context, isError: true, errorMessage: "خطأ تحميل محلي"); }
    } else {
      return _buildMediaPlaceholder(context, isError: true, errorMessage: "ملف محلي غير موجود");
    }
  }


  // --- دالة مساعدة مضافة لعرض الصورة البعيدة أو Placeholder ---
  Widget _buildRemoteOrPlaceholder(BuildContext context, String remoteUrl, {bool isLoading = false, bool isError = false, String? errorMessage}) {
    if (remoteUrl.isNotEmpty && !isError) {
      return CachedNetworkImage(
        imageUrl: remoteUrl,
        fit: BoxFit.cover,
        // تمرير حالة التحميل إلى Placeholder إذا أردت
        placeholder: (context, url) => _buildMediaPlaceholder(context, isLoading: true),
        errorWidget: (context, url, error) => _buildMediaPlaceholder(context, isError: true, errorMessage: "خطأ تحميل الصورة"),
      );
    } else {
      // إذا كان الرابط فارغًا أو هناك خطأ محدد، اعرض Placeholder للخطأ
      return _buildMediaPlaceholder(context, isError: true, errorMessage: errorMessage ?? "رابط غير صالح");
    }
  }



  // --- بناء محتوى الفيديو (مشابه للصورة ولكن يستخدم مصغرة ومؤشر تشغيل) ---
  // --- بناء محتوى الفيديو (النسخة الكاملة والمعدلة) ---
  // داخل MessageBubble


  // --- بناء محتوى الفيديو (عرض المصغرة + overlay، الانتقال عند النقر) ---
  Widget _buildVideoContent(BuildContext context) {
    final String? localVideoName = message.localFilePath;     // اسم ملف الفيديو المحلي
    final String? localThumbName = message.localThumbnailPath;  // اسم ملف المصغرة المحلي
    final String remoteVideoUrl = message.content;               // رابط الفيديو (URL بعد الرفع، أو اسم ملف أثناء الإرسال)
    final String? remoteThumbnailUrl = message.thumbnailUrl;     // رابط المصغرة (URL بعد الرفع)
    final currentStatus = message.status;

    // الويدجت الأساسية ستكون دائمًا المصغرة أو الـ placeholder
    Widget thumbnailWidget = _buildStaticThumbnail(context, remoteThumbnailUrl, localThumbName);

    // الطبقة العلوية تتغير بناءً على الحالة
    Widget overlayWidget = const SizedBox.shrink();
    // هل يجب أن يظهر زر التشغيل؟ (للحالات النهائية والجهاز المحلي موجود أو تم الإرسال)
    bool showPlayButton = (currentStatus == MessageStatus.received && localVideoName != null) || // تم الاستلام والملف المحلي موجود
        (message.isMe && (currentStatus == MessageStatus.sent || currentStatus == MessageStatus.delivered || currentStatus == MessageStatus.read)); // مرسل والعملية مكتملة

    switch (currentStatus) {
      case MessageStatus.pending:
      case MessageStatus.sending:
        overlayWidget = _buildDownloadIndicator(isUploading: true);
        break;
      case MessageStatus.downloading:
        overlayWidget = _buildDownloadIndicator();
        break;
      case MessageStatus.downloadFailed:
        overlayWidget = _buildRetryDownloadButton(onRetryDownload);
        break;
      case MessageStatus.failed:
        overlayWidget = _buildRetrySendButton(onRetrySend);
        break;
      case MessageStatus.received:
      case MessageStatus.sent:
      case MessageStatus.delivered:
      case MessageStatus.read:
      // في الحالات النهائية، نضيف زر التشغيل إلى overlayWidget
      // فقط إذا كان يجب عرضه
        if (showPlayButton) {
          overlayWidget = _buildPlayButtonOverlay(); // <--- إضافة زر التشغيل
        } else if (localVideoName == null && !message.isMe) {
          // حالة Received ولكن الملف المحلي غير موجود -> زر تنزيل
          overlayWidget = _buildManualDownloadButton(onDownloadMedia);
        } else if(localVideoName == null && message.isMe){
          // حالة Sent/Read للمرسل ولكن الملف المحلي مفقود (خطأ)
          overlayWidget = _buildMediaPlaceholder(context, isError: true, errorMessage: "ملف مفقود");
        }
        break;
      default:
      // placeholder افتراضي للخطأ في حالات غير معروفة
        thumbnailWidget = _buildMediaPlaceholder(context, isError: true, errorMessage: "حالة غير معروفة");
        overlayWidget = const SizedBox.shrink();
    }

    // --- بناء الإطار النهائي ---
    return GestureDetector(
      // --- النقرة الآن تفتح دائمًا الشاشة الكاملة ---
      onTap: () async => _handleMediaTap(context, localVideoName, remoteVideoUrl, isVideo: true),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.35, minWidth: 180),

          child: Stack( // <-- نستخدم Stack دائمًا لوضع Overlay فوق المصغرة
            alignment: Alignment.center,
            children: [
              thumbnailWidget, // عرض المصغرة أو Placeholder دائمًا
              overlayWidget,  // عرض المؤشر أو زر التشغيل/التنزيل/إعادة المحاولة فوقها
            ],
          ),

      ),
    );
  }


  Widget _buildStaticThumbnail(BuildContext context, String? remoteThumbnailUrl, String? localThumbnailFileName){
    // هنا نحتاج لبناء المسار الكامل ديناميكيًا *داخل* هذه الدالة أو الويدجت التي تستدعيها
    // سنستخدم FutureBuilder هنا أيضًا لعرض المصغرة بشكل صحيح بعد بناء المسار
    return FutureBuilder<String?>(
        future: _buildFullLocalPath(localThumbnailFileName), // بناء مسار المصغرة
        builder: (context, snapshot){
          // لا نعرض تحميل هنا، بل نعتمد على الصورة البعيدة كاحتياطي سريع
          final String? fullLocalThumbPath = snapshot.data; // المسار الكامل أو null
          Widget thumbnailWidget;
          // 1. حاول المحلي أولاً
          if (fullLocalThumbPath != null) {
            try {
              final file = File(fullLocalThumbPath);
              if (file.existsSync() && file.lengthSync() > 0) {
                // *** تأكد من وجود fit: BoxFit.cover ***
                thumbnailWidget = Image.file(file, key: ValueKey('static_thumb_${message.messageId}'), fit: BoxFit.cover); // <--- FIT
              } else {
                if (kDebugMode) debugPrint("[StaticThumb] Local invalid ($fullLocalThumbPath), using remote.");
                thumbnailWidget = _buildRemoteThumbnailOrPlaceholder(context, remoteThumbnailUrl);
              }
            } catch(e){
              if(kDebugMode) debugPrint("!!! Error reading static local thumb: $e");
              thumbnailWidget = _buildRemoteThumbnailOrPlaceholder(context, remoteThumbnailUrl);
            }
          } else {
            // لا يوجد مسار محلي، استخدم البعيد
            thumbnailWidget = _buildRemoteThumbnailOrPlaceholder(context, remoteThumbnailUrl);
          }
          return thumbnailWidget; // اعرض المصغère أو الـ placeholder
        }
    );
  }


  // --- الدالة المساعدة لبناء المسار الكامل (تبقى كما هي) ---
  Future<String?> _buildFullLocalPath(String? localFileName) async {
    if (localFileName == null || localFileName.isEmpty) return null;
    try {
      final appDocsDir = await getApplicationDocumentsDirectory();
      final mediaPath = p.join(appDocsDir.path, 'sent_media', localFileName);
      final file = File(mediaPath);
      if (await file.exists() && await file.length() > 0) { return mediaPath; }
      else { if(kDebugMode) debugPrint("!!! [_buildFullLocalPath] File check FAILED! $mediaPath"); return null; }
    } catch (e) { if (kDebugMode) debugPrint("!!! Error _buildFullLocalPath $localFileName: $e"); return null; }
  }




// --- الدالة المساعدة لعرض المصغرة البعيدة أو الـ placeholder ---
  Widget _buildRemoteThumbnailOrPlaceholder(BuildContext context, String? remoteThumbnailUrl) {
    final defaultIcon = Icons.movie_creation_outlined; // Default icon for video thumbs
    if (remoteThumbnailUrl != null && remoteThumbnailUrl.isNotEmpty) {
      // يوجد رابط بعيد، استخدم CachedNetworkImage
      return CachedNetworkImage(
        key: ValueKey(remoteThumbnailUrl),
        imageUrl: remoteThumbnailUrl,
        // *** تأكد من وجود fit: BoxFit.cover ***
        fit: BoxFit.cover, // <--- FIT
        placeholder: (context, url) => _buildMediaPlaceholder(context, isLoading: true, defaultIcon: defaultIcon),
        errorWidget: (context, url, error) => _buildMediaPlaceholder(context, isError: true, defaultIcon: defaultIcon, errorMessage: "خطأ تحميل مصغرة"),
      );
    } else {
      // لا يوجد رابط بعيد، اعرض placeholder افتراضي للفيديو
      return _buildMediaPlaceholder(context, defaultIcon: defaultIcon, errorMessage: "لا توجد مصغرة");
    }
  }



// زر إعادة محاولة الإرسال (يشبه إعادة محاولة التنزيل)
  Widget _buildRetrySendButton(VoidCallback? onRetry) {
    return _buildActionButtonOverlay(
        icon: Icons.refresh_rounded,
        tooltip: 'إعادة محاولة الإرسال',
        onPressed: onRetry
    );
  }

  // --- عناصر مساعدة لعرض الوسائط ---

  Widget _buildMediaPlaceholder(BuildContext context, {bool isLoading = false, bool isError = false, IconData? defaultIcon, String? errorMessage}) {
    Widget content;
    if (isLoading) {
      content = const CircularProgressIndicator(strokeWidth: 2);
    } else if (isError) {
      content = Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(defaultIcon ?? Icons.broken_image_outlined, color: Colors.grey.shade600, size: 40),
        if(errorMessage != null) const SizedBox(height:4),
        if(errorMessage != null) Text(errorMessage, style: TextStyle(color: Colors.grey.shade700, fontSize: 10), textAlign: TextAlign.center,)
      ]);
    } else {
      content = Icon(defaultIcon ?? Icons.image_not_supported_outlined, color: Colors.grey.shade500, size: 40);
    }
    return Container(
      color: Colors.grey.shade300,
      alignment: Alignment.center,
      child: content,
    );
  }

  Widget _buildDownloadIndicator({bool isUploading = false}) {
    return Container(
      width: 50, height: 50,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.6),
        shape: BoxShape.circle,
      ),
      child: CircularProgressIndicator(
        strokeWidth: 2.5,
        valueColor: AlwaysStoppedAnimation<Color>(Colors.white.withOpacity(0.8)),
        // يمكنك إضافة قيمة للتقدم إذا كانت متوفرة من خدمة التنزيل/الرفع
        // value: downloadProgress,
      ),
    );
  }

  Widget _buildPlayButtonOverlay() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
      child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 40),
    );
  }

  Widget _buildRetryDownloadButton(VoidCallback? onRetry) {
    return _buildActionButtonOverlay(
        icon: Icons.download_for_offline_rounded,
        tooltip: 'إعادة محاولة التنزيل',
        onPressed: onRetry
    );
  }
  Widget _buildManualDownloadButton(VoidCallback? onDownload){
    return _buildActionButtonOverlay(
        icon: Icons.download_rounded,
        tooltip: 'تنزيل الوسائط',
        onPressed: onDownload
    );
  }


  Widget _buildActionButtonOverlay({required IconData icon, required String tooltip, required VoidCallback? onPressed}){
    return Container(
      width: 55, height: 55,
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.65),
        shape: BoxShape.circle,
      ),
      child: IconButton(
        icon: Icon(icon, color: Colors.white),
        iconSize: 30,
        tooltip: tooltip,
        onPressed: onPressed,
      ),
    );
  }

  // --- بناء صف الوقت والحالة ---
  Widget _buildStatusAndTimestampRow(BuildContext context) {
    final theme = Theme.of(context);
    final timestampString = Helpers.dateTimeToText(message.timestamp.toDate(), short: true);
    final status = message.status;
    Widget? statusIcon;

    // ألوان واتساب للوقت والحالة
    Color timeAndStatusColor = message.isMe
        ? Colors.black.withOpacity(0.45) // أخضر داكن شفاف للوقت/الحالة في رسائلي
        : Colors.grey.shade600;      // رمادي للوقت/الحالة في رسائل الطرف الآخر

    // إذا كانت الخلفية الأساسية للفقاعة هي الوسائط (شفافة)، فالوقت يجب أن يكون بلون فاتح
    bool isMediaBubble = message.type == FirestoreConstants.typeImage || message.type == FirestoreConstants.typeVideo;
    if (isMediaBubble) {
      timeAndStatusColor = Colors.white.withOpacity(0.85);
    }


    if (message.isMe) {
      IconData iconData = Icons.access_time_rounded; // افتراضي
      Color iconColor = timeAndStatusColor; // أيقونة الحالة تأخذ لون الوقت مبدئيًا

      switch (status) {
        case MessageStatus.pending:
        case MessageStatus.sending:
          iconData = Icons.access_time_rounded;
          break;
        case MessageStatus.sent:
          iconData = Icons.done_rounded; // علامة واحدة
          break;
        case MessageStatus.delivered: // إذا طبقت هذا، سيكون علامتين رماديتين
          iconData = Icons.done_all_rounded;
          break;
        case MessageStatus.read:
          iconData = Icons.done_all_rounded; // علامتين
          iconColor = const Color(0xFF4FC3F7); // أزرق سماوي فاتح شبيه بواتساب للقراءة
          break;
        case MessageStatus.failed:
          iconData = Icons.error_outline_rounded;
          iconColor = theme.colorScheme.error.withOpacity(0.8);
          break;
        default:
          statusIcon = null;
      }
      if(statusIcon == null && (status == MessageStatus.sent || status == MessageStatus.delivered || status == MessageStatus.read || status == MessageStatus.pending || status == MessageStatus.sending || status == MessageStatus.failed)) {
        statusIcon = Icon(iconData, size: 17, color: iconColor); // حجم أيقونة مناسب
      }
    }

    BoxDecoration? timeOverlayDecoration;
    if (isMediaBubble) {
      timeOverlayDecoration = BoxDecoration(
        color: Colors.black.withOpacity(0.5), // خلفية داكنة شفافة للوضوح فوق الوسائط
        borderRadius: BorderRadius.circular(8),
      );
    }

    return Container(
      padding: timeOverlayDecoration != null
          ? const EdgeInsets.symmetric(horizontal: 6, vertical: 2.5)
          : EdgeInsets.zero,
      decoration: timeOverlayDecoration,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(timestampString, style: TextStyle(fontSize: 11.0, color: timeAndStatusColor)),
          if (message.isEdited && message.type != FirestoreConstants.typeDeleted) // <--- [جديد]
            Padding(
              padding: const EdgeInsets.only(left: 4.0),
              child: Text(
                "(تم التعديل)",
                style: TextStyle(fontSize: 10.0, fontStyle: FontStyle.italic, color: timeAndStatusColor.withOpacity(0.8)),
              ),
            ),
          if (message.isMe && statusIcon != null) ...[
            const SizedBox(width: 3),
            statusIcon,
          ],
        ],
      ),
    );
  }







  Widget _buildLinkPreview(BuildContext context, Map<String, dynamic> previewData) {
    final theme = Theme.of(context);
    final String? title = previewData['title'];
    final String? description = previewData['description'];
    final String? imageUrl = previewData['image']; // هذا هو رابط الصورة المصغرة للمعاينه
    final String? siteName = previewData['siteName'];
    final String? originalUrl = previewData['url']; // الرابط الأصلي الذي تم تحليله

    // لا تعرض شيئًا إذا لم يكن هناك عنوان أو رابط
    if (originalUrl == null || title == null) return const SizedBox.shrink();

    return InkWell(
      onTap: () async {
        final uri = Uri.tryParse(originalUrl); // originalUrl يجب أن يكون الرابط الفعلي للذهاب إليه
        if (uri != null && await canLaunchUrl(uri)) { // استخدم canLaunchUrl
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        }  else {
          if (kDebugMode) debugPrint("Could not launch $originalUrl");
          // يمكنك إظهار رسالة خطأ للمستخدم إذا فشل فتح الرابط
          Get.snackbar("خطأ", "لا يمكن فتح الرابط", snackPosition: SnackPosition.BOTTOM);
        }
      },
      borderRadius: BorderRadius.circular(8), // لتأثير الضغط
      child: Container(
        margin: const EdgeInsets.only(top: 6.0, bottom: 2.0), // هامش علوي وسفلي
        padding: const EdgeInsets.all(10.0),
        decoration: BoxDecoration(
          // لون خلفية مختلف قليلاً لتمييز المعاينة
          color: message.isMe
              ? Colors.green.shade100.withOpacity(0.4)
              : theme.dividerColor.withOpacity(0.6),
          borderRadius: BorderRadius.circular(8),
          // border: Border.all(color: theme.dividerColor, width: 0.5), // حد خفيف (اختياري)
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // الصورة المصغرة (إذا وجدت)
            if (imageUrl != null && imageUrl.isNotEmpty)
              ClipRRect( // لقص الصورة بشكل دائري أو مستدير
                borderRadius: BorderRadius.circular(6.0),
                child: SizedBox(
                  width: 65, height: 65, // حجم مناسب للصورة
                  child: CachedNetworkImage(
                    imageUrl: imageUrl,
                    fit: BoxFit.cover,
                    placeholder: (ctx, u) => Container(
                      color: theme.cardColor.withOpacity(0.5),
                      child: Icon(Icons.image, size: 24, color: theme.hintColor.withOpacity(0.5)),
                    ),
                    errorWidget: (ctx, u, e) => Container(
                      color: theme.cardColor.withOpacity(0.5),
                      child: Icon(Icons.link_off, size: 24, color: theme.hintColor.withOpacity(0.5)),
                    ),
                  ),
                ),
              ),
            if (imageUrl != null && imageUrl.isNotEmpty) const SizedBox(width: 10),

            // النص (العنوان، الوصف، اسم الموقع)
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min, // لتأخذ أقل ارتفاع
                children: [
                  if (siteName != null && siteName.isNotEmpty)
                    Text(
                      siteName,
                      style: TextStyle(fontSize: 11.5, color: theme.hintColor, fontWeight: FontWeight.w500),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  if (siteName != null && siteName.isNotEmpty) const SizedBox(height: 2.5),
                  Text(
                    title,
                    style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: theme.textTheme.bodyLarge?.color?.withOpacity(0.9)),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (description != null && description.isNotEmpty) const SizedBox(height: 3.5),
                  if (description != null && description.isNotEmpty)
                    Text(
                      description,
                      style: TextStyle(fontSize: 12, color: theme.textTheme.bodyMedium?.color?.withOpacity(0.75)),
                      maxLines: 2, // يمكن زيادته إذا أردت
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

} // نهاية كلاس MessageBubble