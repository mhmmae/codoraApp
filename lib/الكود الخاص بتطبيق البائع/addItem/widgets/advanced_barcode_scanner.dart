import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'dart:async';
import 'dart:math' as math;
import 'dart:io';
import 'package:intl/intl.dart';

class AdvancedBarcodeScanner extends StatefulWidget {
  final int requiredQuantity;
  final Function(List<String>) onBarcodesScanned;
  final Function(int)? onQuantityUpdated; // callback لتحديث الكمية
  final List<String> initialBarcodes;

  const AdvancedBarcodeScanner({
    super.key,
    required this.requiredQuantity,
    required this.onBarcodesScanned,
    this.onQuantityUpdated,
    this.initialBarcodes = const [],
  });

  @override
  State<AdvancedBarcodeScanner> createState() => _AdvancedBarcodeScannerState();
}

class _AdvancedBarcodeScannerState extends State<AdvancedBarcodeScanner> 
    with TickerProviderStateMixin {
  late MobileScannerController controller;
  
  // Animation Controllers
  late AnimationController _slideController;
  late AnimationController _fadeController;
  late AnimationController _pulseController;
  late AnimationController _successController;
  late AnimationController _scanLineController;
  late AnimationController _progressController;
  late AnimationController _counterController;
  
  // Animations
  late Animation<double> _fadeAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<double> _scanLineAnimation;
  late Animation<double> _progressAnimation;
  
  // Data
  List<String> scannedBarcodes = [];
  Set<String> _scannedSet = {};
  final Map<String, DateTime> _scannedHistory = {}; // تاريخ كل باركود
  bool isScanning = true;
  bool _isProcessingBarcode = false;
  final bool _soundEnabled = true; // تحكم في تشغيل الأصوات
  bool _isDuplicateDetected = false; // لتتبع حالة الباركود المكرر
  Timer? _duplicateResetTimer; // لإعادة تعيين حالة المكرر
  int _currentRequiredQuantity = 0; // الكمية الحالية المطلوبة
  
  // للمنصات المكتبية (Windows/Mac)
  bool _isDesktopPlatform = false;
  late TextEditingController _barcodeInputController;
  late FocusNode _barcodeInputFocus;
  Timer? _inputTimer;
  String _currentInput = '';
  bool _isProcessingExternalInput = false;
  
  // Timing
  DateTime? _sessionStartTime;
  Timer? _cooldownTimer;
  int scanCount = 0;

  @override
  void initState() {
    super.initState();
    _checkPlatform();
    _initializeControllers();
    _initializeAnimations();
    _setupInitialData();
    _startEntrySequence();
  }
  
  void _checkPlatform() {
    _isDesktopPlatform = Platform.isWindows || Platform.isMacOS;
    if (_isDesktopPlatform) {
      _barcodeInputController = TextEditingController();
      _barcodeInputFocus = FocusNode();
    }
  }
  
  void _initializeControllers() {
    controller = MobileScannerController();
    
    _slideController = AnimationController(
      duration: Duration(milliseconds: 1200),
      vsync: this,
    );
    _fadeController = AnimationController(
      duration: Duration(milliseconds: 800),
      vsync: this,
    );
    _pulseController = AnimationController(
      duration: Duration(milliseconds: 2000),
      vsync: this,
    );
    _successController = AnimationController(
      duration: Duration(milliseconds: 600),
      vsync: this,
    );
    _scanLineController = AnimationController(
      duration: Duration(milliseconds: 2500),
      vsync: this,
    );
    _progressController = AnimationController(
      duration: Duration(milliseconds: 800),
      vsync: this,
    );
    _counterController = AnimationController(
      duration: Duration(milliseconds: 300),
      vsync: this,
    );
  }
  
  void _initializeAnimations() {
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _scanLineAnimation = Tween<double>(begin: -1.0, end: 1.0).animate(
      CurvedAnimation(parent: _scanLineController, curve: Curves.linear),
    );
    _progressAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _progressController, curve: Curves.easeOut),
    );
  }
  
  void _setupInitialData() {
    scannedBarcodes = List.from(widget.initialBarcodes);
    _scannedSet = Set.from(widget.initialBarcodes);
    _currentRequiredQuantity = widget.requiredQuantity; // تحديد الكمية الحالية
    _sessionStartTime = DateTime.now();
    scanCount = scannedBarcodes.length;
    
    // Initialize history for existing barcodes
    final now = DateTime.now();
    for (String barcode in widget.initialBarcodes) {
      _scannedHistory[barcode] = now;
    }
    
    // Update progress based on initial barcodes
    if (_currentRequiredQuantity > 0) {
      _progressController.animateTo(scannedBarcodes.length / _currentRequiredQuantity);
    }
  }
  
  void _startEntrySequence() async {
    await Future.delayed(Duration(milliseconds: 100));
    _slideController.forward();
    await Future.delayed(Duration(milliseconds: 200));
    _fadeController.forward();
    await Future.delayed(Duration(milliseconds: 300));
    _pulseController.repeat(reverse: true);
    if (!_isDesktopPlatform) {
      _scanLineController.repeat();
    }
    
    // التركيز على حقل الإدخال للمنصات المكتبية
    if (_isDesktopPlatform) {
      await Future.delayed(Duration(milliseconds: 500));
      _barcodeInputFocus.requestFocus();
    }
  }
  
  @override
  void dispose() {
    controller.dispose();
    _slideController.dispose();
    _fadeController.dispose();
    _pulseController.dispose();
    _successController.dispose();
    _scanLineController.dispose();
    _progressController.dispose();
    _counterController.dispose();
    _cooldownTimer?.cancel();
    _duplicateResetTimer?.cancel();
    _inputTimer?.cancel();
    
    if (_isDesktopPlatform) {
      _barcodeInputController.dispose();
      _barcodeInputFocus.dispose();
    }
    
    super.dispose();
  }

  void _onBarcodeDetected(BarcodeCapture capture) {
    if (!isScanning || _isProcessingBarcode) return;
    
    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isEmpty) {
      // لا يوجد باركود، إعادة تعيين حالة المكرر
      _resetDuplicateState();
      return;
    }
    
    final String? code = barcodes.first.rawValue;
    if (code == null || code.isEmpty) {
      _resetDuplicateState();
      return;
    }
    
    // التحقق من الباركود المكرر
    if (_scannedSet.contains(code)) {
      _handleDuplicateBarcode(code);
      return;
    }
    
    // إعادة تعيين حالة المكرر وإضافة الباركود الجديد
    _resetDuplicateState();
    _processBarcodeSuccess(code);
  }
  
  void _processBarcodeSuccess(String code) {
    _isProcessingBarcode = true;
    scanCount++;
    
    final scanTime = DateTime.now();
    
    setState(() {
      scannedBarcodes.add(code);
      _scannedSet.add(code);
      _scannedHistory[code] = scanTime; // حفظ تاريخ المسح
    });
    
    // Trigger animations and effects
    _triggerSuccessEffects();
    _playSuccessSound(); // تشغيل صوت النجاح
    _updateProgress();
    
    // Check if quantity exceeded
    if (scannedBarcodes.length > _currentRequiredQuantity) {
      _handleExcessBarcode(code);
    }
    
    // Cooldown before next scan
    _startScanningCooldown();
  }
  
  // معالجة الباركود المكرر
  void _handleDuplicateBarcode(String code) {
    if (!_isDuplicateDetected) {
      setState(() {
        _isDuplicateDetected = true;
      });
      _playWarningSound(); // تشغيل صوت التحذير
      HapticFeedback.lightImpact(); // اهتزاز خفيف
    }
    
    // إعادة تعيين المؤقت - سيتم إعادة تعيين الحالة بعد ثانية واحدة من آخر كشف
    _duplicateResetTimer?.cancel();
    _duplicateResetTimer = Timer(Duration(milliseconds: 800), () {
      _resetDuplicateState();
    });
  }
  
  // إعادة تعيين حالة الباركود المكرر
  void _resetDuplicateState() {
    if (_isDuplicateDetected) {
      setState(() {
        _isDuplicateDetected = false;
      });
    }
    _duplicateResetTimer?.cancel();
  }
  
  // معالجة الإدخال من قارئ الباركود الخارجي
  void _handleExternalBarcodeInput(String value) {
    if (!isScanning || _isProcessingBarcode) return;
    
    _currentInput = value;
    
    // إعادة تعيين مؤقت الإدخال
    _inputTimer?.cancel();
    
    // تفعيل مؤشر المعالجة
    setState(() {
      _isProcessingExternalInput = true;
    });
    
    _inputTimer = Timer(Duration(milliseconds: 150), () {
      if (_currentInput.isNotEmpty && _currentInput.length >= 3) {
        _processExternalBarcode(_currentInput.trim());
        _barcodeInputController.clear();
        _currentInput = '';
      }
      
      setState(() {
        _isProcessingExternalInput = false;
      });
    });
  }
  
  // معالجة الباركود من المصدر الخارجي
  void _processExternalBarcode(String code) {
    if (code.isEmpty) return;
    
    // التحقق من الباركود المكرر
    if (_scannedSet.contains(code)) {
      _handleDuplicateBarcode(code);
      return;
    }
    
    // إعادة تعيين حالة المكرر وإضافة الباركود الجديد
    _resetDuplicateState();
    _processBarcodeSuccess(code);
    
    // إعادة التركيز على حقل الإدخال للسماح بمسح آخر
    if (_isDesktopPlatform) {
      Future.delayed(Duration(milliseconds: 300), () {
        _barcodeInputFocus.requestFocus();
      });
    }
  }
  
  void _triggerSuccessEffects() {
    // Haptic feedback
    HapticFeedback.mediumImpact();
    
    // Success animation
    _successController.forward().then((_) {
      _successController.reverse();
    });
    
    // Counter animation
    _counterController.forward().then((_) {
      _counterController.reverse();
    });
  }
  
  // تشغيل صوت النجاح
  void _playSuccessSound() {
    if (_soundEnabled) {
      // تشغيل صوت نظام iOS/Android الافتراضي
      SystemSound.play(SystemSoundType.click);
      
      // يمكن إضافة صوت مخصص هنا لاحقاً
      // AudioPlayer().play(AssetSource('sounds/success_beep.mp3'));
    }
  }
  
  // تشغيل صوت التحذير
  void _playWarningSound() {
    if (_soundEnabled) {
      SystemSound.play(SystemSoundType.alert);
    }
  }
  
  // تنسيق وقت المسح
  String _formatScanTime(DateTime scanTime) {
    final now = DateTime.now();
    final difference = now.difference(scanTime);
    
    if (difference.inMinutes < 1) {
      return 'منذ ${difference.inSeconds} ثانية';
    } else if (difference.inHours < 1) {
      return 'منذ ${difference.inMinutes} دقيقة';
    } else if (difference.inDays < 1) {
      return 'منذ ${difference.inHours} ساعة';
    } else {
      return DateFormat('dd/MM/yyyy HH:mm').format(scanTime);
    }
  }
  
  // حساب متوسط الوقت بين المسحات
  String _getAverageScanTime() {
    if (_scannedHistory.length < 2) return 'غير متوفر';
    
    final times = _scannedHistory.values.toList()..sort();
    double totalSeconds = 0;
    
    for (int i = 1; i < times.length; i++) {
      totalSeconds += times[i].difference(times[i-1]).inSeconds;
    }
    
    final average = totalSeconds / (times.length - 1);
    return '${average.toStringAsFixed(1)} ثانية';
  }
  
  // الحصول على إجمالي وقت الجلسة
  String _getSessionDuration() {
    if (_sessionStartTime == null) return 'غير متوفر';
    
    final duration = DateTime.now().difference(_sessionStartTime!);
    if (duration.inMinutes < 1) {
      return '${duration.inSeconds} ثانية';
    } else if (duration.inHours < 1) {
      return '${duration.inMinutes} دقيقة';
    } else {
      return '${duration.inHours} ساعة و ${duration.inMinutes % 60} دقيقة';
    }
  }
  
  // عرض نافذة الإحصائيات المتقدمة
  void _showStatistics() {
    final firstScanTime = _scannedHistory.isNotEmpty 
        ? _scannedHistory.values.reduce((a, b) => a.isBefore(b) ? a : b)
        : null;
    final lastScanTime = _scannedHistory.isNotEmpty 
        ? _scannedHistory.values.reduce((a, b) => a.isAfter(b) ? a : b)
        : null;
    
    Get.defaultDialog(
      title: "📊 إحصائيات المسح",
      titleStyle: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
                         _buildStatRow("📈 إجمالي المسحات", "${scannedBarcodes.length}", Icons.qr_code),
             _buildStatRow("🎯 النسبة المكتملة", "${_currentRequiredQuantity > 0 ? ((scannedBarcodes.length / _currentRequiredQuantity) * 100).toInt() : 0}%", Icons.show_chart),
             _buildStatRow("⏱️ مدة الجلسة", _getSessionDuration(), Icons.timer),
             _buildStatRow("⚡ متوسط الوقت", _getAverageScanTime(), Icons.speed),
             if (firstScanTime != null)
               _buildStatRow("🏁 أول مسح", DateFormat('HH:mm:ss').format(firstScanTime), Icons.play_arrow),
             if (lastScanTime != null)
               _buildStatRow("🏆 آخر مسح", DateFormat('HH:mm:ss').format(lastScanTime), Icons.stop),
            _buildStatRow("🔊 حالة الصوت", _soundEnabled ? "مفعل" : "معطل", _soundEnabled ? Icons.volume_up : Icons.volume_off),
            _buildStatRow("📱 حالة المسح", isScanning ? "نشط" : "متوقف", isScanning ? Icons.play_circle : Icons.pause_circle),
          ],
        ),
      ),
      confirm: ElevatedButton.icon(
        onPressed: () => Get.back(),
        icon: Icon(Icons.close),
        label: Text("إغلاق"),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.deepPurple,
          foregroundColor: Colors.white,
        ),
      ),
    );
  }
  
  Widget _buildStatRow(String label, String value, IconData icon) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 4),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.deepPurple, size: 20),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade700,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.deepPurple,
            ),
          ),
        ],
      ),
    );
  }
  
  // عرض تفاصيل باركود محدد
  void _showBarcodeDetails(String barcode, int index) {
    final scanTime = _scannedHistory[barcode];
    final sessionTime = _sessionStartTime;
    
    String timeSinceStart = 'غير متوفر';
    if (scanTime != null && sessionTime != null) {
      final difference = scanTime.difference(sessionTime);
      if (difference.inMinutes < 1) {
        timeSinceStart = '${difference.inSeconds} ثانية من بداية الجلسة';
      } else {
        timeSinceStart = '${difference.inMinutes} دقيقة من بداية الجلسة';
      }
    }
    
    Get.defaultDialog(
      title: "🔍 تفاصيل الباركود",
      titleStyle: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // الباركود نفسه
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.deepPurple.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.deepPurple.shade200),
              ),
              child: Column(
                children: [
                  Text(
                    "الباركود",
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.deepPurple.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: 8),
                  SelectableText(
                    barcode,
                    style: TextStyle(
                      fontSize: 18,
                      fontFamily: 'monospace',
                      fontWeight: FontWeight.bold,
                      color: Colors.deepPurple,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 16),
            
            // التفاصيل
            _buildDetailRow("📍 الترتيب", "رقم ${index + 1} من ${scannedBarcodes.length}"),
            if (scanTime != null) ...[
              _buildDetailRow("📅 تاريخ المسح", DateFormat('dd/MM/yyyy').format(scanTime)),
              _buildDetailRow("🕐 وقت المسح", DateFormat('HH:mm:ss').format(scanTime)),
              _buildDetailRow("⏰ منذ", _formatScanTime(scanTime)),
              _buildDetailRow("🚀 وقت المسح", timeSinceStart),
            ],
          ],
        ),
      ),
      actions: [
        TextButton.icon(
          onPressed: () {
            Clipboard.setData(ClipboardData(text: barcode));
            Get.back();
            Get.snackbar(
              '📋 تم النسخ',
              'تم نسخ الباركود إلى الحافظة',
              backgroundColor: Colors.green.shade600,
              colorText: Colors.white,
              duration: Duration(seconds: 1),
            );
          },
          icon: Icon(Icons.copy),
          label: Text("نسخ"),
        ),
        TextButton.icon(
          onPressed: () => Get.back(),
          icon: Icon(Icons.close),
          label: Text("إغلاق"),
        ),
      ],
    );
  }
  
  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  void _updateProgress() {
    if (_currentRequiredQuantity > 0) {
      final progress = math.min(scannedBarcodes.length / _currentRequiredQuantity, 1.0);
      _progressController.animateTo(progress);
    }
  }
  

  
  void _handleExcessBarcode(String code) {
    Get.defaultDialog(
      title: "🎯 باركود إضافي",
      titleStyle: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
      middleText: "تم مسح $_currentRequiredQuantity باركود كما هو مطلوب.\nهل تريد إضافة هذا الباركود الإضافي؟\n\nسيتم تحديث كمية المنتج لتصبح ${scannedBarcodes.length}",
      textConfirm: "نعم، أضف وحدث الكمية",
      textCancel: "لا، احذف",
      confirmTextColor: Colors.white,
      buttonColor: Colors.blue,
      cancelTextColor: Colors.red,
      onConfirm: () {
        // تحديث الكمية الحالية لتصبح مساوية لعدد الباركودات
        _updateCurrentQuantity(scannedBarcodes.length);
        Get.back();
        
        // إشعار بالتحديث
        Get.snackbar(
          '✨ تم تحديث الكمية',
          'الكمية الجديدة: ${scannedBarcodes.length} قطعة',
          backgroundColor: Colors.blue.shade600,
          colorText: Colors.white,
          icon: Icon(Icons.update, color: Colors.white),
          duration: Duration(seconds: 2),
        );
      },
      onCancel: () {
        setState(() {
          scannedBarcodes.removeLast();
          _scannedSet.remove(code);
          _scannedHistory.remove(code);
        });
        _updateProgress();
        Get.back();
      },
    );
  }
  
  // تحديث الكمية الحالية
  void _updateCurrentQuantity(int newQuantity) {
    setState(() {
      _currentRequiredQuantity = newQuantity;
    });
    
    // استدعاء callback لتحديث الكمية في الصفحات الأخرى
    if (widget.onQuantityUpdated != null) {
      widget.onQuantityUpdated!(newQuantity);
    }
    
    // تحديث شريط التقدم
    _updateProgress();
  }
  
  void _startScanningCooldown() {
    setState(() {
      isScanning = false;
    });
    
    _cooldownTimer?.cancel();
    _cooldownTimer = Timer(Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() {
          isScanning = true;
          _isProcessingBarcode = false;
        });
      }
    });
  }
  
  void _removeBarcode(int index) {
    final removedCode = scannedBarcodes[index];
    setState(() {
      scannedBarcodes.removeAt(index);
      _scannedSet.remove(removedCode);
      _scannedHistory.remove(removedCode); // إزالة من التاريخ أيضاً
    });
    _updateProgress();
    
    HapticFeedback.selectionClick();
    Get.snackbar(
      '🗑️ تم الحذف',
      'تم حذف الباركود',
      backgroundColor: Colors.red.shade600,
      colorText: Colors.white,
      duration: Duration(seconds: 1),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: SafeArea(
        child: Column(
          children: [
            _buildStatsHeader(),
            _buildScannerSection(),
            _buildBarcodeList(),
            _buildBottomActions(),
          ],
        ),
      ),
    );
  }
  

  
    Widget _buildStatsHeader() {
    return AnimatedBuilder(
      animation: _fadeAnimation,
      builder: (context, child) {
        return Opacity(
          opacity: _fadeAnimation.value,
          child: Container(
            margin: EdgeInsets.all(8),
            padding: EdgeInsets.all(10),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blue.shade50, Colors.purple.shade50],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(15),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.15),
                  blurRadius: 6,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              children: [
                // شريط التحكم العلوي
                Row(
                  children: [
                    IconButton(
                      icon: Icon(Icons.arrow_back_ios, color: Colors.deepPurple),
                      onPressed: () => Get.back(),
                    ),
                    Expanded(
                      child: Center(
                        child: Text(
                          _isDesktopPlatform 
                              ? "قارئ الباركود الخارجي 🖥️"
                              : "مسح الباركودات 📱",
                          style: TextStyle(
                            color: Colors.deepPurple,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 48), // للتوازن مع زر الرجوع
                  ],
                ),
                SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildAnimatedStatCard(
                      "🎯 المطلوب",
                      _currentRequiredQuantity.toString(),
                      Colors.blue,
                      Icons.gps_fixed,
                    ),
                    _buildAnimatedStatCard(
                      scannedBarcodes.length >= _currentRequiredQuantity ? "✅ مكتمل" : "✅ تم المسح",
                      scannedBarcodes.length.toString(),
                      scannedBarcodes.length >= _currentRequiredQuantity ? Colors.green : Colors.blue,
                      scannedBarcodes.length >= _currentRequiredQuantity ? Icons.check_circle : Icons.check_circle_outline,
                    ),
                    _buildAnimatedStatCard(
                      "⏳ المتبقي",
                      math.max(0, _currentRequiredQuantity - scannedBarcodes.length).toString(),
                      Colors.orange,
                      Icons.pending,
                    ),
                  ],
                ),
                SizedBox(height: 8),
                _buildProgressBar(),
              ],
            ),
          ),
        );
      },
    );
  }
  
  Widget _buildAnimatedStatCard(String title, String value, Color color, IconData icon) {
    return AnimatedBuilder(
      animation: _counterController,
      builder: (context, child) {
        return Transform.scale(
          scale: 1.0 + (_counterController.value * 0.05),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: color.withOpacity(0.3), width: 1),
            ),
            child: Column(
              children: [
                Icon(icon, color: color, size: 16),
                SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 10,
                    color: color.withOpacity(0.8),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
  
  Widget _buildProgressBar() {
    return AnimatedBuilder(
      animation: _progressAnimation,
      builder: (context, child) {
        // حساب التقدم بناءً على الكمية الحالية
        final progressPercent = _currentRequiredQuantity > 0 
            ? ((_progressAnimation.value) * 100).toInt()
            : 0;
        
        // تحديد لون شريط التقدم
        List<Color> progressColors;
        if (scannedBarcodes.length >= _currentRequiredQuantity) {
          progressColors = [Colors.green, Colors.green.shade700];
        } else if (scannedBarcodes.length >= (_currentRequiredQuantity * 0.5)) {
          progressColors = [Colors.orange, Colors.orange.shade700];
        } else {
          progressColors = [Colors.blue, Colors.purple];
        }
        
        return Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "التقدم",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade700,
                  ),
                ),
                Text(
                  "$progressPercent% (${scannedBarcodes.length}/$_currentRequiredQuantity)",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: scannedBarcodes.length >= _currentRequiredQuantity 
                        ? Colors.green 
                        : Colors.deepPurple,
                  ),
                ),
              ],
            ),
            SizedBox(height: 8),
            Container(
              height: 8,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                color: Colors.grey.shade300,
              ),
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: _progressAnimation.value,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    gradient: LinearGradient(
                      colors: progressColors,
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
  
    Widget _buildScannerSection() {
    if (_isDesktopPlatform) {
      return _buildDesktopBarcodeInput();
    } else {
      return _buildMobileCameraScanner();
    }
  }
  
  Widget _buildDesktopBarcodeInput() {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _pulseAnimation.value,
          child: Container(
            margin: EdgeInsets.symmetric(horizontal: 16),
            height: 200,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: _isDuplicateDetected ? Colors.orange : 
                       (isScanning ? Colors.blue : Colors.grey),
                width: 3,
              ),
              gradient: LinearGradient(
                colors: [
                  Colors.blue.shade50,
                  Colors.purple.shade50,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.blue.withOpacity(0.2),
                  blurRadius: 15,
                  offset: Offset(0, 8),
                ),
              ],
            ),
            child: Stack(
              children: [
                // رمز قارئ الباركود
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.scanner,
                        size: 48,
                        color: Colors.blue.shade600,
                      ),
                      SizedBox(height: 16),
                      Text(
                        "قارئ الباركود الخارجي",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade700,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        "امسح الباركود باستخدام قارئ الليزر",
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                
                // حقل الإدخال المخفي
                Positioned(
                  bottom: 10,
                  left: 10,
                  right: 10,
                  child: TextField(
                    controller: _barcodeInputController,
                    focusNode: _barcodeInputFocus,
                    onChanged: _handleExternalBarcodeInput,
                    onSubmitted: (value) {
                      if (value.isNotEmpty) {
                        _processExternalBarcode(value.trim());
                        _barcodeInputController.clear();
                      }
                      _barcodeInputFocus.requestFocus();
                    },
                    decoration: InputDecoration(
                      hintText: _isProcessingExternalInput 
                          ? "جاري المعالجة..." 
                          : "انقر هنا ثم امسح الباركود...",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(
                          color: _isProcessingExternalInput 
                              ? Colors.orange 
                              : Colors.grey,
                        ),
                      ),
                      prefixIcon: _isProcessingExternalInput
                          ? SizedBox(
                              width: 20,
                              height: 20,
                              child: Padding(
                                padding: EdgeInsets.all(12.0),
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.orange,
                                  ),
                                ),
                              ),
                            )
                          : Icon(Icons.qr_code_scanner),
                      filled: true,
                      fillColor: _isProcessingExternalInput
                          ? Colors.orange.shade50
                          : Colors.white.withOpacity(0.9),
                    ),
                    autofocus: true,
                  ),
                ),
                
                _buildScanStatus(),
              ],
            ),
          ),
        );
      },
    );
  }
  
  Widget _buildMobileCameraScanner() {
    final screenWidth = MediaQuery.of(context).size.width;
    
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _pulseAnimation.value,
          child: Container(
            margin: EdgeInsets.symmetric(horizontal: 16),
            height: 150,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isScanning ? Colors.green : Colors.grey,
                width: 3,
              ),
              boxShadow: [
                BoxShadow(
                  color: (isScanning ? Colors.green : Colors.grey).withOpacity(0.3),
                  blurRadius: 15,
                  offset: Offset(0, 8),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(17),
              child: Stack(
                children: [
                  MobileScanner(
                    controller: controller,
                    onDetect: _onBarcodeDetected,
                  ),
                  _buildScanOverlay(screenWidth),
                  _buildScanningLine(),
                  _buildScanStatus(),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
  
    Widget _buildScanOverlay(double screenWidth) {
    // تحديد لون الإطار حسب الحالة
    Color borderColor;
    if (!isScanning) {
      borderColor = Colors.grey;
    } else if (_isDuplicateDetected) {
      borderColor = Colors.orange;
    } else {
      borderColor = Colors.red;
    }
    
    return Center(
      child: Container(
        width: screenWidth * 0.6,
        height: 60,
        decoration: BoxDecoration(
          border: Border.all(
            color: borderColor,
            width: 3,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Stack(
          children: [
            // Corner decorations
                         Positioned(
               top: -2,
               left: -2,
               child: Container(
                 width: 15,
                 height: 15,
                 decoration: BoxDecoration(
                   color: borderColor,
                   borderRadius: BorderRadius.only(topLeft: Radius.circular(8)),
                 ),
               ),
             ),
                         Positioned(
               top: -2,
               right: -2,
               child: Container(
                 width: 15,
                 height: 15,
                 decoration: BoxDecoration(
                   color: borderColor,
                   borderRadius: BorderRadius.only(topRight: Radius.circular(8)),
                 ),
               ),
             ),
                         Positioned(
               bottom: -2,
               left: -2,
               child: Container(
                 width: 15,
                 height: 15,
                 decoration: BoxDecoration(
                   color: borderColor,
                   borderRadius: BorderRadius.only(bottomLeft: Radius.circular(8)),
                 ),
               ),
             ),
                         Positioned(
               bottom: -2,
               right: -2,
               child: Container(
                 width: 15,
                 height: 15,
                 decoration: BoxDecoration(
                   color: borderColor,
                   borderRadius: BorderRadius.only(bottomRight: Radius.circular(8)),
                 ),
               ),
             ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildScanningLine() {
    if (!isScanning) return SizedBox.shrink();
    
    return AnimatedBuilder(
      animation: _scanLineAnimation,
      builder: (context, child) {
                 return Positioned(
           top: 45 + (_scanLineAnimation.value * 60),
           left: 80,
           right: 80,
          child: Container(
            height: 3,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  Colors.red,
                  Colors.red,
                  Colors.transparent,
                ],
              ),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        );
      },
    );
  }
  
    Widget _buildScanStatus() {
    // تحديد لون ونص الحالة
    Color statusColor;
    IconData statusIcon;
    String statusText;
    
    if (!isScanning) {
      statusColor = Colors.red.shade600;
      statusIcon = Icons.pause_circle;
      statusText = "⏸️ المسح متوقف";
    } else if (_isDuplicateDetected) {
      statusColor = Colors.orange.shade600;
      statusIcon = Icons.warning;
      statusText = "⚠️ باركود مكرر";
    } else {
      statusColor = Colors.green.shade600;
      if (_isDesktopPlatform) {
        statusIcon = Icons.scanner;
        statusText = "🖥️ جاهز للقراءة";
      } else {
        statusIcon = Icons.camera_alt;
        statusText = "🔄 جاهز للمسح";
      }
    }
    
    return Positioned(
      top: 16,
      left: 16,
      right: 16,
      child: AnimatedContainer(
        duration: Duration(milliseconds: 300),
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: statusColor,
          borderRadius: BorderRadius.circular(25),
          boxShadow: [
            BoxShadow(
              color: statusColor.withOpacity(0.4),
              blurRadius: 8,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              statusIcon,
              color: Colors.white,
              size: 16,
            ),
            SizedBox(width: 6),
            Text(
              statusText,
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildBarcodeList() {
    return Expanded(
      child: Container(
        margin: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.2),
              blurRadius: 10,
              offset: Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(Icons.list_alt, color: Colors.deepPurple),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          "📋 الباركودات المسحوبة (${scannedBarcodes.length})",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.deepPurple,
                          ),
                        ),
                      ),
                      // زر الإحصائيات
                      IconButton(
                        icon: Icon(Icons.analytics, color: Colors.deepPurple),
                        onPressed: _showStatistics,
                        tooltip: "عرض إحصائيات المسح",
                      ),
                    ],
                  ),
                  
                  // إرشادات للمنصات المكتبية
                  if (_isDesktopPlatform && scannedBarcodes.isEmpty)
                    _buildDesktopInstructions(),
                ],
              ),
            ),
            Expanded(
              child: scannedBarcodes.isEmpty
                  ? _buildEmptyState()
                  : _buildBarcodeListView(),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildDesktopInstructions() {
    return Container(
      margin: EdgeInsets.only(top: 8),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, color: Colors.blue.shade600, size: 20),
              SizedBox(width: 8),
              Text(
                "إرشادات استخدام قارئ الباركود:",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.blue.shade700,
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Text(
            "• تأكد من أن قارئ الباركود متصل بالحاسوب\n"
            "• انقر في حقل الإدخال أسفل المنطقة الزرقاء أعلاه\n"
            "• وجه قارئ الباركود نحو الرمز واضغط الزناد\n"
            "• سيتم إضافة الباركود تلقائياً إلى القائمة أدناه",
            style: TextStyle(
              color: Colors.blue.shade600,
              fontSize: 13,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _isDesktopPlatform ? Icons.scanner : Icons.qr_code_scanner,
            size: 80,
            color: Colors.grey.shade400,
          ),
          SizedBox(height: 16),
          Text(
            "لم يتم مسح أي باركود بعد",
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 8),
          Text(
            _isDesktopPlatform 
                ? "استخدم قارئ الباركود لإضافة المنتجات"
                : "وجه الكاميرا نحو الباركود لبدء المسح",
            style: TextStyle(
              color: Colors.grey.shade500,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildBarcodeListView() {
    return ListView.builder(
      padding: EdgeInsets.symmetric(horizontal: 16),
      itemCount: scannedBarcodes.length,
      itemBuilder: (context, index) {
        final barcode = scannedBarcodes[index];
        return AnimatedContainer(
          duration: Duration(milliseconds: 300),
          margin: EdgeInsets.only(bottom: 8),
          child: Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
                          child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.deepPurple,
                  child: Text(
                    "${index + 1}",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                title: Text(
                  barcode,
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.w500,
                  ),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("الباركود رقم ${index + 1}"),
                    if (_scannedHistory[barcode] != null)
                      Text(
                        "⏰ ${_formatScanTime(_scannedHistory[barcode]!)}",
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 12,
                        ),
                      ),
                  ],
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // زر عرض التفاصيل
                    IconButton(
                      icon: Icon(Icons.info_outline, color: Colors.blue.shade400),
                      onPressed: () => _showBarcodeDetails(barcode, index),
                    ),
                    // زر الحذف
                    IconButton(
                      icon: Icon(Icons.delete_outline, color: Colors.red.shade400),
                      onPressed: () => _removeBarcode(index),
                    ),
                  ],
                ),
              ),
          ),
        );
      },
    );
  }
  
  Widget _buildBottomActions() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            blurRadius: 10,
            offset: Offset(0, -5),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () => Get.back(),
              icon: Icon(Icons.close),
              label: Text("إلغاء"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey.shade600,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          SizedBox(width: 16),
          Expanded(
            flex: 2,
            child: ElevatedButton.icon(
              onPressed: scannedBarcodes.isNotEmpty
                  ? () {
                      HapticFeedback.mediumImpact();
                      widget.onBarcodesScanned(scannedBarcodes);
                      Get.back();
                    }
                  : null,
              icon: Icon(Icons.save),
              label: Text("حفظ (${scannedBarcodes.length})"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: scannedBarcodes.isNotEmpty ? 4 : 0,
              ),
            ),
          ),
        ],
      ),
    );
  }
} 