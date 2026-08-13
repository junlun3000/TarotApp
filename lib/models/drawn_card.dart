import 'tarot_card.dart';

enum CardOrientation { upright, reversed }

/// 一次抽牌的结果：具体是哪张牌、正位还是逆位、在牌阵中的位置。
class DrawnCard {
  const DrawnCard({
    required this.card,
    required this.orientation,
    this.positionLabel,
  });

  final TarotCard card;
  final CardOrientation orientation;

  /// 牌阵中的位置标签，例如"过去"/"现在"/"未来"；单张牌阵时为 null。
  final String? positionLabel;

  String get meaning => orientation == CardOrientation.upright
      ? card.uprightMeaning
      : card.reversedMeaning;

  bool get isReversed => orientation == CardOrientation.reversed;
}
