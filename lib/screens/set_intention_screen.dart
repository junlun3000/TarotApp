import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../widgets/background_texture.dart';
import '../widgets/decorative_image.dart';
import 'spread_selection_screen.dart';

/// "冥想引导"页 —— 还原自 Figma node 464:277。
///
/// 这是抽牌正式流程里、抽牌前的一个静心提醒停顿页：提醒用户清空思绪、
/// 洗牌，然后进入"选择牌阵"。
///
/// 具体想问什么、背景近况这些不再在这里收集——改成选好牌阵之后，由
/// [SpreadIntakeScreen] 针对这个牌阵问几个更有针对性的问题（见该文件的
/// 说明），比这里一个通用的"想问什么"输入框更容易问出有用的信息。
class SetIntentionScreen extends StatelessWidget {
  const SetIntentionScreen({super.key});

  void _goToSpreadSelection(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const SpreadSelectionScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: ClipRRect(
        borderRadius: BorderRadius.circular(_SetIntentionMetrics.cardRadius),
        child: FittedBox(
          fit: BoxFit.contain,
          clipBehavior: Clip.hardEdge,
          child: SizedBox(
            width: _SetIntentionMetrics.designWidth,
            height: _SetIntentionMetrics.designHeight,
            child: Stack(
              children: [
                const BackgroundTexture(),
                const DecorativeImage(spec: _SetIntentionMetrics.swirl1),
                const DecorativeImage(spec: _SetIntentionMetrics.swirl2),
                const _BackButton(),
                const _Title(),
                const _Body(),
                _StartButton(onTap: () => _goToSpreadSelection(context)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SetIntentionMetrics {
  const _SetIntentionMetrics._();

  static const double designWidth = 414;
  static const double designHeight = 896;
  static const double cardRadius = 24;

  static const double titleTop = 221;

  static const double bodyLeft = 24;
  static const double bodyTop = 332;
  static const double bodyWidth = 365;

  static const double buttonTop = 470;

  static const double backButtonLeft = 14;
  static const double backButtonTop = 78;

  static const swirl1 = DecorationSpec(
    asset: 'assets/images/vector_swirl_1.png',
    left: -101,
    top: -151,
    width: 817,
    height: 795,
    rotationDegrees: -41.56,
  );

  static const swirl2 = DecorationSpec(
    asset: 'assets/images/vector_swirl_2.png',
    left: -229,
    top: 295,
    width: 611,
    height: 782,
    rotationDegrees: 77.08,
  );
}

class _BackButton extends StatelessWidget {
  const _BackButton();

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: _SetIntentionMetrics.backButtonLeft,
      top: _SetIntentionMetrics.backButtonTop,
      child: IconButton(
        onPressed: () => Navigator.of(context).maybePop(),
        icon: const Icon(Icons.arrow_back, color: Colors.white),
      ),
    );
  }
}

class _Title extends StatelessWidget {
  const _Title();

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 0,
      right: 0,
      top: _SetIntentionMetrics.titleTop,
      child: Text(
        '静心片刻',
        textAlign: TextAlign.center,
        style: GoogleFonts.playfairDisplay(
          fontSize: 30,
          height: 1.35,
          color: Colors.white,
          shadows: const [Shadow(color: Colors.white, blurRadius: 14)],
        ),
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body();

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: _SetIntentionMetrics.bodyLeft,
      top: _SetIntentionMetrics.bodyTop,
      width: _SetIntentionMetrics.bodyWidth,
      child: Text(
        '在读牌之前，先清空思绪——一段简短的冥想会有帮助。'
        '如果你在使用实体牌，现在正是洗牌、静心的好时机。'
        '选好牌阵之后，我们会再问你几个跟这个牌阵相关的小问题。',
        textAlign: TextAlign.center,
        style: GoogleFonts.inter(
          fontSize: 16,
          height: 1.3,
          color: Colors.white.withValues(alpha: 0.6),
        ),
      ),
    );
  }
}

class _StartButton extends StatelessWidget {
  const _StartButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 0,
      right: 0,
      top: _SetIntentionMetrics.buttonTop,
      child: Center(
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(85),
            onTap: onTap,
            child: Ink(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(85),
                boxShadow: [
                  BoxShadow(
                    color: Colors.white.withValues(alpha: 0.8),
                    blurRadius: 7,
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 30,
                  vertical: 10,
                ),
                child: Text(
                  '开始',
                  style: GoogleFonts.inter(fontSize: 18, color: Colors.black),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
