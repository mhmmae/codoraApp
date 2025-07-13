import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../XXX/xxx_firebase.dart';
import '../controllers/enhanced_category_filter_controller.dart';
import '../widgets/simple_main_categories_widget.dart';
import '../controllers/brand_filter_controller.dart';
import '../controllers/barcode_filter_controller.dart';
import '../widgets/brand_filter_widget.dart';

import '../Get-Controllar/GetSerchController.dart';
import '../class/FavoritesScreen.dart';
import '../class/OffersCarouselWidget.dart';
import '../class/ProductGridWidget.dart';
import '../class/SearchResultsListWidget.dart';
// النظام المبسط تم حذفه واستبداله بالنظام المحسن

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // الحصول على المتحكمات (تفترض أنه تم حقنها مسبقًا)
    final GetSearchController searchCtrl = Get.find<GetSearchController>();
    
    // محاولة استخدام النظام الجديد، وفي حالة عدم وجوده، استخدم النظام المبسط
    try {
      Get.find<EnhancedCategoryFilterController>();
    } catch (e) {
      debugPrint("النظام الجديد غير متاح، سيتم استخدام النظام المبسط");
      Get.put(EnhancedCategoryFilterController());
    }
    
    final BrandFilterController brandCtrl = Get.put(BrandFilterController());
    final BarcodeFilterController barcodeCtrl = Get.put(BarcodeFilterController());

    double hi = MediaQuery.of(context).size.height;
    final wi = MediaQuery.of(context).size.width; 
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text("الصفحة الرئيسية", style: TextStyle(color: theme.textTheme.titleLarge?.color)),
        backgroundColor: theme.appBarTheme.backgroundColor ?? theme.scaffoldBackgroundColor,
        elevation: theme.appBarTheme.elevation ?? 0,
        foregroundColor: theme.appBarTheme.foregroundColor ?? theme.colorScheme.primary,
        actions: [
          // --- أيقونة البحث ---
          IconButton(
            icon: Icon(Icons.search),
            tooltip: 'بحث',
            onPressed: () {
              Get.to(() => SearchScreen(), transition: Transition.downToUp );
            },
          ),

          // --- أيقونة البحث بالباركود ---
          Obx(() => IconButton(
            icon: Icon(
              Icons.qr_code_scanner,
              color: barcodeCtrl.hasActiveFilter 
                  ? theme.colorScheme.primary 
                  : theme.appBarTheme.foregroundColor,
            ),
            tooltip: 'البحث بالباركود',
            onPressed: () {
              if (barcodeCtrl.hasActiveFilter) {
                barcodeCtrl.clearCurrentBarcode();
              } else {
                if (brandCtrl.isBrandModeActive.value) {
                  brandCtrl.deactivateBrandMode();
                }
                barcodeCtrl.activateBarcodeSearch();
              }
            },
          )),

          IconButton(
            icon: Icon(Icons.favorite_border_rounded),
            tooltip: 'المفضلة',
            onPressed: () {
              Get.to(() => FavoritesScreen());
            },
          ),
          
          // --- أيقونة الترتيب ---
          PopupMenuButton<SortOption>(
            icon: Icon(Icons.sort),
            tooltip: 'ترتيب حسب',
            onSelected: (SortOption result) {
              searchCtrl.changeSortOption(result);
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<SortOption>>[
              for (final option in SortOption.values)
                PopupMenuItem<SortOption>(
                  value: option,
                  child: Obx(() => Text(
                    option.label,
                    style: TextStyle(
                      fontWeight: searchCtrl.currentSortOption.value == option
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  )),
                ),
            ],
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          debugPrint("Refreshing...");
          await Future.delayed(Duration(seconds: 1));
        },
        child: ListView(
          children: [
             SizedBox(height: hi/70),
            // عروض - مرر الـ pageController من searchController
            StreamBuilder(
              stream: FirebaseFirestore.instance
                  .collection(FirebaseX.offersCollection)
                  .where('appName', isEqualTo: FirebaseX.appName)
                  .limit(10)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  // يمكنك إرجاع شيمر أو لا شيء حسب رغبتك
                  return SizedBox.shrink();
                }
                final docs = snapshot.data?.docs ?? [];
                if (docs.isEmpty) {
                  // لا يوجد عروض: لا ترجع أي ويدجت (لا تأخذ أي مساحة)
                  return SizedBox.shrink();
                }
                // يوجد عروض: أظهر ويدجت العروض
                return OffersCarouselWidget();
              },
            ),

             SizedBox(height: hi/70),
            const Divider(),

            // ويدجت البحث من خلال البراند والباركود
            const BrandFilterWidget(),
            const Divider(),
             SizedBox(height: hi/70),

            // عرض الأقسام (النظام الجديد أو القديم)
            Obx(() => (brandCtrl.isBrandModeActive.value || barcodeCtrl.isBarcodeSearchActive.value)
                ? const SizedBox.shrink()
                : _buildCategoriesWidget()),
            const Divider(),



            SizedBox(height: hi/70),

            // شبكة المنتجات مع الفلترة المحسنة
            Obx(() {
              String filterKey = 'all_items'; // القيمة الافتراضية
              
              if (barcodeCtrl.hasActiveFilter) {
                filterKey = barcodeCtrl.getFilterKey();
              } else if (brandCtrl.isBrandModeActive.value) {
                filterKey = brandCtrl.getFilterKey();
              } else {
                // محاولة استخدام النظام الجديد أولاً
                try {
                  final filterCtrl = Get.find<EnhancedCategoryFilterController>();
                  filterKey = filterCtrl.getFilterKey();
                                 } catch (e) {
                   // إذا فشل، استخدم النظام المبسط
                   try {
                     final categoryFilterCtrl = Get.find<EnhancedCategoryFilterController>();
                     filterKey = categoryFilterCtrl.getFilterKey();
                   } catch (e2) {
                     // إبقاء القيمة الافتراضية
                   }
                 }
              }
              
              final selectedSort = searchCtrl.currentSortOption.value;

              debugPrint("Rebuilding Product Grid: Filter='$filterKey', Sort='${selectedSort.label}'");
              debugPrint("Brand Mode Active: ${brandCtrl.isBrandModeActive.value}");
              debugPrint("Barcode Search Active: ${barcodeCtrl.hasActiveFilter}");

              return ProductGridWidgetOption(
                selectedSubtypeKey: filterKey,
              );
            }),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

     // بناء ويدجت الأقسام (جديد أو مبسط)
   Widget _buildCategoriesWidget() {
     try {
       final filterCtrl = Get.find<EnhancedCategoryFilterController>();
       // إذا وُجد النظام الجديد، استخدمه
       return const SimpleMainCategoriesWidget();
     } catch (e) {
       // إذا لم يوجد النظام الجديد، استخدم النظام المبسط
       return const SimpleMainCategoriesWidget();
     }
   }
}

// --- شاشة البحث المنفصلة (مثال بسيط) ---
class SearchScreen extends StatelessWidget {
  const SearchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // الحصول على نفس المتحكم الرئيسي أو إنشاء متحكم بحث خاص
    final GetSearchController searchController = Get.find<GetSearchController>();
    // أو إنشاء واحد جديد: Get.put(SearchScreenController());

    return Scaffold(
      appBar: AppBar(
        // --- حقل البحث في AppBar ---
        title: TextField(
          controller: searchController.searchFieldController, // ربط المتحكم
          autofocus: true, // فتح لوحة المفاتيح تلقائياً
          decoration: InputDecoration(
            hintText: "ابحث عن المنتجات...", // <<-- تعريب
            border: InputBorder.none,
            hintStyle: TextStyle(color: Colors.grey[600]),
          ),
          style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color, fontSize: 18),
          onChanged: (value) {
            // قيمة البحث تتحدث تلقائياً في RxString في المتحكم بفضل المستمع
            // searchController.searchQuery.value = value; // لا حاجة لهذا السطر إذا كان المستمع يعمل
          },
        ),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        foregroundColor: Theme.of(context).appBarTheme.foregroundColor,
      ),
      body: Obx(() { // مراقبة searchQuery
        // --- عرض النتائج باستخدام Widget البحث ---
        return SearchResultsListWidget(searchQuery: searchController.searchQuery.value);
      }),
    );
  }
}
