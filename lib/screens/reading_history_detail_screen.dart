import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/drawn_card.dart';
import '../models/reading_history_entry.dart';
import '../models/spread_preset.dart';
import '../models/tarot_card.dart';
import '../widgets/background_texture.dart';
import 'card_detail_screen.dart';

/// 回看一条历史记录里具体抽到的牌 —— 按牌阵实际布局摆放，
/// 卡面直接显示（已经是"过去"的记录，不需要再播一次翻牌动画）。
class ReadingHistoryDetailScreen extends StatelessWidget {
  const ReadingHistoryDetailScreen({
    super.key,
    required this.entry,
    required this.cardsById,
  });

  final ReadingHistoryEntry entry;
  final Map<String, TarotCard> cardsById;

  static const double _designWidth = 414;
  static const double _designHeight = 896;
  static const double _cardRadius = 24;
  static const double _cellWidth = 64;
  static const double _cellHeight = 64 * 1.4;
  static const double _cellSpacing = 12;

  List<GridPosition> get _layout {
    final matches = SpreadPreset.all.where(
      (p) => p.spread.id == entry.spreadId,
    );
    if (matches.isEmpty) {
      return [for (var i = 0; i < entry.cards.length; i++) GridPosition(0, i)];
    }
    return matches.first.previewLayout;
  }

  @override
  Widget build(BuildContext context) {
    final layout = _layout;
    final maxRow = layout.map((p) => p.row).reduce((a, b) => a > b ? a : b);
    final maxCol = layout.map((p) => p.col).reduce((a, b) => a > b ? a : b);
    final step = _cellWidth + _cellSpacing;
    final stepV = _cellHeight + _cellSpacing;

    return Scaffold(
      backgroundColor: Colors.black,
      body: ClipRRect(
        borderRadius: BorderRadius.circular(_cardRadius),
        child: FittedBox(
          fit: BoxFit.contain,
          clipBehavior: Clip.hardEdge,
          child: SizedBox(
            width: _designWidth,
            height: _designHeight,
            child: Stack(
              children: [
                const BackgroundTexture(),
                SafeArea(
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Row(
                          children: [
                            IconButton(
                              onPressed: () => Navigator.of(context).maybePop(),
                              icon: const Icon(
                                Icons.arrow_back,
                                color: Colors.white,
                              ),
                            ),
                            Expanded(
                              child: Text(
                                entry.spreadNameZh,
                                textAlign: TextAlign.center,
                                style: GoogleFonts.playfairDisplay(
                                  fontSize: 18,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            const SizedBox(width: 48),
                          ],
                        ),
                      ),
                      if (entry.question != null)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 32),
                          child: Text(
                            entry.question!,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              color: Colors.white70,
                            ),
                          ),
                        ),
                      const SizedBox(height: 16),
                      Expanded(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          child: SizedBox(
                            width: (maxCol + 1) * step - _cellSpacing,
                            height: (maxRow + 1) * stepV - _cellSpacing,
                            child: Stack(
                              children: [
                                for (final (index, position) in layout.indexed)
                                  if (index < entry.cards.length)
                                    Positioned(
                                      left: position.col * step,
                                      top: position.row * stepV,
                                      child: _HistoryCardThumbnail(
                                        cardEntry: entry.cards[index],
                                        card:
                                            cardsById[entry
                                                .cards[index]
                                                .cardId],
                                      ),
                                    ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _HistoryCardThumbnail extends StatelessWidget {
  const _HistoryCardThumbnail({required this.cardEntry, required this.card});

  final HistoryCardEntry cardEntry;
  final TarotCard? card;

  @override
  Widget build(BuildContext context) {
    final card = this.card;
    return GestureDetector(
      onTap: card == null
          ? null
          : () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => CardDetailScreen(
                    card: card,
                    initialOrientation: cardEntry.orientation,
                  ),
                ),
              );
            },
      child: Container(
        width: 64,
        height: 64 * 1.4,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(6),
          boxShadow: [
            BoxShadow(
              color: Colors.white.withValues(alpha: 0.4),
              blurRadius: 10,
              spreadRadius: 1,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: card == null
              ? const SizedBox.shrink()
              : Transform.rotate(
                  angle: cardEntry.orientation == CardOrientation.reversed
                      ? 3.14159
                      : 0,
                  child: Image.asset(
                    card.imagePath,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      color: Colors.white10,
                      alignment: Alignment.center,
                      child: const Icon(
                        Icons.image_not_supported_outlined,
                        color: Colors.white24,
                        size: 20,
                      ),
                    ),
                  ),
                ),
        ),
      ),
    );
  }
}
