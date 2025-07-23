# دليل إعداد Firebase للتحقق من رقم الهاتف

## 🔧 الإعدادات المطلوبة

### 1. في Firebase Console:

#### أ) تفعيل Phone Authentication:
1. اذهب إلى [Firebase Console](https://console.firebase.google.com)
2. اختر مشروعك `codora-app1`
3. من القائمة الجانبية، اختر **Authentication**
4. اذهب إلى تبويب **Sign-in method**
5. فعّل **Phone** من قائمة Sign-in providers
6. احفظ التغييرات

#### ب) إعداد reCAPTCHA (للويب):
1. في نفس صفحة Sign-in method
2. في قسم Phone، تأكد من إعداد reCAPTCHA
3. أضف domain التطبيق إذا كان مطلوباً

#### ج) إعداد Test Phone Numbers (اختياري):
1. في نفس صفحة Sign-in method
2. مرر للأسفل إلى **Phone numbers for testing**
3. أضف أرقام الاختبار:
   - `+9647803346793` : `123456`
   - `+1234567890` : `123456`

### 2. في Android Studio/Xcode:

#### أ) ملفات التكوين:
- **Android**: تأكد من وجود `google-services.json` في `android/app/`
- **iOS**: تأكد من وجود `GoogleService-Info.plist` في `ios/Runner/`

#### ب) الصلاحيات المطلوبة:

**Android** (`android/app/src/main/AndroidManifest.xml`):
```xml
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />
<uses-permission android:name="android.permission.RECEIVE_SMS" />
<uses-permission android:name="android.permission.READ_SMS" />
```

**iOS** (`ios/Runner/Info.plist`):
```xml
<key>NSPhotoLibraryUsageDescription</key>
<string>يحتاج التطبيق لإرسال الصور</string>
```

### 3. فحص الإعدادات:

#### أ) تشغيل التطبيق مع التشخيص:
1. شغّل التطبيق في وضع Debug
2. راقب console logs للحصول على معلومات التشخيص
3. ابحث عن رسائل تبدأ بـ `🔍 Firebase Diagnosis`

#### ب) فحص الشبكة:
1. تأكد من اتصال الإنترنت
2. تأكد من عدم حجب Firebase في الشبكة
3. جرب شبكة مختلفة إذا كان متاحاً

## 🚨 المشاكل الشائعة وحلولها:

### 1. "لا يتم إرسال الرمز":
```
الحلول:
✅ تأكد من تفعيل Phone Authentication في Firebase Console
✅ تحقق من صحة ملفات التكوين (google-services.json/GoogleService-Info.plist)
✅ تأكد من صحة تنسيق رقم الهاتف (+9647xxxxxxxx)
✅ تحقق من الصلاحيات في AndroidManifest.xml
```

### 2. "رمز خطأ من Firebase":
```
الحلول:
✅ تأكد من استخدام نفس Project ID في جميع الملفات
✅ أعد تنزيل ملفات التكوين من Firebase Console
✅ تأكد من Package Name/Bundle ID الصحيح
```

### 3. "تم تجاوز الحد المسموح":
```
الحلول:
✅ انتظر 24 ساعة قبل المحاولة مرة أخرى
✅ استخدم أرقام اختبار أثناء التطوير
✅ تحقق من إعدادات Quota في Firebase Console
```

### 4. "خطأ في التحقق":
```
الحلول:
✅ تأكد من صحة SHA-1/SHA-256 للـ Android app
✅ تحقق من Bundle ID للـ iOS app
✅ أعد بناء التطبيق بعد تحديث الإعدادات
```

## 🔍 خطوات التشخيص المتقدم:

### 1. فحص console logs:
```
ابحث عن هذه الرسائل:
🔍 Firebase Diagnosis: {...}
📱 Phone Validation: {...}
✅ Code sent successfully
❌ Firebase error: ...
```

### 2. تشغيل الأوامر التشخيصية:
```bash
# للـ Android
flutter build apk --debug
adb logcat | grep FirebaseAuth

# للـ iOS  
flutter build ios --debug
# راقب logs في Xcode Console
```

### 3. تجربة أرقام مختلفة:
```
جرب هذه الأرقام للاختبار:
✅ +9647803346793 (رقم اختبار)
✅ +1234567890 (رقم اختبار)  
✅ رقمك الحقيقي بتنسيق +964xxxxxxx
```

## 📋 checklist سريع:

- [ ] Firebase Authentication مفعل
- [ ] Phone provider مفعل في Firebase Console
- [ ] ملفات التكوين موجودة وصحيحة
- [ ] الصلاحيات مضافة في AndroidManifest.xml
- [ ] Package Name/Bundle ID صحيح
- [ ] SHA fingerprints مضافة (Android)
- [ ] اتصال الإنترنت يعمل
- [ ] رقم الهاتف بالتنسيق الصحيح (+964xxxxxxx)

---
**ملاحظة**: إذا كانت المشكلة مستمرة، راقب console logs وأرسل التفاصيل للحصول على مساعدة أكثر تفصيلاً.
