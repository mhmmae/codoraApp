#!/usr/bin/env python3
"""
معالج اللغة الطبيعية المتقدم جداً لـ Gemini CLI
يوفر قدرات ذكية لفهم النص، تحليل النوايا والسياق، التعلم من التفاعلات، وتقديم مساعدة استباقية.
"""
import re
import json
import os
from typing import Dict, List, Tuple, Optional, Any
from dataclasses import dataclass, field
from enum import Enum
from pathlib import Path
from datetime import datetime
import logging

# إعداد التسجيل
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')

# --- قسم استيراد المكتبات الاختيارية ---
try:
    import nltk
    nltk.download('punkt', quiet=True)
    nltk.download('stopwords', quiet=True)
except ImportError:
    logging.warning("NLTK not found. Keyword extraction will be basic.")
    nltk = None

try:
    import spacy
    from spacy.cli.download import download as spacy_download
except ImportError:
    logging.warning("spaCy not found. Coreference resolution and advanced entity extraction will be disabled.")
    spacy = None

try:
    from textblob import TextBlob
except ImportError:
    logging.warning("TextBlob not found. Sentiment analysis will be basic.")
    TextBlob = None

try:
    from transformers import pipeline, AutoTokenizer, AutoModelForTokenClassification
    logging.info("Hugging Face Transformers library found. Advanced ML models will be used if available.")
except ImportError:
    logging.warning("Hugging Face Transformers not found. Falling back to Regex-based intent/entity recognition.")
    pipeline = None
    
# --- تعريف هياكل البيانات الأساسية ---

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
    SUMMARIZATION = "summarization" # نية جديدة
    CORRECTION = "correction"       # نية جديدة

# --- مكونات المعالجة المتقدمة ---

class ProjectKnowledgeBase:
    """
    يقوم بمسح المشروع وبناء قاعدة معرفة بالكيانات (كلاسات، دوال)
    """
    def __init__(self, project_path: str):
        self.kb_path = Path.home() / '.gemini-enhanced' / 'project_kb.json'
        self.project_path = project_path
        self.knowledge_base = self._load_kb()

    def _load_kb(self) -> Dict:
        if self.kb_path.exists():
            with open(self.kb_path, 'r', encoding='utf-8') as f:
                return json.load(f)
        return {'entities': {}}

    def _save_kb(self):
        self.kb_path.parent.mkdir(exist_ok=True)
        with open(self.kb_path, 'w', encoding='utf-8') as f:
            json.dump(self.knowledge_base, f, ensure_ascii=False, indent=2)

    def scan_project(self):
        """يمسح المشروع ويستخرج الكيانات."""
        logging.info(f"Scanning project at {self.project_path} to build knowledge base.")
        # استخدام regex بسيط لاستخراج الكلاسات والدوال (يمكن استخدام AST لتحليل أدق)
        class_pattern = re.compile(r'class\s+(\w+)')
        func_pattern = re.compile(r'def\s+(\w+)|function\s+(\w+)')

        for root, _, files in os.walk(self.project_path):
            for file in files:
                if file.endswith(('.py', '.dart', '.js')):
                    file_path = Path(root) / file
                    try:
                        content = file_path.read_text(encoding='utf-8')
                        classes = class_pattern.findall(content)
                        functions = [f[0] or f[1] for f in func_pattern.findall(content)]
                        
                        for c in classes:
                            self.knowledge_base['entities'][c] = {'type': 'class', 'file': str(file_path)}
                        for f in functions:
                            self.knowledge_base['entities'][f] = {'type': 'function', 'file': str(file_path)}
                    except Exception as e:
                        logging.warning(f"Could not read or parse file {file_path}: {e}")
        
        self._save_kb()
        logging.info("Project scan complete. Knowledge base updated.")

    def query(self, entity_name: str) -> Optional[Dict]:
        return self.knowledge_base['entities'].get(entity_name)

