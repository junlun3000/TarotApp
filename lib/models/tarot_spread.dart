/// 一种牌阵：抽几张牌、每个位置代表什么含义。
class TarotSpread {
  const TarotSpread({
    required this.id,
    required this.nameZh,
    required this.positionLabels,
  });

  final String id;
  final String nameZh;
  final List<String> positionLabels;

  int get cardCount => positionLabels.length;

  static const single = TarotSpread(
    id: 'single',
    nameZh: '单张指引',
    positionLabels: ['指引'],
  );

  static const threeCard = TarotSpread(
    id: 'three_card',
    nameZh: '三张牌阵（过去·现在·未来）',
    positionLabels: ['过去', '现在', '未来'],
  );

  static const celticCross = TarotSpread(
    id: 'celtic_cross',
    nameZh: '凯尔特十字',
    positionLabels: [
      '现状',
      '挑战',
      '根基',
      '近期过去',
      '可能结果',
      '近期未来',
      '自身态度',
      '外在影响',
      '希望与恐惧',
      '最终结果',
    ],
  );

  static const nextStep = TarotSpread(
    id: 'next_step',
    nameZh: '下一步',
    positionLabels: ['现状', '阻碍', '建议', '结果'],
  );

  static const partnerRelationship = TarotSpread(
    id: 'partner_relationship',
    nameZh: '伴侣关系',
    positionLabels: ['我的过去', '我的现在', '我的未来', '对方的过去', '对方的现在', '对方的未来'],
  );

  static const moodOfTheDay = TarotSpread(
    id: 'mood_of_the_day',
    nameZh: '今日心情',
    positionLabels: ['早晨', '下午', '晚上'],
  );

  static const loveOracle = TarotSpread(
    id: 'love_oracle',
    nameZh: '爱情神谕',
    positionLabels: ['你', '对方', '关系现状', '发展方向'],
  );

  static const compass = TarotSpread(
    id: 'compass',
    nameZh: '指南针',
    positionLabels: ['北：目标', '东：机会', '南：根基', '西：挑战'],
  );

  // 下面这些都来自《塔罗牌阵大全》整理的 30 个牌阵——位置含义直接照文档
  // 里的表格转录，文档里也提醒过"并非绝对标准，不同流派解释常有差异"，
  // 这里标注的是较主流的通用版本。

  static const goldenDawn = TarotSpread(
    id: 'golden_dawn',
    nameZh: '金色黎明牌阵',
    positionLabels: [
      '问题本质',
      '过去影响',
      '现在状态',
      '未来发展',
      '最佳可能结果',
      '环境/外部力量',
      '内在态度',
      '建议行动',
      '最终结果',
    ],
  );

  static const treeOfLife = TarotSpread(
    id: 'tree_of_life',
    nameZh: '生命之树牌阵',
    positionLabels: [
      '王冠·精神源头',
      '智慧·原始动力',
      '理解·深层洞察',
      '慈悲·扩张机会',
      '严厉·限制挑战',
      '美·核心平衡',
      '胜利·情感欲望',
      '荣耀·理智沟通',
      '基础·潜意识',
      '王国·现实结果',
    ],
  );

  static const horoscope = TarotSpread(
    id: 'horoscope',
    nameZh: '十二宫牌阵',
    positionLabels: [
      '自我/形象',
      '金钱/资源',
      '沟通/学习',
      '家庭/根基',
      '创造/恋爱',
      '健康/日常工作',
      '伴侣关系',
      '转变/共有资源',
      '信念/远行',
      '事业/social地位',
      '朋友/愿望',
      '潜意识/隐藏之事',
    ],
  );

  static const pentagram = TarotSpread(
    id: 'pentagram',
    nameZh: '五角星牌阵',
    positionLabels: ['灵性/目的', '情感状态', '心智/想法', '身体/物质', '整体能量/结果'],
  );

  static const relationship = TarotSpread(
    id: 'relationship',
    nameZh: '关系牌阵',
    positionLabels: [
      '你自己',
      '对方',
      '你对对方的感受',
      '对方对你的感受',
      '关系现状',
      '关系的挑战',
      '关系的潜力/结果',
    ],
  );

  static const decision = TarotSpread(
    id: 'decision',
    nameZh: '决策牌阵',
    positionLabels: [
      '当前处境',
      '选项A',
      '选择A的结果',
      '选项B',
      '选择B的结果',
      '未察觉的因素',
      '最终建议',
    ],
  );

  static const yearAhead = TarotSpread(
    id: 'year_ahead',
    nameZh: '年度运势牌阵',
    positionLabels: [
      '一月',
      '二月',
      '三月',
      '四月',
      '五月',
      '六月',
      '七月',
      '八月',
      '九月',
      '十月',
      '十一月',
      '十二月',
      '全年整体主题',
    ],
  );

  static const starSpread = TarotSpread(
    id: 'star_spread',
    nameZh: '星芒阵',
    positionLabels: ['过去', '现在', '未来', '目标/愿望', '障碍', '外部影响', '最终结果'],
  );

  static const boxSpread = TarotSpread(
    id: 'box_spread',
    nameZh: '箱型牌阵',
    positionLabels: ['过去', '现在', '隐藏影响', '未来', '核心建议'],
  );

