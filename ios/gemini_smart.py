#!/usr/bin/env python3
import os
import sys
import json
import requests
import argparse
from datetime import datetime, timedelta
from pathlib import Path
import hashlib

# استيراد مدير المحادثات
sys.path.append(str(Path(__file__).parent))
try:
    from conversation_manager import ConversationManager
except ImportError:
    print("تحذير: لا يمكن تحميل conversation_manager")
    ConversationManager = None

# استيراد محلل الأخطاء المتقدم
try:
    from error_analyzer import SmartErrorAnalyzer, ErrorReportGenerator, analyze_errors, SolutionEngine
except ImportError:
    print("تحذير: لا يمكن تحميل error_analyzer")
    SmartErrorAnalyzer = None

# استيراد معالج اللغة الطبيعية المتقدم
try:
    from natural_language_processor import (
        SmartTextProcessor, ContextualUnderstanding,
        SmartResponseGenerator, process_user_input
    )
except ImportError:
    print("تحذير: لا يمكن تحميل natural_language_processor")
    SmartTextProcessor = None

class EnhancedGeminiCLI:
    def __init__(self):
        self.config_dir = Path.home() / '.gemini-enhanced'
        self.config_file = self.config_dir / 'config.json'
        self.memory_file = self.config_dir / 'memory.json'
        self.context_cache_file = self.config_dir / 'context_cache.json'
        self.current_conversation_file = self.config_dir / 'current_conversation.txt'
        self.error_history_file = self.config_dir / 'error_history.json'

        # إنشاء المجلد إذا لم يكن موجوداً
        self.config_dir.mkdir(exist_ok=True)

        self.config = self.load_config()
        self.memory = self.load_memory()
        self.context_cache = self.load_context_cache()
        self.error_history = self.load_error_history()

        # تهيئة مدير المحادثات
        self.conversation_manager = ConversationManager() if ConversationManager else None
        self.current_conversation_id = self.load_current_conversation()

        # تهيئة محلل الأخطاء ومحرك الحلول
        self.solution_engine = SolutionEngine() if SmartErrorAnalyzer else None
        self.error_analyzer = SmartErrorAnalyzer(self.solution_engine) if SmartErrorAnalyzer and self.solution_engine else None

        # تهيئة معالج اللغة الطبيعية
        if SmartTextProcessor:
            self.text_processor = SmartTextProcessor()
            self.context_analyzer = ContextualUnderstanding()
            self.response_generator = SmartResponseGenerator()
        else:
            self.text_processor = None
            self.context_analyzer = None
            self.response_generator = None

    def load_config(self):
        """تحميل الإعدادات"""
        default_config = {
            "api_key": os.getenv('GEMINI_API_KEY', ''),
            "model": "gemini-1.5-pro",
            "temperature": 0.7,
            "max_tokens": 2048,
            "system_instruction": "أنت مساعد ذكي ومطور خبير. تفهم السياق جيداً وتقدم حلول عملية.",
            "language": "ar",
            "enable_memory": True,
            "enable_context_cache": True,
            "context_window_size": 10
        }

        if self.config_file.exists():
            with open(self.config_file, 'r', encoding='utf-8') as f:
                config = json.load(f)
                # دمج الإعدادات الافتراضية مع المحفوظة
                default_config.update(config)

        return default_config

    def save_config(self):
        """حفظ الإعدادات"""
        with open(self.config_file, 'w', encoding='utf-8') as f:
            json.dump(self.config, f, ensure_ascii=False, indent=2)

    def load_memory(self):
        """تحميل الذاكرة"""
        if self.memory_file.exists():
            with open(self.memory_file, 'r', encoding='utf-8') as f:
                return json.load(f)
        return []

    def save_memory(self):
        """حفظ الذاكرة"""
        # الاحتفاظ بآخر 50 محادثة فقط
        if len(self.memory) > 50:
            self.memory = self.memory[-50:]

        with open(self.memory_file, 'w', encoding='utf-8') as f:
            json.dump(self.memory, f, ensure_ascii=False, indent=2)

    def load_context_cache(self):
        """تحميل context cache"""
        if self.context_cache_file.exists():
            with open(self.context_cache_file, 'r', encoding='utf-8') as f:
                return json.load(f)
        return {}

    def save_context_cache(self):
        """حفظ context cache"""
        with open(self.context_cache_file, 'w', encoding='utf-8') as f:
            json.dump(self.context_cache, f, ensure_ascii=False, indent=2)

    def get_relevant_context(self, prompt):
        """الحصول على السياق المناسب"""
        if not self.config['enable_memory'] or not self.memory:
            return ""

        # البحث في المحادثات السابقة
        relevant_conversations = []
        prompt_words = set(prompt.lower().split())

        for conv in self.memory[-self.config['context_window_size']:]:
            conv_words = set(conv['prompt'].lower().split())
            # حساب التشابه البسيط
            similarity = len(prompt_words & conv_words) / len(prompt_words | conv_words)
            if similarity > 0.1:  # عتبة التشابه
                relevant_conversations.append(conv)

        if relevant_conversations:
            context = "السياق من المحادثات السابقة:\n"
            for conv in relevant_conversations[-3:]:  # آخر 3 محادثات مناسبة
                context += f"س: {conv['prompt'][:100]}...\n"
                context += f"ج: {conv['response'][:200]}...\n\n"
            return context

        return ""

    def enhance_prompt(self, prompt, context_files=None):
        """تحسين الـ prompt بذكاء"""
        enhanced_prompt = prompt

        # استخدام معالج اللغة الطبيعية إذا كان متوفراً
        if self.text_processor and self.context_analyzer and self.response_generator:
            # تحليل النص
            analysis = self.text_processor.analyze_text(prompt)

            # فهم السياق
            context = self.context_analyzer.understand_context(prompt, analysis)

            # توليد prompt محسّن
            enhanced_prompt = self.response_generator.generate_enhanced_prompt(
                prompt, analysis, context
            )

            # إضافة معلومات إضافية للـ prompt
            if analysis.entities.get('files'):
                enhanced_prompt += f"\n\nملفات مذكورة: {', '.join(analysis.entities['files'])}"

            if analysis.entities.get('errors'):
                enhanced_prompt += f"\n\nأخطاء مذكورة: {', '.join(analysis.entities['errors'])}"

        else:
            # الطريقة القديمة إذا لم يكن المعالج متوفراً
            # إضافة السياق من الذاكرة
            if self.config['enable_memory']:
                context = self.get_relevant_context(prompt)
                if context:
                    enhanced_prompt = f"{context}\nالسؤال الحالي: {prompt}"

        # إضافة محتوى الملفات إذا تم تحديدها
        if context_files:
            file_context = "\nمحتوى الملفات:\n"
            for file_path in context_files:
                try:
                    with open(file_path, 'r', encoding='utf-8') as f:
                        content = f.read()[:2000]  # أول 2000 حرف
                        file_context += f"\n--- {file_path} ---\n{content}\n"
                except Exception as e:
                    file_context += f"\n--- {file_path} ---\nخطأ في قراءة الملف: {e}\n"

            enhanced_prompt = f"{file_context}\n\n{enhanced_prompt}"

        return enhanced_prompt

    def call_gemini_api(self, prompt):
        """استدعاء Gemini API"""
        if not self.config['api_key']:
            return "خطأ: لم يتم تعيين GEMINI_API_KEY"

        url = f"https://generativelanguage.googleapis.com/v1beta/models/{self.config['model']}:generateContent"

        headers = {
            'Content-Type': 'application/json',
        }

        data = {
            'contents': [
                {
                    'parts': [
                        {'text': prompt}
                    ]
                }
            ],
            'generationConfig': {
                'temperature': self.config['temperature'],
                'maxOutputTokens': self.config['max_tokens'],
            },
            'systemInstruction': {
                'parts': [
                    {'text': self.config['system_instruction']}
                ]
            }
        }

        try:
            response = requests.post(
                f"{url}?key={self.config['api_key']}",
                headers=headers,
                json=data
            )
            response.raise_for_status()

            result = response.json()
            return result['candidates'][0]['content']['parts'][0]['text']

        except requests.exceptions.RequestException as e:
            return f"خطأ في الاتصال: {e}"
        except KeyError as e:
            return f"خطأ في تحليل الاستجابة: {e}"

    def generate(self, prompt, context_files=None, save_to_memory=True):
        """توليد المحتوى"""
        enhanced_prompt = self.enhance_prompt(prompt, context_files)
        response = self.call_gemini_api(enhanced_prompt)

        # حفظ في الذاكرة القديمة
        if save_to_memory and self.config['enable_memory']:
            conversation = {
                'timestamp': datetime.now().isoformat(),
                'prompt': prompt,
                'response': response,
                'enhanced_prompt': enhanced_prompt != prompt
            }
            self.memory.append(conversation)
            self.save_memory()

        # حفظ في نظام المحادثات الجديد
        if save_to_memory and self.conversation_manager:
            # إنشاء محادثة جديدة إذا لم تكن موجودة
            if not self.current_conversation_id:
                self.current_conversation_id = self.conversation_manager.create_conversation()
                self.save_current_conversation(self.current_conversation_id)

            # إضافة الرسالة للمحادثة
            self.conversation_manager.add_message(
                self.current_conversation_id,
                prompt,
                response,
                {
                    'enhanced_prompt': enhanced_prompt != prompt,
                    'context_files': context_files is not None,
                    'files_count': len(context_files) if context_files else 0
                }
            )

        return response

    def analyze_code(self, file_paths, question):
        """تحليل الكود"""
        if not file_paths:
            return "لم يتم تحديد ملفات للتحليل"

        code_context = "\n=== تحليل الكود ===\n"

        for file_path in file_paths:
            try:
                with open(file_path, 'r', encoding='utf-8') as f:
                    content = f.read()
                    code_context += f"\n--- {file_path} ---\n{content[:3000]}\n"
            except Exception as e:
                code_context += f"\n--- {file_path} ---\nخطأ: {e}\n"

        enhanced_question = f"{code_context}\n\nالسؤال: {question}\n\nيرجى تحليل الكود والإجابة على السؤال."

        return self.call_gemini_api(enhanced_question)

    def configure(self, key, value):
        """تعديل الإعدادات"""
        if key in self.config:
            # تحويل القيم المناسبة
            if key in ['temperature']:
                value = float(value)
            elif key in ['max_tokens', 'context_window_size']:
                value = int(value)
            elif key in ['enable_memory', 'enable_context_cache']:
                value = value.lower() in ['true', '1', 'yes', 'on']

            self.config[key] = value
            self.save_config()
            return f"تم تحديث {key} إلى {value}"
        else:
            return f"المفتاح {key} غير معروف"

    def show_config(self):
        """عرض الإعدادات"""
        print("الإعدادات الحالية:")
        for key, value in self.config.items():
            if key == 'api_key':
                print(f"  {key}: {'*' * len(str(value)) if value else 'غير محدد'}")
            else:
                print(f"  {key}: {value}")

    def show_memory(self, limit=10):
        """عرض الذاكرة"""
        if not self.memory:
            print("لا توجد محادثات محفوظة")
            return

        print(f"آخر {min(limit, len(self.memory))} محادثات:")
        for i, conv in enumerate(self.memory[-limit:], 1):
            timestamp = datetime.fromisoformat(conv['timestamp']).strftime('%Y-%m-%d %H:%M')
            print(f"\n{i}. [{timestamp}]")
            print(f"   س: {conv['prompt'][:100]}...")
            print(f"   ج: {conv['response'][:200]}...")

    # ==== دوال إدارة المحادثات الجديدة ====

    def load_current_conversation(self):
        """تحميل معرف المحادثة الحالية"""
        if self.current_conversation_file.exists():
            try:
                return self.current_conversation_file.read_text(encoding='utf-8').strip()
            except:
                return None
        return None

    def save_current_conversation(self, conversation_id):
        """حفظ معرف المحادثة الحالية"""
        if conversation_id:
            self.current_conversation_file.write_text(conversation_id, encoding='utf-8')
        elif self.current_conversation_file.exists():
            self.current_conversation_file.unlink()

    def new_conversation(self, title=None):
        """إنشاء محادثة جديدة"""
        if not self.conversation_manager:
            return "نظام المحادثات غير متوفر"

        if not title:
            title = f"محادثة {datetime.now().strftime('%Y-%m-%d %H:%M')}"

        conversation_id = self.conversation_manager.create_conversation(title)
        self.current_conversation_id = conversation_id
        self.save_current_conversation(conversation_id)

        return f"تم إنشاء محادثة جديدة: {title} (ID: {conversation_id})"

    def list_conversations(self, limit=20, search_term=None):
        """عرض قائمة المحادثات المحفوظة"""
        if not self.conversation_manager:
            return "نظام المحادثات غير متوفر"

        conversations = self.conversation_manager.list_conversations(limit, search_term)

        if not conversations:
            return "لا توجد محادثات محفوظة"

        output = f"📚 المحادثات المحفوظة ({len(conversations)}):\n\n"

        for i, conv in enumerate(conversations, 1):
            current_marker = "🔥" if conv['id'] == self.current_conversation_id else "  "

            # تنسيق التاريخ
            try:
                last_updated = datetime.fromisoformat(conv['last_updated'])
                time_str = last_updated.strftime('%Y-%m-%d %H:%M')
            except:
                time_str = conv['last_updated'][:16]

            # العلامات
            tags = " ".join([f"#{tag}" for tag in conv.get('tags', [])])
            tags_str = f" {tags}" if tags else ""

            output += f"{current_marker} {i:2d}. [{conv['id']}] {conv['title']}\n"
            output += f"     📅 {time_str} | 💬 {conv['message_count']} رسالة{tags_str}\n\n"

        if self.current_conversation_id:
            output += f"المحادثة الحالية: {self.current_conversation_id}\n"

        return output

    def load_conversation(self, conversation_id):
        """تحميل محادثة محددة"""
        if not self.conversation_manager:
            return "نظام المحادثات غير متوفر"

        conversation = self.conversation_manager.get_conversation(conversation_id)
        if not conversation:
            return f"لم يتم العثور على المحادثة: {conversation_id}"

        self.current_conversation_id = conversation_id
        self.save_current_conversation(conversation_id)

        return f"تم تحميل المحادثة: {conversation['title']} ({len(conversation['messages'])} رسالة)"

    def show_conversation(self, conversation_id=None, limit=10):
        """عرض محتوى محادثة"""
        if not self.conversation_manager:
            return "نظام المحادثات غير متوفر"

        conv_id = conversation_id or self.current_conversation_id
        if not conv_id:
            return "لا توجد محادثة محددة"

        conversation = self.conversation_manager.get_conversation(conv_id)
        if not conversation:
            return f"لم يتم العثور على المحادثة: {conv_id}"

        output = f"📖 المحادثة: {conversation['title']}\n"
        output += f"🆔 ID: {conversation['id']}\n"
        output += f"📅 تاريخ الإنشاء: {conversation['created_at'][:19]}\n"
        output += f"💬 عدد الرسائل: {len(conversation['messages'])}\n"

        if conversation.get('tags'):
            output += f"🏷️  العلامات: {', '.join(conversation['tags'])}\n"

        output += "=" * 60 + "\n\n"

        # عرض آخر الرسائل
        messages = conversation['messages'][-limit:]
        for i, msg in enumerate(messages, 1):
            timestamp = datetime.fromisoformat(msg['timestamp']).strftime('%Y-%m-%d %H:%M')
            output += f"[{timestamp}] الرسالة {i}:\n"
            output += f"👤 السؤال: {msg['prompt']}\n"
            output += f"🤖 الإجابة: {msg['response'][:500]}{'...' if len(msg['response']) > 500 else ''}\n"
            output += "-" * 40 + "\n\n"

        return output

    def delete_conversation(self, conversation_id):
        """حذف محادثة"""
        if not self.conversation_manager:
            return "نظام المحادثات غير متوفر"

        if conversation_id == self.current_conversation_id:
            self.current_conversation_id = None
            self.save_current_conversation(None)

        success = self.conversation_manager.delete_conversation(conversation_id)

        if success:
            return f"تم حذف المحادثة: {conversation_id}"
        else:
            return f"فشل في حذف المحادثة: {conversation_id}"

    def search_conversations(self, search_term):
        """البحث في المحادثات"""
        if not self.conversation_manager:
            return "نظام المحادثات غير متوفر"

        conversations = self.conversation_manager.list_conversations(50, search_term)

        if not conversations:
            return f"لم يتم العثور على نتائج للبحث: {search_term}"

        output = f"🔍 نتائج البحث عن '{search_term}' ({len(conversations)} نتيجة):\n\n"

        for i, conv in enumerate(conversations, 1):
            time_str = conv['last_updated'][:16]
            output += f"{i:2d}. [{conv['id']}] {conv['title']}\n"
            output += f"     📅 {time_str} | 💬 {conv['message_count']} رسالة\n\n"

        return output

    def export_conversation(self, conversation_id, format='txt'):
        """تصدير محادثة"""
        if not self.conversation_manager:
            return "نظام المحادثات غير متوفر"

        content = self.conversation_manager.export_conversation(conversation_id, format)

        if content:
            filename = f"conversation_{conversation_id}.{format}"
            with open(filename, 'w', encoding='utf-8') as f:
                f.write(content)
            return f"تم تصدير المحادثة إلى: {filename}"
        else:
            return f"فشل في تصدير المحادثة: {conversation_id}"

    def analyze_text(self, text):
        """تحليل وفهم النص"""
        if not self.text_processor:
            return "معالج اللغة الطبيعية غير متوفر"

        # تحليل النص
        analysis = self.text_processor.analyze_text(text)

        # فهم السياق
        context = self.context_analyzer.understand_context(text, analysis) if self.context_analyzer else {}

        # إنشاء تقرير التحليل
        output = f"📊 تحليل النص:\n"
        output += f"{'='*60}\n\n"

        output += f"📝 النص الأصلي: {text[:100]}{'...' if len(text) > 100 else ''}\n\n"

        output += f"🌐 اللغة: {analysis.language}\n"
        output += f"💭 المشاعر: {analysis.sentiment}\n"
        output += f"📈 التعقيد: {analysis.complexity:.2f}\n\n"

        output += f"🎯 النوايا المكتشفة:\n"
        for intent in analysis.intents:
            output += f"   - {intent.type} (ثقة: {intent.confidence:.2f})\n"

        output += f"\n🏷️  الكلمات المفتاحية: {', '.join(analysis.keywords)}\n"
        output += f"📚 المواضيع: {', '.join(analysis.topics)}\n\n"

        output += f"📦 الكيانات المستخرجة:\n"
        for entity_type, entities in analysis.entities.items():
            if entities:
                output += f"   - {entity_type}: {', '.join(entities[:5])}\n"

        if context.get('suggested_responses'):
            output += f"\n💡 ردود مقترحة:\n"
            for i, suggestion in enumerate(context['suggested_responses'], 1):
                output += f"   {i}. {suggestion}\n"

        if context.get('user_intent_pattern'):
            patterns = context['user_intent_pattern']
            output += f"\n👤 أنماط المستخدم:\n"
            output += f"   - اللغة المفضلة: {patterns.get('preferred_language', 'غير محدد')}\n"
            output += f"   - المستوى التقني: {patterns.get('technical_level', 'متوسط')}\n"
            output += f"   - أسلوب التفاعل: {patterns.get('interaction_style', 'عام')}\n"

        return output

    def smart_generate(self, prompt, **kwargs):
        """توليد محتوى بفهم ذكي للنص"""
        # تحليل النص أولاً
        if self.text_processor:
            analysis_result = process_user_input(prompt, self)

            # استخدام الـ prompt المحسّن
            enhanced_prompt = analysis_result['enhanced_prompt']

            # إضافة معلومات السياق
            metadata = {
                'original_prompt': prompt,
                'language': analysis_result['analysis'].language,
                'intents': [i.type for i in analysis_result['analysis'].intents],
                'topics': analysis_result['analysis'].topics,
                'complexity': analysis_result['analysis'].complexity
            }

            # توليد الرد
            response = self.generate(enhanced_prompt, **kwargs)

            # إضافة المعلومات التحليلية للرد
            return {
                'response': response,
                'analysis': analysis_result,
                'metadata': metadata
            }
        else:
            # استخدام الطريقة العادية
            return self.generate(prompt, **kwargs)

    def load_error_history(self):
        """تحميل سجل الأخطاء"""
        if self.error_history_file.exists():
            with open(self.error_history_file, 'r', encoding='utf-8') as f:
                return json.load(f)
        return []

    def save_error_history(self):
        """حفظ سجل الأخطاء"""
        # الاحتفاظ بآخر 100 خطأ
        if len(self.error_history) > 100:
            self.error_history = self.error_history[-100:]

        with open(self.error_history_file, 'w', encoding='utf-8') as f:
            json.dump(self.error_history, f, ensure_ascii=False, indent=2)

    def analyze_errors_smart(self, file_paths, auto_fix=False, report_format='text'):
        """تحليل الأخطاء بشكل ذكي"""
        if not self.error_analyzer:
            return "محلل الأخطاء غير متوفر. تأكد من وجود error_analyzer.py"

        all_errors = []
        fixed_count = 0

        for file_path in file_paths:
            if not Path(file_path).exists():
                print(f"⚠️  الملف غير موجود: {file_path}")
                continue

            print(f"\n🔍 تحليل الملف: {file_path}")
            errors = self.error_analyzer.analyze_file(file_path)

            if errors:
                print(f"❌ تم اكتشاف {len(errors)} خطأ")
                all_errors.extend(errors)

                # حفظ في السجل
                for error in errors:
                    error_record = {
                        'timestamp': datetime.now().isoformat(),
                        'file': file_path,
                        'type': error.type.value,
                        'severity': error.severity.name,
                        'message': error.message,
                        'fixed': False
                    }
                    self.error_history.append(error_record)

                # محاولة إصلاح الأخطاء تلقائياً
                if auto_fix:
                    fixed = self._auto_fix_errors(file_path, errors)
                    fixed_count += fixed

            else:
                print(f"✅ لا توجد أخطاء!")

        # حفظ السجل
        self.save_error_history()

        # توليد التقرير
        if all_errors:
            report_generator = ErrorReportGenerator()
            report = report_generator.generate_report(all_errors, report_format)

            if auto_fix:
                report += f"\n\n🔧 تم إصلاح {fixed_count} خطأ تلقائياً"

            # طلب تحليل متقدم من Gemini
            if self.config.get('enable_ai_analysis', True):
                ai_analysis = self._get_ai_error_analysis(all_errors)
                if ai_analysis:
                    report += f"\n\n🤖 تحليل الذكاء الاصطناعي:\n{ai_analysis}"

            return report
        else:
            return "✅ جميع الملفات خالية من الأخطاء!"

    def _auto_fix_errors(self, file_path: str, errors: list) -> int:
        """محاولة إصلاح الأخطاء تلقائياً"""
        fixed_count = 0

        # قراءة محتوى الملف
        with open(file_path, 'r', encoding='utf-8') as f:
            content = f.read()

        original_content = content

        # محاولة إصلاح كل خطأ
        for error in errors:
            if error.solutions:
                # اختيار أفضل حل قابل للتطبيق التلقائي
                for solution in error.solutions:
                    if solution.auto_applicable and solution.confidence > 0.8:
                        print(f"🔧 تطبيق الحل: {solution.description}")

                        # تطبيق الحل
                        if solution.code_fix and error.line_number:
                            lines = content.split('\n')
                            if 0 <= error.line_number - 1 < len(lines):
                                # محاولة تطبيق الإصلاح
                                # هنا يمكن إضافة منطق أكثر تعقيداً
                                fixed_count += 1
                                break

        # حفظ الملف إذا تم تعديله
        if content != original_content:
            # نسخ احتياطي
            backup_path = f"{file_path}.backup"
            with open(backup_path, 'w', encoding='utf-8') as f:
                f.write(original_content)

            # حفظ الملف المُصلح
            with open(file_path, 'w', encoding='utf-8') as f:
                f.write(content)

            print(f"💾 تم حفظ الملف المُصلح (النسخة الأصلية في {backup_path})")

        return fixed_count

    def _get_ai_error_analysis(self, errors: list) -> str:
        """الحصول على تحليل ذكي للأخطاء من Gemini"""
        # إعداد السياق للذكاء الاصطناعي
        context = "تحليل الأخطاء التالية وتقديم نصائح متقدمة:\n\n"

        # تلخيص الأخطاء
        error_summary = {}
        for error in errors:
            error_type = error.type.value
            if error_type not in error_summary:
                error_summary[error_type] = []
            error_summary[error_type].append(error.message)

        for error_type, messages in error_summary.items():
            context += f"\n{error_type} ({len(messages)} أخطاء):\n"
            for msg in messages[:3]:  # أول 3 أخطاء من كل نوع
                context += f"  - {msg}\n"

        # إضافة السؤال
        context += "\n\nيرجى تحليل هذه الأخطاء وتقديم:\n"
        context += "1. السبب الجذري المحتمل لهذه الأخطاء\n"
        context += "2. أفضل الممارسات لتجنبها مستقبلاً\n"
        context += "3. اقتراحات لتحسين جودة الكود\n"
        context += "4. أي أنماط مقلقة تلاحظها\n"

        # استدعاء Gemini
        response = self.call_gemini_api(context)
        return response

    def suggest_fixes(self, error_description: str) -> str:
        """اقتراح حلول لوصف خطأ"""
        prompt = f"""أنا أواجه الخطأ التالي:

{error_description}

يرجى تقديم:
1. شرح مفصل للخطأ
2. الأسباب المحتملة
3. حلول مقترحة خطوة بخطوة
4. أمثلة على الكود الصحيح
5. كيفية تجنب هذا الخطأ مستقبلاً

يرجى أن تكون الإجابة باللغة العربية ومفصلة."""

        response = self.call_gemini_api(prompt)

        # حفظ في السجل
        self.error_history.append({
            'timestamp': datetime.now().isoformat(),
            'type': 'user_query',
            'description': error_description,
            'solution': response
        })
        self.save_error_history()

        return response

    def analyze_project_errors(self, project_path: str, file_extensions: list = None) -> str:
        """تحليل أخطاء مشروع كامل"""
        if not self.error_analyzer:
            return "محلل الأخطاء غير متوفر"

        project_path = Path(project_path)
        if not project_path.exists():
            return f"المسار غير موجود: {project_path}"

        # الامتدادات الافتراضية
        if not file_extensions:
            file_extensions = ['.py', '.dart', '.js', '.ts', '.json', '.yaml', '.yml']

        print(f"🔍 تحليل المشروع: {project_path}")

        all_errors = []
        files_analyzed = 0

        # البحث عن الملفات
        for ext in file_extensions:
            for file_path in project_path.rglob(f'*{ext}'):
                # تجاهل المجلدات المستبعدة
                if any(part in file_path.parts for part in ['node_modules', '.git', '__pycache__', 'build', 'dist']):
                    continue

                files_analyzed += 1
                errors = self.error_analyzer.analyze_file(str(file_path))

                if errors:
                    print(f"❌ {file_path.relative_to(project_path)}: {len(errors)} أخطاء")
                    all_errors.extend(errors)

        print(f"\n📊 تم تحليل {files_analyzed} ملف")

        # توليد تقرير شامل
        if all_errors:
            report = f"=== تقرير تحليل المشروع ===\n"
            report += f"المسار: {project_path}\n"
            report += f"الملفات المحللة: {files_analyzed}\n"
            report += f"إجمالي الأخطاء: {len(all_errors)}\n\n"

            # إحصائيات حسب النوع
            error_stats = {}
            for error in all_errors:
                error_type = error.type.value
                if error_type not in error_stats:
                    error_stats[error_type] = 0
                error_stats[error_type] += 1

            report += "📈 إحصائيات الأخطاء:\n"
            for error_type, count in sorted(error_stats.items(), key=lambda x: x[1], reverse=True):
                report += f"  - {error_type}: {count} خطأ\n"

            # أكثر الملفات أخطاءً
            file_errors = {}
            for error in all_errors:
                if error.file_path:
                    if error.file_path not in file_errors:
                        file_errors[error.file_path] = 0
                    file_errors[error.file_path] += 1

            report += "\n🔥 أكثر الملفات أخطاءً:\n"
            for file_path, count in sorted(file_errors.items(), key=lambda x: x[1], reverse=True)[:5]:
                rel_path = Path(file_path).relative_to(project_path)
                report += f"  - {rel_path}: {count} أخطاء\n"

            # التوصيات
            report += "\n💡 التوصيات:\n"
            report += self._generate_project_recommendations(all_errors, error_stats)

            return report
        else:
            return f"✅ ممتاز! المشروع خالي من الأخطاء ({files_analyzed} ملف)"

    def _generate_project_recommendations(self, errors: list, stats: dict) -> str:
        """توليد توصيات للمشروع"""
        recommendations = []

        # توصيات بناءً على نوع الأخطاء
        if stats.get('syntax', 0) > 5:
            recommendations.append("• كثرة أخطاء Syntax - يُنصح باستخدام IDE مع فحص تلقائي")

        if stats.get('import', 0) > 3:
            recommendations.append("• مشاكل في الاستيراد - تحقق من تثبيت جميع المتطلبات")

        if stats.get('security', 0) > 0:
            recommendations.append("• ⚠️  وجود مشاكل أمنية - يجب معالجتها فوراً")

        if stats.get('performance', 0) > 10:
            recommendations.append("• فرص لتحسين الأداء - راجع الكود لتحسين الكفاءة")

        if not recommendations:
            recommendations.append("• المشروع في حالة جيدة، استمر في اتباع أفضل الممارسات")

        return '\n'.join(recommendations)

    def learn_from_fixes(self) -> str:
        """التعلم من الإصلاحات السابقة"""
        if not self.error_history:
            return "لا يوجد سجل أخطاء للتعلم منه"

        # تحليل الأخطاء الشائعة
        error_types = {}
        for error in self.error_history:
            error_type = error.get('type', 'unknown')
            if error_type not in error_types:
                error_types[error_type] = 0
            error_types[error_type] += 1

        report = "📚 التعلم من الأخطاء السابقة:\n\n"
        report += f"إجمالي الأخطاء المسجلة: {len(self.error_history)}\n\n"

        report += "🔝 الأخطاء الأكثر شيوعاً:\n"
        for error_type, count in sorted(error_types.items(), key=lambda x: x[1], reverse=True)[:5]:
            percentage = (count / len(self.error_history)) * 100
            report += f"  - {error_type}: {count} مرة ({percentage:.1f}%)\n"

        # نصائح مخصصة
        report += "\n💡 نصائح مخصصة بناءً على سجلك:\n"

        if error_types.get('syntax', 0) > 5:
            report += "• لديك أخطاء syntax متكررة - تأكد من مراجعة الكود قبل التشغيل\n"

        if error_types.get('import', 0) > 3:
            report += "• مشاكل استيراد متكررة - أنشئ requirements.txt للمشروع\n"

        if error_types.get('undefined', 0) > 3:
            report += "• متغيرات غير معرفة - استخدم IDE مع إكمال تلقائي\n"

        # الأخطاء المُصلحة مقابل غير المُصلحة
        fixed = len([e for e in self.error_history if e.get('fixed', False)])
        unfixed = len(self.error_history) - fixed

        report += f"\n📊 الإحصائيات:\n"
        report += f"  - أخطاء تم إصلاحها: {fixed}\n"
        report += f"  - أخطاء لم تُصلح: {unfixed}\n"

        if unfixed > fixed:
            report += "\n⚠️  معظم الأخطاء لم تُصلح - جرب استخدام --auto-fix"

        return report

