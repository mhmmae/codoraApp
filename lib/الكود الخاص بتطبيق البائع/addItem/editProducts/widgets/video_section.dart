import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:video_player/video_player.dart';
import '../controllers/edit_product_controller.dart';

class VideoSection extends StatelessWidget {
  const VideoSection({super.key});

  @override
  Widget build(BuildContext context) {
    try {
      final controller = Get.find<EditProductController>();
      
      if (!controller.isProductLoaded.value) {
        return const Center(child: CircularProgressIndicator());
      }
      
      return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // عنوان القسم
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'الفيديو',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            Obx(() {
              final hasVideo = (controller.videoUrl.value != null && controller.videoUrl.value!.isNotEmpty) || 
                             controller.newVideoFile.value != null;
              
              if (hasVideo && !controller.isVideoDeleted.value) {
                return TextButton.icon(
                  onPressed: controller.deleteVideo,
                  icon: const Icon(Icons.delete, color: Colors.red),
                  label: const Text('حذف الفيديو', style: TextStyle(color: Colors.red)),
                );
              }
              
              return TextButton.icon(
                onPressed: controller.pickVideo,
                icon: const Icon(Icons.videocam),
                label: const Text('إضافة فيديو'),
              );
            }),
          ],
        ),
        const SizedBox(height: 16),
        
        Obx(() {
          // إذا تم حذف الفيديو
          if (controller.isVideoDeleted.value) {
            return _buildNoVideoCard(controller);
          }
          
          // إذا كان هناك فيديو جديد أو موجود
          if (controller.videoController != null) {
            return _buildVideoPlayer(controller);
          }
          
          // لا يوجد فيديو
          return _buildNoVideoCard(controller);
        }),
      ],
    );
    } catch (e) {
      return const Center(child: Text('خطأ في تحميل البيانات'));
    }
  }
  
  Widget _buildVideoPlayer(EditProductController controller) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Column(
          children: [
            AspectRatio(
              aspectRatio: controller.videoController!.value.aspectRatio,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  VideoPlayer(controller.videoController!),
                  
                  // زر التشغيل/الإيقاف
                  GetBuilder<EditProductController>(
                    builder: (_) {
                      final isPlaying = controller.videoController?.value.isPlaying ?? false;
                      
                      return InkWell(
                        onTap: () {
                          if (isPlaying) {
                            controller.videoController?.pause();
                          } else {
                            controller.videoController?.play();
                          }
                          controller.update();
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.black54,
                            shape: BoxShape.circle,
                          ),
                          padding: const EdgeInsets.all(12),
                          child: Icon(
                            isPlaying ? Icons.pause : Icons.play_arrow,
                            color: Colors.white,
                            size: 32,
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            
            // شريط التقدم
            GetBuilder<EditProductController>(
              builder: (_) {
                final controller = Get.find<EditProductController>();
                final videoController = controller.videoController;
                
                if (videoController == null) return const SizedBox();
                
                final position = videoController.value.position;
                final duration = videoController.value.duration;
                
                return Column(
                  children: [
                    VideoProgressIndicator(
                      videoController,
                      allowScrubbing: true,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _formatDuration(position),
                            style: const TextStyle(fontSize: 12),
                          ),
                          Text(
                            _formatDuration(duration),
                            style: const TextStyle(fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildNoVideoCard(EditProductController controller) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      child: InkWell(
        onTap: controller.pickVideo,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          height: 200,
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.video_call,
                size: 50,
                color: Colors.grey[600],
              ),
              const SizedBox(height: 8),
              Text(
                'اضغط لإضافة فيديو',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'الحد الأقصى 5 دقائق',
                style: TextStyle(
                  color: Colors.grey[500],
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }
} 