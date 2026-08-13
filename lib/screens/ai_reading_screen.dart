import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../data/ai_reading_service.dart';
import '../data/share_reading.dart';
import '../models/ai_reading.dart';
import '../models/drawn_card.dart';
import '../widgets/background_texture.dart';
import '../widgets/reading_share_card.dart';

/// AI 深度解读页 —— 把问题 + 抽到的牌交给后端 Worker 转发给 Claude，
/// 生成一段针对这次占卜的解读文字。
///
/// 跟其他页面一样套固定 414x896 画布 + FittedBox 整体缩放。
class AiReadingScreen extends StatefulWidget {
  const AiReadingScreen({
    super.key,
    required this.spreadName,
    required this.drawnCards,
    this.question,
    this.background,
  });

  final String spreadName;
  final List<DrawnCard> drawnCards;
  final String? question;

  /// 用户在"设置问题"页填写的背景/近况，帮 AI 判断这次问题的领域，
  /// 让解读更贴合占卜者本人的处境。
  final String? background;

  @override
  State<AiReadingScreen> createState() => _AiReadingScreenState();
}

class _AiReadingScreenState extends State<AiReadingScreen> {
  static const double _designWidth = 414;
  static const double _designHeight = 896;
  static const double _cardRadius = 24;

  final _service = const AiReadingService();
  final _shareCardKey = GlobalKey();
  late Future<AiReading> _readingFuture;

  /// 解读成功后缓存一份，给分享按钮和离屏渲染的分享卡用——分享卡不跟着
  /// [FutureBuilder] 走，是因为分享按钮长在页面顶部固定的那一行，跟下面
  /// 会随请求状态变化的内容区是分开的。
  AiReading? _loadedReading;
  bool _sharing = false;
  Uint8List? _previewBytes;

  @override
  void initState() {
    super.initState();
    _readingFuture = _requestReading();
  }

  Future<AiReading> _requestReading() {
    final future = _service.generateReading(
      spreadName: widget.spreadName,
      drawnCards: widget.drawnCards,
      question: widget.question,
      background: widget.background,
    );
    future.then((reading) {
      if (mounted) setState(() => _loadedReading = reading);
    }).catchError((Object _) {});
    return future;
  }

  void _retry() {
    setState(() {
      _loadedReading = null;
      _readingFuture = _requestReading();
    });
  }

