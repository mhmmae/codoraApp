#!/usr/bin/env python3
"""
معالج اللغة الطبيعية المتقدم لـ Gemini CLI
يوفر قدرات ذكية لفهم النص وتحليل النوايا والسياق
"""
import re
import json
from typing import Dict, List, Tuple, Optional, Any
from dataclasses import dataclass, field
from enum import Enum
import difflib
from pathlib import Path
from datetime import datetime

# محاولة استيراد المكتبات الاختيارية
try:
    import nltk
except ImportError:
    print("تحذير: nltk غير متوفر. بعض الميزات قد تكون محدودة.")
    nltk = None

try:
    import spacy
except ImportError:
    print("تحذير: spacy غير متوفر. بعض الميزات قد تكون محدودة.")
    spacy = None

try:
    from textblob import TextBlob
except ImportError:
    print("تحذير: textblob غير متوفر. تحليل المشاعر سيكون محدوداً.")
    TextBlob = None

try:
    import arabic_reshaper
except ImportError:
    arabic_reshaper = None

try:
    from bidi.algorithm import get_display
except ImportError:
    get_display = None

# تحميل النماذج المطلوبة
if nltk:
    try:
        nltk.download('punkt', quiet=True)
        nltk.download('stopwords', quiet=True)
        nltk.download('vader_lexicon', quiet=True)
    except:
        pass

@dataclass
class Intent:
    """تمثيل نية المستخدم"""
    type: str
    confidence: float
    entities: Dict[str, Any] = field(default_factory=dict)
    context: Dict[str, Any] = field(default_factory=dict)

@dataclass
class TextAnalysis:
    """نتيجة تحليل النص"""
    original_text: str
    cleaned_text: str
    language: str
    sentiment: str
    intents: List[Intent]
    entities: Dict[str, List[str]]
    keywords: List[str]
    topics: List[str]
    complexity: float

class LanguageType(Enum):
    ARABIC = "ar"
    ENGLISH = "en"
    MIXED = "mixed"
    UNKNOWN = "unknown"

class IntentType(Enum):
    # أنواع النوايا الأساسية
    QUESTION = "question"
    COMMAND = "command"
    EXPLANATION = "explanation"
    CODE_HELP = "code_help"
    ERROR_FIX = "error_fix"
    TRANSLATION = "translation"
    CONVERSATION = "conversation"
    ANALYSIS = "analysis"
    SUGGESTION = "suggestion"
    LEARNING = "learning"

