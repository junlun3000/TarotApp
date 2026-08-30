import 'tarot_spread.dart';

/// "选择牌阵"目录页里每张小卡片的相对位置（行/列坐标，从 0 开始）。
class GridPosition {
  const GridPosition(this.row, this.col);

  final int row;
  final int col;
}

/// 选好牌阵之后要问的一道小问题——给几个常见选项方便快速选，选中最后
/// 那个"其他"才需要自己打字。比一上来就丢一个空白输入框更容易让用户
/// 至少选/填点什么，AI 解读也才有具体信息可用，而不是泛泛而谈。
class IntakeQuestion {
  const IntakeQuestion({required this.prompt, required this.options});

  /// 问题文案。
  final String prompt;

  /// 预设选项，不包含"其他"——"其他"由 UI 统一加在选项列表最后。
  final List<String> options;
}

/// "选择牌阵"目录页里的一个条目：在 [TarotSpread]（抽牌逻辑用的数据）之上
/// 附加分类标签、预览图案和牌阵详情说明，专用于浏览/挑选界面。
class SpreadPreset {
  const SpreadPreset({
    required this.spread,
    required this.category,
    required this.previewLayout,
    required this.predictions,
    required this.typicalQuestions,
    required this.features,
    required this.intakeQuestions,
    this.recommended = false,
  });

  final TarotSpread spread;

  /// 分类标签，对应筛选栏（例如"常规"/"关系"/"未来"）。
  final String category;

  /// 预览图案：几张小卡片在网格里的排布方式。同一套坐标既用于目录页的
  /// 小图标，也用于详情页的编号大图和抽牌结果页的卡片摆放。
  final List<GridPosition> previewLayout;

  /// 可能预测方向。
  final String predictions;

  /// 典型问题示例。
  final List<String> typicalQuestions;

  /// 牌阵特点/适用场景。
  final String features;

  /// 选好这个牌阵之后，[SpreadIntakeScreen] 会问的几个针对性小问题——
  /// 代替原来那个通用的"想问什么"输入框，让 AI 拿到的背景信息更贴合
  /// 这个牌阵本身的主题（比如事业类牌阵问工作状况，感情类问关系阶段）。
  /// 每道题必须选一个选项（或选"其他"并填写）才能继续抽牌。
  final List<IntakeQuestion> intakeQuestions;

  /// 新用户友好、结构简单、上手门槛低的牌阵——牌阵目录页顶部会单独
  /// 标出来推荐给第一次用 App 的人，帮他们不用先看完 35 个牌阵才敢下手。
  final bool recommended;

  String get nameZh => spread.nameZh;
  int get cardCount => spread.cardCount;

  static const categoryRegular = '常规';
  static const categoryRelationship = '关系';
  static const categoryFuture = '未来';
  static const categoryLife = '生活';
  static const categoryMystic = '主题';

  /// 下一步：十字形排布
  static const nextStep = SpreadPreset(
    spread: TarotSpread.nextStep,
    category: categoryRegular,
    previewLayout: [
      GridPosition(0, 1),
      GridPosition(1, 0),
      GridPosition(1, 2),
      GridPosition(2, 1),
    ],
    predictions: '帮助你看清接下来该往哪个方向走，梳理现状、阻碍与建议。',
    typicalQuestions: ['我该怎么做才能达成目标？', '接下来会发生什么？'],
    features: '结构简单直接，适合面对具体选择、需要行动指引时使用。',
    recommended: true,
    intakeQuestions: [
      IntakeQuestion(
        prompt: '现在让你纠结的是哪件事？',
        options: ['感情关系', '工作/学业', '家庭关系', '自我状态与选择'],
      ),
      IntakeQuestion(
        prompt: '你希望通过这次抽牌得到什么样的指引？',
        options: ['该往哪个方向走', '要不要现在行动', '有什么该注意的风险', '单纯想被安慰一下'],
      ),
    ],
  );

  /// 伴侣关系：2 列 x 3 行网格
  static const partnerRelationship = SpreadPreset(
    spread: TarotSpread.partnerRelationship,
    category: categoryRelationship,
    previewLayout: [
      GridPosition(0, 0),
      GridPosition(0, 1),
      GridPosition(1, 0),
      GridPosition(1, 1),
      GridPosition(2, 0),
      GridPosition(2, 1),
    ],
    predictions: '呈现你和对方在关系中的过去、现在与未来。',
    typicalQuestions: ['我们之间的关系走向如何？', '对方对我是什么感觉？'],
    features: '双人对照结构，适合婚恋、伴侣关系类问题。',
    intakeQuestions: [
      IntakeQuestion(
        prompt: '你们现在是什么关系状态？',
        options: ['暧昧期', '稳定恋爱中', '异地恋', '婚姻关系'],
      ),
      IntakeQuestion(
        prompt: '最近你们之间发生了什么让你想问这个问题？',
        options: ['沟通变少/冷战', '意见分歧或争吵', '第三者疑虑', '没有具体事件，只是想了解现状'],
      ),
    ],
  );

