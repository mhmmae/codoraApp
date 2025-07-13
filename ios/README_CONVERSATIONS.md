# 🔥 نظام إدارة المحادثات المحسن لـ Gemini CLI

## نظرة عامة
تم تطوير نظام متقدم لحفظ وإدارة المحادثات مع Gemini CLI، مما يتيح لك:
- **حفظ تلقائي** لجميع المحادثات
- **استكمال المحادثات** السابقة
- **البحث** في المحادثات المحفوظة
- **تنظيم وترتيب** المحادثات بالعناوين والعلامات
- **تصدير** المحادثات

---

## 🚀 المميزات الجديدة

### ✨ الحفظ التلقائي
- كل سؤال وإجابة يُحفظ تلقائياً
- لا حاجة لإعدادات إضافية
- يعمل مع جميع أنواع الاستعلامات

### 🔍 البحث المتقدم
- بحث في عناوين المحادثات
- بحث في محتوى الأسئلة والإجابات
- نتائج مرتبة حسب الصلة

### 📊 التنظيم الذكي
- عناوين تلقائية أو مخصصة
- ترتيب حسب التاريخ
- عرض عدد الرسائل لكل محادثة

---

## 📋 الأوامر الأساسية

### إدارة المحادثات

```bash
# عرض قائمة المحادثات
glist

# إنشاء محادثة جديدة
gnew "عنوان المحادثة"
gnew  # بدون عنوان - يتم إنشاء عنوان تلقائي

# تحميل محادثة محددة
gload <conversation_id>

# عرض المحادثة الحالية
gshow
gcurrent

# عرض محادثة محددة
gshow <conversation_id>
```

### البحث والاستعلام

```bash
# البحث في المحادثات
gsearch "كلمة البحث"

# سؤال سريع (يُحفظ في المحادثة الحالية)
gask "سؤالك هنا"
```

### الإدارة المتقدمة

```bash
# حذف محادثة
gdelete <conversation_id>

# تصدير محادثة
gexport <conversation_id>

# الوضع التفاعلي المحسن
gchat
```

---

## 🎯 أمثلة عملية

### مثال 1: إنشاء مشروع جديد
```bash
# إنشاء محادثة لمشروع Flutter جديد
gnew "مشروع تطبيق التسوق - Flutter"

# طرح أسئلة حول المشروع
gask "ما هي أفضل بنية للمشروع؟"
gask "كيف أتعامل مع إدارة الحالة؟"
gask "ما هي الpackages المطلوبة؟"

# عرض المحادثة الحالية
gshow
```

### مثال 2: البحث في المحادثات السابقة
```bash
# البحث عن حلول مشاكل Flutter
gsearch "flutter error"
gsearch "build failed"
gsearch "performance"

# تحميل محادثة قديمة للمراجعة
gload a1b2c3d4
```

### مثال 3: العمل على مشاريع متعددة
```bash
# عرض جميع المحادثات
glist

# التبديل بين المشاريع
gload project1_id  # الانتقال لمشروع التسوق
gask "كيف أضيف ميزة الدفع؟"

gload project2_id  # الانتقال لمشروع آخر
gask "كيف أحسن الأداء؟"
```

---

## 💡 الوضع التفاعلي

استخدم `gchat` للدخول في وضع محادثة تفاعلي محسن:

```bash
gchat
```

الأوامر المتاحة في الوضع التفاعلي:
- `conversations` أو `list` - عرض المحادثات
- `new [title]` - إنشاء محادثة جديدة
- `load <id>` - تحميل محادثة
- `current` أو `show` - عرض المحادثة الحالية
- `search <term>` - البحث
- `exit` أو `quit` - خروج

---

## 📁 هيكل البيانات

### مجلد التخزين
```
~/.gemini-enhanced/
├── conversations/           # مجلد المحادثات
│   ├── a1b2c3d4.json       # ملفات المحادثات
│   └── e5f6g7h8.json
├── conversations_index.json # فهرس المحادثات
└── current_conversation.txt # المحادثة الحالية
```

### بنية ملف المحادثة
```json
{
  "id": "a1b2c3d4",
  "title": "مشروع Flutter الجديد",
  "created_at": "2025-07-02T10:30:00",
  "last_updated": "2025-07-02T11:45:00",
  "messages": [
    {
      "timestamp": "2025-07-02T10:30:00",
      "prompt": "كيف أبدأ مشروع Flutter؟",
      "response": "يمكنك البدء بـ...",
      "context_info": {
        "enhanced_prompt": false,
        "files_count": 0
      }
    }
  ],
  "tags": ["flutter", "mobile"],
  "summary": ""
}
```

