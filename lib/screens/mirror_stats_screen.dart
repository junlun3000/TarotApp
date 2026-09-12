import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../data/reading_history_repository.dart';
import '../data/tarot_card_repository.dart';
import '../models/reading_history_entry.dart';
import '../models/tarot_card.dart';
import '../widgets/app_bottom_nav_bar.dart';
import '../widgets/background_texture.dart';
import '../widgets/responsive_app_shell.dart';
import 'reading_history_screen.dart';

/// "镜子"统计分析页 —— 还原自 Figma 里的 "Зеркало"。
///
/// 汇总所有历史抽牌记录：大阿尔卡那/四个花色的占比环形图、一段根据占比
/// 自动生成的解读文字，以及抽到次数最多的几张具体牌的频率条 + 对应解读。
/// 之前做的"阅读日记"（完整历史列表）挪到这页右上角的书签图标里。
class MirrorStatsScreen extends StatefulWidget {
  const MirrorStatsScreen({super.key});

  @override
  State<MirrorStatsScreen> createState() => _MirrorStatsScreenState();
}

class _MirrorStatsScreenState extends State<MirrorStatsScreen> {
  static const double _designWidth = 414;
  static const double _designHeight = 896;
  static const double _cardRadius = 24;

  static const _cardRepository = TarotCardRepository();

  late final Future<List<TarotCard>> _deckFuture;

  @override
  void initState() {
    super.initState();
    _deckFuture = _cardRepository.loadDeck();
  }

  @override
  Widget build(BuildContext context) {
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
                  child: FutureBuilder<List<TarotCard>>(
                    future: _deckFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState != ConnectionState.done) {
                        return const Center(
                          child: CircularProgressIndicator(color: Colors.white),
                        );
                      }
                      final cardsById = {
                        for (final card in snapshot.data!) card.id: card,
                      };
                      final entries = ReadingHistoryRepository.instance
                          .getAllEntries();
                      final stats = _MirrorStats.compute(entries, cardsById);
                      return _StatsBody(stats: stats);
                    },
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

class _StatsBody extends StatelessWidget {
  const _StatsBody({required this.stats});

  final _MirrorStats stats;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            children: [
              const SizedBox(width: 48),
              Expanded(
                child: Text(
                  '镜子',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 18,
                    color: Colors.white,
                  ),
                ),
              ),
              IconButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const ReadingHistoryScreen(),
                    ),
                  );
                },
                icon: const Icon(Icons.bookmark_border, color: Colors.white),
              ),
            ],
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: Column(
              children: [
                Text(
                  '总体牌组',
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 22,
                    color: Colors.white,
                  ),
                ),
                Text(
                  '塔罗花色分布',
                  style: GoogleFonts.inter(fontSize: 12, color: Colors.white54),
                ),
                const SizedBox(height: 16),
                _SuitRing(percentages: stats.categoryPercentages),
                const SizedBox(height: 16),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final entry in stats.categoryPercentages.entries)
                      Chip(
                        label: Text(
                          '${(entry.value * 100).round()}% ${entry.key}',
                        ),
                        labelStyle: GoogleFonts.inter(
                          fontSize: 12,
                          color: Colors.white,
                        ),
                        backgroundColor: Colors.white.withValues(alpha: 0.08),
                        side: BorderSide.none,
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                _InsightBox(text: stats.insightText),
                if (stats.topCards.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  Column(
                    children: [
                      for (final freq in stats.topCards)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _FrequencyBar(
                            label: freq.card.nameZh,
                            fraction: stats.topCards.first.count == 0
                                ? 0
                                : freq.count / stats.topCards.first.count,
                          ),
                        ),
                    ],
                  ),
                ],
                if (stats.topCardInsightText != null) ...[
                  const SizedBox(height: 8),
                  _InsightBox(text: stats.topCardInsightText!),
                ],
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
        const AppBottomNavBar(currentIndex: 0),
      ],
    );
  }
}

class _InsightBox extends StatelessWidget {
  const _InsightBox({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        text,
        style: GoogleFonts.inter(
          fontSize: 13,
          height: 1.5,
          color: Colors.white70,
        ),
      ),
    );
  }
}

class _FrequencyBar extends StatelessWidget {
  const _FrequencyBar({required this.label, required this.fraction});

  final String label;
  final double fraction;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          flex: 3,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: fraction.clamp(0.05, 1.0),
              minHeight: 8,
              backgroundColor: Colors.white10,
              valueColor: const AlwaysStoppedAnimation(Colors.white),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 2,
          child: Text(
            label,
            style: GoogleFonts.inter(fontSize: 12, color: Colors.white70),
          ),
        ),
      ],
    );
  }
}

