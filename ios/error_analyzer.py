"""
نظام تحليل الأخطاء المتقدم لـ Gemini CLI
يوفر قدرات ذكية للتعرف على الأخطاء وإيجاد أفضل الحلول
"""
import os
import sys
import re
import json
import ast
import traceback
import subprocess
from pathlib import Path
from typing import Dict, List, Tuple, Optional, Any
from datetime import datetime
from dataclasses import dataclass, field
from enum import Enum
import difflib
import requests
import argparse  # <-- الإصلاح رقم 1: تمت إضافة الاستيراد المفقود
import google.generativeai as genai  # <--- أضف هذا السطر هنا

import hashlib


# نفترض أن هذه الوحدات موجودة في نفس المجلد أو يمكن الوصول إليها
# from feedback_manager import FeedbackManager
# from knowledge_harvester import KnowledgeHarvester
# from tools.default_api import google_web_search

# --- فئات وعناصر نائبة (Placeholders) للتبعيات ---
# في حال عدم وجود الملفات الفعلية، هذه الفئات تسمح للكود بالعمل
class FeedbackManager:
    """فئة وهمية لإدارة ملاحظات المستخدمين."""

    def get_all_feedback(self): return []

    def add_feedback(self, **kwargs): pass


class KnowledgeHarvester:
    """فئة وهمية لجمع المعرفة من مصادر خارجية."""

    def get_knowledge(self, message): return []

    def process_search_results(self, message, results): pass


def google_web_search(query: str) -> List[Dict[str, str]]:
    """دالة وهمية لمحاكاة البحث على الويب."""
    print(f"--> [Placeholder] Searching web for: {query}")
    return [{"source": "stackoverflow.com/example", "solution": "Check your import paths.",
             "summary": "Often a result of misconfigured PYTHONPATH."}]


# --- نهاية العناصر النائبة ---


# أنواع الأخطاء المدعومة
class ErrorType(Enum):
    SYNTAX = "syntax"
    RUNTIME = "runtime"
    LOGIC = "logic"
    PERFORMANCE = "performance"
    SECURITY = "security"
    STYLE = "style"
    IMPORT = "import"
    TYPE = "type"
    UNDEFINED = "undefined"
    DEPRECATED = "deprecated"


# مستويات الخطورة
class ErrorSeverity(Enum):
    CRITICAL = 5  # يمنع تشغيل البرنامج
    HIGH = 4  # خطر على الأداء أو الأمان
    MEDIUM = 3  # مشكلة في المنطق أو الجودة
    LOW = 2  # تحسينات مقترحة
    INFO = 1  # معلومات إضافية


@dataclass
class Error:
    """تمثيل للخطأ المكتشف"""
    type: ErrorType
    severity: ErrorSeverity
    message: str
    file_path: Optional[str] = None
    line_number: Optional[int] = None
    column_number: Optional[int] = None
    code_snippet: Optional[str] = None
    context: Dict[str, Any] = field(default_factory=dict)
    solutions: List['Solution'] = field(default_factory=list)


@dataclass
class Solution:
    """حل مقترح للخطأ"""
    description: str
    code_fix: Optional[str] = None
    confidence: float = 0.0  # من 0 إلى 1
    explanation: Optional[str] = None
    references: List[str] = field(default_factory=list)
    auto_applicable: bool = False
    side_effects: List[str] = field(default_factory=list)


