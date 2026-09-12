import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../data/ziwei_palace_meta.dart';
import '../data/ziwei_service.dart';
import '../models/ziwei_chart.dart';
import '../widgets/background_texture.dart';
import '../widgets/responsive_app_shell.dart';
import 'ziwei_reading_screen.dart';

/// 紫微斗数命盘可视化页——传统的十二宫格布局：外圈固定 12 格按地支
/// （巳午未申/酉戌/亥子丑寅/卯辰，从左上角顺时针）排布，中间 2x2 区域
/// 放命主的基本信息。具体哪个宫位名称落在哪个地支格子，因人而异，靠
/// [ZiweiPalace.earthlyBranch] 去查——地支的格子位置本身是固定的。
///
/// 跟其他页面一样套固定 414x896 画布 + FittedBox 整体缩放。
class ZiweiChartScreen extends StatefulWidget {
  const ZiweiChartScreen({
    super.key,
    required this.birthDate,
    required this.timeIndex,
    required this.gender,
    this.question,
  });

  final DateTime birthDate;
  final int timeIndex;
  final String gender;
  final String? question;

  @override
  State<ZiweiChartScreen> createState() => _ZiweiChartScreenState();
}

/// 地支 → 命盘固定格子的 (行, 列)，4x4 网格，从左上角顺时针排布，
/// 这是紫微斗数命盘的传统固定布局，不随命主变化。
const Map<String, (int, int)> kBranchGridPosition = {
  '巳': (0, 0), '午': (0, 1), '未': (0, 2), '申': (0, 3),
  '辰': (1, 0), '酉': (1, 3),
  '卯': (2, 0), '戌': (2, 3),
  '寅': (3, 0), '丑': (3, 1), '子': (3, 2), '亥': (3, 3),
};

class _ZiweiChartScreenState extends State<ZiweiChartScreen> {
  static const _service = ZiweiService();
  late final Future<ZiweiChart> _chartFuture;

  @override
  void initState() {
    super.initState();
    _chartFuture = _service.fetchChart(
      birthDate: widget.birthDate,
      timeIndex: widget.timeIndex,
      gender: widget.gender,
    );
  }

  static const double _designWidth = 414;
  static const double _designHeight = 896;
  static const double _cardRadius = 24;

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
                                '我的命盘',
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
                      Expanded(
                        child: FutureBuilder<ZiweiChart>(
                          future: _chartFuture,
                          builder: (context, snapshot) {
                            if (snapshot.connectionState !=
                                ConnectionState.done) {
                              return const Center(
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                ),
                              );
                            }
                            if (snapshot.hasError) {
                              return Center(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 32,
                                  ),
                                  child: Text(
                                    '排盘失败：${snapshot.error}',
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.inter(
                                      color: Colors.redAccent,
                                    ),
                                  ),
                                ),
                              );
                            }
                            final chart = snapshot.data!;
                            return _ChartBody(
                              chart: chart,
                              onAiReading: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (context) => ZiweiReadingScreen(
                                      birthDate: widget.birthDate,
                                      timeIndex: widget.timeIndex,
                                      gender: widget.gender,
                                      question: widget.question,
                                    ),
                                  ),
                                );
                              },
                            );
                          },
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

class _ChartBody extends StatelessWidget {
  const _ChartBody({required this.chart, required this.onAiReading});

  final ZiweiChart chart;
  final VoidCallback onAiReading;

