import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:photo_view/photo_view.dart';
import 'package:video_player/video_player.dart' as vp;
import 'package:flutter/foundation.dart';


class ViewMediaScreen extends StatelessWidget { // <-- تغيير إلى StatelessWidget
  final String? imageUrl;
  final String? videoUrl;
  final bool isLocalFile;
  final Object? heroTag;

  // منشئ مع تأكيد إلزامي لأحد المصادر
  const ViewMediaScreen({
    super.key,
    this.imageUrl,
    this.videoUrl,
    required this.isLocalFile,
    this.heroTag,
  }) : assert((imageUrl != null) ^ (videoUrl != null));

  @override
  Widget build(BuildContext context) {
    // --- حقن/إيجاد المتحكم مع تمرير البيانات اللازمة ---
    // نستخدم tag لضمان عدم تداخله مع متحكمات فيديو/صور أخرى
    final String uniqueTag = imageUrl ?? videoUrl ?? UniqueKey().toString(); // استخدم المصدر أو مفتاح فريد
    final ViewMediaController controller = Get.put(
      ViewMediaController(
        imageUrl: imageUrl,
        videoUrl: videoUrl,
        isLocalFile: isLocalFile,
      ),
      tag: uniqueTag, // TAG فريد لهذه الشاشة
      // permanent: false, // يتخلص منه GetX عند إغلاق الشاشة عادةً
    );

    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent, elevation: 0,
        leading: IconButton(icon: const Icon(Icons.close_rounded, color: Colors.white, size: 28), onPressed: () => Get.back()),
        // actions...
      ),
      body: Center(
        // --- إزالة Obx من هنا ---
        child: _buildConditionalMediaContent(controller), // <-- دالة مساعدة جديدة
        // ---------------------
      ),
    );
  }

// --- دالة مساعدة جديدة لتحديد المحتوى ---
  Widget _buildConditionalMediaContent(ViewMediaController controller){
    if (controller.videoUrl != null) {
      // --- الجزء الخاص بالفيديو لا يزال يحتاج Obx داخله لمراقبة حالة الفيديو ---
      return Obx((){ // <--- Obx هنا حول جزء الفيديو فقط
        if(controller.hasVideoError.value) { return _buildErrorWidget(controller.videoErrorMsg.value, () => controller.retryVideoLoading()); }
        if(!controller.isVideoInitialized.value || controller.sdkVideoController == null) { return const CircularProgressIndicator(color: Colors.white); }
        return _buildVideoPlayerUI(controller); // الدالة السابقة للفيديو
      });
    } else if (controller.imageUrl != null) {
      // --- عرض الصورة لا يحتاج Obx إذا لم تكن هناك حالة تفاعلية له ---
      return _buildPhotoViewUI(controller); // الدالة السابقة للصورة
    } else {
      // حالة خطأ
      return _buildErrorWidget("لم يتم تحديد مصدر الوسائط.", null);
    }
  }
  // --- ويدجت بناء مشغل الفيديو (تستخدم حالة Controller) ---
  Widget _buildVideoPlayerUI(ViewMediaController controller) {
    // Obx يراقب التغييرات في القيم التالية داخل المتحكم
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Expanded(
          child: Center(
            child: AspectRatio(
              aspectRatio: controller.videoAspectRatio.value,
              child: GestureDetector(
                onTap: controller.toggleVideoPlayPause,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // التأكد من وجود sdkPlayerController قبل استخدامه
                    if(controller.sdkVideoController != null)
                      vp.VideoPlayer(controller.sdkVideoController!),

                    // مؤشر التحميل Buffering
                    if (controller.isVideoBuffering.value)
                      const CircularProgressIndicator(strokeWidth: 2, color: Colors.white70),

                    // زر التشغيل overlay
                    AnimatedOpacity(
                      opacity: controller.isVideoPlaying.value ? 0.0 : 1.0,
                      duration: const Duration(milliseconds: 300),
                      child: Visibility(
                        visible: !controller.isVideoPlaying.value,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                          child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 50),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        // --- شريط التقدم ---
        // مراقبة isVideoInitialized مرة أخرى للأمان
        if (controller.isVideoInitialized.value && controller.sdkVideoController != null)
          vp.VideoProgressIndicator(
            controller.sdkVideoController!,
            allowScrubbing: true,
            padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 16.0),
            colors: const vp.VideoProgressColors(
              playedColor: Colors.white,
              bufferedColor: Colors.white54,
              backgroundColor: Colors.white24,
            ),
          ),
      ],
    );
  }

  // --- ويدجت بناء عارض الصور ---
  Widget _buildPhotoViewUI(ViewMediaController controller) {
    ImageProvider imageProviderToShow;
    if (controller.isLocalFile) {
      try { imageProviderToShow = FileImage(File(controller.imageUrl!)); }
      catch (e) { return _buildErrorWidget("خطأ تحميل ملف الصورة المحلي", null); }
    } else {
      if (Uri.tryParse(controller.imageUrl!)?.hasScheme ?? false) { imageProviderToShow = CachedNetworkImageProvider(controller.imageUrl!); }
      else { return _buildErrorWidget("رابط صورة غير صالح", null); }
    }

    return PhotoView(
      imageProvider: imageProviderToShow,
      loadingBuilder: (context, event) => const Center(child: CircularProgressIndicator(color: Colors.white)),
      errorBuilder: (context, error, stackTrace) {
        if(kDebugMode) debugPrint("!!! PhotoView Error: $error");
        return const Center(child: Icon(Icons.broken_image_outlined, color: Colors.white54, size: 60));
      },
      minScale: PhotoViewComputedScale.contained * 0.9,
      maxScale: PhotoViewComputedScale.covered * 3.0,
      // heroTag يتم استقباله من الـ Widget الأصلي مباشرة
      heroAttributes: heroTag != null ? PhotoViewHeroAttributes(tag: heroTag!) : null,
    );
  }


  // --- ويدجت لعرض الخطأ (تقبل callback لإعادة المحاولة) ---
  Widget _buildErrorWidget(String errorMessage, VoidCallback? onRetry) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 50),
          const SizedBox(height: 15),
          Text( errorMessage, style: const TextStyle(color: Colors.white70, fontSize: 16), textAlign: TextAlign.center),
          // عرض زر إعادة المحاولة فقط إذا تم تمرير دالة له
          if (onRetry != null) ...[
            const SizedBox(height: 20),
            ElevatedButton.icon(
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text("إعادة المحاولة"),
              onPressed: onRetry, // <--- استدعاء callback
              style: ElevatedButton.styleFrom( /* ... */ ),
            ),
          ]
        ],
      ),
    );
  }

} // نهاية ViewMediaScreen




