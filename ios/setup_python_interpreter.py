#!/usr/bin/env python3
"""
سكريبت لإعداد Python Interpreter في مختلف IDEs
"""

import os
import sys
import json
import subprocess
from pathlib import Path

def get_python_info():
    """الحصول على معلومات Python"""
    info = {
        'executable': sys.executable,
        'version': sys.version,
        'version_info': f"{sys.version_info.major}.{sys.version_info.minor}.{sys.version_info.micro}",
        'prefix': sys.prefix,
        'base_prefix': sys.base_prefix,
        'platform': sys.platform
    }
    return info

def create_pycharm_config():
    """إنشاء إعدادات PyCharm"""
    print("🔧 إعداد PyCharm...")

    # المسار الرئيسي للمشروع
    project_root = Path.cwd().parent
    idea_dir = project_root / '.idea'
    idea_dir.mkdir(exist_ok=True)

    # إنشاء misc.xml
    python_info = get_python_info()
    misc_xml = f"""<?xml version="1.0" encoding="UTF-8"?>
<project version="4">
  <component name="ProjectRootManager" version="2" project-jdk-name="Python {python_info['version_info']}" project-jdk-type="Python SDK" />
</project>"""

    with open(idea_dir / 'misc.xml', 'w') as f:
        f.write(misc_xml)

    # إنشاء modules.xml
    modules_xml = """<?xml version="1.0" encoding="UTF-8"?>
<project version="4">
  <component name="ProjectModuleManager">
    <modules>
      <module fileurl="file://$PROJECT_DIR$/.idea/gemini_cli.iml" filepath="$PROJECT_DIR$/.idea/gemini_cli.iml" />
    </modules>
  </component>
</project>"""

    with open(idea_dir / 'modules.xml', 'w') as f:
        f.write(modules_xml)

    # إنشاء gemini_cli.iml
    iml_content = f"""<?xml version="1.0" encoding="UTF-8"?>
<module type="PYTHON_MODULE" version="4">
  <component name="NewModuleRootManager">
    <content url="file://$MODULE_DIR$">
      <sourceFolder url="file://$MODULE_DIR$/ios" isTestSource="false" />
      <excludeFolder url="file://$MODULE_DIR$/venv" />
      <excludeFolder url="file://$MODULE_DIR$/.venv" />
    </content>
    <orderEntry type="jdk" jdkName="Python {python_info['version_info']}" jdkType="Python SDK" />
    <orderEntry type="sourceFolder" forTests="false" />
  </component>
  <component name="PyDocumentationSettings">
    <option name="format" value="PLAIN" />
    <option name="myDocStringFormat" value="Plain" />
  </component>
</module>"""

    with open(idea_dir / 'gemini_cli.iml', 'w') as f:
        f.write(iml_content)

    print("✅ تم إنشاء إعدادات PyCharm")
    print(f"   - Python Path: {python_info['executable']}")

def create_vscode_config():
    """إنشاء إعدادات VS Code"""
    print("\n🔧 إعداد VS Code...")

    project_root = Path.cwd().parent
    vscode_dir = project_root / '.vscode'
    vscode_dir.mkdir(exist_ok=True)

    python_info = get_python_info()

    settings = {
        "python.defaultInterpreterPath": python_info['executable'],
        "python.autoComplete.extraPaths": [
            "${workspaceFolder}/ios",
            "${workspaceFolder}"
        ],
        "python.analysis.extraPaths": [
            "${workspaceFolder}/ios",
            "${workspaceFolder}"
        ],
        "python.linting.enabled": true,
        "python.linting.pylintEnabled": false,
        "python.terminal.activateEnvironment": false,
        "python.analysis.autoImportCompletions": true,
        "python.analysis.typeCheckingMode": "basic",
        "files.associations": {
            "*.py": "python"
        }
    }

    with open(vscode_dir / 'settings.json', 'w') as f:
        json.dump(settings, f, indent=2)

    # إنشاء launch.json للتصحيح
    launch_config = {
        "version": "0.2.0",
        "configurations": [
            {
                "name": "Python: Gemini CLI",
                "type": "python",
                "request": "launch",
                "program": "${workspaceFolder}/ios/gemini_smart.py",
                "console": "integratedTerminal",
                "justMyCode": true,
                "cwd": "${workspaceFolder}/ios"
            }
        ]
    }

    with open(vscode_dir / 'launch.json', 'w') as f:
        json.dump(launch_config, f, indent=2)

    print("✅ تم إنشاء إعدادات VS Code")
    print(f"   - Python Path: {python_info['executable']}")

