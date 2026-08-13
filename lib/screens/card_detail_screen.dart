import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/drawn_card.dart';
import '../models/tarot_card.dart';
import '../widgets/background_texture.dart';
import '../widgets/card_flip_reveal.dart';
import '../widgets/decorative_image.dart';

/// 单张牌的详情页 —— 视觉框架参考 Figma node 241:112（"恋人"牌详情页）。
///
/// 原设计里卡图上叠了可点击的符号学解读圆点 + 底部横向轮播，那部分内容我们
/// 现在没有（需要 78 张牌 x 每张牌若干符号的手工解读内容，且需要真实牌面
/// 扫描图），先不做。这版保留了原设计的整体视觉框架（黑底、返回箭头、
/// 牌名标题、圆角卡图），下半区换成我们已有的数据：关键词 + 正逆位含义
/// + 一个正逆位切换按钮（对应原设计里其他变体页面的"перевернуть"翻转按钮）。
///
/// 跟其他页面一样套固定 414x896 画布 + FittedBox 整体缩放，保持全 App
/// 页面尺寸/比例一致；牌义文字长度随牌不同会变化，靠画布内部的
/// [SingleChildScrollView] 处理，不会影响外层画布尺寸。
class CardDetailScreen extends StatefulWidget {
  const CardDetailScreen({
    super.key,
    required this.card,
    this.initialOrientation = CardOrientation.upright,
  });

  final TarotCard card;
  final CardOrientation initialOrientation;

  @override
  State<CardDetailScreen> createState() => _CardDetailScreenState();
}

class _CardDetailScreenState extends State<CardDetailScreen> {
  late CardOrientation _orientation;

  @override
  void initState() {
    super.initState();
    _orientation = widget.initialOrientation;
  }

  bool get _isReversed => _orientation == CardOrientation.reversed;

  void _toggleOrientation() {
    setState(() {
      _orientation = _isReversed
          ? CardOrientation.upright
          : CardOrientation.reversed;
    });
  }

  static const double _designWidth = 414;
  static const double _designHeight = 896;
  static const double _cardRadius = 24;

  // 星芒背景装饰——复用项目里已有的 intersect_shape.png（跟 onboarding 页
  // 用的是同一张图），大致居中罩在卡图所在的区域，营造发光氛围感。
  // 固定在画布背景层，不随 SingleChildScrollView 滚动。
  static const _starDeco = DecorationSpec(
    asset: 'assets/images/intersect_shape.png',
    left: -143,
    top: 20,
    width: 700,
    height: 700,
  );

  @override
  Widget build(BuildContext context) {
    final card = widget.card;
    final meaning = _isReversed ? card.reversedMeaning : card.uprightMeaning;

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
                const DecorativeImage(spec: _starDeco),
                SafeArea(
                  child: Column(
                    children: [
                      _Header(title: card.nameZh),
                      const SizedBox(height: 16),
                      Expanded(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.symmetric(horizontal: 32),
                          child: Column(
                            children: [
                              _CardImage(
                                imagePath: card.imagePath,
                                isReversed: _isReversed,
                              ),
                              const SizedBox(height: 16),
                              _OrientationToggle(
                                isReversed: _isReversed,
                                onTap: _toggleOrientation,
                              ),
                              const SizedBox(height: 20),
                              _KeywordChips(keywords: card.keywords),
                              const SizedBox(height: 20),
                              Align(
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  _isReversed ? '逆位含义' : '正位含义',
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    color: Colors.white54,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                meaning,
                                style: GoogleFonts.inter(
                                  fontSize: 15,
                                  height: 1.5,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 32),
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

class _Header extends StatelessWidget {
  const _Header({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: SizedBox(
        height: 44,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: IconButton(
                onPressed: () => Navigator.of(context).maybePop(),
                icon: const Icon(Icons.arrow_back, color: Colors.white),
              ),
            ),
            Text(
              title,
              style: GoogleFonts.playfairDisplay(
                fontSize: 18,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CardImage extends StatelessWidget {
  const _CardImage({required this.imagePath, required this.isReversed});

  final String imagePath;
  final bool isReversed;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 317.7 / 568.6,
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(17),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(17),
          child: CardFlipReveal(
            frontImagePath: imagePath,
            isReversed: isReversed,
            startDelay: const Duration(milliseconds: 300),
            flipDuration: const Duration(milliseconds: 900),
          ),
        ),
      ),
    );
  }
}

class _OrientationToggle extends StatelessWidget {
  const _OrientationToggle({required this.isReversed, required this.onTap});

  final bool isReversed;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.white,
        side: const BorderSide(color: Colors.white30),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
      icon: const Icon(Icons.sync, size: 18),
      label: Text(isReversed ? '逆位（点击切换正位）' : '正位（点击切换逆位）'),
    );
  }
}

class _KeywordChips extends StatelessWidget {
  const _KeywordChips({required this.keywords});

  final List<String> keywords;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final keyword in keywords)
          Chip(
            label: Text(keyword),
            labelStyle: GoogleFonts.inter(fontSize: 12, color: Colors.white),
            backgroundColor: Colors.white.withValues(alpha: 0.1),
            side: BorderSide.none,
          ),
      ],
    );
  }
}
