import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import '../controllers/store_products_controller.dart';

class StoreStatisticsPage extends StatefulWidget {
  const StoreStatisticsPage({super.key});

  @override
  State<StoreStatisticsPage> createState() => _StoreStatisticsPageState();
}

class _StoreStatisticsPageState extends State<StoreStatisticsPage>
    with TickerProviderStateMixin {
  late TabController _tabController;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));
    _animationController.forward();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  // دالة تنسيق السعر مع الفواصل
  String _formatPrice(double price) {
    final formatter = NumberFormat('#,###', 'ar');
    return formatter.format(price.toInt());
  }

  // دالة تنسيق النسبة المئوية
  String _formatPercentage(double percentage) {
    return '${percentage.toStringAsFixed(1)}%';
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<StoreProductsController>();
    
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: CustomScrollView(
            slivers: [
              _buildSliverAppBar(controller),
              SliverToBoxAdapter(
                child: Column(
                  children: [
                    _buildOverviewCards(controller),
                    _buildTabSection(controller),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSliverAppBar(StoreProductsController controller) {
    return SliverAppBar(
      expandedHeight: 200.h,
      floating: false,
      pinned: true,
      elevation: 0,
      backgroundColor: const Color(0xFF6366F1),
      flexibleSpace: FlexibleSpaceBar(
        title: Text(
          'إحصائيات ${controller.store.shopName}',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color(0xFF6366F1),
                const Color(0xFF8B5CF6),
                const Color(0xFFEC4899),
              ],
            ),
          ),
          child: Stack(
            children: [
              // تأثيرات بصرية
              Positioned(
                top: 50.h,
                right: -50.w,
                child: Container(
                  width: 200.w,
                  height: 200.w,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.1),
                  ),
                ),
              ),
              Positioned(
                bottom: -30.h,
                left: -30.w,
                child: Container(
                  width: 120.w,
                  height: 120.w,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.1),
                  ),
                ),
              ),
              // أيقونة الإحصائيات
              Positioned(
                bottom: 60.h,
                right: 30.w,
                child: Icon(
                  Icons.analytics_rounded,
                  size: 60.sp,
                  color: Colors.white.withOpacity(0.3),
                ),
              ),
            ],
          ),
        ),
      ),
      leading: IconButton(
        icon: Icon(Icons.arrow_back_ios, color: Colors.white, size: 20.sp),
        onPressed: () => Get.back(),
      ),
      actions: [
        IconButton(
          icon: Icon(Icons.refresh, color: Colors.white, size: 22.sp),
          onPressed: () => controller.refresh(),
        ),
        IconButton(
          icon: Icon(Icons.share, color: Colors.white, size: 22.sp),
          onPressed: _shareStatistics,
        ),
      ],
    );
  }

  Widget _buildOverviewCards(StoreProductsController controller) {
    return Obx(() {
      final totalProducts = controller.allProducts.length;
      final totalValue = _calculateTotalValue(controller);
      final totalCost = _calculateTotalCost(controller);
      final expectedProfit = totalValue - totalCost;
      final profitMargin = totalValue > 0 ? (expectedProfit / totalValue) * 100 : 0.0;

      return Container(
        padding: EdgeInsets.all(20.w),
        child: AnimationLimiter(
          child: GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: 15.w,
            mainAxisSpacing: 15.h,
            childAspectRatio: 1.2,
            children: AnimationConfiguration.toStaggeredList(
              duration: const Duration(milliseconds: 600),
              childAnimationBuilder: (widget) => SlideAnimation(
                horizontalOffset: 50.0,
                child: FadeInAnimation(child: widget),
              ),
              children: [
                _buildOverviewCard(
                  title: 'إجمالي المنتجات',
                  value: totalProducts.toString(),
                  icon: Icons.inventory_2_rounded,
                  color: const Color(0xFF6366F1),
                  gradient: [const Color(0xFF6366F1), const Color(0xFF8B5CF6)],
                ),
                _buildOverviewCard(
                  title: 'قيمة المخزون',
                  value: '${_formatPrice(totalValue)} د.ع',
                  icon: Icons.monetization_on_rounded,
                  color: const Color(0xFF059669),
                  gradient: [const Color(0xFF059669), const Color(0xFF10B981)],
                ),
                _buildOverviewCard(
                  title: 'تكلفة المخزون',
                  value: '${_formatPrice(totalCost)} د.ع',
                  icon: Icons.account_balance_wallet_rounded,
                  color: const Color(0xFFEF4444),
                  gradient: [const Color(0xFFEF4444), const Color(0xFFF97316)],
                ),
                _buildOverviewCard(
                  title: 'الربح المتوقع',
                  value: '${_formatPrice(expectedProfit)} د.ع',
                  subtitle: 'هامش ${_formatPercentage(profitMargin)}',
                  icon: Icons.trending_up_rounded,
                  color: const Color(0xFFEC4899),
                  gradient: [const Color(0xFFEC4899), const Color(0xFF8B5CF6)],
                ),
              ],
            ),
          ),
        ),
      );
    });
  }

  Widget _buildOverviewCard({
    required String title,
    required String value,
    String? subtitle,
    required IconData icon,
    required Color color,
    required List<Color> gradient,
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradient,
        ),
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 15.r,
            offset: Offset(0, 8.h),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Stack(
        children: [
          // تأثير بصري
          Positioned(
            top: -20.h,
            right: -20.w,
            child: Container(
              width: 80.w,
              height: 80.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.1),
              ),
            ),
          ),
          // المحتوى
          Padding(
            padding: EdgeInsets.all(16.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  icon,
                  color: Colors.white,
                  size: 28.sp,
                ),
                Spacer(),
                Text(
                  title,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  value,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (subtitle != null) ...[
                  SizedBox(height: 2.h),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 10.sp,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabSection(StoreProductsController controller) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 20.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20.r,
            offset: Offset(0, 10.h),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Column(
        children: [
          _buildTabBar(),
          SizedBox(
            height: 400.h,
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildCategoryChart(controller),
                _buildPriceRangeChart(controller),
                _buildProfitAnalysis(controller),
                _buildDetailedStats(controller),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          gradient: LinearGradient(
            colors: [const Color(0xFF6366F1), const Color(0xFF8B5CF6)],
          ),
          borderRadius: BorderRadius.circular(10.r),
        ),
        labelColor: Colors.white,
        unselectedLabelColor: const Color(0xFF64748B),
        labelStyle: TextStyle(fontSize: 10.sp, fontWeight: FontWeight.w600),
        unselectedLabelStyle: TextStyle(fontSize: 10.sp, fontWeight: FontWeight.w500),
        tabs: const [
          Tab(text: 'الفئات'),
          Tab(text: 'الأسعار'),
          Tab(text: 'الأرباح'),
          Tab(text: 'التفاصيل'),
        ],
      ),
    );
  }

  Widget _buildCategoryChart(StoreProductsController controller) {
    return Obx(() {
      final categoryData = _getCategoryData(controller);
      
      if (categoryData.isEmpty) {
        return _buildEmptyChart('لا توجد فئات متاحة');
      }

      return Padding(
        padding: EdgeInsets.all(20.w),
        child: Column(
          children: [
            Text(
              'توزيع المنتجات حسب الفئات',
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1E293B),
              ),
            ),
            SizedBox(height: 20.h),
            Expanded(
              child: Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: PieChart(
                      PieChartData(
                        sectionsSpace: 2,
                        centerSpaceRadius: 40.r,
                        sections: categoryData.map((data) {
                          return PieChartSectionData(
                            color: data['color'],
                            value: data['value'].toDouble(),
                            title: '${data['value']}',
                            radius: 50.r,
                            titleStyle: TextStyle(
                              fontSize: 12.sp,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          );
                        }).toList(),
                        pieTouchData: PieTouchData(
                          touchCallback: (FlTouchEvent event, pieTouchResponse) {
                            // يمكن إضافة تفاعل هنا
                          },
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 20.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: categoryData.map((data) {
                        return Padding(
                          padding: EdgeInsets.symmetric(vertical: 4.h),
                          child: Row(
                            children: [
                              Container(
                                width: 12.w,
                                height: 12.w,
                                decoration: BoxDecoration(
                                  color: data['color'],
                                  shape: BoxShape.circle,
                                ),
                              ),
                              SizedBox(width: 8.w),
                              Expanded(
                                child: Text(
                                  data['name'],
                                  style: TextStyle(
                                    fontSize: 11.sp,
                                    color: const Color(0xFF64748B),
                                  ),
                                ),
                              ),
                              Text(
                                '${data['value']}',
                                style: TextStyle(
                                  fontSize: 11.sp,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF1E293B),
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildPriceRangeChart(StoreProductsController controller) {
    return Obx(() {
      final priceRangeData = _getPriceRangeData(controller);
      
      if (priceRangeData.isEmpty) {
        return _buildEmptyChart('لا توجد بيانات أسعار');
      }

      return Padding(
        padding: EdgeInsets.all(20.w),
        child: Column(
          children: [
            Text(
              'توزيع المنتجات حسب نطاقات الأسعار',
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1E293B),
              ),
            ),
            SizedBox(height: 20.h),
            Expanded(
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: priceRangeData.map((e) => e['count'] as double).reduce((a, b) => a > b ? a : b) + 2,
                  barTouchData: BarTouchData(
                    touchTooltipData: BarTouchTooltipData(
                      tooltipBorder: BorderSide(color: const Color(0xFF6366F1), width: 1),
                      tooltipPadding: EdgeInsets.all(8.w),
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        return BarTooltipItem(
                          '${priceRangeData[group.x.toInt()]['range']}\n${rod.toY.round()} منتج',
                          TextStyle(
                            color: Colors.white,
                            fontSize: 10.sp,
                            fontWeight: FontWeight.w500,
                          ),
                        );
                      },
                    ),
                  ),
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (double value, TitleMeta meta) {
                          if (value.toInt() < priceRangeData.length) {
                            return Padding(
                              padding: EdgeInsets.only(top: 8.h),
                              child: Text(
                                priceRangeData[value.toInt()]['range'],
                                style: TextStyle(
                                  fontSize: 9.sp,
                                  color: const Color(0xFF64748B),
                                ),
                              ),
                            );
                          }
                          return const Text('');
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 30.w,
                        getTitlesWidget: (double value, TitleMeta meta) {
                          return Text(
                            value.toInt().toString(),
                            style: TextStyle(
                              fontSize: 9.sp,
                              color: const Color(0xFF64748B),
                            ),
                          );
                        },
                      ),
                    ),
                    topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: false),
                  barGroups: priceRangeData.asMap().entries.map((entry) {
                    return BarChartGroupData(
                      x: entry.key,
                      barRods: [
                        BarChartRodData(
                          toY: (entry.value['count'] as num).toDouble(),
                          gradient: LinearGradient(
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                            colors: [
                              const Color(0xFF6366F1),
                              const Color(0xFF8B5CF6),
                            ],
                          ),
                          width: 20.w,
                          borderRadius: BorderRadius.circular(4.r),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildProfitAnalysis(StoreProductsController controller) {
    return Obx(() {
      final profitData = _getProfitAnalysisData(controller);
      
      return Padding(
        padding: EdgeInsets.all(20.w),
        child: Column(
          children: [
            Text(
              'تحليل الأرباح المتوقعة',
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1E293B),
              ),
            ),
            SizedBox(height: 20.h),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    // مؤشرات الربح الرئيسية
                    Row(
                      children: [
                        Expanded(
                          child: _buildProfitIndicator(
                            'إجمالي التكلفة',
                            '${_formatPrice(profitData['totalCost'])} د.ع',
                            const Color(0xFFEF4444),
                            Icons.trending_down,
                          ),
                        ),
                        SizedBox(width: 10.w),
                        Expanded(
                          child: _buildProfitIndicator(
                            'إجمالي القيمة',
                            '${_formatPrice(profitData['totalValue'])} د.ع',
                            const Color(0xFF059669),
                            Icons.trending_up,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 15.h),
                    Row(
                      children: [
                        Expanded(
                          child: _buildProfitIndicator(
                            'الربح المتوقع',
                            '${_formatPrice(profitData['expectedProfit'])} د.ع',
                            const Color(0xFF6366F1),
                            Icons.monetization_on,
                          ),
                        ),
                        SizedBox(width: 10.w),
                        Expanded(
                          child: _buildProfitIndicator(
                            'هامش الربح',
                            _formatPercentage(profitData['profitMargin']),
                            const Color(0xFFEC4899),
                            Icons.percent,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 20.h),
                    // رسم بياني دائري للتكلفة مقابل الربح
                    SizedBox(
                      height: 200.h,
                      child: PieChart(
                        PieChartData(
                          sectionsSpace: 3,
                          centerSpaceRadius: 50.r,
                          sections: [
                            PieChartSectionData(
                              color: const Color(0xFFEF4444),
                              value: (profitData['totalCost'] as num).toDouble(),
                              title: 'التكلفة\n${_formatPercentage(profitData['costPercentage'])}',
                              radius: 60.r,
                              titleStyle: TextStyle(
                                fontSize: 11.sp,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            PieChartSectionData(
                              color: const Color(0xFF059669),
                              value: (profitData['expectedProfit'] as num).toDouble(),
                              title: 'الربح\n${_formatPercentage(profitData['profitPercentage'])}',
                              radius: 60.r,
                              titleStyle: TextStyle(
                                fontSize: 11.sp,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildDetailedStats(StoreProductsController controller) {
    return Obx(() {
      return Padding(
        padding: EdgeInsets.all(20.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'إحصائيات تفصيلية',
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1E293B),
              ),
            ),
            SizedBox(height: 20.h),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    _buildDetailedStatItem(
                      'إجمالي المنتجات',
                      controller.allProducts.length.toString(),
                      Icons.inventory_2,
                      const Color(0xFF6366F1),
                    ),
                    _buildDetailedStatItem(
                      'الفئات المتاحة',
                      (controller.categories.length - 1).toString(),
                      Icons.category,
                      const Color(0xFF8B5CF6),
                    ),
                    _buildDetailedStatItem(
                      'المنتجات المفضلة',
                      controller.favoritesCount.toString(),
                      Icons.favorite,
                      const Color(0xFFEC4899),
                    ),
                    _buildDetailedStatItem(
                      'المنتجات في السلة',
                      controller.totalProductsInCart.toString(),
                      Icons.shopping_cart,
                      const Color(0xFFF59E0B),
                    ),
                    _buildDetailedStatItem(
                      'أعلى سعر',
                      '${_formatPrice(controller.maxPrice.value)} د.ع',
                      Icons.arrow_upward,
                      const Color(0xFF059669),
                    ),
                    _buildDetailedStatItem(
                      'أقل سعر',
                      '${_formatPrice(controller.minPrice.value)} د.ع',
                      Icons.arrow_downward,
                      const Color(0xFFEF4444),
                    ),
                    _buildDetailedStatItem(
                      'متوسط السعر',
                      '${_formatPrice(controller.averagePrice)} د.ع',
                      Icons.trending_flat,
                      const Color(0xFF64748B),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildDetailedStatItem(String title, String value, IconData icon, Color color) {
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40.w,
            height: 40.w,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(10.r),
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: 20.sp,
            ),
          ),
          SizedBox(width: 16.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: const Color(0xFF64748B),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 16.sp,
                    color: const Color(0xFF1E293B),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfitIndicator(String title, String value, Color color, IconData icon) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withOpacity(0.1),
            color.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: color,
            size: 24.sp,
          ),
          SizedBox(height: 8.h),
          Text(
            title,
            style: TextStyle(
              fontSize: 10.sp,
              color: const Color(0xFF64748B),
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 4.h),
          Text(
            value,
            style: TextStyle(
              fontSize: 14.sp,
              color: color,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyChart(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.analytics_outlined,
            size: 60.sp,
            color: const Color(0xFFCBD5E1),
          ),
          SizedBox(height: 16.h),
          Text(
            message,
            style: TextStyle(
              fontSize: 14.sp,
              color: const Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }

  // دوال مساعدة لحساب البيانات
  double _calculateTotalValue(StoreProductsController controller) {
    return controller.allProducts.fold(0.0, (sum, product) {
      final price = double.tryParse(product['priceOfItem']?.toString() ?? '0') ?? 0.0;
      return sum + price;
    });
  }

  double _calculateTotalCost(StoreProductsController controller) {
    return controller.allProducts.fold(0.0, (sum, product) {
      final cost = double.tryParse(product['costPrice']?.toString() ?? '0') ?? 0.0;
      return sum + cost;
    });
  }

  List<Map<String, dynamic>> _getCategoryData(StoreProductsController controller) {
    final categoryCount = <String, int>{};
    
    for (var product in controller.allProducts) {
      final category = product['selectedMainCategoryNameAr']?.toString() ?? 'غير محدد';
      categoryCount[category] = (categoryCount[category] ?? 0) + 1;
    }

    final colors = [
      const Color(0xFF6366F1),
      const Color(0xFF8B5CF6),
      const Color(0xFFEC4899),
      const Color(0xFFF59E0B),
      const Color(0xFF059669),
      const Color(0xFFEF4444),
    ];

    return categoryCount.entries.map((entry) {
      final index = categoryCount.keys.toList().indexOf(entry.key);
      return {
        'name': entry.key,
        'value': entry.value,
        'color': colors[index % colors.length],
      };
    }).toList();
  }

  List<Map<String, dynamic>> _getPriceRangeData(StoreProductsController controller) {
    final ranges = [
      {'min': 0.0, 'max': 1000.0, 'range': '0-1K'},
      {'min': 1000.0, 'max': 5000.0, 'range': '1K-5K'},
      {'min': 5000.0, 'max': 10000.0, 'range': '5K-10K'},
      {'min': 10000.0, 'max': 25000.0, 'range': '10K-25K'},
      {'min': 25000.0, 'max': double.infinity, 'range': '25K+'},
    ];

    return ranges.map((range) {
      final count = controller.allProducts.where((product) {
        final price = double.tryParse(product['priceOfItem']?.toString() ?? '0') ?? 0.0;
        return price >= (range['min'] as double) && price < (range['max'] as double);
      }).length;

      return {
        'range': range['range'],
        'count': count.toDouble(),
      };
    }).toList();
  }

  Map<String, dynamic> _getProfitAnalysisData(StoreProductsController controller) {
    final totalValue = _calculateTotalValue(controller);
    final totalCost = _calculateTotalCost(controller);
    final expectedProfit = totalValue - totalCost;
    final profitMargin = totalValue > 0 ? (expectedProfit / totalValue) * 100 : 0.0;
    final costPercentage = totalValue > 0 ? (totalCost / totalValue) * 100 : 0.0;
    final profitPercentage = 100 - costPercentage;

    return {
      'totalValue': totalValue,
      'totalCost': totalCost,
      'expectedProfit': expectedProfit,
      'profitMargin': profitMargin,
      'costPercentage': costPercentage,
      'profitPercentage': profitPercentage,
    };
  }

  void _shareStatistics() {
    // يمكن إضافة وظيفة مشاركة الإحصائيات هنا
    Get.snackbar(
      'مشاركة الإحصائيات',
      'سيتم إضافة هذه الميزة قريباً',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: const Color(0xFF6366F1),
      colorText: Colors.white,
    );
  }
}