class SolutionEngine:
    """
    محرك توليد حلول ذكي، صلب وفعال.
    يستخدم Gemini API مع التخزين المؤقت لتحسين الأداء وتقليل التكلفة.
    """

    def __init__(self, cache_dir: str = ".gemini_cli_cache"):
        """
        يقوم بإعداد المحرك، التحقق من مفتاح API، وتهيئة مجلد التخزين المؤقت.
        """
        # --- التحسين 1: معالجة خطأ مفتاح API بشكل احترافي ---
        try:
            api_key = os.environ["GEMINI_API_KEY"]
            genai.configure(api_key=api_key)
        except KeyError:
            raise ValueError(
                "خطأ: متغير البيئة GEMINI_API_KEY غير موجود. يرجى إعداده قبل تشغيل الأداة.")

        self.model = genai.GenerativeModel('gemini-1.5-pro-latest')

        # --- التحسين 2: إعداد نظام التخزين المؤقت (Caching) ---
        self.cache_path = Path(cache_dir)
        self.cache_path.mkdir(exist_ok=True)  # إنشاء مجلد الكاش إذا لم يكن موجودًا

    def _get_cache_key(self, error: Error, file_content: str) -> str:
        """
        ينشئ بصمة فريدة للخطأ ومحتوى الملف لتكون مفتاحًا للتخزين المؤقت.
        """
        # نستخدم دالة هاش لضمان مفتاح ثابت الطول وآمن للملفات.
        hasher = hashlib.sha256()
        # نضم كل المعلومات التي قد تؤثر على الحل
        unique_string = (
                str(error.file_path) +
                str(error.line_number) +
                str(error.type) +
                error.message +
                file_content  # مهم: إذا تغير الملف، يجب أن يتغير الحل
        )
        hasher.update(unique_string.encode('utf-8'))
        return hasher.hexdigest()

    def generate_solutions(self, error: Error) -> List[Solution]:
        """
        يولد حلولاً للخطأ، ويستخدم الكاش أولاً لتجنب استدعاءات API المتكررة.
        """
        # --- التحسين 1 (جزء 2): معالجة خطأ قراءة الملف بوضوح ---
        full_file_content = ""
        if error.file_path and os.path.exists(error.file_path):
            try:
                with open(error.file_path, 'r', encoding='utf-8') as f:
                    full_file_content = f.read()
            except Exception as e:
                print(f"--> [Warning] Could not read file {error.file_path}: {e}")
        else:
            print(
                "--> [Warning] File path not provided or file does not exist. Analysis quality may be lower.")

        # --- التحسين 2 (جزء 2): التحقق من الكاش أولاً ---
        cache_key = self._get_cache_key(error, full_file_content)
        cache_file = self.cache_path / f"{cache_key}.json"

        if cache_file.exists():
            # --- التحسين 3: تحسين تجربة المستخدم ---
            print(f"--> Found solution for '{error.message}' in cache. Using stored result.")
            with open(cache_file, 'r', encoding='utf-8') as f:
                cached_data = json.load(f)
            return self._parse_gemini_response(cached_data)

        # إذا لم يكن الحل في الكاش، قم باستدعاء Gemini API
        prompt = self._build_prompt_for_gemini(error, full_file_content)

        # --- التحسين 3 (جزء 2): إعلام المستخدم بالعملية ---
        print(f"--> Contacting Gemini for deep analysis of '{error.message}'...")

        try:
            response = self.model.generate_content(
                prompt,
                generation_config=genai.types.GenerationConfig(
                    response_mime_type="application/json"
                )
            )
            print("--> Analysis received from Gemini.")

            solutions_data = json.loads(response.text)

            # --- التحسين 2 (جزء 3): حفظ النتيجة الجديدة في الكاش ---
            with open(cache_file, 'w', encoding='utf-8') as f:
                json.dump(solutions_data, f, indent=2, ensure_ascii=False)

            return self._parse_gemini_response(solutions_data)

        except Exception as e:
            # معالجة أخطاء الـ API برسالة واضحة
            print(f"--> [Gemini API Error] Failed to generate solutions: {e}")
            # نرجع حلًا فارغًا بدلاً من تعطيل البرنامج بالكامل
            return [Solution(
                description=f"Failed to contact Gemini for a solution due to an API error: {e}")]

    def _build_prompt_for_gemini(self, error: Error, file_content: str) -> str:
        """يبني موجهًا مفصلاً لـ Gemini (نفس الموجه القوي السابق)."""
        # هذا الموجه ممتاز بالفعل، لذا لا نحتاج لتغييره
        # ... (نفس كود بناء الموجه من الإصدار السابق)
        prompt = f"""
        You are an expert-level software engineer and code analyzer. Your task is to analyze a reported error within a source code file and provide the best possible solutions.

        **Error Analysis Request:**

        1.  **Project Context:**
            *   File Path: `{error.file_path}`
            *   Error Type: `{error.type.name}`
            *   Severity: `{error.severity.name}`
            *   Error Message: `{error.message}`
            *   Line Number: `{error.line_number}`
            *   Code Snippet Around Error:
                ```
                {error.code_snippet}
                ```

        2.  **Full File Content (if available):**
            ```
            {file_content if file_content else "File content is not available."}
            ```

        3.  **Task:**
            Analyze the error in the context of the full file. Provide a list of potential solutions. For each solution:
            - Provide a concise `description`.
            - Suggest the corrected `code_fix`. The fix should be the exact code to replace the faulty lines.
            - Provide a confidence score (`confidence`) from 0.0 to 1.0.
            - Provide a detailed `explanation` of why this solution works.
            - List any potential `side_effects` or considerations.
            - Determine if the fix is `auto_applicable` (True if it can be applied programmatically without user intervention).
            - List any web `references` (e.g., StackOverflow links, official documentation) that support this solution.

        **Output Format:**
        Respond ONLY with a valid JSON object representing a list of solutions, following this schema:
        [
            {{
                "description": "...",
                "code_fix": "...",
                "confidence": 0.95,
                "explanation": "...",
                "side_effects": ["...", "..."],
                "auto_applicable": true,
                "references": ["..."]
            }}
        ]
        """
        return prompt

    def _parse_gemini_response(self, response_json: List[Dict]) -> List[Solution]:
        """يحلل استجابة JSON ويحولها إلى قائمة من كائنات Solution (نفس الكود الآمن السابق)."""
        if not isinstance(response_json, list):
            print(f"--> [Warning] Gemini returned a non-list response: {response_json}")
            return []

        solutions = []
        for sol_data in response_json:
            solutions.append(Solution(
                description=sol_data.get('description', 'No description provided.'),
                code_fix=sol_data.get('code_fix'),
                confidence=float(sol_data.get('confidence', 0.0)),
                explanation=sol_data.get('explanation'),
                references=sol_data.get('references', []),
                auto_applicable=bool(sol_data.get('auto_applicable', False)),
                side_effects=sol_data.get('side_effects', [])
            ))
        return solutions

    def get_refactoring_suggestions(self, file_path: str) -> None:
        """
        يحلل ملفًا ويطلب من Gemini اقتراحات لإعادة هيكلته.
        """
        print(f"Analyzing {file_path} for refactoring opportunities...")
        try:
            with open(file_path, 'r', encoding='utf-8') as f:
                content = f.read()
        except FileNotFoundError:
            print(f"--> [Error] File not found: {file_path}")
            return
        except Exception as e:
            print(f"--> [Error] Could not read file {file_path}: {e}")
            return

        prompt = self._build_refactor_prompt(content, file_path)

        print("--> Contacting Gemini for refactoring suggestions...")
        try:
            response = self.model.generate_content(prompt)
            print("--- Gemini's Refactoring Report ---")
            # نطبع الاستجابة مباشرة كنص لأنها ستكون تقريرًا مقروءًا
            print(response.text)
            print("-----------------------------------")
        except Exception as e:
            print(f"--> [Gemini API Error] Failed to get refactoring suggestions: {e}")

    def _build_refactor_prompt(self, code_content: str, file_name: str) -> str:
        """
        يبني موجهًا مخصصًا لطلب اقتراحات إعادة الهيكلة.
        """
        # --- تعديل طفيف للموجه ليكون متوافقًا مع Dart ---
        language = 'Dart' if file_name.endswith('.dart') else 'Python'

        return f"""
         You are an expert-level Principal Software Engineer specializing in Clean Code and Software Architecture for {language}.
         Your task is to analyze the provided source code and suggest concrete refactoring improvements.

        **File to Analyze:** `{file_name}`

        **Source Code:**
        ```{language.lower()}
        {code_content}
        ```

        **Your Task:**
        1.  Analyze the code for potential improvements in readability, efficiency, maintainability, and adherence to {language} best practices.
        2.  Provide 2-3 specific, actionable refactoring suggestions.
        3.  For each suggestion:
            - **Title:** Give it a clear, concise title (e.g., "Extract Widget to Reduce Build Method Complexity").
            - **Reasoning:** Explain *why* this change is beneficial (e.g., "This improves performance by reducing rebuilds and makes the widget tree more readable.").
            - **Code (Before):** Show the original block of code that should be changed.
            - **Code (After):** Show the new, improved code.

        **Output Format:**
        Present your report in a clear, well-formatted Markdown. Use headers for each suggestion.
        """

    # --- الإصلاح: تمت إضافة هذه الدالة وكل ما يليها داخل الكلاس SolutionEngine ---

    def generate_test_cases(self, file_path: str):
        """
        يقرأ ملف Dart ويطلب من Gemini إنشاء اختبارات وحدة أو ودجت له.
        """
        print(f"Analyzing {file_path} to generate Flutter/Dart test cases...")
        file_path_obj = Path(file_path)
        if not file_path_obj.exists() or not file_path_obj.is_file():
            print(f"--> [Error] File not found or is not a file: {file_path}")
            return
        try:
            with open(file_path_obj, 'r', encoding='utf-8') as f:
                content = f.read()
        except Exception as e:
            print(f"--> [Error] Could not read file {file_path_obj}: {e}")
            return
        test_type = 'widget' if 'StatelessWidget' in content or 'StatefulWidget' in content else 'unit'
        print(f"--> Detected file type: {test_type} test seems appropriate.")
        prompt = self._build_dart_test_generation_prompt(content, file_path_obj, test_type)
        print("--> Contacting Gemini to generate test cases...")
        try:
            response = self.model.generate_content(prompt)
            generated_code = response.text
            cleaned_code = self._clean_response_code(generated_code, "dart")
            test_file_path = self._save_dart_tests_to_file(file_path_obj, cleaned_code)
            print("--- Tests Generated Successfully ---")
            print(f"Tests have been saved to: {test_file_path}")
            print("-----------------------------------")
            print("You can run them from your project root using the command: flutter test")
        except Exception as e:
            print(f"--> [Gemini API Error] Failed to generate test cases: {e}")

    def _build_dart_test_generation_prompt(self, code_content: str, file_path_obj: Path,
                                           test_type: str) -> str:
        """
        يبني موجهًا مخصصًا لطلب اختبارات Flutter/Dart.
        """
        project_name = self._find_flutter_project_name(file_path_obj)
        relative_path = self._get_relative_path_for_import(file_path_obj)

        task_description = ""
        if test_type == 'widget':
            task_description = """
            Write a comprehensive suite of Widget Tests for the widgets in the provided file.
            The tests must cover:
            -   Initial state: Verify that the widget renders correctly with default properties.
            -   Interaction: Use `tester.tap()` to simulate user interactions (like button presses) and verify the resulting state changes (`tester.pump()`).
            -   Property changes: Test how the widget rebuilds when its input properties change.
            -   Use `find.text()`, `find.byIcon()`, `find.byKey()` etc. to locate widgets.
            """
        else:  # unit test
            task_description = """
            Write a comprehensive suite of Unit Tests for the public functions and classes in the provided file.
            The tests must cover:
            -   Happy path: Normal, expected inputs and their outputs.
            -   Edge cases: Null inputs, empty strings, zero values.
            -   Error conditions: Test that functions throw the expected exceptions (e.g., `throwsA(isA<ArgumentError>())`).
            """

        return f"""
        You are an expert-level Flutter/Dart developer specializing in automated testing.

        **File to Test:** `{file_path_obj.name}`

        **Project Name (for imports):** `{project_name}`

        **Source Code:**
        ```dart
        {code_content}
        ```

        **Your Task:**
        1.  Analyze the provided Dart code.
        2.  **Test Type:** You should write a `{test_type}` test.
        3.  **Task Details:** {task_description}
        4.  **Important:** Make sure to import the necessary file using a relative package import, like `import '{project_name}/{relative_path}';`. Also import `package:flutter_test/flutter_test.dart`.
        5.  The final output must be **only the Dart code** for the tests, ready to be saved to a file. Do not include any explanations, headings, or markdown formatting.

        **Example Output Format:**
        ```dart
        import 'package:flutter_test/flutter_test.dart';
        import '{project_name}/{relative_path}';

        void main() {{
          group('Widget/Class Name Tests', () {{
            testWidgets('Test description for a widget', (WidgetTester tester) async {{
              // Test implementation
            }});

            test('Test description for a function', () {{
              // Test implementation
            }});
          }});
        }}
        ```
        """

    def _find_flutter_project_name(self, file_path_obj: Path) -> str:
        """يجد اسم مشروع Flutter بالبحث عن pubspec.yaml في الأدلة الأعلى."""
        current_dir = file_path_obj.parent
        while current_dir != current_dir.parent:  # Loop until root
            pubspec_file = current_dir / 'pubspec.yaml'
            if pubspec_file.exists():
                with open(pubspec_file, 'r', encoding='utf-8') as f:
                    for line in f:
                        if line.strip().startswith('name:'):
                            return line.strip().split(':')[1].strip()
            current_dir = current_dir.parent
        return "my_flutter_app"  # Default fallback

    def _get_relative_path_for_import(self, file_path_obj: Path) -> str:
        """يحصل على المسار النسبي من مجلد 'lib' للاستخدام في جملة import."""
        try:
            return str(file_path_obj.relative_to(Path.cwd() / 'lib')).replace('\\', '/')
        except ValueError:
            # If the file is not in a 'lib' subdirectory, return its name as a fallback.
            return file_path_obj.name

    def _clean_response_code(self, response_text: str, language: str) -> str:
        """ينظف استجابة Gemini لإزالة أي نص غير برمجي."""
        if response_text.strip().startswith(f"```{language}"):
            response_text = response_text.strip()[len(language) + 3:]
        if response_text.strip().endswith("```"):
            response_text = response_text.strip()[:-3]
        return response_text.strip()

    def _save_dart_tests_to_file(self, source_file_path: Path, test_code: str) -> str:
        """يحفظ كود اختبار Dart في مجلد test بالمشروع."""
        # العثور على جذر المشروع (حيث يوجد pubspec.yaml)
        project_root = source_file_path.parent
        while not (project_root / 'pubspec.yaml').exists() and project_root != project_root.parent:
            project_root = project_root.parent

        # إنشاء مسار الاختبار
        test_dir = project_root / 'test'
        test_dir.mkdir(exist_ok=True)

        # إنشاء اسم ملف الاختبار
        relative_source_path = source_file_path.relative_to(project_root / 'lib')
        test_file_name = f"{relative_source_path.stem}_test.dart"
        test_file_path = test_dir / relative_source_path.parent / test_file_name

        # إنشاء المجلدات الفرعية داخل test/ إذا لزم الأمر
        test_file_path.parent.mkdir(parents=True, exist_ok=True)

        with open(test_file_path, 'w', encoding='utf-8') as f:
            f.write(test_code)

        return str(test_file_path)

    def explain_code(self, file_path: str):
        """
        يقرأ ملف Dart ويطلب من Gemini شرح محتواه أو جزء منه.
        """
        print(f"Analyzing {file_path} to provide an explanation...")
        try:
            with open(file_path, 'r', encoding='utf-8') as f:
                content = f.read()
        except FileNotFoundError:
            print(f"--> [Error] File not found: {file_path}")
            return
        except Exception as e:
            print(f"--> [Error] Could not read file {file_path}: {e}")
            return

        # يمكننا جعلها أكثر تفاعلية بسؤال المستخدم عن جزء معين
        target = input(
            "Enter a specific class/widget/function name to explain, or leave blank to explain the whole file: ")

        prompt = self._build_explanation_prompt(content, file_path, target.strip())

        print("--> Contacting Gemini for a detailed explanation...")
        try:
            # نستخدم وضع "stream" هنا للحصول على إجابة متدفقة كأنها محادثة
            response = self.model.generate_content(prompt, stream=True)

            print("\n--- Gemini's Code Explanation ---\n")
            for chunk in response:
                print(chunk.text, end="", flush=True)  # طباعة كل جزء فور وصوله
            print("\n\n---------------------------------\n")
        except Exception as e:
            print(f"--> [Gemini API Error] Failed to get explanation: {e}")

    def _build_explanation_prompt(self, code_content: str, file_name: str, target: str) -> str:
        """
        يبني موجهًا مخصصًا لطلب شرح الكود.
        """
        file_type = "Flutter/Dart" if file_name.endswith('.dart') else "code"

        if target:
            task_instruction = f"Focus specifically on the `{target}` class/widget/function. Explain its purpose, how it works, its parameters, and its role within the file."
        else:
            task_instruction = "Provide a high-level overview of the entire file. Explain its main purpose, key widgets/classes/functions, and how they interact."

        return f"""
        You are a senior Flutter/Dart developer and an excellent technical communicator.
        Your task is to explain a piece of code to a fellow developer.

        **File to Explain:** `{file_name}`

        **Source Code:**
        ```dart
        {code_content}
        ```

        **Your Task:**
        -   Explain the provided {file_type} code in a clear, concise, and easy-to-understand manner.
        -   {task_instruction}
        -   If it's a widget, describe what it looks like and how a user might interact with it.
        -   If it involves state management, explain the state management approach used (e.g., setState, Provider, BLoC).
        -   Use Markdown for formatting, including bullet points and code snippets for clarity.
        """

    def analyze_dependencies(self):
        """
        يجد ويحلل ملف pubspec.yaml في المشروع الحالي.
        """
        # البحث عن pubspec.yaml بدءًا من الدليل الحالي
        pubspec_path = self._find_pubspec_recursively(Path.cwd())

        if not pubspec_path:
            print(
                "--> [Error] Could not find a pubspec.yaml file in the current directory or its parents. Make sure you are inside a Flutter project.")
            return

        print(f"Found pubspec.yaml at: {pubspec_path}")
        print("Analyzing project dependencies...")

        try:
            with open(pubspec_path, 'r', encoding='utf-8') as f:
                content = f.read()
        except Exception as e:
            print(f"--> [Error] Could not read {pubspec_path}: {e}")
            return

        prompt = self._build_deps_analysis_prompt(content)

        print("--> Contacting Gemini for a dependency health report...")
        try:
            response = self.model.generate_content(prompt, stream=True)

            print("\n--- Gemini's Dependency Analysis Report ---\n")
            for chunk in response:
                print(chunk.text, end="", flush=True)
            print("\n\n-----------------------------------------\n")
        except Exception as e:
            print(f"--> [Gemini API Error] Failed to get dependency analysis: {e}")

    def _find_pubspec_recursively(self, start_dir: Path) -> Optional[Path]:
        """يبحث عن pubspec.yaml صعودًا من الدليل الحالي."""
        current_dir = start_dir
        while current_dir != current_dir.parent:
            pubspec_file = current_dir / 'pubspec.yaml'
            if pubspec_file.exists():
                return pubspec_file
            current_dir = current_dir.parent
        return None

    def _build_deps_analysis_prompt(self, pubspec_content: str) -> str:
        """
        يبني موجهًا مخصصًا لطلب تحليل لملف pubspec.yaml.
        """
        return f"""
        You are an expert-level Senior Flutter developer with deep knowledge of the pub.dev ecosystem.
        Your task is to perform a "dependency health check" on a Flutter project.

        **pubspec.yaml Content:**
        ```yaml
        {pubspec_content}
        ```

        **Your Task:**
        Analyze the `dependencies` and `dev_dependencies` sections and provide a concise report covering the following points.
        For each point, provide a rating (Good, Warning, or Critical) and a brief explanation.

        1.  **Outdated Packages:**
            - Are there any packages with significantly outdated versions?
            - Suggest running `flutter pub outdated` and highlight any major versions behind that could be updated.

        2.  **Package Health & Popularity:**
            - Are there any deprecated or unpopular packages?
            - Suggest better, more modern, or more popular alternatives if they exist (e.g., suggesting `go_router` over older routing packages, or `dio` for advanced networking).

        3.  **Null-Safety:**
            - Quickly check if the SDK constraint (`environment: sdk:`) is up-to-date and supports modern null-safe Dart.

        4.  **Potential Conflicts or Redundancies:**
            - Do you see any packages that do the same thing? (e.g., having two different state management libraries).
            - Mention any known compatibility issues between listed packages.

        **Output Format:**
        Present your report in a clear, well-formatted Markdown. Use headers for each category (e.g., ### 1. Outdated Packages [Warning]). Be concise and actionable.
        """