class SmartTextProcessor:
    """معالج النص الذكي المطور"""
    
    def __init__(self, project_path: str):
        self.intent_patterns = self._load_intent_patterns()
        self.abbreviations = self._load_abbreviations()
        self.slang_dictionary = self._load_slang_dictionary()
        self.project_kb = ProjectKnowledgeBase(project_path)
        
        # --- تحميل نماذج NLP و ML ---
        self.nlp_en = self._load_spacy_model()
        self.hf_ner_pipeline = self._load_hf_pipeline("ner")
        self.hf_cls_pipeline = self._load_hf_pipeline("text-classification")

    def _load_spacy_model(self):
        if not spacy: return None
        try:
            return spacy.load("en_core_web_sm")
        except OSError:
            logging.info("Spacy model 'en_core_web_sm' not found. Downloading...")
            try:
                spacy_download("en_core_web_sm")
                return spacy.load("en_core_web_sm")
            except Exception as e:
                logging.error(f"Failed to download or load spacy model: {e}")
                return None

    def _load_hf_pipeline(self, task: str):
        if not pipeline: return None
        model_map = {
            "ner": "dslim/bert-base-NER",
            "text-classification": "SamLowe/roberta-base-go_emotions" # كمثال لتحليل المشاعر
        }
        try:
            return pipeline(task, model=model_map[task])
        except Exception as e:
            logging.warning(f"Could not load Hugging Face pipeline for task '{task}'. Error: {e}")
            return None

    def analyze_text(self, text: str, context: Optional[Dict] = None) -> TextAnalysis:
        """تحليل شامل للنص"""
        cleaned_text = self._clean_text(text)
        language = self._detect_language(cleaned_text)
        
        intents = self._extract_intents(cleaned_text, language)
        entities = self._extract_entities(cleaned_text, language)
        keywords = self._extract_keywords(cleaned_text, language)
        topics = self._analyze_topics(cleaned_text, keywords)
        sentiment = self._analyze_sentiment(cleaned_text, language)
        complexity = self._calculate_complexity(cleaned_text)
        
        return TextAnalysis(
            original_text=text, cleaned_text=cleaned_text, language=language,
            sentiment=sentiment, intents=intents, entities=entities,
            keywords=keywords, topics=topics, complexity=complexity
        )

    def _clean_text(self, text: str) -> str:
        text = re.sub(r'\s+', ' ', text).strip()
        text = self._fix_common_typos(text)
        text = self._normalize_punctuation(text)
        text = self._expand_abbreviations(text)
        text = self._process_slang(text)
        return text

    def _detect_language(self, text: str) -> str:
        arabic_chars = len(re.findall(r'[\u0600-\u06FF]', text))
        english_chars = len(re.findall(r'[a-zA-Z]', text))
        total_chars = arabic_chars + english_chars
        if total_chars == 0: return LanguageType.UNKNOWN.value
        
        arabic_ratio = arabic_chars / total_chars
        if arabic_ratio > 0.7: return LanguageType.ARABIC.value
        if arabic_ratio < 0.3: return LanguageType.ENGLISH.value
        return LanguageType.MIXED.value

    def _extract_intents(self, text: str, language: str) -> List[Intent]:
        # الأولوية لنموذج HF إذا كان متاحاً
        if self.hf_cls_pipeline:
            # (هذا مثال، يتطلب نموذجاً مدرباً على النوايا المحددة)
            # For now, we'll stick to regex and fallback logic.
            pass

        # Fallback to Regex
        intents = []
        for intent_type, patterns in self.intent_patterns.items():
            for pattern in patterns.get(language, []):
                if re.search(pattern, text, re.IGNORECASE):
                    confidence = self._calculate_intent_confidence(text, pattern)
                    intents.append(Intent(type=intent_type, confidence=confidence))
                    break
        
        if not intents:
            intents = self._analyze_general_intent(text)
        
        intents.sort(key=lambda x: x.confidence, reverse=True)
        return intents[:3]

    def _extract_entities(self, text: str, language: str) -> Dict[str, List[str]]:
        entities = {
            'files': list(set(re.findall(r'[\w\-]+\.(?:py|dart|js|json|yaml|md|html|css|ts|tsx|java|kt)', text, re.IGNORECASE))),
            'urls': list(set(re.findall(r'https?://[^\s]+', text))),
            'code_elements': [], 'technologies': [], 'errors': []
        }
        
        # استخدام قاعدة المعرفة
        for word in re.split(r'\s|\W', text):
            kb_entry = self.project_kb.query(word)
            if kb_entry:
                entities['code_elements'].append(f"{word} ({kb_entry['type']} in {Path(kb_entry['file']).name})")

        # استخدام HF NER
        if self.hf_ner_pipeline and language == 'en':
            try:
                ner_results = self.hf_ner_pipeline(text)
                for result in ner_results:
                    label = result['entity_group']
                    if label not in entities: entities[label] = []
                    entities[label].append(result['word'])
            except Exception as e:
                logging.warning(f"HF NER pipeline failed: {e}")

        return entities

    def _extract_keywords(self, text: str, language: str) -> List[str]:
        if not nltk: return re.findall(r'\b\w{4,}\b', text.lower())[:10]
        
        stopwords_lang = 'arabic' if language == 'ar' else 'english'
        stopwords = set(nltk.corpus.stopwords.words(stopwords_lang))
        words = nltk.tokenize.word_tokenize(text.lower())
        return [word for word in words if word.isalpha() and word not in stopwords][:10]

    def _analyze_sentiment(self, text: str, language: str) -> str:
        if TextBlob and language == 'en':
            polarity = TextBlob(text).sentiment.polarity
            if polarity > 0.2: return "positive"
            if polarity < -0.2: return "negative"
            return "neutral"
        
        # Fallback
        positive_words = ['ممتاز', 'رائع', 'جيد', 'شكرا', 'أحسنت', 'great', 'good', 'thanks', 'excellent']
        negative_words = ['سيء', 'خطأ', 'مشكلة', 'فشل', 'لا يعمل', 'bad', 'error', 'problem', 'issue']
        if any(w in text for w in positive_words): return "positive"
        if any(w in text for w in negative_words): return "negative"
        return "neutral"

    # --- الدوال المساعدة ---
    def _calculate_intent_confidence(self, text: str, pattern: str) -> float:
        return 0.9 if text.lower().strip().startswith(pattern.lower()[:10]) else 0.7

    def _analyze_general_intent(self, text: str) -> List[Intent]:
        if '?' in text or text.lower().startswith(('how', 'what', 'why', 'where', 'when', 'is', 'can')):
            return [Intent(type=IntentType.QUESTION.value, confidence=0.6)]
        if any(w in text.lower() for w in ['error', 'bug', 'problem', 'issue', 'خطأ', 'مشكلة']):
            return [Intent(type=IntentType.ERROR_FIX.value, confidence=0.65)]
        return [Intent(type=IntentType.CONVERSATION.value, confidence=0.5)]
        
    def _calculate_complexity(self, text: str) -> float:
        score = len(text) / 500.0 + len(re.findall(r'```', text))
        return min(1.0, score)

    def _load_intent_patterns(self) -> Dict:
        return {
            IntentType.COMMAND.value: {'ar': [r'نفذ', r'شغل', r'قم ب'], 'en': [r'run', r'execute', r'create', r'do']},
            IntentType.CODE_HELP.value: {'ar': [r'كود', r'دالة'], 'en': [r'code', r'function', r'class']},
            IntentType.ERROR_FIX.value: {'ar': [r'أصلح الخطأ', r'حل مشكلة'], 'en': [r'fix the error', r'solve the issue']},
            IntentType.SUMMARIZATION.value: {'ar': [r'لخص', r'ملخص'], 'en': [r'summarize', r'summary']},
            IntentType.CORRECTION.value: {'ar': [r'لا، أقصد', r'ليس كذلك'], 'en': [r'no, i meant', r'that\'s wrong']},
        }
    
    def _fix_common_typos(self, text: str) -> str: return text # Placeholder
    def _normalize_punctuation(self, text: str) -> str: return text # Placeholder
    def _expand_abbreviations(self, text: str) -> str: return text # Placeholder
    def _process_slang(self, text: str) -> str: return text # Placeholder
    def _analyze_topics(self, text: str, keywords: List[str]) -> List[str]: return keywords # Placeholder

