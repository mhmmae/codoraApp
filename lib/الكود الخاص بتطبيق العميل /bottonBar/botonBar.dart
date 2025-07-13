import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/scheduler.dart';

// <-- تأكد من صحة المسار
import '../../XXX/xxx_firebase.dart';
import '../HomePage/Get-Controllar/GetChoseTheTypeOfItem.dart';
import '../HomePage/Get-Controllar/GetSerchController.dart';
import '../HomePage/class/FavoriteController.dart';
import '../HomePage/home/home.dart';
import '../PersonallPage/PersonallPae.dart';
import '../Services/الصفحة الرئيسية/ServicesPage.dart'; // <-- تأكد من صحة المسار
import '../TheOrder/ChooseCategory/CategoryController.dart';
import '../TheOrder/ViewOeder/class/Drawer.dart';

import '../chat/chatMember/chatMember.dart';
import '../chat/google/ChatScreen.dart';
import '../chat/google/LocalDatabaseService2GetxService.dart';
import '../theـchosen/theـchosen.dart';
import 'Get2/Get2.dart';
// --- نهاية الاستيرادات التي تحتاج للتأكد منها ---

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_nav_bar/google_nav_bar.dart';

class BottomBar extends StatefulWidget {
  final int initialIndex;
  const BottomBar({super.key, this.initialIndex = 0});
  @override
  State<BottomBar> createState() => _BottomBarState();
}

class _BottomBarState extends State<BottomBar> {
  // --- يجب التأكد من أن Get2 تم حقنه قبل استخدام find، استخدم put مؤقتًا أو Binding ---
  // final Get2 logic = Get.put(Get2(), permanent: false); // قد يسبب مشاكل إذا استخدمت binding
  late final Get2 logic; // سيتم البحث عنه لاحقاً


  Stream<QuerySnapshot<Map<String, dynamic>>> cartItemStream = Stream.empty(); // تهيئة بقيمة افتراضية
  String? currentUserId;
  bool isAdmin = false;
  List<Widget> pages = [];