  /// 今日心情：一行三张
  static const moodOfTheDay = SpreadPreset(
    spread: TarotSpread.moodOfTheDay,
    category: categoryRegular,
    previewLayout: [GridPosition(0, 0), GridPosition(0, 1), GridPosition(0, 2)],
    predictions: '快速捕捉当下这一天的整体状态与提醒。',
    typicalQuestions: ['今天需要注意什么？', '今天适合做什么？'],
    features: '结构简单，适合每日一抽的轻量使用场景。',
    recommended: true,
    intakeQuestions: [
      IntakeQuestion(
        prompt: '今天有什么特别的安排或者心事吗？',
        options: ['有重要的事要做', '心情有点低落', '纯粹想看看今天的状态', '没什么特别的，随手一抽'],
      ),
    ],
  );

  /// 爱情神谕：菱形排布
  static const loveOracle = SpreadPreset(
    spread: TarotSpread.loveOracle,
    category: categoryRelationship,
    previewLayout: [
      GridPosition(0, 1),
      GridPosition(1, 0),
      GridPosition(1, 2),
      GridPosition(2, 1),
    ],
    predictions: '聚焦感情关系的现状与发展方向。',
    typicalQuestions: ['这段感情会如何发展？', '我们彼此的感觉是什么？'],
    features: '适合恋爱、暧昧期等情感类问题。',
    intakeQuestions: [
      IntakeQuestion(
        prompt: '你们现在是什么阶段？',
        options: ['单身', '单恋/暗恋', '暧昧不明', '恋爱中', '复合期'],
      ),
      IntakeQuestion(
        prompt: '这段感情里最让你困惑的是什么？',
        options: ['不确定对方的心意', '该不该主动', '要不要继续下去', '如何处理矛盾', '还没遇到合适的人，想知道感情什么时候来'],
      ),
    ],
  );

  /// 指南针：一行四张
  static const compass = SpreadPreset(
    spread: TarotSpread.compass,
    category: categoryFuture,
    previewLayout: [
      GridPosition(0, 0),
      GridPosition(0, 1),
      GridPosition(0, 2),
      GridPosition(0, 3),
    ],
    predictions: '从目标、机会、根基、挑战四个方向全面审视当前处境。',
    typicalQuestions: ['我现在的处境如何？', '有哪些机会和挑战？'],
    features: '视角全面，适合需要通盘考虑的复杂问题。',
    intakeQuestions: [
      IntakeQuestion(
        prompt: '你现在面对的是什么处境？',
        options: ['需要做重要决定', '事情太多不知从何下手', '感觉停滞不前', '刚开始一件新事情'],
      ),
      IntakeQuestion(
        prompt: '你希望在这次抽牌里重点看清哪个方向？',
        options: ['目标是否可行', '有什么潜在机会', '有什么风险要留意', '自己的根基是否稳固'],
      ),
    ],
  );

  // 下面是《塔罗牌阵大全》里另外 30 个牌阵——其中凯尔特十字/三张牌阵/单张
  // 指引的抽牌逻辑（[TarotSpread]）本来就有，只是一直没有配上目录页用的
  // SpreadPreset，这里一并补上；其余都是全新牌阵。

  static const celticCross = SpreadPreset(
    spread: TarotSpread.celticCross,
    category: categoryRegular,
    previewLayout: [
      GridPosition(1, 1), // 现状
      GridPosition(1, 1), // 挑战——按传统画法叠压在"现状"牌上
      GridPosition(2, 1), // 根基
      GridPosition(1, 0), // 近期过去
      GridPosition(0, 1), // 可能结果
      GridPosition(1, 2), // 近期未来
      GridPosition(3, 4), // 自身态度
      GridPosition(2, 4), // 外在影响
      GridPosition(1, 4), // 希望与恐惧
      GridPosition(0, 4), // 最终结果
    ],
    predictions: '最经典的十张牌阵，从现状、阻碍到最终结果，全方位剖析整个局面。',
    typicalQuestions: ['这件事整体会如何发展？', '我现在面临的处境是什么？'],
    features: '信息量最大的通用牌阵，适合复杂、多层面的问题。',
    intakeQuestions: [
      IntakeQuestion(
        prompt: '你想深入了解的这件事是什么？',
        options: ['感情关系', '工作事业', '人生方向', '一个具体的决定'],
      ),
      IntakeQuestion(
        prompt: '这件事目前进展到什么阶段了？',
        options: ['刚刚开始', '进行中遇到阻碍', '已经持续很久', '即将有结果'],
      ),
    ],
  );