class ContextualUnderstanding:
    """فهم السياق المتقدم مع ذاكرة دائمة"""
    def __init__(self):
        self.profile_path = Path.home() / '.gemini-enhanced' / 'user_profile.json'
        self.history_path = Path.home() / '.gemini-enhanced' / 'conversation_history.json'
        self.user_profile = self._load_json(self.profile_path, default={})
        self.conversation_history = self._load_json(self.history_path, default=[])

    def _load_json(self, path: Path, default: Any) -> Any:
        if path.exists():
            with open(path, 'r', encoding='utf-8') as f:
                return json.load(f)
        return default

    def _save_json(self, path: Path, data: Any):
        path.parent.mkdir(exist_ok=True)
        with open(path, 'w', encoding='utf-8') as f:
            json.dump(data, f, ensure_ascii=False, indent=2)

    def understand_context(self, text: str, analysis: TextAnalysis) -> Dict[str, Any]:
        context = {
            'current_topic': analysis.topics[0] if analysis.topics else 'general',
            'user_intent_pattern': self.user_profile,
            'relevant_history': self._get_relevant_history(analysis),
            'suggested_responses': self._suggest_responses(analysis)
        }
        self._update_history(text, analysis, context)
        self._update_user_profile(analysis)
        return context

    def _get_relevant_history(self, analysis: TextAnalysis) -> List[Dict]:
        # Simple relevance: last 3 messages
        return self.conversation_history[-3:]

    def _suggest_responses(self, analysis: TextAnalysis) -> List[str]:
        suggestions = []
        if not analysis.intents: return []
        
        primary_intent = analysis.intents[0].type
        if primary_intent == IntentType.ERROR_FIX.value:
            suggestions.append("هل يمكنك مشاركة رسالة الخطأ الكاملة؟")
            suggestions.append("ما هي الخطوات التي أدت إلى هذا الخطأ؟")
        elif primary_intent == IntentType.COMMAND.value:
            suggestions.append("هل تريد مراجعة الأمر قبل التنفيذ؟")
        
        # Proactive suggestions
        if self.conversation_history:
            last_intent = self.conversation_history[-1].get('intents', [{}])[0].get('type')
            if last_intent == IntentType.ERROR_FIX.value:
                suggestions.append("هل تريد تشغيل الاختبارات للتحقق من الحل؟")
            if last_intent == IntentType.COMMAND.value and "create" in self.conversation_history[-1]['text']:
                 suggestions.append("هل تريد عمل commit للملفات الجديدة؟")

        return suggestions

    def _update_history(self, text: str, analysis: TextAnalysis, context: Dict):
        entry = {
            'text': text, 'timestamp': datetime.now().isoformat(),
            'language': analysis.language,
            'intents': [{'type': i.type, 'confidence': i.confidence} for i in analysis.intents],
            'topics': analysis.topics,
        }
        self.conversation_history.append(entry)
        self.conversation_history = self.conversation_history[-50:] # Keep last 50
        self._save_json(self.history_path, self.conversation_history)

    def _update_user_profile(self, analysis: TextAnalysis):
        # Update preferred language
        lang = analysis.language
        counts = self.user_profile.get('lang_counts', {})
        counts[lang] = counts.get(lang, 0) + 1
        self.user_profile['lang_counts'] = counts
        self.user_profile['preferred_language'] = max(counts, key=counts.get)
        
        # Update technical level (simplified)
        level = self.user_profile.get('tech_level', 0)
        self.user_profile['tech_level'] = level + (analysis.complexity - 0.5)
        
        self._save_json(self.profile_path, self.user_profile)

    def summarize_conversation(self) -> str:
        """يولد prompt لتلخيص المحادثة."""
        history_text = "\\n".join([f"User: {h['text']}" for h in self.conversation_history])
        return f"Please summarize the key points of the following conversation:\\n\\n{history_text}"