class SmartTextProcessor:
    """معالج النص الذكي"""

    def __init__(self):
        self.arabic_patterns = self._load_arabic_patterns()
        self.intent_patterns = self._load_intent_patterns()
        self.entity_patterns = self._load_entity_patterns()
        self.abbreviations = self._load_abbreviations()
        self.slang_dictionary = self._load_slang_dictionary()
        self.context_memory = []
        self.user_preferences = {}

        # تحميل نماذج معالجة اللغة
        self.nlp_en = None
        if spacy:
            try:
                self.nlp_en = spacy.load("en_core_web_sm")
            except:
                self.nlp_en = None

    def analyze_text(self, text: str, context: Optional[Dict] = None) -> TextAnalysis:
        """تحليل شامل للنص"""
        # تنظيف النص
        cleaned_text = self._clean_text(text)

        # تحديد اللغة
        language = self._detect_language(cleaned_text)

        # استخراج النوايا
        intents = self._extract_intents(cleaned_text, language)

        # استخراج الكيانات
        entities = self._extract_entities(cleaned_text, language)

        # استخراج الكلمات المفتاحية
        keywords = self._extract_keywords(cleaned_text, language)

        # تحليل المواضيع
        topics = self._analyze_topics(cleaned_text, keywords)

        # تحليل المشاعر
        sentiment = self._analyze_sentiment(cleaned_text, language)

        # حساب التعقيد
        complexity = self._calculate_complexity(cleaned_text, language)

        # تحديث السياق
        if context:
            self._update_context(text, intents, entities)

        return TextAnalysis(
            original_text=text,
            cleaned_text=cleaned_text,
            language=language,
            sentiment=sentiment,
            intents=intents,
            entities=entities,
            keywords=keywords,
            topics=topics,
            complexity=complexity
        )

    def _clean_text(self, text: str) -> str:
        """تنظيف النص من الشوائب"""
        # إزالة المسافات الزائدة
        text = re.sub(r'\s+', ' ', text).strip()

        # تصحيح الأخطاء الإملائية الشائعة
        text = self._fix_common_typos(text)

        # توحيد الترقيم
        text = self._normalize_punctuation(text)

        # معالجة الاختصارات
        text = self._expand_abbreviations(text)

        # معالجة الكلمات العامية
        text = self._process_slang(text)

        return text

    def _detect_language(self, text: str) -> str:
        """تحديد لغة النص"""
        # حساب نسبة الأحرف العربية
        arabic_chars = len(re.findall(r'[\u0600-\u06FF]', text))
        english_chars = len(re.findall(r'[a-zA-Z]', text))
        total_chars = len(re.findall(r'\w', text))

        if total_chars == 0:
            return LanguageType.UNKNOWN.value

        arabic_ratio = arabic_chars / total_chars
        english_ratio = english_chars / total_chars

        if arabic_ratio > 0.7:
            return LanguageType.ARABIC.value
        elif english_ratio > 0.7:
            return LanguageType.ENGLISH.value
        elif arabic_ratio > 0.2 and english_ratio > 0.2:
            return LanguageType.MIXED.value
        else:
            return LanguageType.UNKNOWN.value

    def _extract_intents(self, text: str, language: str) -> List[Intent]:
        """استخراج نوايا المستخدم"""
        intents = []

        # البحث عن أنماط النوايا
        for intent_type, patterns in self.intent_patterns.items():
            for pattern in patterns.get(language, []):
                if re.search(pattern, text, re.IGNORECASE):
                    confidence = self._calculate_intent_confidence(text, pattern, intent_type)
                    entities = self._extract_intent_entities(text, intent_type)

                    intents.append(Intent(
                        type=intent_type,
                        confidence=confidence,
                        entities=entities
                    ))
                    break

        # إذا لم يتم العثور على نوايا محددة، استخدم التحليل العام
        if not intents:
            intents = self._analyze_general_intent(text, language)

        # ترتيب حسب الثقة
        intents.sort(key=lambda x: x.confidence, reverse=True)

        return intents[:3]  # أعلى 3 نوايا

    def _extract_entities(self, text: str, language: str) -> Dict[str, List[str]]:
        """استخراج الكيانات من النص"""
        entities = {
            'files': [],
            'code_elements': [],
            'technologies': [],
            'actions': [],
            'errors': [],
            'numbers': [],
            'dates': [],
            'urls': []
        }

        # استخراج أسماء الملفات
        file_pattern = r'[\w\-]+\.(py|dart|js|json|yaml|yml|txt|md|html|css)'
        entities['files'] = re.findall(file_pattern, text, re.IGNORECASE)

        # استخراج عناصر الكود
        code_patterns = [
            r'(?:function|def|class|method|variable|const|let|var)\s+(\w+)',
            r'(\w+)\(\)',  # دوال
            r'`([^`]+)`',  # كود inline
        ]
        for pattern in code_patterns:
            entities['code_elements'].extend(re.findall(pattern, text))

        # استخراج التقنيات
        tech_keywords = [
            'python', 'dart', 'flutter', 'javascript', 'react', 'node',
            'django', 'fastapi', 'tensorflow', 'pytorch', 'docker',
            'kubernetes', 'aws', 'gcp', 'azure', 'git', 'github'
        ]
        for tech in tech_keywords:
            if tech.lower() in text.lower():
                entities['technologies'].append(tech)

        # استخراج الأخطاء
        error_patterns = [
            r'(Error|Exception|Warning):\s*([^\n]+)',
            r'(خطأ|استثناء|تحذير):\s*([^\n]+)',
        ]
        for pattern in error_patterns:
            matches = re.findall(pattern, text, re.IGNORECASE)
            entities['errors'].extend([m[1] for m in matches])

        # استخراج الأرقام
        entities['numbers'] = re.findall(r'\b\d+\b', text)

        # استخراج URLs
        url_pattern = r'https?://[^\s]+'
        entities['urls'] = re.findall(url_pattern, text)

        # استخدام NLP للغة الإنجليزية
        if language == LanguageType.ENGLISH.value and self.nlp_en:
            doc = self.nlp_en(text)
            for ent in doc.ents:
                if ent.label_ not in entities:
                    entities[ent.label_] = []
                entities[ent.label_].append(ent.text)

        return entities

    def _extract_keywords(self, text: str, language: str) -> List[str]:
        """استخراج الكلمات المفتاحية"""
        keywords = []

        # إزالة كلمات التوقف
        if language == LanguageType.ARABIC.value:
            stopwords = self._get_arabic_stopwords()
        else:
            stopwords = self._get_english_stopwords()

        # تقسيم النص إلى كلمات
        words = re.findall(r'\w+', text.lower())

        # تصفية الكلمات
        keywords = [
            word for word in words
            if len(word) > 2 and word not in stopwords
        ]

        # حساب التكرار
        word_freq = {}
        for word in keywords:
            word_freq[word] = word_freq.get(word, 0) + 1

        # ترتيب حسب التكرار
        sorted_words = sorted(word_freq.items(), key=lambda x: x[1], reverse=True)

        return [word for word, _ in sorted_words[:10]]

    def _analyze_topics(self, text: str, keywords: List[str]) -> List[str]:
        """تحليل المواضيع الرئيسية"""
        topics = []

        # مواضيع البرمجة
        programming_topics = {
            'web_development': ['html', 'css', 'javascript', 'react', 'vue', 'angular'],
            'mobile_development': ['flutter', 'dart', 'android', 'ios', 'react native'],
            'backend_development': ['api', 'database', 'server', 'django', 'fastapi'],
            'machine_learning': ['tensorflow', 'pytorch', 'model', 'training', 'dataset'],
            'devops': ['docker', 'kubernetes', 'ci/cd', 'deployment', 'aws'],
            'data_science': ['pandas', 'numpy', 'analysis', 'visualization', 'statistics']
        }

        # تحديد المواضيع بناءً على الكلمات المفتاحية
        for topic, topic_keywords in programming_topics.items():
            if any(kw in keywords or kw in text.lower() for kw in topic_keywords):
                topics.append(topic)

        # مواضيع عامة
        if 'خطأ' in text or 'error' in text.lower():
            topics.append('error_handling')

        if 'شرح' in text or 'explain' in text.lower():
            topics.append('explanation')

        if 'كيف' in text or 'how' in text.lower():
            topics.append('tutorial')

        return topics

    def _analyze_sentiment(self, text: str, language: str) -> str:
        """تحليل المشاعر في النص"""
        if language == LanguageType.ENGLISH.value and TextBlob:
            try:
                blob = TextBlob(text)
                polarity = blob.sentiment.polarity

                if polarity > 0.5:
                    return "very_positive"
                elif polarity > 0.1:
                    return "positive"
                elif polarity < -0.5:
                    return "very_negative"
                elif polarity < -0.1:
                    return "negative"
                else:
                    return "neutral"
            except:
                pass

        # تحليل بسيط للعربية
        positive_words = ['ممتاز', 'رائع', 'جيد', 'شكرا', 'أحسنت']
        negative_words = ['سيء', 'خطأ', 'مشكلة', 'فشل', 'لا يعمل']

        positive_count = sum(1 for word in positive_words if word in text)
        negative_count = sum(1 for word in negative_words if word in text)

        if positive_count > negative_count:
            return "positive"
        elif negative_count > positive_count:
            return "negative"
        else:
            return "neutral"

    def _calculate_complexity(self, text: str, language: str) -> float:
        """حساب تعقيد النص"""
        # عوامل التعقيد
        factors = {
            'length': len(text) / 1000,  # طول النص
            'sentences': len(re.split(r'[.!?]', text)),  # عدد الجمل
            'technical_terms': 0,
            'code_snippets': 0,
            'nested_structures': 0
        }

        # حساب المصطلحات التقنية
        technical_terms = [
            'algorithm', 'function', 'class', 'method', 'api', 'database',
            'خوارزمية', 'دالة', 'صنف', 'واجهة', 'قاعدة بيانات'
        ]
        factors['technical_terms'] = sum(1 for term in technical_terms if term in text.lower())

        # حساب أجزاء الكود
        factors['code_snippets'] = len(re.findall(r'```[\s\S]*?```', text))

        # حساب التعقيد الكلي (من 0 إلى 1)
        complexity = min(1.0, sum(factors.values()) / 10)

        return complexity

    def _fix_common_typos(self, text: str) -> str:
        """تصحيح الأخطاء الإملائية الشائعة"""
        typos = {
            # عربي
            'الى': 'إلى',
            'هذى': 'هذه',
            'ذالك': 'ذلك',
            'اللذي': 'الذي',
            'انشاء': 'إنشاء',
            # إنجليزي
            'recieve': 'receive',
            'definately': 'definitely',
            'occured': 'occurred',
            'seperate': 'separate',
        }

        for typo, correct in typos.items():
            text = re.sub(r'\b' + typo + r'\b', correct, text, flags=re.IGNORECASE)

        return text

    def _normalize_punctuation(self, text: str) -> str:
        """توحيد علامات الترقيم"""
        # توحيد علامات الاستفهام والتعجب المتعددة
        text = re.sub(r'[?!]+', lambda m: m.group(0)[0], text)

        # إضافة مسافة بعد الفواصل والنقاط
        text = re.sub(r'([,.!?])([^\s])', r'\1 \2', text)

        return text

    def _expand_abbreviations(self, text: str) -> str:
        """توسيع الاختصارات"""
        for abbr, expansion in self.abbreviations.items():
            text = re.sub(r'\b' + abbr + r'\b', expansion, text, flags=re.IGNORECASE)

        return text

    def _process_slang(self, text: str) -> str:
        """معالجة الكلمات العامية"""
        for slang, formal in self.slang_dictionary.items():
            text = re.sub(r'\b' + slang + r'\b', formal, text, flags=re.IGNORECASE)

        return text

    def _calculate_intent_confidence(self, text: str, pattern: str, intent_type: str) -> float:
        """حساب مستوى الثقة في النية"""
        confidence = 0.5  # قيمة أساسية

        # زيادة الثقة إذا كان النمط في بداية النص
        if text.lower().startswith(pattern.lower()[:10]):
            confidence += 0.2

        # زيادة الثقة بناءً على وضوح النمط
        if pattern in text:
            confidence += 0.3

        # تعديل بناءً على السياق السابق
        if self.context_memory:
            last_intent = self.context_memory[-1].get('intent')
            if last_intent == intent_type:
                confidence += 0.1

        return min(1.0, confidence)

    def _extract_intent_entities(self, text: str, intent_type: str) -> Dict[str, Any]:
        """استخراج الكيانات المرتبطة بالنية"""
        entities = {}

        if intent_type == IntentType.CODE_HELP.value:
            # استخراج لغة البرمجة
            languages = ['python', 'dart', 'javascript', 'java', 'c++']
            for lang in languages:
                if lang in text.lower():
                    entities['language'] = lang
                    break

        elif intent_type == IntentType.ERROR_FIX.value:
            # استخراج نوع الخطأ
            error_match = re.search(r'(Error|Exception|خطأ):\s*(.+)', text)
            if error_match:
                entities['error_type'] = error_match.group(2)

        return entities

    def _analyze_general_intent(self, text: str, language: str) -> List[Intent]:
        """تحليل النية العامة عندما لا تتطابق أنماط محددة"""
        # قواعد بسيطة للتحليل العام
        if '?' in text or 'كيف' in text or 'ما هو' in text:
            return [Intent(type=IntentType.QUESTION.value, confidence=0.7)]

        elif any(word in text for word in ['اشرح', 'explain', 'وضح']):
            return [Intent(type=IntentType.EXPLANATION.value, confidence=0.7)]

        elif any(word in text for word in ['خطأ', 'error', 'مشكلة', 'problem']):
            return [Intent(type=IntentType.ERROR_FIX.value, confidence=0.6)]

        else:
            return [Intent(type=IntentType.CONVERSATION.value, confidence=0.5)]

    def _update_context(self, text: str, intents: List[Intent], entities: Dict):
        """تحديث ذاكرة السياق"""
        context_entry = {
            'text': text,
            'intent': intents[0].type if intents else None,
            'entities': entities,
            'timestamp': datetime.now().isoformat()
        }

        self.context_memory.append(context_entry)

        # الاحتفاظ بآخر 10 إدخالات فقط
        if len(self.context_memory) > 10:
            self.context_memory.pop(0)

    def _get_arabic_stopwords(self) -> set:
        """الحصول على كلمات التوقف العربية"""
        return {
            'في', 'من', 'إلى', 'على', 'هذا', 'هذه', 'ذلك', 'التي', 'الذي',
            'كان', 'كانت', 'هو', 'هي', 'أن', 'إن', 'مع', 'عن', 'بعد', 'قبل'
        }

    def _get_english_stopwords(self) -> set:
        """الحصول على كلمات التوقف الإنجليزية"""
        return {
            'the', 'is', 'at', 'which', 'on', 'a', 'an', 'as', 'are', 'was',
            'were', 'been', 'be', 'have', 'has', 'had', 'do', 'does', 'did'
        }

    def _load_arabic_patterns(self) -> Dict:
        """تحميل أنماط اللغة العربية"""
        return {
            'questions': [
                r'ما هو',
                r'ما هي',
                r'كيف',
                r'لماذا',
                r'متى',
                r'أين',
                r'هل',
            ],
            'commands': [
                r'قم ب',
                r'أنشئ',
                r'اصنع',
                r'حلل',
                r'اشرح',
                r'ترجم',
            ]
        }

    def _load_intent_patterns(self) -> Dict:
        """تحميل أنماط النوايا"""
        return {
            IntentType.QUESTION.value: {
                'ar': [r'ما هو', r'ما هي', r'كيف', r'لماذا', r'متى', r'أين', r'هل'],
                'en': [r'what is', r'how to', r'why', r'when', r'where', r'is it', r'can you']
            },
            IntentType.COMMAND.value: {
                'ar': [r'قم ب', r'أنشئ', r'اصنع', r'نفذ', r'شغل'],
                'en': [r'create', r'make', r'build', r'run', r'execute', r'generate']
            },
            IntentType.CODE_HELP.value: {
                'ar': [r'كود', r'برنامج', r'دالة', r'صنف'],
                'en': [r'code', r'function', r'class', r'method', r'program']
            },
            IntentType.ERROR_FIX.value: {
                'ar': [r'خطأ', r'مشكلة', r'لا يعمل', r'تعطل'],
                'en': [r'error', r'bug', r'issue', r'problem', r'not working', r'crash']
            }
        }

    def _load_entity_patterns(self) -> Dict:
        """تحميل أنماط الكيانات"""
        return {
            'file_paths': r'[./\w\-]+\.\w+',
            'urls': r'https?://[^\s]+',
            'emails': r'\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z|a-z]{2,}\b',
            'code_blocks': r'```[\s\S]*?```',
            'inline_code': r'`[^`]+`'
        }

    def _load_abbreviations(self) -> Dict[str, str]:
        """تحميل قاموس الاختصارات"""
        return {
            # عربي
            'ص': 'صفحة',
            'د': 'دكتور',
            'أ': 'أستاذ',
            'م': 'مهندس',
            # إنجليزي
            'btw': 'by the way',
            'fyi': 'for your information',
            'asap': 'as soon as possible',
            'api': 'application programming interface',
            'ui': 'user interface',
            'ux': 'user experience',
            'db': 'database',
            'dev': 'development',
            'prod': 'production'
        }

    def _load_slang_dictionary(self) -> Dict[str, str]:
        """تحميل قاموس الكلمات العامية"""
        return {
            # عربي
            'مش': 'ليس',
            'عشان': 'لأجل',
            'كده': 'هكذا',
            'ايه': 'ماذا',
            # إنجليزي
            'gonna': 'going to',
            'wanna': 'want to',
            'gotta': 'got to',
            'kinda': 'kind of',
            'sorta': 'sort of'
        }