  static const mindBodySpirit = TarotSpread(
    id: 'mind_body_spirit',
    nameZh: '身心灵牌阵',
    positionLabels: ['心智/想法', '身体/物质', '灵性/精神'],
  );

  static const yesNo = TarotSpread(
    id: 'yes_no',
    nameZh: '是非阵',
    positionLabels: ['倾向一', '倾向二', '倾向三', '倾向四', '倾向五'],
  );

  static const fiveCardAnalysis = TarotSpread(
    id: 'five_card_analysis',
    nameZh: '问题分析阵',
    positionLabels: ['问题核心', '原因', '现状', '建议', '可能结果'],
  );

  static const weekAhead = TarotSpread(
    id: 'week_ahead',
    nameZh: '星期阵',
    positionLabels: ['周一', '周二', '周三', '周四', '周五', '周六', '周日'],
  );

  static const lovePyramid = TarotSpread(
    id: 'love_pyramid',
    nameZh: '爱情金字塔阵',
    positionLabels: ['你的感受', '对方的感受', '关系的现状', '挑战/障碍', '关系走向'],
  );

  static const careerCross = TarotSpread(
    id: 'career_cross',
    nameZh: '事业十字阵',
    positionLabels: ['当前工作状况', '阻碍/挑战', '你的优势/资源', '需要注意的风险', '未来发展方向'],
  );

  static const healthSpread = TarotSpread(
    id: 'health_spread',
    nameZh: '健康牌阵',
    positionLabels: ['身体状态', '情绪状态', '生活习惯影响', '需要改善之处', '整体建议'],
  );

  static const moneySpread = TarotSpread(
    id: 'money_spread',
    nameZh: '财富牌阵',
    positionLabels: ['当前财务状况', '收入来源/机会', '支出/漏财隐患', '潜在风险', '未来财运走向'],
  );

  static const selfDiscovery = TarotSpread(
    id: 'self_discovery',
    nameZh: '自我认知牌阵',
    positionLabels: ['你如何看待自己', '他人如何看待你', '你内心真实的样子', '你想成为的样子', '达成的关键'],
  );

  static const dreamInterpretation = TarotSpread(
    id: 'dream_interpretation',
    nameZh: '梦境解析牌阵',
    positionLabels: ['梦境的核心象征', '梦境反映的情绪', '梦境与现实的联系', '梦境给出的讯息/建议'],
  );

  static const karmaSpread = TarotSpread(
    id: 'karma_spread',
    nameZh: '过去因果阵',
    positionLabels: ['过去种下的因', '现在承受的果', '该学习的课题', '如何化解/前进方向'],
  );

  static const moonPhase = TarotSpread(
    id: 'moon_phase',
    nameZh: '月相牌阵',
    positionLabels: ['新月·新的开始', '上弦月·遇到的挑战', '满月·高峰结果', '下弦月·释放放下'],
  );

  static const elementalBalance = TarotSpread(
    id: 'elemental_balance',
    nameZh: '元素平衡阵',
    positionLabels: ['火·热情行动力', '水·情感状态', '风·思维沟通', '土·物质现实', '整体平衡建议'],
  );

  static const mandalaSpread = TarotSpread(
    id: 'mandala_spread',
    nameZh: '曼陀罗牌阵',
    positionLabels: ['核心自我', '情感', '事业', '健康', '人际', '财务', '成长', '家庭', '灵性'],
  );

  static const wheelOfLife = TarotSpread(
    id: 'wheel_of_life',
    nameZh: '人生之轮牌阵',
    positionLabels: ['事业', '财务', '健康', '人际关系', '个人成长', '休闲娱乐', '家庭', '灵性/精神生活'],
  );

  static const obstacleSolution = TarotSpread(
    id: 'obstacle_solution',
    nameZh: '障碍与解决阵',
    positionLabels: ['当前处境', '主要障碍', '障碍的根源', '解决方法', '解决后的结果'],
  );

  static const twoPaths = TarotSpread(
    id: 'two_paths',
    nameZh: '两条路牌阵',
    positionLabels: ['当前处境', '路径A', '路径A的结果', '路径B', '路径B的结果', '最终建议'],
  );

  static const miniCelticCross = TarotSpread(
    id: 'mini_celtic_cross',
    nameZh: '迷你凯尔特十字',
    positionLabels: ['现状', '阻碍', '过去', '未来', '建议', '结果'],
  );

  static const all = [
    single,
    threeCard,
    celticCross,
    nextStep,
    partnerRelationship,
    moodOfTheDay,
    loveOracle,
    compass,
    goldenDawn,
    treeOfLife,
    horoscope,
    pentagram,
    relationship,
    decision,
    yearAhead,
    starSpread,
    boxSpread,
    mindBodySpirit,
    yesNo,
    fiveCardAnalysis,
    weekAhead,
    lovePyramid,
    careerCross,
    healthSpread,
    moneySpread,
    selfDiscovery,
    dreamInterpretation,
    karmaSpread,
    moonPhase,
    elementalBalance,
    mandalaSpread,
    wheelOfLife,
    obstacleSolution,
    twoPaths,
    miniCelticCross,
  ];
}
