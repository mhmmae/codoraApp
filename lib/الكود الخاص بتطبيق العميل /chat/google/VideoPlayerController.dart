import 'dart:async';
import 'dart:io'; // For File based video
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:video_player/video_player.dart' as vp; // Use prefix

class VideoPlayerController extends GetxController {
  final String videoSourceUrl; // Can be network URL or file path
  final String messageId;     // Unique ID for GetX tag and debugging
  final bool isFileSource;   // Flag to know if the source is local file or network

  // --- Public Reactive State Variables ---
  final RxBool isInitialized = false.obs;
  final RxBool isPlaying = false.obs;
  final RxBool isBuffering = false.obs; // Note: video_player's isBuffering might be less reliable than audio's
  final Rx<Duration> totalDuration = Duration.zero.obs;
  final Rx<Duration> currentPosition = Duration.zero.obs;
  final RxBool hasError = false.obs;
  final RxString errorMessage = ''.obs;
  final RxDouble aspectRatio = (16 / 9.0).obs; // Default aspect ratio
  final RxBool isMuted = false.obs;

  // --- Internal Player Instance ---
  final Rx<vp.VideoPlayerController?> _sdkController = Rx<vp.VideoPlayerController?>(null);
  vp.VideoPlayerController? get sdkPlayerController => _sdkController.value;

  VideoPlayerController({
    required this.videoSourceUrl,
    required this.messageId,
    this.isFileSource = false,
  });

  @override
  void onInit() {
    super.onInit();
    _initializePlayer();
  }

  @override
  void onClose() {
    _sdkController.value?.removeListener(_updateStateFromSdk);
    // Dispose should handle potential async operations internally if needed
    _sdkController.value?.dispose();
    _sdkController.value = null; // Clear the reactive variable
    if (kDebugMode) {
      debugPrint('Disposed VideoPlayerController for message: $messageId');
    }
    super.onClose();
  }

  // --- Private Initialization Logic ---
  Future<void> _initializePlayer() async {
    // Reset state flags at the beginning of initialization/retry
    hasError.value = false;
    errorMessage.value = '';
    isInitialized.value = false;
    isPlaying.value = false; // Reset playing state
    isBuffering.value = false; // Reset buffering state
    currentPosition.value = Duration.zero; // Reset position
    totalDuration.value = Duration.zero; // Reset duration

    // Make newController nullable
    vp.VideoPlayerController? newController; // <-- تغيير هنا: أصبح nullable

    try {

      if (isFileSource) {
        if (kDebugMode) debugPrint("[$messageId] Initializing video from file: $videoSourceUrl");
        newController = vp.VideoPlayerController.file(File(videoSourceUrl));
      } else {
        if (kDebugMode) debugPrint("[$messageId] Initializing video from network: $videoSourceUrl");
        newController = vp.VideoPlayerController.networkUrl(Uri.parse(videoSourceUrl));
      }

      // Assign to Rx variable AFTER potential creation failure is handled by catch
      _sdkController.value = newController;

      // Initialize the player (this can throw errors)
      await newController.initialize();

      // --- Check if the controller instance we're working with is still the current one ---
      // This handles race conditions if dispose was called during the await initialize()
      if (_sdkController.value != newController) {
        if (kDebugMode) debugPrint("[$messageId] Controller was disposed during initialization.");
        // Dispose the newly created controller that's no longer needed
        await newController.dispose(); // Use await if dispose is async
        return; // Exit initialization
      }
      // --- End of check ---

      // --- Set initial state from the successfully initialized controller ---
      if(newController.value.isInitialized){ // Double check if init succeeded
        isInitialized.value = true;
        totalDuration.value = newController.value.duration;
        aspectRatio.value = (newController.value.size.width == 0 || newController.value.size.height == 0)
            ? 16/9 // Default if size is invalid
            : newController.value.size.aspectRatio;
        isMuted.value = newController.value.volume == 0;
        // We don't assume it auto-plays, set isPlaying based on its actual state
        isPlaying.value = newController.value.isPlaying;
        isBuffering.value = newController.value.isBuffering;
        // Set position carefully after init
        currentPosition.value = _clampDuration(newController.value.position, Duration.zero, totalDuration.value);


        // Add listener *after* successful initialization
        newController.addListener(_updateStateFromSdk);

        if (kDebugMode) debugPrint("[$messageId] Video initialized successfully. Duration: ${totalDuration.value}, Aspect Ratio: ${aspectRatio.value}");

        // --- Optional: Auto-play ---
        // Uncomment if you want video to play automatically after initialization
        // await newController.play();
        // --- End Optional ---

      } else {
        // Handle cases where initialize completes but isInitialized is false (indicates an issue)
        throw Exception("Player initialization completed but isInitialized is false.");
      }


    } catch (e, stackTrace) {
      _handleError("Initialization failed: $e", stackTrace);
      // --- Safely dispose the controller IF IT WAS CREATED ---
      // Using ?. handles the case where newController might still be null if Uri.parse failed etc.
      await newController?.dispose(); // <-- تغيير هنا: استخدام ?. واستخدام await إذا كانت dispose async
      // --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---
      // Ensure the reactive controller state reflects the failed init
      if (_sdkController.value == newController) {
        _sdkController.value = null;
      }
    }
  }

