import 'dart:convert';

import 'package:http/http.dart' as http;

import 'worker_config.dart';

/// 拍照识别实体塔罗牌的结果。[cardNameZh] 保证是 App 本地 78 张牌数据里的
/// 一个（Worker 端用 JSON schema 的 enum 约束了 Claude 的回答范围），
/// 拿到手直接按名字去本地牌库找对应的 [TarotCard] 就行。
class CardScanResult {
  const CardScanResult({
    required this.recognized,
    required this.cardNameZh,
    required this.isReversed,
    required this.notes,
  });

  final bool recognized;
  final String cardNameZh;
  final bool isReversed;
  final String notes;

  factory CardScanResult.fromJson(Map<String, dynamic> json) {
    return CardScanResult(
      recognized: json['recognized'] as bool? ?? false,
      cardNameZh: json['cardNameZh'] as String? ?? '',
      isReversed: json['orientation'] == 'reversed',
      notes: json['notes'] as String? ?? '',
    );
  }
}

/// 把实体塔罗牌的照片传给后端 Worker，让 Claude 的视觉能力识别这是
/// 哪张牌、正位还是逆位——给"用户手上有实体牌"这种场景用，跟数字抽牌
/// （[DrawService]）是两条不同的取牌路径，抽完之后汇合到同一个
/// [DrawResultScreen] 展示。
class CardScanService {
  const CardScanService();

  Future<CardScanResult> identifyCard({
    required List<int> imageBytes,
    required String mediaType,
  }) async {
    final response = await http.post(
      Uri.parse('${WorkerConfig.baseUrl}/identify-card'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'imageBase64': base64Encode(imageBytes),
        'mediaType': mediaType,
      }),
    );

    final body = jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode != 200) {
      throw CardScanException(body['error'] as String? ?? '未知错误');
    }

    return CardScanResult.fromJson(
      Map<String, dynamic>.from(body['result'] as Map),
    );
  }
}

class CardScanException implements Exception {
  const CardScanException(this.message);

  final String message;

  @override
  String toString() => message;
}