class ViewMediaController extends GetxController {
  // --- المعاملات التي سيتلقاها عند إنشائه ---
  final String? videoUrl;
  final String? imageUrl; // يمكن الاحتفاظ به إذا احتجته في المتحكم لسبب ما
  final bool isLocalFile;
  // ------------------------------------------

  // --- حالات الفيديو التفاعلية ---
  final RxBool isVideoInitialized = false.obs;
  final RxBool isVideoPlaying = false.obs;
  final RxBool isVideoBuffering = false.obs; // (قد تكون أقل موثوقية)
  final Rx<Duration> videoPosition = Duration.zero.obs;
  final Rx<Duration> videoDuration = Duration.zero.obs;
  final RxDouble videoAspectRatio = (16 / 9.0).obs;
  final RxBool hasVideoError = false.obs;
  final RxString videoErrorMsg = ''.obs;
  // --------------------------------

  // --- المتحكم الأصلي لمشغل الفيديو ---
  // اجعله nullable وقابلاً للتحديث بشكل تفاعلي إذا احتجت لذلك
  final Rx<vp.VideoPlayerController?> _sdkVideoController = Rx<vp.VideoPlayerController?>(null);
  vp.VideoPlayerController? get sdkVideoController => _sdkVideoController.value;
  // -------------------------------------

  // --- المنشئ (Constructor) ---
  ViewMediaController({
    this.videoUrl,
    this.imageUrl, // يستقبله ولكن قد لا يستخدمه مباشرة
    required this.isLocalFile,
  });

  // === دورة الحياة ===
  @override
  void onInit() {
    super.onInit();
    if (kDebugMode) debugPrint("[ViewMediaController] onInit. Video URL: $videoUrl, Image URL: $imageUrl, isLocal: $isLocalFile");
    // تهيئة مشغل الفيديو فقط إذا تم تمرير رابط فيديو
    if (videoUrl != null && videoUrl!.isNotEmpty) {
      _initializeVideoPlayer();
    } else if(imageUrl == null || imageUrl!.isEmpty){
      // حالة خطأ: لم يتم تمرير مصدر صالح
      debugPrint("!!! [ViewMediaController] No valid video or image source provided!");
      hasVideoError.value = true; // استخدم hasVideoError كحالة خطأ عامة
      videoErrorMsg.value = "لم يتم توفير مصدر وسائط صالح.";
    }
    // لا نحتاج لتهيئة للصور لأنها ستُعرض مباشرة بواسطة PhotoView
  }

  @override
  void onClose() {
    if (kDebugMode) debugPrint("[ViewMediaController] onClose.");
    // التخلص من المتحكم الأصلي للفيديو ومسح المستمعين
    final player = _sdkVideoController.value;
    if(player != null){
      player.removeListener(_updateVideoState); // <-- إزالة المستمع مهمة
      player.dispose();
      _sdkVideoController.value = null; // <-- تعيينه null
      if(kDebugMode) debugPrint("   -> SDK Video Player disposed.");
    }
    super.onClose();
  }


