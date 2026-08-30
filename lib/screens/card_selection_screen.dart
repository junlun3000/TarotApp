import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:google_fonts/google_fonts.dart';

import '../data/draw_service.dart';
import '../data/tarot_card_repository.dart';
import '../models/drawn_card.dart';
import '../models/spread_preset.dart';
import '../widgets/background_texture.dart';
import '../widgets/card_flip_reveal.dart';
import 'draw_result_screen.dart';

/// "选牌"页 —— 78 张牌背朝上摊开，用户凭直觉点选，制造"这是我自己选的牌"
/// 的仪式感，而不是让 App 直接甩结果给你。
///
/// 关键点：具体抽到哪张牌、正逆位，其实在进这个页面时就已经用
/// [DrawService] 随机算好了（逻辑跟其他抽牌入口完全一样），只是暂时不
/// 揭晓。用户点的顺序决定"第几个位置"（对应牌阵的过去/现在/未来这类
/// 标签），具体点了哪张牌背在视觉上不影响结果——这是"选牌"体验常见的
/// 做法：真随机 + 让用户觉得自己在挑。
///
/// 跟其他页面一样套固定 414x896 画布 + FittedBox 整体缩放。
class CardSelectionScreen extends StatefulWidget {
  const CardSelectionScreen({
    super.key,
    required this.preset,
    this.question,
    this.background,
  });

  final SpreadPreset preset;

  /// 用户在"设置问题"页填写的具体问题，一路带到抽牌结果/AI 解读。
  final String? question;

  /// 用户在"设置问题"页填写的背景/近况，一路带到抽牌结果/AI 解读。
  final String? background;

  @override
  State<CardSelectionScreen> createState() => _CardSelectionScreenState();
}

class _CardSelectionScreenState extends State<CardSelectionScreen> {
  static const _repository = TarotCardRepository();
  final _drawService = DrawService();

  static const double _designWidth = 414;
  static const double _designHeight = 896;
  static const double _cardRadius = 24;
  static const int _totalCards = 78;

  late final Future<List<DrawnCard>> _drawnCardsFuture;
  List<DrawnCard>? _drawnCards;

  final Set<int> _pickedGridIndices = {};

  @override
  void initState() {
    super.initState();
    _drawnCardsFuture = _drawDeck();
  }

  Future<List<DrawnCard>> _drawDeck() async {
    final deck = await _repository.loadDeck();
    final drawnCards = _drawService.draw(
      deck: deck,
      spread: widget.preset.spread,
    );
    _drawnCards = drawnCards;
    return drawnCards;
  }

