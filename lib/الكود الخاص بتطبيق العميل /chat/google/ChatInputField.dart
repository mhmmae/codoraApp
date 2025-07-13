import 'package:codora/%D8%A7%D9%84%D9%83%D9%88%D8%AF%20%D8%A7%D9%84%D8%AE%D8%A7%D8%B5%20%D8%A8%D8%AA%D8%B7%D8%A8%D9%8A%D9%82%20%D8%A7%D9%84%D8%B9%D9%85%D9%8A%D9%84%20/chat/google/truncate.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'ChatController.dart';
import 'Helpers.dart';

class ChatInputField extends StatelessWidget {
  final ChatController controller;

  const ChatInputField({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column( // <--- تغيير إلى Column
      mainAxisSize: MainAxisSize.min, // ليأخذ أقل مساحة ممكنة
      children: [
        // --- [جديد] ويدجت عرض الرد المقتبس ---
        Obx(() {
          if (controller.isEditingMessage) {
            // تصميم الجزء الذي يعرض "تعديل الرسالة"
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              margin: const EdgeInsets.only(left: 8, right: 8, top: 8),
              decoration: BoxDecoration(
                  color: theme.canvasColor.withOpacity(0.8), // لون خلفية مختلف قليلاً
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                  border: Border(top: BorderSide(color: Colors.grey[300]!, width: 0.5))
              ),
              child: Row(
                children: [
                  Icon(Icons.edit_note, color: theme.primaryColor, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "تعديل الرسالة",
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: theme.primaryColorDark),
                        ),
                        Text(
                          controller.messageBeingEdited.value?.content.truncate(maxLength: 50) ?? "", // معاينة النص الأصلي
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 13, color: theme.textTheme.bodySmall?.color),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, size: 20, color: Colors.grey[600]),
                    onPressed: controller.cancelEditMessage,
                    tooltip: 'إلغاء التعديل',
                  ),
                ],
              ),
            );
          }
          else if (controller.isReplying) {
            // تصميم الجزء الذي يعرض معاينة الرد
            final String senderNameForReplyPreview = (controller.currentlyQuotedMessage.value?.senderId == controller.currentUserId)
                ? "أنت"
            // : controller.recipientName; // هذه قد تكون غير دقيقة إذا كان الرد على رسالة قديمة والمرسل تغير اسمه
            // الأفضل الاعتماد على اسم مرسل الرسالة المقتبسة المخزن أو جلبه ديناميكياً
            // كحل مؤقت إذا كان recipientName هو اسم الطرف الآخر دائماً:
                : controller.recipientName.isNotEmpty ? controller.recipientName : (controller.currentlyQuotedMessage.value?.senderId.substring(0,6) ?? "شخص ما");


            return Container(
              key: const ValueKey("replying_preview"), // مفتاح للتعرف عليه
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              margin: const EdgeInsets.only(left: 8, right: 8, top: 8),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.7),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Row(
                children: [
                  // أيقونة أو خط عمودي للرد
                  Icon(Icons.reply_rounded, color: theme.primaryColor, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          "رد على: $senderNameForReplyPreview",
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                            color: theme.primaryColorDark,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          controller.quotedMessagePreviewText, // تستخدم هذه الدالة من ChatController
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12.5,
                            color: theme.textTheme.bodySmall?.color?.withOpacity(0.8),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close_rounded, size: 22, color: theme.hintColor),
                    onPressed: controller.cancelQuotedMessage, // دالة إلغاء الرد
                    tooltip: 'إلغاء الرد',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            );
          }
          // إذا لم يكن هناك تعديل أو رد، لا تعرض شيئًا
          return const SizedBox.shrink();
        }),
        // --- نهاية ويدجت عرض الرد المقتبس ---

        // صف الإدخال الأصلي
        AnimatedContainer(
          duration: const Duration(milliseconds: 200), // سرعة التحريك
          curve: Curves.easeInOut, // نوع التحريك
          padding: EdgeInsets.only(
            left: 8,
            right: 8,
            top: 8,
            bottom: 8 + MediaQuery.of(context).viewInsets.bottom, // هذا سيتغير بسلاسة
          ),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            border: Border(top: BorderSide(color: Colors.grey[300]!, width: 0.5)),
          ),
          child: SafeArea(
            child:
            // --- سنبني دائماً نفس الهيكل، ولكن نغير محتواه ---
            _buildInputRow(theme, context),
          ),
        )
      ],
    );
  }

  // --- الدالة الرئيسية لبناء صف الإدخال ---
  Widget _buildInputRow(ThemeData theme, BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // --- المنطقة اليسرى: قد تحتوي على زر الإيموجي أو مؤشر الإلغاء ---
        Obx(() => _buildLeftSection(theme)),

        // --- المنطقة الوسطى: حقل النص أو مؤقت التسجيل ---
        Expanded(
          child: Obx(() => _buildCenterSection(theme)),
        ),
        const SizedBox(width: 8),

        // --- المنطقة اليمنى: زر الإرسال/الميكروفون/مؤشر الإرسال ---
        Obx(() => _buildRightButtonSection(theme)),
      ],
    );
  }

  // --- الجزء الأيسر (مثال: الإلغاء) ---
  Widget _buildLeftSection(ThemeData theme) {
    // هذا يظهر فقط أثناء التسجيل النشط والسحب للإلغاء
    return AnimatedOpacity(
      opacity: controller.isRecording && controller.isRecordDeleting ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 200),
      child: Visibility( // استخدم Visibility لإخفائه تماماً عند عدم الحاجة
        visible: controller.isRecording && controller.isRecordDeleting,
        maintainSize: false, // لا تحافظ على المساحة
        maintainAnimation: true,
        maintainState: true,
        child: Padding( // أضف padding إذا لزم الأمر
          padding: const EdgeInsets.only(bottom: 12.0, right: 8), // ضبط المحاذاة مع الأيقونة
          child: Icon(Icons.delete_outline_rounded, color: Colors.redAccent.shade100, size: 24),
        ),
      ),
    );
  }

  // --- الجزء الأوسط (حقل النص أو المؤقت) ---
  Widget _buildCenterSection(ThemeData theme) {
    if (controller.isRecording) {
      // --- واجهة التسجيل في المنتصف ---
      return Container(
        height: 48, // ارتفاع ثابت ليتناسب مع حجم الزر
        alignment: Alignment.center, // توسيط المؤقت
        padding: const EdgeInsets.symmetric(horizontal: 12.0), // هوامش داخلية
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center, // أو MainAxisAlignment.spaceBetween إذا وضعت أيقونة mic هنا
          children: [
            // أيقونة mic حمراء هنا أو مؤشر آخر
            Icon(Icons.mic_none, color: Colors.redAccent, size: 20), // أيقونة رفيعة
            const SizedBox(width: 8),
            Text(
              "اسحب للإلغاء   ${Helpers.formatDuration(controller.recordingDuration)}", // دمج المؤقت والنص
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, letterSpacing: 0.5),
              textAlign: TextAlign.center, // توسيط النص
            ),
          ],
        ),
      );
    } else {
      // --- واجهة حقل النص العادية ---
      return Container(
        clipBehavior: Clip.antiAlias,
        padding: const EdgeInsets.symmetric(horizontal: 2),
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.grey[300]!)
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                onChanged: (text) => controller.updateCanSendMessageState(),
                controller: controller.messageController,
                focusNode: controller.focusNode,
                style: const TextStyle(fontSize: 16),
                keyboardType: TextInputType.multiline,
                maxLines: 5, minLines: 1,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  hintText: "اكتب رسالة...",
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 11, horizontal: 4),
                  isCollapsed: true,
                ),
              ),
            ),
            // زر الإرفاق
            if (!controller.canSendMessage)
              IconButton(
                padding: const EdgeInsets.only(bottom: 5, right: 4, left: 4),
                constraints: const BoxConstraints(),
                visualDensity: VisualDensity.compact,
                icon: Icon(Icons.attach_file_rounded, color: Colors.grey[600], size: 24),
                onPressed: controller.showAttachmentOptions,
              ),
            const SizedBox(width: 4),
          ],
        ),
      );
    }
  }


  // --- الجزء الأيمن (الأزرار) ---
  Widget _buildRightButtonSection(ThemeData theme) {
    // زر التسجيل / الإرسال
    Widget micOrSendButton;

    if (controller.canSendMessage && !controller.isRecording) {
      // زر الإرسال
      micOrSendButton = FloatingActionButton(
        key: const ValueKey('send_button'), // مفتاح لـ Flutter للتعرف عليه
        mini: true,
        onPressed: controller.isEditingMessage
            ? controller.sendTextMessage // ستنفذ منطق التعديل إذا كانت isEditingMessage true
            : (controller.showMediaPreview
            ? controller.sendMediaMessageFromPreview
            : controller.sendTextMessage),
        backgroundColor: theme.primaryColor,
        elevation: 1.0,
        tooltip: 'إرسال',
        child: Icon(
            controller.isEditingMessage ? Icons.check_rounded : Icons.send_rounded, // تغيير الأيقونة
            color: Colors.white, size: 20
        ),
      );
    } else {
      // --- زر الميكروفون (مع GestureDetector دائمًا) ---
      // استخدام ScaleTransition أو SizeTransition لإظهار تأثير أن الزر يكبر قليلاً عند التسجيل
      // لكن يجب أن يبقى الـ GestureDetector ثابتاً.
      micOrSendButton = GestureDetector(
        key: const ValueKey('mic_gesture'), // مفتاح لـ GestureDetector
        onLongPressStart: controller.startRecording,
        onLongPressMoveUpdate: controller.updateRecordingPosition,
        onLongPressEnd: (_) => controller.stopRecording(),
        onLongPressCancel: controller.cancelRecording,

        onTap: () { /* No action on short tap */ },
        behavior: HitTestBehavior.opaque, // ضمان التقاط الضغط في المساحة
        child: AnimatedContainer( // تحريك الخلفية أو الحجم قليلاً عند التسجيل
          duration: const Duration(milliseconds: 150),
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: controller.isRecording ? Colors.redAccent : theme.primaryColor, // تغيير اللون
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(controller.isRecording ? 0.3 : 0.2), // ظل أكبر قليلاً؟
                blurRadius: controller.isRecording ? 6.0 : 4.0,
                offset: Offset(0, controller.isRecording ? 3 : 2),
              ),
            ],
          ),
          alignment: Alignment.center,
          child: Icon(
                controller.isRecording ? Icons.stop_circle_outlined : Icons.mic_rounded, // تغيير الأيقونة (اختياري)
                color: Colors.white, size: 22
            ),
          ),

      );
    }

    // --- عرض مؤشر الإرسال أو الزر المناسب ---
    if (controller.isSending) {
      return Container(
        key: const ValueKey('sending_indicator'),
        width: 48, height: 48, padding: const EdgeInsets.all(12),
        child: CircularProgressIndicator(strokeWidth: 3, valueColor: AlwaysStoppedAnimation<Color>(theme.primaryColor)),
      );
    } else {
      // استخدم AnimatedSwitcher لتبديل سلس بين زر الإرسال والميكروفون
      return AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        transitionBuilder: (Widget child, Animation<double> animation) {
          return ScaleTransition(scale: animation, child: child);
        },
        child: micOrSendButton, // الويدجت التي تتغير (mic أو send)
      );
    }
  }

} // نهاية الكلاس