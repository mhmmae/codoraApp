#!/usr/bin/env python3
"""
اختبار شامل لـ conversation_manager.py
"""

import sys
import os

# اختبار جميع الاستيرادات
print("🧪 اختبار الاستيرادات الأساسية...")

try:
    import os
    print("✅ os - تم الاستيراد بنجاح")
except ImportError as e:
    print(f"❌ os - فشل الاستيراد: {e}")

try:
    import sys
    print("✅ sys - تم الاستيراد بنجاح")
except ImportError as e:
    print(f"❌ sys - فشل الاستيراد: {e}")

try:
    import json
    print("✅ json - تم الاستيراد بنجاح")
except ImportError as e:
    print(f"❌ json - فشل الاستيراد: {e}")

try:
    import uuid
    print("✅ uuid - تم الاستيراد بنجاح")
except ImportError as e:
    print(f"❌ uuid - فشل الاستيراد: {e}")

try:
    from datetime import datetime, timedelta
    print("✅ datetime - تم الاستيراد بنجاح")
except ImportError as e:
    print(f"❌ datetime - فشل الاستيراد: {e}")

try:
    from pathlib import Path
    print("✅ pathlib - تم الاستيراد بنجاح")
except ImportError as e:
    print(f"❌ pathlib - فشل الاستيراد: {e}")

try:
    import hashlib
    print("✅ hashlib - تم الاستيراد بنجاح")
except ImportError as e:
    print(f"❌ hashlib - فشل الاستيراد: {e}")

# اختبار استيراد ConversationManager
print("\n🧪 اختبار استيراد ConversationManager...")
try:
    from conversation_manager import ConversationManager
    print("✅ ConversationManager - تم الاستيراد بنجاح")

    # اختبار إنشاء instance
    cm = ConversationManager()
    print("✅ تم إنشاء ConversationManager instance بنجاح")

    # اختبار الوظائف الأساسية
    print("\n🧪 اختبار الوظائف الأساسية...")

    # إنشاء محادثة
    conv_id = cm.create_conversation("محادثة اختبارية")
    print(f"✅ تم إنشاء محادثة بمعرف: {conv_id}")

    # إضافة رسالة
    success = cm.add_message(conv_id, "مرحبا", "أهلاً وسهلاً!")
    if success:
        print("✅ تم إضافة رسالة بنجاح")

    # قراءة المحادثة
    conv = cm.get_conversation(conv_id)
    if conv:
        print("✅ تم قراءة المحادثة بنجاح")
        print(f"   - العنوان: {conv['title']}")
        print(f"   - عدد الرسائل: {len(conv['messages'])}")

    # حذف المحادثة
    if cm.delete_conversation(conv_id):
        print("✅ تم حذف المحادثة بنجاح")

except ImportError as e:
    print(f"❌ ConversationManager - فشل الاستيراد: {e}")
except Exception as e:
    print(f"❌ خطأ في اختبار ConversationManager: {e}")

print("\n" + "="*50)
print("✅ اكتمل الاختبار!")
print("\n📌 معلومات إضافية:")
print(f"Python Version: {sys.version}")
print(f"Current Directory: {os.getcwd()}")
print(f"Python Path: {sys.path[:3]}...")  # أول 3 مسارات فقط