  void _onCardTapped(int gridIndex) {
    final needed = widget.preset.spread.cardCount;
    if (_pickedGridIndices.contains(gridIndex)) return;
    if (_pickedGridIndices.length >= needed) return;
    if (_drawnCards == null) return;

    setState(() => _pickedGridIndices.add(gridIndex));

    if (_pickedGridIndices.length == needed) {
      Future.delayed(const Duration(milliseconds: 450), () {
        if (!mounted) return;
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => DrawResultScreen(
              preset: widget.preset,
              precomputedCards: _drawnCards!,
              question: widget.question,
              background: widget.background,
            ),
          ),
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final needed = widget.preset.spread.cardCount;

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
                                widget.preset.nameZh,
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
                      Text(
                        '凭直觉选 $needed 张牌（已选 ${_pickedGridIndices.length} / $needed）',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: Colors.white54,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Expanded(
                        child: FutureBuilder<List<DrawnCard>>(
                          future: _drawnCardsFuture,
                          builder: (context, snapshot) {
                            if (snapshot.connectionState !=
                                ConnectionState.done) {
                              return const Center(
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                ),
                              );
                            }

                            final full = _pickedGridIndices.length >= needed;
                            return Center(
                              child: _CardWheel(
                                totalCards: _totalCards,
                                pickedIndices: _pickedGridIndices,
                                disabled: full,
                                onTap: _onCardTapped,
                              ),
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

/// 78 张牌背排成一圈（PTCG Pocket 抽卡式），拖拽转动圆环来浏览、点选。
///
/// 实现技巧：把牌沿一个大圆的圆周等角摆开，圆心放在可视区域下方（屏幕外），
/// 只露出圆周顶部一小段弧——所以看起来像"一圈牌"向两侧弯出屏幕，而不是
/// 现在这种直线扇形。半径按 [_arcSpacing] 换算，让弧上每张牌之间的间距
/// 跟原来的直线扇形手感一致。超过 [_maxVisibleAngle] 的牌转到看不见的
/// 位置，不渲染也点不到，跟原来"划不到就点不到"的行为一致。
///
/// 交互上用 [GestureDetector] 直接把水平拖拽位移换算成圆环的转动角度，
/// 松手时按当时的甩动速度用 [FrictionSimulation] 做惯性减速旋转，
/// 模拟"转卡盘"的手感。首次打开时会自动轻轻转一点再弹回来，提示这里
/// 可以拖拽旋转。
class _CardWheel extends StatefulWidget {
  const _CardWheel({
    required this.totalCards,
    required this.pickedIndices,
    required this.disabled,
    required this.onTap,
  });

  final int totalCards;
  final Set<int> pickedIndices;
  final bool disabled;
  final ValueChanged<int> onTap;

  static const double _cardWidth = 96;
  static const double _cardHeight = _cardWidth * 1.4;

  /// 弧上相邻两张牌之间的间距，沿用原扇形 [_itemExtent] 的密度感。
  static const double _arcSpacing = 34;

  /// 超过这个角度（弧度）的牌视为转到看不见的位置，不渲染。
  static const double _maxVisibleAngle = 50 * math.pi / 180;

  @override
  State<_CardWheel> createState() => _CardWheelState();
}

class _CardWheelState extends State<_CardWheel>
    with SingleTickerProviderStateMixin {
  late final double _radius =
      widget.totalCards * _CardWheel._arcSpacing / (2 * math.pi);
  late final double _angleStep = 2 * math.pi / widget.totalCards;

  late final AnimationController _rotationController =
      AnimationController.unbounded(vsync: this)
        ..addListener(() => setState(() {}));

  double get _rotation => _rotationController.value;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _playRotateHint());
  }

  @override
  void dispose() {
    _rotationController.dispose();
    super.dispose();
  }

  Future<void> _playRotateHint() async {
    await Future.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;
    await _rotationController.animateTo(
      _angleStep * 1.6,
      duration: const Duration(milliseconds: 550),
      curve: Curves.easeOut,
    );
    if (!mounted) return;
    await _rotationController.animateTo(
      0,
      duration: const Duration(milliseconds: 550),
      curve: Curves.easeInOut,
    );
  }

  void _onPanUpdate(DragUpdateDetails details) {
    _rotationController.stop();
    _rotationController.value -= details.delta.dx / _radius;
  }

  void _onPanEnd(DragEndDetails details) {
    final velocity = -details.velocity.pixelsPerSecond.dx / _radius;
    _rotationController.animateWith(
      FrictionSimulation(0.15, _rotation, velocity),
    );
  }

  /// 把角度归一化到 (-π, π]，这样才能算出每张牌离圆环"正面"最近的那一圈
  /// 角度，而不是绕了好几圈之后的原始角度。
  double _normalizeAngle(double angle) {
    const twoPi = 2 * math.pi;
    var a = (angle + math.pi) % twoPi;
    if (a < 0) a += twoPi;
    return a - math.pi;
  }

  @override
  Widget build(BuildContext context) {
    const cutoff = _CardWheel._maxVisibleAngle;
    final maxDy = _radius * (1 - math.cos(cutoff));
    final stackHeight = maxDy + _CardWheel._cardHeight;

    final visible = <MapEntry<int, double>>[];
    for (var i = 0; i < widget.totalCards; i++) {
      final normalized = _normalizeAngle(i * _angleStep - _rotation);
      if (normalized.abs() <= cutoff) {
        visible.add(MapEntry(i, normalized));
      }
    }
    // 离正面越远越先画，越近的后画、盖在上面，模拟卡片朝向观众叠放。
    visible.sort((a, b) => b.value.abs().compareTo(a.value.abs()));

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onPanUpdate: _onPanUpdate,
      onPanEnd: _onPanEnd,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final centerX = constraints.maxWidth / 2;
          return SizedBox(
            width: double.infinity,
            height: stackHeight,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                for (final entry in visible)
                  _buildTile(entry.key, entry.value, cutoff, centerX),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildTile(int index, double angle, double cutoff, double centerX) {
    final dx = _radius * math.sin(angle);
    final dy = _radius * (1 - math.cos(angle));
    final t = angle.abs() / cutoff;
    final scale = 1.0 - 0.2 * t;
    final fade = 1.0 - 0.35 * t;
    // 越靠边的牌，转开的一面被"背光"，叠一层半透明黑压暗它，配合下面
    // 的 rotateY 才会看起来像真的转过去了，而不是单纯变窄变淡。
    final shade = 0.5 * t;
    final picked = widget.pickedIndices.contains(index);

    return Positioned(
      left: centerX + dx - _CardWheel._cardWidth / 2,
      top: dy,
      child: Transform(
        alignment: Alignment.topCenter,
        transform: Matrix4.identity()
          ..setEntry(3, 2, 0.0022)
          ..rotateY(angle * 0.85),
        child: Transform.scale(
          scale: scale,
          alignment: Alignment.topCenter,
          child: Opacity(
            opacity: fade,
            child: SizedBox(
              width: _CardWheel._cardWidth,
              height: _CardWheel._cardHeight,
              child: Stack(
                children: [
                  _CardBackTile(
                    picked: picked,
                    disabled: widget.disabled && !picked,
                    onTap: () => widget.onTap(index),
                  ),
                  if (shade > 0)
                    Positioned.fill(
                      child: IgnorePointer(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(4),
                            color: Colors.black.withValues(alpha: shade),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CardBackTile extends StatelessWidget {
  const _CardBackTile({
    required this.picked,
    required this.disabled,
    required this.onTap,
  });

  final bool picked;
  final bool disabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: (picked || disabled) ? null : onTap,
      child: AnimatedScale(
        scale: picked ? 0.85 : 1.0,
        duration: const Duration(milliseconds: 300),
        child: AnimatedOpacity(
          opacity: picked ? 0.35 : (disabled ? 0.4 : 1.0),
          duration: const Duration(milliseconds: 300),
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(4),
              // 深色投影 + 一圈细白边光，让牌看起来像悬空的实体卡片，
              // 而不是贴在背景上的一张平面图。
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: picked ? 0 : 0.55),
                  blurRadius: 12,
                  offset: const Offset(0, 7),
                ),
                BoxShadow(
                  color: Colors.white.withValues(alpha: picked ? 0 : 0.18),
                  blurRadius: 3,
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: Image.asset(
                CardFlipReveal.backImagePath,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                    Container(color: Colors.white10),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
