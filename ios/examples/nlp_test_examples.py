#!/usr/bin/env python3
"""
أمثلة لاختبار معالج اللغة الطبيعية المتقدم
"""
import sys
from pathlib import Path

# إضافة المسار الرئيسي للمشروع
sys.path.append(str(Path(__file__).parent.parent))

from natural_language_processor import (
    SmartTextProcessor, 
    ContextualUnderstanding,
    SmartResponseGenerator,
    process_user_input
)

# أمثلة نصوص للاختبار
test_examples = {
    "أسئلة عربية": [
        "كيف أقوم بإنشاء تطبيق Flutter يستخدم GetX للإدارة الحالة؟",
        "ما هو الفرق بين Python و JavaScript في البرمجة؟",
        "اشرح لي مفهوم Machine Learning بشكل مبسط",
        "كيف أحل مشكلة CORS في تطبيق React مع Express backend؟",
        "ما هي أفضل الممارسات لتأمين API في Django؟"
    ],
    
    "أسئلة إنجليزية": [
        "How do I create a REST API with FastAPI and PostgreSQL?",
        "What's the difference between let, const and var in JavaScript?",
        "Explain async/await in Python with examples",
        "How to optimize React app performance with large datasets?",
        "Best practices for microservices architecture"
    ],
    
    "نصوص مختلطة": [
        "أريد إنشاء mobile app باستخدام Flutter مع backend بـ Node.js",
        "عندي error: Cannot find module 'express' كيف أحل المشكلة؟",
        "اشرح لي الـ Design Patterns الأساسية في OOP",
        "أحتاج لعمل authentication system آمن لتطبيق Django",
        "كيف أستخدم Docker containers مع Python applications؟"
    ],
    
    "أخطاء ومشاكل": [
        "TypeError: Cannot read property 'map' of undefined في React",
        "خطأ: ImportError: No module named 'numpy' رغم أني ثبتته",
        "التطبيق بطيء جداً عند تحميل 10000 row من database",
        "CORS error عند محاولة الاتصال بـ API من React app",
        "Memory leak في تطبيق Node.js كيف أكتشفه وأحله؟"
    ],
    
    "طلبات كود": [
        "اكتب لي function لترتيب array of objects حسب property معين",
        "أريد كود Python لقراءة CSV file وتحويله إلى JSON",
        "قم بإنشاء React component للـ infinite scrolling",
        "اكتب validation schema باستخدام Joi لـ user registration",
        "أحتاج Flutter widget مخصص لعرض charts"
    ],
    
    "نصوص عامية": [
        "ايه احسن framework للـ web development دلوقتي؟",
        "مش عارف ازاي اعمل deployment للـ app بتاعي",
        "الكود ده مش شغال ليه؟ ممكن تساعدني؟",
        "عايز اتعلم programming من الصفر ابدأ بايه؟",
        "ازاي اخلي الـ website responsive على كل الأجهزة؟"
    ]
}

def test_text_processor():
    """اختبار معالج النص"""
    print("🧪 اختبار معالج النص")
    print("=" * 60)
    
    processor = SmartTextProcessor()
    
    for category, examples in test_examples.items():
        print(f"\n📁 {category}:")
        print("-" * 40)
        
        for text in examples[:2]:  # أول مثالين من كل فئة
            print(f"\n📝 النص: {text}")
            
            # تحليل النص
            analysis = processor.analyze_text(text)
            
            print(f"🌐 اللغة: {analysis.language}")
            print(f"💭 المشاعر: {analysis.sentiment}")
            print(f"📈 التعقيد: {analysis.complexity:.2f}")
            
            if analysis.intents:
                print(f"🎯 النية الرئيسية: {analysis.intents[0].type} (ثقة: {analysis.intents[0].confidence:.2f})")
            
            if analysis.keywords:
                print(f"🏷️  كلمات مفتاحية: {', '.join(analysis.keywords[:5])}")
            
            if analysis.entities.get('technologies'):
                print(f"💻 تقنيات: {', '.join(analysis.entities['technologies'])}")
            
            if analysis.entities.get('errors'):
                print(f"❌ أخطاء: {', '.join(analysis.entities['errors'])}")
            
            print("-" * 40)