def create_sublime_config():
    """إنشاء إعدادات Sublime Text"""
    print("\n🔧 إعداد Sublime Text...")

    project_root = Path.cwd().parent
    python_info = get_python_info()

    sublime_project = {
        "folders": [
            {
                "path": ".",
                "folder_exclude_patterns": ["__pycache__", ".git", "venv"],
                "file_exclude_patterns": ["*.pyc"]
            }
        ],
        "settings": {
            "python_interpreter": python_info['executable'],
            "sublimeLinter.linters.flake8.executable": python_info['executable'],
            "sublimeLinter.linters.pylint.executable": python_info['executable']
        }
    }

    with open(project_root / 'gemini_cli.sublime-project', 'w') as f:
        json.dump(sublime_project, f, indent=2)

    print("✅ تم إنشاء إعدادات Sublime Text")

def check_python_installation():
    """فحص تثبيت Python"""
    print("🔍 فحص Python...")

    python_info = get_python_info()

    print(f"✅ Python موجود:")
    print(f"   - المسار: {python_info['executable']}")
    print(f"   - الإصدار: {python_info['version_info']}")
    print(f"   - النظام: {python_info['platform']}")

    # فحص الوحدات الأساسية
    print("\n🔍 فحص الوحدات الأساسية...")
    modules = ['os', 'sys', 'json', 'uuid', 'datetime', 'pathlib', 'hashlib']

    all_ok = True
    for module in modules:
        try:
            __import__(module)
            print(f"   ✅ {module}")
        except ImportError:
            print(f"   ❌ {module}")
            all_ok = False

    if all_ok:
        print("\n✅ جميع الوحدات الأساسية متوفرة!")
    else:
        print("\n⚠️  بعض الوحدات مفقودة - قد تحتاج لإعادة تثبيت Python")

    return all_ok

def create_pyproject_toml():
    """إنشاء pyproject.toml للمشروع"""
    print("\n🔧 إنشاء pyproject.toml...")

    project_root = Path.cwd().parent
    python_info = get_python_info()

    pyproject = f"""[tool.poetry]
name = "gemini-cli"
version = "2.0.0"
description = "Gemini CLI with advanced features"
authors = ["Your Name <email@example.com>"]
readme = "README.md"
packages = [{{include = "ios"}}]

[tool.poetry.dependencies]
python = "^{sys.version_info.major}.{sys.version_info.minor}"
requests = "^2.31.0"

[tool.poetry.group.dev.dependencies]
pytest = "^7.4.0"
black = "^23.7.0"
flake8 = "^6.1.0"

[build-system]
requires = ["poetry-core"]
build-backend = "poetry.core.masonry.api"

[tool.black]
line-length = 88
target-version = ['py{sys.version_info.major}{sys.version_info.minor}']

[tool.pylint]
max-line-length = 88
disable = ["C0111", "C0103"]
"""

    with open(project_root / 'pyproject.toml', 'w') as f:
        f.write(pyproject)

    print("✅ تم إنشاء pyproject.toml")

def fix_shebang_lines():
    """إصلاح shebang lines في ملفات Python"""
    print("\n🔧 إصلاح shebang lines...")

    count = 0
    for py_file in Path.cwd().glob('*.py'):
        with open(py_file, 'r', encoding='utf-8') as f:
            content = f.read()

        if not content.startswith('#!/usr/bin/env python3'):
            content = '#!/usr/bin/env python3\n' + content
            with open(py_file, 'w', encoding='utf-8') as f:
                f.write(content)
            count += 1
            print(f"   ✅ {py_file.name}")

    if count > 0:
        print(f"✅ تم إصلاح {count} ملف")
    else:
        print("✅ جميع الملفات تحتوي على shebang صحيح")

def main():
    print("🚀 إعداد Python Interpreter لجميع IDEs")
    print("=" * 60)

    # فحص Python
    if not check_python_installation():
        print("\n❌ هناك مشكلة في تثبيت Python!")
        return

    # إنشاء الإعدادات
    try:
        create_vscode_config()
    except Exception as e:
        print(f"⚠️  فشل إنشاء إعدادات VS Code: {e}")

    try:
        create_pycharm_config()
    except Exception as e:
        print(f"⚠️  فشل إنشاء إعدادات PyCharm: {e}")

    try:
        create_sublime_config()
    except Exception as e:
        print(f"⚠️  فشل إنشاء إعدادات Sublime: {e}")

    try:
        create_pyproject_toml()
    except Exception as e:
        print(f"⚠️  فشل إنشاء pyproject.toml: {e}")

    fix_shebang_lines()

    print("\n" + "=" * 60)
    print("✅ تم الانتهاء!")
    print("\n📋 الخطوات التالية:")
    print("1. أعد تشغيل IDE الخاص بك")
    print("2. في VS Code: اضغط Ctrl+Shift+P > Python: Select Interpreter")
    print("3. في PyCharm: File > Reload Project from Disk")
    print("4. اختر Python interpreter المعروض")

    python_info = get_python_info()
    print(f"\n💡 Python Path للنسخ:")
    print(f"   {python_info['executable']}")

if __name__ == "__main__":
    main()