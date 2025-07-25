# إرشادات اختبار رمز التحقق

## 📱 أرقام الاختبار المدعومة

يدعم التطبيق الآن أرقام اختبار محددة مسبقاً للتطوير والاختبار:

### الأرقام المتاحة:
- `+9647803346793` - الرمز: `123456`
- `+1234567890` - الرمز: `123456`
- `+966500000000` - الرمز: `123456`
- `+201234567890` - الرمز: `123456`
- `+962791234567` - الرمز: `123456`

## 🔧 كيفية الاختبار

### 1. استخدام رقم اختبار:
1. أدخل أحد الأرقام المذكورة أعلاه في صفحة التسجيل
2. ستظهر رسالة تؤكد أن هذا رقم اختبار
3. سيظهر إشعار يحتوي على الرمز الصحيح
4. أدخل الرمز `123456` في حقول التحقق

### 2. ميزات الاختبار:
- ✅ **انتقال تلقائي** بين الحقول عند إدخال الأرقام
- ✅ **مسح تلقائي** للحقول عند إدخال رمز خاطئ
- ✅ **إشعار توضيحي** يظهر الرمز الصحيح للأرقام التجريبية
- ✅ **دعم اللصق** للرمز الكامل (6 أرقام)
- ✅ **عدّ صحيح للمحاولات** - لا توجد محاولات إضافية

## 🧪 سيناريوهات الاختبار

### اختبار النجاح:
1. استخدم رقم: `+9647803346793`
2. أدخل الرمز: `123456`
3. ✅ يجب أن يتم قبول الرمز بنجاح

### اختبار الفشل:
1. استخدم رقم: `+9647803346793`
2. أدخل رمز خاطئ: `999999`
3. ❌ ستظهر رسالة خطأ
4. 🧹 سيتم مسح الحقول تلقائياً بعد 1.5 ثانية
5. 🎯 سيعود التركيز للحقل الأول

## 🔄 الميزات المحسنة

### الانتقال التلقائي:
- عند إدخال رقم، ينتقل للحقل التالي تلقائياً
- عند مسح رقم، يرجع للحقل السابق
- تأخير 50ms لضمان انتقال سلس

### معالجة الأخطاء:
- مسح تلقائي للحقول بعد رسالة الخطأ
- عودة التركيز للحقل الأول
- عداد محاولات دقيق (لا توجد محاولات إضافية)

### دعم اللصق:
- يمكن لصق الرمز الكامل (6 أرقام) في أي حقل
- تنظيف تلقائي للنص (إزالة المسافات والرموز)
- توزيع الأرقام على الحقول تلقائياً

## 🚀 للمطورين

### إضافة رقم اختبار جديد:
```dart
// في ملف phone_auth_service.dart
static const Map<String, String> _testPhoneNumbers = {
  '+رقمك_الجديد': 'الرمز_المطلوب',
  // ...أرقام أخرى
};
```

### تشغيل وضع Debug:
- في بيئة التطوير، ستظهر رسائل console تحتوي على معلومات الاختبار
- رسائل إرشادية واضحة للمطور

## ⚠️ ملاحظات مهمة

1. **أرقام الاختبار**: تعمل فقط في بيئة التطوير
2. **Firebase Console**: تأكد من إضافة نفس الأرقام في Firebase Console إذا كنت تستخدم أرقام حقيقية
3. **الأمان**: لا تترك أرقام الاختبار في الإنتاج النهائي

## 🎯 النتيجة النهائية

✅ انتقال تلقائي سلس بين حقول الإدخال  
✅ مسح تلقائي للرمز الخاطئ مع رسالة واضحة  
✅ عدّ صحيح للمحاولات - لا توجد محاولات إضافية  
✅ دعم كامل لأرقام الاختبار  
✅ تجربة مستخدم محسنة مع إرشادات واضحة  
✅ لا توجد أخطاء compilation  

---
**تاريخ آخر تحديث**: 17 يوليو 2025  
**الإصدار**: 2.0.0 - Enhanced  
