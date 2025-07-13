import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';
// For QuerySnapshot & Timestamp

// تأكد من صحة مسارات الاستيراد
import 'ChatController.dart';
import 'ChatInputField.dart';
import 'FirestoreConstants.dart';
import 'Message.dart';
import 'MessageBubble.dart';
import 'MessageRepository.dart';
import 'MessageStatus.dart';
// استيراد ويدجتس الواجهة المستخدمة

class ChatScreen extends StatelessWidget {
  final String recipientId;

  const ChatScreen({super.key, required this.recipientId});

  @override
  Widget build(BuildContext context) {
    // حقن/العثور على المتحكم باستخدام GetX
    // تأكد من أن المتحكم إما يتم إنشاؤه هنا لأول مرة أو العثور عليه إذا كان موجودًا بالفعل (بناءً على استخدام tag)
    // قد تحتاج إلى `fenix: true` للحفاظ عليه إذا خرجت من الشاشة وعدت بسرعة
    if (kDebugMode) debugPrint("--- [ChatScreen build] START ---"); // <-- طباعة هنا

    final ChatController controller = Get.put(
        ChatController(recipientId: recipientId,chatScreenTabIndexInBottomBar: 3),
        tag: recipientId, permanent: false);

    // الحصول على تيار الرسائل من المستودع مباشرة
    // نستخدم Get.find لأن المستودع هو Singleton أو مسجل كـ fenix:true
    final Stream<List<Message>> messagesStream = Get
        .find<MessageRepository>()
        .getMessages(recipientId);

    return Scaffold(
      backgroundColor: const Color(0xFFECE5DD), // لون خلفية شبيه بواتساب
      appBar: AppBar(
        backgroundColor: Theme
            .of(context)
            .primaryColor,
        // استخدام لون الثيم الأساسي
        foregroundColor: Colors.white,
        // لون الأيقونات والنصوص في الـ AppBar
        elevation: 1.0,
        // ظل خفيف

        titleSpacing: 0,
        // إزالة المسافة الافتراضية قبل العنوان
        title: Obx(() =>
        controller.recipientData.value == null
            ? const Center(child: SizedBox(width: 20,
            height: 20,
            child: CircularProgressIndicator(
                strokeWidth: 2, color: Colors.white))) // مؤشر تحميل أصغر
            : InkWell( // جعل منطقة العنوان قابلة للنقر (للانتقال لملف المستخدم مثلاً)
          onTap: () {
            /* TODO: الانتقال إلى شاشة ملف المستخدم */
          },
          child: Row(
            children: [
              // صورة الملف الشخصي للمستلم
              CircleAvatar(
                radius: 20,
                backgroundColor: Colors.grey.shade300,
                backgroundImage: controller.recipientProfilePic.isNotEmpty
                    ? CachedNetworkImageProvider(controller.recipientProfilePic)
                    : null,
                child: controller.recipientProfilePic.isEmpty
                    ? const Icon(
                    Icons.person, color: Colors.white, size: 24) // أيقونة بديلة
                    : null,
              ),
              const SizedBox(width: 10),
              // اسم المستخدم وحالته (إذا كانت متاحة)
              Expanded( // لمنع تجاوز النص إذا كان الاسم طويلًا
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      controller.recipientName,
                      style: const TextStyle(fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white),
                      overflow: TextOverflow.ellipsis, // قص النص الطويل
                    ),

                    Obx(() {
                      if (controller.isRecipientTyping.value) {
                        return Text(
                          "يكتب الآن...", // أو استخدم ويدجت نقاط متحركة
                          style: TextStyle(fontSize: 12,
                              color: Colors.white.withOpacity(0.85),
                              fontStyle: FontStyle.italic),
                          overflow: TextOverflow.ellipsis,
                        );
                      } else {
                        // يمكنك عرض "آخر ظهور" هنا إذا أردت، أو اتركها فارغة
                        // return Text(
                        //   controller.recipientLastSeen.value, // <--- ستحتاج لمتغير lastSeen في Controller
                        //   style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.8)),
                        //   overflow: TextOverflow.ellipsis,
                        // );
                        return const SizedBox
                            .shrink(); // لا تعرض شيئًا إذا لم يكن يكتب
                      }
                    }),
                    // --- يمكنك تفعيل هذا إذا كان لديك بيانات الحالة ---
                    // Text(
                    //   "آخر ظهور اليوم في 10:30 ص", // مثال لحالة الظهور
                    //   style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.8)),
                    //   overflow: TextOverflow.ellipsis,
                    // ),
                    // --- --- --- --- --- --- --- --- --- --- --- ---
                  ],
                ),
              ),
            ],
          ),
        )),
        actions: [
          // IconButton(
          //   tooltip: 'مكالمة فيديو',
          //   icon: const Icon(Icons.videocam_outlined),
          //   onPressed: () {
          //     /* TODO: Implement Video Call */
          //   },
          // ),
          // IconButton(
          //   tooltip: 'مكالمة صوتية',
          //   icon: const Icon(Icons.call_outlined),
          //   onPressed: () {
          //     /* TODO: Implement Audio Call */
          //   },
          // ),
          // يمكن إضافة زر قائمة الخيارات الإضافية هنا
          // PopupMenuButton(...)
        ],
      ),
      body: Obx(() {
        final String selectedPath = controller.currentWallpaperPath.value; // القيمة التفاعلية
        bool hasCustomWallpaper = selectedPath.isNotEmpty;
        return Container(
          decoration: BoxDecoration(
            image: hasCustomWallpaper
                ? DecorationImage(
              image: FileImage(File(selectedPath)), // تأكد أن selectedPath هو مسار صالح
              fit: BoxFit.cover,
              colorFilter: ColorFilter.mode(Colors.black.withOpacity(0.15), BlendMode.darken), // تعتيم بسيط
            )
                : null,
            color: !hasCustomWallpaper
                ? const Color(0xFFECE5DD) // اللون الافتراضي إذا لم توجد خلفية مخصصة
                : null, // لا لون إذا كانت هناك صورة خلفية
          ),
          child: Column(
            children: [
              // --- منطقة عرض قائمة الرسائل ---
              Expanded(
                child: GestureDetector( // لإخفاء لوحة المفاتيح عند النقر خارج حقل الإدخال
                  onTap: () => FocusScope.of(context).unfocus(),
                  // استخدام خلفية صورة للدردشة (اختياري)
                  // child: Container(
                  //  decoration: BoxDecoration(
                  //   image: DecorationImage(
                  //     image: AssetImage('assets/whatsapp_background.png'), // تأكد من إضافة الصورة
                  //      fit: BoxFit.cover,
                  //     colorFilter: ColorFilter.mode(Colors.black.withOpacity(0.05), BlendMode.darken), // لتعتيم الخلفية قليلًا
                  //    ),
                  // ),
                  child: StreamBuilder<
                      List<Message>>( // <--- يستمع الآن لـ List<Message>
                    stream: messagesStream,
                    // <--- مصدر التيار هو المستودع المحلي
                    builder: (context, snapshot) {
                      if (kDebugMode) {
                        debugPrint(
                          "    --- [ChatScreen StreamBuilder] Building with state: ${snapshot
                              .connectionState}, hasData: ${snapshot
                              .hasData}, hasError: ${snapshot
                              .hasError}"); // <-- طباعة هنا
                      }

                      // التعامل مع الحالات المختلفة للتيار
                      if (snapshot.connectionState == ConnectionState.waiting &&
                          !snapshot.hasData) {
                        // إظهار تحميل فقط إذا لم تكن هناك بيانات قديمة متاحة للعرض
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (snapshot.hasError) {
                        if (kDebugMode) {
                          debugPrint(
                            "خطأ في تيار الرسائل المحلية: ${snapshot.error}");
                        }
                        return Center(child: Text("حدث خطأ في تحميل الرسائل.",
                            style: TextStyle(color: Colors.grey[600])));
                      }
                      // استخدام data ?? [] للتعامل مع حالة عدم وجود بيانات بعد اكتمال التحميل
                      final messages = snapshot.data ?? [];

                      if (messages.isEmpty) {
                        return Center(child: Text("لا توجد رسائل بعد.",
                            style: TextStyle(color: Colors.grey[700])));
                      }
                      // بناء القائمة باستخدام ListView.builder
                      return ListView.builder(
                        controller: controller.scrollController,
                        // استخدام المتحكم المعرف
                        reverse: true,
                        // الأحدث في الأسفل
                        padding: const EdgeInsets.symmetric(
                            vertical: 10.0, horizontal: 6.0),
                        itemCount: messages.length,
                        itemBuilder: (context, index) {
                          final String chatPartnerIdForBubble = controller
                              .recipientId; // <--- ID الطرف الآخر دائمًا هو tag للـ ChatController

                          final message = messages[index]; // <--- الحصول على كائن Message
                          final isMe = message.isMe;
                          // يمكنك حسابه هنا أو الاعتماد على قيمة message.isMe
                          VoidCallback? retrySendCallback = isMe &&
                              message.status == MessageStatus.failed
                              ? () =>
                              controller.retrySendMessage(message.messageId)
                              : null;
                          VoidCallback? retryDownloadCallback = !isMe &&
                              message.status == MessageStatus.downloadFailed
                              ? () =>
                              controller.retryDownloadMedia(message.messageId)
                              : null;
                          VoidCallback? downloadMediaCallback = !isMe &&
                              message.type != FirestoreConstants.typeText &&
                              message.localFilePath == null &&
                              message.status != MessageStatus.downloading &&
                              message.status != MessageStatus.downloadFailed
                              ? () =>
                              controller.startManualMediaDownload(
                                  message.messageId)
                              : null;
                          // عرض فقاعة الرسالة
                          return MessageBubble(
                            key: ValueKey(message.messageId),
                            message: message,
                            chatPartnerId: chatPartnerIdForBubble,
                            // ... (callbacks)
                          )
                          // .animate() // <--- ابدأ سلسلة الأنيميشن
                          // .fadeIn(duration: 400.ms, curve: Curves.easeOutQuad) // تأثير ظهور تدريجي
                          // .slideY( // تأثير انزلاق عمودي
                          //   begin: 0.3, // ابدأ من 30% أسفل موضعها النهائي
                          //   end: 0,
                          //   duration: 500.ms,
                          //   delay: (50 * index).ms, // تأخير لكل عنصر بناءً على الـ index (تأثير متتالي)
                          //                      // عدل 50ms لتغيير سرعة التتالي
                          //   curve: Curves.elasticOut, // منحنى مرن
                          // );

                          // --- أو تأثير أكثر حداثة وجمالاً (انزلاق من الجانب مع دوران خفيف وظهور) ---
                              .animate(
                              delay: (75 * index)
                                  .clamp(0, 400)
                                  .ms // تأخير تدريجي مع حد أقصى للتأخير
                          )
                              .fadeIn(
                              duration: 500.ms, curve: Curves.easeOutCubic)
                              .move(
                            begin: Offset(message.isMe ? 60 : -60, 15),
                            // انزلاق من الجانب (يمين/يسار) والأسفل قليلاً
                            end: Offset.zero,
                            duration: 600.ms,
                            curve: Curves.easeOutQuint,
                          )
                              .rotate( // دوران خفيف
                              begin: message.isMe ? -0.05 : 0.05,
                              // دوران عكسي لرسائلي
                              end: 0,
                              duration: 700.ms,
                              curve: Curves.easeOutBack
                          )
                              .scaleXY( // تغيير حجم طفيف
                              begin: 0.95,
                              end: 1,
                              duration: 500.ms,
                              curve: Curves.decelerate
                          );
                        },
                      );
                    },
                  ),
                  // ), // نهاية Container الخلفية
                ),
              ),

              // --- منطقة معاينة الوسائط (تظهر فوق حقل الإدخال عند اختيار وسائط) ---
              Obx(() { // استخدام Obx جيد هنا لأنه يعتمد على Rx variables
                final shouldShow = controller.showMediaPreview;
                // تحريك الظهور والإخفاء
                return AnimatedSize(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeInOut,
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 200),
                    opacity: shouldShow ? 1.0 : 0.0,
                    child: shouldShow ? _buildMediaPreviewWidget(
                        controller, context) : const SizedBox.shrink(),
                  ),
                );
              }),


              // --- منطقة حقل الإدخال ---
              ChatInputField(controller: controller),
              // تمرير المتحكم لويدجت الإدخال
            ],
          ),
        );
      }),
    );
  }

  // --- ويدجت عرض معاينة الوسائط المصغرة فوق حقل الإدخال ---
  Widget _buildMediaPreviewWidget(ChatController controller,
      BuildContext context) {
    // الوصول إلى حالة المعاينة من المتحكم
    final mediaFile = controller.mediaPreviewFile;
    final imageData = controller.imagePreviewData;
    final mediaType = controller.mediaPreviewType;

    Widget previewContent; // محتوى المعاينة (صورة، أيقونة فيديو)

    if (imageData != null) {
      // عرض صورة من بيانات Uint8List
      previewContent = Image.memory(imageData, fit: BoxFit.cover);
    } else if (mediaFile != null) {
      if (mediaType == 'image') {
        // عرض صورة من ملف
        previewContent = Image.file(mediaFile, fit: BoxFit.cover);
      } else if (mediaType == 'video') {
        // عرض أيقونة للفيديو (لأن إنشاء Thumbnail حقيقي هنا قد يكون مكلفًا)
        // يمكنك إنشاء Thumbnail مرة واحدة عند الاختيار وتخزينه في Controller إذا أردت عرضه هنا
        previewContent = Container(
          width: double.infinity, // جعلها تملأ المساحة
          height: double.infinity,
          color: Colors.black87.withOpacity(0.7),
          child: const Center(child: Icon(
              Icons.play_circle_outline, color: Colors.white, size: 35)),
        );
      } else {
        // نوع وسائط غير مدعوم
        previewContent = Container(color: Colors.grey,
            child: const Center(child: Icon(Icons.broken_image_outlined)));
      }
    } else {
      // يجب ألا نصل إلى هنا إذا كانت showMediaPreview صحيحة، لكن كإجراء احترازي
      return const SizedBox.shrink();
    }

    return Container(
      height: 80,
      // ارتفاع ثابت لمنطقة المعاينة
      margin: const EdgeInsets.only(left: 12, right: 12, bottom: 6, top: 4),
      // هوامش حول المعاينة
      child: Stack(
        alignment: Alignment.center, // توسيط المحتوى
        children: [
          // --- محتوى المعاينة نفسه ---
          Container(
            width: 80,
            // عرض مربع للمعاينة
            height: 80,
            decoration: BoxDecoration(
              // لون خلفية احتياطي أو إطار
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(12), // حواف مستديرة
            ),
            clipBehavior: Clip.antiAlias,
            // قص المحتوى ليطابق الحواف المستديرة
            child: previewContent,
          ),
          // --- زر إلغاء المعاينة ---
          Positioned(
            top: 0, // تحديد موقع الزر في الزاوية العلوية اليمنى
            right: 0,
            child: InkWell( // جعل المنطقة قابلة للنقر
              onTap: controller.clearMediaPreview,
              // <-- استدعاء الدالة العامة الآن
              borderRadius: BorderRadius.circular(50),
              // حافة مستديرة لتأثير الضغط
              child: Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.6), // خلفية شبه شفافة للزر
                  shape: BoxShape.circle, // شكل دائري
                ),
                child: const Icon(Icons.close_rounded, color: Colors.white,
                    size: 16), // أيقونة الإغلاق
              ),
            ),
          ),
        ],
      ),
    );
  }
}