class _SuitRing extends StatelessWidget {
  const _SuitRing({required this.percentages});

  final Map<String, double> percentages;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 160,
      height: 160,
      child: CustomPaint(painter: _RingPainter(percentages)),
    );
  }
}

class _RingPainter extends CustomPainter {
  const _RingPainter(this.percentages);

  final Map<String, double> percentages;

  static const _colors = {
    '大阿尔卡那': Colors.white,
    '权杖': Color(0xFF6B89FB),
    '圣杯': Color(0xFF9AD1D4),
    '宝剑': Color(0xFFE0A0A0),
    '星币': Color(0xFFD9C36A),
  };

  @override
  void paint(Canvas canvas, Size size) {
    final strokeWidth = size.width * 0.12;
    final radius = (size.width - strokeWidth) / 2;
    final center = size.center(Offset.zero);
    var startAngle = -math.pi / 2;

    for (final entry in percentages.entries) {
      if (entry.value <= 0) continue;
      final sweep = entry.value * 2 * math.pi;
      final paint = Paint()
        ..color = _colors[entry.key] ?? Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweep,
        false,
        paint,
      );
      startAngle += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant _RingPainter oldDelegate) => true;
}

class _CardFrequency {
  const _CardFrequency({required this.card, required this.count});

  final TarotCard card;
  final int count;
}

class _MirrorStats {
  const _MirrorStats({
    required this.categoryPercentages,
    required this.topCards,
    required this.insightText,
    required this.topCardInsightText,
  });

  final Map<String, double> categoryPercentages;
  final List<_CardFrequency> topCards;
  final String insightText;
  final String? topCardInsightText;

  static _MirrorStats compute(
    List<ReadingHistoryEntry> entries,
    Map<String, TarotCard> cardsById,
  ) {
    final categoryCounts = <String, int>{
      '大阿尔卡那': 0,
      '权杖': 0,
      '圣杯': 0,
      '宝剑': 0,
      '星币': 0,
    };
    final cardCounts = <String, int>{};
    var total = 0;

    for (final entry in entries) {
      for (final cardEntry in entry.cards) {
        final card = cardsById[cardEntry.cardId];
        if (card == null) continue;
        total++;
        cardCounts[cardEntry.cardId] = (cardCounts[cardEntry.cardId] ?? 0) + 1;

        final label = card.arcana == Arcana.major
            ? '大阿尔卡那'
            : switch (card.suit!) {
                Suit.wands => '权杖',
                Suit.cups => '圣杯',
                Suit.swords => '宝剑',
                Suit.pentacles => '星币',
              };
        categoryCounts[label] = categoryCounts[label]! + 1;
      }
    }

    final percentages = {
      for (final entry in categoryCounts.entries)
        entry.key: total == 0 ? 0.0 : entry.value / total,
    };

    final sortedCardCounts = cardCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final topCards = [
      for (final entry in sortedCardCounts.take(4))
        if (cardsById[entry.key] != null)
          _CardFrequency(card: cardsById[entry.key]!, count: entry.value),
    ];

    final String insight;
    if (total == 0) {
      insight = '还没有抽牌记录，多抽几次就能看到你的花色分布规律。';
    } else {
      final dominant = percentages.entries.reduce(
        (a, b) => a.value >= b.value ? a : b,
      );
      insight = switch (dominant.key) {
        '大阿尔卡那' => '最近抽到很多大阿尔卡那，这可能意味着你正在经历深刻的转变与人生重大转折。',
        '权杖' => '权杖占比较高，暗示你的能量集中在事业、创造力与行动力相关的课题上。',
        '圣杯' => '圣杯占比较高，暗示你的重心更多在情感、关系与内心世界。',
        '宝剑' => '宝剑占比较高，暗示你近期更多在处理思维、沟通与冲突相关的课题。',
        '星币' => '星币占比较高，暗示你近期更关注物质、金钱与现实层面的问题。',
        _ => '',
      };
    }

    String? topCardInsight;
    if (topCards.isNotEmpty) {
      final top = topCards.first;
      topCardInsight =
          '「${top.card.nameZh}」是你抽到次数最多的一张牌，反复出现的牌往往在提醒你注意：'
          '${top.card.uprightMeaning}';
    }

    return _MirrorStats(
      categoryPercentages: percentages,
      topCards: topCards,
      insightText: insight,
      topCardInsightText: topCardInsight,
    );
  }
}
