import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/ai_reading.dart';
import '../models/drawn_card.dart';
import 'worker_config.dart';

/// 调用后端 Cloudflare Worker，让它代理转发到 Claude API，生成一段
/// 针对这次抽牌结果的解读文字。
///
/// App 本身不直接持有 Anthropic API key（那样会被反编译拿走），
/// 所有请求都先经过 Worker。
class AiReadingService {
  const AiReadingService();

  Future<AiReading> generateReading({
    required String spreadName,
    required List<DrawnCard> drawnCards,
    String? question,
    String? background,
  }) async {
    final response = await http.post(
      Uri.parse(WorkerConfig.baseUrl),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'question': question,
        'background': background,
        'spreadName': spreadName,
        'cards': [
          for (final drawn in drawnCards)
            {
              'nameZh': drawn.card.nameZh,
              'positionLabel': drawn.positionLabel,
              'orientation': drawn.orientation.name,
              'keywords': drawn.card.keywords,
            },
        ],
      }),
    );

    final body = jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode != 200) {
      throw AiReadingException(body['error'] as String? ?? '未知错误');
    }

    return AiReading.fromJson(
      Map<String, dynamic>.from(body['reading'] as Map),
    );
  }
}

class AiReadingException implements Exception {
  const AiReadingException(this.message);

  final String message;

  @override
  String toString() => message;
}
