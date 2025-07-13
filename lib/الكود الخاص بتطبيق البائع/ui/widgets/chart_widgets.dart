import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:fl_chart/fl_chart.dart';

class ChartWidgets {
  


  // دالة تنسيق النسبة المئوية
  static String _formatPercentage(double percentage) {
    return '${percentage.toStringAsFixed(1)}%';
  }

  /// رسم بياني دائري محسن للفئات
  static Widget buildEnhancedPieChart({
    required List<Map<String, dynamic>> data,
    required String title,
    double radius = 60.0,
    double centerSpaceRadius = 40.0,
    bool showLegend = true,
  }) {
    if (data.isEmpty) {
      return _buildEmptyChart('لا توجد بيانات متاحة');
    }

    return Column(
      children: [
        Text(
          title,
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
                flex: showLegend ? 2 : 1,
                child: PieChart(
                  PieChartData(
                    sectionsSpace: 3,
                    centerSpaceRadius: centerSpaceRadius.r,
                    sections: data.map((item) {
                      return PieChartSectionData(
                        color: item['color'],
                        value: item['value'].toDouble(),
                        title: '${item['value']}',
                        radius: radius.r,
                        titleStyle: TextStyle(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        badgeWidget: _buildBadge(item['value'].toString()),
                        badgePositionPercentageOffset: 1.3,
                      );
                    }).toList(),
                    pieTouchData: PieTouchData(
                      touchCallback: (FlTouchEvent event, pieTouchResponse) {
                        // يمكن إضافة تفاعل متقدم هنا
                      },
                      enabled: true,
                    ),
                  ),
                ),
              ),
              if (showLegend) ...[
                SizedBox(width: 20.w),
                Expanded(
                  child: _buildPieChartLegend(data),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  /// رسم بياني عمودي محسن
  static Widget buildEnhancedBarChart({
    required List<Map<String, dynamic>> data,
    required String title,
    String xAxisTitle = '',
    String yAxisTitle = '',
    double maxY = 0,
    List<Color>? gradientColors,
  }) {
    if (data.isEmpty) {
      return _buildEmptyChart('لا توجد بيانات متاحة');
    }

    final colors = gradientColors ?? [
      const Color(0xFF6366F1),
      const Color(0xFF8B5CF6),
    ];

    return Column(
      children: [
        Text(
          title,
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
              maxY: maxY > 0 ? maxY : data.map((e) => e['count'] as double).reduce((a, b) => a > b ? a : b) + 2,
              barTouchData: BarTouchData(
                touchTooltipData: BarTouchTooltipData(
                  tooltipBorder: BorderSide(color: colors.first, width: 1),
                  tooltipPadding: EdgeInsets.all(8.w),
                  getTooltipItem: (group, groupIndex, rod, rodIndex) {
                    return BarTooltipItem(
                      '${data[group.x.toInt()]['range']}\n${rod.toY.round()} منتج',
                      TextStyle(
                        color: Colors.white,
                        fontSize: 10.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    );
                  },
                ),
              ),
              titlesData: FlTitlesData(
                show: true,
                bottomTitles: AxisTitles(
                  axisNameWidget: xAxisTitle.isNotEmpty ? Text(
                    xAxisTitle,
                    style: TextStyle(fontSize: 12.sp, color: const Color(0xFF64748B)),
                  ) : null,
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 30.h,
                    getTitlesWidget: (double value, TitleMeta meta) {
                      if (value.toInt() < data.length) {
                        return Padding(
                          padding: EdgeInsets.only(top: 8.h),
                          child: Text(
                            data[value.toInt()]['range'],
                            style: TextStyle(
                              fontSize: 9.sp,
                              color: const Color(0xFF64748B),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        );
                      }
                      return const Text('');
                    },
                  ),
                ),
                leftTitles: AxisTitles(
                  axisNameWidget: yAxisTitle.isNotEmpty ? Text(
                    yAxisTitle,
                    style: TextStyle(fontSize: 12.sp, color: const Color(0xFF64748B)),
                  ) : null,
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 40.w,
                    getTitlesWidget: (double value, TitleMeta meta) {
                      return Text(
                        value.toInt().toString(),
                        style: TextStyle(
                          fontSize: 9.sp,
                          color: const Color(0xFF64748B),
                          fontWeight: FontWeight.w500,
                        ),
                      );
                    },
                  ),
                ),
                topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              borderData: FlBorderData(
                show: true,
                border: Border(
                  bottom: BorderSide(color: const Color(0xFFE2E8F0), width: 1),
                  left: BorderSide(color: const Color(0xFFE2E8F0), width: 1),
                ),
              ),
              gridData: FlGridData(
                show: true,
                drawHorizontalLine: true,
                drawVerticalLine: false,
                horizontalInterval: 1,
                getDrawingHorizontalLine: (value) => FlLine(
                  color: const Color(0xFFE2E8F0),
                  strokeWidth: 0.5,
                ),
              ),
              barGroups: data.asMap().entries.map((entry) {
                return BarChartGroupData(
                  x: entry.key,
                  barRods: [
                    BarChartRodData(
                      toY: (entry.value['count'] as num).toDouble(),
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: colors,
                      ),
                      width: 25.w,
                      borderRadius: BorderRadius.circular(6.r),
                      backDrawRodData: BackgroundBarChartRodData(
                        show: true,
                        toY: maxY > 0 ? maxY : data.map((e) => e['count'] as double).reduce((a, b) => a > b ? a : b) + 2,
                        color: const Color(0xFFF1F5F9),
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }

  /// رسم بياني خطي محسن للاتجاهات
  static Widget buildEnhancedLineChart({
    required List<Map<String, dynamic>> data,
    required String title,
    String xAxisTitle = '',
    String yAxisTitle = '',
    List<Color>? gradientColors,
  }) {
    if (data.isEmpty) {
      return _buildEmptyChart('لا توجد بيانات متاحة');
    }

    final colors = gradientColors ?? [
      const Color(0xFF6366F1),
      const Color(0xFF8B5CF6),
    ];

    return Column(
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF1E293B),
          ),
        ),
        SizedBox(height: 20.h),
        Expanded(
          child: LineChart(
            LineChartData(
              lineTouchData: LineTouchData(
                touchTooltipData: LineTouchTooltipData(
                  tooltipBorder: BorderSide(color: colors.first, width: 1),
                  getTooltipItems: (List<LineBarSpot> touchedBarSpots) {
                    return touchedBarSpots.map((barSpot) {
                      return LineTooltipItem(
                        '${data[barSpot.x.toInt()]['label']}\n${barSpot.y.toInt()}',
                        TextStyle(
                          color: Colors.white,
                          fontSize: 10.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      );
                    }).toList();
                  },
                ),
              ),
              gridData: FlGridData(
                show: true,
                drawHorizontalLine: true,
                drawVerticalLine: true,
                horizontalInterval: 1,
                verticalInterval: 1,
                getDrawingHorizontalLine: (value) => FlLine(
                  color: const Color(0xFFE2E8F0),
                  strokeWidth: 0.5,
                ),
                getDrawingVerticalLine: (value) => FlLine(
                  color: const Color(0xFFE2E8F0),
                  strokeWidth: 0.5,
                ),
              ),
              titlesData: FlTitlesData(
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 30.h,
                    getTitlesWidget: (double value, TitleMeta meta) {
                      if (value.toInt() < data.length) {
                        return Padding(
                          padding: EdgeInsets.only(top: 8.h),
                          child: Text(
                            data[value.toInt()]['label'],
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
                    reservedSize: 40.w,
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
              borderData: FlBorderData(
                show: true,
                border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
              ),
              lineBarsData: [
                LineChartBarData(
                  spots: data.asMap().entries.map((entry) {
                    return FlSpot(entry.key.toDouble(), entry.value['value'].toDouble());
                  }).toList(),
                  isCurved: true,
                  gradient: LinearGradient(colors: colors),
                  barWidth: 3.w,
                  isStrokeCapRound: true,
                  dotData: FlDotData(
                    show: true,
                    getDotPainter: (spot, percent, barData, index) {
                      return FlDotCirclePainter(
                        radius: 4.r,
                        color: Colors.white,
                        strokeWidth: 2.w,
                        strokeColor: colors.first,
                      );
                    },
                  ),
                  belowBarData: BarAreaData(
                    show: true,
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: colors.map((color) => color.withOpacity(0.1)).toList(),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// بناء legend للرسم البياني الدائري
  static Widget _buildPieChartLegend(List<Map<String, dynamic>> data) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: data.map((item) {
        final percentage = (item['value'] / data.fold(0, (sum, item) => sum + (item['value'] as int))) * 100;
        return Padding(
          padding: EdgeInsets.symmetric(vertical: 4.h),
          child: Row(
            children: [
              Container(
                width: 16.w,
                height: 16.w,
                decoration: BoxDecoration(
                  color: item['color'],
                  borderRadius: BorderRadius.circular(4.r),
                  boxShadow: [
                    BoxShadow(
                      color: item['color'].withOpacity(0.3),
                      blurRadius: 4.r,
                      offset: Offset(0, 2.h),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item['name'],
                      style: TextStyle(
                        fontSize: 11.sp,
                        color: const Color(0xFF64748B),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      '${item['value']} (${_formatPercentage(percentage)})',
                      style: TextStyle(
                        fontSize: 10.sp,
                        color: const Color(0xFF1E293B),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  /// شارة للرسم الدائري
  static Widget _buildBadge(String text) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4.r,
            offset: Offset(0, 2.h),
          ),
        ],
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 8.sp,
          fontWeight: FontWeight.bold,
          color: const Color(0xFF1E293B),
        ),
      ),
    );
  }

  /// عرض رسالة عند عدم وجود بيانات
  static Widget _buildEmptyChart(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(20.w),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.analytics_outlined,
              size: 40.sp,
              color: const Color(0xFFCBD5E1),
            ),
          ),
          SizedBox(height: 16.h),
          Text(
            message,
            style: TextStyle(
              fontSize: 14.sp,
              color: const Color(0xFF64748B),
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// بناء مؤشر إحصائي
  static Widget buildStatIndicator({
    required String title,
    required String value,
    required Color color,
    required IconData icon,
    String? subtitle,
    double? trend,
  }) {
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
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8.w),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Icon(
                  icon,
                  color: Colors.white,
                  size: 18.sp,
                ),
              ),
              Spacer(),
              if (trend != null)
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                  decoration: BoxDecoration(
                    color: trend >= 0 ? Colors.green : Colors.red,
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        trend >= 0 ? Icons.trending_up : Icons.trending_down,
                        size: 12.sp,
                        color: Colors.white,
                      ),
                      SizedBox(width: 2.w),
                      Text(
                        '${trend.abs().toStringAsFixed(1)}%',
                        style: TextStyle(
                          fontSize: 8.sp,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          SizedBox(height: 12.h),
          Text(
            title,
            style: TextStyle(
              fontSize: 12.sp,
              color: const Color(0xFF64748B),
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            value,
            style: TextStyle(
              fontSize: 20.sp,
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (subtitle != null) ...[
            SizedBox(height: 4.h),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 10.sp,
                color: const Color(0xFF64748B),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
    );
  }
}