class ContextualUnderstanding:
    """فهم السياق المتقدم"""

    def __init__(self):
        self.conversation_history = []
        self.user_profile = {}
        self.topic_memory = {}

    def understand_context(self, current_text: str, analysis: TextAnalysis) -> Dict[str, Any]:
        """فهم السياق الكامل للمحادثة"""
        context = {
            'current_topic': self._identify_current_topic(analysis),
            'conversation_flow': self._analyze_conversation_flow(),
            'user_intent_pattern': self._analyze_user_patterns(),
            'relevant_history': self._get_relevant_history(analysis),
            'suggested_responses': self._suggest_responses(analysis),
            'context_switches': self._detect_context_switches(analysis)
        }

        # تحديث السجل
        self._update_history(current_text, analysis, context)

        return context

    def _identify_current_topic(self, analysis: TextAnalysis) -> str:
        """تحديد الموضوع الحالي"""
        if analysis.topics:
            return analysis.topics[0]

        # البحث في السجل عن موضوع مرتبط
        for entry in reversed(self.conversation_history[-5:]):
            if entry.get('topics'):
                return entry['topics'][0]

        return 'general'

    def _analyze_conversation_flow(self) -> Dict[str, Any]:
        """تحليل تدفق المحادثة"""
        if len(self.conversation_history) < 2:
            return {'type': 'new_conversation', 'coherence': 1.0}

        # تحليل الترابط بين الرسائل
        recent_messages = self.conversation_history[-5:]

        # حساب الترابط
        coherence_score = self._calculate_coherence(recent_messages)

        # تحديد نوع التدفق
        flow_type = 'continuous' if coherence_score > 0.7 else 'fragmented'

        return {
            'type': flow_type,
            'coherence': coherence_score,
            'message_count': len(self.conversation_history)
        }

    def _analyze_user_patterns(self) -> Dict[str, Any]:
        """تحليل أنماط المستخدم"""
        if not self.conversation_history:
            return {}

        patterns = {
            'preferred_language': self._get_preferred_language(),
            'common_topics': self._get_common_topics(),
            'interaction_style': self._get_interaction_style(),
            'technical_level': self._estimate_technical_level()
        }

        return patterns

    def _get_relevant_history(self, analysis: TextAnalysis) -> List[Dict]:
        """الحصول على السجل ذو الصلة"""
        relevant = []

        current_keywords = set(analysis.keywords)
        current_topics = set(analysis.topics)

        for entry in self.conversation_history:
            # حساب التشابه
            entry_keywords = set(entry.get('keywords', []))
            entry_topics = set(entry.get('topics', []))

            keyword_similarity = len(current_keywords & entry_keywords) / max(len(current_keywords), 1)
            topic_similarity = len(current_topics & entry_topics) / max(len(current_topics), 1)

            if keyword_similarity > 0.3 or topic_similarity > 0.5:
                relevant.append(entry)

        return relevant[-3:]  # آخر 3 إدخالات ذات صلة

    def _suggest_responses(self, analysis: TextAnalysis) -> List[str]:
        """اقتراح ردود مناسبة"""
        suggestions = []

        # بناءً على النية
        if analysis.intents:
            primary_intent = analysis.intents[0]

            if primary_intent.type == IntentType.QUESTION.value:
                suggestions.extend([
                    "هل تريد شرحاً مفصلاً أم ملخصاً سريعاً؟",
                    "هل تحتاج لمثال عملي؟",
                    "هل هناك جزء معين تريد التركيز عليه؟"
                ])

            elif primary_intent.type == IntentType.ERROR_FIX.value:
                suggestions.extend([
                    "هل يمكنك مشاركة رسالة الخطأ الكاملة؟",
                    "ما هي الخطوات التي جربتها لحل المشكلة؟",
                    "في أي بيئة تعمل (نظام التشغيل، الإصدارات)؟"
                ])

            elif primary_intent.type == IntentType.CODE_HELP.value:
                suggestions.extend([
                    "هل تريد كود كامل أم شرح للمفهوم؟",
                    "ما هي لغة البرمجة المفضلة لديك؟",
                    "هل تريد التعليقات بالعربية أم الإنجليزية؟"
                ])

        return suggestions

    def _detect_context_switches(self, analysis: TextAnalysis) -> List[str]:
        """اكتشاف تغييرات السياق"""
        switches = []

        if not self.conversation_history:
            return switches

        last_entry = self.conversation_history[-1]

        # مقارنة المواضيع
        last_topics = set(last_entry.get('topics', []))
        current_topics = set(analysis.topics)

        if not last_topics & current_topics:
            switches.append('topic_change')

        # مقارنة اللغة
        if last_entry.get('language') != analysis.language:
            switches.append('language_change')

        # مقارنة النية
        if self.conversation_history:
            last_intents = [i['type'] for i in last_entry.get('intents', [])]
            current_intents = [i.type for i in analysis.intents]

            if not set(last_intents) & set(current_intents):
                switches.append('intent_change')

        return switches

    def _update_history(self, text: str, analysis: TextAnalysis, context: Dict):
        """تحديث سجل المحادثة"""
        entry = {
            'text': text,
            'timestamp': datetime.now().isoformat(),
            'language': analysis.language,
            'intents': [{'type': i.type, 'confidence': i.confidence} for i in analysis.intents],
            'topics': analysis.topics,
            'keywords': analysis.keywords,
            'sentiment': analysis.sentiment,
            'context': context
        }

        self.conversation_history.append(entry)

        # الاحتفاظ بآخر 50 رسالة
        if len(self.conversation_history) > 50:
            self.conversation_history.pop(0)

    def _calculate_coherence(self, messages: List[Dict]) -> float:
        """حساب ترابط الرسائل"""
        if len(messages) < 2:
            return 1.0

        coherence_scores = []

        for i in range(1, len(messages)):
            prev_keywords = set(messages[i-1].get('keywords', []))
            curr_keywords = set(messages[i].get('keywords', []))

            if prev_keywords and curr_keywords:
                similarity = len(prev_keywords & curr_keywords) / len(prev_keywords | curr_keywords)
                coherence_scores.append(similarity)

        return sum(coherence_scores) / len(coherence_scores) if coherence_scores else 0.5

    def _get_preferred_language(self) -> str:
        """تحديد اللغة المفضلة للمستخدم"""
        language_counts = {}

        for entry in self.conversation_history:
            lang = entry.get('language', 'unknown')
            language_counts[lang] = language_counts.get(lang, 0) + 1

        if language_counts:
            return max(language_counts, key=language_counts.get)

        return 'unknown'

    def _get_common_topics(self) -> List[str]:
        """الحصول على المواضيع الشائعة"""
        topic_counts = {}

        for entry in self.conversation_history:
            for topic in entry.get('topics', []):
                topic_counts[topic] = topic_counts.get(topic, 0) + 1

        sorted_topics = sorted(topic_counts.items(), key=lambda x: x[1], reverse=True)

        return [topic for topic, _ in sorted_topics[:5]]

    def _get_interaction_style(self) -> str:
        """تحديد أسلوب التفاعل"""
        if not self.conversation_history:
            return 'unknown'

        # تحليل طول الرسائل
        avg_length = sum(len(e['text']) for e in self.conversation_history) / len(self.conversation_history)

        # تحليل الأسئلة مقابل الأوامر
        question_count = sum(1 for e in self.conversation_history
                           if any(i['type'] == IntentType.QUESTION.value
                                 for i in e.get('intents', [])))

        command_count = sum(1 for e in self.conversation_history
                          if any(i['type'] == IntentType.COMMAND.value
                                for i in e.get('intents', [])))

        if avg_length < 50:
            style = 'concise'
        elif avg_length > 200:
            style = 'detailed'
        else:
            style = 'moderate'

        if question_count > command_count * 2:
            style += '_questioning'
        elif command_count > question_count * 2:
            style += '_commanding'

        return style

    def _estimate_technical_level(self) -> str:
        """تقدير المستوى التقني للمستخدم"""
        technical_indicators = {
            'beginner': ['ما هو', 'كيف', 'شرح', 'مبتدئ', 'أساسيات'],
            'intermediate': ['function', 'class', 'api', 'database', 'algorithm'],
            'advanced': ['optimization', 'architecture', 'design pattern', 'microservices', 'distributed']
        }

        scores = {'beginner': 0, 'intermediate': 0, 'advanced': 0}

        for entry in self.conversation_history:
            text = entry['text'].lower()

            for level, indicators in technical_indicators.items():
                for indicator in indicators:
                    if indicator in text:
                        scores[level] += 1

        if scores['advanced'] > scores['intermediate'] and scores['advanced'] > scores['beginner']:
            return 'advanced'
        elif scores['intermediate'] > scores['beginner']:
            return 'intermediate'
        else:
            return 'beginner'