  static const threeCard = SpreadPreset(
    spread: TarotSpread.threeCard,
    category: categoryRegular,
    previewLayout: [GridPosition(0, 0), GridPosition(0, 1), GridPosition(0, 2)],
    predictions: '梳理一件事从过去到现在再到未来的发展脉络。',
    typicalQuestions: ['这件事接下来会怎么发展？', '我现在的处境是怎么来的？'],
    features: '结构最简单的入门牌阵，几乎什么问题都能用。',
    recommended: true,
    intakeQuestions: [
      IntakeQuestion(
        prompt: '你想问的是哪件事？',
        options: ['感情关系', '工作/学业', '家庭', '自我成长'],
      ),
    ],
  );

  static const single = SpreadPreset(
    spread: TarotSpread.single,
    category: categoryRegular,
    previewLayout: [GridPosition(0, 0)],
    predictions: '给当下最需要知道的一条核心讯息。',
    typicalQuestions: ['今天我需要注意什么？', '现在最重要的是什么？'],
    features: '最快速的抽牌方式，适合日常一抽或想不清楚具体问题的时候。',
    recommended: true,
    intakeQuestions: [
      IntakeQuestion(
        prompt: '有什么具体想问的吗？',
        options: ['感情', '工作', '生活琐事', '没有具体问题，就想抽一张看看'],
      ),
    ],
  );

  static const goldenDawn = SpreadPreset(
    spread: TarotSpread.goldenDawn,
    category: categoryRegular,
    previewLayout: [
      GridPosition(0, 0), GridPosition(0, 1), GridPosition(0, 2),
      GridPosition(1, 0), GridPosition(1, 1), GridPosition(1, 2),
      GridPosition(2, 0), GridPosition(2, 1), GridPosition(2, 2),
    ],
    predictions: '从问题本质出发，梳理过去、现在、未来直到最终结果的完整链条。',
    typicalQuestions: ['这件事的来龙去脉是什么？', '最后会走向哪里？'],
    features: '比三张牌阵更详细的经典进阶牌阵，适合想深入了解一件事全貌时使用。',
    intakeQuestions: [
      IntakeQuestion(
        prompt: '你想深入梳理的是哪件事？',
        options: ['感情关系', '工作事业', '一个重要决定', '人生方向'],
      ),
      IntakeQuestion(
        prompt: '这件事目前处于什么阶段？',
        options: ['刚开始', '进行中', '卡住了', '快有结果了'],
      ),
    ],
  );

  static const treeOfLife = SpreadPreset(
    spread: TarotSpread.treeOfLife,
    category: categoryMystic,
    previewLayout: [
      GridPosition(0, 1),
      GridPosition(1, 2), GridPosition(1, 0),
      GridPosition(2, 2), GridPosition(2, 0),
      GridPosition(3, 1),
      GridPosition(4, 2), GridPosition(4, 0),
      GridPosition(5, 1),
      GridPosition(6, 1),
    ],
    predictions: '借用卡巴拉生命之树的十个质点，从精神源头到现实结果层层展开。',
    typicalQuestions: ['这件事背后更深层的原因是什么？', '我该如何从精神到现实理清这件事？'],
    features: '带有神秘学背景的进阶牌阵，适合喜欢深度、体系化解读的人。',
    intakeQuestions: [
      IntakeQuestion(
        prompt: '你想从精神层面探索的是什么问题？',
        options: ['人生意义与方向', '内在恐惧或阻碍', '天赋与使命', '一段关系的深层意义'],
      ),
      IntakeQuestion(
        prompt: '这件事对你来说意味着什么？',
        options: ['关乎自我认同', '关乎重要的人生选择', '想更了解自己', '单纯的好奇探索'],
      ),
    ],
  );

  static const horoscope = SpreadPreset(
    spread: TarotSpread.horoscope,
    category: categoryMystic,
    previewLayout: [
      GridPosition(0, 0), GridPosition(0, 1), GridPosition(0, 2),
      GridPosition(1, 0), GridPosition(1, 1), GridPosition(1, 2),
      GridPosition(2, 0), GridPosition(2, 1), GridPosition(2, 2),
      GridPosition(3, 0), GridPosition(3, 1), GridPosition(3, 2),
    ],
    predictions: '对照占星十二宫，逐一审视生活的十二个面向。',
    typicalQuestions: ['我这段时间整体运势如何？', '生活里哪些领域需要关注？'],
    features: '牌数较多，适合想做一次全面人生盘点的时候。',
    intakeQuestions: [
      IntakeQuestion(
        prompt: '最近生活里哪个领域让你比较在意？',
        options: ['感情', '事业', '健康', '人际关系'],
      ),
      IntakeQuestion(
        prompt: '有没有什么特别想了解的近期变化？',
        options: ['工作/学业上的变动', '感情状态的变化', '搬家或环境改变', '暂时没有具体变化'],
      ),
    ],
  );

