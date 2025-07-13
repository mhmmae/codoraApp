import 'package:flutter/material.dart';
import 'package:get/get.dart';

// استبدل هذا بالمسار الصحيح للكنترولر في مشروعك
import 'CodeGroupsController.dart';

class CodeGroupsScreen extends StatelessWidget {
  const CodeGroupsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // استخدام Get.put لإنشاء أو العثور على الـ Controller
    final CodeGroupsController controller = Get.put(CodeGroupsController());
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    final Color primaryColor = Theme.of(context).colorScheme.primary;
    final double topPadding = MediaQuery.of(context).padding.top;
    // حساب ارتفاع تقريبي لمنطقة الأيقونات العلوية لتحديد إزاحة مؤشر التحديث ومقدار الحشو العلوي للمحتوى
    final double topBarHeight = topPadding + kToolbarHeight * 0.9; // قيمة تقديرية

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Stack( // Stack لوضع العناصر فوق بعضها (المحتوى، البحث، الأيقونات)
        children: [
          // --- المحتوى القابل للتمرير ---
          RefreshIndicator(
            onRefresh: controller.refreshData,
            color: primaryColor,
            // إزاحة مؤشر التحديث لأسفل قليلاً
            displacement: topBarHeight + 10,
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(), // تمكين التمرير دائمًا لـ RefreshIndicator
              slivers: [
                // --- فراغ علوي للمحتوى لتجنب التداخل مع الأيقونات ---
                SliverToBoxAdapter(
                  child: SizedBox(height: topBarHeight + (screenHeight * 0.01)),
                ),

                // --- قسم شرائح التصنيفات ---
                SliverToBoxAdapter(
                  child: _buildCategoryChips(context, controller, screenWidth, screenHeight, primaryColor),
                ),

                // --- قسم العناصر الهامة (PageView) ---
                SliverToBoxAdapter(
                  child: Obx(() {
                    // لا تعرض القسم إذا كان قيد التحميل الأولي والفارغ
                    if (controller.isLoading.value && controller.filteredHighImportanceItems.isEmpty && controller.filteredRandomItems.isEmpty) {
                      return const SizedBox.shrink();
                    }
                    // اعرض القسم حتى لو كان فارغًا بعد الفلترة لعرض الرسالة المناسبة داخله
                    return _buildHighImportanceSection(context, controller);
                  }),
                ),

                // --- فاصل بصري ---
                SliverToBoxAdapter(
                    child: Obx(() => // اعرض الفاصل فقط إذا كان هناك أي عناصر (هامة أو عشوائية)
                    (controller.filteredHighImportanceItems.isNotEmpty || controller.filteredRandomItems.isNotEmpty)
                        ? Divider(thickness: screenHeight * 0.001, indent: screenWidth * 0.05, endIndent: screenWidth * 0.05, height: screenHeight * 0.02,)
                        : const SizedBox.shrink()
                    )
                ),

                // --- قسم العناصر العشوائية (شبكة/قائمة) أو رسالة الحالة ---
                Obx(() {
                  // 1. حالة التحميل الأولية (عندما تكون كل القوائم فارغة والتحميل جارٍ)
                  if (controller.isLoading.value && controller.filteredRandomItems.isEmpty && controller.filteredHighImportanceItems.isEmpty) {
                    // عرض شبكة تحميل كعنصر نائب
                    return _buildLoadingSliverGrid(context, screenWidth, screenHeight);
                  }
                  // 2. حالة عدم وجود أي نتائج على الإطلاق (بعد التحميل والفلترة)
                  else if (!controller.isLoading.value && controller.filteredRandomItems.isEmpty && controller.filteredHighImportanceItems.isEmpty) {
                    return SliverFillRemaining( // لملء المساحة المتبقية
                      hasScrollBody: false, // لا تحتاج تمرير داخلي
                      child: Center(
                        child: Padding(
                          padding: EdgeInsets.all(screenWidth * 0.05),
                          child: Text(
                            _getEmptyResultMessage(controller), // الحصول على الرسالة المناسبة
                            style: TextStyle(fontSize: screenWidth * 0.045, color: Colors.grey[600]),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    );
                  }
                  // 3. حالة وجود عناصر هامة ولكن لا توجد عناصر عشوائية تطابق الفلتر
                  else if (controller.filteredRandomItems.isEmpty && controller.filteredHighImportanceItems.isNotEmpty) {
                    // عرض رسالة توضيحية بسيطة أو لا شيء
                    return SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: screenHeight * 0.05),
                        child: Center(
                          child: Text(
                            _getEmptyResultMessageForRandom(controller), // رسالة خاصة لهذه الحالة
                            style: TextStyle(fontSize: screenWidth * 0.04, color: Colors.grey[500]),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    );
                  }
                  // 4. حالة وجود عناصر عشوائية لعرضها (الاختيار بين الشبكة والقائمة)
                  else {
                    // استخدام Obx آخر لمراقبة نوع العرض وتحديث الواجهة فورًا
                    return Obx(() {
                      if (controller.currentViewType.value == ViewType.list) {
                        // بناء وعرض القائمة
                        return _buildRandomItemsSliverList(context, controller, screenWidth, screenHeight);
                      } else {
                        // بناء وعرض الشبكة (الافتراضي)
                        return _buildRandomItemsSliverGrid(context, controller, screenWidth, screenHeight);
                      }
                    });
                  }
                }),
                // --- نهاية قسم العناصر العشوائية ---

                // فراغ سفلي إضافي
                SliverToBoxAdapter(child: SizedBox(height: screenHeight * 0.03)),
              ],
            ),
          ),


          // --- شريط البحث (يظهر فوق المحتوى عند تفعيله) ---
          Obx(() => AnimatedPositioned(
            duration: const Duration(milliseconds: 300), // مدة الحركة
            curve: Curves.easeInOut, // نوع الحركة
            // تحديد الموضع: يظهر من الأعلى عند تفعيله، يختفي للأعلى عند إخفائه
            top: controller.isSearchVisible.value ? topPadding + (screenHeight * 0.01) : -kToolbarHeight,
            left: screenWidth * 0.04,
            right: screenWidth * 0.04,
            // التحكم في الشفافية أثناء الحركة
            child: AnimatedOpacity(
                duration: const Duration(milliseconds: 300),
                opacity: controller.isSearchVisible.value ? 1.0 : 0.0,
                // بناء حقل البحث الفعلي
                child: _buildSearchField(context, controller, screenWidth, screenHeight, primaryColor)
            ),
          )),


          // --- الأيقونات العلوية الثابتة (تظهر فوق المحتوى) ---
          _buildTopIconsOverlay(context, controller, screenWidth, screenHeight, topPadding, primaryColor),

        ],
      ),
    );
  }


