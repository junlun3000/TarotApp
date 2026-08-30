/// AI 深度解读的结构化结果——不再是一整段自由文本，而是拆成"整体印象 +
/// 逐张牌的解读 + 建议"三块，好让 UI 能把每张牌的图片跟它自己的那段
/// 解读文字精确配对展示（图文故事的排版），而不是图片和文字各摆各的。
///
/// [cards] 的顺序跟请求时传给 Worker 的抽牌结果顺序一致，UI 按下标
/// 对应回 [DrawnCard] 列表取图片；[positionLabel]/[cardNameZh] 只是
/// 从 Claude 的结构化输出里原样带回来，用来兜底校验/展示，不参与匹配。
class AiReading {
  const AiReading({
    required this.themeTitle,
    required this.overview,
    required this.cards,
    required this.advice,
  });

  /// 3-4 个词概括整个牌阵主题（顿号分隔），给分享卡片当标题用。
  final String themeTitle;
  final String overview;
  final List<AiReadingCardSection> cards;
  final String advice;

  factory AiReading.fromJson(Map<String, dynamic> json) {
    return AiReading(
      themeTitle: json['themeTitle'] as String? ?? '',
      overview: json['overview'] as String? ?? '',
      cards: (json['cards'] as List? ?? const [])
          .map(
            (e) => AiReadingCardSection.fromJson(
              Map<String, dynamic>.from(e as Map),
            ),
          )
          .toList(),
      advice: json['advice'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'themeTitle': themeTitle,
      'overview': overview,
      'cards': cards.map((c) => c.toJson()).toList(),
      'advice': advice,
    };
  }
}

class AiReadingCardSection {
  const AiReadingCardSection({
    required this.positionLabel,
    required this.cardNameZh,
    required this.keywordCore,
    required this.interpretation,
  });

  final String positionLabel;
  final String cardNameZh;

  /// 3-4 个词概括这张牌在这个位置的核心特质（顿号分隔），分享卡片用。
  final String keywordCore;
  final String interpretation;

  factory AiReadingCardSection.fromJson(Map<String, dynamic> json) {
    return AiReadingCardSection(
      positionLabel: json['positionLabel'] as String? ?? '',
      cardNameZh: json['cardNameZh'] as String? ?? '',
      keywordCore: json['keywordCore'] as String? ?? '',
      interpretation: json['interpretation'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'positionLabel': positionLabel,
      'cardNameZh': cardNameZh,
      'keywordCore': keywordCore,
      'interpretation': interpretation,
    };
  }
}