class SmartErrorAnalyzer:
    """محلل الأخطاء الذكي"""

    def __init__(self, solution_engine: SolutionEngine):
        self.errors_db = self._load_errors_database()
        self.solutions_db = self._load_solutions_database()
        self.patterns = self._load_error_patterns()
        self.context_analyzer = ContextAnalyzer()
        self.solution_engine = solution_engine  # الآن هذا السطر صحيح لأنه يستخدم المعامل

    def analyze_files(self, file_paths: List[str], global_definitions: Optional[Dict] = None,
                      global_imports: Optional[Dict] = None) -> List[Error]:
        """تحليل قائمة من الملفات واكتشاف الأخطاء"""
        all_errors = []

        # Ensure global_definitions and global_imports are initialized if not provided
        if global_definitions is None:
            global_definitions = {}
        if global_imports is None:
            global_imports = {}

        for file_path in file_paths:
            errors = []
            file_ext = Path(file_path).suffix

            if file_ext == '.py':
                errors.extend(self._analyze_python_file(file_path))
            elif file_ext == '.dart':
                errors.extend(self._analyze_dart_file(file_path))
            elif file_ext in ['.js', '.ts']:
                errors.extend(self._analyze_javascript_file(file_path))
            elif file_ext in ['.html', '.xml']:
                errors.extend(self._analyze_markup_file(file_path))
            else:
                errors.extend(self._analyze_generic_file(file_path))

            all_errors.extend(errors)

        # فحوصات عبر الملفات (تعتمد على المعلومات العالمية إذا كانت متوفرة)
        all_errors.extend(
            self._check_cross_file_imports(file_paths, global_definitions, global_imports))

        all_errors.extend(self._check_security_vulnerabilities(file_paths))
        all_errors.extend(self._check_performance_bottlenecks(file_paths))
        all_errors.extend(self._predict_runtime_errors(file_paths))
        all_errors.extend(self._check_duplicate_code(file_paths))

        # إضافة السياق وتوليد الحلول لكل خطأ
        for error in all_errors:
            error.context = self.context_analyzer.analyze_error_context(error, error.file_path)
            error.solutions = self.solution_engine.generate_solutions(error)

        return all_errors

    def analyze_project(self, project_path: str) -> List[Error]:
        """تحليل مشروع كامل واكتشاف الأخطاء"""
        file_paths = []
        for root, _, files in os.walk(project_path):
            for file in files:
                # يمكن إضافة فلاتر لأنواع الملفات هنا
                if file.endswith(
                        ('.py', '.dart', '.js', '.ts', '.html', '.xml', '.json', '.yaml', '.yml')):
                    file_paths.append(os.path.join(root, file))

        # جمع المعلومات العالمية لملفات Python
        global_definitions = {}
        global_imports = {}
        for f_path in file_paths:
            if f_path.endswith('.py'):
                defs, imports = self._collect_global_info(f_path)
                global_definitions[f_path] = defs
                global_imports[f_path] = imports

        all_errors = self.analyze_files(file_paths, global_definitions, global_imports)

        return all_errors

    def _collect_global_info(self, file_path: str) -> Tuple[Dict[str, Any], Dict[str, Any]]:
        """يجمع معلومات حول التعريفات والاستيرادات في ملف Python."""
        definitions = {'functions': set(), 'classes': set()}
        imports = {'modules': set(), 'symbols': set()}

        try:
            with open(file_path, 'r', encoding='utf-8') as f:
                content = f.read()
            tree = ast.parse(content)

            for node in ast.walk(tree):
                if isinstance(node, ast.FunctionDef):
                    definitions['functions'].add(node.name)
                elif isinstance(node, ast.ClassDef):
                    definitions['classes'].add(node.name)
                elif isinstance(node, ast.Import):
                    for alias in node.names:
                        imports['modules'].add(alias.name.split('.')[0])
                        if alias.asname:  # if imported with an alias
                            imports['symbols'].add(alias.asname)
                        else:
                            imports['symbols'].add(alias.name.split('.')[-1])
                elif isinstance(node, ast.ImportFrom):
                    if node.module:
                        imports['modules'].add(node.module.split('.')[0])
                    for alias in node.names:
                        if alias.asname:
                            imports['symbols'].add(alias.asname)
                        else:
                            imports['symbols'].add(alias.name)
        except Exception as e:
            # Handle parsing errors gracefully
            print(f"Warning: Could not parse {file_path} for global info: {e}")

        return definitions, imports

    def _check_cross_file_imports(self, file_paths: List[str], global_definitions: Dict,
                                  global_imports: Dict) -> List[Error]:
        """فحص الاستيراد عبر الملفات، الرموز غير المستخدمة، والتبعيات الدائرية"""
        errors = []
        standard_library_modules = {
            'os', 'sys', 're', 'json', 'ast', 'traceback', 'subprocess', 'pathlib',
            'typing', 'datetime', 'dataclasses', 'enum', 'difflib', 'requests', 'argparse',
            'collections', 'io', 'math', 'shutil', 'tempfile', 'urllib', 'uuid', 'logging',
            'threading', 'multiprocessing', 'socket', 'http', 'xml', 'csv', 'sqlite3',
            'hashlib', 'random', 'time', 'warnings', 'abc', 'copy', 'decimal', 'fractions',
            'itertools', 'functools', 'operator', 'queue', 'selectors', 'statistics', 'zipfile'
        }
        project_modules = {Path(f).stem for f in file_paths if Path(f).suffix == '.py'}

        # 1. فحص الاستيراد غير الموجود
        for file_path in file_paths:
            if Path(file_path).suffix == '.py':
                with open(file_path, 'r', encoding='utf-8') as f:
                    content = f.read()
                    for line_num, line in enumerate(content.split('\n')):
                        match = re.search(r'^import\s+(\w+)|from\s+(\w+)\s+import', line)
                        if match:
                            imported_module = match.group(1) or match.group(2)
                            if imported_module and imported_module not in project_modules and imported_module not in standard_library_modules:
                                errors.append(Error(
                                    type=ErrorType.IMPORT,
                                    severity=ErrorSeverity.MEDIUM,
                                    message=f"الوحدة '{imported_module}' مستوردة ولكنها غير موجودة في المشروع أو المكتبات القياسية",
                                    file_path=file_path,
                                    line_number=line_num + 1,
                                    code_snippet=line
                                ))

        # 2. اكتشاف الرموز غير المستخدمة (الدوال والفئات)
        all_defined_symbols = set()
        for f_path, defs in global_definitions.items():
            all_defined_symbols.update(defs['functions'])
            all_defined_symbols.update(defs['classes'])

        all_imported_symbols = set()
        for f_path, imports in global_imports.items():
            all_imported_symbols.update(imports['symbols'])

        unused_symbols = all_defined_symbols - all_imported_symbols
        for symbol in unused_symbols:
            # حاول تحديد الملف الذي تم تعريف الرمز فيه للإبلاغ الدقيق
            defined_file = None
            for f_path, defs in global_definitions.items():
                if symbol in defs['functions'] or symbol in defs['classes']:
                    defined_file = f_path
                    break
            if defined_file:
                errors.append(Error(
                    type=ErrorType.LOGIC,
                    severity=ErrorSeverity.LOW,
                    message=f"الرمز '{symbol}' معرف ولكنه غير مستخدم في أي مكان بالمشروع. قد يكون كوداً ميتاً.",
                    file_path=defined_file,
                    code_snippet=f"def {symbol}(...)" if symbol in global_definitions.get(
                        defined_file, {}).get('functions', set()) else f"class {symbol}:"
                ))

        # 3. اكتشاف التبعيات الدائرية
        graph = {Path(f).stem: set() for f in file_paths if Path(f).suffix == '.py'}
        for f_path, imports in global_imports.items():
            current_module = Path(f_path).stem
            for imported_module in imports['modules']:
                if imported_module in graph:
                    graph[current_module].add(imported_module)

        visited = set()
        recursion_stack = set()

        def dfs(node, path):
            visited.add(node)
            recursion_stack.add(node)

            for neighbor in graph.get(node, set()):
                if neighbor not in visited:
                    cycle = dfs(neighbor, path + [neighbor])
                    if cycle:
                        return cycle
                elif neighbor in recursion_stack:
                    cycle_start_index = path.index(neighbor)
                    return path[cycle_start_index:] + [neighbor]

            recursion_stack.remove(node)
            return None

        for node in graph:
            cycle = dfs(node, [node])
            if cycle:
                errors.append(Error(
                    type=ErrorType.LOGIC,
                    severity=ErrorSeverity.MEDIUM,
                    message=f"تم اكتشاف تبعية دائرية: {' -> '.join(cycle)}. يجب إعادة هيكلة هذه الوحدات.",
                    file_path=None,
                    code_snippet=None
                ))
                break

        return errors

    def _check_security_vulnerabilities(self, file_paths: List[str]) -> List[Error]:
        errors = []
        for file_path in file_paths:
            with open(file_path, 'r', encoding='utf-8', errors='ignore') as f:
                content = f.read()
            errors.extend(self._check_security_issues_in_content(content, file_path))
        return errors

    def _check_performance_bottlenecks(self, file_paths: List[str]) -> List[Error]:
        errors = []
        for file_path in file_paths:
            with open(file_path, 'r', encoding='utf-8', errors='ignore') as f:
                content = f.read()
            errors.extend(self._check_performance_issues_in_content(content, file_path))
        return errors

    def _predict_runtime_errors(self, file_paths: List[str]) -> List[Error]:
        errors = []
        for file_path in file_paths:
            if Path(file_path).suffix == '.py':
                with open(file_path, 'r', encoding='utf-8', errors='ignore') as f:
                    content = f.read()
                try:
                    tree = ast.parse(content)
                    for node in ast.walk(tree):
                        if isinstance(node, ast.BinOp):
                            if isinstance(node.op, (ast.Div, ast.FloorDiv, ast.Mod)) and isinstance(
                                    node.right, ast.Constant) and node.right.value == 0:
                                errors.append(Error(
                                    type=ErrorType.RUNTIME,
                                    severity=ErrorSeverity.CRITICAL,
                                    message="قسمة على صفر محتملة",
                                    file_path=file_path,
                                    line_number=node.lineno,
                                    code_snippet=self._get_code_snippet(content, node.lineno)
                                ))
                except SyntaxError:
                    pass
        return errors

    def _check_duplicate_code(self, file_paths: List[str]) -> List[Error]:
        errors = []
        all_lines = {}

        for file_path in file_paths:
            with open(file_path, 'r', encoding='utf-8', errors='ignore') as f:
                lines = f.readlines()
            for i, line in enumerate(lines):
                stripped_line = line.strip()
                if stripped_line and not stripped_line.startswith(('#', '//', '/*', '*', '*/')):
                    if stripped_line not in all_lines:
                        all_lines[stripped_line] = []
                    all_lines[stripped_line].append((file_path, i + 1))

        for line_content, locations in all_lines.items():
            if len(locations) > 1:
                error_locations = [f"{loc_file}:{loc_line}" for loc_file, loc_line in locations]
                message = f"تم العثور على كود مكرر: '{line_content}' في {len(locations)} مواقع."
                errors.append(Error(
                    type=ErrorType.LOGIC,
                    severity=ErrorSeverity.MEDIUM,
                    message=message,
                    file_path=locations[0][0],
                    line_number=locations[0][1],
                    code_snippet=line_content,
                    context={"duplicate_locations": error_locations}
                ))
        return errors

    def _analyze_python_file(self, file_path: str) -> List[Error]:
        errors = []
        try:
            with open(file_path, 'r', encoding='utf-8') as f:
                content = f.read()
        except Exception as e:
            return [Error(type=ErrorType.RUNTIME, severity=ErrorSeverity.HIGH,
                          message=f"لا يمكن قراءة الملف: {e}", file_path=file_path)]

        try:
            tree = ast.parse(content)
        except SyntaxError as e:
            return [Error(
                type=ErrorType.SYNTAX,
                severity=ErrorSeverity.CRITICAL,
                message=str(e),
                file_path=file_path,
                line_number=e.lineno,
                column_number=e.offset,
                code_snippet=self._get_code_snippet(content, e.lineno)
            )]

        # فحوصات تعتمد على AST
        _add_parent_pointers(tree)
        type_analyzer = TypeAnalyzer()
        type_analyzer.visit(tree)
        for type_error in type_analyzer.errors:
            type_error.file_path = file_path
            type_error.code_snippet = self._get_code_snippet(content, type_error.line_number)
            errors.append(type_error)

        data_flow_analyzer = DataFlowAnalyzer()
        data_flow_analyzer.visit(tree)
        for data_flow_error in data_flow_analyzer.errors:
            data_flow_error.file_path = file_path
            data_flow_error.code_snippet = self._get_code_snippet(content,
                                                                  data_flow_error.line_number)
            errors.append(data_flow_error)

        for unreachable_node in data_flow_analyzer.unreachable_code_nodes:
            errors.append(Error(
                type=ErrorType.LOGIC,
                severity=ErrorSeverity.MEDIUM,
                message="كود غير قابل للوصول (Unreachable Code)",
                file_path=file_path,
                line_number=getattr(unreachable_node, 'lineno', None),
                code_snippet=self._get_code_snippet(content,
                                                    getattr(unreachable_node, 'lineno', None))
            ))

        # فحوصات تعتمد على المحتوى
        errors.extend(self._check_python_imports(content, file_path))
        errors.extend(self._check_undefined_variables(content, file_path))
        errors.extend(self._check_error_handling(content, file_path))
        errors.extend(self._check_resource_management(content, file_path))
        errors.extend(self._check_code_style(content, file_path))
        errors.extend(self._check_deprecated_usage(content, file_path))

        return errors

    def _analyze_dart_file(self, file_path: str) -> List[Error]:
        errors = []
        try:
            result = subprocess.run(['dart', 'analyze', file_path], capture_output=True, text=True,
                                    check=False)
            if result.returncode != 0:
                errors.extend(self._parse_dart_analyzer_output(result.stdout))
            with open(file_path, 'r', encoding='utf-8') as f:
                content = f.read()
            errors.extend(self._check_getx_usage(content, file_path))
        except Exception as e:
            errors.append(Error(type=ErrorType.RUNTIME, severity=ErrorSeverity.MEDIUM,
                                message=f"خطأ في تحليل ملف Dart: {e}", file_path=file_path))
        return errors

    def _check_python_imports(self, content: str, file_path: str) -> List[Error]:
        errors = []
        import_pattern = re.compile(r'^(?:from\s+(\S+)\s+)?import\s+(.+)$', re.MULTILINE)
        for match in import_pattern.finditer(content):
            module = match.group(1) or match.group(2).split(',')[0].strip()
            try:
                __import__(module)
            except ImportError:
                errors.append(Error(
                    type=ErrorType.IMPORT,
                    severity=ErrorSeverity.HIGH,
                    message=f"لا يمكن استيراد الوحدة '{module}'. قد تكون غير مثبتة أو هناك خطأ إملائي.",
                    file_path=file_path,
                    line_number=content.count('\n', 0, match.start()) + 1,
                    code_snippet=match.group(0)
                ))
        return errors

    def _check_undefined_variables(self, content: str, file_path: str) -> List[Error]:
        errors = []
        try:
            tree = ast.parse(content)
            analyzer = UndefinedVariableAnalyzer()
            analyzer.visit(tree)
            for var, line in analyzer.undefined_vars:
                errors.append(Error(
                    type=ErrorType.UNDEFINED,
                    severity=ErrorSeverity.HIGH,
                    message=f"المتغير '{var}' غير معرف",
                    file_path=file_path,
                    line_number=line,
                    code_snippet=self._get_code_snippet(content, line)
                ))
        except SyntaxError:
            pass  # Syntax errors handled elsewhere
        return errors

    def _check_security_issues_in_content(self, content: str, file_path: str) -> List[Error]:
        errors = []
        lines = content.split('\n')
        dangerous_patterns = [
            (r'eval\s*\(', "استخدام eval() خطر أمنياً، قد يؤدي إلى تنفيذ كود عشوائي."),
            (r'pickle\.loads', "استخدام pickle مع بيانات غير موثوقة خطر."),
            (r'subprocess\..*shell\s*=\s*True', "استخدام shell=True في subprocess خطر."),
            (r'requests\..*verify=False', "تعطيل التحقق من SSL خطر أمنياً."),
            (r'(password|api_key)\s*=\s*["\'].*["\']', "كلمة مرور أو مفتاح API في الكود."),
        ]
        for i, line in enumerate(lines):
            for pattern, message in dangerous_patterns:
                if re.search(pattern, line):
                    errors.append(
                        Error(type=ErrorType.SECURITY, severity=ErrorSeverity.HIGH, message=message,
                              file_path=file_path, line_number=i + 1, code_snippet=line))
        return errors

    def _check_performance_issues_in_content(self, content: str, file_path: str) -> List[Error]:
        errors = []
        lines = content.split('\n')
        performance_patterns = [
            (r'for\s+\w+\s+in\s+range\s*\(\s*len\s*\(\s*\w+\s*\)\s*\)',
             "استخدم enumerate() بدلاً من range(len()) لتحسين الأداء"),
            (r'list.append\s*\(', "استخدم list comprehension لأداء أفضل إذا أمكن."),
        ]
        for i, line in enumerate(lines):
            for pattern, message in performance_patterns:
                if re.search(pattern, line):
                    errors.append(Error(type=ErrorType.PERFORMANCE, severity=ErrorSeverity.MEDIUM,
                                        message=message, file_path=file_path, line_number=i + 1,
                                        code_snippet=line))
        return errors

    def _check_code_style(self, content: str, file_path: str) -> List[Error]:
        errors = []
        # Implementation from original file
        return errors

    def _check_deprecated_usage(self, content: str, file_path: str) -> List[Error]:
        errors = []
        # Implementation from original file
        return errors

    def _check_error_handling(self, content: str, file_path: str) -> List[Error]:
        errors = []
        # Implementation from original file
        return errors

    def _check_resource_management(self, content: str, file_path: str) -> List[Error]:
        errors = []
        # Implementation from original file
        return errors

    def _check_getx_usage(self, content: str, file_path: str) -> List[Error]:
        errors = []
        # Implementation from original file
        return errors

    def _get_code_snippet(self, content: str, line_number: int, context_lines: int = 2) -> str:
        lines = content.split('\n')
        if not (1 <= line_number <= len(lines)):
            return ""
        start = max(0, line_number - context_lines - 1)
        end = min(len(lines), line_number + context_lines)
        snippet_lines = [f"{'>>>' if i == line_number - 1 else '   '} {i + 1: >4}| {lines[i]}" for i
                         in range(start, end)]
        return '\n'.join(snippet_lines)

    def _load_errors_database(self) -> Dict:
        """تحميل قاعدة بيانات الأخطاء"""
        # يمكن تحميلها من ملف JSON أو قاعدة بيانات
        return {
            "syntax_errors": {
                "missing_colon": {
                    "pattern": r"SyntaxError.*expected.*:",
                    "solution": "إضافة : في نهاية السطر"
                },
                "missing_parenthesis": {
                    "pattern": r"SyntaxError.*\\(",
                    "solution": "إضافة الأقواس المفقودة"
                }
            }
        }

    def _load_solutions_database(self) -> Dict:
        """تحميل قاعدة بيانات الحلول"""
        return {
            "import_error": {
                "install_package": {
                    "description": "تثبيت الحزمة المفقودة",
                    "command": "pip install {package_name}"
                },
                "fix_import_path": {
                    "description": "تصحيح مسار الاستيراد",
                    "pattern": "from {correct_path} import {module}"
                }
            }
        }

    def _load_error_patterns(self) -> List[Dict]:
        """تحميل أنماط الأخطاء"""
        return [
            {
                "pattern": r"NameError.*'(\\w+)'",
                "type": ErrorType.UNDEFINED,
                "severity": ErrorSeverity.HIGH,
                "message": "المتغير '{1}' غير معرف"
            }
        ]

    def _parse_dart_analyzer_output(self, output: str) -> List[Error]:
        """تحليل مخرجات dart analyze"""
        errors = []
        # Example line: lib/main.dart:10:5 - [lint] prefer_const_constructors - Use 'const' for constructors.
        # Example line: lib/my_widget.dart:25:10 - [error] A value of type 'Null' can't be assigned to a variable of type 'String'.
        dart_error_pattern = re.compile(
            r'^(?P<file_path>.+):(?P<line>\d+):(?P<column>\d+)\s+-\s+\[(?P<type>\w+)\]\s+(?P<code>\w+)\s+-\s+(?P<message>.+)')

        for line in output.split('\n'):
            match = dart_error_pattern.match(line.strip())
            if match:
                data = match.groupdict()

                error_type_str = data['type'].lower()
                error_code = data['code']
                message = data['message']
                file_path = data['file_path']
                line_number = int(data['line'])
                column_number = int(data['column'])

                # Infer ErrorType and ErrorSeverity
                error_type = ErrorType.RUNTIME  # Default
                severity = ErrorSeverity.MEDIUM  # Default

                if error_type_str == 'error':
                    severity = ErrorSeverity.HIGH
                    if 'syntax' in message.lower():
                        error_type = ErrorType.SYNTAX
                    elif 'type' in message.lower() or 'assign' in message.lower():
                        error_type = ErrorType.TYPE
                    elif 'undefined' in message.lower() or 'not found' in message.lower():
                        error_type = ErrorType.UNDEFINED
                    else:
                        error_type = ErrorType.RUNTIME
                elif error_type_str == 'warning' or error_type_str == 'lint':
                    severity = ErrorSeverity.LOW
                    if 'performance' in message.lower() or 'inefficient' in message.lower() or 'unnecessary' in message.lower() or 'const' in message.lower():
                        error_type = ErrorType.PERFORMANCE
                    elif 'style' in message.lower() or 'convention' in message.lower():
                        error_type = ErrorType.STYLE
                    elif 'unused' in message.lower() or 'dead code' in message.lower():
                        error_type = ErrorType.LOGIC  # Dead code is a logic issue
                    elif 'memory' in message.lower() or 'leak' in message.lower():
                        error_type = ErrorType.SECURITY  # Memory leaks can be security issues
                    else:
                        error_type = ErrorType.INFO  # General info/lint

                errors.append(Error(
                    type=error_type,
                    severity=severity,
                    message=message,
                    file_path=file_path,
                    line_number=line_number,
                    column_number=column_number,
                    code_snippet=None  # Will be filled by SmartErrorAnalyzer later if needed
                ))

        return errors

    def _analyze_javascript_file(self, file_path: str) -> List[Error]:
        """تحليل ملف JavaScript/TypeScript"""
        errors = []

        try:
            with open(file_path, 'r', encoding='utf-8') as f:
                content = f.read()

            # فحوصات JavaScript الأساسية
            errors.extend(self._check_javascript_syntax(content, file_path))
            errors.extend(self._check_javascript_best_practices(content, file_path))

        except Exception as e:
            errors.append(Error(
                type=ErrorType.RUNTIME,
                severity=ErrorSeverity.MEDIUM,
                message=f"خطأ في تحليل ملف JavaScript: {str(e)}",
                file_path=file_path
            ))

        return errors

    def _analyze_markup_file(self, file_path: str) -> List[Error]:
        """تحليل ملفات HTML/XML"""
        errors = []

        try:
            with open(file_path, 'r', encoding='utf-8') as f:
                content = f.read()

            # فحص إغلاق التاقات
            errors.extend(self._check_unclosed_tags(content, file_path))

        except Exception as e:
            errors.append(Error(
                type=ErrorType.RUNTIME,
                severity=ErrorSeverity.MEDIUM,
                message=f"خطأ في تحليل الملف: {str(e)}",
                file_path=file_path
            ))

        return errors

    def _analyze_generic_file(self, file_path: str) -> List[Error]:
        """تحليل عام للملفات"""
        errors = []

        try:
            with open(file_path, 'r', encoding='utf-8') as f:
                content = f.read()

            # فحوصات عامة
            # التحقق من التشفير
            try:
                content.encode('utf-8')
            except UnicodeEncodeError:
                errors.append(Error(
                    type=ErrorType.SYNTAX,
                    severity=ErrorSeverity.LOW,
                    message="الملف يحتوي على أحرف غير متوافقة مع UTF-8",
                    file_path=file_path
                ))

        except Exception as e:
            errors.append(Error(
                type=ErrorType.RUNTIME,
                severity=ErrorSeverity.MEDIUM,
                message=f"خطأ في قراءة الملف: {str(e)}",
                file_path=file_path
            ))

        return errors


