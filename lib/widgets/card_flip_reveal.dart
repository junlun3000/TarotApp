import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

/// 翻牌揭示动画：先显示卡背，延迟一段时间后沿 Y 轴 3D 翻转，露出正面
/// 真实牌面。多张牌一起用时，给每张牌不同的 [startDelay] 就能做出
/// "1→2→3→4 依次翻开"的效果。
class CardFlipReveal extends StatefulWidget {
  const CardFlipReveal({
    super.key,
    required this.frontImagePath,
    this.isReversed = false,
    this.revealed = true,
    this.startDelay = Duration.zero,
    this.flipDuration = const Duration(milliseconds: 900),
  });

  final String frontImagePath;
  final bool isReversed;

  /// 是否已揭晓——为 false 时保持卡背静止，直到外部把它改成 true 才会
  /// 触发翻面动画。默认 true，保持"组件一挂载就自动翻开"的原有行为；
  /// 用在"一张一张点开"的揭示流程时传 false，再由父组件在用户点击后
  /// 改成 true。
  final bool revealed;

  /// 翻牌开始前的等待时间，用于让多张牌错开、依次翻开。
  final Duration startDelay;

  /// 翻转本身的时长，调这个可以让翻牌动作更慢/更快。
  final Duration flipDuration;

  static const String backImagePath = 'assets/images/cards/CardBacks.png';

  @override
  State<CardFlipReveal> createState() => _CardFlipRevealState();
}

class _CardFlipRevealState extends State<CardFlipReveal>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  Timer? _delayTimer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.flipDuration,
    );
    if (widget.revealed) _scheduleFlip();
  }

  void _scheduleFlip() {
    _delayTimer = Timer(widget.startDelay, () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void didUpdateWidget(CardFlipReveal oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!oldWidget.revealed && widget.revealed) _scheduleFlip();
  }

  @override
  void dispose() {
    _delayTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final angle = _controller.value * math.pi;
        final showBack = angle < math.pi / 2;
        // 转过一半之后，用 (angle - pi) 而不是继续用 angle，
        // 不然翻过去看到的正面图会是镜像的。
        final displayAngle = showBack ? angle : angle - math.pi;

        return Transform(
          alignment: Alignment.center,
          transform: Matrix4.identity()
            ..setEntry(3, 2, 0.0015)
            ..rotateY(displayAngle),
          child: showBack ? _buildBack() : _buildFront(),
        );
      },
    );
  }

  Widget _buildBack() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Image.asset(
        CardFlipReveal.backImagePath,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) =>
            const _FallbackFace(icon: Icons.style_outlined),
      ),
    );
  }

  Widget _buildFront() {
    // 用 AnimatedRotation（Z 轴）而不是固定角度，这样翻牌揭示完成后，
    // 用户再切换正逆位时这里会平滑过渡，不会瞬间跳转。
    return AnimatedRotation(
      turns: widget.isReversed ? 0.5 : 0,
      duration: const Duration(milliseconds: 300),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.asset(
          widget.frontImagePath,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) =>
              const _FallbackFace(icon: Icons.image_not_supported_outlined),
        ),
      ),
    );
  }
}

class _FallbackFace extends StatelessWidget {
  const _FallbackFace({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white10,
      alignment: Alignment.center,
      child: Icon(icon, color: Colors.white24),
    );
  }
}
