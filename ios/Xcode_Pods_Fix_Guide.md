# حل مشكلة "Framework 'Pods_Runner' not found" في Xcode

## المشكلة
```
Framework 'Pods_Runner' not found
Linker command failed with exit code 1
```

## السبب الأكثر شيوعاً
فتح `.xcodeproj` بدلاً من `.xcworkspace`

## الحل الصحيح

### 1. ✅ افتح الملف الصحيح
**يجب فتح:**
```bash
open ios/Runner.xcworkspace
```

**❌ لا تفتح:**
```bash
ios/Runner.xcodeproj  # هذا خطأ!
```

### 2. التحقق من إعدادات Build Configuration

#### A. في Xcode Navigator:
1. اختر `Runner` project (الأعلى)
2. اختر `Runner` target 
3. اذهب إلى `Build Settings`
4. ابحث عن `Configurations`

#### B. تأكد من الإعدادات:
- **Debug:** `Pods/Target Support Files/Pods-Runner/Pods-Runner.debug.xcconfig`
- **Release:** `Pods/Target Support Files/Pods-Runner/Pods-Runner.release.xcconfig` 
- **Profile:** `Pods/Target Support Files/Pods-Runner/Pods-Runner.profile.xcconfig`

### 3. إذا استمرت المشكلة

#### الحل الجذري:
```bash
# في Terminal
cd path/to/your/project
flutter clean
cd ios
rm -rf Pods Podfile.lock
pod install
cd ..
flutter pub get
```

#### ثم افتح workspace:
```bash
open ios/Runner.xcworkspace
```

### 4. تحقق من Scheme في Xcode

1. في Xcode toolbar، اضغط على scheme dropdown
2. تأكد من اختيار `Runner` scheme
3. تأكد من اختيار جهازك كـ destination

### 5. إعدادات Framework Search Paths

إذا استمرت المشكلة:

1. في `Build Settings`
2. ابحث عن `Framework Search Paths`
3. تأكد من وجود:
   ```
   $(inherited)
   "${PODS_CONFIGURATION_BUILD_DIR}/Pods-Runner"
   ```

### 6. إعدادات Library Search Paths

1. في `Build Settings`
2. ابحث عن `Library Search Paths`
3. تأكد من وجود:
   ```
   $(inherited)
   "${PODS_CONFIGURATION_BUILD_DIR}/Pods-Runner"
   ```

### 7. تنظيف Derived Data

إذا لم يساعد ما سبق:

1. في Xcode: `Product` > `Clean Build Folder`
2. أو في Terminal:
   ```bash
   rm -rf ~/Library/Developer/Xcode/DerivedData
   ```

### 8. إعادة إنشاء المشروع كاملاً

```bash
flutter clean
flutter pub get
cd ios
pod deintegrate
pod install
cd ..
flutter run
```

## نصائح إضافية

### ✅ افعل:
- استخدم دائماً `.xcworkspace`
- تأكد من `pod install` بعد أي تغيير في dependencies
- نظف المشروع بعد تحديث Pods

### ❌ لا تفعل:
- لا تفتح `.xcodeproj` مباشرة
- لا تحذف ملفات Pods يدوياً بدون إعادة install
- لا تغير إعدادات Build Configuration يدوياً

## التحقق من نجاح الحل

يجب أن ترى في Xcode Navigator:
- مجلد `Pods` في project
- `Pods-Runner.framework` في `Frameworks` folder
- لا توجد أخطاء linker

## إذا استمرت المشكلة

جرب استخدام Flutter CLI بدلاً من Xcode:
```bash
flutter run --release
```

هذا يجب أن يعمل دائماً لأنه يتعامل مع Pods تلقائياً. 