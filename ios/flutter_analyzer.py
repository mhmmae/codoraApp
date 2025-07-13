#!/usr/bin/env python3
import sys
import os
import json
from pathlib import Path

def analyze_flutter_project(project_path, question=""):
    """تحليل مشروع Flutter"""
    project_path = Path(project_path)

    if not project_path.exists():
        return f"المسار غير موجود: {project_path}"

    # جمع معلومات المشروع
    analysis = "=== تحليل مشروع Flutter ===\n\n"

    # pubspec.yaml
    pubspec = project_path / "pubspec.yaml"
    if pubspec.exists():
        analysis += "--- pubspec.yaml ---\n"
        try:
            analysis += pubspec.read_text(encoding='utf-8')[:1500] + "\n\n"
        except Exception as e:
            analysis += f"خطأ في قراءة pubspec.yaml: {e}\n\n"

    # lib files
    lib_dir = project_path / "lib"
    if lib_dir.exists():
        dart_files = list(lib_dir.glob("**/*.dart"))[:10]  # أول 10 ملفات
        for dart_file in dart_files:
            analysis += f"--- {dart_file.relative_to(project_path)} ---\n"
            try:
                content = dart_file.read_text(encoding='utf-8')[:2000]
                analysis += content + "\n\n"
            except Exception as e:
                analysis += f"خطأ في قراءة الملف: {e}\n\n"

    # android/app/build.gradle للإعدادات المهمة
    android_gradle = project_path / "android" / "app" / "build.gradle"
    if android_gradle.exists():
        analysis += "--- android/app/build.gradle ---\n"
        try:
            content = android_gradle.read_text(encoding='utf-8')[:1000]
            analysis += content + "\n\n"
        except Exception as e:
            analysis += f"خطأ في قراءة build.gradle: {e}\n\n"

    # ios/Runner/Info.plist للإعدادات المهمة
    ios_info = project_path / "ios" / "Runner" / "Info.plist"
    if ios_info.exists():
        analysis += "--- ios/Runner/Info.plist ---\n"
        try:
            content = ios_info.read_text(encoding='utf-8')[:1000]
            analysis += content + "\n\n"
        except Exception as e:
            analysis += f"خطأ في قراءة Info.plist: {e}\n\n"

    # تشغيل التحليل
    sys.path.append(os.path.expanduser('~/.gemini-enhanced'))
    try:
        from gemini_smart import EnhancedGeminiCLI
        cli = EnhancedGeminiCLI()

        if question:
            full_prompt = f"{analysis}\n\nالسؤال: {question}\n\nيرجى تحليل مشروع Flutter والإجابة على السؤال."
        else:
            full_prompt = f"{analysis}\n\nيرجى تحليل هذا المشروع Flutter وتقديم ملخص عن بنيته ومكوناته الرئيسية ونصائح للتحسين."

        return cli.call_gemini_api(full_prompt)
    except ImportError:
        return "خطأ: لم يتم العثور على gemini_smart.py"
    except Exception as e:
        return f"خطأ في التحليل: {e}"

def get_project_structure(project_path):
    """عرض بنية المشروع"""
    project_path = Path(project_path)
    structure = "بنية المشروع:\n"

    important_paths = [
        "lib/",
        "android/app/",
        "ios/Runner/",
        "test/",
        "assets/",
        "fonts/"
    ]

    for path in important_paths:
        full_path = project_path / path
        if full_path.exists():
            structure += f"\n{path}\n"
            if full_path.is_dir():
                try:
                    files = list(full_path.iterdir())[:10]  # أول 10 عناصر
                    for file in files:
                        structure += f"  - {file.name}\n"
                    if len(list(full_path.iterdir())) > 10:
                        structure += f"  ... و {len(list(full_path.iterdir())) - 10} ملف إضافي\n"
                except Exception:
                    structure += "  (خطأ في قراءة المجلد)\n"

    return structure

def check_flutter_dependencies(project_path):
    """فحص dependencies المشروع"""
    pubspec = Path(project_path) / "pubspec.yaml"
    if not pubspec.exists():
        return "لم يتم العثور على pubspec.yaml"

    try:
        content = pubspec.read_text(encoding='utf-8')

        # استخراج معلومات مهمة
        info = "معلومات المشروع:\n"

        lines = content.split('\n')
        for line in lines:
            if 'name:' in line:
                info += f"اسم المشروع: {line.strip()}\n"
            elif 'version:' in line:
                info += f"الإصدار: {line.strip()}\n"
            elif 'flutter:' in line and 'sdk:' in line:
                info += f"Flutter SDK: {line.strip()}\n"

        return info
    except Exception as e:
        return f"خطأ في قراءة pubspec.yaml: {e}"

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("الاستخدام:")
        print("  flutter_analyzer.py <مسار_المشروع> [سؤال]")
        print("  flutter_analyzer.py <مسار_المشروع> --structure")
        print("  flutter_analyzer.py <مسار_المشروع> --deps")
        sys.exit(1)

    project_path = sys.argv[1]

    if len(sys.argv) > 2 and sys.argv[2] == "--structure":
        result = get_project_structure(project_path)
        print(result)
    elif len(sys.argv) > 2 and sys.argv[2] == "--deps":
        result = check_flutter_dependencies(project_path)
        print(result)
    else:
        question = " ".join(sys.argv[2:]) if len(sys.argv) > 2 else ""
        result = analyze_flutter_project(project_path, question)
        print(result)