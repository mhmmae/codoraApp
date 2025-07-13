#!/usr/bin/env python3
# This file makes the directory a Python package
"""
حزمة Gemini CLI المحسّنة
تحتوي على جميع الوحدات المطلوبة لتشغيل Gemini CLI
"""

__version__ = "2.0.0"
__author__ = "Gemini CLI Team"

# استيراد الوحدات الرئيسية
from .conversation_manager import ConversationManager
from .gemini_smart import EnhancedGeminiCLI

# استيراد اختياري للوحدات الإضافية
try:
    from .error_analyzer import SmartErrorAnalyzer
except ImportError:
    SmartErrorAnalyzer = None

try:
    from .natural_language_processor import SmartTextProcessor
except ImportError:
    SmartTextProcessor = None

__all__ = [
    'ConversationManager',
    'EnhancedGeminiCLI',
    'SmartErrorAnalyzer',
    'SmartTextProcessor'
]