---

## 🔧 الإعدادات المتقدمة

### تخصيص عرض المحادثات
```bash
# عرض عدد معين من المحادثات
python3 ~/.gemini-enhanced/gemini_smart.py --list-conversations | head -10

# البحث مع حد أقصى للنتائج
gsearch "flutter" | head -5
```

### تصدير البيانات
```bash
# تصدير محادثة كملف نصي
gexport a1b2c3d4

# تصدير كـ JSON (للأدوات المتقدمة)
python3 ~/.gemini-enhanced/gemini_smart.py --export-conversation a1b2c3d4 --format json
```

---

## 🎨 التخصيص

### إضافة aliases شخصية
أضف هذه الأسطر إلى ملف `~/.zshrc`:

```bash
# اختصارات شخصية للمحادثات
alias gwork="gload work_project_id"      # التبديل لمشروع العمل
alias gpersonal="gload personal_id"      # التبديل للمشاريع الشخصية
alias gflutter="gsearch flutter"         # بحث سريع عن Flutter
alias grecent="glist | head -5"         # آخر 5 محادثات
```

### إضافة علامات للمحادثات
يمكنك إضافة علامات للمحادثات عبر Python:

```python
from conversation_manager import ConversationManager
cm = ConversationManager()
cm.add_tags("conversation_id", ["flutter", "mobile", "work"])
```

---

## 🐛 استكشاف الأخطاء

### مشاكل شائعة

**1. لا تظهر المحادثات:**
```bash
# تحقق من وجود المجلد
ls -la ~/.gemini-enhanced/conversations/

# تحقق من صحة فهرس المحادثات
cat ~/.gemini-enhanced/conversations_index.json
```

**2. خطأ في تحميل محادثة:**
```bash
# تحقق من وجود المحادثة
ls ~/.gemini-enhanced/conversations/conversation_id.json

# إعادة إنشاء الفهرس (إذا تالف)
python3 -c "
from conversation_manager import ConversationManager
cm = ConversationManager()
print('تم إعادة بناء الفهرس')
"
```

**3. المحادثة الحالية غير صحيحة:**
```bash
# إعادة تعيين المحادثة الحالية
rm ~/.gemini-enhanced/current_conversation.txt
gnew "محادثة جديدة"
```

---

## 📈 نصائح للاستخدام الأمثل

### 1. تنظيم المحادثات
- استخدم عناوين وصفية للمحادثات
- أنشئ محادثة منفصلة لكل مشروع
- استخدم البحث للعثور على المحادثات بسرعة

### 2. الاستفادة من السياق
- حافظ على استمرارية المحادثة في نفس المشروع
- استخدم `gshow` لمراجعة السياق قبل طرح أسئلة جديدة

### 3. النسخ الاحتياطي
```bash
# نسخ احتياطي للمحادثات
cp -r ~/.gemini-enhanced/conversations ~/backup_conversations_$(date +%Y%m%d)

# أو تصدير محادثات مهمة
for id in important_id1 important_id2; do
    gexport $id
done
```

---

## 🔄 التحديثات المستقبلية

### ميزات مخططة
- [ ] ربط المحادثات (المحادثات ذات الصلة)
- [ ] تصنيف تلقائي للمحادثات
- [ ] ملخصات ذكية للمحادثات الطويلة
- [ ] مزامنة مع التخزين السحابي
- [ ] واجهة ويب للمحادثات

### مساهمة في التطوير
- الملفات الأساسية: `conversation_manager.py`, `gemini_smart.py`
- اقتراح ميزات: افتح issue في المشروع
- تحسينات: أرسل pull request

---

## 📞 الدعم

### الحصول على مساعدة
```bash
# دليل الاستخدام
ghelpconv

# الدعم التقني
gask "لدي مشكلة في نظام المحادثات"
```

### الموارد المفيدة
- [Gemini AI Documentation](https://ai.google.dev/)
- [Python JSON Handling](https://docs.python.org/3/library/json.html)
- [Shell Scripting Guide](https://www.shellscript.sh/)

---

**🎉 تهانينا! أصبح لديك الآن نظام محادثات متقدم يحفظ تلقائياً جميع محادثاتك مع Gemini ويتيح لك استكمالها في أي وقت!** 