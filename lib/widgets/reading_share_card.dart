import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/ai_reading.dart';
import '../models/drawn_card.dart';
import 'background_texture.dart';
import 'decorative_image.dart';

/// 塔罗 AI 解读的分享卡——参考用户提供的"TAROT GUIDE"海报式排版：
/// 编号牌位 + 每张牌的关键词核心 + "深度解读"主题框 + "综合启示" +
/// 收藏向的底部横幅。紫金配色呼应参考图的"典藏感"；没有可用的水晶/花枝
/// 插画素材，角落的藤蔓花纹是用 CustomPainter 手绘的矢量装饰，不是抠图。
class ReadingShareCard extends StatelessWidget {
  const ReadingShareCard({
    super.key,
    required this.spreadName,
    required this.drawnCards,
    required this.reading,
  });

  final String spreadName;
  final List<DrawnCard> drawnCards;
  final AiReading reading;

  static const double width = 360;

  static const _gold = Color(0xFFD9B37C);
  static const _purple = Color(0xFF6B4FA0);

  static const _starGlow = DecorationSpec(
    asset: 'assets/images/intersect_shape.png',
    left: -170,
    top: -190,
    width: 640,
    height: 640,
  );

  @override
  Widget build(BuildContext context) {
    // 卡不多的时候（≤4）每张都摊开讲：图 + 编号 + 牌名 + 牌意核心。
    // 牌阵本身有很多张牌时（比如凯尔特十字这种 10 张的），摊开讲不下，
    // 也不该用"+N"直接把剩下的牌藏起来——那样等于这几张牌的解读完全没
    // 出现在分享图里。改成让所有牌都以小图 + 编号的形式露出来，不配文字，
    // 具体解读交给下面"深度解读"/"综合启示"两块已经综合过的文字来承载。
    final isCompact = drawnCards.length > 4;

    return SizedBox(
      // 只固定宽度，高度让内容自己撑开——牌阵张数不定（3 张到 10+ 张都
      // 有），用固定高度装不下多张牌时会截断底部内容，改成自适应高度就
      // 不用管到底有几张牌了。Stack 不设 StackFit.expand，改由下面
      // Padding+Column 这个非 positioned 子项决定 Stack 的实际大小，
      // Positioned.fill 的背景层会跟着长到这个大小。
      width: width,
      child: ClipRect(
        child: Stack(
          children: [
            const Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0xFF241735),
                      Color(0xFF130D1E),
                      Color(0xFF09060D),
                    ],
                    stops: [0.0, 0.45, 1.0],
                  ),
                ),
              ),
            ),
            const BackgroundTexture(opacity: 0.22),
            // 不能像 `Opacity(child: ColorFiltered(child: DecorativeImage(...)))`
            // 这样套——DecorativeImage 内部直接返回一个 Positioned，而
            // Positioned 只有直接挂在 Stack 下面才有效，中间隔着
            // Opacity/ColorFiltered 这种也会创建自己 RenderObject 的
            // widget 时，Positioned 会把定位信息错误地应用到底下 Image
            // 的 RenderObject 上（它在渲染树里的实际父节点其实是
            // ColorFiltered，不是 Stack）。debug 模式这里本该有清晰的
            // assert 报错，但 release 构建会跳过 assert，问题就变成一个
            // 很难看懂的类型转换报错，甚至波及到别的地方（比如离屏截图）。
            // 改成 Positioned 直接在最外层，里面才叠 Opacity/ColorFiltered。
            Positioned(
              left: _starGlow.left,
              top: _starGlow.top,
              child: Opacity(
                opacity: 0.18,
                child: ColorFiltered(
                  colorFilter: const ColorFilter.mode(
                    Color(0xFFB79CE0),
                    BlendMode.modulate,
                  ),
                  child: Image.asset(
                    _starGlow.asset,
                    width: _starGlow.width,
                    height: _starGlow.height,
                    errorBuilder: (context, error, stackTrace) =>
                        const SizedBox.shrink(),
                  ),
                ),
              ),
            ),
            const Positioned(
              left: 0,
              top: 0,
              child: _CornerFlourish(),
            ),
            const Positioned(
              right: 0,
              top: 0,
              child: _CornerFlourish(flip: true),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 34, 22, 22),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const _Header(),
                  const SizedBox(height: 8),
                  Text(
                    spreadName,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: ReadingShareCard._gold.withValues(alpha: 0.5),
                        ),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '✦ 抽一张牌，看看此刻想对你说什么 ✦',
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          letterSpacing: 0.5,
                          color: ReadingShareCard._gold.withValues(alpha: 0.9),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  if (isCompact)
                    _CompactCardGrid(drawnCards: drawnCards)
                  else
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        for (var i = 0; i < drawnCards.length; i++) ...[
                          if (i > 0) const SizedBox(width: 10),
                          Expanded(
                            child: _CardColumn(
                              index: i + 1,
                              drawn: drawnCards[i],
                              section: i < reading.cards.length
                                  ? reading.cards[i]
                                  : null,
                            ),
                          ),
                        ],
                      ],
                    ),
                  const SizedBox(height: 20),
                  _DeepReadBox(
                    themeTitle: reading.themeTitle,
                    overview: reading.overview,
                  ),
                  const SizedBox(height: 18),
                  _InsightSection(advice: reading.advice),
                  const SizedBox(height: 24),
                  const _SaveBanner(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 顶部装饰——月亮 + 两侧的小分隔线，呼应参考图那种"典藏感"抬头。
class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(
              child: Container(
                height: 1,
                margin: const EdgeInsets.only(right: 10),
                color: ReadingShareCard._gold.withValues(alpha: 0.35),
              ),
            ),
            const Icon(
              Icons.dark_mode,
              color: ReadingShareCard._gold,
              size: 22,
            ),
            Expanded(
              child: Container(
                height: 1,
                margin: const EdgeInsets.only(left: 10),
                color: ReadingShareCard._gold.withValues(alpha: 0.35),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Text(
          'T A R O T',
          style: GoogleFonts.inter(
            fontSize: 12,
            letterSpacing: 4,
            fontWeight: FontWeight.w600,
            color: ReadingShareCard._gold,
          ),
        ),
      ],
    );
  }
}

