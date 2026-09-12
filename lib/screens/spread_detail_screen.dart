import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/spread_preset.dart';
import '../widgets/background_texture.dart';
import '../widgets/responsive_app_shell.dart';
import '../widgets/spread_preview_icon.dart';
import 'spread_intake_screen.dart';

/// 牌阵详情页 —— 参考 Figma 里"Путь"（路径）牌阵详情页的结构：
/// 编号牌位图 + 可能预测/典型问题/牌阵特点说明 + 底部"选择这个牌阵"按钮。
///
/// 两个底部按钮都先走 [SpreadIntakeScreen] 问几个针对这个牌阵的小问题，
/// 再进数字选牌/拍照扫描——具体问题/背景不再由"设置问题"页统一收集。
///
/// 跟其他页面一样套固定 414x896 画布 + FittedBox 整体缩放，保持全 App
/// 页面尺寸/比例一致。
class SpreadDetailScreen extends StatefulWidget {
  const SpreadDetailScreen({super.key, required this.preset});

  final SpreadPreset preset;

  @override
  State<SpreadDetailScreen> createState() => _SpreadDetailScreenState();
}

class _SpreadDetailScreenState extends State<SpreadDetailScreen> {
  static const double _designWidth = 414;
  static const double _designHeight = 896;
  static const double _cardRadius = 24;

  bool _isFavorite = false;

  @override
  Widget build(BuildContext context) {
    final preset = widget.preset;

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
                      _Header(
                        title: preset.nameZh,
                        isFavorite: _isFavorite,
                        onFavoriteToggle: () =>
                            setState(() => _isFavorite = !_isFavorite),
                      ),
                      const SizedBox(height: 24),
                      SpreadPreviewIcon(
                        layout: preset.previewLayout,
                        cellSize: 44,
                        showNumbers: true,
                      ),
                      const SizedBox(height: 24),
                      Expanded(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.06),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _Section(
                                  title: '牌位说明',
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      for (final (index, label)
                                          in preset
                                              .spread
                                              .positionLabels
                                              .indexed)
                                        Padding(
                                          padding: const EdgeInsets.only(
                                            bottom: 6,
                                          ),
                                          child: Text(
                                            '${index + 1}. $label',
                                            style: GoogleFonts.inter(
                                              fontSize: 14,
                                              height: 1.5,
                                              color: Colors.white70,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 20),
                                _Section(
                                  title: '可能预测',
                                  child: Text(
                                    preset.predictions,
                                    style: GoogleFonts.inter(
                                      fontSize: 14,
                                      height: 1.5,
                                      color: Colors.white70,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 20),
                                _Section(
                                  title: '典型问题',
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      for (final question
                                          in preset.typicalQuestions)
                                        Padding(
                                          padding: const EdgeInsets.only(
                                            bottom: 6,
                                          ),
                                          child: Text(
                                            '· $question',
                                            style: GoogleFonts.inter(
                                              fontSize: 14,
                                              height: 1.5,
                                              color: Colors.white70,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 20),
                                _Section(
                                  title: '牌阵特点',
                                  child: Text(
                                    preset.features,
                                    style: GoogleFonts.inter(
                                      fontSize: 14,
                                      height: 1.5,
                                      color: Colors.white70,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
                        child: Column(
                          children: [
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  foregroundColor: Colors.black,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 14,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(85),
                                  ),
                                ),
                                onPressed: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (context) => SpreadIntakeScreen(
                                        preset: preset,
                                        mode: SpreadIntakeMode.select,
                                      ),
                                    ),
                                  );
                                },
                                child: Text(
                                  '选择这个牌阵',
                                  style: GoogleFonts.inter(fontSize: 16),
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.white,
                                  side: const BorderSide(
                                    color: Colors.white30,
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 14,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(85),
                                  ),
                                ),
                                onPressed: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (context) => SpreadIntakeScreen(
                                        preset: preset,
                                        mode: SpreadIntakeMode.scan,
                                      ),
                                    ),
                                  );
                                },
                                icon: const Icon(
                                  Icons.camera_alt_outlined,
                                  size: 18,
                                ),
                                label: Text(
                                  '拍照扫描我的实体牌',
                                  style: GoogleFonts.inter(fontSize: 15),
                                ),
                              ),
                            ),
                          ],
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

class _Header extends StatelessWidget {
  const _Header({
    required this.title,
    required this.isFavorite,
    required this.onFavoriteToggle,
  });

  final String title;
  final bool isFavorite;
  final VoidCallback onFavoriteToggle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.of(context).maybePop(),
            icon: const Icon(Icons.arrow_back, color: Colors.white),
          ),
          Expanded(
            child: Text(
              title,
              textAlign: TextAlign.center,
              style: GoogleFonts.playfairDisplay(
                fontSize: 18,
                color: Colors.white,
              ),
            ),
          ),
          IconButton(
            onPressed: onFavoriteToggle,
            icon: Icon(
              isFavorite ? Icons.favorite : Icons.favorite_border,
              color: isFavorite ? Colors.redAccent : Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.inter(
            fontSize: 13,
            color: Colors.white38,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        child,
      ],
    );
  }
}
