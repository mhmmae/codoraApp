// Inside MessageBubble or a specific VideoMessageWidget

// ... other imports
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:video_player/video_player.dart' as vp;

import 'VideoPlayerController.dart'; // Use prefix

class VideoMessageWidget extends StatelessWidget { // Example widget
  final String videoUrl;
  final String thumbnailUrl;
  final String messageId;

  const VideoMessageWidget({
    super.key,
    required this.videoUrl,
    required this.thumbnailUrl,
    required this.messageId,
  });

  @override
  Widget build(BuildContext context) {
    // Crucial: Use unique tag for Get.put!
    final controller = Get.put(
      VideoPlayerController(
        videoSourceUrl: videoUrl,
        messageId: messageId,
      ),
      tag: messageId, // Use messageId as the unique tag
    );

    return GestureDetector(
      onTap: controller.togglePlayPause, // Toggle play/pause on tap
      child: Obx( // Use Obx to react to controller state changes
            () => Stack(
          alignment: Alignment.center,
          children: [
            // Video Player Area (conditionally shown)
            if (controller.isInitialized.value && controller.sdkPlayerController != null)
              AspectRatio(
                aspectRatio: controller.aspectRatio.value,
                child: vp.VideoPlayer(controller.sdkPlayerController!),
              )
            else // Show Thumbnail or Loading/Error State
              _buildPlaceholder(context, controller),

            // Buffering Indicator
            if (controller.isBuffering.value)
              const CircularProgressIndicator(color: Colors.white70),

            // Play/Pause Button Overlay (only if initialized and not buffering)
            if (controller.isInitialized.value && !controller.isBuffering.value && !controller.hasError.value)
              _buildPlayPauseOverlay(controller),

            // Error Indicator / Retry Button
            if (controller.hasError.value)
              _buildErrorOverlay(context, controller),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholder(BuildContext context, VideoPlayerController controller) {
    // Use AspectRatio based on known (or default) ratio to prevent layout jumps
    return AspectRatio(
      aspectRatio: controller.aspectRatio.value,
      child: Container(
        color: Colors.black54, // Placeholder background
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Show Thumbnail Image
            if (thumbnailUrl.isNotEmpty)
              CachedNetworkImage(imageUrl: thumbnailUrl, fit: BoxFit.cover),
            // Loading Indicator (if not error state)
            if (!controller.hasError.value)
              const CircularProgressIndicator(color: Colors.white),
          ],
        ),
      ),
    );
  }

  Widget _buildPlayPauseOverlay(VideoPlayerController controller) {
    // Only show the overlay when the video is *not* playing
    return AnimatedOpacity(
      opacity: controller.isPlaying.value ? 0.0 : 1.0, // Fade out when playing
      duration: const Duration(milliseconds: 300),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.black54,
          shape: BoxShape.circle,
        ),
        child: Icon(
            controller.isPlaying.value ? Icons.pause : Icons.play_arrow_rounded, // Show appropriate icon
            color: Colors.white, size: 40
        ),
      ),
    );
  }


  Widget _buildErrorOverlay(BuildContext context, VideoPlayerController controller) {
    return Container(
      color: Colors.black87.withOpacity(0.7),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: Colors.redAccent, size: 40),
            const SizedBox(height: 8),
            Text(
              controller.errorMessage.value.isNotEmpty
                  ? controller.errorMessage.value
                  : "Failed to load video",
              style: const TextStyle(color: Colors.white),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            TextButton.icon(
              icon: const Icon(Icons.refresh, color: Colors.white),
              label: const Text("Retry", style: TextStyle(color: Colors.white)),
              onPressed: controller.retryLoading,
              style: TextButton.styleFrom(backgroundColor: Colors.white24),
            ),
          ],
        ),
      ),
    );
  }
}