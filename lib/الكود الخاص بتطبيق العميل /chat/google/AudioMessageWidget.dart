import 'dart:io';
import 'package:path/path.dart' as p; // تأكد من وجود الاستيراد

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';

// تأكد من استيراد هذه الملفات من مساراتها الصحيحة في مشروعك
import 'AudioPlayerController.dart';
import 'Helpers.dart';

import 'package:just_audio/just_audio.dart' as ja; // <-- استيراد مهم

class AudioMessageWidget extends StatelessWidget {
  final String remoteAudioUrl;
  final bool isMe;
  final String messageId;
  final String? localAudioFileName; // اسم الملف
  final List<double>? waveformData; // قيم بين 0.0 و 1.0 تمثل ارتفاعات الموجة

  const AudioMessageWidget({
    super.key,
    this.localAudioFileName,
    required this.remoteAudioUrl,
    required this.isMe,
    required this.messageId,
    this.waveformData, // اجعله اختياريًا

  });

  Widget _buildErrorState(String errorMsg){
    return Container( height: 50, alignment: Alignment.centerLeft, padding: EdgeInsets.only(left: 15),
        child: Row(children: [ Icon(Icons.error, color: Colors.red), SizedBox(width: 5), Text(errorMsg, style: TextStyle(fontSize: 12, color: Colors.red)) ] ) );
  }

  Future<String?> getFullLocalPath(String? localFileName) async {
    if (localFileName == null || localFileName.isEmpty) return null;
    try {
      final appDocsDir = await getApplicationDocumentsDirectory();
      final mediaPath = p.join(appDocsDir.path, 'sent_media', localFileName);
      // يمكنك إضافة تحقق من وجود الملف هنا إذا أردت
      // if(await File(mediaPath).exists()){ return mediaPath; } else { return null;}
      return mediaPath;
    } catch (e) {
      return null;
    }
  }


  /// دالة مساعدة لبناء المسار المطلق الكامل للملف المحلي
  Future<String?> _buildFullLocalPath(String? localFileName) async {
    // إذا لم يتم تمرير اسم ملف، لا يوجد مسار محلي
    if (localFileName == null || localFileName.isEmpty) return null;
    try {
      final appDocsDir = await getApplicationDocumentsDirectory();
      // بناء المسار داخل المجلد المخصص 'sent_media'
      final mediaPath = p.join(appDocsDir.path, 'sent_media', localFileName);
      if(kDebugMode) debugPrint("[AudioMsgWidget $messageId] Constructed full local path: $mediaPath");
      // **التحقق النهائي هنا (اختياري ولكنه جيد)**:
      // تحقق من وجود الملف في المسار المبني قبل إعادته
      // إذا لم يكن موجودًا، فهذا يعني خطأً حقيقياً في الحفظ أو الحذف
      final file = File(mediaPath);
      if (await file.exists() && await file.length() > 0) {
        if(kDebugMode) debugPrint("   -> File check successful.");
        return mediaPath; // أعد المسار فقط إذا كان الملف موجودًا بالفعل
      } else {
        if(kDebugMode) debugPrint("   !!! File check FAILED! File doesn't exist or is empty at constructed path.");
        return null; // الملف غير موجود في المسار المتوقع
      }
    } catch (e) {
      if (kDebugMode) debugPrint("!!! Error constructing or checking local path for $localFileName: $e");
      return null;
    }
  }

  //

