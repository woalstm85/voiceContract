import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// 텍스트 번역을 담당하는 서비스 클래스
class TranslationService {
  // 텍스트 번역
  Future<String> translate(String text, String targetLanguage) async {
    try {
      final apiKey = dotenv.env['GOOGLE_API_KEY'] ?? '';

      if (apiKey.isEmpty) {
        throw Exception('API 키가 설정되지 않았습니다');
      }

      final uri = Uri.parse('https://translation.googleapis.com/language/translate/v2?key=$apiKey');

      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'q': text,
          'source': 'ko',
          'target': targetLanguage,
        }),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        return data['data']['translations'][0]['translatedText'];
      } else {
        print('번역 API 오류: ${response.statusCode} ${response.body}');
        return '';
      }
    } catch (e) {
      print('번역 오류: $e');
      return '';
    }
  }
}