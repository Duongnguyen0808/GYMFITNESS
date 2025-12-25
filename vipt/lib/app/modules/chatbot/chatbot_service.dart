import 'dart:convert';
import 'package:http/http.dart' as http;

class ChatbotService {
  String get _apiKey => '';

  Future<List<String>> getAvailableModels() async {
    try {
      final response = await http
          .get(
            Uri.parse(
                'https://generativelanguage.googleapis.com/v1beta/models?key=$_apiKey'),
          )
          .timeout(Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        List<String> models = [];
        if (data['models'] != null) {
          for (var model in data['models']) {
            String name = model['name'] ?? '';

            List<dynamic>? supportedMethods =
                model['supportedGenerationMethods'];
            bool supportsGenerateContent =
                supportedMethods?.contains('generateContent') ?? false;

            if (supportsGenerateContent &&
                name.toLowerCase().contains('gemini')) {
              if (name.startsWith('models/')) {
                name = name.substring(7);
              }
              models.add(name);
            }
          }
        }
        return models;
      } else {
        return [];
      }
    } catch (e) {
      return [];
    }
  }

  Future<String> sendMessage(
      String userMessage, List<Map<String, String>> conversationHistory) async {
    List<String> availableModels = [];
    try {
      availableModels =
          await getAvailableModels().timeout(Duration(seconds: 5));
    } catch (e) {}

    List<String> endpoints = [];
    Set<String> addedModels = {};

    if (availableModels.isNotEmpty) {
      List<String> sortedModels = List.from(availableModels);
      sortedModels.sort((a, b) {
        String lowerA = a.toLowerCase();
        String lowerB = b.toLowerCase();

        bool aIsFlash = lowerA.contains('flash');
        bool bIsFlash = lowerB.contains('flash');
        if (aIsFlash && !bIsFlash) return -1;
        if (!aIsFlash && bIsFlash) return 1;

        bool aIsLatest = lowerA.contains('latest');
        bool bIsLatest = lowerB.contains('latest');
        if (aIsLatest && !bIsLatest) return -1;
        if (!aIsLatest && bIsLatest) return 1;

        return 0;
      });

      for (String model in sortedModels) {
        if (!addedModels.contains(model)) {
          endpoints.add(
              'https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent?key=$_apiKey');
          addedModels.add(model);
        }
      }
    }

    List<String> backupModels = [
      'gemini-1.5-flash-latest',
      'gemini-1.5-flash',
      'gemini-1.5-pro-latest',
      'gemini-1.5-pro',
      'gemini-pro',
    ];

    for (String model in backupModels) {
      if (!addedModels.contains(model)) {
        endpoints.add(
            'https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent?key=$_apiKey');
        addedModels.add(model);
      }
    }

    Exception? lastError;
    String? lastErrorMessage;

    for (String endpoint in endpoints) {
      try {
        String result =
            await _trySendMessage(endpoint, userMessage, conversationHistory);
        return result;
      } catch (e) {
        String errorMsg = e.toString();
        lastError = e is Exception ? e : Exception(errorMsg);
        lastErrorMessage = errorMsg;

        if (errorMsg.contains('API key') ||
            errorMsg.contains('quota') ||
            errorMsg.contains('permission') ||
            errorMsg.contains('403')) {
          throw lastError;
        }

        continue;
      }
    }
    String finalError = 'Không thể kết nối với API. ';
    if (lastErrorMessage != null) {
      if (lastErrorMessage.contains('not found')) {
        finalError +=
            'Không tìm thấy model phù hợp. Vui lòng kiểm tra API key.';
      } else if (lastErrorMessage.contains('timeout')) {
        finalError += 'Kết nối quá chậm. Vui lòng thử lại sau.';
      } else {
        finalError += lastErrorMessage;
      }
    }
    throw Exception(finalError);
  }