class ContextAnalyzer:
    """محلل السياق للأخطاء"""

    def analyze_error_context(self, error: Error, file_path: Optional[str]) -> Dict[str, Any]:
        if not file_path or not os.path.exists(file_path):
            return {}
        context = {
            'file_type': Path(file_path).suffix,
            'file_size': os.path.getsize(file_path),
            'project_type': self._detect_project_type(file_path)
        }
        return context

    def _detect_project_type(self, file_path: str) -> str:
        project_root = Path(file_path).parent
        if (project_root / 'pubspec.yaml').exists(): return 'Flutter/Dart'
        if (project_root / 'requirements.txt').exists(): return 'Python'
        if (project_root / 'package.json').exists(): return 'Node.js'
        return 'Generic'


class TypeAnalyzer(ast.NodeVisitor):
    def __init__(self): self.errors = []
    # Implementation from original file


class UndefinedVariableAnalyzer(ast.NodeVisitor):
    def __init__(self):
        self.defined_vars = set()
        self.undefined_vars = []
    # Implementation from original file


class DataFlowAnalyzer(ast.NodeVisitor):
    """محلل تدفق البيانات لاكتشاف الأخطاء المنطقية والكود غير القابل للوصول"""

    def __init__(self):
        self.scopes = [{}]
        self.errors = []
        self.unreachable_code_nodes = set()

    def visit_FunctionDef(self, node):
        self.scopes.append({})
        self.generic_visit(node)
        self.scopes.pop()

    def visit_Name(self, node):
        if isinstance(node.ctx, ast.Store):
            self.scopes[-1][node.id] = node.lineno
        elif isinstance(node.ctx, ast.Load):
            if not any(node.id in scope for scope in self.scopes) and node.id not in __builtins__:
                self.errors.append(Error(
                    type=ErrorType.LOGIC,
                    severity=ErrorSeverity.HIGH,
                    message=f"المتغير '{node.id}' مستخدم قبل تعريفه",
                    file_path=None, line_number=node.lineno
                ))
        self.generic_visit(node)

    def check_unreachable(self, node):
        parent = getattr(node, 'parent', None)
        if parent:
            body_list = None
            if hasattr(parent, 'body') and isinstance(parent.body, list):
                body_list = parent.body
            elif hasattr(parent, 'orelse') and isinstance(parent.orelse, list):
                body_list = parent.orelse

            if body_list and node in body_list:
                idx = body_list.index(node)
                if idx < len(body_list) - 1:
                    for unreachable_node in body_list[idx + 1:]:
                        # الإصلاح رقم 2: تم حذف حرف 'n' الزائد من السطر التالي
                        self.unreachable_code_nodes.add(unreachable_node)

    def visit_Return(self, node):
        self.check_unreachable(node)
        self.generic_visit(node)

    def visit_Break(self, node):
        self.check_unreachable(node)
        self.generic_visit(node)

    def visit_Continue(self, node):
        self.check_unreachable(node)
        self.generic_visit(node)