class SmartResponseGenerator:
    """مولد الردود الذكية المحسن"""
    def generate_enhanced_prompt(self, original_prompt: str, analysis: TextAnalysis, context: Dict[str, Any]) -> str:
        profile = context.get('user_intent_pattern', {})
        tech_level_score = profile.get('tech_level', 0)
        
        if tech_level_score > 10:
            detail_level = "Provide a detailed, expert-level explanation with advanced examples."
        elif tech_level_score < -5:
            detail_level = "Provide a simple, beginner-friendly explanation. Avoid jargon."
        else:
            detail_level = "Provide a balanced and clear explanation."

        lang_instruction = f"Please respond in {profile.get('preferred_language', analysis.language)}."

        prompt = f"""
{lang_instruction}
{detail_level}

**User's Original Request:**
{original_prompt}

**Analysis & Context:**
- **Detected Intent:** {analysis.intents[0].type if analysis.intents else 'N/A'} (Confidence: {analysis.intents[0].confidence:.2f})
- **Key Topics:** {', '.join(analysis.topics)}
- **Sentiment:** {analysis.sentiment}
- **User's Technical Level Estimate:** {'Advanced' if tech_level_score > 10 else 'Beginner' if tech_level_score < -5 else 'Intermediate'}

**Instructions for Assistant:**
- Address the user's request directly.
- If fixing an error, explain the root cause and provide a corrected code snippet.
- If helping with code, adhere to best practices for the identified technologies.
- If the user seems frustrated (negative sentiment), be encouraging.
"""
        return prompt