def test_context_understanding():
    """اختبار فهم السياق"""
    print("\n\n🧪 اختبار فهم السياق")
    print("=" * 60)
    
    processor = SmartTextProcessor()
    context_analyzer = ContextualUnderstanding()
    
    # محادثة متسلسلة
    conversation = [
        "أريد إنشاء تطبيق Flutter",
        "كيف أضيف authentication للتطبيق؟",
        "وما هي أفضل packages للـ state management؟",
        "شكراً، هل يمكنك اقتراح UI libraries أيضاً؟"
    ]
    
    print("📱 محادثة عن تطوير Flutter:")
    print("-" * 40)
    
    for i, text in enumerate(conversation, 1):
        print(f"\n{i}. المستخدم: {text}")
        
        # تحليل النص
        analysis = processor.analyze_text(text)
        
        # فهم السياق
        context = context_analyzer.understand_context(text, analysis)
        
        print(f"   📍 الموضوع الحالي: {context['current_topic']}")
        print(f"   🔄 تدفق المحادثة: {context['conversation_flow']['type']}")
        
        if context.get('context_switches'):
            print(f"   ⚡ تغييرات السياق: {', '.join(context['context_switches'])}")
        
        if context.get('suggested_responses'):
            print(f"   💡 ردود مقترحة:")
            for j, suggestion in enumerate(context['suggested_responses'][:2], 1):
                print(f"      {j}. {suggestion}")

def test_response_generation():
    """اختبار توليد الردود المحسّنة"""
    print("\n\n🧪 اختبار توليد الردود المحسّنة")
    print("=" * 60)
    
    # أمثلة مختلفة
    test_prompts = [
        {
            "text": "خطأ: Cannot connect to database في Django",
            "description": "طلب حل خطأ"
        },
        {
            "text": "أريد شرح مبسط لمفهوم Recursion",
            "description": "طلب شرح"
        },
        {
            "text": "اكتب كود Python لحساب Fibonacci sequence",
            "description": "طلب كود"
        }
    ]
    
    for example in test_prompts:
        print(f"\n📋 {example['description']}")
        print(f"📝 النص: {example['text']}")
        print("-" * 40)
        
        # معالجة النص
        result = process_user_input(example['text'])
        
        # عرض الـ prompt المحسّن
        enhanced = result['enhanced_prompt']
        print(f"✨ الـ Prompt المحسّن:")
        print(enhanced[:300] + "..." if len(enhanced) > 300 else enhanced)
        
        # معلومات إضافية
        print(f"\n📊 معلومات التحليل:")
        print(f"   - اللغة: {result['analysis'].language}")
        print(f"   - النوايا: {[i.type for i in result['analysis'].intents]}")
        print(f"   - الثقة: {result['metadata']['confidence']:.2f}")

def test_edge_cases():
    """اختبار الحالات الخاصة"""
    print("\n\n🧪 اختبار الحالات الخاصة")
    print("=" * 60)
    
    processor = SmartTextProcessor()
    
    edge_cases = [
        "",  # نص فارغ
        "؟",  # علامة استفهام فقط
        "!@#$%^&*()",  # رموز فقط
        "ااااااااااا",  # تكرار حرف
        "a" * 1000,  # نص طويل جداً
        "مرحبا Hello שלום",  # لغات متعددة
        "😀🎉👍",  # إيموجي فقط
    ]
    
    for text in edge_cases:
        try:
            display_text = text[:20] + "..." if len(text) > 20 else text
            print(f"\n🔸 اختبار: '{display_text}'")
            
            analysis = processor.analyze_text(text)
            print(f"   ✅ نجح - اللغة: {analysis.language}")
            
        except Exception as e:
            print(f"   ❌ فشل: {str(e)}")

def run_all_tests():
    """تشغيل جميع الاختبارات"""
    print("🚀 بدء اختبار معالج اللغة الطبيعية المتقدم")
    print("=" * 80)
    
    tests = [
        ("معالج النص", test_text_processor),
        ("فهم السياق", test_context_understanding),
        ("توليد الردود", test_response_generation),
        ("الحالات الخاصة", test_edge_cases)
    ]
    
    for name, test_func in tests:
        try:
            test_func()
            print(f"\n✅ اختبار {name} اكتمل بنجاح")
        except Exception as e:
            print(f"\n❌ فشل اختبار {name}: {str(e)}")
    
    print("\n" + "=" * 80)
    print("✨ اكتملت جميع الاختبارات!")

if __name__ == "__main__":
    # تشغيل اختبار محدد أو جميع الاختبارات
    if len(sys.argv) > 1:
        test_name = sys.argv[1]
        if test_name == "text":
            test_text_processor()
        elif test_name == "context":
            test_context_understanding()
        elif test_name == "response":
            test_response_generation()
        elif test_name == "edge":
            test_edge_cases()
        else:
            print(f"❌ اختبار غير معروف: {test_name}")
            print("الاختبارات المتاحة: text, context, response, edge")
    else:
        run_all_tests() 