  // Listener callback to update GetX state from SDK controller state
  void _updateStateFromSdk() {
    // --- التحقق الرئيسي ---
    // 1. هل المتحكم الأساسي (_sdkController.value) موجود؟
    // 2. هل المتحكم الحالي (this GetxController) لم يتم التخلص منه بعد؟ (GetX يدير هذا داخليًا إلى حد ما)
    final sdkValue = _sdkController.value?.value;
    // إذا كان sdkValue هو null، فهذا يعني أن _sdkController هو null أو .value غير صالح،
    // أو ربما تم التخلص من المتحكم الأساسي بالفعل.
    if (sdkValue == null) {
      // يمكن إضافة تسجيل هنا إذا لزم الأمر
      // if(kDebugMode) debugPrint("[$messageId] _updateStateFromSdk called but sdkValue is null.");
      // قد نحتاج لإعادة تعيين حالتنا هنا إذا أصبح sdkValue فجأة null
      if (isInitialized.value || isPlaying.value){
        // Reset state if we thought we were active but sdk is gone
        isInitialized.value = false;
        isPlaying.value = false;
        isBuffering.value = false;
        // لا نعيد تعيين الخطأ هنا تلقائيًا
      }
      return; // لا تتابع إذا لم يكن sdkValue صالحًا
    }
    // --- نهاية التحقق ---


    // Proceed with state updates only if controller and value exist

    final currentSdkInitialized = sdkValue.isInitialized;
    final currentSdkPlaying = sdkValue.isPlaying;
    final currentSdkBuffering = sdkValue.isBuffering;
    final currentSdkDuration = sdkValue.duration;
    final currentSdkPosition = sdkValue.position;
    final currentSdkVolume = sdkValue.volume;
    final currentSdkError = sdkValue.hasError;

    // --- تحديث الحالات التفاعلية ---
    // (الكود الخاص بتحديث isInitialized, isPlaying, etc., يبقى كما كان في النسخة المصححة السابقة)
    // ... (الكود الذي يقوم بـ:
    // if (isInitialized.value != currentSdkInitialized) ...
    // if (isPlaying.value != currentSdkPlaying) ...
    // if (isBuffering.value != currentSdkBuffering) ...
    // etc. ) ...

    // --- مثال على تحديث الحالة من الكود السابق ---
    if (isInitialized.value != currentSdkInitialized) isInitialized.value = currentSdkInitialized;
    if (isPlaying.value != currentSdkPlaying) isPlaying.value = currentSdkPlaying;
    if (isBuffering.value != currentSdkBuffering) isBuffering.value = currentSdkBuffering;

    if (totalDuration.value != currentSdkDuration && currentSdkDuration >= Duration.zero) { // Check >= zero
      totalDuration.value = currentSdkDuration;
    }

    // استخدام clamping هنا مهم
    final clampedSdkPosition = _clampDuration(currentSdkPosition, Duration.zero, totalDuration.value);
    if (currentPosition.value != clampedSdkPosition) {
      currentPosition.value = clampedSdkPosition;
    }

    if (isMuted.value != (currentSdkVolume == 0)) isMuted.value = (currentSdkVolume == 0);

    // التعامل مع تغيير حالة الخطأ
    if (hasError.value != currentSdkError) {
      hasError.value = currentSdkError;
      if (currentSdkError) {
        errorMessage.value = sdkValue.errorDescription ?? "An unknown video error occurred";
        isPlaying.value = false; // التأكد من إيقاف الحالة عند الخطأ
        isBuffering.value = false;
        // عادة ما نعامل الخطأ كغير مهيأ أيضاً
        // isInitialized.value = false; // هذا يحدث تلقائياً غالباً
        if (kDebugMode) debugPrint("[$messageId] Video Error Occurred: ${errorMessage.value}");
      } else {
        // الخطأ تم حله (ربما بعد retry)
        errorMessage.value = '';
      }
    } else if (currentSdkError && errorMessage.value.isEmpty) {
      // حالة نادرة: خطأ موجود ولكن لا توجد رسالة، حاول الحصول عليها
      errorMessage.value = sdkValue.errorDescription ?? "Video error without description";
    }


    // تحديث نسبة العرض للطول
    final sdkSize = sdkValue.size;
    if(sdkSize.width > 0 && sdkSize.height > 0) {
      final sdkAspectRatio = sdkSize.aspectRatio;
      if (aspectRatio.value != sdkAspectRatio) {
        aspectRatio.value = sdkAspectRatio;
      }
    }
  }

