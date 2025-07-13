import 'dart:convert';
import 'package:http/http.dart' as http;

class GeminiService {
  static const String _baseUrl = 'https://generativelanguage.googleapis.com/v1beta';
  final String _apiKey;
  
  GeminiService(this._apiKey);
  
  // تحسين الاستجابات بـ custom system instructions
  Future<String> generateContent({
    required String prompt,
    String? systemInstruction,
    double temperature = 0.7,
    int maxOutputTokens = 1024,
  }) async {
    final url = Uri.parse('$_baseUrl/models/gemini-pro:generateContent?key=$_apiKey');
    
    final body = {
      'contents': [
        {
          'parts': [
            {'text': prompt}
          ]
        }
      ],
      'generationConfig': {
        'temperature': temperature,
        'maxOutputTokens': maxOutputTokens,
      }
    };
    
    // إضافة system instruction لتحسين الذكاء
    if (systemInstruction != null) {
      body['systemInstruction'] = {
        'parts': [
          {'text': systemInstruction}
        ]
      };
    }
    
    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
      },
      body: json.encode(body),
    );
    
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['candidates'][0]['content']['parts'][0]['text'];
    } else {
      throw Exception('فشل في الاتصال بـ Gemini API: ${response.statusCode}');
    }
  }
  
  // إضافة context awareness لجعلها أكثر ذكاءً
  Future<String> smartGenerate({
    required String prompt,
    Map<String, dynamic>? context,
    String userPreferences = '',
  }) async {
    String enhancedPrompt = prompt;
    
    // إضافة السياق
    if (context != null) {
      enhancedPrompt = '''
السياق: ${json.encode(context)}

تفضيلات المستخدم: $userPreferences

المطلوب: $prompt

يرجى الإجابة بناءً على السياق المعطى ومراعاة تفضيلات المستخدم.
''';
    }
    
    return generateContent(
      prompt: enhancedPrompt,
      systemInstruction: '''
أنت مساعد ذكي ومتخصص. 
- استخدم السياق المعطى بذكاء
- اعطِ إجابات دقيقة ومفصلة
- راعِ تفضيلات المستخدم
- تحدث بالعربية عند الطلب
''',
      temperature: 0.8,
    );
  }
}

// مثال على الاستخدام المحسن
class SmartGeminiHelper {
  final GeminiService _geminiService;
  final Map<String, dynamic> _userContext = {};
  
  SmartGeminiHelper(String apiKey) : _geminiService = GeminiService(apiKey);
  
  // تعلم من تفاعلات المستخدم
  void updateUserContext(String key, dynamic value) {
    _userContext[key] = value;
  }
  
  Future<String> askWithMemory(String question) async {
    // استخدام الذاكرة السابقة لتحسين الإجابات
    return await _geminiService.smartGenerate(
      prompt: question,
      context: _userContext,
      userPreferences: 'يفضل الإجابات التفصيلية والأمثلة العملية',
    );
  }
} 