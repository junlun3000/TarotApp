import 'package:flutter/material.dart';

import 'background_texture.dart';

/// 包在整个 App 外面一层（挂在 [MaterialApp.builder]），不改动任何单个
/// 页面——每个页面自己内部还是"固定 414x896 画布 + FittedBox 整体缩放"
/// 那一套，这里只决定"给那块画布多大的地方去缩放"：
///
/// 判断标准不是"宽度是不是超过某个像素值"，而是**当前可用空间的宽高比
/// 是不是比设计稿（414:896）更"宽"**——只要更宽，内部那个
/// `FittedBox(fit: BoxFit.contain)` 就必然会在左右两侧留黑边（这是
/// contain 的本质：为了不裁切内容，只能在跟设计稿比例不一致的方向上
/// 留白）。这种情况不止发生在桌面宽屏浏览器，手机上的 Facebook/Messenger
/// 应用内置浏览器同理——它上下各有一条很高的工具栏，把实际可视区域挤成
/// 一个偏"宽"的长方形（比如 390x664，宽高比 0.59，远宽于设计稿的
/// 0.4621），即使是在手机上也会出现同样的黑边。
///
/// - 宽高比 在设计稿比例的容忍范围内（正常全屏手机浏览器，比如
///   390x844≈0.462，跟 414:896≈0.4621 几乎一样；也包括 18:9≈0.5 这种
///   偏"矮胖"一点的机型）：不做任何处理，原样传下去。容忍范围要留够，
///   否则单纯的浮点误差（比如 390/844 实际算出来是 0.46209，比设计稿
///   的 0.46205 还大那么一丁点）就会在完全正常的全面屏手机上也触发相框。
/// - 宽高比明显超出容忍范围（桌面宽屏浏览器，或者工具栏很高的手机内置
///   浏览器）：按 414:896 的比例居中裁出一块"手机相框"（配阴影 + 背景
///   纹理），画布本身在这块相框里正常铺满，两边不再是死黑一片，而且
///   保证是居中的（不会因为内部 FittedBox 在特定尺寸下出现的对齐怪癖
///   而贴到左边去）。
///
/// 曾经加过一个"全屏/安全"切换按钮，让用户自己选择要不要裁切换取铺满，
/// 后来发现在 iOS Safari 系内核（包括 Messenger 内置浏览器）里，浏览器
/// 自己的地址栏/工具栏是系统级锁死的、网页拿不到那部分空间，所以"全屏"
/// 顶多是把左右填满、上下依然会裁到内容，效果不上不下，体验反而更怪，
/// 应用户要求去掉了，只保留这个安全模式。
class ResponsiveAppShell extends StatelessWidget {
  const ResponsiveAppShell({super.key, required this.child});

  final Widget child;

  static const double _designAspect = 414 / 896;

  /// 宽高比超过设计稿的多少倍才触发相框——留足容忍空间，覆盖常见机型的
  /// 宽高比差异（19.5:9 到 18:9 之间都不该触发），只有明显变宽的场景
  /// （桌面窗口、工具栏很高的内嵌浏览器）才会超过这个界限。
  static const double _aspectTolerance = 1.2;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final viewportAspect = constraints.maxWidth / constraints.maxHeight;
        if (viewportAspect <= _designAspect * _aspectTolerance) {
          return child;
        }

        double frameWidth = constraints.maxWidth * 0.92;
        if (frameWidth > 480) frameWidth = 480;
        double frameHeight = frameWidth / _designAspect;
        final maxFrameHeight = constraints.maxHeight * 0.94 > 900
            ? 900.0
            : constraints.maxHeight * 0.94;
        if (frameHeight > maxFrameHeight) {
          frameHeight = maxFrameHeight;
          frameWidth = frameHeight * _designAspect;
        }

        return ColoredBox(
          color: const Color(0xFF08080A),
          child: Stack(
            children: [
              const BackgroundTexture(opacity: 0.3),
              Center(
                child: Container(
                  width: frameWidth,
                  height: frameHeight,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.6),
                        blurRadius: 60,
                        spreadRadius: 6,
                      ),
                    ],
                  ),
                  child: child,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
