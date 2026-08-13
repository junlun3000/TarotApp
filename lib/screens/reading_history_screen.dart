import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../data/reading_history_repository.dart';
import '../data/tarot_card_repository.dart';
import '../models/drawn_card.dart';
import '../models/reading_history_entry.dart';
import '../models/tarot_card.dart';
import '../widgets/background_texture.dart';
import 'reading_history_detail_screen.dart';

/// "阅读日记"（历史记录）页 —— 还原自 Figma 里的 "Дневник чтений"。
///
/// 每条记录显示日期、当时的问题（如果有）、用的牌阵、抽到的几张牌缩略图，
/// 点"查看详情"能回看那次具体抽到了哪些牌。
class ReadingHistoryScreen extends StatefulWidget {
  const ReadingHistoryScreen({super.key});

  @override
  State<ReadingHistoryScreen> createState() => _ReadingHistoryScreenState();
}

class _ReadingHistoryScreenState extends State<ReadingHistoryScreen> {
  static const double _designWidth = 414;
  static const double _designHeight = 896;
  static const double _cardRadius = 24;

  static const _cardRepository = TarotCardRepository();

  late final Future<List<TarotCard>> _deckFuture;

  @override
  void initState() {
    super.initState();
    _deckFuture = _cardRepository.loadDeck();
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
                                '阅读日记',
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

                            final cardsById = {
                              for (final card in snapshot.data!) card.id: card,
                            };
                            final entries = ReadingHistoryRepository.instance
                                .getAllEntries();

                            if (entries.isEmpty) {
                              return Center(
                                child: Text(
                                  '还没有抽牌记录',
                                  style: GoogleFonts.inter(
                                    color: Colors.white54,
                                  ),
                                ),
                              );
                            }

                            return ListView.separated(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                              ),
                              itemCount: entries.length,
                              separatorBuilder: (context, index) =>
                                  const SizedBox(height: 16),
                              itemBuilder: (context, index) {
                                return _HistoryEntryCard(
                                  entry: entries[index],
                                  cardsById: cardsById,
                                );
                              },
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

class _HistoryEntryCard extends StatelessWidget {
  const _HistoryEntryCard({required this.entry, required this.cardsById});

  final ReadingHistoryEntry entry;
  final Map<String, TarotCard> cardsById;

  String get _formattedDate {
    final d = entry.dateTime;
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(d.day)}/${two(d.month)}/${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            _formattedDate,
            style: GoogleFonts.inter(fontSize: 12, color: Colors.white54),
          ),
          if (entry.question != null) ...[
            const SizedBox(height: 8),
            Text(
              entry.question!,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(fontSize: 14, color: Colors.white),
            ),
          ],
          const SizedBox(height: 16),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            children: [
              for (final cardEntry in entry.cards)
                _MiniCardThumbnail(
                  card: cardsById[cardEntry.cardId],
                  isReversed: cardEntry.orientation == CardOrientation.reversed,
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            entry.spreadNameZh,
            style: GoogleFonts.inter(fontSize: 12, color: Colors.white54),
          ),
          const SizedBox(height: 16),
          OutlinedButton(
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white,
              backgroundColor: Colors.white.withValues(alpha: 0.1),
              side: BorderSide.none,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(85),
              ),
            ),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => ReadingHistoryDetailScreen(
                    entry: entry,
                    cardsById: cardsById,
                  ),
                ),
              );
            },
            child: const Text('查看详情'),
          ),
        ],
      ),
    );
  }
}

class _MiniCardThumbnail extends StatelessWidget {
  const _MiniCardThumbnail({required this.card, required this.isReversed});

  final TarotCard? card;
  final bool isReversed;

  @override
  Widget build(BuildContext context) {
    final card = this.card;
    return Container(
      width: 40,
      height: 56,
      decoration: BoxDecoration(
        color: Colors.white10,
        borderRadius: BorderRadius.circular(4),
      ),
      child: card == null
          ? null
          : ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: Transform.rotate(
                angle: isReversed ? 3.14159 : 0,
                child: Image.asset(
                  card.imagePath,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) =>
                      const SizedBox.shrink(),
                ),
              ),
            ),
    );
  }
}