  // --- Public Control Methods ---

  Future<void> togglePlayPause() async {
    // Add check: Do nothing if controller is null
    if (!isInitialized.value || hasError.value || _sdkController.value == null) return;

    try {
      final player = _sdkController.value!; // Safe access after null check
      if (player.value.isPlaying) {
        await player.pause();
      } else {
        // If completed, seek to start before playing
        if (player.value.position >= player.value.duration && player.value.duration > Duration.zero) {
          await seek(Duration.zero); // Use our seek method which handles clamping/errors
        }
        await player.play();
      }
      // The listener _updateStateFromSdk handles the state update
    } catch (e, stackTrace) {
      _handleError("Play/Pause command failed: $e", stackTrace);
    }
  }

  Future<void> seek(Duration position) async {
    if (!isInitialized.value || hasError.value || _sdkController.value == null) return;
    try {
      final player = _sdkController.value!;
      final clampedPosition = _clampDuration(position, Duration.zero, player.value.duration);
      // Optimistically update UI slightly for faster feedback
      // Be careful with this if seeks are slow/fail often
      currentPosition.value = clampedPosition;
      await player.seekTo(clampedPosition);
      // The listener will update the state accurately shortly after
    } catch (e, stackTrace) {
      _handleError("Seek command failed: $e", stackTrace);
    }
  }

  Future<void> toggleMute() async {
    if (!isInitialized.value || hasError.value || _sdkController.value == null) return;
    try {
      final player = _sdkController.value!;
      final newVolume = player.value.volume == 0 ? 1.0 : 0.0; // Toggle based on current SDK volume
      await player.setVolume(newVolume);
      // The listener handles the state update for isMuted
    } catch (e, stackTrace) {
      _handleError("Mute/Unmute command failed: $e", stackTrace);
    }
  }

  // Convenience methods are fine
  Future<void> play() async => await togglePlayPause();
  Future<void> pause() async => await togglePlayPause();

  /// Attempts to re-initialize the player after an error.
  Future<void> retryLoading() async {
    if (kDebugMode) debugPrint('[$messageId] Retrying video load...');
    // We need to ensure the old controller is disposed before creating a new one
    final oldController = _sdkController.value;
    if (oldController != null) {
      oldController.removeListener(_updateStateFromSdk);
      await oldController.dispose(); // Wait for disposal if needed
      _sdkController.value = null; // Clear the Rx variable immediately
    }
    // Reset flags managed by our controller
    // hasError.value = false; // _initializePlayer will reset these
    // errorMessage.value = '';
    // isInitialized.value = false;

    // Call initialize which handles resetting state and creating a new player
    await _initializePlayer();
  }


  // --- Private Helper Methods ---

  void _handleError(String message, StackTrace? stackTrace) {
    if (kDebugMode) {
      debugPrint('VideoPlayerController Error [$messageId]: $message');
      if (stackTrace != null) {
        // debugPrint(stackTrace);
      }
    }
    // Update reactive state variables to reflect the error
    hasError.value = true;
    errorMessage.value = message;
    isInitialized.value = false; // Treat error as uninitialized
    isPlaying.value = false; // Stop playback indication
    isBuffering.value = false; // Stop buffering indication
  }

  Duration _clampDuration(Duration value, Duration min, Duration max) {
    // If max is invalid (zero or negative), don't clamp against it upper bound
    final validMax = max > Duration.zero ? max : const Duration(days: 999); // Very large duration

    if (value < min) return min;
    if (value > validMax) return validMax;
    return value;
  }

  // Helper to check internal disposed state (less reliable)
  // Extension method could make this cleaner: controller.isDisposedInternal
  bool get isControllerInternallyDisposed {
    try {
      // Attempting to access certain properties on a disposed controller throws.
      // Accessing `value` itself might not always throw immediately.
      _sdkController.value?.value; // Access value to potentially trigger disposed exception
      // Access another property that likely throws when disposed
      _sdkController.value?.dataSource; // Use dataSource instead of textureId
      return false; // If no exception, assume not disposed (may not be fully reliable)
    } catch (_) {
      // If an exception occurs, it's likely disposed.
      return true;
    }
  }
}