  static const pentagram = SpreadPreset(
    spread: TarotSpread.pentagram,
    category: categoryMystic,
    previewLayout: [
      GridPosition(0, 1),
      GridPosition(1, 0), GridPosition(1, 2),
      GridPosition(2, 0), GridPosition(2, 2),
    ],
    predictions: '从灵性、情感、心智、身体到整体结果，五个层面综合审视。',
    typicalQuestions: ['这件事在各个层面分别是什么状态？', '我该如何达到内外平衡？'],
    features: '强调身心灵整体平衡，适合想跳出单一角度看问题时使用。',
    intakeQuestions: [
      IntakeQuestion(
        prompt: '最近感觉哪方面（身心灵）不太平衡？',
        options: ['情绪起伏大', '身体容易疲惫', '想法很多却难落地', '感觉与自己脱节'],
      ),
    ],
  );

  static const relationship = SpreadPreset(
    spread: TarotSpread.relationship,
    category: categoryRelationship,
    previewLayout: [
      GridPosition(0, 0), GridPosition(0, 2),
      GridPosition(1, 0), GridPosition(1, 2),
      GridPosition(2, 0), GridPosition(2, 1), GridPosition(2, 2),
    ],
    predictions: '拆解你和对方在这段关系里各自的感受、位置与走向。',
    typicalQuestions: ['这段关系接下来会怎么发展？', 'ta是怎么看待我们的关系的？'],
    features: '比爱情神谕更细致的关系类牌阵，双方视角都会照顾到。',
    intakeQuestions: [
      IntakeQuestion(
        prompt: '这段关系是什么类型？',
        options: ['恋人', '朋友', '家人', '合伙人/同事'],
      ),
      IntakeQuestion(
        prompt: '你们之间现在最大的问题是什么？',
        options: ['缺乏沟通', '价值观不一致', '信任问题', '没有明显问题，只是想了解现状'],
      ),
    ],
  );

  static const decision = SpreadPreset(
    spread: TarotSpread.decision,
    category: categoryLife,
    previewLayout: [
      GridPosition(0, 1),
      GridPosition(1, 0), GridPosition(2, 0),
      GridPosition(1, 2), GridPosition(2, 2),
      GridPosition(1, 1),
      GridPosition(3, 1),
    ],
    predictions: '把两个选项分别推演一遍，帮你看清各自的结果。',
    typicalQuestions: ['我该选A还是选B？', '这两个选择分别会带来什么结果？'],
    features: '专门为"二选一"的纠结设计，适合做重要决定前使用。',
    intakeQuestions: [
      IntakeQuestion(
        prompt: '你在纠结的两个选项分别是什么？',
        options: ['两份工作/机会', '留下还是离开', '两个人之间的选择', '做还是不做一件事'],
      ),
      IntakeQuestion(
        prompt: '是什么让你迟迟做不了决定？',
        options: ['怕选错后悔', '两边都有舍不得的地方', '缺乏足够的信息', '身边的人意见不一致'],
      ),
    ],
  );

  static const yearAhead = SpreadPreset(
    spread: TarotSpread.yearAhead,
    category: categoryFuture,
    previewLayout: [
      GridPosition(0, 0), GridPosition(0, 1), GridPosition(0, 2),
      GridPosition(1, 0), GridPosition(1, 1), GridPosition(1, 2),
      GridPosition(2, 0), GridPosition(2, 1), GridPosition(2, 2),
      GridPosition(3, 0), GridPosition(3, 1), GridPosition(3, 2),
      GridPosition(4, 1),
    ],
    predictions: '逐月展开，看清接下来一整年每个月的主题与提醒。',
    typicalQuestions: ['我今年整体运势如何？', '这一年里我该注意什么？'],
    features: '牌数最多的年度总览牌阵，适合年初或生日前后使用。',
    intakeQuestions: [
      IntakeQuestion(
        prompt: '接下来这一年，你最希望在哪方面有进展？',
        options: ['事业与收入', '感情与关系', '健康与状态', '自我成长'],
      ),
    ],
  );

  static const starSpread = SpreadPreset(
    spread: TarotSpread.starSpread,
    category: categoryFuture,
    previewLayout: [
      GridPosition(1, 0), GridPosition(1, 1), GridPosition(1, 2),
      GridPosition(0, 1),
      GridPosition(2, 0), GridPosition(2, 2),
      GridPosition(3, 1),
    ],
    predictions: '从过去现在未来出发，进一步看清目标、障碍与最终结果。',
    typicalQuestions: ['我该如何达成这个目标？', '路上会遇到什么阻碍？'],
    features: '比三张牌阵更进一步，适合已经有明确目标、想知道具体路径时使用。',
    intakeQuestions: [
      IntakeQuestion(
        prompt: '你现在的目标或愿望是什么？',
        options: ['事业上的突破', '一段感情的进展', '完成一个具体项目', '想活得更自在从容'],
      ),
      IntakeQuestion(
        prompt: '达成这个目标最大的顾虑是什么？',
        options: ['能力或资源不够', '外部环境的不确定', '自己容易半途而废', '担心结果不如预期'],
      ),
    ],
  );

