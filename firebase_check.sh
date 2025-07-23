#!/bin/bash

echo "🔍 فحص إعدادات Firebase للـ Phone Authentication"
echo "=================================================="

# فحص الملفات المطلوبة
echo "📱 فحص ملفات التكوين:"

if [ -f "android/app/google-services.json" ]; then
    echo "✅ google-services.json موجود"
    PROJECT_ID=$(grep -o '"project_id": "[^"]*"' android/app/google-services.json | cut -d'"' -f4)
    echo "   📋 Project ID: $PROJECT_ID"
else
    echo "❌ google-services.json غير موجود"
fi

if [ -f "ios/Runner/GoogleService-Info.plist" ]; then
    echo "✅ GoogleService-Info.plist موجود"
else
    echo "❌ GoogleService-Info.plist غير موجود"
fi

# فحص الصلاحيات
echo ""
echo "🔐 فحص الصلاحيات:"

if grep -q "android.permission.RECEIVE_SMS" android/app/src/main/AndroidManifest.xml; then
    echo "✅ RECEIVE_SMS permission موجود"
else
    echo "❌ RECEIVE_SMS permission غير موجود"
fi

if grep -q "android.permission.READ_SMS" android/app/src/main/AndroidManifest.xml; then
    echo "✅ READ_SMS permission موجود"
else
    echo "❌ READ_SMS permission غير موجود"
fi

if grep -q "android.permission.ACCESS_NETWORK_STATE" android/app/src/main/AndroidManifest.xml; then
    echo "✅ ACCESS_NETWORK_STATE permission موجود"
else
    echo "❌ ACCESS_NETWORK_STATE permission غير موجود"
fi

# فحص Dependencies
echo ""
echo "📦 فحص Dependencies:"

if grep -q "firebase_auth:" pubspec.yaml; then
    echo "✅ firebase_auth dependency موجود"
    FIREBASE_AUTH_VERSION=$(grep "firebase_auth:" pubspec.yaml | cut -d' ' -f4)
    echo "   📋 الإصدار: $FIREBASE_AUTH_VERSION"
else
    echo "❌ firebase_auth dependency غير موجود"
fi

if grep -q "firebase_core:" pubspec.yaml; then
    echo "✅ firebase_core dependency موجود"
else
    echo "❌ firebase_core dependency غير موجود"
fi

# فحص الملفات المطلوبة
echo ""
echo "🔧 فحص ملفات الكود:"

if [ -f "lib/الكود الخاص بتطبيق العميل /services/phone_auth_service.dart" ]; then
    echo "✅ phone_auth_service.dart موجود"
else
    echo "❌ phone_auth_service.dart غير موجود"
fi

echo ""
echo "🚀 الخطوات التالية:"
echo "1. تأكد من تفعيل Phone Authentication في Firebase Console"
echo "2. أضف أرقام الاختبار في Firebase Console إذا كنت تريد"
echo "3. تأكد من صحة Package Name: com.homy.codora"
echo "4. شغّل التطبيق وراقب console logs"
echo ""
echo "📱 أرقام الاختبار المدعومة:"
echo "   +9647803346793 : 123456"
echo "   +1234567890 : 123456"
echo ""
echo "🔍 للمزيد من المساعدة، اقرأ ملف FIREBASE_SETUP_GUIDE.md"
