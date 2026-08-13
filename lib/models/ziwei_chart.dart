/// 紫微斗数命盘——排盘结果都是从 Worker 的 `/ziwei-chart` 拿回来的，
/// 排盘本身由 Worker 端的 iztro 库算好（确定性算法，App 这边只管展示），
/// 这些 model 只是把那份 JSON 结构化成 Dart 对象。
class ZiweiChart {
  const ZiweiChart({
    required this.gender,
    required this.solarDate,
    required this.lunarDate,
    required this.chineseDate,
    required this.sign,
    required this.zodiac,
    required this.fiveElementsClass,
    required this.soul,
    required this.body,
    required this.palaces,
    required this.horoscope,
  });

  final String gender;
  final String solarDate;
  final String lunarDate;
  final String chineseDate;
  final String sign;
  final String zodiac;
  final String fiveElementsClass;

  /// 命主星（比如"破军"）。
  final String soul;

  /// 身主星。
  final String body;

  /// 固定 12 个宫位，顺序跟 Worker 返回的一致（不是按传统方位排的，
  /// 展示的时候要按 [ZiweiPalace.earthlyBranch] 去查固定的方位）。
  final List<ZiweiPalace> palaces;

  final ZiweiHoroscope horoscope;

  factory ZiweiChart.fromJson(Map<String, dynamic> json) {
    return ZiweiChart(
      gender: json['gender'] as String? ?? '',
      solarDate: json['solarDate'] as String? ?? '',
      lunarDate: json['lunarDate'] as String? ?? '',
      chineseDate: json['chineseDate'] as String? ?? '',
      sign: json['sign'] as String? ?? '',
      zodiac: json['zodiac'] as String? ?? '',
      fiveElementsClass: json['fiveElementsClass'] as String? ?? '',
      soul: json['soul'] as String? ?? '',
      body: json['body'] as String? ?? '',
      palaces: (json['palaces'] as List? ?? const [])
          .map(
            (e) => ZiweiPalace.fromJson(Map<String, dynamic>.from(e as Map)),
          )
          .toList(),
      horoscope: ZiweiHoroscope.fromJson(
        Map<String, dynamic>.from(json['horoscope'] as Map? ?? const {}),
      ),
    );
  }
}

class ZiweiPalace {
  const ZiweiPalace({
    required this.name,
    required this.heavenlyStem,
    required this.earthlyBranch,
    required this.isBodyPalace,
    required this.isOriginalPalace,
    required this.majorStars,
    required this.minorStars,
    this.decadalRange,
  });

  final String name;
  final String heavenlyStem;

  /// 地支（子丑寅卯……）——命盘里固定 12 宫的方位是按地支排的，跟宫位
  /// 名称（命宫/兄弟……）在不同人的命盘里对应关系不一样。
  final String earthlyBranch;

  final bool isBodyPalace;
  final bool isOriginalPalace;
  final List<ZiweiStar> majorStars;
  final List<ZiweiStar> minorStars;

  /// 大限年龄区间 [起, 止]，没有则为 null。
  final List<int>? decadalRange;

  factory ZiweiPalace.fromJson(Map<String, dynamic> json) {
    return ZiweiPalace(
      name: json['name'] as String? ?? '',
      heavenlyStem: json['heavenlyStem'] as String? ?? '',
      earthlyBranch: json['earthlyBranch'] as String? ?? '',
      isBodyPalace: json['isBodyPalace'] as bool? ?? false,
      isOriginalPalace: json['isOriginalPalace'] as bool? ?? false,
      majorStars: (json['majorStars'] as List? ?? const [])
          .map((e) => ZiweiStar.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(),
      minorStars: (json['minorStars'] as List? ?? const [])
          .map((e) => ZiweiStar.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(),
      decadalRange: json['decadalRange'] == null
          ? null
          : List<int>.from(json['decadalRange'] as List),
    );
  }
}

class ZiweiStar {
  const ZiweiStar({required this.name, this.brightness, this.mutagen});

  final String name;

  /// 庙旺得利平不陷之类的亮度描述，可能为空字符串。
  final String? brightness;

  /// 四化：禄/权/科/忌，可能为空字符串。
  final String? mutagen;

  factory ZiweiStar.fromJson(Map<String, dynamic> json) {
    return ZiweiStar(
      name: json['name'] as String? ?? '',
      brightness: json['brightness'] as String?,
      mutagen: json['mutagen'] as String?,
    );
  }
}

class ZiweiHoroscope {
  const ZiweiHoroscope({
    required this.decadalStem,
    required this.decadalBranch,
    required this.yearlyStem,
    required this.yearlyBranch,
    required this.nominalAge,
  });

  final String decadalStem;
  final String decadalBranch;
  final String yearlyStem;
  final String yearlyBranch;
  final int nominalAge;

  factory ZiweiHoroscope.fromJson(Map<String, dynamic> json) {
    final decadal = Map<String, dynamic>.from(
      json['decadal'] as Map? ?? const {},
    );
    final yearly = Map<String, dynamic>.from(
      json['yearly'] as Map? ?? const {},
    );
    return ZiweiHoroscope(
      decadalStem: decadal['heavenlyStem'] as String? ?? '',
      decadalBranch: decadal['earthlyBranch'] as String? ?? '',
      yearlyStem: yearly['heavenlyStem'] as String? ?? '',
      yearlyBranch: yearly['earthlyBranch'] as String? ?? '',
      nominalAge: json['nominalAge'] as int? ?? 0,
    );
  }
}