  static const boxSpread = SpreadPreset(
    spread: TarotSpread.boxSpread,
    category: categoryRegular,
    previewLayout: [
      GridPosition(0, 0), GridPosition(0, 1),
      GridPosition(1, 0), GridPosition(1, 1),
      GridPosition(2, 1),
    ],
    predictions: '用一个简单的方框结构，梳理过去、现在、隐藏影响与未来。',
    typicalQuestions: ['这件事背后有什么我没注意到的影响？', '接下来会如何发展？'],
    features: '结构清晰好记，适合快速整理一件事的来龙去脉。',
    intakeQuestions: [
      IntakeQuestion(
        prompt: '你想梳理的是哪件事？',
        options: ['感情关系', '工作事业', '一件让你困惑的事', '人生阶段性的状态'],
      ),
    ],
  );

  static const mindBodySpirit = SpreadPreset(
    spread: TarotSpread.mindBodySpirit,
    category: categoryLife,
    previewLayout: [GridPosition(0, 0), GridPosition(0, 1), GridPosition(0, 2)],
    predictions: '分别从心智、身体、灵性三个层面看当下的状态。',
    typicalQuestions: ['我现在整体状态怎么样？', '哪个层面最需要照顾？'],
    features: '适合想做自我状态检查、身心灵整体调频时使用。',
    intakeQuestions: [
      IntakeQuestion(
        prompt: '最近整体状态怎么样？有没有哪方面比较累？',
        options: ['心累，情绪压力大', '身体容易疲惫', '脑子转不停', '整体还算平衡，想确认一下'],
      ),
    ],
  );

  static const yesNo = SpreadPreset(
    spread: TarotSpread.yesNo,
    category: categoryRegular,
    previewLayout: [
      GridPosition(0, 0), GridPosition(0, 1), GridPosition(0, 2),
      GridPosition(0, 3), GridPosition(0, 4),
    ],
    predictions: '通过几张牌的正逆位倾向，给一个相对明确的是/否方向。',
    typicalQuestions: ['这件事能成吗？', '我该不该做这个决定？'],
    features: '适合需要一个相对直接答案的场合，不建议用于特别复杂的问题。',
    intakeQuestions: [
      IntakeQuestion(
        prompt: '你想问的是非题是什么？',
        options: ['这件事能不能成', '要不要主动去做', '对方是不是那个对的人', '现在是不是好时机'],
      ),
    ],
  );

  static const fiveCardAnalysis = SpreadPreset(
    spread: TarotSpread.fiveCardAnalysis,
    category: categoryRegular,
    previewLayout: [
      GridPosition(1, 1),
      GridPosition(0, 1),
      GridPosition(1, 0), GridPosition(1, 2),
      GridPosition(2, 1),
    ],
    predictions: '从问题核心、原因、现状到建议和可能结果，完整分析一件事。',
    typicalQuestions: ['这个问题的根源是什么？', '我该怎么解决它？'],
    features: '结构完整的问题分析牌阵，适合遇到具体困扰时使用。',
    intakeQuestions: [
      IntakeQuestion(
        prompt: '困扰你的具体问题是什么？',
        options: ['感情上的纠结', '工作上的瓶颈', '一个重要决定', '说不清楚，但就是不舒服'],
      ),
      IntakeQuestion(
        prompt: '这个问题已经持续多久了？',
        options: ['最近才开始', '断断续续好一阵子了', '已经持续很久了', '其实是刚发生的事'],
      ),
    ],
  );

  static const weekAhead = SpreadPreset(
    spread: TarotSpread.weekAhead,
    category: categoryFuture,
    previewLayout: [
      GridPosition(0, 0), GridPosition(0, 1), GridPosition(0, 2),
      GridPosition(0, 3), GridPosition(0, 4), GridPosition(0, 5),
      GridPosition(0, 6),
    ],
    predictions: '逐日展开，看清接下来一周每天的主题与能量。',
    typicalQuestions: ['这周我需要注意什么？', '哪几天比较关键？'],
    features: '适合每周开始时做一次整体规划参考。',
    intakeQuestions: [
      IntakeQuestion(
        prompt: '这周有什么特别的安排或者担心的事吗？',
        options: ['有重要的事要处理', '担心某个结果', '只是想规划一下这周', '没什么特别的，随手一抽'],
      ),
    ],
  );

