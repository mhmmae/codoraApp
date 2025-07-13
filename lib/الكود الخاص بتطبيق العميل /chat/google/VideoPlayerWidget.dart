import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';
import 'package:video_player/video_player.dart' as vp; // استخدام Prefix
import 'dart:io'; // للتحقق من وجود الملف المحلي
import 'package:flutter/foundation.dart'; // لـ kDebugMode
import 'package:path/path.dart' as p; // تأكد من وجود الاستيراد

// --- استيراد المتحكم الذي أنشأناه سابقًا ---

import 'VideoPlayerController.dart'; // <--- عدّل المسار

// (يمكنك استخدام نفس المتحكم `VideoPlayerController` الذي أنشأناه سابقًا)

class VideoPlayerWidget extends StatelessWidget {
  final String messageId;
  final String remoteVideoUrl;     // الرابط البعيد للفيديو (إلزامي)
  final String? remoteThumbnailUrl; // الرابط البعيد للمصغرة (اختياري)
  final String? localVideoFileName;   // *اسم* ملف الفيديو المحلي (اختياري)
  final String? localThumbnailFileName; // *اسم* ملف المصغرة المحلي (اختياري)
  final double aspectRatio;          // نسبة العرض للارتفاع المتوقعة (يمكن تمريرها أو أخذها من المتحكم)

  const VideoPlayerWidget({
    super.key,
    required this.messageId,
    required this.remoteVideoUrl,
    this.remoteThumbnailUrl,
    this.localVideoFileName,
    this.localThumbnailFileName,
    this.aspectRatio = 16 / 9,
  });