class SmartResponseGenerator:
    """مولد الردود الذكية"""

    def __init__(self):
        self.response_templates = self._load_response_templates()
        self.personality_traits = {
            'helpful': 0.9,
            'friendly': 0.8,
            'professional': 0.7,
            'detailed': 0.6
        }

    def generate_enhanced_prompt(self,
                               original_prompt: str,
                               analysis: TextAnalysis,
                               context: Dict[str, Any]) -> str:
        """توليد prompt محسّن لـ Gemini"""

        # البناء الأساسي للـ prompt
        enhanced_prompt = self._build_base_prompt(original_prompt, analysis)

        # إضافة السياق
        enhanced_prompt = self._add_context(enhanced_prompt, context)

        # إضافة التوجيهات
        enhanced_prompt = self._add_instructions(enhanced_prompt, analysis, context)

        # إضافة أمثلة إذا لزم الأمر
        if analysis.complexity > 0.7:
            enhanced_prompt = self._add_examples(enhanced_prompt, analysis)

        return enhanced_prompt

    def _build_base_prompt(self, original: str, analysis: TextAnalysis) -> str:
        """بناء الـ prompt الأساسي"""
        # تحديد اللغة المناسبة للرد
        if analysis.language == LanguageType.ARABIC.value:
            language_instruction = "الرجاء الرد باللغة العربية."
        elif analysis.language == LanguageType.ENGLISH.value:
            language_instruction = "Please respond in English."
        else:
            language_instruction = "الرجاء الرد بنفس لغة السؤال (عربي/إنجليزي)."

        # تحديد مستوى التفصيل
        if analysis.complexity < 0.3:
            detail_level = "قدم إجابة مختصرة ومباشرة."
        elif analysis.complexity > 0.7:
            detail_level = "قدم شرحاً مفصلاً مع أمثلة."
        else:
            detail_level = "قدم إجابة متوازنة بين الإيجاز والتفصيل."

        prompt = f"""
{language_instruction}
{detail_level}

السؤال/الطلب: {original}

السياق:
- النية المكتشفة: {analysis.intents[0].type if analysis.intents else 'general'}
- المواضيع: {', '.join(analysis.topics)}
- مستوى التعقيد: {analysis.complexity:.1f}
"""

        return prompt

    def _add_context(self, prompt: str, context: Dict[str, Any]) -> str:
        """إضافة السياق للـ prompt"""
        if context.get('relevant_history'):
            prompt += "\n\nمحادثات سابقة ذات صلة:\n"
            for entry in context['relevant_history']:
                prompt += f"- {entry['text'][:100]}...\n"

        if context.get('user_intent_pattern'):
            patterns = context['user_intent_pattern']
            prompt += f"\n\nمعلومات عن المستخدم:\n"
            prompt += f"- اللغة المفضلة: {patterns.get('preferred_language', 'غير محدد')}\n"
            prompt += f"- المستوى التقني: {patterns.get('technical_level', 'متوسط')}\n"
            prompt += f"- أسلوب التفاعل: {patterns.get('interaction_style', 'عام')}\n"

        return prompt

    def _add_instructions(self, prompt: str, analysis: TextAnalysis, context: Dict) -> str:
        """إضافة توجيهات محددة"""
        instructions = "\n\nتوجيهات إضافية:\n"

        # بناءً على النية
        if analysis.intents:
            intent_type = analysis.intents[0].type

            if intent_type == IntentType.CODE_HELP.value:
                instructions += "- قدم كود نظيف مع تعليقات واضحة\n"
                instructions += "- اشرح المفاهيم الأساسية\n"
                instructions += "- قدم أفضل الممارسات\n"

            elif intent_type == IntentType.ERROR_FIX.value:
                instructions += "- حدد السبب المحتمل للخطأ\n"
                instructions += "- قدم خطوات واضحة للحل\n"
                instructions += "- اقترح طرق لتجنب الخطأ مستقبلاً\n"

            elif intent_type == IntentType.EXPLANATION.value:
                instructions += "- ابدأ بتعريف بسيط\n"
                instructions += "- قدم أمثلة عملية\n"
                instructions += "- اربط بمفاهيم مشابهة\n"

        # بناءً على المشاعر
        if analysis.sentiment in ['negative', 'very_negative']:
            instructions += "- كن متعاطفاً ومشجعاً\n"
            instructions += "- قدم الدعم والمساعدة الإضافية\n"

        prompt += instructions

        return prompt

    def _add_examples(self, prompt: str, analysis: TextAnalysis) -> str:
        """إضافة أمثلة للـ prompt"""
        if IntentType.CODE_HELP.value in [i.type for i in analysis.intents]:
            prompt += "\n\nيرجى تضمين:\n"
            prompt += "1. مثال كود بسيط\n"
            prompt += "2. مثال كود متقدم\n"
            prompt += "3. حالات استخدام شائعة\n"

        return prompt

    def _load_response_templates(self) -> Dict:
        """تحميل قوالب الردود"""
        return {
            'greeting': {
                'ar': ['مرحباً! كيف يمكنني مساعدتك؟', 'أهلاً وسهلاً! ماذا تحتاج؟'],
                'en': ['Hello! How can I help you?', 'Hi there! What do you need?']
            },
            'clarification': {
                'ar': ['هل يمكنك توضيح المزيد؟', 'هل تقصد...؟'],
                'en': ['Could you clarify?', 'Do you mean...?']
            }
        }