  static const lovePyramid = SpreadPreset(
    spread: TarotSpread.lovePyramid,
    category: categoryRelationship,
    previewLayout: [
      GridPosition(2, 0), GridPosition(2, 1), GridPosition(2, 2),
      GridPosition(1, 1),
      GridPosition(0, 1),
    ],
    predictions: '从双方各自的感受出发，一路推演到关系最终的走向。',
    typicalQuestions: ['ta对这段感情是什么感觉？', '我们这段关系会走向哪里？'],
    features: '聚焦感情类问题，结构比爱情神谕更细致一些。',
    intakeQuestions: [
      IntakeQuestion(
        prompt: '你们现在是什么关系阶段？',
        options: ['单身', '暧昧未定', '稳定交往', '异地或聚少离多', '感情出现裂痕'],
      ),
      IntakeQuestion(
        prompt: '你对这段感情最大的期待或者担忧是什么？',
        options: ['希望关系更进一步', '担心对方不够投入', '担心走向分开', '只是想确认彼此的状态', '想知道自己什么时候会遇到合适的人'],
      ),
    ],
  );

  static const careerCross = SpreadPreset(
    spread: TarotSpread.careerCross,
    category: categoryLife,
    previewLayout: [
      GridPosition(1, 1),
      GridPosition(0, 1),
      GridPosition(1, 0), GridPosition(1, 2),
      GridPosition(2, 1),
    ],
    predictions: '梳理当前工作状况、阻碍、优势与未来发展方向。',
    typicalQuestions: ['我现在的工作/事业怎么样？', '接下来该往哪个方向发展？'],
    features: '专注事业/职场类问题，适合纠结跳槽、转型时使用。',
    intakeQuestions: [
      IntakeQuestion(
        prompt: '你现在的工作/事业状态大概是怎样的？',
        options: ['稳定但缺乏成长', '压力很大', '正在找方向', '刚开始一份新工作'],
      ),
      IntakeQuestion(
        prompt: '最近有没有在考虑什么改变？',
        options: ['跳槽', '转行/创业', '晋升或加薪', '暂时没有具体打算'],
      ),
    ],
  );

  static const healthSpread = SpreadPreset(
    spread: TarotSpread.healthSpread,
    category: categoryLife,
    previewLayout: [
      GridPosition(1, 1),
      GridPosition(0, 1),
      GridPosition(1, 0), GridPosition(1, 2),
      GridPosition(2, 1),
    ],
    predictions: '从身体、情绪、生活习惯到整体建议，综合看待健康状态。',
    typicalQuestions: ['我最近的身体/精神状态怎么样？', '有什么需要注意调整的地方？'],
    features: '偏向自我关照和情绪疏导，不能替代医学诊断，仅供参考。',
    intakeQuestions: [
      IntakeQuestion(
        prompt: '最近身体或情绪上有什么在意的地方？',
        options: ['容易疲惫/睡不好', '情绪起伏比较大', '身体有些小毛病', '整体还好，只是想关注一下'],
      ),
      IntakeQuestion(
        prompt: '有没有什么生活习惯是你想调整的？',
        options: ['作息', '饮食', '运动量', '压力管理'],
      ),
    ],
  );

  static const moneySpread = SpreadPreset(
    spread: TarotSpread.moneySpread,
    category: categoryLife,
    previewLayout: [
      GridPosition(1, 1),
      GridPosition(0, 1),
      GridPosition(1, 0), GridPosition(1, 2),
      GridPosition(2, 1),
    ],
    predictions: '梳理当前财务状况、收入机会、支出隐患与未来财运走向。',
    typicalQuestions: ['我最近的财运怎么样？', '有什么理财上需要注意的？'],
    features: '专注财务类问题，给的是方向性建议，不涉及具体投资操作。',
    intakeQuestions: [
      IntakeQuestion(
        prompt: '最近的财务状况大概是怎样的？',
        options: ['收支比较紧张', '想开始做理财规划', '有一笔投资在犹豫', '整体稳定，想看看趋势'],
      ),
      IntakeQuestion(
        prompt: '有没有具体的收支或投资上的顾虑？',
        options: ['该不该买/该不该投', '担心收入不稳定', '想知道怎么开始理财', '暂时没有具体顾虑'],
      ),
    ],
  );

  static const selfDiscovery = SpreadPreset(
    spread: TarotSpread.selfDiscovery,
    category: categoryLife,
    previewLayout: [
      GridPosition(1, 1),
      GridPosition(0, 1),
      GridPosition(1, 0), GridPosition(1, 2),
      GridPosition(2, 1),
    ],
    predictions: '对照自己眼中的自己、他人眼中的自己，看清真实与理想的差距。',
    typicalQuestions: ['别人是怎么看我的？', '我该如何成为想成为的自己？'],
    features: '偏内省的自我探索牌阵，适合想更了解自己时使用。',
    intakeQuestions: [
      IntakeQuestion(
        prompt: '最近有没有什么让你怀疑自己或者想更了解自己的时刻？',
        options: ['别人的评价和我想的不一样', '不确定自己真正想要什么', '做了让自己意外的选择', '只是单纯想更了解自己'],
      ),
    ],
  );

