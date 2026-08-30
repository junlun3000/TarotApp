import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../data/draw_service.dart';
import '../data/reading_history_repository.dart';
import '../data/tarot_card_repository.dart';
import '../models/drawn_card.dart';
import '../models/reading_history_entry.dart';
import '../models/spread_preset.dart';
import '../widgets/background_texture.dart';
import '../widgets/card_flip_reveal.dart';
import 'ai_reading_screen.dart';
import 'card_detail_screen.dart';

/// 抽牌结果页 —— 按牌阵的实际布局（[SpreadPreset.previewLayout]）把抽到的
/// 真实卡图摆在对应位置上，点任意一张跳到它的详情页。
///
/// 跟其他页面一样套固定 414x896 画布 + FittedBox 整体缩放，保持全 App
/// 页面尺寸/比例一致。
class DrawResultScreen extends StatefulWidget {
  const DrawResultScreen({
    super.key,
    required this.preset,
    this.precomputedCards,
    this.question,
    this.background,
  });

  final SpreadPreset preset;

  /// 如果抽牌结果已经在别处算好了（比如"选牌"页——用户自己点了 78 张
  /// 牌背中的几张，背后其实早就抽好了，只是揭晓顺序跟着用户点的顺序走），
  /// 传进来直接用，不再重新抽一次。
  final List<DrawnCard>? precomputedCards;

  /// 用户在"设置问题"页填写的具体问题，存进历史记录，也用于 AI 解读。
  final String? question;

  /// 用户在"设置问题"页填写的背景/近况，只用于 AI 解读，不存进历史记录。
  final String? background;

  @override
  State<DrawResultScreen> createState() => _DrawResultScreenState();
}

class _DrawResultScreenState extends State<DrawResultScreen> {
  static const _repository = TarotCardRepository();
  final _drawService = DrawService();

  static const double _designWidth = 414;
  static const double _designHeight = 896;
  static const double _cardRadius = 24;

  late final Future<List<DrawnCard>> _drawnCardsFuture;

  /// 这次抽牌存进历史记录后的 id——传给 [AiReadingScreen]，让它在 AI
  /// 解读生成完之后能回填到同一条记录里，而不是另开一条。
  String? _historyId;

  @override
  void initState() {
    super.initState();
    _drawnCardsFuture = _drawDeck();
  }

  Future<List<DrawnCard>> _drawDeck() async {
    final precomputed = widget.precomputedCards;
    if (precomputed != null) {
      await _tryToSaveHistory(precomputed);
      return precomputed;
    }

    final deck = await _repository.loadDeck();
    final drawnCards = _drawService.draw(
      deck: deck,
      spread: widget.preset.spread,
    );
    await _tryToSaveHistory(drawnCards);
    return drawnCards;
  }

  /// 存历史记录失败（比如某些浏览器内嵌 WebView 的本地数据库不稳定）
  /// 不应该连累用户看不到自己刚抽到的牌——历史记录本来就是锦上添花的
  /// 功能，这里吞掉异常，只在调试日志里留个记录。
  Future<void> _tryToSaveHistory(List<DrawnCard> drawnCards) async {
    try {
      await _saveToHistory(drawnCards);
    } catch (error) {
      debugPrint('保存历史记录失败（已忽略，不影响本次抽牌结果）：$error');
    }
  }

  Future<void> _saveToHistory(List<DrawnCard> drawnCards) async {
    final now = DateTime.now();
    final entry = ReadingHistoryEntry(
      id: now.microsecondsSinceEpoch.toString(),
      dateTime: now,
      spreadId: widget.preset.spread.id,
      spreadNameZh: widget.preset.nameZh,
      question: widget.question,
      cards: [
        for (final drawn in drawnCards)
          HistoryCardEntry(
            cardId: drawn.card.id,
            orientation: drawn.orientation,
            positionLabel: drawn.positionLabel,
          ),
      ],
    );
    await ReadingHistoryRepository.instance.addEntry(entry);
    if (mounted) setState(() => _historyId = entry.id);
  }

