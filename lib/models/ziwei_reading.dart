/// 紫微斗数 AI 解读结果——跟 [AiReading]（塔罗那边）是同一个思路：
/// 拆成"整体印象 / 挑几个宫位解读 / 当前运势 / 建议"结构化返回，而不是
/// 一整段自由文本，方便 UI 分块展示。
class ZiweiReading {
  const ZiweiReading({
    required this.overview,
    required this.fourTransformations,
    required this.palaces,
    required this.lifeStages,
    required this.currentFortune,
    required this.advice,
    required this.keySummary,
  });

  final String overview;
  final String fourTransformations;
  final List<ZiweiPalaceReading> palaces;
  final String lifeStages;
  final String currentFortune;
  final String advice;
  final String keySummary;

  factory ZiweiReading.fromJson(Map<String, dynamic> json) {
    return ZiweiReading(
      overview: json['overview'] as String? ?? '',
      fourTransformations: json['fourTransformations'] as String? ?? '',
      palaces: (json['palaces'] as List? ?? const [])
          .map(
            (e) => ZiweiPalaceReading.fromJson(
              Map<String, dynamic>.from(e as Map),
            ),
          )
          .toList(),
      lifeStages: json['lifeStages'] as String? ?? '',
      currentFortune: json['currentFortune'] as String? ?? '',
      advice: json['advice'] as String? ?? '',
      keySummary: json['keySummary'] as String? ?? '',
    );
  }
}

class ZiweiPalaceReading {
  const ZiweiPalaceReading({required this.name, required this.interpretation});

  final String name;
  final String interpretation;

  factory ZiweiPalaceReading.fromJson(Map<String, dynamic> json) {
    return ZiweiPalaceReading(
      name: json['name'] as String? ?? '',
      interpretation: json['interpretation'] as String? ?? '',
    );
  }
}
