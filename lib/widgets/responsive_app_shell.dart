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
///   偏"矮胖"一点的机型）：不加相框装饰，但仍然会显式居中一块按设计稿
///   比例算出来的内容区（见下）。
/// - 宽高比明显超出容忍范围（桌面宽屏浏览器，或者工具栏很高的手机内置
///   浏览器）：按 414:896 的比例居中裁出一块"手机相框"（配阴影 + 背景
///   纹理），画布本身在这块相框里正常铺满，两边不再是死黑一片。
///
/// **两种情况都不再把 `child` 原样传下去、指望它自己内部裸的
/// `FittedBox(fit: BoxFit.contain)` 去处理留白**——曾经发现且在 iOS
/// Chrome（iOS 上第三方浏览器只是套壳 WebKit，视口比设计稿略"宽"一点点，
/// 但又没宽到超过下面的容忍倍数）上再次复现：这种"轻微超出但没触发相框"
/// 的场景下，裸 FittedBox(contain) 会把留白整块贴到一侧（比如全部贴到
/// 右边变成一条黑边），而不是左右对称居中——这是 CanvasKit 在这类尺寸下
/// 的对齐怪癖，不是缓存或时序问题（无痕模式下同样复现）。
///
/// 中间还试过两版都不理想：
/// 1. 显式 `Center` + 精确尺寸：黑边确实对称了，但用户反馈"黑边太多，
///    铺满一点"——而且这个分支没背景色打底，网页默认白底会从黑边缝隙露
///    出来，变成更难看的白边。
/// 2. `BoxFit.cover` 居中裁边：铺满是铺满了，但居中裁切会上下各切掉一点，
///    切到了页面顶部标题栏（"牌阵"两个字被状态栏吃掉一截）。
///
/// 试过把裁切锚点从居中改成顶部对齐（裁切全部转到底部），铺满、也不切
/// 顶部标题了，但底部导航栏这次真的被裁到了——铺满和不裁内容这两个目标
/// 在数学上是互斥的：裁多少完全由"宽度铺满所需的缩放比例"决定，跟内容
/// 怎么摆放无关；不管往哪边挪、挪多少，被裁掉的绝对量不会变，只能决定
/// "被裁的这条边里装的是可以牺牲的东西，还是不能裁的真内容"。
///
/// 最终方案：裁切锚点固定在顶部对齐（`Alignment.bottomCenter`，即只从
/// 顶部裁），并且把"这次会裁掉多少 design 像素"通过 [topCropInset] 暴露
/// 给下面的页面——每个页面在自己最外层 `SafeArea` 上加
/// `minimum: EdgeInsets.only(top: ResponsiveAppShell.topCropInset(context))`，
/// 把标题往下推够这个量，正常设备上该值是 0（不会多出死区），只有真的
/// 会被裁的设备上才会推下去。底部导航栏因为裁切固定只发生在顶部，不用
/// 额外处理。
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

  /// 这次渲染顶部会被裁掉多少 design 像素（414x896 坐标系下）——正常
  /// 设备（宽高比跟设计稿一致，或触发了相框分支）是 0。页面自己的顶部
  /// `SafeArea` 应该用这个值作为 `minimum` 的 top，把标题/返回按钮之类
  /// 往下推够，避免被裁掉。
  static double topCropInset(BuildContext context) {
    return context
            .dependOnInheritedWidgetOfExactType<_ResponsiveInsetsScope>()
            ?.topCropInset ??
        0;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth;
        final availableHeight = constraints.maxHeight;
        final viewportAspect = availableWidth / availableHeight;
        final needsFrame = viewportAspect > _designAspect * _aspectTolerance;

        double contentWidth;
        double contentHeight;
        if (!needsFrame) {
          // 铺满整个视口，裁掉多出来的一点点边缘——底部对齐，裁切只落在
          // 顶部。clipBehavior: Clip.hardEdge 是因为 FittedBox 默认不
          // 裁剪溢出内容。顶部会裁掉多少（design 像素）算给
          // topCropInset，页面自己负责把标题推下去避开。
          double topCropInset = 0;
          if (viewportAspect > _designAspect) {
            final scale = availableWidth / 414;
            topCropInset = (896 - availableHeight / scale).clamp(
              0.0,
              double.infinity,
            );
          }
          return _ResponsiveInsetsScope(
            topCropInset: topCropInset,
            child: FittedBox(
              fit: BoxFit.cover,
              alignment: Alignment.bottomCenter,
              clipBehavior: Clip.hardEdge,
              child: SizedBox(width: 414, height: 896, child: child),
            ),
          );
        }

        contentWidth = availableWidth * 0.92;
        if (contentWidth > 480) contentWidth = 480;
        contentHeight = contentWidth / _designAspect;
        final maxFrameHeight = availableHeight * 0.94 > 900
            ? 900.0
            : availableHeight * 0.94;
        if (contentHeight > maxFrameHeight) {
          contentHeight = maxFrameHeight;
          contentWidth = contentHeight * _designAspect;
        }

        return ColoredBox(
          color: const Color(0xFF08080A),
          child: Stack(
            children: [
              const BackgroundTexture(opacity: 0.3),
              Center(
                child: Container(
                  width: contentWidth,
                  height: contentHeight,
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

class _ResponsiveInsetsScope extends InheritedWidget {
  const _ResponsiveInsetsScope({
    required this.topCropInset,
    required super.child,
  });

  final double topCropInset;

  @override
  bool updateShouldNotify(_ResponsiveInsetsScope oldWidget) {
    return oldWidget.topCropInset != topCropInset;
  }
}
