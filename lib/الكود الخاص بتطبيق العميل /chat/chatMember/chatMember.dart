import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // تحتاجها Timestamp وغيرها
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';

// --- استيراد المتحكم والكلاسات الأخرى ---
import '../google/ChatScreen.dart';
import '../google/FirestoreConstants.dart';
import '../google/Helpers.dart';
import 'MemberScreenController.dart';
// (عدّل المسار)
    // <--- تأكد أنه هذا هو الملف الصحيح (عدّل المسار)
// import 'package:codora/core/models/message_model.dart'; // قد لا تحتاجه مباشرة هنا
// import 'package:codora/core/models/message_status.dart';// قد لا تحتاجه مباشرة هنا

class MemberScreen extends StatelessWidget { // <--- تغيير إلى StatelessWidget
  const MemberScreen({super.key});

  // --- دالة بناء الويدجت الرئيسية ---
  @override
  Widget build(BuildContext context) {
    // --- حقن أو إيجاد المتحكم ---
    final MemberScreenController controller = Get.put(MemberScreenController());
    final ThemeData theme = Theme.of(context); // الوصول للثيم

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'المحادثات', // تغيير العنوان ليعكس المحتوى
          style: TextStyle(color: theme.brightness == Brightness.dark ? Colors.white : Colors.black87),
        ),
        backgroundColor: theme.appBarTheme.backgroundColor ?? theme.colorScheme.primary, // لون شريط العنوان من الثيم
        elevation: 1.0, // ظل خفيف
        // يمكن إضافة أيقونات أخرى هنا (مثل البحث إذا نقلته هنا أو إضافة محادثة جديدة)
      ),
      body: Column(
        children: [
          // --- شريط البحث ---
          _buildSearchBar(controller, context), // تمرير المتحكم

          // --- قائمة المحادثات (باستخدام StreamBuilder على التيار المُفلتر) ---
          // داخل MemberScreen -> build -> Column -> Expanded

          Expanded(
            child: Obx(() {
              // استخدام isLoading للإشارة للتحميل الأولي، و isSearching للتحميل أثناء الفلترة
              if (controller.isLoading.value) {
                return _buildLoadingList(context);
              }
              // يمكنك إضافة مؤشر بحث منفصل
              // if(controller.isSearching.value){ return Center(child:CircularProgressIndicator()); }

              if (!controller.hasData.value && controller.searchQuery.isEmpty) {
                return _buildEmptyConversationsState(context);
              }
              if (!controller.hasData.value && controller.searchQuery.isNotEmpty) {
                return _buildNoSearchResultsState(context, controller.searchQuery);
              }

              // --- الاعتماد على RxList المفلترة ---
              // لم نعد بحاجة لـ StreamBuilder هنا لأن Obx يراقب القائمة التفاعلية
              final conversationsToShow = controller.filteredConversations; // الوصول للقائمة التفاعلية
              // -----------------------------------

              return ListView.builder(
                itemCount: conversationsToShow.length,
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemBuilder: (context, index) {
                  final combinedData = conversationsToShow[index]; // <-- بيانات جاهزة من RxList
                  final chatData = combinedData['chatData'] as Map<String, dynamic>;
                  final userData = combinedData['userData'] as Map<String, dynamic>;
                  final otherUserId = combinedData['otherUserId'] as String;

                  // بناء العنصر
                  return _buildConversationTile(context, controller, chatData, userData, otherUserId, theme);
                },
              );

            }), // نهاية Obx
          ), // نهاية Expanded // نهاية Expanded
        ],
      ),
    );
  }


  // --- بناء شريط البحث (يستخدم Controller الآن) ---
  Widget _buildSearchBar(MemberScreenController controller, BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 10.0), // تقليل الهوامش قليلًا
      child: TextField(
        controller: controller.searchController,
        decoration: InputDecoration(
          hintText: 'ابحث عن محادثة...', // نص تلميحي أوضح
          prefixIcon: Icon(Icons.search, color: Colors.grey[600], size: 22), // أيقونة البحث
          // إضافة زر لمسح البحث (يظهر فقط عند وجود نص)
          suffixIcon: Obx(() => controller.searchQuery.isNotEmpty
              ? IconButton(
            icon: Icon(Icons.clear, color: Colors.grey[600], size: 20),
            onPressed: () => controller.searchController.clear(), // مسح حقل البحث
          )
              : const SizedBox.shrink()), // زر غير مرئي إذا كان البحث فارغًا
          filled: true, // لتطبيق لون الخلفية
          fillColor: theme.scaffoldBackgroundColor == Colors.black ? Colors.grey.shade800 : Colors.grey[200], // لون خلفية مناسب للثيم
          contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 15), // تعديل الحشو الداخلي
          border: OutlineInputBorder( // استخدام حدود مستديرة
            borderRadius: BorderRadius.circular(30.0),
            borderSide: BorderSide.none, // بدون حدود خارجية
          ),
          focusedBorder: OutlineInputBorder( // تغيير الحدود عند التركيز
            borderRadius: BorderRadius.circular(30.0),
            borderSide: BorderSide(color: theme.primaryColor.withOpacity(0.5), width: 1.5), // حدود بلون الثيم
          ),
        ),
        style: const TextStyle(fontSize: 15), // تعديل حجم الخط
      ),
    );
  }


  // --- بناء هيكل التحميل (Loading Skeleton) ---
  Widget _buildLoadingList(BuildContext context) {
    return ListView.builder(
      itemCount: 6, // عرض عدد ثابت من العناصر النائبة
      itemBuilder: (context, index) => _buildLoadingTile(context),
    );
  }

  Widget _buildLoadingTile(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 12.0),
      child: Shimmer.fromColors(
        baseColor: theme.brightness == Brightness.dark ? Colors.grey[700]! : Colors.grey[300]!,
        highlightColor: theme.brightness == Brightness.dark ? Colors.grey[600]! : Colors.grey[100]!,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
          decoration: BoxDecoration(
            color: Colors.grey[400], // لون أساسي للهيكل
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              CircleAvatar(radius: 28, backgroundColor: Colors.grey[500]), // دائرة للصورة
              const SizedBox(width: 12),
              Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(height: 14, width: MediaQuery.of(context).size.width * 0.4, color: Colors.grey[500]), // اسم المستخدم
                      const SizedBox(height: 8),
                      Container(height: 12, width: MediaQuery.of(context).size.width * 0.6, color: Colors.grey[500]), // آخر رسالة
                    ],
                  )),
            ],
          ),
        ),
      ),
    );
  }

  // --- بناء واجهة حالة عدم وجود محادثات ---
  Widget _buildEmptyConversationsState(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.chat_bubble_outline_rounded, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            "لا توجد محادثات بعد",
            style: theme.textTheme.titleMedium?.copyWith(color: Colors.grey[700]),
          ),
          const SizedBox(height: 8),
          Text(
            "ابدأ محادثة جديدة!",
            style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // --- بناء واجهة حالة عدم وجود نتائج للبحث ---
  Widget _buildNoSearchResultsState(BuildContext context, String query) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off_rounded, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            "لا توجد نتائج للبحث عن:",
            style: theme.textTheme.titleMedium?.copyWith(color: Colors.grey[700]),
          ),
          const SizedBox(height: 4),
          Text(
            "\"$query\"", // عرض مصطلح البحث
            style: theme.textTheme.titleMedium?.copyWith(color: Colors.grey[700], fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  // --- بناء عنصر المحادثة في القائمة (Conversation Tile) ---
  Widget _buildConversationTile(
      BuildContext context,
      MemberScreenController controller, // تمرير المتحكم (إذا احتجت لاستدعاء دوال منه هنا)
      Map<String, dynamic> chatData,   // ملخص آخر رسالة والوقت
      Map<String, dynamic> userData,    // بيانات المستخدم الآخر (الاسم، الصورة)
      String otherUserId,              // معرف المستخدم الآخر
      ThemeData theme,
      ) {

    // الحصول على تفاصيل آخر رسالة بشكل آمن
    final String lastMessageType = chatData[FirestoreConstants.messageType] ?? FirestoreConstants.typeText;
    final String lastMessageContent = chatData[FirestoreConstants.messageContent] ?? '';
    final Timestamp? lastMessageTimestamp = chatData[FirestoreConstants.timestamp] as Timestamp?;
    final bool isLastMessageRead = chatData[FirestoreConstants.isRead] ?? false; // افتراض القراءة إذا لم توجد

    // --- بناء نص فرعي للمعاينة ---
    Widget subtitle;
    if (lastMessageType == FirestoreConstants.typeText) {
      subtitle = Text(
        lastMessageContent,
        maxLines: 1, // سطر واحد للمعاينة
        overflow: TextOverflow.ellipsis,
        style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey[600]), // نمط للنص الفرعي
      );
    } else {
      // عرض أيقونة ونص لنوع الوسائط
      IconData mediaIcon;
      String mediaText;
      switch (lastMessageType) {
        case FirestoreConstants.typeImage: mediaIcon = Icons.photo_camera_back_rounded; mediaText = 'صورة'; break;
        case FirestoreConstants.typeVideo: mediaIcon = Icons.videocam_rounded; mediaText = 'فيديو'; break;
        case FirestoreConstants.typeAudio: mediaIcon = Icons.mic_rounded; mediaText = 'رسالة صوتية'; break;
        default: mediaIcon = Icons.attach_file_rounded; mediaText = 'لا رسالة';
      }
      subtitle = Row(
        children: [
          Icon(mediaIcon, size: 16, color: Colors.grey[600]), // أيقونة مناسبة
          const SizedBox(width: 6),
          Text(
            mediaText,
            style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
          ),
        ],
      );
    }


    return InkWell( // استخدام InkWell لتأثير النقر
      onTap: () {
        if (kDebugMode) debugPrint("Navigating to ChatScreen for recipient: $otherUserId");
        // TODO: يجب تعديل هذه الدالة لتقوم بتحديث isRead في **مستودع الرسائل**
        // وليس مباشرة في Firestore من الواجهة
        // FirebaseFirestore.instance.collection('Chat')...update({'isRead': true}); <-- يجب نقله للمستودع
        // بعد الانتقال يجب أن تقوم ChatController/Repository بتحديث حالة القراءة محلياً وربما عن بعد

        // --- الانتقال إلى شاشة الدردشة ---
        Get.to(
              () => ChatScreen(recipientId: otherUserId), // تمرير معرف المستلم
          transition: Transition.rightToLeftWithFade, // تأثير انتقال
          duration: const Duration(milliseconds: 300), // مدة الانتقال
        );
      },
      splashColor: theme.primaryColor.withOpacity(0.1),
      highlightColor: theme.primaryColor.withOpacity(0.05),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0), // تعديل الحشو
        child: Row( // استخدام Row لمرونة أكبر
          children: [
            // --- الصورة الشخصية ---
            _buildUserAvatar(userData[UserField.profilePic]),

            const SizedBox(width: 12),

            // --- الاسم وآخر رسالة ---
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // --- الاسم ---
                  Text(
                    userData[UserField.name] ?? 'مستخدم غير معروف', // اسم المستخدم
                    style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600), // نمط للاسم
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4), // مسافة صغيرة
                  // --- آخر رسالة (المعاينة) ---
                  subtitle, // ويدجت المعاينة التي بنيناها
                ],
              ),
            ),

            const SizedBox(width: 8), // مسافة قبل الوقت

            // --- الوقت وشارة غير مقروءة ---
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // وقت آخر رسالة
                Text(
                  lastMessageTimestamp != null ? Helpers.dateTimeToText(lastMessageTimestamp.toDate(), short: true) : '', // الوقت النسبي
                  style: theme.textTheme.bodySmall?.copyWith(fontSize: 11, color: Colors.grey[500]),
                ),
                const SizedBox(height: 5), // مسافة
                // شارة الرسائل غير المقروءة
                // تحتاج لتحديد المصدر الصحيح لحالة القراءة والعدد (العدد أفضل)
                if (!isLastMessageRead) // اعرض فقط إذا كانت غير مقروءة
                  Container(
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      color: theme.primaryColor, // لون الشارة
                      shape: BoxShape.circle,
                    ),
                    // يمكن عرض عدد الرسائل غير المقروءة هنا بدلاً من نقطة
                    // child: Text('1', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                    child: const SizedBox(width: 8, height: 8), // مجرد نقطة الآن
                  )
                else
                  const SizedBox(height: 18), // ارتفاع مطابق للحفاظ على المحاذاة
              ],
            ),

          ],
        ),
      ),
    );
  }

  // --- بناء الأفاتار (صورة المستخدم) ---
  Widget _buildUserAvatar(String? imageUrl) {
    return CircleAvatar(
      radius: 28, // حجم أكبر قليلاً
      backgroundColor: Colors.grey.shade300, // لون الخلفية البديل
      backgroundImage: (imageUrl != null && imageUrl.isNotEmpty)
          ? CachedNetworkImageProvider(imageUrl)
          : null, // لا تستخدم NetworkImage مباشرة، Cached أفضل
      child: (imageUrl == null || imageUrl.isEmpty)
          ? Icon(Icons.person_rounded, size: 30, color: Colors.grey.shade500) // أيقونة شخص
          : null,
    );
  }

// --- دالة BadgeMessage أصبحت جزءًا من Tile ---
// لا نحتاج لويدجت منفصلة لـ Badge الآن

} // نهاية كلاس MemberScreen