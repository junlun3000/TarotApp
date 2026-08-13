import 'package:flutter/material.dart';

import '../data/draw_service.dart';
import '../data/tarot_card_repository.dart';
import '../models/drawn_card.dart';
import '../models/tarot_card.dart';
import '../models/tarot_spread.dart';
import 'card_detail_screen.dart';

/// 抽牌功能的功能性验证页——只验证数据层/抽牌逻辑跑得通，
/// 不追求视觉还原。等对应页面的 Figma 设计稿到位后，
/// 这里的排版会被替换成正式 UI（数据加载/抽牌逻辑可以直接复用）。
class DrawTestScreen extends StatefulWidget {
  const DrawTestScreen({super.key, this.initialSpread = TarotSpread.single});

  final TarotSpread initialSpread;

  @override
  State<DrawTestScreen> createState() => _DrawTestScreenState();
}

class _DrawTestScreenState extends State<DrawTestScreen> {
  static const _repository = TarotCardRepository();
  final _drawService = DrawService();

  late final Future<List<TarotCard>> _deckFuture;

  late TarotSpread _selectedSpread;
  List<DrawnCard>? _drawnCards;

  @override
  void initState() {
    super.initState();
    _selectedSpread = widget.initialSpread;
    _deckFuture = _repository.loadDeck();
  }

  void _drawCards(List<TarotCard> deck) {
    setState(() {
      _drawnCards = _drawService.draw(deck: deck, spread: _selectedSpread);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(backgroundColor: Colors.black, title: const Text('抽牌测试')),
      body: FutureBuilder<List<TarotCard>>(
        future: _deckFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Text(
                '牌堆加载失败：${snapshot.error}',
                style: const TextStyle(color: Colors.redAccent),
              ),
            );
          }

          final deck = snapshot.data!;
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _SpreadPicker(
                  selected: _selectedSpread,
                  onChanged: (spread) =>
                      setState(() => _selectedSpread = spread),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => _drawCards(deck),
                  child: Text('抽 ${_selectedSpread.cardCount} 张牌'),
                ),
                const SizedBox(height: 16),
                Expanded(child: _DrawResultList(drawnCards: _drawnCards)),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _SpreadPicker extends StatelessWidget {
  const _SpreadPicker({required this.selected, required this.onChanged});

  final TarotSpread selected;
  final ValueChanged<TarotSpread> onChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      children: [
        for (final spread in TarotSpread.all)
          ChoiceChip(
            label: Text(spread.nameZh),
            selected: identical(selected, spread),
            onSelected: (_) => onChanged(spread),
          ),
      ],
    );
  }
}

class _DrawResultList extends StatelessWidget {
  const _DrawResultList({required this.drawnCards});

  final List<DrawnCard>? drawnCards;

  @override
  Widget build(BuildContext context) {
    final cards = drawnCards;
    if (cards == null) {
      return const Center(
        child: Text('还没抽牌', style: TextStyle(color: Colors.white54)),
      );
    }

    return ListView.separated(
      itemCount: cards.length,
      separatorBuilder: (context, index) =>
          const Divider(color: Colors.white24),
      itemBuilder: (context, index) {
        final drawn = cards[index];
        final orientationLabel = drawn.isReversed ? '逆位' : '正位';
        return ListTile(
          title: Text(
            '${drawn.positionLabel ?? ''}：${drawn.card.nameZh}（$orientationLabel）',
            style: const TextStyle(color: Colors.white),
          ),
          subtitle: Text(
            drawn.meaning,
            style: const TextStyle(color: Colors.white70),
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
      },
    );
  }
}