# --- الدالة الرئيسية للتكامل ---
def process_user_input(text: str, project_path: str) -> Dict[str, Any]:
    """
    الدالة الرئيسية التي تنسق عملية التحليل بأكملها.
    """
    # تهيئة المعالجات (في تطبيق حقيقي، ستكون هذه singletons)
    text_processor = SmartTextProcessor(project_path)
    context_analyzer = ContextualUnderstanding()
    response_generator = SmartResponseGenerator()
    
    # 1. تحليل النص
    analysis = text_processor.analyze_text(text)
    
    # 2. فهم السياق
    context = context_analyzer.understand_context(text, analysis)
    
    # 3. التعامل مع النوايا الخاصة (مثل التلخيص)
    primary_intent = analysis.intents[0].type if analysis.intents else None
    if primary_intent == IntentType.SUMMARIZATION.value:
        enhanced_prompt = context_analyzer.summarize_conversation()
    else:
        # 4. توليد prompt محسّن
        enhanced_prompt = response_generator.generate_enhanced_prompt(text, analysis, context)
    
    return {
        'original_text': text,
        'analysis': analysis,
        'context': context,
        'enhanced_prompt': enhanced_prompt,
        'suggestions': context.get('suggested_responses', []),
    }

if __name__ == "__main__":
    # مثال للاستخدام من سطر الأوامر
    # في التطبيق الفعلي، سيتم استدعاء process_user_input من Gemini CLI
    
    # افترض أننا في مشروع
    current_project_path = "." 
    
    # مسح المشروع لبناء قاعدة المعرفة (يحدث مرة واحدة أو بشكل دوري)
    kb = ProjectKnowledgeBase(current_project_path)
    # kb.scan_project() # يمكن تفعيلها لبناء قاعدة المعرفة

    test_texts = [
        "how to fix the 'User' class? i have an error",
        "لخص محادثتنا حتى الآن",
        "run the tests for me"
    ]
    
    for text in test_texts:
        print(f"\\n{'='*60}")
        print(f"Processing Text: {text}")
        print(f"{'='*60}")
        
        result = process_user_input(text, current_project_path)
        
        print(f"Language: {result['analysis'].language}")
        print(f"Intents: {[i.type for i in result['analysis'].intents]}")
        print(f"Entities: {result['analysis'].entities}")
        print(f"Suggestions: {result['suggestions']}")
        print(f"\\n--- Enhanced Prompt for Gemini ---")
        print(result['enhanced_prompt'].strip())
        print(f"--- End of Prompt ---")