  // ===========================================
  // الدوال المساعدة لبناء واجهة المستخدم (Widgets)
  // ===========================================

  // --- بناء الأيقونات العلوية (رجوع، عرض، ترتيب، بحث) ---
  Widget _buildTopIconsOverlay(BuildContext context, CodeGroupsController controller, double screenWidth, double screenHeight, double topPadding, Color primaryColor) {
    // استخدام Obx لمراقبة isSearchVisible لتغيير الشفافية
    return Obx(() => AnimatedOpacity(
      duration: const Duration(milliseconds: 200),
      opacity: controller.isSearchVisible.value ? 0.0 : 1.0, // إخفاء الأيقونات عند البحث
      child: IgnorePointer( // تجاهل النقرات على الأيقونات عندما تكون مخفية
        ignoring: controller.isSearchVisible.value,
        child: Padding(
          // تحديد موقع الأيقونات في الأعلى مع هوامش
          padding: EdgeInsets.only(
              top: topPadding + (screenHeight * 0.015),
              left: screenWidth * 0.03,
              right: screenWidth * 0.03
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween, // توزيع المسافات بين زر الرجوع وباقي الأيقونات
            children: [
              // زر الرجوع (في اليسار أو اليمين حسب اللغة)
              _buildOverlayIconButton(
                context: context,
                icon: Directionality.of(context) == TextDirection.rtl
                    ? Icons.arrow_forward_ios_rounded // أيقونة السهم لليمين للغة العربية
                    : Icons.arrow_back_ios_new_rounded, // أيقونة السهم لليسار للغات الأخرى
                tooltip: MaterialLocalizations.of(context).backButtonTooltip, // تلميح قياسي لزر الرجوع
                onPressed: () {
                  // التحقق إذا كان يمكن الرجوع قبل استدعاء Get.back()
                  if (Get.key.currentState?.canPop() ?? false) {
                    Get.back();
                  } else {
                    debugPrint("Cannot pop. No previous route.");
                    // يمكنك إضافة سلوك بديل هنا، مثل الانتقال إلى شاشة رئيسية
                  }
                },
                screenWidth: screenWidth,
              ),

              // مجموعة الأيقونات اليمنى (عرض، ترتيب، بحث)
              Row(
                mainAxisSize: MainAxisSize.min, // اجعل الصف يأخذ أقل عرض ممكن
                children: [
                  // --- زر تبديل العرض (قائمة/شبكة) ---
                  Obx(() { // مراقبة نوع العرض الحالي
                    final isGridView = controller.currentViewType.value == ViewType.grid;
                    return _buildOverlayIconButton(
                      context: context,
                      icon: isGridView ? Icons.view_list_rounded : Icons.grid_view_rounded, // تبديل الأيقونة
                      tooltip: isGridView ? 'عرض كقائمة' : 'عرض كشبكة', // تبديل التلميح
                      onPressed: () {
                        // تبديل نوع العرض عند الضغط
                        controller.changeViewType(isGridView ? ViewType.list : ViewType.grid);
                      },
                      screenWidth: screenWidth,
                    );
                  }),
                  SizedBox(width: screenWidth * 0.02), // مسافة فاصلة

                  // --- أيقونة الترتيب ---
                  _buildOverlayIconButton(
                    context: context,
                    icon: Icons.sort_rounded, // أيقونة الترتيب
                    tooltip: 'ترتيب',
                    onPressed: () => _showSortOptions(context, controller), // عرض خيارات الترتيب
                    screenWidth: screenWidth,
                  ),
                  SizedBox(width: screenWidth * 0.02), // مسافة فاصلة

                  // --- أيقونة البحث (لتفعيل شريط البحث) ---
                  _buildOverlayIconButton(
                    context: context,
                    icon: Icons.search_rounded,
                    tooltip: 'بحث',
                    onPressed: controller.toggleSearchVisibility, // تفعيل/إلغاء تفعيل شريط البحث
                    screenWidth: screenWidth,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ));
  }

  // --- دالة مساعدة لبناء الأزرار الأيقونية العلوية ---
  Widget _buildOverlayIconButton({
    required BuildContext context,
    required IconData icon,
    required String tooltip,
    required VoidCallback onPressed,
    required double screenWidth,
  }) {
    // استخدام Material لإضافة خلفية دائرية وظل وتأثير النقر
    return Material(
      color: Colors.black.withOpacity(0.45), // خلفية شبه شفافة
      shape: const CircleBorder(), // شكل دائري
      elevation: 3.0, // إضافة ظل خفيف
      child: InkWell( // لجعل الزر قابلاً للنقر
        onTap: onPressed,
        customBorder: const CircleBorder(), // تحديد منطقة النقر الدائرية
        child: Padding(
          padding: EdgeInsets.all(screenWidth * 0.025), // حشو داخلي حول الأيقونة
          child: Icon(
            icon,
            color: Colors.white, // لون الأيقونة
            size: screenWidth * 0.065, // حجم الأيقونة (تم تكبيره قليلاً)
          ),
        ),
      ),
    );
  }

  // --- بناء حقل البحث (عندما يكون مرئيًا) ---
  // --- بناء حقل البحث (عندما يكون مرئيًا) ---
  Widget _buildSearchField(BuildContext context, CodeGroupsController controller, double screenWidth, double screenHeight, Color primaryColor) {
    // استخدام Material كخلفية للحقل لإضافة ظل وحواف دائرية
    return Material(
      elevation: 4.0, // ظل لتمييز الحقل عن المحتوى
      borderRadius: BorderRadius.circular(screenWidth * 0.07), // حواف دائرية
      color: Theme.of(context).cardColor.withOpacity(0.95), // لون الخلفية (يمكن تعديله)
      child: SizedBox( // تحديد ارتفاع الحقل
        height: kToolbarHeight * 0.85, // ارتفاع مناسب
        child: Center( // توسيط TextField عموديًا
          child: TextField(
            controller: controller.searchController, // ربط المتحكم النصي
            focusNode: controller.searchFocusNode, // ربط عقدة التركيز
            onChanged: controller.updateSearchQuery, // استدعاء الدالة عند التغيير
            // --- ▼▼▼ إزالة أو تحويل هذا السطر إلى تعليق ▼▼▼ ---
            // autofocus: true, // التركيز التلقائي عند الظهور
            // --- ▲▲▲ نهاية التعديل ▲▲▲ ---
            style: TextStyle(fontSize: screenWidth * 0.042, color: Theme.of(context).textTheme.bodyLarge?.color), // نمط النص
            cursorColor: primaryColor, // لون مؤشر الكتابة
            decoration: InputDecoration(
              hintText: 'ابحث عن اسم الكود...', // النص التلميحي
              hintStyle: TextStyle(color: Colors.grey[500]),
              prefixIcon: Icon(Icons.search, size: screenWidth * 0.055, color: Colors.grey[600]), // أيقونة البحث في البداية
              // إظهار زر المسح فقط إذا كان هناك نص في الحقل
              suffixIcon: controller.searchQuery.value.isNotEmpty
                  ? IconButton(
                icon: Icon(Icons.close, size: screenWidth * 0.055, color: Colors.grey[600]),
                tooltip: 'مسح البحث',
                onPressed: controller.clearSearch, // استدعاء دالة المسح والإخفاء
              )
                  : null, // لا تظهر أيقونة إذا كان الحقل فارغًا
              contentPadding: EdgeInsets.symmetric(vertical: 0, horizontal: screenWidth * 0.04), // ضبط الحشو الداخلي
              // إزالة الحدود الافتراضية للـ TextField
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
            ),
          ),
        ),
      ),
    );
  }


  // --- دالة عرض خيارات الترتيب (باستخدام Get.bottomSheet) ---
  void _showSortOptions(BuildContext context, CodeGroupsController controller) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final options = SortOption.values; // الحصول على كل قيم الـ Enum للترتيب

    Get.bottomSheet(
      // استخدام Container لتصميم الـ BottomSheet
      Container(
        padding: EdgeInsets.all(screenWidth * 0.04), // حشو داخلي
        decoration: BoxDecoration(
          color: Theme.of(context).canvasColor, // لون الخلفية (عادة أبيض أو داكن حسب السمة)
          // حواف دائرية علوية
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(screenWidth * 0.05),
            topRight: Radius.circular(screenWidth * 0.05),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min, // اجعل الـ Column يأخذ أقل ارتفاع ممكن
          crossAxisAlignment: CrossAxisAlignment.start, // محاذاة العنوان لليسار
          children: [
            // عنوان الـ BottomSheet
            Padding(
              padding: EdgeInsets.only(bottom: screenHeight * 0.015),
              child: Text(
                'ترتيب حسب:',
                style: TextStyle(
                    fontSize: screenWidth * 0.045,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary // لون العنوان
                ),
              ),
            ),
            // بناء قائمة خيارات الترتيب
            ListView.builder(
              shrinkWrap: true, // ضروري داخل Column لمنع الخطأ في الحجم
              itemCount: options.length, // عدد خيارات الترتيب
              itemBuilder: (context, index) {
                final option = options[index];
                // التحقق إذا كان هذا الخيار هو المختار حاليًا
                final isSelected = controller.currentSortOption.value == option;

                // استخدام RadioListTile لعرض كل خيار
                return RadioListTile<SortOption>(
                  title: Text(
                      controller.getSortOptionText(option), // الحصول على النص المقروء للخيار
                      style: TextStyle(fontSize: screenWidth * 0.04, fontWeight: isSelected ? FontWeight.w500: FontWeight.normal)
                  ),
                  value: option, // القيمة الممثلة لهذا الخيار
                  groupValue: controller.currentSortOption.value, // القيمة المختارة حاليًا في المجموعة
                  // الدالة التي تُستدعى عند اختيار هذا الخيار
                  onChanged: (SortOption? newValue) {
                    if (newValue != null) {
                      controller.changeSortOption(newValue); // تغيير حالة الترتيب في الـ Controller
                      Get.back(); // إغلاق الـ BottomSheet تلقائيًا
                    }
                  },
                  activeColor: Theme.of(context).colorScheme.primary, // لون الراديو عند الاختيار
                  contentPadding: EdgeInsets.symmetric(horizontal: screenWidth * 0.01), // تقليل الحشو
                  visualDensity: VisualDensity.compact, // تقليل الكثافة البصرية (الحجم)
                );
              },
            ),
            SizedBox(height: screenHeight * 0.01), // هامش سفلي
          ],
        ),
      ),
      isScrollControlled: true, // السماح للـ BottomSheet بتغيير حجمه بناءً على المحتوى
    );
  }

  // --- بناء شرائح التصنيفات ---
  Widget _buildCategoryChips(BuildContext context, CodeGroupsController controller, double screenWidth, double screenHeight, Color primaryColor) {
    // مراقبة قائمة التصنيفات وحالة التحميل والتصنيف المختار
    return Obx(() {
      // عرض مؤشر تحميل إذا كانت التصنيفات قيد التحميل
      if (controller.isLoadingCategories.value) {
        return Container(
            height: screenHeight * 0.065, // نفس ارتفاع الشريط
            alignment: Alignment.center,
            child: const SizedBox(height: 30, width: 30, child: CircularProgressIndicator(strokeWidth: 2))
        );
      }
      // إخفاء الشريط إذا لم يكن هناك تصنيفات فعلية (فقط 'الكل' و/أو 'المفضلة' الفارغة)
      final categoriesToShow = controller.availableCategories.where((c) => c != 'الكل' && (c != 'المفضلة' || controller.favoriteItemIds.isNotEmpty)).toList();
      if (categoriesToShow.isEmpty && !controller.availableCategories.contains('المفضلة')) {
        // if (controller.availableCategories.length <= 1) { // الشرط الأصلي كان يعرض المفضلة دائماً
        return const SizedBox.shrink();
      }

      // بناء شريط التصنيفات
      return Container(
        height: screenHeight * 0.065, // ارتفاع الشريط
        padding: EdgeInsets.symmetric(vertical: screenHeight * 0.008), // حشو رأسي
        // يمكن إضافة خلفية أو ظل هنا إذا أردت فصله بصريًا
        // color: Theme.of(context).cardColor,
        child: ListView.builder(
          scrollDirection: Axis.horizontal, // تمرير أفقي
          padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.03), // حشو أفقي للقائمة
          itemCount: controller.availableCategories.length, // عدد التصنيفات الكلي
          itemBuilder: (context, index) {
            final category = controller.availableCategories[index];
            final bool isSelected = controller.selectedCategory.value == category;
            final bool isFavoriteCategory = category == 'المفضلة';

            // بناء كل شريحة تصنيف (ChoiceChip)
            return Padding(
              padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.01), // مسافة بين الشرائح
              child: ChoiceChip(
                // استخدام Row لإضافة أيقونة بجانب نص "المفضلة"
                label: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // عرض أيقونة القلب فقط لتصنيف "المفضلة"
                    if (isFavoriteCategory)
                      Icon( Icons.favorite_rounded, size: screenWidth * 0.04, color: isSelected ? Colors.white : Colors.pink[400]), // لون الأيقونة يتغير مع الاختيار
                    if (isFavoriteCategory) SizedBox(width: screenWidth * 0.01), // مسافة بين الأيقونة والنص
                    Text(category), // نص التصنيف
                  ],
                ),
                selected: isSelected, // تحديد إذا كانت الشريحة مختارة
                onSelected: (selected) {
                  // تغيير التصنيف المختار عند الضغط (إذا لم تكن مختارة بالفعل)
                  if (selected) controller.selectCategory(category);
                },
                // ألوان الشريحة تتغير بناءً على الاختيار ونوع التصنيف
                selectedColor: isFavoriteCategory ? Colors.pink[400] : primaryColor,
                labelStyle: TextStyle( color: isSelected ? Colors.white : (isFavoriteCategory ? Colors.pink[700] : Colors.black87), fontSize: screenWidth * 0.036, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,),
                backgroundColor: Colors.grey[200], // لون الخلفية الافتراضي
                shape: const StadiumBorder(side: BorderSide(color: Colors.transparent)), // شكل الشريحة بدون حدود واضحة
                padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.035, vertical: screenHeight * 0.006), // حشو داخلي
                visualDensity: VisualDensity.compact, // تقليل الحجم قليلاً
              ),
            );
          },
        ),
      );
    });
  }

  // --- بناء قسم العناصر الهامة (PageView) ---
  // --- بناء قسم العناصر الهامة (PageView) ---
  Widget _buildHighImportanceSection(BuildContext context, CodeGroupsController controller) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    // مراقبة قائمة العناصر الهامة المفلترة
    return Obx(() { // هذا Obx يراقب القائمة الخارجية فقط وهو صحيح
      if (controller.filteredHighImportanceItems.isEmpty) {
        return const SizedBox.shrink();
      }

      // بناء القسم إذا كانت هناك عناصر هامة
      return Column(
        children: [
          // حاوية الـ PageView
          SizedBox(
              height: screenHeight * 0.42, // ارتفاع منطقة العرض
              child: PageView.builder(
                controller: controller.pageController,
                itemCount: controller.filteredHighImportanceItems.length,
                onPageChanged: controller.onPageChanged,
                itemBuilder: (context, index) {
                  final item = controller.filteredHighImportanceItems[index];
                  final String itemId = item['id']?.toString() ?? 'invalid_id_$index';

                  return Padding(
                    padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.03, vertical: screenHeight*0.01),
                    child: Card(
                      elevation: 5.0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(screenWidth * 0.04)),
                      clipBehavior: Clip.antiAlias,
                      child: InkWell(
                        onTap: () => controller.navigateToDetail(item),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            _buildNetworkImage(imageUrl: item['imageUrl'], placeholderUrl: 'https://via.placeholder.com/300', itemId: itemId, index: index),
                            _buildItemNameOverlay(name: item['codeName'], context: context, isHighImportance: true),
                            Positioned(
                              top: screenHeight * 0.01,
                              right: screenWidth * 0.02,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // زر المشاركة (يبقى كما هو)
                                  _buildShareButton(context: context, controller: controller, item: item, screenWidth: screenWidth),
                                  SizedBox(width: screenWidth * 0.015),
                                  // --- ▼▼▼ التعديل النهائي هنا: إزالة Obx المحيطة بالاستدعاء ▼▼▼ ---
                                  _buildFavoriteButton( // استدعاء مباشر للدالة
                                      context: context,
                                      controller: controller,
                                      itemId: itemId,
                                      screenWidth: screenWidth
                                    // useDarkBackground يبقى true (الافتراضي) هنا
                                  ),
                                  // --- ▲▲▲ نهاية التعديل النهائي ▲▲▲ ---
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              )
          ),
          // بناء نقاط المؤشر أسفل الـ PageView
          _buildPageIndicator(context, controller, screenWidth, screenHeight),
        ],
      );
    });
  }

  // --- بناء مؤشر الصفحات (Dots) ---
  Widget _buildPageIndicator(BuildContext context, CodeGroupsController controller, double screenWidth, double screenHeight) {
    // مراقبة قائمة العناصر الهامة والمؤشر الحالي
    return Obx(() {
      final itemCount = controller.filteredHighImportanceItems.length;
      final bool hasMultipleItems = itemCount > 1;
      // حساب الارتفاع المتوقع للنقاط + الحشو لضمان ثبات الارتفاع
      final double dotHeight = screenWidth * 0.028; // أقصى ارتفاع للنقطة
      final double verticalPadding = screenHeight * 0.01;
      final double placeholderHeight = (verticalPadding * 2) + dotHeight;

      // عرض النقاط فقط إذا كان هناك أكثر من عنصر
      if (hasMultipleItems) {
        return Padding(
          padding: EdgeInsets.symmetric(vertical: verticalPadding),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center, // توسيط النقاط
            children: List.generate(itemCount, (index) {
              // تحديد إذا كانت النقطة الحالية هي المختارة
              final bool isSelected = controller.currentImageIndex.value == index;
              // بناء كل نقطة
              return InkWell(
                onTap: () => controller.onDotTapped(index), // الانتقال للصفحة عند النقر
                customBorder: const CircleBorder(), // منطقة النقر دائرية
                child: AnimatedContainer( // استخدام AnimatedContainer لتغيير الحجم بسلاسة
                  duration: const Duration(milliseconds: 200),
                  margin: EdgeInsets.symmetric(horizontal: screenWidth * 0.01), // مسافة بين النقاط
                  // تغيير حجم النقطة بناءً على الاختيار
                  width: isSelected ? screenWidth * 0.028 : screenWidth * 0.02,
                  height: isSelected ? dotHeight : screenWidth * 0.02,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle, // شكل دائري
                    // تغيير لون النقطة بناءً على الاختيار
                    color: isSelected ? Theme.of(context).colorScheme.primary : Colors.grey.shade400,
                  ),
                ),
              );
            }),
          ),
        );
      } else {
        // إذا لم يكن هناك نقاط متعددة، اعرض SizedBox بنفس الارتفاع للحفاظ على التنسيق
        return SizedBox(height: placeholderHeight);
      }
    });
  }


  // --- بناء قسم العناصر الأخرى كشبكة (GridView) ---
  // --- بناء قسم العناصر الأخرى كشبكة (GridView) ---
  Widget _buildRandomItemsSliverGrid(BuildContext context, CodeGroupsController controller, double screenWidth, double screenHeight) {
    return SliverPadding(
      padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.03).copyWith(top: screenHeight * 0.01, bottom: screenWidth * 0.02),
      sliver: SliverGrid(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount( crossAxisCount: 3, crossAxisSpacing: screenWidth * 0.025, mainAxisSpacing: screenHeight * 0.015, childAspectRatio: 0.78,),
        delegate: SliverChildBuilderDelegate(
              (context, index) {
            final item = controller.filteredRandomItems[index];
            final String itemId = item['id']?.toString() ?? 'invalid_random_id_$index';

            return Card(
              shape: RoundedRectangleBorder( borderRadius: BorderRadius.circular(screenWidth * 0.03)),
              elevation: 3, clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: () => controller.navigateToDetail(item),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    _buildNetworkImage( imageUrl: item['imageUrl'], placeholderUrl: 'https://via.placeholder.com/150', itemId: itemId, index: index),
                    _buildItemNameOverlay( name: item['codeName'], context: context, isHighImportance: false),
                    Positioned(
                        top: screenHeight * 0.005,
                        right: screenWidth * 0.01,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // زر المشاركة (يبقى كما هو)
                            _buildShareButton(context: context, controller: controller, item: item, screenWidth: screenWidth, sizeMultiplier: 0.8),
                            SizedBox(height: screenHeight * 0.005),
                            // --- ▼▼▼ التعديل هنا: إزالة Obx المحيطة بالاستدعاء ▼▼▼ ---
                            _buildFavoriteButton( // استدعاء مباشر للدالة التي تستدعي FavoriteButtonWidget
                                context: context,
                                controller: controller,
                                itemId: itemId,
                                screenWidth: screenWidth,
                                sizeMultiplier: 0.8 // تصغير الأزرار قليلاً
                            ),
                            // --- ▲▲▲ نهاية التعديل ▲▲▲ ---
                          ],
                        )
                    ),
                  ],
                ),
              ),
            );
          },
          childCount: controller.filteredRandomItems.length,
        ),
      ),
    );
  }

  // --- بناء قسم العناصر الأخرى كقائمة (ListView) ---
  Widget _buildRandomItemsSliverList(BuildContext context, CodeGroupsController controller, double screenWidth, double screenHeight) {
    // استخدام SliverPadding لإضافة حشو حول القائمة
    return SliverPadding(
      padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.02)
          .copyWith(top: screenHeight * 0.01, bottom: screenWidth * 0.02),
      sliver: SliverList(
        // بناء عناصر القائمة
        delegate: SliverChildBuilderDelegate(
              (context, index) {
            final item = controller.filteredRandomItems[index];
            // بناء كل عنصر في القائمة باستخدام ودجت مساعد
            return _buildListItem(context, controller, item, screenWidth, screenHeight);
          },
          // تحديد عدد العناصر في القائمة
          childCount: controller.filteredRandomItems.length,
        ),
      ),
    );
  }

  // --- بناء عنصر واحد في القائمة (ListItem) ---
  // --- بناء عنصر واحد في القائمة (ListItem) ---
  Widget _buildListItem(BuildContext context, CodeGroupsController controller, Map<String, dynamic> item, double screenWidth, double screenHeight) {
    final String itemId = item['id']?.toString() ?? 'invalid_list_id_${item['codeName']}';
    final String? imageUrl = item['imageUrl'];
    final String name = item['codeName'] ?? 'اسم غير معروف';

    return Card(
      margin: EdgeInsets.only(bottom: screenHeight * 0.015),
      elevation: 2.5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(screenWidth * 0.025)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => controller.navigateToDetail(item),
        child: Row(
          children: [
            // الصورة المصغرة
            SizedBox(
              width: screenWidth * 0.25,
              height: screenHeight * 0.12,
              child: _buildNetworkImage( imageUrl: imageUrl, placeholderUrl: 'https://via.placeholder.com/100', itemId: itemId, index: 0,),
            ),
            // المحتوى النصي والأزرار
            Expanded(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.03, vertical: screenHeight * 0.01),
                child: SizedBox(
                  height: screenHeight * 0.1,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // اسم الكود
                      Text( name, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: screenWidth * 0.04, fontWeight: FontWeight.w500),),
                      // أزرار الإجراءات
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          // زر المشاركة (يبقى كما هو)
                          _buildShareButton(context: context, controller: controller, item: item, screenWidth: screenWidth, sizeMultiplier: 0.85, useDarkBackground: false),
                          SizedBox(width: screenWidth * 0.02),

                          // --- ▼▼▼ التعديل هنا: إزالة Obx المحيطة بالاستدعاء ▼▼▼ ---
                          _buildFavoriteButton( // استدعاء مباشر للدالة
                              context: context,
                              controller: controller,
                              itemId: itemId,
                              screenWidth: screenWidth,
                              sizeMultiplier: 0.85,
                              useDarkBackground: false // تأكد من أن Obx داخل هذه الدالة لا يزال يلف Icon
                          ),
                          // --- ▲▲▲ نهاية التعديل ▲▲▲ ---
                        ],
                      )
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- بناء شبكة التحميل (Loading Grid) ---
  Widget _buildLoadingSliverGrid(BuildContext context, double screenWidth, double screenHeight) {
    // استخدام نفس تصميم الشبكة العادية ولكن بعناصر رمادية
    return SliverPadding(
      padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.03).copyWith(top: screenHeight * 0.01, bottom: screenWidth * 0.02),
      sliver: SliverGrid(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount( crossAxisCount: 3, crossAxisSpacing: screenWidth * 0.025, mainAxisSpacing: screenHeight * 0.015, childAspectRatio: 0.78,),
        delegate: SliverChildBuilderDelegate(
              (context, index) => Card( // استخدام Card بنفس الشكل
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(screenWidth * 0.03)),
            elevation: 2, // ظل خفيف
            clipBehavior: Clip.antiAlias,
            child: Container( // محتوى رمادي بسيط
              decoration: BoxDecoration( color: Colors.grey[300], borderRadius: BorderRadius.circular(screenWidth * 0.03)),
              // يمكنك إضافة Shimmer effect هنا إذا أردت
            ),
          ),
          childCount: 9, // عرض عدد ثابت من عناصر التحميل
        ),
      ),
    );
  }

  // --- بناء زر المفضلة (مع خيار للتحكم في الخلفية) ---
  // --- بناء زر المفضلة (مع خيار للتحكم في الخلفية وتعديل Obx) ---
  Widget _buildFavoriteButton({
    required BuildContext context,
    required CodeGroupsController controller,
    required String itemId,
    required double screenWidth,
    double sizeMultiplier = 1.0,
    bool useDarkBackground = true,
  }) {
    // التأكد من أن itemId صالح قبل بناء الزر
    if (itemId.isEmpty || itemId.startsWith('invalid_')) {
      return const SizedBox.shrink();
    }

    // --- ▼▼▼ تعديل هنا: Material و InkWell خارج Obx ▼▼▼ ---
    return Material(
      color: useDarkBackground ? Colors.black.withOpacity(0.35) : Colors.transparent,
      shape: const CircleBorder(),
      elevation: useDarkBackground ? 2.0 : 0.0,
      child: InkWell(
        onTap: () => controller.toggleFavorite(itemId), // تبديل حالة المفضلة عند النقر
        customBorder: const CircleBorder(),
        child: Padding(
          padding: EdgeInsets.all(screenWidth * 0.012 * sizeMultiplier),
          // --- ▼▼▼ تعديل هنا: Obx يلتف حول Icon فقط ▼▼▼ ---
          child: Obx(() {
            // قراءة الحالة المتغيرة داخل Obx
            final bool isFav = controller.isFavorite(itemId);
            // تحديد لون الأيقونة بناءً على الحالة ونوع الخلفية
            final Color iconColor = useDarkBackground
                ? (isFav ? Colors.pinkAccent : Colors.white)
                : (isFav ? Colors.pinkAccent : Colors.grey[600]!);

            // بناء الـ Icon الذي يعتمد على الحالة المتغيرة
            return Icon(
              isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
              color: iconColor,
              size: screenWidth * 0.055 * sizeMultiplier,
            );
          }),
          // --- ▲▲▲ نهاية تعديل Obx ▲▲▲ ---
        ),
      ),
    );
    // --- ▲▲▲ نهاية تعديل Material و InkWell ▲▲▲ ---
  }

  // --- بناء زر المشاركة (مع خيار للتحكم في الخلفية) ---
  Widget _buildShareButton({
    required BuildContext context,
    required CodeGroupsController controller,
    required Map<String, dynamic> item, // تمرير بيانات العنصر للمشاركة
    required double screenWidth,
    double sizeMultiplier = 1.0,
    bool useDarkBackground = true,
  }) {
    // تحديد لون الأيقونة بناءً على الخلفية
    final Color iconColor = useDarkBackground ? Colors.white : Colors.grey[600]!;
    // استخدام Material بنفس طريقة زر المفضلة
    return Material(
      color: useDarkBackground ? Colors.black.withOpacity(0.35) : Colors.transparent,
      shape: const CircleBorder(),
      elevation: useDarkBackground ? 2.0 : 0.0,
      child: InkWell(
        onTap: () => controller.shareCodeGroup(item, context), // استدعاء دالة المشاركة من الـ Controller
        customBorder: const CircleBorder(),
        child: Padding(
          padding: EdgeInsets.all(screenWidth * 0.012 * sizeMultiplier),
          child: Icon(
            Icons.share_rounded, // أيقونة المشاركة
            color: iconColor,
            size: screenWidth * 0.055 * sizeMultiplier,
          ),
        ),
      ),
    );
  }

  // --- بناء وعرض الصورة من الشبكة ---
  Widget _buildNetworkImage({
    required String? imageUrl,
    required String placeholderUrl,
    required dynamic itemId, // يمكن أن يكون String أو أي نوع آخر، نستخدمه للمفتاح
    required int index, // يستخدم كمفتاح احتياطي إذا كان itemId غير صالح
  }) {
    // استخدام مفتاح مميز لكل صورة لـ Flutter لتحديدها وتحديثها بشكل صحيح
    final imageKey = ValueKey(itemId?.toString() ?? 'img_$index');
    // استخدام Image.network لعرض الصورة
    return Image.network(
      imageUrl ?? placeholderUrl, // استخدام placeholder إذا كان imageUrl فارغًا
      key: imageKey, // المفتاح المميز
      fit: BoxFit.cover, // جعل الصورة تغطي المساحة المتاحة
      // بناء واجهة مخصصة أثناء تحميل الصورة
      loadingBuilder: (context, child, loadingProgress) {
        // إذا اكتمل التحميل، اعرض الصورة نفسها
        if (loadingProgress == null) return child;
        // إذا كان التحميل جاريًا، اعرض مؤشر تحميل دائري
        return Center(
            child: CircularProgressIndicator(
              strokeWidth: 2.0,
              // عرض نسبة التحميل إن أمكن
              value: loadingProgress.expectedTotalBytes != null
                  ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                  : null,
            )
        );
      },
      // بناء واجهة مخصصة في حالة حدوث خطأ أثناء تحميل الصورة
      errorBuilder: (context, error, stackTrace) {
        debugPrint("Image Load Error ($itemId): $error"); // طباعة الخطأ للمساعدة في التصحيح
        // عرض أيقونة خطأ أو صورة بديلة
        return Container(
          color: Colors.grey[200], // خلفية رمادية
          child: Center(
            child: Icon(Icons.broken_image_outlined, size: 40, color: Colors.grey[500]), // أيقونة صورة معطلة
          ),
        );
      },
    );
  }

  // --- بناء النص المتراكب فوق الصورة (اسم العنصر) ---
  Widget _buildItemNameOverlay({
    required String? name,
    required BuildContext context,
    required bool isHighImportance, // لتحديد التصميم المختلف للعناصر الهامة
  }) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    // تصميم خاص للعناصر الهامة (PageView)
    if (isHighImportance) {
      return Positioned( // تحديد موقع النص في الأسفل
        bottom: 0, left: 0, right: 0,
        child: Container(
          // إضافة تدرج لوني داكن في الأسفل لتحسين قراءة النص
          decoration: BoxDecoration(
            gradient: LinearGradient(
                colors: [Colors.black.withOpacity(0.85), Colors.transparent], // من داكن إلى شفاف
                begin: Alignment.bottomCenter, // يبدأ من الأسفل
                end: Alignment.topCenter, // ينتهي في الأعلى
                stops: const [0.0, 0.9] // نقاط توقف التدرج
            ),
          ),
          padding: EdgeInsets.symmetric( horizontal: screenWidth * 0.04, vertical: screenHeight * 0.012,).copyWith(top: screenHeight * 0.03), // حشو حول النص
          child: Text(
            name ?? 'اسم غير معروف', // عرض النص أو قيمة افتراضية
            style: TextStyle( color: Colors.white, fontSize: screenWidth * 0.045, fontWeight: FontWeight.bold, // نمط النص (أبيض، عريض)
                shadows: [ Shadow( offset: const Offset(0, 1), blurRadius: 3.0, color: Colors.black.withOpacity(0.7),)]), // ظل للنص
            maxLines: 2, // السماح بسطرين كحد أقصى
            overflow: TextOverflow.ellipsis, // عرض "..." إذا كان النص أطول
            textAlign: TextAlign.center, // توسيط النص
          ),
        ),
      );
    }
    // تصميم العناصر الأخرى (الشبكة أو القائمة)
    else {
      return Positioned( bottom: 0, left: 0, right: 0,
        child: Container(
          decoration: BoxDecoration( gradient: LinearGradient( colors: [Colors.black.withOpacity(0.9), Colors.transparent], begin: Alignment.bottomCenter, end: Alignment.topCenter, stops: const [0.0, 0.9]),),
          padding: EdgeInsets.only( top: screenHeight * 0.02, bottom: screenHeight * 0.008, left: screenWidth * 0.015, right: screenWidth * 0.015,),
          child: Text(
            name ?? 'اسم غير معروف',
            textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis,
            style: TextStyle( fontSize: screenWidth * 0.035, fontWeight: FontWeight.bold, color: Colors.white, shadows: [ Shadow( offset: const Offset(0, 1), blurRadius: 3.0, color: Colors.black.withOpacity(0.8),)]),
          ),
        ),
      );
    }
  }

  // --- دالة للحصول على رسالة الحالة الفارغة المناسبة ---
  String _getEmptyResultMessage(CodeGroupsController controller) {
    if (controller.selectedCategory.value == 'المفضلة') {
      if (controller.searchQuery.value.isNotEmpty) {
        return "لا توجد عناصر مفضلة تطابق بحثك";
      } else {
        return "لم تقم بإضافة أي عناصر إلى المفضلة بعد.\n اضغط على أيقونة القلب لإضافتها.";
      }
    } else if (controller.searchQuery.value.isNotEmpty || controller.selectedCategory.value != 'الكل' || controller.currentSortOption.value != SortOption.none) {
      // إذا كان هناك فلتر (بحث أو تصنيف أو ترتيب) مطبق
      return "لا توجد نتائج تطابق الفلتر أو الترتيب المحدد.";
    } else {
      // الحالة الافتراضية (لا يوجد فلتر ولا توجد أي بيانات على الإطلاق)
      return "لا توجد مجموعات أكواد لعرضها حاليًا.";
    }
  }

  // --- دالة للحصول على رسالة الحالة الفارغة للعناصر العشوائية/القائمة فقط ---
  String _getEmptyResultMessageForRandom(CodeGroupsController controller) {
    // لا تعرض رسالة إذا كان القسم الهام يعرض شيئًا ولم يتم تطبيق فلتر
    if (controller.filteredHighImportanceItems.isNotEmpty && controller.searchQuery.value.isEmpty && controller.selectedCategory.value == 'الكل' && controller.currentSortOption.value == SortOption.none) {
      return "";
    }
    // إذا كان المستخدم في المفضلة، لا تعرض رسالة إضافية هنا
    if (controller.selectedCategory.value == 'المفضلة') {
      return "";
    }
    // إذا كان هناك فلتر مطبق ولم توجد نتائج في هذا القسم
    if (controller.searchQuery.value.isNotEmpty || controller.selectedCategory.value != 'الكل' || controller.currentSortOption.value != SortOption.none) {
      return "لا توجد عناصر أخرى تطابق الفلتر أو الترتيب المحدد";
    } else {
      // حالة نادرة: لا يوجد عناصر هامة ولا عشوائية بدون فلتر (تتم معالجتها بواسطة _getEmptyResultMessage)
      return "";
    }
  }

} // نهاية كلاس CodeGroupsScreen