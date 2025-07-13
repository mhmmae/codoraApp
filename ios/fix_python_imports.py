#!/usr/bin/env python3
"""
سكريبت لإصلاح مشاكل استيراد Python في IDEs
"""

import sys
import os
import subprocess
import json
from pathlib import Path

def check_python_environment():
    """فحص بيئة Python"""
    print("🔍 فحص بيئة Python...")
    print(f"Python Version: {sys.version}")
    print(f"Python Executable: {sys.executable}")
    print(f"Python Path: {sys.path}")
    print(f"Current Directory: {os.getcwd()}")

def test_imports():
    """اختبار الاستيرادات الأساسية"""
    print("\n🧪 اختبار الاستيرادات...")

    modules = [
        'os', 'sys', 'json', 'uuid', 'datetime',
        'pathlib', 'hashlib', 'argparse', 'requests'
    ]

    for module in modules:
        try:
            __import__(module)
            print(f"✅ {module} - متوفر")
        except ImportError as e:
            print(f"❌ {module} - غير متوفر: {e}")

def create_vscode_settings():
    """إنشاء إعدادات VS Code"""
    vscode_dir = Path('.vscode')
    vscode_dir.mkdir(exist_ok=True)

    settings = {
        "python.defaultInterpreterPath": sys.executable,
        "python.linting.enabled": True,
        "python.linting.pylintEnabled": False,
        "python.linting.flake8Enabled": True,
        "python.formatting.provider": "black",
        "python.autoComplete.extraPaths": [
            "${workspaceFolder}/ios"
        ]
    }

    with open(vscode_dir / 'settings.json', 'w') as f:
        json.dump(settings, f, indent=2)

    print("\n✅ تم إنشاء إعدادات VS Code")

def create_pycharm_config():
    """إنشاء ملف إعدادات PyCharm"""
    idea_dir = Path('.idea')
    idea_dir.mkdir(exist_ok=True)

    # إنشاء ملف .iml للمشروع
    iml_content = f"""<?xml version="1.0" encoding="UTF-8"?>
<module type="PYTHON_MODULE" version="4">
  <component name="NewModuleRootManager">
    <content url="file://$MODULE_DIR$">
      <sourceFolder url="file://$MODULE_DIR$/ios" isTestSource="false" />
    </content>
    <orderEntry type="jdk" jdkName="Python {sys.version_info.major}.{sys.version_info.minor}" jdkType="Python SDK" />
    <orderEntry type="sourceFolder" forTests="false" />
  </component>
</module>"""

    with open(idea_dir / 'gemini_cli.iml', 'w') as f:
        f.write(iml_content)

    print("✅ تم إنشاء إعدادات PyCharm")

def create_init_files():
    """إنشاء ملفات __init__.py"""
    dirs_to_init = ['ios', 'ios/examples']

    for dir_path in dirs_to_init:
        init_file = Path(dir_path) / '__init__.py'
        if not init_file.exists():
            init_file.write_text('# This file makes the directory a Python package\n')
            print(f"✅ تم إنشاء {init_file}")

def create_requirements():
    """إنشاء ملف requirements.txt شامل"""
    requirements = """# المتطلبات الأساسية
requests>=2.25.0

# معالجة اللغة الطبيعية (اختياري)
nltk>=3.6
spacy>=3.0
textblob>=0.15.3
arabic-reshaper>=2.1.0
python-bidi>=0.4.2

# أدوات التطوير
black
flake8
mypy
"""

    with open('requirements.txt', 'w') as f:
        f.write(requirements)

    print("✅ تم إنشاء requirements.txt")

def fix_conversation_manager():
    """التأكد من صحة conversation_manager.py"""
    cm_path = Path('ios/conversation_manager.py')
    if cm_path.exists():
        # قراءة المحتوى
        content = cm_path.read_text(encoding='utf-8')

        # التأكد من وجود shebang
        if not content.startswith('#!/usr/bin/env python3'):
            content = '#!/usr/bin/env python3\n' + content
            cm_path.write_text(content, encoding='utf-8')
            print("✅ تم إضافة shebang line")

        # اختبار الاستيراد
        try:
            sys.path.insert(0, 'ios')
            import conversation_manager
            print("✅ conversation_manager.py يعمل بشكل صحيح")
        except Exception as e:
            print(f"❌ خطأ في conversation_manager.py: {e}")
        finally:
            sys.path.remove('ios')

def run_test_script():
    """تشغيل سكريبت اختبار بسيط"""
    test_script = """#!/usr/bin/env python3
# اختبار الاستيرادات
import os
import sys
import json
import uuid
from datetime import datetime, timedelta
from pathlib import Path
import hashlib

print("✅ جميع الاستيرادات تعمل بشكل صحيح!")

# اختبار conversation_manager
sys.path.append('ios')
try:
    from conversation_manager import ConversationManager
    cm = ConversationManager()
    print("✅ ConversationManager يعمل بشكل صحيح!")
except Exception as e:
    print(f"❌ خطأ في ConversationManager: {e}")
"""

    with open('test_imports.py', 'w') as f:
        f.write(test_script)

    # تشغيل الاختبار
    result = subprocess.run([sys.executable, 'test_imports.py'],
                          capture_output=True, text=True)
    print("\n📋 نتائج الاختبار:")
    print(result.stdout)
    if result.stderr:
        print("أخطاء:")
        print(result.stderr)

    # حذف ملف الاختبار
    os.remove('test_imports.py')

def main():
    print("🔧 إصلاح مشاكل استيراد Python")
    print("=" * 50)

    # الفحوصات
    check_python_environment()
    test_imports()

    # الإصلاحات
    print("\n🔨 تطبيق الإصلاحات...")
    create_init_files()
    create_requirements()
    create_vscode_settings()
    create_pycharm_config()
    fix_conversation_manager()

    # الاختبار
    print("\n🧪 تشغيل الاختبارات...")
    run_test_script()

    print("\n" + "=" * 50)
    print("✨ تم الانتهاء!")
    print("\n📌 خطوات إضافية مطلوبة:")
    print("1. في VS Code: اضغط Ctrl+Shift+P واختر 'Python: Select Interpreter'")
    print("2. في PyCharm: File > Settings > Project > Python Interpreter")
    print("3. أعد تشغيل IDE الخاص بك")
    print("4. في بعض الحالات، قد تحتاج لتشغيل: pip install -r requirements.txt")

if __name__ == "__main__":
    main()