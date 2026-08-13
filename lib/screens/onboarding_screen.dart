import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../widgets/background_texture.dart';
import '../widgets/decorative_image.dart';
import 'set_intention_screen.dart';

/// Onboarding 页面 —— 还原自 Figma node 254:1 ("onboarding")
///
/// 使用前请确认：
/// 1. 已把设计里用到的图片/矢量图导出并放进 assets/images/
///    （原设计用了 6 个资源：background texture、两个装饰性 vector、
///    intersect 图形、一个小 line 装饰、一个 group 装饰。图片缺失时
///    下面的 errorBuilder 会让它们静默不显示，而不是让整页崩溃）
/// 2. [_OnboardingMetrics.designWidth]/[designHeight] 已核对为 Figma 上
///    onboarding frame（254:1）的真实尺寸 414x896
/// 3. 文字内容目前是占位的中文翻译，替换成你要的最终文案即可
class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: ClipRRect(
        borderRadius: BorderRadius.circular(_OnboardingMetrics.cardRadius),
        child: FittedBox(
          fit: BoxFit.contain,
          clipBehavior: Clip.hardEdge,
          child: SizedBox(
            width: _OnboardingMetrics.designWidth,
            height: _OnboardingMetrics.designHeight,
            child: const _OnboardingStack(),
          ),
        ),
      ),
    );
  }
}

/// Figma 设计画布上的固定尺寸/坐标，整体通过 [FittedBox] 等比缩放到实际屏幕。
class _OnboardingMetrics {
  const _OnboardingMetrics._();

  static const double designWidth = 414;
  static const double designHeight = 896;

  static const double cardRadius = 24;
  static const double horizontalPadding = 44;
  static const double bottomFadeHeight = 127;
  static const double buttonBottomSpace = 60;

  static const swirl1 = DecorationSpec(
    asset: 'assets/images/vector_swirl_1.png',
    left: -336,
    top: 240,
    width: 1125,
    height: 488,
    rotationDegrees: -32.01,
  );

  static const swirl2 = DecorationSpec(
    asset: 'assets/images/vector_swirl_2.png',
    left: -510,
    top: 415,
    width: 975,
    height: 574,
  );

  static const intersect = DecorationSpec(
    asset: 'assets/images/intersect_shape.png',
    left: -23,
    top: -412,
    width: 830,
    height: 828,
  );
}

class _OnboardingStack extends StatelessWidget {
  const _OnboardingStack();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        const BackgroundTexture(),
        const DecorativeImage(spec: _OnboardingMetrics.swirl1),
        const DecorativeImage(spec: _OnboardingMetrics.swirl2),
        const DecorativeImage(spec: _OnboardingMetrics.intersect),
        const _OnboardingCopy(),
        const _BottomFadeMask(),
      ],
    );
  }
}

class _OnboardingCopy extends StatelessWidget {
  const _OnboardingCopy();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: _OnboardingMetrics.horizontalPadding,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          // 主标题 —— 原文 "Гадай" (占卜)
          Text(
            '占卜',
            style: GoogleFonts.playfairDisplay(
              fontSize: 64,
              height: 0.975,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          // 副标题 —— 原文 "и сохраняй" (与保存)
          Text(
            '与记录',
            style: GoogleFonts.playfairDisplay(
              fontSize: 24,
              height: 0.975,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 24),
          // 正文 —— 原文描述用法
          Text(
            '向塔罗提问，无论是实体牌还是在 App 里。\n保存你的牌阵，比较、分析每一次占卜。',
            style: GoogleFonts.inter(
              fontSize: 18,
              height: 1.19,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 24),
          _StartButton(),
          const SizedBox(height: _OnboardingMetrics.buttonBottomSpace),
        ],
      ),
    );
  }
}

/// 开始按钮 —— 放在设计稿底部预留的空间里（原来是临时的 FloatingActionButton，
/// 浮在内容上方跟设计对不上；现在改成正常摆在页面布局里的按钮）。
class _StartButton extends StatelessWidget {
  const _StartButton();

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(85),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => const SetIntentionScreen()),
          );
        },
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
            padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 14),
            child: Text(
              '开始占卜',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(fontSize: 16, color: Colors.black),
            ),
          ),
        ),
      ),
    );
  }
}

/// 底部渐变遮罩（黑色到透明），让文字在背景纹理上更清晰。
class _BottomFadeMask extends StatelessWidget {
  const _BottomFadeMask();

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      // 纯视觉遮罩，不能拦截点击——不然会挡住下面的"开始占卜"按钮。
      // Container 只要有 decoration，默认会整块吃掉点击事件，
      // 即使渐变看起来是透明的也一样。
      child: IgnorePointer(
        child: Container(
          height: _OnboardingMetrics.bottomFadeHeight,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
              colors: [Colors.black, Colors.transparent],
            ),
          ),
        ),
      ),
    );
  }
}