  // --- تهيئة مشغل الفيديو ---
  Future<void> _initializeVideoPlayer() async {
    hasVideoError.value = false; videoErrorMsg.value = ''; isVideoInitialized.value = false;

    // التخلص من أي مشغل قديم قبل إنشاء الجديد
    await _sdkVideoController.value?.dispose();
    _sdkVideoController.value = null;


    if (videoUrl == null || videoUrl!.isEmpty) {
      _handleVideoError("رابط الفيديو مفقود."); return;
    }

    if (kDebugMode) debugPrint("[ViewMediaController] Initializing video player for: $videoUrl (isLocal: $isLocalFile)");

    vp.VideoPlayerController newController;
    try {
      if (isLocalFile) {
        newController = vp.VideoPlayerController.file(File(videoUrl!));
      } else {
        // التحقق من صحة URL الشبكة
        if (!Uri.tryParse(videoUrl!)!.hasScheme || !Uri.tryParse(videoUrl!)!.hasAuthority) {
          throw Exception("Invalid network URL format: $videoUrl");
        }
        newController = vp.VideoPlayerController.networkUrl(Uri.parse(videoUrl!));
      }

      // تعيين المتحكم الجديد للمتغير التفاعلي
      _sdkVideoController.value = newController;

      await newController.initialize(); // انتظر التهيئة

      // تحقق مرة أخرى إذا كان GetX Controller لا يزال موجوداً
      if (!isClosed && _sdkVideoController.value == newController) {
        if (newController.value.isInitialized) {
          videoDuration.value = newController.value.duration;
          videoAspectRatio.value = newController.value.size.aspectRatio > 0 ? newController.value.size.aspectRatio : 16/9;
          await newController.setVolume(1.0); // التأكد من وجود الصوت
          await newController.setLooping(false); // عدم التكرار
          newController.addListener(_updateVideoState); // <-- إضافة المستمع
          isVideoInitialized.value = true; // الآن جاهز
          await newController.play(); // تشغيل تلقائي
          if (kDebugMode) debugPrint("[ViewMediaController] Video initialized successfully.");
        } else {
          throw Exception("Video player completed initialization but isInitialized is false.");
        }
      } else {
        if(kDebugMode) debugPrint("[ViewMediaController] Controller was closed during video init. Disposing new player.");
        await newController.dispose(); // تخلص منه لأنه لم يعد مستخدمًا
      }

    } catch (e, s) {
      _handleVideoError("فشل تهيئة مشغل الفيديو: $e", s);
      await _sdkVideoController.value?.dispose(); // تخلص من المتحكم الفاشل
      _sdkVideoController.value = null; // التأكد أنه null
    }
  }

  // --- المستمع لتحديث حالات الفيديو التفاعلية ---
  void _updateVideoState() {
    final sdkValue = _sdkVideoController.value?.value;
    if (sdkValue == null || isClosed) return; // التأكد من وجود المتحكم وعدم إغلاق الـ Controller GetX

    // تحديث الحالات التفاعلية (أضف hasError أيضاً)
    if (isVideoPlaying.value != sdkValue.isPlaying) isVideoPlaying.value = sdkValue.isPlaying;
    if (isVideoBuffering.value != sdkValue.isBuffering) isVideoBuffering.value = sdkValue.isBuffering;
    if (videoDuration.value != sdkValue.duration && sdkValue.duration > Duration.zero) videoDuration.value = sdkValue.duration; // تحديث المدة إن تغيرت وكانت صالحة
    // تحديث الموضع بحذر
    final newPos = sdkValue.position;
    if (newPos >= Duration.zero && newPos <= videoDuration.value && videoPosition.value != newPos) videoPosition.value = newPos;
    if (hasVideoError.value != sdkValue.hasError) hasVideoError.value = sdkValue.hasError;
    if (hasVideoError.value && videoErrorMsg.value.isEmpty) videoErrorMsg.value = sdkValue.errorDescription ?? "خطأ فيديو غير معروف.";
    if (!hasVideoError.value && videoErrorMsg.isNotEmpty) videoErrorMsg.value = ''; // مسح الخطأ

  }


  // --- التحكم في التشغيل ---
  void toggleVideoPlayPause() {
    final player = _sdkVideoController.value;
    if (player == null || !isVideoInitialized.value || hasVideoError.value) return;
    try {
      if (player.value.isPlaying) { player.pause(); }
      else {
        // إذا اكتمل، ارجع للبداية
        if (player.value.position >= player.value.duration && player.value.duration > Duration.zero) {
          player.seekTo(Duration.zero);
        }
        player.play();
      }
    } catch(e,s){ _handleVideoError("خطأ في التشغيل/الإيقاف: $e",s); }
  }


  // --- معالجة الخطأ ---
  void _handleVideoError(String message, [StackTrace? stackTrace]) {
    if (kDebugMode) {
      debugPrint("!!! [ViewMediaController] Video Error: $message");
      if(stackTrace != null) {
        // debugPrint(stackTrace)
      }
    }
    hasVideoError.value = true;
    videoErrorMsg.value = message;
    isVideoInitialized.value = false; // غير مهيأ في حالة الخطأ
    isVideoPlaying.value = false; // ليس قيد التشغيل
    isVideoBuffering.value = false; // ليس قيد التحميل
  }

  // --- إعادة محاولة تحميل الفيديو ---
  Future<void> retryVideoLoading() async {
    if (kDebugMode) debugPrint("[ViewMediaController] Retrying video load...");
    // ببساطة استدعي التهيئة مرة أخرى
    await _initializeVideoPlayer();
  }

}