  @override
  Widget build(BuildContext context) {
    Widget playerContent;

    // **احصل على حالة الرسالة من الكائن الممرر (عبر MessageBubble)**
    // افترض أن message.status مُتاح هنا. إذا لم يكن كذلك، يجب تمريره من MessageBubble.
    // للحظة، سنفترض أنه يمكننا بطريقة ما معرفة حالة التنزيل للرسالة.
    // هذا يتطلب تمرير كائن Message الكامل إلى AudioMessageWidget أو على الأقل حالته ومساره.

    // الطريقة الأفضل: يجب أن تستقبل AudioMessageWidget كائن Message بأكمله
    // أو على الأقل الحالة والمسار واسم الملف بشكل منفصل.
    // سنفترض أنك عدلتها لتقبل Message:
    // final Message message; // يجب تمريرها من MessageBubble

    // إذا لم يكن message.localFilePath موجودًا (أو إذا كانت الحالة downloading/failed)
    // لا تحاول بناء المسار المحلي مباشرة للتشغيل.
    //  سنبسط الآن بالافتراض أننا نعتمد على ما إذا كان localAudioFileName ممررًا أم لا.

    final bool isLikelyDownloaded = localAudioFileName != null && localAudioFileName!.isNotEmpty;
    final String sourceToUse = isLikelyDownloaded ? localAudioFileName! : remoteAudioUrl;
    final bool isSourceEffectivelyLocal = isLikelyDownloaded;

    if (sourceToUse.isEmpty) {
      return _buildErrorState("لا يوجد مصدر صوتي");
    }

    return FutureBuilder<String?>(
      future: _buildFullLocalPath(localAudioFileName),
      builder: (context, snapshot) {
        // --- حالات بناء المسار ---
        if (snapshot.connectionState != ConnectionState.done) {
          return const SizedBox( height: 50, child: Center(child: SizedBox(width: 15, height: 15, child: CircularProgressIndicator(strokeWidth: 1.5))));
        }
        if (snapshot.hasError || snapshot.data == null && localAudioFileName != null) { // اعتبر فشل البناء خطأ
          return _buildErrorState("خطأ الوصول للملف المحلي");
        }
        // ---------------------------

        final String? fullLocalPath = snapshot.data;
        final bool shouldUseLocal = fullLocalPath != null;
        final String sourceToUse = shouldUseLocal ? fullLocalPath : remoteAudioUrl;
        final bool isSourceLocal = shouldUseLocal;
        final bool shouldUseLocalAudio = fullLocalPath != null; // هل المسار المحلي صالح الآن؟
        final String audioSourceForPlayer = shouldUseLocalAudio ? fullLocalPath : remoteAudioUrl;
        final bool isPlayerSourceLocal = shouldUseLocalAudio;
        if (sourceToUse.isEmpty) return _buildErrorState("لا يوجد مصدر صوتي");

        // --- الحصول على/إنشاء المتحكم ---
        final AudioPlayerController controller = Get.put(
          AudioPlayerController(
            audioSource: audioSourceForPlayer, // المسار الفعلي المستخدم
            messageId: messageId,
            isSourceLocal: isPlayerSourceLocal, // هل المصدر الذي مررناه للتو محلي؟
          ),
          tag: messageId,
        );
        if (audioSourceForPlayer.isEmpty) {
          return _buildErrorState("لا يوجد مصدر صوتي");
        }


        if (localAudioFileName != null && localAudioFileName!.isNotEmpty && !shouldUseLocalAudio && snapshot.connectionState == ConnectionState.done) {
          // كان من المفترض أن يكون الملف محليًا (لأن localAudioFileName موجود)، لكن _buildFullLocalPath فشل.
          // هذا يعني "خطأ الوصول للملف المحلي" أو "فشل التنزيل" إذا كانت هذه الحالة متتبعة.
          // هنا يمكنك عرض زر إعادة المحاولة للتنزيل إذا كان هذا مناسبًا.
          // For now, the AudioPlayerController might handle retrying if its source is remote and fails.
          // Or, if you know it *should* be local but isn't, display a specific error/retry for download.
          //  if (message.status == MessageStatus.downloadFailed) {
          //      return _buildRetryDownloadButton();
          //  }
          //  if (message.status == MessageStatus.downloading) {
          //      return Center(child: CircularProgressIndicator());
          //  }
          return _buildErrorState("فشل الوصول للملف الصوتي المحلي.");
        }
        // --- بناء الواجهة باستخدام StreamBuilders ---
        final accentColor = isMe ? Colors.teal.shade600 : Theme.of(context).primaryColor;
        final iconColor = isMe ? Colors.black.withOpacity(0.6) : Colors.black.withOpacity(0.7);
        final timeColor = Colors.grey[600];
        final List<double> displayWaveformData = waveformData ?? List.generate(30, (index) => (index % 5 + 1) * 0.15 + 0.1);

        return Container(
          constraints: const BoxConstraints(minHeight: 48, minWidth: 180, maxWidth: 250), // تحديد حجم
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildPlayControlButtonWithStream(controller, accentColor, iconColor), // الزر كما هو
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // --- [مهم] استخدام StreamBuilder هنا ---
                    SizedBox( // لتحديد ارتفاع ثابت لمنطقة الموجة
                      height: 32,
                      child: StreamBuilder<ja.PlayerState>(
                        stream: controller.audioPlayer.playerStateStream, // حالة المشغل
                        builder: (context, playerStateSnapshot) {
                          final playerState = playerStateSnapshot.data;
                          final processingState = playerState?.processingState;

                          // إذا كان هناك خطأ في المتحكم
                          if (controller.hasError) {
                            return InkWell(
                                onTap: controller.retryLoading,
                                child: Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 4.0),
                                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                                      Icon(Icons.warning_amber_rounded, color: Colors.redAccent.shade100, size: 14),
                                      const SizedBox(width: 4),
                                      Flexible(child: Text(controller.errorMessage.isNotEmpty ? controller.errorMessage : "فشل التحميل", style: TextStyle(color: Colors.red.shade800, fontSize: 11), overflow: TextOverflow.ellipsis)),
                                      const SizedBox(width: 4),
                                      const Icon(Icons.refresh_rounded, size: 14, color: Colors.blueAccent)
                                    ])));
                          }

                          // عرض مؤشر خطي أثناء التحميل
                          if (processingState == ja.ProcessingState.loading || processingState == ja.ProcessingState.buffering) {
                            return Center(
                              child: SizedBox(
                                height: 2, // ارتفاع المؤشر الخطي
                                child: LinearProgressIndicator(
                                  valueColor: AlwaysStoppedAnimation<Color>(accentColor.withOpacity(0.6)),
                                  backgroundColor: accentColor.withOpacity(0.2),
                                ),
                              ),
                            );
                          }


                          return StreamBuilder<Duration?>(
                            stream: controller.audioPlayer.durationStream, // مدة المقطع
                            builder: (context, durationSnapshot) {
                              final duration = durationSnapshot.data ?? Duration.zero;
                              return StreamBuilder<Duration>(
                                stream: controller.audioPlayer.positionStream, // الموضع الحالي
                                builder: (context, positionSnapshot) {
                                  var position = positionSnapshot.data ?? Duration.zero;
                                  if (position > duration && duration != Duration.zero) position = duration;

                                  final double progressValue = (duration.inMilliseconds > 0)
                                      ? (position.inMilliseconds / duration.inMilliseconds).clamp(0.0, 1.0)
                                      : 0.0;

                                  return CustomPaint(
                                    size: const Size(double.infinity, double.infinity), // اجعلها تملأ المساحة المتاحة
                                    painter: AudioWaveformPainter(
                                      waveData: displayWaveformData, // استخدم البيانات المجهزة
                                      progress: progressValue,
                                      waveColor: isMe ? Colors.green.shade300.withOpacity(0.8) : Theme.of(context).colorScheme.primaryContainer.withOpacity(0.7),
                                      progressColor: isMe ? Colors.teal.shade600 : Theme.of(context).primaryColor,
                                      isMe: isMe,
                                    ),
                                  );
                                },
                              );
                            },
                          );
                        },
                      ),
                    ),
                    // --------------------------------------
                    const SizedBox(height: 1),
                    Align(
                        alignment: isMe ? Alignment.topLeft : Alignment.bottomRight, // عكس مكان الوقت
                        child: _buildTimeTextWithStreams(controller, timeColor) // الوقت كما هو
                    ),
                  ],
                ),
              ),
              if(isMe) const SizedBox(width: 5), // مسافة إضافية صغيرة للرسائل المرسلة
            ],
          ),
        );
      },
    ); // نهاية Container الرئيسي
      // نهاية FutureBuilder
  }





  // --- بناء زر التحكم (يستخدم Getters مباشرة أو الحالة من StreamBuilder) ---
  // --- بناء زر التحكم باستخدام تيار حالة المشغل ---
  Widget _buildPlayControlButtonWithStream(AudioPlayerController controller, Color accentColor, Color iconColor) {
    return StreamBuilder<ja.PlayerState>( // <-- الاستماع للحالة
        stream: controller.audioPlayer.playerStateStream,
        builder: (context, snapshot) {
          final playerState = snapshot.data;
          final processingState = playerState?.processingState ?? ja.ProcessingState.idle;
          final isPlaying = playerState?.playing ?? false;
          final isLoading = processingState == ja.ProcessingState.loading || processingState == ja.ProcessingState.buffering;
          // هل هناك خطأ فعلي الآن (من hasError في الـ Controller)؟
          final hasError = controller.hasError; // <--- الوصول للـ getter مباشرة

          return InkWell(
            onTap: isLoading ? null : (hasError ? controller.retryLoading : controller.togglePlayPause),
            borderRadius: BorderRadius.circular(25),
            child: Container(
              width: 40, height: 40, padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(color: accentColor.withOpacity(0.1), shape: BoxShape.circle),
              child: Stack( /* ... Stack لعرض أيقونة/تحميل بناءً على isLoading, isPlaying, hasError ... */
                alignment: Alignment.center,
                children: [
                  if (!isLoading)
                    Icon(
                      hasError ? Icons.refresh_rounded // <--- أيقونة إعادة المحاولة عند الخطأ
                          : isPlaying ? Icons.pause_rounded
                          : Icons.play_arrow_rounded,
                      color: hasError ? Colors.redAccent : iconColor,
                      size: 28,
                    ),
                  if (isLoading)
                    SizedBox(width: 26, height: 26, child: CircularProgressIndicator(/* ... */)),
                ],
              ),
            ),
          );
        }
    );
  }


  // --- **بناء شريط التقدم باستخدام التيارات** ---
  Widget _buildProgressBarWithStreams(AudioPlayerController controller, Color accentColor, Color backgroundColor) {
    if(controller.hasError){ // التعامل مع الخطأ أولاً
      return InkWell(  onTap: controller.retryLoading, // السماح بإعادة المحاولة عند النقر على الخطأ
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.redAccent.shade100, size: 16),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  controller.errorMessage.isNotEmpty ? controller.errorMessage : "فشل تحميل الصوت",
                  style: TextStyle(color: Colors.red.shade800, fontSize: 12),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 4),
              const Icon(Icons.refresh_rounded, size: 16, color: Colors.blueAccent,)
            ],
          ),
        ),
      );
    }

    return StreamBuilder<ja.PlayerState>( // <--- الاستماع لحالة المشغل
        stream: controller.audioPlayer.playerStateStream, // استخدم المشغل الداخلي
        builder: (context, snapshot) {
          final state = snapshot.data;
          final processingState = state?.processingState ?? ja.ProcessingState.idle;

          // عرض مؤشر خطي أثناء التحميل/التهيئة
          if (processingState == ja.ProcessingState.loading || processingState == ja.ProcessingState.buffering) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 10.0), // ضبط الهوامش للـ LinearProgressIndicator
              child: LinearProgressIndicator(
                minHeight: 2, // ارتفاع الشريط
                valueColor: AlwaysStoppedAnimation<Color>(accentColor.withOpacity(0.5)),
                backgroundColor: accentColor.withOpacity(0.2),
              ),
            );
          }

          // عرض Slider لبقية الحالات (Ready, Completed, Idle بعد التشغيل)
          return StreamBuilder<Duration?>( // <-- تيار للمدة
              stream: controller.audioPlayer.durationStream,
              builder: (context, durationSnapshot) {
                final duration = durationSnapshot.data ?? Duration.zero;
                return StreamBuilder<Duration>( // <-- تيار للموضع
                    stream: controller.audioPlayer.positionStream,
                    builder: (context, positionSnapshot) {
                      var position = positionSnapshot.data ?? Duration.zero;
                      // التأكد أن الموضع لا يتجاوز المدة
                      if (position > duration) position = duration;
                      // عرض Slider بقيم من التيارات
                      return SliderTheme(
                        data: SliderTheme.of(context).copyWith( /* ... */ ),
                        child: Slider(
                          value: position.inMilliseconds.toDouble(),
                          min: 0.0,
                          max: duration.inMilliseconds.toDouble() > 0 ? duration.inMilliseconds.toDouble() : 1.0,
                          onChanged: (value) {
                            controller.seek(Duration(milliseconds: value.toInt()), debounce: true);
                          },
                        ),
                      );
                    }
                );
              }
          );
        }
    );
  }

  // --- **بناء نص الوقت باستخدام التيارات** ---
  Widget _buildTimeTextWithStreams(AudioPlayerController controller, Color? timeColor) {
    return StreamBuilder<ja.PlayerState>( // استمع للحالة لمعرفة متى تعرض loading/error
        stream: controller.audioPlayer.playerStateStream,
        builder: (context, stateSnapshot) {
          final state = stateSnapshot.data;
          final processingState = state?.processingState ?? ja.ProcessingState.idle;
          final isPlaying = state?.playing ?? false;

          if (controller.hasError) return const Text("--:--", style: TextStyle(fontSize: 11.5)); // وقت الخطأ
          if (processingState == ja.ProcessingState.loading || processingState == ja.ProcessingState.buffering) {
            return const Text("تحميل...", style: TextStyle(fontSize: 11.5)); // وقت التحميل
          }

          return StreamBuilder<Duration?>( // استمع للمدة
              stream: controller.audioPlayer.durationStream,
              builder: (context, durationSnapshot) {
                final duration = durationSnapshot.data ?? Duration.zero;
                return StreamBuilder<Duration>( // استمع للموضع
                    stream: controller.audioPlayer.positionStream,
                    builder: (context, positionSnapshot) {
                      final position = positionSnapshot.data ?? Duration.zero;
                      String timeLabel;
                      // حساب الوقت المتبقي أو الإجمالي بناءً على الحالة والموضع
                      if (duration > Duration.zero) {
                        if (isPlaying || position > Duration.zero && processingState != ja.ProcessingState.completed) {
                          final remaining = duration - position;
                          timeLabel = Helpers.formatDuration(remaining >= Duration.zero ? remaining : Duration.zero);
                        } else { // Completed or Idle at start
                          timeLabel = Helpers.formatDuration(duration);
                        }
                      } else {
                        timeLabel = "--:--"; // مدة غير معروفة
                      }
                      return Text(timeLabel, style: TextStyle(fontSize: 11.5, color: timeColor));
                    }
                );
              }
          );
        }
    );
  }

}