  @override
  Widget build(BuildContext context) {
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
                      _Header(title: widget.preset.nameZh),
                      const SizedBox(height: 16),
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
                            if (snapshot.hasError) {
                              return Center(
                                child: Text(
                                  '抽牌失败：${snapshot.error}',
                                  style: const TextStyle(
                                    color: Colors.redAccent,
                                  ),
                                ),
                              );
                            }

                            final drawnCards = snapshot.data!;
                            return _ResultBody(
                              layout: widget.preset.previewLayout,
                              drawnCards: drawnCards,
                              spreadName: widget.preset.nameZh,
                              question: widget.question,
                              background: widget.background,
                              historyId: _historyId,
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

class _Header extends StatelessWidget {
  const _Header({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.of(context).maybePop(),
            icon: const Icon(Icons.arrow_back, color: Colors.white),
          ),
          Expanded(
            child: Text(
              title,
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
    );
  }
}

/// 抽牌结果按牌阵位置摆好后，不是一次性全部翻开，而是要求用户按顺序
/// （从第 0 张开始）依次点开——一张一张揭晓，比自动翻开更有仪式感。
/// [_revealedCount] 记录已经翻开的张数，只有下标等于它的那张牌当前可点。
class _ResultBody extends StatefulWidget {
  const _ResultBody({
    required this.layout,
    required this.drawnCards,
    required this.spreadName,
    required this.question,
    required this.background,
    required this.historyId,
  });

  final List<GridPosition> layout;
  final List<DrawnCard> drawnCards;
  final String spreadName;
  final String? question;
  final String? background;

  /// 这次抽牌在历史记录里的 id；传给 [AiReadingScreen] 让它把生成的
  /// AI 解读回填到这条记录里。
  final String? historyId;

  static const double _cellWidth = 64;
  static const double _cellHeight = 64 * 1.4;
  static const double _cellSpacing = 12;

  @override
  State<_ResultBody> createState() => _ResultBodyState();
}

class _ResultBodyState extends State<_ResultBody> {
  int _revealedCount = 0;

  void _revealCard(int index) {
    if (index != _revealedCount) return;
    setState(() => _revealedCount++);
  }

  @override
  Widget build(BuildContext context) {
    final layout = widget.layout;
    final drawnCards = widget.drawnCards;
    final maxRow = layout.map((p) => p.row).reduce((a, b) => a > b ? a : b);
    final maxCol = layout.map((p) => p.col).reduce((a, b) => a > b ? a : b);
    final step = _ResultBody._cellWidth + _ResultBody._cellSpacing;
    final stepV = _ResultBody._cellHeight + _ResultBody._cellSpacing;
    final allRevealed = _revealedCount >= drawnCards.length;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 28),
            child: Text(
              allRevealed ? '牌已翻开' : '按顺序点开每一张牌',
              style: GoogleFonts.inter(fontSize: 13, color: Colors.white54),
            ),
          ),
          SizedBox(
            width: (maxCol + 1) * step - _ResultBody._cellSpacing,
            height: (maxRow + 1) * stepV - _ResultBody._cellSpacing,
            child: Stack(
              // 提示箭头会画在牌的上方（top 是负数），关掉裁剪才不会被切掉。
              clipBehavior: Clip.none,
              children: [
                for (final (index, position) in layout.indexed)
                  if (index < drawnCards.length) ...[
                    Positioned(
                      left: position.col * step,
                      top: position.row * stepV,
                      child: _CardThumbnail(
                        drawn: drawnCards[index],
                        revealed: index < _revealedCount,
                        active: index == _revealedCount,
                        onReveal: () => _revealCard(index),
                      ),
                    ),
                    if (index == _revealedCount)
                      Positioned(
                        left: position.col * step,
                        top: position.row * stepV - 24,
                        width: _ResultBody._cellWidth,
                        child: const Center(child: _TapHint()),
                      ),
                  ],
              ],
            ),
          ),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                for (final (index, drawn) in drawnCards.indexed)
                  _ResultListTile(
                    drawn: drawn,
                    revealed: index < _revealedCount,
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Colors.white30),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(85),
                  ),
                ),
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => AiReadingScreen(
                        spreadName: widget.spreadName,
                        question: widget.question,
                        background: widget.background,
                        drawnCards: drawnCards,
                        historyId: widget.historyId,
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.auto_awesome),
                label: const Text('AI 深度解读'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CardThumbnail extends StatelessWidget {
  const _CardThumbnail({
    required this.drawn,
    required this.revealed,
    required this.active,
    required this.onReveal,
  });

  final DrawnCard drawn;

  /// 是否已经点开翻面。
  final bool revealed;

  /// 是不是"下一张该点的牌"——只有它可以点。
  final bool active;
  final VoidCallback onReveal;

  @override
  Widget build(BuildContext context) {
    final card = Container(
      width: _ResultBody._cellWidth,
      height: _ResultBody._cellHeight,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        boxShadow: [
          BoxShadow(
            color: Colors.white.withValues(alpha: active ? 0.7 : 0.4),
            blurRadius: active ? 16 : 10,
            spreadRadius: active ? 2 : 1,
          ),
        ],
      ),
      child: CardFlipReveal(
        frontImagePath: drawn.card.imagePath,
        isReversed: drawn.isReversed,
        revealed: revealed,
      ),
    );

    return GestureDetector(
      onTap: revealed
          ? () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => CardDetailScreen(
                    card: drawn.card,
                    initialOrientation: drawn.orientation,
                  ),
                ),
              );
            }
          : (active ? onReveal : null),
      // 当前该点的那张牌轻轻呼吸缩放，加上上面那个跳动的箭头，
      // 让用户一眼看出接下来该点哪张，而不用先读文字提示。
      child: active && !revealed ? _Pulse(child: card) : card,
    );
  }
}

