import 'package:flutter/material.dart';
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
                              child: _CardFan(
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

/// 横向堆叠成扇形的 78 张牌背，可以左右划动浏览。
///
/// 实现技巧：[ListView] 给每张牌分配的横向"格子"（[itemExtent]）比牌
/// 本身的宽度（[_cardWidth]）要窄，牌的实际渲染宽度用 [OverflowBox] 撑开，
/// 这样相邻的牌就会视觉上叠在一起；后面（索引更大）的牌在 Stack 绘制顺序
/// 上更晚，会盖在前一张上面，形成从左到右层层叠加的扇形效果。
///
/// 首次打开时会自动轻轻往右滑一下再弹回来，提示这里可以左右划动
/// （不然堆叠起来的牌看着容易被当成一张静态图片，看不出能滑动）。
class _CardFan extends StatefulWidget {
  const _CardFan({
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
  static const double _itemExtent = 34;

  @override
  State<_CardFan> createState() => _CardFanState();
}

class _CardFanState extends State<_CardFan> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _playSwipeHint());
  }

  Future<void> _playSwipeHint() async {
    await Future.delayed(const Duration(milliseconds: 500));
    if (!mounted || !_scrollController.hasClients) return;
    await _scrollController.animateTo(
      100,
      duration: const Duration(milliseconds: 550),
      curve: Curves.easeOut,
    );
    if (!mounted || !_scrollController.hasClients) return;
    await _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 550),
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: _CardFan._cardHeight,
      child: ListView.builder(
        controller: _scrollController,
        scrollDirection: Axis.horizontal,
        clipBehavior: Clip.none,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemExtent: _CardFan._itemExtent,
        itemCount: widget.totalCards,
        itemBuilder: (context, index) {
          final picked = widget.pickedIndices.contains(index);
          return OverflowBox(
            minWidth: _CardFan._cardWidth,
            maxWidth: _CardFan._cardWidth,
            alignment: Alignment.centerLeft,
            child: _CardBackTile(
              picked: picked,
              disabled: widget.disabled && !picked,
              onTap: () => widget.onTap(index),
            ),
          );
        },
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
              boxShadow: [
                BoxShadow(
                  color: Colors.white.withValues(alpha: picked ? 0 : 0.25),
                  blurRadius: 6,
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