  static const dreamInterpretation = SpreadPreset(
    spread: TarotSpread.dreamInterpretation,
    category: categoryMystic,
    previewLayout: [
      GridPosition(0, 0), GridPosition(0, 1),
      GridPosition(0, 2), GridPosition(0, 3),
    ],
    predictions: '从梦境的核心象征出发，解读它反映的情绪与给出的讯息。',
    typicalQuestions: ['这个梦在暗示什么？', '这个梦跟我最近的处境有什么关系？'],
    features: '专门用来解读印象深刻的梦境，适合配合具体梦境内容使用。',
    intakeQuestions: [
      IntakeQuestion(
        prompt: '这个梦大概是什么内容？',
        options: ['和某个人有关', '和过去的事情有关', '感觉很不安/害怕', '记不太清细节，但印象很深'],
      ),
      IntakeQuestion(
        prompt: '醒来之后你有什么感觉？',
        options: ['心情沉重', '松了一口气', '困惑不解', '莫名的熟悉感'],
      ),
    ],
  );

  static const karmaSpread = SpreadPreset(
    spread: TarotSpread.karmaSpread,
    category: categoryMystic,
    previewLayout: [
      GridPosition(0, 0), GridPosition(0, 1),
      GridPosition(0, 2), GridPosition(0, 3),
    ],
    predictions: '看清过去种下的因、现在承受的果，以及该学习的课题。',
    typicalQuestions: ['为什么我总是遇到类似的问题？', '这件事我该学到什么？'],
    features: '偏因果/课题视角，适合反复出现的模式或困境。',
    intakeQuestions: [
      IntakeQuestion(
        prompt: '有没有什么反复出现、让你困扰的模式或处境？',
        options: ['总是遇到类似的感情模式', '工作上重复的困境', '和某类人相处总有摩擦', '说不清楚，但确实有种"又来了"的感觉'],
      ),
    ],
  );

  static const moonPhase = SpreadPreset(
    spread: TarotSpread.moonPhase,
    category: categoryMystic,
    previewLayout: [
      GridPosition(0, 0), GridPosition(0, 1),
      GridPosition(0, 2), GridPosition(0, 3),
    ],
    predictions: '对照新月到下弦月的月相周期，看一件事从开始到释放的完整过程。',
    typicalQuestions: ['这件事现在处于哪个阶段？', '我该放下什么、开始什么？'],
    features: '带有月亮魔法色彩的主题牌阵，适合配合月相周期使用。',
    intakeQuestions: [
      IntakeQuestion(
        prompt: '你想开始或者放下的是什么？',
        options: ['一段关系', '一个旧习惯或想法', '一份工作或身份', '还没想清楚，想借这次抽牌理一理'],
      ),
    ],
  );

  static const elementalBalance = SpreadPreset(
    spread: TarotSpread.elementalBalance,
    category: categoryMystic,
    previewLayout: [
      GridPosition(0, 0), GridPosition(0, 1),
      GridPosition(1, 0), GridPosition(1, 1),
      GridPosition(0, 2),
    ],
    predictions: '对照火水风土四元素，看热情、情感、思维、现实各自的状态是否平衡。',
    typicalQuestions: ['我最近哪方面比较失衡？', '该怎么找回整体平衡？'],
    features: '强调四元素能量平衡，适合感觉哪里"不太对劲"却说不清的时候。',
    intakeQuestions: [
      IntakeQuestion(
        prompt: '最近感觉自己哪方面不太对劲？',
        options: ['提不起劲（热情）', '情绪敏感易波动（情感）', '想法很多但混乱（思维）', '金钱/身体有压力（现实）'],
      ),
    ],
  );

  static const mandalaSpread = SpreadPreset(
    spread: TarotSpread.mandalaSpread,
    category: categoryMystic,
    previewLayout: [
      GridPosition(1, 1),
      GridPosition(0, 1), GridPosition(0, 2),
      GridPosition(1, 2), GridPosition(2, 2),
      GridPosition(2, 1), GridPosition(2, 0),
      GridPosition(1, 0), GridPosition(0, 0),
    ],
    predictions: '以核心自我为中心，向外展开情感、事业、健康等各个生活层面。',
    typicalQuestions: ['我生活里各方面现在整体怎么样？', '哪个层面最需要关注？'],
    features: '结构像曼陀罗一样由内而外展开，适合做一次生活全景检视。',
    intakeQuestions: [
      IntakeQuestion(
        prompt: '最近整体生活状态怎么样？',
        options: ['忙碌但充实', '有些迷茫停滞', '压力比较大', '整体平稳，想做个全面检视'],
      ),
    ],
  );