/// 让 [child] 在 1.0~1.06 之间持续呼吸缩放，用来吸引用户注意力。
class _Pulse extends StatefulWidget {
  const _Pulse({required this.child});

  final Widget child;

  @override
  State<_Pulse> createState() => _PulseState();
}

class _PulseState extends State<_Pulse> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.scale(scale: 1.0 + 0.06 * _controller.value, child: child);
      },
      child: widget.child,
    );
  }
}

/// 悬在当前该点的牌上方、持续上下轻跳的小箭头，指示用户点这里。
class _TapHint extends StatefulWidget {
  const _TapHint();

  @override
  State<_TapHint> createState() => _TapHintState();
}

class _TapHintState extends State<_TapHint> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 700),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, -4 * _controller.value),
          child: child,
        );
      },
      child: const Icon(
        Icons.keyboard_arrow_down_rounded,
        color: Colors.amberAccent,
        size: 24,
      ),
    );
  }
}

class _ResultListTile extends StatelessWidget {
  const _ResultListTile({required this.drawn, required this.revealed});

  final DrawnCard drawn;
  final bool revealed;

  @override
  Widget build(BuildContext context) {
    if (!revealed) {
      return ListTile(
        contentPadding: EdgeInsets.zero,
        leading: const Icon(
          Icons.lock_outline,
          color: Colors.white38,
          size: 20,
        ),
        title: Text(
          '${drawn.positionLabel ?? ''}：待翻开',
          style: GoogleFonts.inter(fontSize: 14, color: Colors.white38),
        ),
      );
    }

    final orientationLabel = drawn.isReversed ? '逆位' : '正位';
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(
        '${drawn.positionLabel ?? ''}：${drawn.card.nameZh}（$orientationLabel）',
        style: GoogleFonts.inter(fontSize: 14, color: Colors.white),
      ),
      subtitle: Text(
        drawn.meaning,
        style: GoogleFonts.inter(fontSize: 12, color: Colors.white54),
      ),
      trailing: const Icon(Icons.chevron_right, color: Colors.white38),
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => CardDetailScreen(
              card: drawn.card,
              initialOrientation: drawn.orientation,
            ),
          ),
        );
      },
    );
  }
}