def _add_parent_pointers(node):
    for child in ast.iter_child_nodes(node):
        child.parent = node
        _add_parent_pointers(child)


class ErrorReportGenerator:
    """مولد تقارير الأخطاء"""

    def generate_report(self, errors: List[Error], format: str = 'text') -> str:
        """
        الدالة الرئيسية لتوليد التقرير. تختار الصيغة المناسبة.
        """
        # أولاً، تحقق مما إذا كانت هناك أخطاء على الإطلاق
        if not errors:
            return "✅ === تقرير تحليل الأخطاء === ✅\n\nلم يتم العثور على أي أخطاء. عمل رائع!\n"

        # ثانياً، اختر الدالة المناسبة بناءً على الصيغة المطلوبة
        if format == 'json':
            return self._generate_json_report(errors)
        if format == 'html':
            return self._generate_html_report(errors)

        # الصيغة الافتراضية هي النص
        return self._generate_text_report(errors)

    def _generate_text_report(self, errors: List[Error]) -> str:
        """
        ينشئ تقريرًا نصيًا مفصلاً وواضحًا مصممًا للعرض في الطرفية (Terminal).
        """
        # بناء رأس التقرير
        report_parts = [
            """
            """ + " = "*25 + """
        تقرير
        تحليل
        الأخطاء
        """ + " = "*25,
                f"\n🔍 تم العثور على إجمالي {len(errors)} خطأ/تحذير.\n"
        ]


        # فرز الأخطاء حسب الخطورة (من الأعلى إلى الأقل) لعرض الأهم أولاً
        errors.sort(key=lambda e: e.severity.value, reverse=True)

        # المرور على كل خطأ لبناء قسم خاص به
        for error in errors:
            # استخدام قاموس لربط مستوى الخطورة برمز ولون
            severity_map = {
                ErrorSeverity.CRITICAL: ("💥 CRITICAL", '\033[91m'),  # أحمر
                ErrorSeverity.HIGH: ("🔥 HIGH", '\033[93m'),  # أصفر
                ErrorSeverity.MEDIUM: ("🔶 MEDIUM", '\033[94m'),  # أزرق
                ErrorSeverity.LOW: ("🔷 LOW", '\033[96m'),  # سماوي
                ErrorSeverity.INFO: ("ℹ️ INFO", '\033[92m')  # أخضر
            }
            RESET_COLOR = '\033[0m'

            severity_text, color = severity_map.get(error.severity, (error.severity.name, ""))

            # بناء قسم الخطأ الحالي
            error_section = [
                "\n" + "-" * 60,
                f"{color}📍 {severity_text:<15} | {error.file_path or 'N/A'}" + (
                    f":{error.line_number}" if error.line_number else ""),
                f"❌ الرسالة: {error.message}{RESET_COLOR}"
            ]

            # إضافة مقتطف الكود إذا كان موجودًا
            if error.code_snippet:
                error_section.append(f"💻 الكود:\n{error.code_snippet}\n")

            # إضافة الحلول المقترحة إذا كانت موجودة
            if error.solutions:
                error_section.append("💡 الحلول المقترحة:")
                # عرض أفضل 3 حلول فقط لجعل التقرير موجزًا
                for i, sol in enumerate(error.solutions[:3], 1):
                    confidence_str = f"(الثقة: {sol.confidence:.0%})" if sol.confidence > 0 else ""
                    solution_line = f"   {i}. {sol.description} {confidence_str}"
                    error_section.append(solution_line)
                    # إضافة شرح للحل إذا كان موجودًا
                    if sol.explanation:
                        error_section.append(f"      ➡️ الشرح: {sol.explanation}")

            report_parts.extend(error_section)

        # تجميع كل الأجزاء في سلسلة نصية واحدة وإرجاعها
        return "\n".join(report_parts)

    def _generate_json_report(self, errors: List[Error]) -> str:
        """
        ينشئ تقريرًا بصيغة JSON. مفيد للدمج مع أدوات أخرى أو للتحليل الآلي.
        """
        # تحويل قائمة كائنات Error إلى قائمة قواميس (dictionaries)
        errors_as_dicts = []
        for error in errors:
            # نقوم بنسخ القاموس لتحويل بعض الكائنات إلى نصوص
            error_dict = error.__dict__.copy()
            error_dict['type'] = error.type.value  # تحويل Enum إلى قيمتها النصية
            error_dict['severity'] = error.severity.name  # تحويل Enum إلى اسمها النصي
            # تحويل الحلول إلى قواميس أيضًا
            error_dict['solutions'] = [sol.__dict__ for sol in error.solutions]
            errors_as_dicts.append(error_dict)

        # تحويل القائمة إلى سلسلة JSON منسقة
        return json.dumps(errors_as_dicts, indent=2, ensure_ascii=False)

    def _generate_html_report(self, errors: List[Error]) -> str:
        """
        ينشئ تقرير HTML أساسي. (هذا مجرد هيكل، يمكن تطويره بشكل كبير).
        """
        # يمكن إضافة CSS هنا لجعله أجمل
        html = f"""
        <html>
        <head>
            <title>تقرير تحليل الأخطاء</title>
            <style>
                body {{ font-family: sans-serif; margin: 2em; }}
                h1 {{ color: #333; }}
                .error-card {{ border: 1px solid #ccc; border-radius: 8px; margin-bottom: 1em; padding: 1em; }}
                .severity-CRITICAL {{ border-left: 5px solid red; }}
                .severity-HIGH {{ border-left: 5px solid orange; }}
                .severity-MEDIUM {{ border-left: 5px solid #007bff; }}
                pre {{ background-color: #f4f4f4; padding: 1em; border-radius: 4px; white-space: pre-wrap; }}
            </style>
        </head>
        <body>
            <h1>📊 تقرير تحليل الأخطاء - تم العثور على {len(errors)} خطأ</h1>
        """

        errors.sort(key=lambda e: e.severity.value, reverse=True)

        for error in errors:
            html += f"""
            <div class="error-card severity-{error.severity.name}">
                <h3>📍 [{error.severity.name}] {error.message}</h3>
                <p><strong>الموقع:</strong> {error.file_path or 'N/A'}:{error.line_number or 'N/A'}</p>
                <h4>الكود:</h4>
                <pre><code>{error.code_snippet or "غير متوفر"}</code></pre>
            """
            if error.solutions:
                html += "<h4>💡 الحلول المقترحة:</h4><ul>"
                for sol in error.solutions:
                    html += f"<li><strong>{sol.description}</strong> (الثقة: {sol.confidence:.0%})<br><small>{sol.explanation or ''}</small></li>"
                html += "</ul>"

            html += "</div>"

        html += """
        </body>
        </html>
        """
        return html