  @override
  void initState() {
    super.initState();
    debugPrint("BottomBar initState: Starting..."); // للمساعدة في التتبع

    // ---- البحث عن/حقن Get2 مبدئياً -----
    // استخدام find إذا كنت متأكداً أنه موجود (عبر Binding)
    // أو put إذا كنت تريد إنشاءه هنا (لكن احذر التكرار)
    // Get.put<Get2>(Get2(), permanent: false); // طريقة للحقن إذا لم تستخدم binding
    try {
      logic = Get.find<Get2>();
      debugPrint("BottomBar initState: Found existing Get2 instance.");
    } catch (e) {
      debugPrint("BottomBar initState: Get2 not found, creating new instance with Get.put.");
      logic = Get.put(Get2(), permanent: false); // <-- الحقن هنا (أقل مثالية من Binding)
    }
    //----------------------------------


    final currentUser = FirebaseAuth.instance.currentUser;
    currentUserId = currentUser?.uid;
    isAdmin = currentUser?.email == FirebaseX.EmailOfWnerApp;

    // 1. إعداد الصفحات (بدون تعديل selectedIndex)
    _setupPages();
    debugPrint("BottomBar initState: _setupPages completed. Page count: ${pages.length}");

    // 2. التعامل مع Stream إذا كان المستخدم مسجل
    if (currentUserId != null) {
      cartItemStream = FirebaseFirestore.instance
          .collection(FirebaseX.chosenCollection)
          .doc(currentUserId!)
          .collection(FirebaseX.appName)
          .snapshots()
          .cast<QuerySnapshot<Map<String, dynamic>>>();
      debugPrint("BottomBar initState: User is logged in, cart stream initialized.");
    } else {
      cartItemStream = Stream.empty(); // تيار فارغ لغير المسجل
      debugPrint("BottomBar initState: No user logged in, cart stream is empty.");
    }

    // 3. تأجيل تعيين الفهرس الأولي لما بعد أول build
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return; // تحقق إضافي إذا تم dispose للـ state بسرعة
      debugPrint("BottomBar: PostFrameCallback executing...");
      try {
        // لا حاجة للبحث مرة أخرى، logic تم تعيينها بالفعل
        // final logic = Get.find<Get2>();

        // استخدام clamp لضمان الفهرس ضمن حدود قائمة الصفحات الحالية
        final validInitialIndex = widget.initialIndex.clamp(0, pages.isEmpty ? 0 : pages.length - 1);
        debugPrint("BottomBar PostFrameCallback: Calculated valid initial index: $validInitialIndex");

        // التحقق من القيمة الحالية قبل التغيير لمنع إعادة البناء غير الضرورية
        if (logic.selectedIndex.value != validInitialIndex) {
          logic.changeIndex(validInitialIndex); // <-- التغيير يحدث هنا فقط
          debugPrint("BottomBar PostFrameCallback: Initial index set to: $validInitialIndex");
        } else {
          debugPrint("BottomBar PostFrameCallback: Index already set correctly to $validInitialIndex.");
        }
      } catch (e) {
        debugPrint("Error inside BottomBar PostFrameCallback: $e");
        // يمكن إضافة معالجة خطأ إضافية هنا
      }
    });
    debugPrint("BottomBar initState: PostFrameCallback scheduled.");
  } // نهاية initState

  // --- دالة إعداد الصفحات: **بدون** أي استدعاء لـ logic.changeIndex ---
  void _setupPages() {
    if (currentUserId == null) {
      pages = [const HomeScreen(), Servicespage()];
    } else {
      pages = isAdmin
          ? [ const HomeScreen(), Servicespage(), TheChosen(uid: currentUserId!), Drawer2(),
        // ViewOrder(uid: currentUserId!),
        MemberScreen(), const PersonallPage()]
          : [ const HomeScreen(), Servicespage(), TheChosen(uid: currentUserId!), ChatScreen(recipientId: FirebaseX.UIDOfWnerApp), const PersonallPage()];
    }
    // === تم حذف كتلة if/else الخاصة بـ changeIndex من هنا ===
  } // نهاية setupPages


  @override
  Widget build(BuildContext context) {
    debugPrint("BottomBar build: Building UI..."); // للتأكد من أن build يُستدعى

    // الحقن بـ lazyPut جيد هنا (أو في Bindings)
    Get.lazyPut(() => GetSearchController(), fenix: true);
    Get.lazyPut(() => GetChoseTheTypeOfItem(), fenix: true);
    Get.lazyPut(() => FavoriteController());
    Get.lazyPut(() => CategoryController());
    Get.lazyPut(() => LocalDatabaseService(), fenix: true);
// <-- إضافة هنا


// <--- إضافة هنا
    // يمكن استخدام find هنا لـ logic، حيث أنه يجب أن يكون موجوداً بعد initState أو postFrameCallback
    // final Get2 logic = Get.find<Get2>(); // <-- هذا هو المكان الصحيح لـ find

    if (pages.isEmpty) {
      // حالة نادرة، ولكن من الأفضل التعامل معها
      debugPrint("BottomBar build: pages list is empty, showing loading indicator.");
      return const Scaffold(body: Center(child: Text("Loading pages...")));
    }

    final double wi = MediaQuery.of(context).size.width;
    final theme = Theme.of(context); // تعريف theme للاستخدام
    final Color primaryColor = theme.primaryColor;
    final Color bottomNavBarColor = theme.bottomNavigationBarTheme.backgroundColor ?? theme.colorScheme.surface;
    final Color inactiveColor = Colors.grey[600]!;

    return Scaffold(
      // استخدام Obx لمراقبة الفهرس المحدد
      body: Obx(() {
        // استخدام clamp مجددًا للأمان المطلق قبل تمرير الفهرس
        final safeIndex = logic.selectedIndex.value.clamp(0, pages.length - 1);
        debugPrint("BottomBar build (Obx body): Displaying page index $safeIndex");
        return IndexedStack(index: safeIndex, children: pages);
      }),
      bottomNavigationBar: Container(
        decoration: BoxDecoration( color: bottomNavBarColor, boxShadow: [ BoxShadow(blurRadius: 10, color: Colors.black.withOpacity(.08)) ], ),
        child: SafeArea(
          child: Padding(
              padding: EdgeInsets.symmetric(horizontal: wi * 0.04, vertical: 8),
              child: Obx(() { // Obx لـ GNav لمراقبة selectedIndex لتحديث التبويب النشط
                final List<GButton> tabs = _buildGNavTabs(isAdmin, wi, context, primaryColor, inactiveColor, logic.selectedIndex.value);
                // التأكد من أن الفهرس لا يتجاوز عدد التبويبات الفعلية
                final safeGNavIndex = logic.selectedIndex.value.clamp(0, tabs.length - 1);
                debugPrint("BottomBar build (Obx GNav): Selected GNav index $safeGNavIndex (of ${tabs.length} tabs)");
                return GNav(
                  selectedIndex: safeGNavIndex,
                  onTabChange: (index) {
                    debugPrint("BottomBar onTabChange: Index $index selected.");
                    // التحديث يتم داخل logic.changeIndex
                    logic.changeIndex(index);
                    // **لا تستدع setState() هنا إذا كنت تستخدم GetX و Obx**
                  },
                  rippleColor: Colors.grey[300]!, hoverColor: Colors.grey[100]!, gap: 8, activeColor: primaryColor, iconSize: wi * 0.06, padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12), duration: const Duration(milliseconds: 300), tabBackgroundColor: primaryColor.withOpacity(0.1), color: inactiveColor,
                  tabs: tabs,
                );
              })
          ),
        ),
      ),
    );
  } // نهاية build

  // --- تم تعديل الدالة هنا ---
  List<GButton> _buildGNavTabs(bool isAdmin, double wi, BuildContext context, Color activeColor, Color inactiveColor, int selectedIndex) {
    final textStyle = TextStyle(fontSize: wi / 44, color: activeColor, fontWeight: FontWeight.w600);
    final Get2 bottomBarLogic = Get.find<Get2>(); // الحصول على مثيل Get2

    // تعريف الأيقونات لكل حالة
    final homeIcon = selectedIndex == 0 ? Icons.home : Icons.home_outlined;
    final servicesIcon = selectedIndex == 1 ? Icons.grid_view_rounded : Icons.grid_view_outlined;
    final cartIcon = selectedIndex == 2 ? Icons.shopping_basket : Icons.shopping_basket_outlined;

    int messageTabIndex = isAdmin ? 4 : 3; // فهرس تبويب الرسائل/الأعضاء
    int profileTabIndex = isAdmin ? 5 : 4; // فهرس تبويب الملف الشخصي

    IconData messageOrMemberIcon;
    if (isAdmin) {
      messageOrMemberIcon = selectedIndex == messageTabIndex ? Icons.groups_rounded : Icons.groups_outlined;
    } else {
      messageOrMemberIcon = selectedIndex == messageTabIndex ? Icons.chat_bubble : Icons.chat_bubble_outline;
    }


    final profileIcon = selectedIndex == profileTabIndex ? Icons.person : Icons.person_outline;


    // التعامل مع المستخدم غير المسجل دخوله (إذا كان مسموحاً به في الشريط السفلي)
    if(currentUserId == null){
      return [
        GButton(icon: homeIcon, text: 'الرئيسية', textStyle: textStyle, iconActiveColor: activeColor, iconColor: inactiveColor),
        GButton(icon: servicesIcon, text: 'الخدمات', textStyle: textStyle, iconActiveColor: activeColor, iconColor: inactiveColor),
      ];
    }

    List<GButton> tabs = [
      GButton(icon: homeIcon, text: 'الرئيسية', textStyle: textStyle, iconActiveColor: activeColor, iconColor: inactiveColor), // <<-- تعريب
      GButton(icon: servicesIcon, text: 'الخدمات', textStyle: textStyle, iconActiveColor: activeColor, iconColor: inactiveColor), // <<-- تعريب
      GButton(
        // الأيقونة داخل Badge تتغير أيضًا
        icon: cartIcon,
        text: 'السلة', // <<-- تعريب
        textStyle: textStyle,
        iconActiveColor: activeColor,
        iconColor: inactiveColor,
        leading: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: cartItemStream,
          builder: (c, s) {
            int count = 0;
            if (s.connectionState == ConnectionState.active && s.hasData) {
              count = s.data!.docs.fold(0, (sum, d) => sum + ((d.data()['number'] as num?)?.toInt() ?? 0));
            }
            return Badge(
              label: Text(count.toString()),
              isLabelVisible: count > 0,
              // الأيقونة داخل Badge تتغير أيضاً
              child: Icon(selectedIndex == 2 ? Icons.shopping_basket : Icons.shopping_basket_outlined, size: wi * 0.06, color: selectedIndex == 2 ? activeColor : inactiveColor),
            );
          },
        ),
      ),
    ];

    if (isAdmin) {
      int orderTabIndex = 3; // فهرس الطلبات يظهر فقط للادمن
      final orderIcon = selectedIndex == orderTabIndex ? Icons.receipt_long : Icons.receipt_long_outlined;
      tabs.add(GButton(icon: orderIcon, text: 'الطلبات', textStyle: textStyle, iconActiveColor: activeColor, iconColor: inactiveColor)); // <<-- تعريب
    }

    tabs.add(GButton(
      icon: isAdmin
          ? (selectedIndex == 4 ? Icons.groups_rounded : Icons.groups_outlined) // للأدمن
          : (selectedIndex == 3 ? Icons.chat_bubble_rounded : Icons.chat_bubble_outline_rounded), // للمستخدم
      text: isAdmin ? 'الأعضاء' : 'الرسائل',
      textStyle: textStyle,
      iconActiveColor: activeColor,
      iconColor: inactiveColor,
      // --- [جديد] إضافة الشارة ---
      leading: Obx(() { // Obx لمراقبة hasUnreadGlobalMessages
        if (bottomBarLogic.hasUnreadGlobalMessages.value) {
          debugPrint(';;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;');
          debugPrint(bottomBarLogic.hasUnreadGlobalMessages.value as String?);
          debugPrint(';;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;fs;;;;');

          return Badge( // يمكن استخدام Badge مدمج في Flutter أو من مكتبة
            // backgroundColor: Colors.red, // يمكنك تخصيص لون الشارة
            // صغير ومرتفع قليلاً
            padding: const EdgeInsets.all(1.5), // لجعل النقطة أصغر
            alignment: AlignmentDirectional.topEnd,
            offset: const Offset(-8, -5), // ضبط موضع النقطة
            child: Icon( // الأيقونة الأصلية
                isAdmin
                    ? (selectedIndex == 4 ? Icons.groups_rounded : Icons.groups_outlined)
                    : (selectedIndex == 3 ? Icons.chat_bubble_rounded : Icons.chat_bubble_outline_rounded),
                size: wi * 0.06,
                color: selectedIndex == 4 ? activeColor : inactiveColor
            ),
          );
        }
        // إذا لم تكن هناك رسائل غير مقروءة، اعرض الأيقونة فقط
        return Icon(
          isAdmin
              ? (selectedIndex == 4 ? Icons.groups_rounded : Icons.groups_outlined)
              : (selectedIndex == 3 ? Icons.chat_bubble_rounded : Icons.chat_bubble_outline_rounded),
          size: wi * 0.06,
          color: selectedIndex == 4 ? activeColor : inactiveColor,
        );
      }),
      // ---------------------------
    ));

    // إضافة الرسائل/الأعضاء والحساب الشخصي
    tabs.addAll([
      GButton(icon: profileIcon, text: 'حسابي', textStyle: textStyle, iconActiveColor: activeColor, iconColor: inactiveColor), // <<-- تعريب
    ]);

    return tabs;
  }
}