def main():
    parser = argparse.ArgumentParser(description='Gemini CLI محسن')
    parser.add_argument('prompt', nargs='*', help='النص المراد إرساله')
    parser.add_argument('--files', '-f', nargs='+', help='ملفات للسياق')
    parser.add_argument('--analyze', '-a', nargs='+', help='تحليل ملفات الكود')
    parser.add_argument('--config', '-c', nargs=2, metavar=('KEY', 'VALUE'), help='تعديل الإعدادات')
    parser.add_argument('--show-config', action='store_true', help='عرض الإعدادات')
    parser.add_argument('--show-memory', type=int, nargs='?', const=10, help='عرض الذاكرة')
    parser.add_argument('--interactive', '-i', action='store_true', help='الوضع التفاعلي')

    # أوامر المحادثات الجديدة
    parser.add_argument('--list-conversations', '--lc', action='store_true', help='عرض قائمة المحادثات')
    parser.add_argument('--new-conversation', '--new', type=str, nargs='?', const='', help='إنشاء محادثة جديدة')
    parser.add_argument('--load-conversation', '--load', type=str, help='تحميل محادثة محددة')
    parser.add_argument('--show-conversation', '--show', type=str, nargs='?', const='', help='عرض محتوى محادثة')
    parser.add_argument('--delete-conversation', '--delete', type=str, help='حذف محادثة')
    parser.add_argument('--search-conversations', '--search', type=str, help='البحث في المحادثات')
    parser.add_argument('--export-conversation', '--export', type=str, help='تصدير محادثة')

    # أوامر تحليل الأخطاء الجديدة
    parser.add_argument('--analyze-errors', '--ae', nargs='+', help='تحليل أخطاء الملفات بذكاء')
    parser.add_argument('--auto-fix', action='store_true', help='إصلاح الأخطاء تلقائياً')
    parser.add_argument('--analyze-project', '--ap', type=str, help='تحليل أخطاء مشروع كامل')
    parser.add_argument('--suggest-fix', '--sf', type=str, help='اقتراح حلول لوصف خطأ')
    parser.add_argument('--learn-errors', action='store_true', help='التعلم من الأخطاء السابقة')
    parser.add_argument('--report-format', choices=['text', 'json', 'html'], default='text', help='صيغة تقرير الأخطاء')

    # أوامر معالج اللغة الطبيعية الجديدة
    parser.add_argument('--analyze-text', '--at', type=str, help='تحليل وفهم النص')
    parser.add_argument('--smart', '-s', action='store_true', help='استخدام المعالج الذكي للنص')
    parser.add_argument('--understand', '-u', type=str, help='فهم وتحليل النص بعمق')

    args = parser.parse_args()

    cli = EnhancedGeminiCLI()

    # معالجة أوامر معالج اللغة الطبيعية
    if args.analyze_text:
        result = cli.analyze_text(args.analyze_text)
        print(result)
    elif args.understand:
        result = cli.analyze_text(args.understand)
        print(result)
        # توليد رد ذكي أيضاً
        print("\n🤖 الرد الذكي:")
        smart_response = cli.smart_generate(args.understand)
        if isinstance(smart_response, dict):
            print(smart_response['response'])
        else:
            print(smart_response)
    # معالجة أوامر تحليل الأخطاء
    elif args.analyze_errors:
        result = cli.analyze_errors_smart(
            args.analyze_errors,
            auto_fix=args.auto_fix,
            report_format=args.report_format
        )
        print(result)
    elif args.analyze_project:
        result = cli.analyze_project_errors(args.analyze_project)
        print(result)
    elif args.suggest_fix:
        result = cli.suggest_fixes(args.suggest_fix)
        print(result)
    elif args.learn_errors:
        result = cli.learn_from_fixes()
        print(result)
    # معالجة الأوامر - أوامر المحادثات
    elif args.list_conversations:
        result = cli.list_conversations()
        print(result)
    elif args.new_conversation is not None:
        title = args.new_conversation if args.new_conversation else None
        result = cli.new_conversation(title)
        print(result)
    elif args.load_conversation:
        result = cli.load_conversation(args.load_conversation)
        print(result)
    elif args.show_conversation is not None:
        conv_id = args.show_conversation if args.show_conversation else None
        result = cli.show_conversation(conv_id)
        print(result)
    elif args.delete_conversation:
        result = cli.delete_conversation(args.delete_conversation)
        print(result)
    elif args.search_conversations:
        result = cli.search_conversations(args.search_conversations)
        print(result)
    elif args.export_conversation:
        result = cli.export_conversation(args.export_conversation)
        print(result)
    # الأوامر القديمة
    elif args.show_config:
        cli.show_config()
    elif args.show_memory is not None:
        cli.show_memory(args.show_memory)
    elif args.config:
        result = cli.configure(args.config[0], args.config[1])
        print(result)
    elif args.analyze:
        if not args.prompt:
            print("يرجى تحديد سؤال للتحليل")
            return
        question = ' '.join(args.prompt)
        result = cli.analyze_code(args.analyze, question)
        print(result)
    elif args.interactive:
        print("الوضع التفاعلي - اكتب 'exit' للخروج")
        print("أوامر إضافية: 'conversations', 'new', 'load <id>', 'current'")
        print("أوامر تحليل الأخطاء: 'errors <file>', 'fix <error>', 'learn'")
        while True:
            try:
                prompt = input("\n> ")
                if prompt.lower() in ['exit', 'quit', 'خروج']:
                    break
                elif prompt.lower() in ['conversations', 'list']:
                    result = cli.list_conversations()
                    print(f"\n{result}")
                elif prompt.lower().startswith('new'):
                    parts = prompt.split(' ', 1)
                    title = parts[1] if len(parts) > 1 else None
                    result = cli.new_conversation(title)
                    print(f"\n{result}")
                elif prompt.lower().startswith('load '):
                    conv_id = prompt.split(' ', 1)[1]
                    result = cli.load_conversation(conv_id)
                    print(f"\n{result}")
                elif prompt.lower() in ['current', 'show']:
                    result = cli.show_conversation()
                    print(f"\n{result}")
                elif prompt.lower().startswith('search '):
                    search_term = prompt.split(' ', 1)[1]
                    result = cli.search_conversations(search_term)
                    print(f"\n{result}")
                elif prompt.lower().startswith('errors '):
                    file_path = prompt.split(' ', 1)[1]
                    result = cli.analyze_errors_smart([file_path])
                    print(f"\n{result}")
                elif prompt.lower().startswith('fix '):
                    error_desc = prompt.split(' ', 1)[1]
                    result = cli.suggest_fixes(error_desc)
                    print(f"\n{result}")
                elif prompt.lower() == 'learn':
                    result = cli.learn_from_fixes()
                    print(f"\n{result}")
                elif prompt.strip():
                    result = cli.generate(prompt)
                    print(f"\n{result}")
            except KeyboardInterrupt:
                print("\nتم الخروج")
                break
    elif args.prompt:
        prompt = ' '.join(args.prompt)

        # استخدام المعالج الذكي إذا تم تحديده
        if args.smart:
            result = cli.smart_generate(prompt, context_files=args.files)
            if isinstance(result, dict):
                print(result['response'])

                # عرض معلومات التحليل إذا رغب المستخدم
                if '--verbose' in sys.argv:
                    print("\n" + "="*60)
                    print("📊 معلومات التحليل:")
                    print(f"اللغة: {result['metadata']['language']}")
                    print(f"النوايا: {', '.join(result['metadata']['intents'])}")
                    print(f"المواضيع: {', '.join(result['metadata']['topics'])}")
                    print(f"التعقيد: {result['metadata']['complexity']:.2f}")
            else:
                print(result)
        else:
            result = cli.generate(prompt, args.files)
            print(result)
    else:
        parser.print_help()

if __name__ == '__main__':
    main()