def display_diff(original_code: str, new_code: str):
        """
        تعرض الفروقات بين سلسلتين نصيتين (الكود الأصلي والجديد)
        بشكل منسق وواضح باستخدام ألوان للتمييز في الطرفية.
        """

        # تعريف رموز الألوان (ANSI escape codes)
        # يمكن تعريفها كثوابت لجعل الكود أكثر قابلية للقراءة
        class Colors:
            RESET = '\033[0m'  # لإعادة اللون إلى الوضع الطبيعي
            RED = '\033[91m'  # لون أحمر للإضافات (الأسطر المحذوفة)
            GREEN = '\033[92m'  # لون أخضر للحذف (الأسطر المضافة)
            YELLOW = '\033[93m'  # لون أصفر لمعلومات الـ diff
            GRAY = '\033[90m'  # لون رمادي للأسطر التي لم تتغير (للسياق)

        # 1. تحويل السلاسل النصية إلى قوائم من الأسطر
        # `splitlines()` هو أفضل من `split('\n')` لأنه يتعامل مع نهايات الأسطر المختلفة
        original_lines = original_code.splitlines()
        new_lines = new_code.splitlines()

        # 2. إنشاء كائن `differ` الذي يقوم بالمقارنة
        # يمكن استخدام `difflib.unified_diff` أو `difflib.context_diff` أيضًا
        # ولكن `ndiff` يعطي تحكمًا دقيقًا في كل سطر
        differ = difflib.ndiff(original_lines, new_lines)

        # 3. بناء رأس واضح للـ diff
        print(f"\n{Colors.YELLOW}--- 💡 عرض التغيير المقترح ---{Colors.RESET}")
        print(f"{Colors.RED}- الكود الأصلي{Colors.RESET}")
        print(f"{Colors.GREEN}+ الكود المقترح{Colors.RESET}")
        print("-" * 30)

        # 4. المرور على كل سطر في نتيجة المقارنة وطباعته باللون المناسب
        has_changes = False
        for line in differ:
            # line[0] يحتوي على رمز الحالة:
            #   '-': موجود فقط في السلسلة الأولى (الأصل)
            #   '+': موجود فقط في السلسلة الثانية (الجديد)
            #   ' ': موجود في كليهما (لم يتغير)
            #   '?': سطر معلومات إضافية عن الفروقات الدقيقة داخل السطر

            if line.startswith('+ '):
                # اطبع السطر المضاف باللون الأخضر
                print(f"{Colors.GREEN}{line}{Colors.RESET}")
                has_changes = True
            elif line.startswith('- '):
                # اطبع السطر المحذوف باللون الأحمر
                print(f"{Colors.RED}{line}{Colors.RESET}")
                has_changes = True
            elif line.startswith('? '):
                # هذا السطر يشير إلى الفروقات داخل السطر نفسه، وهو مفيد جدًا
                # لكن يمكن تجاهله لتبسيط العرض
                pass  # نتجاهله حاليًا لعدم إرباك المستخدم
            else:
                # يمكن طباعة الأسطر التي لم تتغير بلون باهت لإعطاء سياق
                # print(f"{Colors.GRAY}{line}{Colors.RESET}")
                pass  # أو تجاهلها تمامًا للتركيز على التغيير فقط

        if not has_changes:
            print(
                f"{Colors.GRAY}(لا توجد تغييرات مرئية، قد تكون هناك تغييرات في المسافات البيضاء فقط){Colors.RESET}")