  // --- دالة مساعدة لبناء المسار الكامل (مشابهة لتلك في AudioMessageWidget) ---
  Future<String?> _buildFullLocalPath(String? localFileName) async {
    if (localFileName == null || localFileName.isEmpty) return null;
    try {
      final appDocsDir = await getApplicationDocumentsDirectory();
      final mediaPath = p.join(appDocsDir.path, 'sent_media', localFileName);
      final file = File(mediaPath);
      // التحقق الإضافي
      if (await file.exists() && await file.length() > 0) {
        return mediaPath;
      } else {
        if(kDebugMode) debugPrint("!!! [VideoPlayerWidget] File check FAILED for '$localFileName' at path: $mediaPath");
        return null; // الملف غير موجود أو فارغ
      }
    } catch (e) { if (kDebugMode) debugPrint("!!! Error constructing/checking path for $localFileName: $e"); return null; }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String?>(
      future: _buildFullLocalPath(localVideoFileName),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          // عرض مصغرة بسيطة أثناء انتظار المسار المحلي
          return AspectRatio(aspectRatio: aspectRatio, child: _buildThumbnailOnly(context, remoteThumbnailUrl, null)); // لا نعرف المسار المحلي بعد
        }

        final String? fullLocalVideoPath = snapshot.data; // المسار المحلي النهائي للفيديو
        final bool shouldUseLocalVideo = fullLocalVideoPath != null;

        // تحديد المصدر الأساسي للفيديو
        final String videoSourceToUse = shouldUseLocalVideo ? fullLocalVideoPath : remoteVideoUrl;
        final bool isSourceLocalVideo = shouldUseLocalVideo;

        if (kDebugMode) debugPrint("[VideoPlayerWidget $messageId] Resolved video source: $videoSourceToUse (isLocal: $isSourceLocalVideo)");

        if (videoSourceToUse.isEmpty) {
          return AspectRatio(aspectRatio: aspectRatio, child: _buildMediaPlaceholder(context, isError: true, errorMessage: "مصدر الفيديو غير صالح"));
        }

        // --- الحصول على المتحكم أو إنشاؤه ---
        final VideoPlayerController controller = Get.put(
          VideoPlayerController(
            videoSourceUrl: videoSourceToUse,
            messageId: messageId,
            isFileSource: isSourceLocalVideo, // النوع الصحيح للمصدر
          ),
          tag: messageId,
        );

        // --- بناء الواجهة التفاعلية ---
        return Obx(() {
          // في حالة الخطأ أو عدم التهيئة، اعرض المصغرة/الخطأ
          if (!controller.isInitialized.value || controller.hasError.value || controller.sdkPlayerController == null) {
            // بناء المسار الكامل للمصغرة لاستخدامها كـ placeholder
            return FutureBuilder<String?>(
                future: _buildFullLocalPath(localThumbnailFileName), // بناء مسار المصغرة
                builder: (ctx, thumbSnapshot){
                  return AspectRatio(aspectRatio: aspectRatio, child: _buildThumbnailOnly(ctx, remoteThumbnailUrl, thumbSnapshot.data));
                }
            );

            // الحل الأبسط: اعرض placeholder للخطأ مباشرة
            // return AspectRatio(aspectRatio: aspectRatio, child: _buildPlaceholderOrError(context, controller, defaultAspectRatio: aspectRatio));
          }

          // في حالة التهيئة، اعرض المشغل
          return AspectRatio(
            aspectRatio: controller.aspectRatio.value, // النسبة من المتحكم
            child: GestureDetector(
              onTap: controller.togglePlayPause,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // الفيديو
                  vp.VideoPlayer(controller.sdkPlayerController!),
                  // مؤشر التحميل
                  if (controller.isBuffering.value)
                    const CircularProgressIndicator(strokeWidth: 2, color: Colors.white70),
                  // زر التشغيل
                  AnimatedOpacity(
                    opacity: controller.isPlaying.value ? 0.0 : 1.0,
                    duration: const Duration(milliseconds: 300),
                    child: Visibility(
                      visible: !controller.isPlaying.value,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                        child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 50),
                      ),
                    ),
                  ),
                  // شريط التحكم (اختياري)
                  // Positioned(bottom: 0, left: 0, right: 0, child: vp.VideoProgressIndicator(...)),
                ],
              ),
            ),
          );
        }); // نهاية Obx
      }, // نهاية builder لـ FutureBuilder
    );
  }


  Widget _buildMediaPlaceholder(BuildContext context, {bool isLoading = false, bool isError = false, IconData? defaultIcon, String? errorMessage}) { /* ... نفس كود Placeholder ... */
    Widget content;
    final icon = defaultIcon ?? Icons.movie_creation_outlined;
    if (isLoading) { content = const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2.0, color: Colors.white70)); }
    else if (isError) { content = Column(mainAxisSize: MainAxisSize.min, children: [ Icon(icon, color: Colors.grey.shade700, size: 40), if(errorMessage != null) ...[const SizedBox(height:4), Text(errorMessage, style: TextStyle(color: Colors.grey.shade800, fontSize: 10), textAlign: TextAlign.center,)] ]); }
    else { content = Icon(icon, color: Colors.grey.shade500, size: 50); }
    return Container(color: Colors.black54, alignment: Alignment.center, child: content); // خلفية داكنة للفيديو
  }


  Widget _buildThumbnailOnly(BuildContext context, String? remoteThumbnailUrl, String? fullLocalThumbPath) {
    // بناء المسار المحلي للمصغرة (هنا نحتاج لـ full path المبني مسبقاً)
    // --- (المنطق التالي يجب أن يكون مشابهًا لـ MessageBubble._buildThumbnailOnly) ---
    Widget thumbnailWidget;
    bool triedLocal = false;

    if (fullLocalThumbPath != null && fullLocalThumbPath.isNotEmpty) {
      triedLocal = true;
      try {
        final file = File(fullLocalThumbPath);
        if (file.existsSync()) {
          thumbnailWidget = Image.file(file, fit: BoxFit.cover, key: ValueKey('thumb_$messageId'));
          return thumbnailWidget;
        } else {
          if (kDebugMode) debugPrint("[_buildThumbnailOnly $messageId] Local thumb path exists but file NOT found: $fullLocalThumbPath");
          thumbnailWidget = _buildRemoteThumbnailOrPlaceholder(context, remoteThumbnailUrl);
        }
      } catch (e) {
        if (kDebugMode) debugPrint("!!! Error loading local thumb '$fullLocalThumbPath': $e");
        thumbnailWidget = _buildRemoteThumbnailOrPlaceholder(context, remoteThumbnailUrl);
      }
    } else {
      thumbnailWidget = _buildRemoteThumbnailOrPlaceholder(context, remoteThumbnailUrl);
    }
    return thumbnailWidget;
  }


  Widget _buildRemoteThumbnailOrPlaceholder(BuildContext context, String? remoteThumbnailUrl) {
    // ... (نفس كود المصغرة البعيدة من MessageBubble) ...
    if (remoteThumbnailUrl != null && remoteThumbnailUrl.isNotEmpty) {
      return CachedNetworkImage(
        key: ValueKey(remoteThumbnailUrl),
        imageUrl: remoteThumbnailUrl, fit: BoxFit.cover,
        placeholder: (context, url) => _buildMediaPlaceholder(context, isLoading: true, defaultIcon: Icons.movie_creation_outlined),
        errorWidget: (context, url, error) => _buildMediaPlaceholder(context, isError: true, defaultIcon: Icons.movie_creation_outlined, errorMessage: "خطأ تحميل المصغرة"),
      );
    } else {
      return _buildMediaPlaceholder(context, defaultIcon: Icons.movie_creation_outlined, errorMessage: "لا توجد مصغرة");
    }
  }

  // --- ويدجت لعرض حالة التحميل أو الخطأ ---
  Widget _buildPlaceholderOrError(BuildContext context, VideoPlayerController controller, { required double defaultAspectRatio}) {
    return AspectRatio(
      aspectRatio: defaultAspectRatio, // استخدام النسبة المتوقعة
      child: Container(
        color: Colors.grey.shade800, // خلفية داكنة للفيديو
        alignment: Alignment.center,
        child: controller.hasError.value
        // عرض الخطأ مع زر إعادة المحاولة
            ? Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 30),
              const SizedBox(height: 8),
              Text(
                controller.errorMessage.value.isNotEmpty ? controller.errorMessage.value : "فشل تحميل الفيديو",
                style: const TextStyle(color: Colors.white70, fontSize: 12),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              ElevatedButton.icon( // استخدام زر أوضح لإعادة المحاولة
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text("إعادة المحاولة"),
                onPressed: controller.retryLoading, // استدعاء دالة إعادة المحاولة في المتحكم
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white30,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    textStyle: const TextStyle(fontSize: 12)
                ),
              ),
            ],
          ),
        )
        // عرض مؤشر التحميل
            : const CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
      ),
    );
  }

}