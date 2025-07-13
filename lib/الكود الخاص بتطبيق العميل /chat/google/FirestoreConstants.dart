class FirestoreConstants {
  static const String userCollection = "Usercodora"; // Assuming you have a users collection
  static const String chatCollection = "Chat";
  static const String chatSubCollection = "chat";
  static const String messagesSubCollection = "messages";

  // Message Fields
  static const String senderId = "senderId";
  static const String recipientId = "recipientId";
  static const String messageContent = "content"; // Keep 'message' for compatibility? Or rename?
  static const String messageType = "type";
  static const String timestamp = "time";
  static const String isRead = "isRead";
  static const String messageId = "messageId";
  static const String thumbnailUrl = "thumbnail";
  static const String typeDeleted = 'deleted';
  static const String deletedMessageContent = '🚫 تم حذف هذه الرسالة';

  // Message Types
  static const String typeText = 'text';
  static const String typeImage = 'img'; // Keep 'img' for compatibility? Or 'image'?
  static const String typeVideo = 'video';
  static const String typeAudio = 'audio';

  // Storage Folders
  static const String storageImages = 'images';
  static const String storageVideos = 'videos';
  static const String storageAudio = 'audio';
  static const String storageThumbnails = 'thumbnails';
}

class UserField { // Example for user data
  static const String name = 'name';
  static const String profilePic = 'url';
  static const String fcmToken = 'token';
  static const String isOnline = 'isOnline';
  static const String lastSeen = 'lastSeen';
}