def analyze_errors(
    paths: List[str],
    solution_engine: SolutionEngine,
    fix_mode: bool = False,
    is_project: bool = False,
    report_format: str = 'text'
):
    """
    الدالة المحورية لتحليل الأخطاء في الملفات أو المشاريع.

    تقوم هذه الدالة بتنسيق عملية التحليل، ثم تقرر ما إذا كانت ستعرض
    تقريرًا بناءً على الأخطاء المكتشفة، أو ستدخل في وضع الإصلاح التفاعلي.

    Args:
        paths (List[str]): قائمة بمسارات الملفات أو مسار المشروع للتحليل.
        solution_engine (SolutionEngine): كائن محرك الحلول الذي تم إنشاؤه مسبقًا.
        fix_mode (bool): إذا كانت True، ستدخل الأداة في وضع الإصلاح التفاعلي.
        is_project (bool): إذا كانت True، سيتم التعامل مع المسار كمشروع كامل.
        report_format (str): صيغة التقرير المطلوب (text, json, html).
    """

    # 1. طباعة رسالة بداية واضحة لتحسين تجربة المستخدم
    analysis_target = f"project at '{paths[0]}'" if is_project else f"{len(paths)} file(s)"
    print(f"\n🚀 Starting analysis for {analysis_target}...")

    # 2. إنشاء كائن المحلل وتمرير محرك الحلول إليه
    # هذا يتبع مبدأ "حقن التبعية" (Dependency Injection)
    try:
        analyzer = SmartErrorAnalyzer(solution_engine)
    except Exception as e:
        print(f"\n❌ Fatal Error: Could not initialize the error analyzer: {e}")
        return  # الخروج من الدالة في حالة فشل التهيئة

    # 3. تنفيذ التحليل الفعلي (إما للمشروع أو للملفات)
    errors: List[Error] = []
    try:
        if is_project:
            if not os.path.isdir(paths[0]):
                print(
                    f"\n❌ Error: The specified project path does not exist or is not a directory: {paths[0]}")
                return
            print("Analyzing project structure...")
            errors = analyzer.analyze_project(paths[0])
        else:
            # التحقق من وجود الملفات قبل البدء
            valid_paths = [p for p in paths if os.path.exists(p)]
            invalid_paths = [p for p in paths if not os.path.exists(p)]
            if invalid_paths:
                print(f"⚠️ Warning: The following file(s) were not found and will be skipped:")
                for p in invalid_paths:
                    print(f"  - {p}")
            if not valid_paths:
                print("\n❌ Error: No valid files to analyze.")
                return

            errors = analyzer.analyze_files(valid_paths)

    except Exception as e:
        print(f"\n❌ An unexpected error occurred during the analysis phase: {e}")
        traceback.print_exc()  # طباعة التتبع الكامل للمساعدة في تصحيح الأخطاء
        return

    # 4. معالجة النتائج بعد انتهاء التحليل
    print(f"✅ Analysis complete. Found {len(errors)} potential issue(s).")

    # 5. اتخاذ القرار بناءً على النتائج ووضع التشغيل
    if not errors:
        # لا توجد أخطاء، لا داعي لعمل أي شيء آخر
        return

    # إذا وجدنا أخطاء، نقرر هل سنصلح أم سنبلغ فقط
    if fix_mode:
        # وضع الإصلاح التفاعلي
        print("\n🛠️ Entering interactive fix mode...")
        # استدعاء الدالة المخصصة للتعامل مع الإصلاحات
        apply_fixes_interactively(errors)
    else:
        # وضع التقرير العادي
        print("\n📄 Generating report...")
        # إنشاء مولد التقارير واستخدامه
        report_generator = ErrorReportGenerator()
        report = report_generator.generate_report(errors, format=report_format)

        # إذا كان التقرير HTML، قد نرغب في حفظه في ملف بدلاً من طباعته
        if report_format == 'html':
            report_file_name = f"error_report_{datetime.now().strftime('%Y%m%d_%H%M%S')}.html"
            with open(report_file_name, "w", encoding="utf-8") as f:
                f.write(report)
            print(f"✅ HTML report saved to: {report_file_name}")
        else:
            # طباعة التقرير النصي أو JSON
            print(report)

