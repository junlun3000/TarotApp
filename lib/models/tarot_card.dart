/// 大阿尔卡那 / 小阿尔卡那。
enum Arcana { major, minor }

/// 小阿尔卡那的四种花色。大阿尔卡那没有花色。
enum Suit { wands, cups, swords, pentacles }

/// 一张塔罗牌的静态数据：牌名、图片、关键词、正逆位含义。
/// 不包含抽牌结果（正逆位判定见 [DrawnCard]）。
class TarotCard {
  const TarotCard({
    required this.id,
    required this.nameEn,
    required this.nameZh,
    required this.arcana,
    required this.number,
    required this.imagePath,
    required this.keywords,
    required this.uprightMeaning,
    required this.reversedMeaning,
    this.suit,
  });

  final String id;
  final String nameEn;
  final String nameZh;
  final Arcana arcana;

  /// 大阿尔卡那：0-21。小阿尔卡那：1-10 为数字牌，11=侍从，12=骑士，13=皇后，14=国王。
  final int number;

  final String imagePath;
  final List<String> keywords;
  final String uprightMeaning;
  final String reversedMeaning;

  /// 小阿尔卡那的花色；大阿尔卡那为 null。
  final Suit? suit;

  factory TarotCard.fromJson(Map<String, dynamic> json) {
    return TarotCard(
      id: json['id'] as String,
      nameEn: json['nameEn'] as String,
      nameZh: json['nameZh'] as String,
      arcana: Arcana.values.byName(json['arcana'] as String),
      suit: json['suit'] == null
          ? null
          : Suit.values.byName(json['suit'] as String),
      number: json['number'] as int,
      imagePath: json['imagePath'] as String,
      keywords: List<String>.from(json['keywords'] as List),
      uprightMeaning: json['uprightMeaning'] as String,
      reversedMeaning: json['reversedMeaning'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nameEn': nameEn,
      'nameZh': nameZh,
      'arcana': arcana.name,
      'suit': suit?.name,
      'number': number,
      'imagePath': imagePath,
      'keywords': keywords,
      'uprightMeaning': uprightMeaning,
      'reversedMeaning': reversedMeaning,
    };
  }
}
