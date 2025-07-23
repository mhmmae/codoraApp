import 'package:flutter/services.dart';
import 'package:flutter/painting.dart';
import 'dart:io';

class GPUService {
  static const platform = MethodChannel('codora.gpu.channel');

  static Future<void> clearMemory() async {
    try {
      if (Platform.isAndroid) {
        await platform.invokeMethod('clearMemory');
        print('GPU Service: Memory cleared successfully');
      }
    } on MissingPluginException catch (e) {
      print('GPU Service: Plugin not implemented - $e');
      // استمرار التنفيذ بدون خطأ
    } catch (e) {
      print('GPU Service: Error clearing memory: $e');
    }
  }

  static Future<String> getGPUInfo() async {
    try {
      if (Platform.isAndroid) {
        final String result = await platform.invokeMethod('getGpuInfo');
        return result;
      }
      return 'iOS GPU';
    } on MissingPluginException catch (e) {
      print('GPU Service: GPU info plugin not implemented - $e');
      return 'GPU info not available';
    } catch (e) {
      print('GPU Service: Error getting GPU info: $e');
      return 'Unknown GPU';
    }
  }

  static void optimizeForMaliGPU() {
    // Force garbage collection
    print('GPU Service: Optimizing for Mali GPU');

    try {
      // Clear any cached images or resources
      PaintingBinding.instance.imageCache.clear();
      PaintingBinding.instance.imageCache.clearLiveImages();

      print('GPU Service: Image cache cleared for Mali optimization');
    } catch (e) {
      print('GPU Service: Error clearing image cache for Mali: $e');
      // لا نوقف التنفيذ، نستمر
    }
  }

  static void handlePageTransition() {
    try {
      // Clear memory before page transitions to prevent GPU errors
      clearMemory();
      optimizeForMaliGPU();
      print('GPU Service: Page transition handled successfully');
    } catch (e) {
      print('GPU Service: Error handling page transition: $e');
      // لا نوقف التنفيذ
    }
  }
}