# دالة رئيسية لدمج المعالج مع Gemini CLI
def process_user_input(text: str, gemini_cli_instance=None) -> Dict[str, Any]:
    """معالجة مدخلات المستخدم وإرجاع تحليل شامل"""

    # تهيئة المعالجات
    text_processor = SmartTextProcessor()
    context_analyzer = ContextualUnderstanding()
    response_generator = SmartResponseGenerator()

    # تحليل النص
    analysis = text_processor.analyze_text(text)

    # فهم السياق
    context = context_analyzer.understand_context(text, analysis)

    # توليد prompt محسّن
    enhanced_prompt = response_generator.generate_enhanced_prompt(text, analysis, context)

    # إعداد النتيجة
    result = {
        'original_text': text,
        'analysis': analysis,
        'context': context,
        'enhanced_prompt': enhanced_prompt,
        'suggestions': context.get('suggested_responses', []),
        'metadata': {
            'processing_time': datetime.now().isoformat(),
            'confidence': analysis.intents[0].confidence if analysis.intents else 0.5
        }
    }

    return result


if __name__ == "__main__":
    # أمثلة للاختبار
    test_texts = [
        "كيف أقوم بإنشاء تطبيق Flutter يستخدم GetX؟",
        "I have an error: undefined variable 'x' in Python",
        "اشرح لي ما هو machine learning بشكل مبسط",
        "قم بتحليل الكود التالي وأخبرني بالمشاكل الموجودة فيه",
        "مش عارف ازاي اعمل API بـ FastAPI ممكن تساعدني؟"
    ]

    for text in test_texts:
        print(f"\n{'='*60}")
        print(f"النص: {text}")
        print(f"{'='*60}")

        result = process_user_input(text)

        print(f"اللغة: {result['analysis'].language}")
        print(f"النوايا: {[i.type for i in result['analysis'].intents]}")
        print(f"المواضيع: {result['analysis'].topics}")
        print(f"المشاعر: {result['analysis'].sentiment}")
        print(f"التعقيد: {result['analysis'].complexity:.2f}")
        print(f"\nالـ Prompt المحسّن:\n{result['enhanced_prompt'][:500]}...")