import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

import '../models/tarot_card.dart';

/// 从本地 JSON 资源加载 78 张塔罗牌数据。
class TarotCardRepository {
  const TarotCardRepository();

  static const _assetPath = 'assets/data/tarot_cards.json';

  Future<List<TarotCard>> loadDeck() async {
    final raw = await rootBundle.loadString(_assetPath);
    final entries = jsonDecode(raw) as List<dynamic>;
    return entries
        .map((entry) => TarotCard.fromJson(entry as Map<String, dynamic>))
        .toList(growable: false);
  }
}
