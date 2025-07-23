# دليل استكشاف أخطاء PhoneAuthService وإصلاحها

## الأخطاء الشائعة وحلولها

### 1. خطأ `internal-error`

**السبب:** خطأ داخلي في Firebase، عادة مرتبط بإعدادات reCAPTCHA أو الشبكة.

**الحلول:**

#### للـ iOS:
```bash
# التحقق من Bundle ID في Firebase Console
# التأكد من أن Bundle ID في Xcode يطابق Firebase Console
# فحص Google Service Info.plist
```

#### للـ Android:
```bash
# التحقق من SHA-1 fingerprint
keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android

# إضافة SHA-1 إلى Firebase Console > Project Settings > Your Apps
```

#### حلول عامة:
1. **إعادة تشغيل التطبيق**
2. **التحقق من الاتصال بالإنترنت**
3. **انتظار بضع دقائق ثم المحاولة مرة أخرى**
4. **تنظيف cache التطبيق**

### 2. خطأ `too-many-requests`

**السبب:** تم إرسال الكثير من الطلبات في فترة قصيرة.

**الحلول:**
- انتظار 5-15 دقيقة قبل المحاولة مرة أخرى
- استخدام أرقام هواتف مختلفة للاختبار
- تحديد حدود أقل في اختبارات التطوير

### 3. خطأ `invalid-phone-number`

**السبب:** تنسيق رقم الهاتف غير صحيح.

**الحلول:**
- التأكد من استخدام رمز الدولة (+964 للعراق)
- التأكد من أن الرقم صحيح ومكتمل
- استخدام تنسيق E.164: `+9647XXXXXXXX`

### 4. خطأ `captcha-check-failed`

**السبب:** فشل في التحقق من reCAPTCHA.

**الحلول للـ iOS:**
1. التأكد من إعدادات reCAPTCHA في Firebase Console
2. إعادة تشغيل التطبيق
3. التحقق من إعدادات الشبكة

**الحلول للـ Android:**
1. التأكد من Google Play Services محدث
2. التحقق من SHA-1 fingerprint
3. إعادة بناء التطبيق

### 5. خطأ `network-request-failed`

**السبب:** مشكلة في الاتصال بالإنترنت.

**الحلول:**
- التحقق من اتصال الإنترنت
- التأكد من عدم حجب Firebase من قبل جدار الحماية
- المحاولة على شبكة مختلفة

## فحص إعدادات Firebase

### 1. التحقق من iOS Setup:

```bash
# في ios/Runner/Info.plist تحقق من:
<key>CFBundleIdentifier</key>
<string>YOUR_BUNDLE_ID</string>

# تأكد من وجود GoogleService-Info.plist في المجلد الصحيح
```

### 2. التحقق من Android Setup:

```bash
# في android/app/build.gradle تحقق من:
applicationId "YOUR_PACKAGE_NAME"

# تأكد من وجود google-services.json في android/app/
```

### 3. فحص Firebase Console:

1. **الذهاب إلى Firebase Console**
2. **اختيار المشروع**
3. **Project Settings > General**
4. **التحقق من:**
   - iOS Bundle ID
   - Android Package Name
   - SHA-1 Fingerprints

## أدوات التشخيص

### استخدام PhoneAuthTestPage:

```dart
// الانتقال لصفحة الاختبار
Get.to(() => PhoneAuthTestPage());

// أو في Routes
static const String phoneAuthTest = '/phone-auth-test';
```

### فحص logs التطبيق:

```bash
# في VS Code Terminal
flutter logs

# أو
flutter run --verbose
```

### استخدام دوال التشخيص:

```dart
final phoneAuthService = Get.find<PhoneAuthService>();

// اختبار الخدمة
phoneAuthService.testService();

// تشخيص Firebase
final diagnosis = await phoneAuthService.diagnoseFirebaseSetup();
print(diagnosis);

// فحص رقم الهاتف
final validation = phoneAuthService.validatePhoneNumber('+9647XXXXXXXX');
print(validation);
```

## نصائح لتجنب الأخطاء

### 1. في التطوير:
- استخدام أرقام هواتف حقيقية للاختبار
- عدم الإفراط في إرسال الطلبات
- اختبار على أجهزة مختلفة

### 2. في الإنتاج:
- إعداد معالجة أخطاء شاملة
- عرض رسائل خطأ واضحة للمستخدمين
- توفير طرق بديلة للتسجيل

### 3. الأمان:
- عدم حفظ أرقام الاختبار في الكود
- استخدام بيئات منفصلة للتطوير والإنتاج
- مراجعة logs بانتظام

## متطلبات الشبكة

### Firebase Auth يتطلب الوصول إلى:
- `*.googleapis.com`
- `*.firebase.com` 
- `*.google.com`
- `identitytoolkit.googleapis.com`

### للشركات/الجامعات:
قد تحتاج لطلب إلغاء حجب هذه النطاقات من IT.

## الدعم الفني

إذا استمرت المشاكل:

1. **جمع معلومات التشخيص**
2. **أخذ screenshots للأخطاء**
3. **نسخ logs التطبيق**
4. **التواصل مع فريق التطوير**

---

*آخر تحديث: يناير 2025*
