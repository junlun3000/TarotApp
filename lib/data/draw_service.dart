import 'dart:math';

import '../models/drawn_card.dart';
import '../models/tarot_card.dart';
import '../models/tarot_spread.dart';

/// 核心抽牌逻辑：不放回随机抽取 + 正逆位判定，支持任意张数的牌阵。
class DrawService {
  DrawService({Random? random}) : _random = random ?? Random();

  final Random _random;

  /// 从 [deck] 中为 [spread] 抽出对应数量的牌，每张牌不会重复，
  /// 并按 [reversalProbability] 的概率判定为逆位（默认 50%）。
  List<DrawnCard> draw({
    required List<TarotCard> deck,
    required TarotSpread spread,
    bool allowReversed = true,
    double reversalProbability = 0.5,
  }) {
    if (spread.cardCount > deck.length) {
      throw ArgumentError(
        '牌阵「${spread.nameZh}」需要 ${spread.cardCount} 张牌，但牌堆只有 ${deck.length} 张。',
      );
    }

    final shuffled = List<TarotCard>.from(deck)..shuffle(_random);
    final selected = shuffled.take(spread.cardCount).toList(growable: false);

    return List.generate(selected.length, (index) {
      final isReversed =
          allowReversed && _random.nextDouble() < reversalProbability;
      return DrawnCard(
        card: selected[index],
        orientation: isReversed
            ? CardOrientation.reversed
            : CardOrientation.upright,
        positionLabel: spread.positionLabels[index],
      );
    }, growable: false);
  }
}