  Future<void> _share() async {
    if (_sharing) return;
    setState(() => _sharing = true);
    try {
      // toImage() 底层要读一次 WebGL 的像素缓冲区（readPixels），在某些
      // 环境下这一步偶尔会因为一次性的 GPU/驱动小抖动失败，不是每次都
      // 稳定复现的那种错误——重试一次通常就好，不用直接甩错误给用户。
      Object? lastError;
      for (var attempt = 0; attempt < 2; attempt++) {
        try {
          final bytes = await captureRepaintBoundaryPng(_shareCardKey);
          if (bytes != null) {
            if (mounted) setState(() => _previewBytes = bytes);
            return;
          }
          lastError = '生成分享图失败';
        } catch (err) {
          lastError = err;
          debugPrint('capture attempt $attempt failed: $err');
        }
      }
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('生成分享图失败：$lastError')));
      }
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

  void _closePreview() => setState(() => _previewBytes = null);

  Future<void> _confirmShare() async {
    final bytes = _previewBytes;
    if (bytes == null) return;
    try {
      await shareImageBytes(
        bytes,
        text: '我在塔罗抽到了「${widget.spreadName}」，来看看结果 ✨',
      );
    } catch (err, stack) {
      debugPrint('share failed: $err\n$stack');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('分享失败：$err')));
      }
    } finally {
      if (mounted) setState(() => _previewBytes = null);
    }
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
                if (_loadedReading != null)
                  // 离屏渲染用来截图分享的卡片——不能用"0 尺寸 +
                  // OverflowBox"那种技巧，OverflowBox 默认不裁切，子内容
                  // 会直接盖在真实页面上面（踩过这个坑）。挪到画布范围
                  // 之外（例如 left: -2000）才是真的不可见：RepaintBoundary
                  // 自己的 toImage() 截图不受祖先裁切/位置影响，只要它还
                  // 在树里正常参与一次 paint（不能用 Offstage，那个会跳过
                  // 绘制）。
                  Positioned(
                    left: -2000,
                    top: 0,
                    child: RepaintBoundary(
                      key: _shareCardKey,
                      child: ReadingShareCard(
                        spreadName: widget.spreadName,
                        drawnCards: widget.drawnCards,
                        reading: _loadedReading!,
                      ),
                    ),
                  ),
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
                                'AI 深度解读',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.playfairDisplay(
                                  fontSize: 18,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            SizedBox(
                              width: 48,
                              child: _loadedReading == null
                                  ? null
                                  : IconButton(
                                      onPressed: _sharing ? null : _share,
                                      icon: _sharing
                                          ? const SizedBox(
                                              width: 18,
                                              height: 18,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                color: Colors.white,
                                              ),
                                            )
                                          : const Icon(
                                              Icons.ios_share,
                                              color: Colors.white,
                                              size: 20,
                                            ),
                                    ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: FutureBuilder<AiReading>(
                          future: _readingFuture,
                          builder: (context, snapshot) {
                            if (snapshot.connectionState !=
                                ConnectionState.done) {
                              return _LoadingBody(
                                spreadName: widget.spreadName,
                              );
                            }
                            if (snapshot.hasError) {
                              return _ErrorBody(
                                message: snapshot.error.toString(),
                                onRetry: _retry,
                              );
                            }
                            return _ReadingBody(
                              reading: snapshot.data!,
                              drawnCards: widget.drawnCards,
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                if (_previewBytes != null)
                  _SharePreviewOverlay(
                    imageBytes: _previewBytes!,
                    onClose: _closePreview,
                    onShare: _confirmShare,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// 点分享图标后，先截图预览再决定要不要真的调起系统分享面板——不是点一下
/// 就直接把图丢给分享面板，让用户能先看一眼生成的卡片长什么样。
class _SharePreviewOverlay extends StatelessWidget {
  const _SharePreviewOverlay({
    required this.imageBytes,
    required this.onClose,
    required this.onShare,
  });

  final Uint8List imageBytes;
  final VoidCallback onClose;
  final VoidCallback onShare;

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Container(
        color: Colors.black.withValues(alpha: 0.92),
        child: SafeArea(
          child: Column(
            children: [
              Row(
                children: [
                  const Spacer(),
                  IconButton(
                    onPressed: onClose,
                    icon: const Icon(Icons.close, color: Colors.white),
                  ),
                ],
              ),
              Expanded(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.memory(imageBytes, fit: BoxFit.contain),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(85),
                      ),
                    ),
                    onPressed: onShare,
                    icon: const Icon(Icons.ios_share),
                    label: Text('分享', style: GoogleFonts.inter(fontSize: 16)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LoadingBody extends StatelessWidget {
  const _LoadingBody({required this.spreadName});

  final String spreadName;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(color: Colors.white),
          const SizedBox(height: 16),
          Text(
            '正在为你解读「$spreadName」……',
            style: GoogleFonts.inter(fontSize: 13, color: Colors.white54),
          ),
        ],
      ),
    );
  }
}

class _ErrorBody extends StatelessWidget {
  const _ErrorBody({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: Colors.redAccent, size: 32),
            const SizedBox(height: 12),
            Text(
              '解读失败：$message',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(fontSize: 13, color: Colors.white70),
            ),
            const SizedBox(height: 16),
            OutlinedButton(
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: const BorderSide(color: Colors.white30),
              ),
              onPressed: onRetry,
              child: const Text('重试'),
            ),
          ],
        ),
      ),
    );
  }
}

/// 解读正文——整体印象 + 逐张牌（图片配文字）+ 建议，取代原来那一整段
/// 自由文本。每张牌的图片直接从 [drawnCards] 里按下标取（跟请求时传给
/// Worker 的顺序一致），只有在数量对不上时才退化成纯文字、不显示图片。
class _ReadingBody extends StatelessWidget {
  const _ReadingBody({required this.reading, required this.drawnCards});

  final AiReading reading;
  final List<DrawnCard> drawnCards;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (reading.overview.isNotEmpty) ...[
            _OverviewCard(text: reading.overview),
            const SizedBox(height: 16),
          ],
          for (final entry in reading.cards.asMap().entries)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: _CardSection(
                section: entry.value,
                drawn: entry.key < drawnCards.length
                    ? drawnCards[entry.key]
                    : null,
              ),
            ),
          if (reading.advice.isNotEmpty) _AdviceCard(text: reading.advice),
        ],
      ),
    );
  }
}

