import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

import '../data/card_scan_service.dart';
import '../data/tarot_card_repository.dart';
import '../models/drawn_card.dart';
import '../models/spread_preset.dart';
import '../models/tarot_card.dart';
import '../widgets/background_texture.dart';
import 'draw_result_screen.dart';

/// "扫描实体牌"页——给手上有真实塔罗牌的用户用：不走 App 里的数字随机
/// 抽牌，而是一张一张拍照，让后端 Worker 用 Claude 的视觉能力识别这是
/// 哪张牌、正位还是逆位。凑够牌阵需要的张数之后，走到跟数字抽牌完全
/// 一样的 [DrawResultScreen] / AI 解读流程——两条取牌路径在这里汇合。
///
/// 跟其他页面一样套固定 414x896 画布 + FittedBox 整体缩放。
class CardScanScreen extends StatefulWidget {
  const CardScanScreen({
    super.key,
    required this.preset,
    this.question,
    this.background,
  });

  final SpreadPreset preset;
  final String? question;
  final String? background;

  @override
  State<CardScanScreen> createState() => _CardScanScreenState();
}

class _CardScanScreenState extends State<CardScanScreen> {
  static const _repository = TarotCardRepository();
  static const _scanService = CardScanService();
  final _picker = ImagePicker();

  late final Future<List<TarotCard>> _deckFuture;
  final List<DrawnCard> _scannedCards = [];
  bool _isScanning = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _deckFuture = _repository.loadDeck();
  }

  int get _needed => widget.preset.spread.cardCount;

  String? get _currentPositionLabel {
    final labels = widget.preset.spread.positionLabels;
    return _scannedCards.length < labels.length
        ? labels[_scannedCards.length]
        : null;
  }

  static const double _designWidth = 414;
  static const double _designHeight = 896;
  static const double _cardRadius = 24;

  Future<void> _scan(ImageSource source) async {
    XFile? picked;
    try {
      picked = await _picker.pickImage(source: source, imageQuality: 85);
    } catch (error) {
      setState(() {
        _errorMessage =
            '打不开${source == ImageSource.camera ? "相机" : "相册"}：$error';
      });
      return;
    }
    if (picked == null) return;

    setState(() {
      _isScanning = true;
      _errorMessage = null;
    });

    try {
      final deck = await _deckFuture;
      final bytes = await picked.readAsBytes();
      final result = await _scanService.identifyCard(
        imageBytes: bytes,
        mediaType: _mediaTypeFor(picked.path),
      );

      if (!result.recognized) {
        setState(() {
          _isScanning = false;
          _errorMessage =
              '没认出这张牌${result.notes.isNotEmpty ? "（${result.notes}）" : ""}，'
              '请重新拍一张清楚点的。';
        });
        return;
      }

      TarotCard? card;
      for (final c in deck) {
        if (c.nameZh == result.cardNameZh) {
          card = c;
          break;
        }
      }
      if (card == null) {
        setState(() {
          _isScanning = false;
          _errorMessage = '识别结果（${result.cardNameZh}）在本地牌库里找不到，请重试。';
        });
        return;
      }

      final drawn = DrawnCard(
        card: card,
        orientation: result.isReversed
            ? CardOrientation.reversed
            : CardOrientation.upright,
        positionLabel: _currentPositionLabel,
      );

      final done = _scannedCards.length + 1 == _needed;
      setState(() {
        _scannedCards.add(drawn);
        _isScanning = false;
      });

      if (done) _goToResult();
    } catch (error) {
      setState(() {
        _isScanning = false;
        _errorMessage = '识别失败：$error';
      });
    }
  }

  String _mediaTypeFor(String path) {
    final lower = path.toLowerCase();
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.webp')) return 'image/webp';
    return 'image/jpeg';
  }

  void _goToResult() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => DrawResultScreen(
          preset: widget.preset,
          precomputedCards: List.of(_scannedCards),
          question: widget.question,
          background: widget.background,
        ),
      ),
    );
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
                      const SizedBox(height: 4),
                      Text(
                        '已扫描 ${_scannedCards.length} / $_needed 张',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: Colors.white54,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Expanded(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: Column(
                            children: [
                              if (_scannedCards.isNotEmpty) ...[
                                _ScannedCardStrip(cards: _scannedCards),
                                const SizedBox(height: 24),
                              ],
                              if (_currentPositionLabel != null) ...[
                                Text(
                                  '请拍摄第 ${_scannedCards.length + 1} 张牌'
                                  '（$_currentPositionLabel）',
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.playfairDisplay(
                                    fontSize: 17,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  '把实体牌放在光线充足的地方，尽量正对镜头拍整张牌面',
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    color: Colors.white.withValues(alpha: 0.5),
                                  ),
                                ),
                              ],
                              const SizedBox(height: 24),
                              if (_isScanning)
                                const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 12),
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                  ),
                                )
                              else ...[
                                _ScanButton(
                                  onTap: () => _scan(ImageSource.camera),
                                ),
                                const SizedBox(height: 12),
                                TextButton(
                                  onPressed: () => _scan(ImageSource.gallery),
                                  child: Text(
                                    '从相册选择照片',
                                    style: GoogleFonts.inter(
                                      fontSize: 13,
                                      color: Colors.white70,
                                    ),
                                  ),
                                ),
                              ],
                              if (_errorMessage != null) ...[
                                const SizedBox(height: 16),
                                Text(
                                  _errorMessage!,
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    color: Colors.redAccent,
                                  ),
                                ),
                              ],
                              const SizedBox(height: 24),
                            ],
                          ),
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

class _ScanButton extends StatelessWidget {
  const _ScanButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(85),
        onTap: onTap,
        child: Ink(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(85),
            boxShadow: [
              BoxShadow(color: Colors.white.withValues(alpha: 0.8), blurRadius: 7),
            ],
          ),
          child: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 32, vertical: 14),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.camera_alt_outlined, color: Colors.black, size: 20),
                SizedBox(width: 8),
                Text(
                  '拍照识别',
                  style: TextStyle(fontSize: 16, color: Colors.black),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// 已经扫描成功的牌，按顺序横排小缩略图，逆位会转 180°——跟抽牌结果页
/// 的缩略图是同一套视觉语言。
class _ScannedCardStrip extends StatelessWidget {
  const _ScannedCardStrip({required this.cards});

  final List<DrawnCard> cards;

  static const double _width = 56;
  static const double _height = _width * 1.4;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 10,
      runSpacing: 10,
      children: [
        for (final drawn in cards)
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: RotatedBox(
              quarterTurns: drawn.isReversed ? 2 : 0,
              child: Image.asset(
                drawn.card.imagePath,
                width: _width,
                height: _height,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  width: _width,
                  height: _height,
                  color: Colors.white10,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