class AudioWaveformPainter extends CustomPainter { // (ضع تعريف AudioWaveformPainter هنا أو في ملف منفصل)
  final List<double> waveData;
  final double progress;
  final Color waveColor;
  final Color progressColor;
  final bool isMe;

  AudioWaveformPainter({
    required this.waveData,
    required this.progress,
    required this.waveColor,
    required this.progressColor,
    this.isMe = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (waveData.isEmpty) { // عرض خط أفقي إذا لم تكن هناك بيانات موجة
      final Paint linePaint = Paint()
        ..color = waveColor.withOpacity(0.5)
        ..strokeWidth = 1.5
        ..style = PaintingStyle.stroke;
      canvas.drawLine(Offset(0, size.height / 2), Offset(size.width, size.height / 2), linePaint);
      return;
    }

    final Paint wavePaint = Paint()..color = waveColor..style = PaintingStyle.fill;
    final Paint progressPaint = Paint()..color = progressColor..style = PaintingStyle.fill;

    final double barWidth = 2.5;
    final double barSpacing = 1.5;
    final double totalBarSpace = barWidth + barSpacing;
    final int numBars = waveData.length;
    final double middleY = size.height / 2;

    for (int i = 0; i < numBars; i++) {
      final double barRawHeight = waveData[i] * size.height; // يمكن أن يصل لـ 100%
      final double barDisplayHeight = (barRawHeight * 0.8).clamp(2.0, size.height * 0.8); // حد أدنى وأقصى لارتفاع الشريط
      final double x = i * totalBarSpace;
      final double y = middleY - (barDisplayHeight / 2);
      final double actualX = isMe ? size.width - x - barWidth : x;

      final Rect barRect = Rect.fromLTWH(actualX, y.clamp(0, size.height - barDisplayHeight), barWidth, barDisplayHeight);
      canvas.drawRRect(RRect.fromRectAndRadius(barRect, const Radius.circular(1.5)), wavePaint);
    }

    final double progressWidth = progress * (numBars * totalBarSpace - barSpacing);
    if (progressWidth > 0) {
      for (int i = 0; i < numBars; i++) {
        final double barRawHeight = waveData[i] * size.height;
        final double barDisplayHeight = (barRawHeight * 0.8).clamp(2.0, size.height * 0.8);
        final double x = i * totalBarSpace;
        final double y = middleY - (barDisplayHeight / 2);
        final double actualX = isMe ? size.width - x - barWidth : x;
        final double currentBarEndPosition = isMe ? size.width - x : x + barWidth; // نهاية الشريط من اليسار
        final double overallProgressPosition = isMe ? size.width - progressWidth : progressWidth; // نهاية التقدم من اليسار

        if ((isMe && actualX >= overallProgressPosition) || (!isMe && currentBarEndPosition <= overallProgressPosition)) {
          final Rect barRect = Rect.fromLTWH(actualX, y.clamp(0, size.height - barDisplayHeight), barWidth, barDisplayHeight);
          canvas.drawRRect(RRect.fromRectAndRadius(barRect, const Radius.circular(1.5)), progressPaint);
        }
      }
    }
  }
  @override
  bool shouldRepaint(covariant AudioWaveformPainter oldDelegate) { /* ... */ return true; }
}