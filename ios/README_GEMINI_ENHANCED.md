# 🚀 Gemini Enhanced CLI - دليل شامل

## 📋 المحتويات
- [نظرة عامة](#نظرة-عامة)
- [الميزات](#الميزات)
- [التثبيت](#التثبيت)
- [الإعداد الأولي](#الإعداد-الأولي)
- [الاستخدام الأساسي](#الاستخدام-الأساسي)
- [الأدوات المتخصصة](#الأدوات-المتخصصة)
- [أمثلة عملية](#أمثلة-عملية)
- [التكوين المتقدم](#التكوين-المتقدم)
- [استكشاف الأخطاء](#استكشاف-الأخطاء)

---

## 🎯 نظرة عامة

Gemini Enhanced CLI هو أداة محسنة وذكية للتفاعل مع Google Gemini مع ميزات متقدمة للمطورين، خاصة مطوري Flutter وDart.

### ✨ الميزات الرئيسية

#### 🧠 الذكاء المحسن
- **الذاكرة الذكية**: يتذكر المحادثات السابقة ويستخدمها للسياق
- **فهم السياق**: يحلل ويفهم سياق مشاريعك
- **System Instructions مخصصة**: توجيهات ذكية للحصول على أفضل النتائج

#### 🔧 أدوات التطوير
- **تحليل الكود**: مراجعة وتحسين الكود تلقائياً
- **تحليل مشاريع Flutter**: فهم عميق لبنية مشاريع Flutter
- **debugging مساعد**: مساعدة في حل الأخطاء والمشاكل

#### 🎛️ واجهات متعددة
- **سطر الأوامر**: استخدام سريع ومباشر
- **الوضع التفاعلي**: محادثة مستمرة
- **أدوات مساعدة**: دوال جاهزة للمهام الشائعة

---

## 🛠️ التثبيت

### الطريقة السريعة (تم تطبيقها)
```bash
# تم بالفعل! ✅
# جميع الملفات موجودة في ~/.gemini-enhanced/
# الاختصارات مضافة إلى ~/.zshrc
```

### التحقق من التثبيت
```bash
gconfig  # عرض الإعدادات
ghelpers # عرض جميع الأدوات
```

---

## ⚙️ الإعداد الأولي

### 1. تعيين API Key
```bash
# الطريقة الأولى: متغير البيئة
export GEMINI_API_KEY="your-api-key-here"

# الطريقة الثانية: عبر الأداة
gsmart --config api_key "your-api-key-here"
```

### 2. التحقق من الإعدادات
```bash
gconfig
```

---

## 🎮 الاستخدام الأساسي

### الأوامر الأساسية

#### 💬 الاستخدام العادي
```bash
gsmart "كيف يمكنني تحسين أداء تطبيق Flutter؟"
gask "ما هي أفضل ممارسات Dart؟"
```

#### 🔧 عرض الإعدادات والذاكرة
```bash
gconfig                    # عرض الإعدادات
gmemory                    # عرض آخر 10 محادثات
gmemory 20                 # عرض آخر 20 محادثة
```

#### 🎯 تحليل الكود
```bash
gcode lib/main.dart "ما رأيك في هذا الكود؟"
gcode lib/models/user.dart lib/services/api.dart "كيف يمكن تحسين هذا؟"
```

#### 💻 الوضع التفاعلي
```bash
gchat                      # بدء محادثة تفاعلية
ginteractive              # نفس الشيء
```

---

## 🛠️ الأدوات المتخصصة

### 📊 تحليل الكود

#### مراجعة سريعة
```bash
greview lib/main.dart
quick_code_review lib/services/api.dart
```
**يعطي:**
- تقييم عام (1-10)
- نقاط القوة والضعف
- اقتراحات للتحسين
- مشاكل الأمان والأداء

#### تحسين الكود
```bash
gimprove lib/widgets/custom_button.dart
improve_code lib/models/user.dart
```

#### توليد التوثيق
```bash
gdocs lib/services/auth_service.dart
generate_docs lib/utils/helpers.dart
```

### 🏥 أدوات Flutter

#### فحص صحة المشروع
```bash
gcheck                     # فحص المشروع الحالي
gcheck /path/to/project    # فحص مشروع محدد
flutter_health_check .
```

#### إضافة ميزة جديدة
```bash
gfeature . "نظام المصادقة"
gfeature . "صفحة الملف الشخصي"
add_flutter_feature . "نظام الإشعارات"
```

#### نصائح الأداء
```bash
gperf                      # للمشروع الحالي
performance_tips /path/to/project
```

#### تحديث المشروع
```bash
gupdate                    # للمشروع الحالي
update_project .
```

### 🐛 مساعدة التطوير

#### مساعدة debugging
```bash
gdebug "RenderFlex overflowed by 10 pixels"
debug_help "NoSuchMethodError: method not found"
debug_help "Failed to load network image"
```

---

## 💡 أمثلة عملية

### مثال 1: مراجعة كود جديد
```bash
# مراجعة ملف main.dart
greview lib/main.dart

# تحسين الكود بناءً على المراجعة
gimprove lib/main.dart

# توليد توثيق للكود المحسن
gdocs lib/main.dart
```

### مثال 2: إضافة ميزة جديدة
```bash
# فحص صحة المشروع أولاً
gcheck .

# إضافة ميزة نظام المصادقة
gfeature . "نظام مصادقة مع Firebase"

# فحص الأداء بعد الإضافة
gperf .
```

### مثال 3: حل مشكلة
```bash
# طلب مساعدة في خطأ محدد
gdebug "setState() called after dispose()"

# تحليل الكود المتعلق بالمشكلة
gcode lib/pages/profile_page.dart "كيف أتجنب استدعاء setState بعد dispose؟"
```

### مثال 4: تحسين مشروع موجود
```bash
# فحص شامل للمشروع
gcheck .

# نصائح لتحسين الأداء
gperf .

# اقتراحات للتحديث
gupdate .
```

---

## 🔧 التكوين المتقدم

### تعديل الإعدادات
```bash
# تغيير النموذج
gsmart --config model "gemini-1.5-pro"

# تعديل درجة الحرارة (الإبداع)
gsmart --config temperature "0.8"

# تعديل الحد الأقصى للكلمات
gsmart --config max_tokens "4096"

# تخصيص System Instruction
gsmart --config system_instruction "أنت خبير Flutter متخصص في الأداء والأمان"

# تفعيل/إلغاء تفعيل الذاكرة
gsmart --config enable_memory "true"
gsmart --config enable_memory "false"
```

### ملفات التكوين
```bash
# عرض مسار ملفات التكوين
ls -la ~/.gemini-enhanced/

# الملفات المهمة:
# ~/.gemini-enhanced/config.json      - الإعدادات
# ~/.gemini-enhanced/memory.json      - الذاكرة
# ~/.gemini-enhanced/context_cache.json - الكاش
```

---

## 🎯 ميزات متقدمة

### استخدام الملفات للسياق
```bash
# إضافة ملفات للسياق
gsmart -f lib/main.dart lib/models/user.dart "كيف يمكن تحسين هذا التطبيق؟"

# تحليل متعدد الملفات
gcode lib/services/*.dart "راجع جميع الخدمات وأعطني تقرير شامل"
```

### الذاكرة الذكية
```bash
# مثال على استخدام الذاكرة
gsmart "أعمل على تطبيق للتوصيل"
# ... بعد فترة
gsmart "كيف أضيف نظام تتبع الطلبات؟"  # سيتذكر أنك تعمل على تطبيق توصيل
```

### تحليل مشروع شامل
```bash
# تحليل بنية المشروع
gflutter . --structure

# فحص المتطلبات
gflutter . --deps

# تحليل شامل مع أسئلة محددة
gflutter . "كيف يمكنني تحسين بنية هذا المشروع؟"
```

---

## ⚡ نصائح للاستخدام الأمثل

### 1. استخدم الأوامر المختصرة
```bash
gask بدلاً من gsmart
greview بدلاً من quick_code_review
gcheck بدلاً من flutter_health_check
```

### 2. استفد من الذاكرة
- ابدأ بوصف مشروعك
- اطرح أسئلة متتالية مترابطة
- استخدم السياق المتراكم

### 3. اجمع بين الأدوات
```bash
# سير عمل متكامل
gcheck .                    # فحص المشروع
greview lib/main.dart       # مراجعة الكود الرئيسي
gperf .                     # نصائح الأداء
gfeature . "ميزة جديدة"    # إضافة ميزة
```

---

## 🐛 استكشاف الأخطاء

### مشاكل شائعة وحلولها

#### 1. "خطأ: لم يتم تعيين GEMINI_API_KEY"
```bash
# الحل
export GEMINI_API_KEY="your-api-key"
# أو
gsmart --config api_key "your-api-key"
```

#### 2. الأوامر غير موجودة
```bash
# إعادة تحميل الـ shell
source ~/.zshrc

# التحقق من وجود الملفات
ls -la ~/.gemini-enhanced/
```

#### 3. مشاكل في Python
```bash
# التحقق من Python
python3 --version

# تثبيت المتطلبات
pip3 install requests
```

#### 4. إعادة الإعداد الكامل
```bash
# تشغيل الإعداد مرة أخرى
./setup_gemini.sh
```

---

## 📚 أمثلة متقدمة

### تطوير تطبيق من الصفر
```bash
# 1. تحليل فكرة التطبيق
gsmart "أريد تطوير تطبيق لإدارة المهام، ما هي أفضل بنية؟"

# 2. إنشاء بنية المشروع
gfeature . "نظام إدارة المهام مع قاعدة بيانات محلية"

# 3. مراجعة الكود أثناء التطوير
greview lib/models/task.dart
greview lib/services/database_service.dart

# 4. تحسين الأداء
gperf .

# 5. إضافة ميزات جديدة
gfeature . "نظام إشعارات للمهام"
gfeature . "مزامنة مع التقويم"
```

### تحسين تطبيق موجود
```bash
# 1. فحص شامل
gcheck .

# 2. تحليل نقاط الضعف
gperf .

# 3. مراجعة الملفات الرئيسية
greview lib/main.dart
greview lib/services/api_service.dart

# 4. تحديث التقنيات
gupdate .

# 5. إضافة ميزات حديثة
gfeature . "دعم الوضع المظلم"
gfeature . "تحسين تجربة المستخدم"
```

---

## 🎉 خلاصة

تم تطبيق جميع التحسينات بنجاح! أصبح لديك الآن:

### ✅ ما تم تطبيقه:
- **Gemini CLI محسن** مع ذاكرة ذكية
- **أدوات تحليل متقدمة** للكود ومشاريع Flutter  
- **واجهات متعددة** (عادي، تفاعلي، تحليلي)
- **اختصارات سهلة** للاستخدام اليومي
- **ذاكرة السياق** للمحادثات المترابطة
- **أدوات debugging** وحل المشاكل
- **نصائح الأداء والتحسين**

### 🚀 ابدأ الآن:
```bash
# اختبار سريع
gsmart "مرحبا، هل تعمل؟"

# عرض جميع الأدوات
ghelpers

# تحليل مشروعك
gcheck .
```

### 📞 للمساعدة:
```bash
ghelp          # مساعدة عامة
ghelpers       # أدوات المساعدة
gconfig        # عرض الإعدادات
```

---

**استمتع بـ Gemini المحسن! 🎯** 