import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart'; // For kDebugMode
import 'package:path/path.dart' as p;

import 'FirestoreConstants.dart'; // Import path package

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Future<String?> uploadFile(File file, String storagePath) async {
    try {
      final ref = _storage.ref(storagePath);
      final uploadTask = ref.putFile(file);
      final snapshot = await uploadTask;
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      if (kDebugMode) {
        debugPrint("Error uploading file to $storagePath: $e");
      }
      return null; // Return null on error
    }
  }

  Future<String?> uploadData(Uint8List data, String storagePath) async {
    try {
      final ref = _storage.ref(storagePath);
      final metadata = SettableMetadata(contentType: 'image/jpeg'); // Or infer type
      final uploadTask = ref.putData(data, metadata);
      final snapshot = await uploadTask;
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      if (kDebugMode) {
        debugPrint("Error uploading data to $storagePath: $e");
      }
      return null; // Return null on error
    }
  }

  Future<bool> deleteFile(String fileUrl) async {
    try {
      final ref = _storage.refFromURL(fileUrl);
      await ref.delete();
      return true;
    } catch (e) {
      if (kDebugMode) {
        debugPrint("Error deleting file $fileUrl: $e");
      }
      return false;
    }
  }

  // Helper to generate storage paths
  String getImagePath(String messageId) => '${FirestoreConstants.storageImages}/$messageId${p.extension(".jpg")}'; // Assume jpg or infer
  String getVideoPath(String messageId, String originalPath) => '${FirestoreConstants.storageVideos}/$messageId${p.extension(originalPath)}';
  String getAudioPath(String messageId) => '${FirestoreConstants.storageAudio}/$messageId.aac'; // Assume aac
  String getThumbnailPath(String messageId) => '${FirestoreConstants.storageThumbnails}/$messageId.png'; // Assume png

}