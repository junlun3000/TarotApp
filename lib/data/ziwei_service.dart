import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/ziwei_chart.dart';
import '../models/ziwei_reading.dart';
import 'worker_config.dart';

/// 紫微斗数排盘 + AI 解读，走同一个 Worker（`/ziwei-chart` 只排盘不调
/// Claude，免费快；`/ziwei-reading` 会重新排一次盘再调 Claude 生成解读，
/// 两边各自独立调用，不依赖对方的结果）。
class ZiweiService {
  const ZiweiService();

  Future<ZiweiChart> fetchChart({
    required DateTime birthDate,
    required int timeIndex,
    required String gender,
  }) async {
    final response = await http.post(
      Uri.parse('${WorkerConfig.baseUrl}/ziwei-chart'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(_birthInfoJson(birthDate, timeIndex, gender)),
    );

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode != 200) {
      throw ZiweiException(body['error'] as String? ?? '未知错误');
    }
    return ZiweiChart.fromJson(
      Map<String, dynamic>.from(body['chart'] as Map),
    );
  }

  Future<ZiweiReadingResult> generateReading({
    required DateTime birthDate,
    required int timeIndex,
    required String gender,
    String? question,
    String? background,
  }) async {
    final response = await http.post(
      Uri.parse('${WorkerConfig.baseUrl}/ziwei-reading'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        ..._birthInfoJson(birthDate, timeIndex, gender),
        'question': question,
        'background': background,
      }),
    );

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode != 200) {
      throw ZiweiException(body['error'] as String? ?? '未知错误');
    }
    return ZiweiReadingResult(
      chart: ZiweiChart.fromJson(
        Map<String, dynamic>.from(body['chart'] as Map),
      ),
      reading: ZiweiReading.fromJson(
        Map<String, dynamic>.from(body['reading'] as Map),
      ),
    );
  }

  Map<String, dynamic> _birthInfoJson(
    DateTime birthDate,
    int timeIndex,
    String gender,
  ) {
    final y = birthDate.year.toString().padLeft(4, '0');
    final m = birthDate.month.toString().padLeft(2, '0');
    final d = birthDate.day.toString().padLeft(2, '0');
    return {
      'birthDate': '$y-$m-$d',
      'timeIndex': timeIndex,
      'gender': gender,
    };
  }
}

class ZiweiReadingResult {
  const ZiweiReadingResult({required this.chart, required this.reading});

  final ZiweiChart chart;
  final ZiweiReading reading;
}

class ZiweiException implements Exception {
  const ZiweiException(this.message);

  final String message;

  @override
  String toString() => message;
}
