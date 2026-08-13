import 'package:flutter_test/flutter_test.dart';
import 'package:tarot_app/data/draw_service.dart';
import 'package:tarot_app/data/tarot_card_repository.dart';
import 'package:tarot_app/models/tarot_card.dart';
import 'package:tarot_app/models/tarot_spread.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('TarotCardRepository', () {
    test('loads exactly 78 cards with unique ids', () async {
      final deck = await const TarotCardRepository().loadDeck();

      expect(deck.length, 78);
      expect(deck.map((card) => card.id).toSet().length, 78);
    });

    test('has 22 major arcana and 56 minor arcana split across 4 suits', () async {
      final deck = await const TarotCardRepository().loadDeck();

      final majors = deck.where((card) => card.arcana == Arcana.major);
      final minors = deck.where((card) => card.arcana == Arcana.minor);

      expect(majors.length, 22);
      expect(minors.length, 56);

      for (final suit in Suit.values) {
        expect(minors.where((card) => card.suit == suit).length, 14);
      }
    });
  });

  group('DrawService', () {
    test('draws the exact card count for each spread with no duplicates', () async {
      final deck = await const TarotCardRepository().loadDeck();
      final drawService = DrawService();

      for (final spread in TarotSpread.all) {
        final drawn = drawService.draw(deck: deck, spread: spread);

        expect(drawn.length, spread.cardCount);
        expect(drawn.map((d) => d.card.id).toSet().length, spread.cardCount);
        expect(
          drawn.map((d) => d.positionLabel),
          spread.positionLabels,
        );
      }
    });

    test('throws when the spread needs more cards than the deck has', () {
      final drawService = DrawService();
      const tinyDeck = <TarotCard>[];

      expect(
        () => drawService.draw(deck: tinyDeck, spread: TarotSpread.single),
        throwsArgumentError,
      );
    });
  });
}
