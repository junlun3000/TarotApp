/// 十二宫的"人话"说明——原始宫位名（命宫、夫妻宫……）对不懂紫微的
/// 用户来说没有意义，这里给每个宫配一个 emoji + 英文标签 + 一句话说明，
/// 用在命盘详情弹窗和 AI 解读卡片上。
class ZiweiPalaceMeta {
  const ZiweiPalaceMeta({
    required this.emoji,
    required this.englishLabel,
    required this.displayName,
    required this.description,
  });

  final String emoji;
  final String englishLabel;
  final String displayName;
  final String description;

  String get title => '$emoji $englishLabel · $displayName';
}

/// key 用 iztro 原始的宫位名（大部分不带"宫"字，只有命宫例外），
/// 查找时用 contains 匹配，所以能兼容 AI 返回的"命宫（亥）紫微、七杀"
/// 这种带地支/星曜后缀的完整字符串。
const Map<String, ZiweiPalaceMeta> kZiweiPalaceMeta = {
  '命宫': ZiweiPalaceMeta(
    emoji: '🧠',
    englishLabel: 'Personality',
    displayName: '命宫',
    description: '你处理人生与挑战的核心方式',
  ),
  '兄弟': ZiweiPalaceMeta(
    emoji: '🧑‍🤝‍🧑',
    englishLabel: 'Siblings',
    displayName: '兄弟宫',
    description: '兄弟姐妹与同辈关系',
  ),
  '夫妻': ZiweiPalaceMeta(
    emoji: '❤️',
    englishLabel: 'Love',
    displayName: '夫妻宫',
    description: '你的长期关系与伴侣模式',
  ),
  '子女': ZiweiPalaceMeta(
    emoji: '👶',
    englishLabel: 'Children',
    displayName: '子女宫',
    description: '子女与后代，也常延伸看创造力',
  ),
  '财帛': ZiweiPalaceMeta(
    emoji: '💰',
    englishLabel: 'Wealth',
    displayName: '财帛宫',
    description: '你的赚钱方式与财富观',
  ),
  '疾厄': ZiweiPalaceMeta(
    emoji: '🩺',
    englishLabel: 'Health',
    displayName: '疾厄宫',
    description: '身体与压力倾向，不作医学诊断',
  ),
  '迁移': ZiweiPalaceMeta(
    emoji: '🧭',
    englishLabel: 'Travel',
    displayName: '迁移宫',
    description: '外地、海外与外部环境中的表现',
  ),
  '仆役': ZiweiPalaceMeta(
    emoji: '🤝',
    englishLabel: 'Friends',
    displayName: '交友宫',
    description: '朋友、同事与人脉关系',
  ),
  '交友': ZiweiPalaceMeta(
    emoji: '🤝',
    englishLabel: 'Friends',
    displayName: '交友宫',
    description: '朋友、同事与人脉关系',
  ),
  '官禄': ZiweiPalaceMeta(
    emoji: '💼',
    englishLabel: 'Career',
    displayName: '官禄宫',
    description: '你的工作风格与事业发展模式',
  ),
  '田宅': ZiweiPalaceMeta(
    emoji: '🏠',
    englishLabel: 'Home',
    displayName: '田宅宫',
    description: '家庭环境、房产与居住',
  ),
  '福德': ZiweiPalaceMeta(
    emoji: '✨',
    englishLabel: 'Inner Self',
    displayName: '福德宫',
    description: '你的精神世界与真正的满足感',
  ),
  '父母': ZiweiPalaceMeta(
    emoji: '👪',
    englishLabel: 'Elders',
    displayName: '父母宫',
    description: '父母、长辈，也常延伸到上级关系',
  ),
};

ZiweiPalaceMeta? lookupZiweiPalaceMeta(String rawName) {
  for (final entry in kZiweiPalaceMeta.entries) {
    if (rawName.contains(entry.key)) return entry.value;
  }
  return null;
}
