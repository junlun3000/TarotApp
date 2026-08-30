import 'ai_reading.dart';
import 'drawn_card.dart';

/// 历史记录里保存的单张牌结果（只存牌的 id，实际的牌名/含义等
/// 从 [TarotCard] 数据里按 id 查，避免文案改了以后历史记录里的内容跟着串）。
class HistoryCardEntry {
  const HistoryCardEntry({
    required this.cardId,
    required this.orientation,
    this.positionLabel,
  });

  final String cardId;
  final CardOrientation orientation;
  final String? positionLabel;

  factory HistoryCardEntry.fromJson(Map<String, dynamic> json) {
    return HistoryCardEntry(
      cardId: json['cardId'] as String,
      orientation: CardOrientation.values.byName(json['orientation'] as String),
      positionLabel: json['positionLabel'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'cardId': cardId,
      'orientation': orientation.name,
      'positionLabel': positionLabel,
    };
  }
}

/// 一条抽牌历史记录 —— 对应"阅读日记"里的一条条目：
/// 什么时候、用什么牌阵、（如果有的话）问了什么问题、抽到了哪些牌。
class ReadingHistoryEntry {
  const ReadingHistoryEntry({
    required this.id,
    required this.dateTime,
    required this.spreadId,
    required this.spreadNameZh,
    required this.cards,
    this.question,
    this.aiReading,
  });

  final String id;
  final DateTime dateTime;
  final String spreadId;
  final String spreadNameZh;
  final List<HistoryCardEntry> cards;

  /// 占卜时问的问题；目前 App 里还没有具体的"输入问题"页面，先留空可选。
  final String? question;

  /// AI 深度解读的结果——抽牌当下还没有（要等用户点了"AI 深度解读"、
  /// Claude 生成完才回填进这条记录），所以是可选的。
  final AiReading? aiReading;

  /// 生成一份带上 [reading] 的新记录，其余字段原样保留——用在 AI 解读
  /// 生成完之后回写历史记录的场景。
  ReadingHistoryEntry withAiReading(AiReading reading) {
    return ReadingHistoryEntry(
      id: id,
      dateTime: dateTime,
      spreadId: spreadId,
      spreadNameZh: spreadNameZh,
      cards: cards,
      question: question,
      aiReading: reading,
    );
  }

  factory ReadingHistoryEntry.fromJson(Map<String, dynamic> json) {
    final rawAiReading = json['aiReading'];
    return ReadingHistoryEntry(
      id: json['id'] as String,
      dateTime: DateTime.parse(json['dateTime'] as String),
      spreadId: json['spreadId'] as String,
      spreadNameZh: json['spreadNameZh'] as String,
      question: json['question'] as String?,
      cards: (json['cards'] as List)
          .map(
            (e) =>
                HistoryCardEntry.fromJson(Map<String, dynamic>.from(e as Map)),
          )
          .toList(),
      aiReading: rawAiReading == null
          ? null
          : AiReading.fromJson(Map<String, dynamic>.from(rawAiReading as Map)),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'dateTime': dateTime.toIso8601String(),
      'spreadId': spreadId,
      'spreadNameZh': spreadNameZh,
      'question': question,
      'cards': cards.map((c) => c.toJson()).toList(),
      'aiReading': aiReading?.toJson(),
    };
  }
}