/// 角落的藤蔓花纹——矢量手绘（几条弧线 + 小圆点/菱形当"花苞"），不依赖
/// 任何图片资源，可以无限缩放不糊。[flip] 为 true 时水平镜像，配对用在
/// 右上角。
class _CornerFlourish extends StatelessWidget {
  const _CornerFlourish({this.flip = false});

  final bool flip;

  @override
  Widget build(BuildContext context) {
    final painter = CustomPaint(
      size: const Size(90, 90),
      painter: _FlourishPainter(
        color: ReadingShareCard._gold.withValues(alpha: 0.55),
      ),
    );
    if (!flip) return painter;
    return Transform(
      alignment: Alignment.center,
      transform: Matrix4.diagonal3Values(-1.0, 1.0, 1.0),
      child: painter,
    );
  }
}

class _FlourishPainter extends CustomPainter {
  const _FlourishPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round;
    final dotPaint = Paint()..color = color;

    final path = Path()
      ..moveTo(6, 30)
      ..cubicTo(20, 8, 34, 4, 52, 10)
      ..moveTo(14, 40)
      ..cubicTo(24, 22, 40, 16, 58, 20);
    canvas.drawPath(path, linePaint);

    canvas.drawCircle(const Offset(52, 10), 2.6, dotPaint);
    canvas.drawCircle(const Offset(58, 20), 2.0, dotPaint);
    canvas.drawCircle(const Offset(6, 30), 1.8, dotPaint);
  }

  @override
  bool shouldRepaint(covariant _FlourishPainter oldDelegate) =>
      oldDelegate.color != color;
}

class _CardColumn extends StatelessWidget {
  const _CardColumn({
    required this.index,
    required this.drawn,
    required this.section,
  });

  final int index;
  final DrawnCard drawn;
  final AiReadingCardSection? section;

