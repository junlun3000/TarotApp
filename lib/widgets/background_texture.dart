import 'package:flutter/material.dart';

/// 深色主题页面共用的背景纹理层（原设计: Rectangle282, mix-blend-mode:
/// soft-light）。onboarding 和"设置问题"页都用了同一张纹理图 + 相同处理。
///
/// Flutter 没有原生对应 CSS `mix-blend-mode: soft-light` 的效果，这里先用
/// 简单的 [Opacity] 近似；如果这个细节还原度重要，可以再用
/// [ShaderMask]/[BackdropFilter] 做精确实现。
class BackgroundTexture extends StatelessWidget {
  const BackgroundTexture({super.key, this.opacity = 0.2});

  final double opacity;

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Opacity(
        opacity: opacity,
        child: Image.asset(
          'assets/images/bg_texture.png',
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
        ),
      ),
    );
  }
}
