# حل سريع لمشكلة GoogleService-Info.plist في Xcode

## المشكلة
```
*** Terminating app due to uncaught exception 'com.firebase.core'
`FirebaseApp.configure()` could not find a valid GoogleService-Info.plist
```

## الحل السريع (3 خطوات)

### 1. افتح Xcode workspace
```bash
open ios/Runner.xcworkspace
```

### 2. أضف الملف إلى Bundle Resources
في Xcode Navigator:
1. **Right-click** على مجلد `Runner`
2. اختر `Add Files to "Runner"`
3. انتقل إلى: `ios/Runner/GoogleService-Info.plist`
4. تأكد من تفعيل:
   - ✅ `Copy items if needed`
   - ✅ `Add to target: Runner`
5. اضغط `Add`

### 3. تحقق من Build Phases
1. اختر `Runner` target
2. اذهب إلى `Build Phases`
3. افتح `Copy Bundle Resources`
4. تأكد من وجود `GoogleService-Info.plist`

## ✅ بديل سريع - تشغيل من Terminal
إذا لم تريد التعامل مع Xcode الآن:
```bash
flutter run --release
```

هذا يجب أن يعمل لأن التطبيق يحتوي الآن على Firebase configuration احتياطي.

## ⚠️ ملاحظة مهمة
إذا استمرت المشكلة، استخدم Flutter CLI بدلاً من Xcode حتى يتم حل مشكلة Bundle Resources. 