  static const wheelOfLife = SpreadPreset(
    spread: TarotSpread.wheelOfLife,
    category: categoryLife,
    previewLayout: [
      GridPosition(0, 0), GridPosition(0, 1), GridPosition(0, 2), GridPosition(0, 3),
      GridPosition(1, 0), GridPosition(1, 1), GridPosition(1, 2), GridPosition(1, 3),
    ],
    predictions: '逐一审视事业、财务、健康、人际等八大生活领域的现状。',
    typicalQuestions: ['我现在的生活整体平衡吗？', '哪个领域最需要投入精力？'],
    features: '常用于生活教练/自我成长场景，适合定期做整体复盘。',
    intakeQuestions: [
      IntakeQuestion(
        prompt: '生活里哪个领域你最想投入关注？',
        options: ['事业', '感情', '健康', '自我成长'],
      ),
    ],
  );

  static const obstacleSolution = SpreadPreset(
    spread: TarotSpread.obstacleSolution,
    category: categoryRegular,
    previewLayout: [
      GridPosition(1, 1),
      GridPosition(0, 1),
      GridPosition(1, 0), GridPosition(1, 2),
      GridPosition(2, 1),
    ],
    predictions: '找出主要障碍和它的根源，再给出具体的解决方法。',
    typicalQuestions: ['是什么在阻碍我？', '我该怎么解决这个问题？'],
    features: '直接聚焦"卡住的点"，适合明确知道自己遇到障碍、想找方法时使用。',
    intakeQuestions: [
      IntakeQuestion(
        prompt: '具体是什么在阻碍你？',
        options: ['外部环境或他人', '自己的犹豫或恐惧', '资源或能力不足', '还不确定，只知道卡住了'],
      ),
      IntakeQuestion(
        prompt: '你已经尝试过什么办法了吗？',
        options: ['试过沟通/行动但没用', '一直在观望还没行动', '找人商量过', '还没想到办法'],
      ),
    ],
  );

  static const twoPaths = SpreadPreset(
    spread: TarotSpread.twoPaths,
    category: categoryLife,
    previewLayout: [
      GridPosition(0, 1),
      GridPosition(1, 0), GridPosition(2, 0),
      GridPosition(1, 2), GridPosition(2, 2),
      GridPosition(3, 1),
    ],
    predictions: '把两条路径分别推演到各自的结果，再给出最终建议。',
    typicalQuestions: ['走这条路会怎么样？', '两个选择该怎么权衡？'],
    features: '跟决策牌阵类似，结构更完整，多了一步综合建议。',
    intakeQuestions: [
      IntakeQuestion(
        prompt: '你在权衡的两条路分别是什么？',
        options: ['两份工作/机会', '留下还是离开', '两个人之间', '做还是不做一件事'],
      ),
      IntakeQuestion(
        prompt: '现在最大的顾虑是什么？',
        options: ['怕选错后悔', '舍不得放弃任何一边', '信息不够做不了判断', '身边人的看法不一致'],
      ),
    ],
  );

  static const miniCelticCross = SpreadPreset(
    spread: TarotSpread.miniCelticCross,
    category: categoryRegular,
    previewLayout: [
      GridPosition(1, 1), // 现状
      GridPosition(1, 1), // 阻碍——叠压在"现状"牌上
      GridPosition(1, 0), // 过去
      GridPosition(1, 2), // 未来
      GridPosition(0, 1), // 建议
      GridPosition(2, 1), // 结果
    ],
    predictions: '凯尔特十字的简化版，六张牌照样能看清现状、阻碍到结果。',
    typicalQuestions: ['这件事接下来会怎么发展？', '我该怎么应对眼前的阻碍？'],
    features: '比完整凯尔特十字轻量，又比三张牌阵更全面，适合日常深度使用。',
    recommended: true,
    intakeQuestions: [
      IntakeQuestion(
        prompt: '你想了解的这件事是什么？',
        options: ['感情关系', '工作事业', '一个具体决定', '近期的整体状态'],
      ),
      IntakeQuestion(
        prompt: '目前进展到什么阶段了？',
        options: ['刚开始', '遇到阻碍', '持续很久了', '快有结果了'],
      ),
    ],
  );

  static const all = [
    nextStep,
    partnerRelationship,
    moodOfTheDay,
    loveOracle,
    compass,
    celticCross,
    threeCard,
    single,
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

  /// 推荐给新用户的牌阵——牌数少、问题结构简单、门槛低，覆盖日常/单一
  /// 问题/稍完整但依然轻量这三档，让第一次用的人不用先看完全部 35 个
  /// 牌阵才敢下手。
  static final recommendedForNewUsers = all.where((p) => p.recommended).toList();
}
