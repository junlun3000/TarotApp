import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/ai_reading.dart';
import '../models/drawn_card.dart';
import '../models/reading_history_entry.dart';
import '../models/spread_preset.dart';
import '../models/tarot_card.dart';
import '../widgets/background_texture.dart';
import '../widgets/responsive_app_shell.dart';
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
                  minimum: EdgeInsets.only(
                    top: ResponsiveAppShell.topCropInset(context),
                  ),
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
                          child: Column(
                            children: [
                              SizedBox(
                                width: (maxCol + 1) * step - _cellSpacing,
                                height: (maxRow + 1) * stepV - _cellSpacing,
                                child: Stack(
                                  children: [
                                    for (final (
                                      index,
                                      position,
                                    ) in layout.indexed)
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
                              if (entry.aiReading != null) ...[
                                const SizedBox(height: 24),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 24,
                                  ),
                                  child: _HistoryReadingBody(
                                    reading: entry.aiReading!,
                                  ),
                                ),
                              ],
                            ],
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

/// 历史记录里保存的 AI 解读——排版思路跟 [AiReadingScreen] 的解读正文
/// 是同一套（半透明白底卡片），保持视觉一致，让用户觉得是"翻回去看同一
/// 份解读"，而不是另一种展示形式。
class _HistoryReadingBody extends StatelessWidget {
  const _HistoryReadingBody({required this.reading});

  final AiReading reading;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (reading.overview.isNotEmpty) ...[
          _HistoryReadingCard(
            icon: Icons.auto_awesome,
            child: Text(
              reading.overview,
              style: GoogleFonts.inter(
                fontSize: 15,
                height: 1.7,
                fontStyle: FontStyle.italic,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
        for (final card in reading.cards)
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: _HistoryReadingCard(
              icon: Icons.stars_outlined,
              title: card.cardNameZh.isEmpty
                  ? card.positionLabel
                  : '${card.positionLabel}：${card.cardNameZh}',
              child: Text(
                card.interpretation,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  height: 1.6,
                  color: Colors.white.withValues(alpha: 0.85),
                ),
              ),
            ),
          ),
        if (reading.advice.isNotEmpty)
          _HistoryReadingCard(
            icon: Icons.tips_and_updates_outlined,
            title: '给你的建议',
            child: Text(
              reading.advice,
              style: GoogleFonts.inter(
                fontSize: 15,
                height: 1.7,
                color: Colors.white,
              ),
            ),
          ),
      ],
    );
  }
}

class _HistoryReadingCard extends StatelessWidget {
  const _HistoryReadingCard({required this.icon, this.title, required this.child});

  final IconData icon;
  final String? title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.white.withValues(alpha: 0.15),
            blurRadius: 20,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: Colors.white70, size: 18),
              if (title != null) ...[
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title!,
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 15,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
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
