import '../models/theory_article.dart';

/// "理论"板块的静态教学内容——历史起源、准备工作、占卜流程、注意事项、
/// 牌组架构。内容基于塔罗牌公开的历史事实与通行的入门知识整理，
/// 供初学者了解背景、学习怎么用这套 App 占卜。
class TheoryContent {
  const TheoryContent._();

  static const history = TheoryArticle(
    id: 'history',
    title: '历史起源',
    subtitle: '塔罗牌是怎么来的',
    sections: [
      TheorySection(
        heading: '起源：欧洲的纸牌游戏',
        body:
            '塔罗牌最早出现在 15 世纪意大利，最初只是一种叫"tarocchi"的纸牌游戏，'
            '供当时的贵族娱乐、玩类似桥牌的接龙游戏，跟占卜完全无关。',
      ),
      TheorySection(
        heading: '从游戏到占卜工具',
        body:
            '18 世纪，法国的神秘学者（如库尔·德·热伯林、埃特拉）开始赋予塔罗牌'
            '神秘学意义，声称它源自古埃及智慧——这个说法并没有历史证据支持，'
            '但从那时起，塔罗牌逐渐从游戏变成了占卜与自我探索的工具。',
      ),
      TheorySection(
        heading: '韦特体系奠定现代标准',
        body:
            '1909 年，作家亚瑟·爱德华·韦特与插画师帕梅拉·科尔曼·史密斯合作出版了'
            '"韦特-史密斯"塔罗牌，第一次给全部 78 张牌（包括小阿尔卡那）都画上了'
            '具体的场景插图，而不只是像扑克牌那样的数字花色。这套设计后来成为'
            '影响最广的标准版本——我们 App 里用的牌图，就是基于这套经典设计。',
      ),
    ],
  );

  static const preparation = TheoryArticle(
    id: 'preparation',
    title: '准备工作',
    subtitle: '占卜前该做什么',
    sections: [
      TheorySection(
        heading: '静心',
        body:
            '找一个不被打扰的时刻，做几次深呼吸，让自己从纷杂的思绪里静下来，'
            '再开始占卜——心态浮躁时抽到的牌往往更难看进去。',
      ),
      TheorySection(
        heading: '明确你的问题',
        body:
            '开放式的问题（"我该如何……"、"接下来会怎样……"）通常比"是/否"式'
            '问题能得到更有参考价值的解读，因为塔罗牌本身讲的是"情境"而不是'
            '简单的对错判断。',
      ),
      TheorySection(
        heading: '洗牌与切牌',
        body:
            '如果你用的是实体牌，洗牌时可以在心里默念你的问题，让注意力集中；'
            '在 App 里，"设置问题"这个引导页就是数字化版本的这个仪式——先静心、'
            '带着问题，再进入抽牌。',
      ),
      TheorySection(
        heading: '用非惯用手抽牌',
        body:
            '不少塔罗爱好者习惯用不常用的那只手（比如惯用右手的人改用左手）来'
            '洗牌、抽牌，流传的说法是"非惯用手"更贴近直觉、不受理性思维干扰，'
            '抽到的牌会更贴近真实的第一感应。这更多是民间经验和个人习惯，'
            '并没有严谨的科学证据支持，但不少人确实觉得这样做更有仪式感、'
            '能让自己慢下来、凭直觉去选——如果你想试试，在 App 的"选牌"页'
            '点选卡牌时，也可以特意换成不常用的那只手。',
      ),
    ],
  );

  static const process = TheoryArticle(
    id: 'process',
    title: '占卜流程',
    subtitle: '完整走一遍该怎么做',
    sections: [
      TheorySection(heading: '第一步：设置问题', body: '明确你想问的具体问题，带着这个问题进入抽牌。'),
      TheorySection(
        heading: '第二步：选择牌阵',
        body:
            '根据问题的类型选一个合适的牌阵——简单问题用"下一步"这类少张数的牌阵，'
            '复杂问题可以用"凯尔特十字"这种多位置的牌阵。',
      ),
      TheorySection(heading: '第三步：抽牌', body: '凭直觉从牌堆里选出需要的张数，每张牌对应牌阵里的一个位置。'),
      TheorySection(
        heading: '第四步：逐张解读',
        body: '按牌阵设计的顺序，一张一张看每个位置代表什么、抽到的牌是正位还是逆位。',
      ),
      TheorySection(
        heading: '第五步：综合思考',
        body:
            '最后退一步，把所有牌放在一起看整体的故事线，而不是孤立地理解每一张——'
            '牌与牌之间的关系，往往比单张牌的含义更重要。',
      ),
    ],
  );

  static const precautions = TheoryArticle(
    id: 'precautions',
    title: '注意事项',
    subtitle: '解读时该记住的几件事',
    sections: [
      TheorySection(
        heading: '塔罗是参考，不是定论',
        body:
            '牌面反映的是当下的能量与趋势，不是无法改变的命运——你的选择和行动'
            '仍然会影响结果。',
      ),
      TheorySection(
        heading: '不要用来替代专业建议',
        body:
            '涉及医疗、法律、财务等重大决定时，塔罗牌可以作为参考角度之一，'
            '但不能替代医生、律师、财务顾问等专业人士的意见。',
      ),
      TheorySection(
        heading: '逆位不等于"坏运气"',
        body:
            '逆位通常代表对应的能量被压抑、延迟或需要往内看，而不是简单的"倒霉"——'
            '不用看到逆位就紧张。',
      ),
      TheorySection(
        heading: '尊重他人隐私',
        body: '如果是在为别人占卜，记得尊重对方的隐私和意愿，不要把解读结果强加于人。',
      ),
    ],
  );

  static const structure = TheoryArticle(
    id: 'structure',
    title: '牌组架构',
    subtitle: '78 张牌是怎么分类的',
    sections: [
      TheorySection(
        heading: '22 张大阿尔卡那',
        body:
            '编号 0-21，代表人生里比较宏观、重大的主题与转折（合称"愚人之旅"），'
            '比如"愚人""恋人""死神""世界"这些。',
      ),
      TheorySection(
        heading: '56 张小阿尔卡那',
        body:
            '4 种花色 × 14 张，对应日常生活里更具体的人事物：\n'
            '权杖（火）—— 事业、创造力、行动力\n'
            '圣杯（水）—— 情感、关系、直觉\n'
            '宝剑（风）—— 思维、沟通、冲突\n'
            '星币（土）—— 物质、金钱、现实层面',
      ),
      TheorySection(
        heading: '每个花色的 14 张牌',
        body:
            '数字牌 A（1）到 10，再加 4 张宫廷牌：侍从、骑士、皇后、国王，'
            '宫廷牌通常代表某种性格特质或具体的人。',
      ),
    ],
  );

  static const all = [history, preparation, process, precautions, structure];
}