class _OverviewCard extends StatelessWidget {
  const _OverviewCard({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return _ReadingCard(
      icon: Icons.auto_awesome,
      child: Text(
        text,
        style: GoogleFonts.inter(
          fontSize: 15,
          height: 1.7,
          fontStyle: FontStyle.italic,
          color: Colors.white,
        ),
      ),
    );
  }
}

class _AdviceCard extends StatelessWidget {
  const _AdviceCard({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return _ReadingCard(
      icon: Icons.tips_and_updates_outlined,
      title: '给你的建议',
      child: Text(
        text,
        style: GoogleFonts.inter(fontSize: 15, height: 1.7, color: Colors.white),
      ),
    );
  }
}

/// 一张牌的解读——左边是这张牌的真实牌面图（逆位会转 180°），右边是
/// 位置/牌名 + Claude 针对这张牌写的那段解读文字。
class _CardSection extends StatelessWidget {
  const _CardSection({required this.section, required this.drawn});

  final AiReadingCardSection section;
  final DrawnCard? drawn;

  static const double _imageWidth = 72;
  static const double _imageHeight = _imageWidth * 1.4;

  @override
  Widget build(BuildContext context) {
    final drawn = this.drawn;
    final headerLabel = drawn?.positionLabel ?? section.positionLabel;
    final headerName = drawn?.card.nameZh ?? section.cardNameZh;
    final orientationLabel = drawn == null
        ? ''
        : (drawn.isReversed ? '逆位' : '正位');
    final header = [
      if (headerLabel.isNotEmpty) headerLabel,
      if (orientationLabel.isNotEmpty) '$headerName（$orientationLabel）' else headerName,
    ].join('：');

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.white.withValues(alpha: 0.12),
            blurRadius: 16,
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (drawn != null) ...[
            _CardThumbnail(drawn: drawn),
            const SizedBox(width: 14),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  header,
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 15,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  section.interpretation,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    height: 1.6,
                    color: Colors.white.withValues(alpha: 0.85),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CardThumbnail extends StatelessWidget {
  const _CardThumbnail({required this.drawn});

  final DrawnCard drawn;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: RotatedBox(
        quarterTurns: drawn.isReversed ? 2 : 0,
        child: Image.asset(
          drawn.card.imagePath,
          width: _CardSection._imageWidth,
          height: _CardSection._imageHeight,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => Container(
            width: _CardSection._imageWidth,
            height: _CardSection._imageHeight,
            color: Colors.white10,
          ),
        ),
      ),
    );
  }
}

/// 整体印象/建议这两块共用的卡片外壳，跟 [_CardSection] 用同一套
/// 视觉语言（圆角、半透明白底、柔光阴影），保持整页排版统一。
class _ReadingCard extends StatelessWidget {
  const _ReadingCard({required this.icon, this.title, required this.child});

  final IconData icon;
  final String? title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.white.withValues(alpha: 0.15),
            blurRadius: 20,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: Colors.white70, size: 18),
              if (title != null) ...[
                const SizedBox(width: 8),
                Text(
                  title!,
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 15,
                    color: Colors.white,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}