def apply_fixes_interactively(errors: List[Error]):
    """
    تتكرر عبر الأخطاء وتعرض الإصلاحات المقترحة على المستخدم للموافقة.
    """

    # فرز الأخطاء حسب الأولوية
    errors.sort(key=lambda e: e.severity.value, reverse=True)
    fixed_count = 0

    for i, error in enumerate(errors):
        print("\n" + "=" * 60)
        print(
            f"Error {i + 1}/{len(errors)}: [{error.severity.name}] in {error.file_path}:{error.line_number}")
        print(f"Message: {error.message}")

        # البحث عن أفضل حل قابل للتطبيق تلقائيًا
        best_solution = None
        for sol in sorted(error.solutions, key=lambda s: s.confidence, reverse=True):
            if sol.auto_applicable and sol.code_fix:
                best_solution = sol
                break  # وجدنا أفضل حل

        if not best_solution:
            print("--> No automatically applicable solution found for this error.")
            continue

        print(
            f"\n💡 Suggested solution (Confidence: {best_solution.confidence:.0%}): {best_solution.description}")
        if best_solution.explanation:
            print(f"   Explanation: {best_solution.explanation}")

        try:
            # قراءة الكود الأصلي لعرض الفروقات
            with open(error.file_path, 'r', encoding='utf-8') as f:
                original_lines = f.readlines()

            # الحصول على الكود الأصلي الذي سيتم استبداله
            # ملاحظة: هذا منطق مبسط، قد يحتاج لتحسين إذا كان الخطأ يمتد لأسطر متعددة
            original_code_snippet = original_lines[error.line_number - 1]

            display_diff(original_code_snippet, best_solution.code_fix + '\n')

            choice = input("Apply this fix? [Y/n/s(kip all)] ").lower().strip()

            if choice == 's':
                print("Skipping all remaining fixes.")
                break
            elif choice == 'n':
                print("Skipping this fix.")
                continue
            elif choice == '' or choice == 'y':
                # تطبيق الإصلاح
                original_lines[error.line_number - 1] = best_solution.code_fix + '\n'
                with open(error.file_path, 'w', encoding='utf-8') as f:
                    f.writelines(original_lines)
                print(f"✅ Fixed successfully in {error.file_path}")
                fixed_count += 1
            else:
                print("Invalid choice. Skipping fix.")

        except Exception as e:
            print(f"--> [Error] Could not apply fix for '{error.message}': {e}")

    print("\n" + "=" * 60)
    print(f"Interactive fix session finished. {fixed_count} error(s) fixed.")


if __name__ == "__main__":
    parser = argparse.ArgumentParser(
        description='نظام تحليل الأخطاء وإعادة الهيكلة المتقدم لـ Gemini CLI',
        formatter_class=argparse.RawTextHelpFormatter
    )
    # -- التعديل: paths الآن ليست إجبارية دائماً --
    parser.add_argument('paths', nargs='*', help='مسار الملفات أو المشروع للتحليل')
    parser.add_argument('--project', action='store_true',
                        help='تحديد ما إذا كان المسار مشروعًا كاملاً لتحليل الأخطاء')
    parser.add_argument('--format', default='text', choices=['text', 'json', 'html'],
                        help='صيغة تقرير الأخطاء')

    # --- الإضافة الجديدة ---
    parser.add_argument(
        '--refactor',
        metavar='FILE_PATH',
        help='تشغيل وضع إعادة الهيكلة لملف معين.'
    )

    parser.add_argument(
        '--generate-tests',
        metavar='FILE_PATH',
        help='يولد حالات اختبار Flutter/Dart لملف معين.'  # <--- يمكن تعديل نص المساعدة ليكون أوضح
    )

    parser.add_argument(
        '--explain',
        metavar='FILE_PATH',
        help='يقدم شرحاً مفصلاً لكود Dart/Flutter في ملف معين.'
    )

    parser.add_argument(
        '--analyze-deps',
        action='store_true',  # لا يأخذ قيمة، وجوده يعني التفعيل
        help='يحلل ملف pubspec.yaml في المشروع الحالي ويقدم تقريرًا عن التبعيات.'
    )

    parser.add_argument(
        '--fix',
        action='store_true',
        help='محاولة إصلاح الأخطاء القابلة للإصلاح تلقائيًا بشكل تفاعلي.'
    )

    args = parser.parse_args()

    try:
        solution_engine = SolutionEngine()
    except ValueError as e:
        print(e, file=sys.stderr)
        sys.exit(1)

    if args.refactor:
        # ** وضع إعادة الهيكلة **
        file_to_refactor = args.refactor
        solution_engine.get_refactoring_suggestions(file_to_refactor)

    elif args.generate_tests:
        # ** وضع توليد الاختبارات **
        file_to_test = args.generate_tests
        solution_engine.generate_test_cases(file_to_test)

    elif args.explain:
        # ** وضع شرح الكود **
        file_to_explain = args.explain
        solution_engine.explain_code(file_to_explain)


    elif args.analyze_deps:
        # ** وضع تحليل التبعيات **
        solution_engine.analyze_dependencies()




    elif args.paths:
        # ** وضع تحليل الأخطاء (الوضع الافتراضي) **
        if args.project and len(args.paths) > 1:
            print("خطأ: عند استخدام --project، يرجى تحديد مسار واحد فقط للمشروع.", file=sys.stderr)
            sys.exit(1)

        # نستدعي الدالة القديمة لتحليل الأخطاء
        # ولكن نمرر لها محرك الحلول الذي تم إنشاؤه بالفعل
        analyze_errors(args.paths, solution_engine, fix_mode=args.fix, is_project=args.project,
                       report_format=args.format)
    else:
        # في حالة عدم تمرير أي خيار
        parser.print_help()
        sys.exit(1)
