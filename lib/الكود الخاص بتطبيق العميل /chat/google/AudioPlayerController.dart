import 'dart:async';
import 'dart:io'; // للتحقق من الملف المحلي
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:just_audio/just_audio.dart' as ja; // <--- استيراد just_audio

class AudioPlayerController extends GetxController {
  // --- المعاملات الواردة ---
  final String audioSource;   // المسار المحلي أو الرابط البعيد
  final String messageId;     // المعرّف الفريد
  final bool isSourceLocal; // هل المصدر الممرر محلي؟

  // --- المشغل الداخلي من just_audio (نهائي ويُهيأ في onInit) ---
  late final ja.AudioPlayer audioPlayer;

  // --- لا نحتاج لـ Rx variables للحالات الأساسية لأننا سنستخدم Streams ---
  // لكن سنحتفظ بحالة الخطأ ورسالته هنا إذا أردنا عرضها بشكل مركزي
  final RxBool _hasError = false.obs;
  final RxString _errorMessage = ''.obs;
  bool get hasError => _hasError.value;
  String get errorMessage => _errorMessage.value;
  final RxList<double> waveformAmplitudes = <double>[].obs; // لتخزين عينات الموجة

  // ------------------------------------------------------------

  Timer? _seekDebounceTimer; // لـ Slider debounce

  AudioPlayerController({
    required this.audioSource,
    required this.messageId,
    required this.isSourceLocal,
  });

  // === دورة حياة Controller ===
  @override
  void onInit() {
    super.onInit();
    if (kDebugMode) debugPrint("--- [JA AudioPlayerController $messageId] onInit ---");
    audioPlayer = ja.AudioPlayer(
      // يمكنك إضافة تهيئة للـ user agent أو غيرها هنا إذا لزم الأمر
      // userAgent: 'YourAppName/...',
    );
    // --- ربط المستمعين **مرة واحدة** في onInit ---
    // سنقوم بالتعامل مع الأخطاء ضمن هذه المستمعات
    _setupPermanentListeners();
    // --------------------------------------
    _setInitialSource().then((_) {
      if (audioPlayer.duration != null) {
        _generateInitialWaveform(audioPlayer.duration!);
      }
    });
  }

  @override
  void onClose() {
    if (kDebugMode) debugPrint("--- [JA AudioPlayerController $messageId] onClose ---");
    _seekDebounceTimer?.cancel();
    audioPlayer.dispose(); // *** التخلص من مشغل just_audio ***
    super.onClose();
  }


  void _generateInitialWaveform(Duration duration) {
    // إذا لم يتم تمرير waveformData إلى AudioMessageWidget،
    // أو إذا كنت تريد حسابها/تحميلها هنا:
    final Random random = Random();
    final int sampleCount = (duration.inMilliseconds / 70).clamp(15, 50).toInt(); // عدد عينات أقل
    List<double> dummyData = [];
    for (int i = 0; i < sampleCount; i++) {
      dummyData.add(random.nextDouble() * 0.6 + 0.2); // قيم لجعلها تبدو أفضل
    }
    if (waveformAmplitudes.isEmpty) { // فقط إذا لم يتم توفيرها من الخارج
      waveformAmplitudes.assignAll(dummyData);
    }
  }





  // === الإعداد ===
  Future<void> _setInitialSource() async {
    _hasError.value = false; // إعادة تعيين الخطأ عند المحاولة
    _errorMessage.value = '';
    if (kDebugMode) debugPrint("--- [JA AudioPlayerController $messageId] Setting Initial Source ---");

    try {
      ja.AudioSource sourceToSet;
      if (isSourceLocal) {
        if (kDebugMode) debugPrint("    -> Preparing LOCAL Source: $audioSource");
        final file = File(audioSource);
        // التحقق الإضافي من وجود الملف قبل تعيينه (لا يزال جيدًا)
        if(await file.exists() && await file.length() > 0) {
          sourceToSet = ja.AudioSource.uri(Uri.file(audioSource), tag: messageId);
        } else {
          throw PathNotFoundException(audioSource, OSError("Local audio file check failed in _setInitialSource", 2));
        }
      } else {
        if (kDebugMode) debugPrint("    -> Preparing REMOTE Source: $audioSource");
        final uri = Uri.tryParse(audioSource);
        if (uri == null || !uri.isAbsolute) throw Exception("Invalid Remote URL: $audioSource");
        sourceToSet = ja.AudioSource.uri(uri, tag: messageId);
      }

      // تعيين المصدر (قد يستغرق وقتًا للتحميل المسبق)
      // لا تستخدم await هنا إذا أردت إظهار حالة التحميل من الـ stream
      // يمكن للواجهة الآن الاعتماد على playerStateStream لإظهار loading/buffering
      audioPlayer.setAudioSource(sourceToSet, preload: true);
      if (kDebugMode) debugPrint("    -> setAudioSource call initiated for $messageId");

    } catch (e, s) {
      _handleError("Set initial source failed", e, s);
      // لا تتخلص من المشغل هنا، retryLoading يمكن أن تستخدمه
    }
  }