  static const double _cellSize = 88;
  static const double _gridSize = _cellSize * 4;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Column(
        children: [
          SizedBox(
            width: _gridSize,
            height: _gridSize,
            child: Stack(
              children: [
                for (final palace in chart.palaces)
                  if (kBranchGridPosition[palace.earthlyBranch] != null)
                    Builder(
                      builder: (context) {
                        final (row, col) =
                            kBranchGridPosition[palace.earthlyBranch]!;
                        return Positioned(
                          left: col * _cellSize,
                          top: row * _cellSize,
                          width: _cellSize,
                          height: _cellSize,
                          child: _PalaceCell(palace: palace),
                        );
                      },
                    ),
                Positioned(
                  left: _cellSize,
                  top: _cellSize,
                  width: _cellSize * 2,
                  height: _cellSize * 2,
                  child: _CenterInfo(chart: chart),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _CurrentHoroscopeCard(chart: chart),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(85),
                ),
              ),
              onPressed: onAiReading,
              icon: const Icon(Icons.auto_awesome),
              label: Text('AI 深度解读', style: GoogleFonts.inter(fontSize: 16)),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _PalaceCell extends StatelessWidget {
  const _PalaceCell({required this.palace});

  final ZiweiPalace palace;

  void _showDetail(BuildContext context) {
    final meta = lookupZiweiPalaceMeta(palace.name);
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF1A1A1F),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (meta != null) ...[
                      Text(meta.emoji, style: const TextStyle(fontSize: 22)),
                      const SizedBox(width: 10),
                    ],
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                meta != null
                                    ? '${meta.englishLabel} · ${meta.displayName}'
                                    : palace.name,
                                style: GoogleFonts.playfairDisplay(
                                  fontSize: 19,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '（${palace.heavenlyStem}${palace.earthlyBranch}）',
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  color: Colors.white54,
                                ),
                              ),
                            ],
                          ),
                          if (meta != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              meta.description,
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontStyle: FontStyle.italic,
                                color: Colors.white.withValues(alpha: 0.5),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
                if (palace.isBodyPalace || palace.isOriginalPalace) ...[
                  const SizedBox(height: 6),
                  Text(
                    [
                      if (palace.isBodyPalace) '身宫',
                      if (palace.isOriginalPalace) '来因宫',
                    ].join(' · '),
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: Colors.amber.shade200,
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                if (palace.majorStars.isNotEmpty) ...[
                  Text(
                    '主星',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: Colors.white38,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final star in palace.majorStars)
                        _StarChip(star: star),
                    ],
                  ),
                  const SizedBox(height: 12),
                ],
                if (palace.minorStars.isNotEmpty) ...[
                  Text(
                    '辅星',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: Colors.white38,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final star in palace.minorStars)
                        _StarChip(star: star),
                    ],
                  ),
                ],
                if (palace.decadalRange != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    '大限：${palace.decadalRange![0]} - ${palace.decadalRange![1]} 岁',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: Colors.white54,
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final starNames = palace.majorStars.map((s) => s.name).join('');
    return InkWell(
      onTap: () => _showDetail(context),
      child: Container(
        margin: const EdgeInsets.all(2),
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
          borderRadius: BorderRadius.circular(8),
          color: palace.isBodyPalace
              ? Colors.amber.withValues(alpha: 0.08)
              : Colors.white.withValues(alpha: 0.03),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              palace.name,
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            const Spacer(),
            if (starNames.isNotEmpty)
              Text(
                starNames,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(fontSize: 9, color: Colors.white60),
              ),
            Text(
              palace.earthlyBranch,
              style: GoogleFonts.inter(fontSize: 9, color: Colors.white24),
            ),
          ],
        ),
      ),
    );
  }
}

class _StarChip extends StatelessWidget {
  const _StarChip({required this.star});

  final ZiweiStar star;

  @override
  Widget build(BuildContext context) {
    final label = [
      star.name,
      if (star.brightness != null && star.brightness!.isNotEmpty)
        star.brightness,
      if (star.mutagen != null && star.mutagen!.isNotEmpty)
        '化${star.mutagen}',
    ].join(' ');
    return Chip(
      label: Text(label),
      labelStyle: GoogleFonts.inter(fontSize: 12, color: Colors.white),
      backgroundColor: Colors.white.withValues(alpha: 0.1),
      side: BorderSide.none,
    );
  }
}

class _CenterInfo extends StatelessWidget {
  const _CenterInfo({required this.chart});

  final ZiweiChart chart;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(2),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            chart.fiveElementsClass,
            style: GoogleFonts.playfairDisplay(
              fontSize: 15,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '命主 ${chart.soul}　身主 ${chart.body}',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(fontSize: 10, color: Colors.white60),
          ),
          const SizedBox(height: 4),
          Text(
            '${chart.zodiac}座'.replaceFirst('座座', '座'),
            style: GoogleFonts.inter(fontSize: 10, color: Colors.white38),
          ),
          Text(
            chart.sign,
            style: GoogleFonts.inter(fontSize: 10, color: Colors.white38),
          ),
          const SizedBox(height: 4),
          Text(
            chart.lunarDate,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(fontSize: 9, color: Colors.white24),
          ),
        ],
      ),
    );
  }
}

class _CurrentHoroscopeCard extends StatelessWidget {
  const _CurrentHoroscopeCard({required this.chart});

  final ZiweiChart chart;

  @override
  Widget build(BuildContext context) {
    final h = chart.horoscope;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '当前运势',
            style: GoogleFonts.inter(
              fontSize: 13,
              color: Colors.white38,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '虚岁 ${h.nominalAge} 岁　大限 ${h.decadalStem}${h.decadalBranch}　流年 ${h.yearlyStem}${h.yearlyBranch}',
            style: GoogleFonts.inter(fontSize: 14, color: Colors.white70),
          ),
        ],
      ),
    );
  }
}
