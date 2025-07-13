# حل مشكلة FCM Token على iOS

## المشكلة
لا يمكن الحصول على FCM token على iOS بسبب عدم توفر APNS token، مما يؤدي إلى:
- `❌ Failed to get APNS token after 5 attempts`
- `⚠️ FCM token attempt failed: [firebase_messaging/apns-token-not-set]`

## الحلول المطبقة

### 1. تحديث AppDelegate.swift
✅ تم إضافة إعدادات Firebase المطلوبة:
- Firebase configuration
- APNS token handling  
- FCM messaging delegate
- Notification permissions

### 2. تحسين منطق FCM Token في Flutter
✅ تم تحسين `_getFCMTokenSafely()`:
- زيادة عدد محاولات APNS (8 محاولات)
- زيادة timeout لـ FCM (45 ثانية)
- انتظار أطول بين المحاولات
- معالجة أفضل للأخطاء

### 3. إضافة دالة iOS محسّنة
✅ تم إضافة `_getIOSOptimizedFCMToken()`:
- انتظار إضافي 5 ثواني قبل البدء
- 3 محاولات مع timeout متزايد
- معالجة خاصة لأخطاء APNS

### 4. تحسين إعادة المحاولة
✅ تم تحسين `retryFCMTokenLater()`:
- محاولة بعد 30 ثانية
- محاولة خاصة بـ iOS بعد دقيقة
- محاولة بعد دقيقتين
- محاولة أخيرة بعد 5 دقائق

### 5. إعدادات Info.plist
✅ تم إضافة:
- `FirebaseMessagingAutoInitEnabled: true`
- `FirebaseAutomaticScreenReportingEnabled: false`

### 6. إعدادات Entitlements
✅ تم التأكد من وجود:
- `aps-environment: development`
- User notifications capabilities

## خطوات إضافية مطلوبة

### 1. إعادة بناء المشروع
```bash
cd ios
pod install --repo-update
cd ..
flutter clean
flutter pub get
flutter build ios
```

### 2. التأكد من إعدادات Xcode
افتح المشروع في Xcode وتأكد من:

#### A. Bundle Identifier
تأكد أن Bundle ID في Xcode يطابق الموجود في Firebase Console

#### B. Signing & Capabilities
- تفعيل "Push Notifications"
- تفعيل "Background Modes" مع remote-notification
- تفعيل Apple Sign In إذا كان مستخدماً

#### C. GoogleService-Info.plist
تأكد أن الملف موجود في Bundle Resources

### 3. إعدادات Firebase Console
تأكد من:
- رفع APNs Certificate أو Key
- تفعيل FCM في المشروع
- صحة Bundle ID

### 4. اختبار الجهاز
⚠️ **مهم**: APNS لا يعمل على Simulator
- اختبر على جهاز فيزيائي فقط
- تأكد من اتصال الإنترنت
- تأكد من تسجيل الدخول بـ Apple ID

## نصائح إضافية

### 1. Debug على الجهاز
```bash
flutter run --release -d [device-id]
```

### 2. مراقبة Logs
```bash
flutter logs
```

### 3. إذا استمرت المشكلة
- تأكد من صحة APNs certificate في Firebase
- جرب إنشاء مشروع Firebase جديد
- تحقق من Developer Account permissions

## التحقق من نجاح الحل

يجب أن تظهر الرسائل التالية في Console:
```
✅ APNS Token received
✅ FCM Token received successfully!
✅ FCM Token will be saved
```

وفي Firestore:
```
fcmToken: "actual_token_value"
fcmTokenStatus: "active"
fcmTokenUpdatedAt: timestamp
``` 