  @override
  Widget build(BuildContext context) {
    final orientationLabel = drawn.isReversed ? '逆位' : '正位';
    // 牌名用抽牌结果里确定性的那份（drawn.card.nameZh），不用 AI 返回的
    // cardNameZh——虽然 prompt 里要求 AI 原样带回牌名，但它有时会自己
    // 把"（正位/逆位）"也写进这个字段，导致这里单行显示时被硬生生截断。
    final cardName = drawn.card.nameZh;
    final keywordCore = section?.keywordCore ?? '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          '牌名：$orientationLabel',
          style: GoogleFonts.inter(fontSize: 9, color: Colors.white54),
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: RotatedBox(
            quarterTurns: drawn.isReversed ? 2 : 0,
            child: Image.asset(
              drawn.card.imagePath,
              width: double.infinity,
              height: 108,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                height: 108,
                color: Colors.white10,
              ),
            ),
          ),
        ),
        Transform.translate(
          offset: const Offset(0, -12),
          child: Container(
            width: 22,
            height: 22,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF130D1E),
              border: Border.all(color: ReadingShareCard._gold, width: 1.2),
            ),
            child: Text(
              '$index',
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: ReadingShareCard._gold,
              ),
            ),
          ),
        ),
        Transform.translate(
          offset: const Offset(0, -6),
          child: Text(
            cardName,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.playfairDisplay(
              fontSize: 13,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(height: 3),
        Text(
          '牌意核心',
          style: GoogleFonts.inter(fontSize: 8, color: Colors.white38),
        ),
        const SizedBox(height: 2),
        Text(
          keywordCore,
          textAlign: TextAlign.center,
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.inter(
            fontSize: 9.5,
            height: 1.4,
            color: Colors.white.withValues(alpha: 0.75),
          ),
        ),
      ],
    );
  }
}

/// 牌很多的时候（>4 张）用——每张牌都露出来（小图 + 编号），不裁掉任何
/// 一张，只是不配名字/关键词文字了（放不下），具体解读靠"深度解读"/
/// "综合启示"两块已经综合过全部牌面的文字来承载。
class _CompactCardGrid extends StatelessWidget {
  const _CompactCardGrid({required this.drawnCards});

  final List<DrawnCard> drawnCards;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 8,
      runSpacing: 12,
      children: [
        for (var i = 0; i < drawnCards.length; i++)
          _CompactCardThumb(index: i + 1, drawn: drawnCards[i]),
      ],
    );
  }
}

class _CompactCardThumb extends StatelessWidget {
  const _CompactCardThumb({required this.index, required this.drawn});

  final int index;
  final DrawnCard drawn;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 52,
      child: Column(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(5),
            child: RotatedBox(
              quarterTurns: drawn.isReversed ? 2 : 0,
              child: Image.asset(
                drawn.card.imagePath,
                width: double.infinity,
                height: 72,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                    Container(height: 72, color: Colors.white10),
              ),
            ),
          ),
          Transform.translate(
            offset: const Offset(0, -9),
            child: Container(
              width: 17,
              height: 17,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF130D1E),
                border: Border.all(color: ReadingShareCard._gold, width: 1),
              ),
              child: Text(
                '$index',
                style: GoogleFonts.inter(
                  fontSize: 8.5,
                  fontWeight: FontWeight.w700,
                  color: ReadingShareCard._gold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DeepReadBox extends StatelessWidget {
  const _DeepReadBox({required this.themeTitle, required this.overview});

  final String themeTitle;
  final String overview;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            ReadingShareCard._purple.withValues(alpha: 0.18),
            Colors.transparent,
          ],
        ),
        border: Border.all(color: ReadingShareCard._gold.withValues(alpha: 0.4)),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            themeTitle.isEmpty ? '深度解读' : '深度解读：$themeTitle',
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.playfairDisplay(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: ReadingShareCard._gold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            overview,
            textAlign: TextAlign.center,
            maxLines: 5,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(
              fontSize: 11.5,
              height: 1.6,
              color: Colors.white.withValues(alpha: 0.85),
            ),
          ),
        ],
      ),
    );
  }
}

class _InsightSection extends StatelessWidget {
  const _InsightSection({required this.advice});

  final String advice;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          '综合启示',
          style: GoogleFonts.playfairDisplay(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          advice,
          textAlign: TextAlign.center,
          maxLines: 5,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.inter(
            fontSize: 11.5,
            height: 1.6,
            color: Colors.white.withValues(alpha: 0.8),
          ),
        ),
      ],
    );
  }
}

class _SaveBanner extends StatelessWidget {
  const _SaveBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            ReadingShareCard._purple.withValues(alpha: 0.25),
            ReadingShareCard._gold.withValues(alpha: 0.16),
          ],
        ),
        border: Border.all(color: ReadingShareCard._gold.withValues(alpha: 0.5)),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.bookmark_outline,
                size: 14,
                color: ReadingShareCard._gold,
              ),
              const SizedBox(width: 6),
              Text(
                'SAVE THIS SPREAD',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  letterSpacing: 1.5,
                  fontWeight: FontWeight.w600,
                  color: ReadingShareCard._gold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '你可能想再次翻阅它',
            style: GoogleFonts.inter(
              fontSize: 10,
              color: Colors.white.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }
}