  // --- المستمعات الدائمة ---
  void _setupPermanentListeners() {
    // حالة المشغل (تتضمن Playing, Buffering, Loading, Completed, Idle)
    audioPlayer.playerStateStream.listen((state) {
      if (kDebugMode) debugPrint("  -> [$messageId] State Stream: ProcState=${state.processingState}, Playing=${state.playing}");
      // لا تحتاج لتحديث متغيرات Rx هنا، الـ StreamBuilder في الواجهة تستمع لهذا التيار
      // لكن إذا كان هناك خطأ سابق، نزيله عند العودة لحالة جاهزة
      if(state.processingState == ja.ProcessingState.ready && !state.playing && _hasError.value) {
        _hasError.value = false;
        _errorMessage.value = '';
      }
    }, onError: (e, s) => _handleError("PlayerState Stream Error", e, s));

    // لا نحتاج لمستمعين منفصلين للموضع أو المدة، يمكن قراءتهم مباشرة
    // أو استخدام durationStream / positionStream في الواجهة مع StreamBuilder
  }


  // === التحكم في التشغيل ===
  Future<void> togglePlayPause() async {
    if (kDebugMode) debugPrint("--- [JA AudioPlayerController $messageId] togglePlayPause ---");
    if (hasError) { // <-- استخدام Getter
      if(kDebugMode) debugPrint("   -> Has error, retrying...");
      retryLoading(); return;
    }
    // لا يوجد isLoading منفصل، نعتمد على حالة المشغل processingState

    final processingState = audioPlayer.playerState.processingState;
    final isCurrentlyPlaying = audioPlayer.playing;

    try {
      if (isCurrentlyPlaying) {
        if (kDebugMode) debugPrint("   -> Pausing player.");
        await audioPlayer.pause();
      } else {
        // إذا كان مكتملًا، ارجع للبداية أولاً
        if (processingState == ja.ProcessingState.completed) {
          if (kDebugMode) debugPrint("   -> Player completed. Seeking to 0 before playing.");
          await audioPlayer.seek(Duration.zero);
          // تأخير بسيط جدًا لضمان اكتمال seek قبل play
          await Future.delayed(const Duration(milliseconds: 50));
        }
        // الآن ابدأ التشغيل
        if (kDebugMode) debugPrint("   -> Starting/Resuming play...");
        await audioPlayer.play();
      }
    } catch (e, s) {
      _handleError("Toggle Play/Pause Error", e, s);
    }
  }

  // --- Seek ---
  void seek(Duration position, {bool debounce = false}) {
    // التأكد من وجود مدة قبل البحث (ضروري لـ clamp)
    final currentDuration = audioPlayer.duration;
    if (currentDuration == null || currentDuration == Duration.zero) {
      if (kDebugMode) debugPrint("[$messageId] Seek ignored: Duration is unknown or zero.");
      return;
    }

    if (debounce) {
      _seekDebounceTimer?.cancel();
      _seekDebounceTimer = Timer(const Duration(milliseconds: 200), () => _performSeek(position));
    } else {
      _performSeek(position);
    }
  }

  Future<void> _performSeek(Duration position) async {
    // إعادة التحقق من المدة
    final currentDuration = audioPlayer.duration;
    if (currentDuration == null || currentDuration == Duration.zero) return;

    final clampedPosition = _clampDuration(position, Duration.zero, currentDuration);
    if (kDebugMode) debugPrint("[$messageId] Seeking to: $clampedPosition (Original: $position)");
    try { await audioPlayer.seek(clampedPosition); }
    catch (e, s) { _handleError("Seek Error", e, s); }
  }

  // --- Set Speed (لا تغيير تقريبًا) ---
  Future<void> setSpeed(double speed) async {
    if (hasError) return;
    try { await audioPlayer.setSpeed(speed); }
    catch (e, s) { _handleError("Set Speed Error", e, s); }
  }


  // --- Retry Loading ---
  Future<void> retryLoading() async {
    if (kDebugMode) debugPrint('[$messageId] Retrying audio load by setting source again...');
    // لا نعيد إنشاء المشغل، فقط نعيد تعيين المصدر
    await _setInitialSource(); // استدعاء دالة تعيين المصدر
    // محاولة التشغيل بعد إعادة المحاولة
    if (!hasError) { // <-- استخدام Getter
      try { await audioPlayer.play(); }
      catch (_) {} // تجاهل الخطأ إذا فشل التشغيل الفوري
    }
  }


  // --- معالجة الخطأ ---
  void _handleError(String contextMsg, dynamic error, StackTrace? stackTrace) {
    _hasError.value = true; // <--- تعيين حالة الخطأ
    _errorMessage.value = "$contextMsg: $error"; // تعيين الرسالة
    if (kDebugMode) { debugPrint("!!! [JA AudioPlayerController $messageId] Error - $contextMsg: $error"); if(stackTrace != null) {
      // debugPrint(stackTrace)
    }


    }
    update(); // تحديث واجهة GetBuilder
  }

  // --- دالة المساعدة Clamp (تبقى كما هي) ---
  Duration _clampDuration(Duration value, Duration min, Duration max) {
    final validMax = max > Duration.zero ? max : const Duration(days: 999);
    if (value < min) return min;
    if (value > validMax) return validMax;
    return value;
  }

} // نهاية كلاس AudioPlayerController