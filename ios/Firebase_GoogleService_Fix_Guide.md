# حل مشكلة "GoogleService-Info.plist not found" في Xcode

## المشكلة
```
FirebaseApp.configure() could not find a valid GoogleService-Info.plist in your project.
Thread 1: Fatal error in AppDelegate
```

## السبب الأكثر شيوعاً
الملف موجود لكن **غير مضاف إلى Bundle Resources** في Xcode

## الحل الشامل

### 1. ✅ فتح Xcode workspace
```bash
open ios/Runner.xcworkspace
```

### 2. 🔍 فحص وجود الملف في Bundle Resources

#### A. في Xcode Navigator (الجانب الأيسر):
1. افتح مجلد `Runner`
2. ابحث عن `GoogleService-Info.plist`
3. إذا لم تجده، فهذا هو السبب!

#### B. التحقق من Target Membership:
1. اضغط على `GoogleService-Info.plist` (إذا وجد)
2. في File Inspector (الجانب الأيمن)
3. تأكد أن `Runner` target مفعل ✅

### 3. 🔧 إضافة الملف إلى Bundle Resources

#### إذا لم يكن الملف موجوداً في Xcode:

1. **Right-click** على مجلد `Runner` في Navigator
2. اختر `Add Files to "Runner"`
3. انتقل إلى: `ios/Runner/GoogleService-Info.plist`
4. تأكد من:
   - ✅ `Copy items if needed`
   - ✅ `Add to target: Runner`
5. اضغط `Add`

### 4. 🎯 التحقق من Bundle ID

في `GoogleService-Info.plist` يجب أن يكون:
```xml
<key>BUNDLE_ID</key>
<string>com.homy.codora</string>
```

وفي Xcode Project Settings:
1. اختر `Runner` project
2. اختر `Runner` target
3. في `General` tab
4. تأكد أن `Bundle Identifier` هو: `com.homy.codora`

### 5. 🧹 تنظيف وإعادة البناء

```bash
# في Terminal
flutter clean
cd ios
rm -rf build/
cd ..
flutter pub get
flutter build ios --debug
```

### 6. 📱 التحقق في Xcode Build Phases

1. اختر `Runner` target
2. اذهب إلى `Build Phases`
3. افتح `Copy Bundle Resources`
4. تأكد من وجود `GoogleService-Info.plist` في القائمة
5. إذا لم يكن موجوداً:
   - اضغط `+`
   - أضف `GoogleService-Info.plist`

### 7. 🔄 إذا استمرت المشكلة

#### حذف وإعادة إضافة الملف:
1. في Xcode، احذف `GoogleService-Info.plist`
2. اختر `Move to Trash`
3. أعد إضافته كما في الخطوة 3

#### تحديد مسار مخصص في AppDelegate:
إذا فشل كل شيء، أضف هذا الكود في `AppDelegate.swift`:

```swift
override func application(
  _ application: UIApplication,
  didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
) -> Bool {
  
  // تحديد مسار مخصص للملف
  if let path = Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist"),
     let options = FirebaseOptions(contentsOfFile: path) {
    FirebaseApp.configure(options: options)
  } else {
    // إذا لم يعمل، استخدم الطريقة العادية
    FirebaseApp.configure()
  }
  
  // باقي الكود...
}
```

### 8. 🎛️ حل بديل - نسخ الملف يدوياً

```bash
# في Terminal من مجلد المشروع
cp ios/GoogleService-Info.plist ios/Runner/
```

ثم أضفه في Xcode كما في الخطوة 3.

## التحقق من نجاح الحل

### ✅ علامات النجاح:
- لا توجد crash في `FirebaseApp.configure()`
- ظهور Firebase logs في console
- عمل Firebase features (Auth, Firestore, etc.)

### 🔍 للتأكد:
في Xcode Console يجب أن ترى:
```
[FirebaseCore] Firebase configured successfully
```

## نصائح إضافية

### ✅ افعل:
- استخدم دائماً `.xcworkspace`
- تأكد من Bundle ID متطابق
- أضف الملف إلى Bundle Resources

### ❌ لا تفعل:
- لا تضع الملف في مجلد خارجي
- لا تغير Bundle ID بعد تنزيل الملف
- لا تنس إضافة الملف إلى Target

## إذا احتجت ملف جديد

1. اذهب إلى [Firebase Console](https://console.firebase.google.com)
2. اختر مشروعك
3. `Project Settings` > `General`
4. في قسم `Your apps` > iOS app
5. حمّل `GoogleService-Info.plist` جديد
6. استبدل الملف القديم 