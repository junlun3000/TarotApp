import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:google_fonts/google_fonts.dart';

import '../data/draw_service.dart';
import '../data/tarot_card_repository.dart';
import '../models/drawn_card.dart';
import '../models/spread_preset.dart';
import '../widgets/background_texture.dart';
import '../widgets/responsive_app_shell.dart';
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
                  minimum: EdgeInsets.only(
                    top: ResponsiveAppShell.topCropInset(context),
                  ),
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
                            return Align(
                              alignment: const Alignment(0, -0.35),
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

/// 78 张牌背绕成一整圈（PTCG Pocket 抽卡式），拖拽转动圆环来浏览、点选。
///
/// 实现技巧：78 张牌均匀分布在一整圈圆周上（[_angleStep] = 360°/78），
/// 用类似"斜着看一个圆环"的椭圆投影摆位置：离用户最近（正面，角度 0）
/// 的牌摆在最下面、最大最亮；角度越往两边转，牌就沿椭圆往上移、变小
/// 变暗，转到正后方（角度 ±180°）时摆在最上面、又小又暗——这样能同时
/// 看到"眼前一排大牌"和"背后绕上去的一圈小牌"，才像真的是一整圈牌，
/// 而不是一段浮在半空的弧。只有正面 [_interactiveCutoff] 范围内的牌
/// 足够大、足够正对着人，才能点选；背后那一圈纯粹是装饰，不响应点击。
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

  /// 正面那一排相邻两张牌之间的间距，沿用原扇形的密度感。
  static const double _arcSpacing = 34;

  /// 正面这一圈能看清、能点选的角度范围（弧度）；超出这个范围的牌
  /// 已经转到侧后方，只作为背景装饰。
  static const double _interactiveCutoff = 55 * math.pi / 180;

  /// 椭圆投影里，从最下面（正面）转到最上面（正后方）总共要爬多高。
  static const double _ringRise = 190;

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
    final all = <MapEntry<int, double>>[
      for (var i = 0; i < widget.totalCards; i++)
        MapEntry(i, _normalizeAngle(i * _angleStep - _rotation)),
    ];
    // 正后方（景深最深）先画，正面（景深最浅）最后画、盖在最上面，
    // 这样近处的牌才会挡住绕到背后的远处的牌。
    all.sort((a, b) => math.cos(a.value).compareTo(math.cos(b.value)));

    const stackHeight = _CardWheel._ringRise + _CardWheel._cardHeight;

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
                for (final entry in all) _buildTile(entry.key, entry.value, centerX),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildTile(int index, double angle, double centerX) {
    // depth：1 = 正对着人（最近），-1 = 转到正后方（最远）。
    final depth = math.cos(angle);
    final frontness = (depth + 1) / 2; // 0（正后方）..1（正面）
    final dx = _radius * math.sin(angle);
    final scale = 0.3 + 0.7 * frontness;
    final fade = 0.4 + 0.6 * frontness;
    // 转开的一面被"背光"，叠一层半透明黑压暗它，越靠后方越暗。
    final shade = (1 - frontness) * 0.45;
    // 正面摆最下面、正后方摆最上面，两边（角度 ±90°）摆中间高度——
    // 连起来正好是一圈立起来、往后倾斜的椭圆，能同时看见眼前一排大牌
    // 和背后绕上去的小牌。
    final top = frontness * _CardWheel._ringRise;
    final interactive = angle.abs() <= _CardWheel._interactiveCutoff;
    final picked = widget.pickedIndices.contains(index);
    // rotateY 角度封顶，不然绕到侧后方的牌会转过 90° 变成镜像，看着很怪；
    // 靠缩放和压暗去表现"转得更远"，旋转本身封顶在一个自然的斜角上。
    final rotY = (angle * 0.85).clamp(-1.05, 1.05);

    return Positioned(
      left: centerX + dx - _CardWheel._cardWidth / 2,
      top: top,
      child: Transform(
        alignment: Alignment.center,
        transform: Matrix4.identity()
          ..setEntry(3, 2, 0.0022)
          ..rotateY(rotY),
        child: Transform.scale(
          scale: scale,
          alignment: Alignment.center,
          child: Opacity(
            opacity: fade,
            child: SizedBox(
              width: _CardWheel._cardWidth,
              height: _CardWheel._cardHeight,
              child: Stack(
                children: [
                  _CardBackTile(
                    picked: picked,
                    disabled: !interactive || (widget.disabled && !picked),
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
