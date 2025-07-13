import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/edit_product_controller.dart';

class ImageSection extends StatelessWidget {
  const ImageSection({super.key});

  @override
  Widget build(BuildContext context) {
    try {
      final controller = Get.find<EditProductController>();
      
      // التأكد من أن الكونترولر جاهز
      if (!controller.isProductLoaded.value) {
        return const Center(
          child: CircularProgressIndicator(),
        );
      }
      
      return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // عنوان القسم
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'الصور',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            TextButton.icon(
              onPressed: controller.pickAdditionalImages,
              icon: const Icon(Icons.add_photo_alternate),
              label: const Text('إضافة صور'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        
        // الصورة الرئيسية
        const Text(
          'الصورة الرئيسية',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        
        Obx(() {
          // إذا كانت هناك صورة جديدة
          if (controller.newMainImage.value != null) {
            return _buildMainImageCard(
              child: Stack(
                children: [
                  Image.memory(
                    controller.newMainImage.value!,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: 200,
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: CircleAvatar(
                      backgroundColor: Colors.black54,
                      child: IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: () => controller.newMainImage.value = null,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }
          
          // إذا كانت هناك صورة موجودة
          if (controller.mainImageUrl.value.isNotEmpty) {
            return _buildMainImageCard(
              child: Stack(
                children: [
                  Image.network(
                    controller.mainImageUrl.value,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: 200,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        height: 200,
                        color: Colors.grey[300],
                        child: const Center(
                          child: Icon(Icons.error, size: 50),
                        ),
                      );
                    },
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: CircleAvatar(
                      backgroundColor: Colors.black54,
                      child: IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: () => {
                          controller.deleteImage(controller.mainImageUrl.value),
                          controller.mainImageUrl.value = ''
                        },
                      ),
                    ),
                  ),
                ],
              ),
            );
          }
          
          // لا توجد صورة
          return _buildMainImageCard(
            child: InkWell(
              onTap: controller.pickMainImage,
              child: Container(
                height: 200,
                color: Colors.grey[200],
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.add_a_photo, size: 50, color: Colors.grey[600]),
                    const SizedBox(height: 8),
                    Text(
                      'اضغط لإضافة صورة رئيسية',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
        
        const SizedBox(height: 24),
        
        // الصور الإضافية
        const Text(
          'الصور الإضافية',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        
        Obx(() {
          final hasImages = controller.additionalImagesUrls.isNotEmpty || 
                          controller.newAdditionalImages.isNotEmpty;
          
          if (!hasImages) {
            return Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[300]!),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  'لا توجد صور إضافية',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ),
            );
          }
          
          return GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: controller.additionalImagesUrls.length + 
                      controller.newAdditionalImages.length,
            itemBuilder: (context, index) {
              // الصور الموجودة
              if (index < controller.additionalImagesUrls.length) {
                final imageUrl = controller.additionalImagesUrls[index];
                return _buildImageTile(
                  child: Image.network(
                    imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: Colors.grey[300],
                        child: const Icon(Icons.error),
                      );
                    },
                  ),
                  onDelete: () => controller.deleteImage(imageUrl),
                );
              }
              
              // الصور الجديدة
              final newImageIndex = index - controller.additionalImagesUrls.length;
              final imageBytes = controller.newAdditionalImages[newImageIndex];
              
              return _buildImageTile(
                child: Image.memory(
                  imageBytes,
                  fit: BoxFit.cover,
                ),
                onDelete: () => controller.deleteNewImage(newImageIndex),
              );
            },
          );
        }),
      ],
    );
    } catch (e) {
      return const Center(
        child: Text('خطأ في تحميل البيانات'),
      );
    }
  }
  
  Widget _buildMainImageCard({required Widget child}) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: child,
      ),
    );
  }
  
  Widget _buildImageTile({
    required Widget child,
    required VoidCallback onDelete,
  }) {
    return Stack(
      children: [
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              width: double.infinity,
              height: double.infinity,
              child: child,
            ),
          ),
        ),
        Positioned(
          top: 4,
          right: 4,
          child: CircleAvatar(
            radius: 15,
            backgroundColor: Colors.black54,
            child: IconButton(
              icon: const Icon(Icons.close, size: 16),
              color: Colors.white,
              padding: EdgeInsets.zero,
              onPressed: onDelete,
            ),
          ),
        ),
      ],
    );
  }
} 