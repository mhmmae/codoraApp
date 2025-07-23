# Firebase Phone Authentication Setup Guide

## المشكلة الحالية
```
operation-not-allowed - This operation is not allowed. This may be because the given sign-in provider is disabled for this Firebase project.
```

## الحل

### 1. تفعيل Phone Authentication في Firebase Console

1. اذهب إلى [Firebase Console](https://console.firebase.google.com/)
2. اختر مشروعك
3. اذهب إلى **Authentication** > **Sign-in method**
4. ابحث عن **Phone** وانقر **Enable**
5. احفظ التغييرات

### 2. إعداد الأرقام التجريبية (Test Phone Numbers)

1. في نفس الصفحة، انتقل إلى **Phone numbers for testing**
2. أضف الأرقام التجريبية:
   ```
   +1 555 123 4567 → 123456
   +966 50 123 4567 → 123456
   +964 780 334 6793 → 123456
   ```

### 3. تحقق من إعدادات Android

تأكد من وجود هذا في `android/app/build.gradle`:
```gradle
android {
    compileSdkVersion 34
    ...
}

dependencies {
    implementation 'com.google.firebase:firebase-auth:22.3.0'
    implementation 'com.google.android.gms:play-services-auth:20.7.0'
}
```

### 4. تحديث قواعد Firebase Security Rules

```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    match /{allPaths=**} {
      allow read, write: if request.auth != null;
    }
  }
}
```

### 5. اختبار النظام

بعد تطبيق الإعدادات:
1. استخدم رقم تجريبي أولاً: `+1 555 123 4567`
2. ادخل الرمز: `123456`
3. إذا نجح، جرب رقماً حقيقياً

### 6. حل مشاكل إضافية

#### إذا استمرت المشكلة:
- تأكد من تشغيل Firebase CLI: `firebase use --add`
- تحديث Firebase SDK: `flutter pub upgrade`
- إعادة تشغيل التطبيق

#### للأرقام الحقيقية:
- تأكد من أن منطقتك مدعومة
- تحقق من حصة SMS في Firebase Console
- قد تحتاج إلى تفعيل حسابك الفوري (Billing Account)

## الحالة الحالية للكود
✅ **تم إصلاح:**
- SellerAuthController مسجل في GetX
- GPU Service محسن لتجنب الأخطاء
- معالجة أخطاء شاملة

⚠️ **يحتاج إصلاح:**
- إعداد Phone Authentication في Firebase Console
- إضافة أرقام تجريبية
