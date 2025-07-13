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

      print('GPU Service: Image cache cleared');
    } catch (e) {
      print('GPU Service: Error clearing image cache: $e');
    }
  }

  static void handlePageTransition() {
    // Clear memory before page transitions to prevent GPU errors
    clearMemory();
    optimizeForMaliGPU();
  }
}