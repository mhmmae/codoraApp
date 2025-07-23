## 🔧 دليل استكشاف أخطاء Firebase internal-error

### خطوات التشخيص:

#### 1. Firebase Console ✅
- ✅ تأكد من تفعيل Phone Authentication
- ✅ تأكد من صحة SHA-1: `68:AE:1B:D8:91:FA:07:3B:73:AE:E3:A7:6C:24:BF:68:EC:0E:36:36`
- ✅ تأكد من Package Name: `com.homy.codora`

#### 2. Google Play Services 🔄
المشكلة المحتملة في logs:
```
E/GoogleApiManager: Failed to get service from broker
E/GoogleApiManager: java.lang.SecurityException: Unknown calling package name 'com.google.android.gms'
```

**الحل:**
- تحديث Google Play Services على الجهاز
- إعادة تشغيل الجهاز
- Clear cache لتطبيق Google Play Services

#### 3. اختبار بديل 🧪
إذا استمرت المشكلة، جرب:

1. **جهاز مختلف** (emulator أو جهاز آخر)
2. **إنترنت مختلف** (WiFi مختلف أو Mobile Data)
3. **تطبيق جديد** لاختبار Firebase

#### 4. Debug Mode 🐛
أضف هذا في main.dart للمزيد من التفاصيل:

```dart
FirebaseAuth.instance.setSettings(
  appVerificationDisabledForTesting: false,
);
```

### 🎯 الخلاصة:
التطبيق يعمل بنجاح، والمشكلة غالباً في إعدادات Firebase Console أو Google Play Services على الجهاز.
