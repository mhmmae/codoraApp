# إعداد Xcode للإشعارات - دليل شامل

## خطوات إجبارية لحل مشكلة APNS Token

### 1. فتح المشروع في Xcode
```bash
open ios/Runner.xcworkspace
```

### 2. إعدادات Project Navigator
1. اختر `Runner` project في المجلد الأيسر
2. اختر `Runner` target (ليس RunnerTests)
3. انتقل إلى تبويب `Signing & Capabilities`

### 3. إعداد Bundle Identifier
تأكد أن Bundle Identifier هو: `com.homy.codora`
- يجب أن يطابق ما هو موجود في Firebase Console
- يجب أن يطابق ما هو مسجل في Apple Developer Account

### 4. إضافة Push Notifications Capability
**هذه الخطوة الأهم:**

1. في `Signing & Capabilities`
2. اضغط على `+ Capability`
3. ابحث عن `Push Notifications`
4. اضغط عليها لإضافتها
5. يجب أن تظهر `Push Notifications` في قائمة Capabilities

### 5. إعداد Background Modes
1. في نفس التبويب، أضف `Background Modes` capability
2. فعّل الخيارات التالية:
   - ✅ `Remote notifications`
   - ✅ `Background fetch`
   - ✅ `Background processing`

### 6. التحقق من Provisioning Profile
1. في `Signing & Capabilities`
2. تأكد أن `Automatically manage signing` مفعل
3. أو اختر provisioning profile يدعم Push Notifications

### 7. إعداد Firebase Console

#### A. رفع APNs Certificate/Key
1. اذهب إلى [Firebase Console](https://console.firebase.google.com)
2. اختر مشروعك
3. اذهب إلى `Project Settings` > `Cloud Messaging`
4. في قسم `iOS app configuration`:

**الخيار الأول (المفضل) - APNs Key:**
- احصل على APNs Key من Apple Developer Account
- ارفعه في Firebase Console
- أدخل Key ID و Team ID

**الخيار الثاني - APNs Certificate:**
- أنشئ APNs Certificate من Apple Developer Account
- ارفعه في Firebase Console

#### B. تحقق من Bundle ID
تأكد أن Bundle ID في Firebase يطابق `com.homy.codora`

### 8. Apple Developer Account Setup

1. اذهب إلى [Apple Developer](https://developer.apple.com)
2. `Certificates, Identifiers & Profiles`
3. `Identifiers` > اختر App ID للتطبيق
4. تأكد أن `Push Notifications` مفعل
5. إذا لم يكن مفعلاً:
   - اضغط `Edit`
   - فعّل `Push Notifications`
   - اضغط `Save`

### 9. إنشاء APNs Key (المفضل)

**في Apple Developer Account:**
1. `Keys` > `+` (إنشاء key جديد)
2. اكتب اسم للـ Key
3. فعّل `Apple Push Notifications service (APNs)`
4. اضغط `Continue` ثم `Register`
5. حمّل الـ `.p8` file
6. احفظ `Key ID` و `Team ID`

**في Firebase Console:**
1. `Project Settings` > `Cloud Messaging`
2. `APNs Authentication Key`
3. ارفع الـ `.p8` file
4. أدخل Key ID و Team ID

### 10. تشغيل التطبيق

**مهم جداً:**
- يجب اختبار التطبيق على **جهاز فيزيائي**
- APNS لا يعمل على Simulator
- تأكد من تسجيل الدخول بـ Apple ID على الجهاز

### 11. التحقق من نجاح الإعداد

في Xcode Console يجب أن تظهر:
```
✅ APNs token retrieved successfully!
🔑 APNs token (hex): [token_value]
✅ FCM registration token: [fcm_token]
```

في Flutter Console:
```
✅ APNS Token received: [token_preview]
✅ FCM Token received successfully!
fcmTokenStatus: "active"
```

## استكشاف الأخطاء

### إذا ظهرت رسالة "Push Notifications entitlement is missing"
- تأكد من إضافة Push Notifications capability في Xcode
- تأكد من أن Bundle ID صحيح
- أعد إنشاء provisioning profile

### إذا ظهرت "Invalid APNs certificate"
- تأكد من رفع certificate/key صحيح في Firebase
- تأكد من صحة Bundle ID في Firebase Console

### إذا استمرت المشكلة
- امسح Derived Data في Xcode
- أعد تثبيت التطبيق على الجهاز
- تأكد من صحة Apple Developer Account permissions 