  Future<String> _trySendMessage(
    String apiUrl,
    String userMessage,
    List<Map<String, String>> conversationHistory,
  ) async {
    try {
      List<Map<String, dynamic>> contents = [];

      for (var msg in conversationHistory) {
        if (msg['role'] == null || msg['content'] == null) continue;
        if (msg['content']?.isEmpty ?? true) continue;

        if (msg['role'] != 'user' && msg['role'] != 'assistant') continue;

        String role = msg['role'] == 'user' ? 'user' : 'model';
        contents.add({
          'role': role,
          'parts': [
            {'text': msg['content']!}
          ]
        });
      }

      DateTime now = DateTime.now();
      String currentDate = '${now.day}/${now.month}/${now.year}';
      List<String> daysOfWeek = [
        'Chủ nhật',
        'Thứ hai',
        'Thứ ba',
        'Thứ tư',
        'Thứ năm',
        'Thứ sáu',
        'Thứ bảy'
      ];
      String currentDay = daysOfWeek[now.weekday % 7];
      String currentDayFull =
          '$currentDay, ngày ${now.day} tháng ${now.month} năm ${now.year}';

      String finalUserMessage = userMessage;
      String lowerMessage = userMessage.toLowerCase();
      if (lowerMessage.contains('ngày') ||
          lowerMessage.contains('hôm nay') ||
          lowerMessage.contains('date') ||
          lowerMessage.contains('thứ') ||
          lowerMessage.contains('bao nhiêu')) {
        finalUserMessage =
            '[THÔNG TIN: Hôm nay là $currentDayFull] $userMessage';
      }

      // Thêm tin nhắn hiện tại với context nếu cần
      contents.add({
        'role': 'user',
        'parts': [
          {'text': finalUserMessage}
        ]
      });

      String systemInstruction = '''
Bạn là trợ lý AI của ViPT về tập luyện và dinh dưỡng.

THÔNG TIN QUAN TRỌNG VỀ NGÀY THÁNG:
- Hôm nay là: $currentDayFull
- Ngày hiện tại: $currentDate
- Khi được hỏi về ngày tháng, hãy trả lời chính xác theo thông tin trên.

QUY TẮC TRẢ LỜI:
- Trả lời chính xác, ngắn gọn bằng tiếng Việt
- KHÔNG dùng markdown formatting như **, *, _, #, `, []
- KHÔNG dùng ký tự đặc biệt như \$1, \$2, #1, #2
- Trả lời tự nhiên và dễ hiểu
- Khi liệt kê, HÃY DÙNG dấu gạch đầu dòng (-) để dễ đọc. Ví dụ:
  - Điểm 1
  - Điểm 2
  - Điểm 3
- Có thể dùng số thường (1, 2, 3) nhưng ưu tiên dùng gạch đầu dòng (-)
''';

      Map<String, dynamic> requestBody = {
        'contents': contents,
      };

      if (apiUrl.contains('/v1beta/')) {
        requestBody['systemInstruction'] = {
          'parts': [
            {'text': systemInstruction}
          ]
        };
      }

      final response = await http
          .post(
            Uri.parse(apiUrl),
            headers: {
              'Content-Type': 'application/json',
            },
            body: jsonEncode(requestBody),
          )
          .timeout(Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['candidates'] != null &&
            data['candidates'].isNotEmpty &&
            data['candidates'][0]['content'] != null &&
            data['candidates'][0]['content']['parts'] != null &&
            data['candidates'][0]['content']['parts'].isNotEmpty) {
          String text = data['candidates'][0]['content']['parts'][0]['text'];
          return text;
        } else {
          throw Exception('Invalid response format: ${jsonEncode(data)}');
        }
      } else {
        String errorMsg = 'HTTP ${response.statusCode}';
        try {
          final errorData = jsonDecode(response.body);
          errorMsg = errorData['error']?['message'] ??
              errorData['error']?.toString() ??
              errorMsg;
        } catch (e) {
          errorMsg =
              'HTTP ${response.statusCode}: ${response.body.substring(0, response.body.length > 200 ? 200 : response.body.length)}';
        }
        throw Exception('API Error: $errorMsg');
      }
    } catch (e) {
      rethrow;
    }
  }
}
