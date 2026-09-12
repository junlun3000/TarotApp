import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../data/tarot_card_repository.dart';
import '../models/tarot_card.dart';
import '../widgets/background_texture.dart';
import '../widgets/responsive_app_shell.dart';
import 'card_detail_screen.dart';

/// "完整牌意"页 —— 按大阿尔卡那/四个花色分组，浏览全部 78 张牌，
/// 点任意一张跳到它的详情页（复用已有的 [CardDetailScreen]）。
///
/// 跟其他页面一样套固定 414x896 画布 + FittedBox 整体缩放。
class CardIndexScreen extends StatefulWidget {
  const CardIndexScreen({super.key});

  @override
  State<CardIndexScreen> createState() => _CardIndexScreenState();
}

class _CardIndexScreenState extends State<CardIndexScreen> {
  static const double _designWidth = 414;
  static const double _designHeight = 896;
  static const double _cardRadius = 24;

  static const _repository = TarotCardRepository();
  late final Future<List<TarotCard>> _deckFuture;

  @override
  void initState() {
    super.initState();
    _deckFuture = _repository.loadDeck();
  }

  static const _suitLabels = {
    Suit.wands: '权杖',
    Suit.cups: '圣杯',
    Suit.swords: '宝剑',
    Suit.pentacles: '星币',
  };

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
                                '完整牌意',
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
                      const SizedBox(height: 8),
                      Expanded(
                        child: FutureBuilder<List<TarotCard>>(
                          future: _deckFuture,
                          builder: (context, snapshot) {
                            if (snapshot.connectionState !=
                                ConnectionState.done) {
                              return const Center(
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                ),
                              );
                            }

                            final deck = snapshot.data!;
                            final majors =
                                deck
                                    .where((c) => c.arcana == Arcana.major)
                                    .toList()
                                  ..sort(
                                    (a, b) => a.number.compareTo(b.number),
                                  );

                            return ListView(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 8,
                              ),
                              children: [
                                _GroupHeader(title: '大阿尔卡那 (${majors.length})'),
                                for (final card in majors)
                                  _CardListTile(card: card),
                                for (final suit in Suit.values) ...[
                                  _GroupHeader(
                                    title: '${_suitLabels[suit]}（小阿尔卡那）',
                                  ),
                                  for (final card
                                      in deck
                                          .where((c) => c.suit == suit)
                                          .toList()
                                        ..sort(
                                          (a, b) =>
                                              a.number.compareTo(b.number),
                                        ))
                                    _CardListTile(card: card),
                                ],
                              ],
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

class _GroupHeader extends StatelessWidget {
  const _GroupHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Text(
        title,
        style: GoogleFonts.inter(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: Colors.white38,
        ),
      ),
    );
  }
}

class _CardListTile extends StatelessWidget {
  const _CardListTile({required this.card});

  final TarotCard card;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: SizedBox(
        width: 32,
        height: 32 * 1.4,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: Image.asset(
            card.imagePath,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) =>
                Container(color: Colors.white10),
          ),
        ),
      ),
      title: Text(
        card.nameZh,
        style: GoogleFonts.inter(fontSize: 14, color: Colors.white),
      ),
      trailing: const Icon(Icons.chevron_right, color: Colors.white38),
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (context) => CardDetailScreen(card: card)),
        );
      },
    );
  }
}
