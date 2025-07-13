# حل مشاكل التوقيع في Xcode

## المشاكل التي تم حلها:
- ✅ تم إزالة `com.apple.developer.usernotifications.filtering` من ملف entitlements
- ✅ تم تنظيف ملف Runner.entitlements

## خطوات إضافية لحل مشكلة التوقيع:

### 1. في Xcode:
1. افتح المشروع في Xcode
2. اذهب إلى **Target** -> **Runner**
3. انقر على تبويب **Signing & Capabilities**

### 2. إعدادات التوقيع:
- تأكد من تفعيل **"Automatically manage signing"**
- اختر **Team** الصحيح (Apple Developer Account)
- تأكد من أن **Bundle Identifier** صحيح: `com.homy.codora`

### 3. إذا استمرت المشكلة:
1. **قم بإزالة الملفات المؤقتة:**
   ```bash
   rm -rf ~/Library/Developer/Xcode/DerivedData
   cd ios
   rm -rf build/
   flutter clean
   cd ios
   pod deintegrate
   pod install
   ```

2. **في Xcode، اذهب إلى:**
   - **Preferences** -> **Accounts**
   - تأكد من تسجيل الدخول بحساب Apple Developer الصحيح
   - انقر على **Download Manual Profiles**

### 4. إعادة تعيين Provisioning Profile:
1. في تبويب **Signing & Capabilities**
2. قم بإلغاء تفعيل **"Automatically manage signing"**
3. ثم أعد تفعيلها مرة أخرى
4. اختر Team مرة أخرى

### 5. تشغيل التطبيق:
```bash
cd ios
flutter run
```

## ملاحظات مهمة:
- الـ entitlement `com.apple.developer.usernotifications.filtering` يتطلب **paid developer account**
- إذا كنت تستخدم **free developer account**، لا يمكنك استخدام هذه الصلاحية
- تأكد من أن Bundle ID فريد ولم يتم استخدامه من قبل

## إذا استمرت المشكلة:
1. جرب تغيير Bundle Identifier إلى شيء فريد
2. تأكد من أن حساب Apple Developer نشط
3. قم بإنشاء provisioning profile جديد يدوياً من Apple Developer Console 