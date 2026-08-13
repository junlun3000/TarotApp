import 'dart:math' as math;

import 'package:flutter/material.dart';

/// 一张装饰性图片在 Figma 设计画布上的定位、尺寸、旋转角度。
class DecorationSpec {
  const DecorationSpec({
    required this.asset,
    required this.left,
    required this.top,
    required this.width,
    required this.height,
    this.rotationDegrees = 0,
  });

  final String asset;
  final double left;
  final double top;
  final double width;
  final double height;
  final double rotationDegrees;
}

/// 按 [DecorationSpec] 定位/缩放/旋转渲染一张装饰性图片。
/// 图片资源缺失时静默收起（[SizedBox.shrink]），不影响页面其余部分渲染——
/// 装饰图通常不是页面的核心内容，缺图不应该导致整页崩溃。
class DecorativeImage extends StatelessWidget {
  const DecorativeImage({super.key, required this.spec});

  final DecorationSpec spec;

  @override
  Widget build(BuildContext context) {
    final image = Image.asset(
      spec.asset,
      width: spec.width,
      height: spec.height,
      errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
    );

    return Positioned(
      left: spec.left,
      top: spec.top,
      child: spec.rotationDegrees == 0
          ? image
          : Transform.rotate(
              angle: spec.rotationDegrees * math.pi / 180,
              child: image,
            ),
    );
  }
}
