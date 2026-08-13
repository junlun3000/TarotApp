// Cloudflare Worker —— 代理转发到 Anthropic API，Flutter App 不直接持有
// API key（客户端代码里放 key 会被反编译拿走）。
//
// 部署后需要设置密钥（千万不要把真实 key 写进这个文件或提交到 git）：
//   npx wrangler secret put ANTHROPIC_API_KEY

import { astro } from 'iztro';

const ANTHROPIC_MODEL = 'claude-sonnet-5';
const ANTHROPIC_API_VERSION = '2023-06-01';

// 韦特塔罗标准 78 张牌的中文名——用户拍实体牌识别时，Claude 的回答必须
// 从这个列表里选一个（塞进 JSON schema 的 enum），保证识别结果一定能
// 对上 App 本地的牌面数据，不会出现"愚者"/"愚人"这种同义词对不上的问题。
const CARD_NAMES = [
  '愚人', '魔术师', '女祭司', '女皇', '皇帝', '教皇', '恋人', '战车', '力量',
  '隐士', '命运之轮', '正义', '倒吊人', '死神', '节制', '恶魔', '塔', '星星',
  '月亮', '太阳', '审判', '世界',
  '权杖A', '权杖二', '权杖三', '权杖四', '权杖五', '权杖六', '权杖七', '权杖八',
  '权杖九', '权杖十', '权杖侍从', '权杖骑士', '权杖皇后', '权杖国王',
  '圣杯A', '圣杯二', '圣杯三', '圣杯四', '圣杯五', '圣杯六', '圣杯七', '圣杯八',
  '圣杯九', '圣杯十', '圣杯侍从', '圣杯骑士', '圣杯皇后', '圣杯国王',
  '宝剑A', '宝剑二', '宝剑三', '宝剑四', '宝剑五', '宝剑六', '宝剑七', '宝剑八',
  '宝剑九', '宝剑十', '宝剑侍从', '宝剑骑士', '宝剑皇后', '宝剑国王',
  '星币A', '星币二', '星币三', '星币四', '星币五', '星币六', '星币七', '星币八',
  '星币九', '星币十', '星币侍从', '星币骑士', '星币皇后', '星币国王',
];

// 识别实体牌照片用的结构化输出 schema。
const IDENTIFY_CARD_SCHEMA = {
  type: 'object',
  properties: {
    recognized: {
      type: 'boolean',
      description: '能不能有把握地看清这是哪张塔罗牌',
    },
    cardNameZh: {
      type: 'string',
      enum: CARD_NAMES,
      description: '识别出的牌名，即使不确定也要给出最接近的猜测',
    },
    orientation: {
      type: 'string',
      enum: ['upright', 'reversed'],
      description: '正位还是逆位——看牌面图案本身是否上下颠倒，不是拍照角度',
    },
    notes: {
      type: 'string',
      description:
        'recognized 为 false 时，简要说明原因（比如照片模糊、光线太暗、不像塔罗牌）；recognized 为 true 时可以留空字符串',
    },
  },
  required: ['recognized', 'cardNameZh', 'orientation', 'notes'],
  additionalProperties: false,
};

// 结构化输出的 schema —— 让 Claude 直接把解读拆成"整体印象 / 逐张牌解读 /
// 建议"三块返回，而不是一整段自由文本。这样 Flutter 端才能把每张牌的图片
// 跟它自己的那段解读文字精确配对展示，不用再靠正则去猜文本里提到了哪张牌。
const READING_SCHEMA = {
  type: 'object',
  properties: {
    themeTitle: {
      type: 'string',
      description:
        '用 3-4 个词概括整个牌阵的核心主题，顿号分隔，比如"行动、规划、匮乏"，8-12 字以内，给分享卡片当标题用',
    },
    overview: {
      type: 'string',
      description: '整体印象，2-3 句，点出这次牌阵传达的核心情绪或主题',
    },
    cards: {
      type: 'array',
      description: '按输入牌面顺序，每张牌一条，不要遗漏也不要调换顺序',
      items: {
        type: 'object',
        properties: {
          positionLabel: {
            type: 'string',
            description: '原样带回这张牌在牌阵中的位置标签',
          },
          cardNameZh: {
            type: 'string',
            description: '原样带回这张牌的中文名',
          },
          keywordCore: {
            type: 'string',
            description:
              '3-4 个词概括这张牌在这个位置的核心特质，顿号分隔，不是完整句子，比如"说话鲁莽、情绪急躁、缺乏条理"',
          },
          interpretation: {
            type: 'string',
            description:
              '这张牌本身的画面/象征意义，结合占卜者的问题和处境展开具体解读，3-5 句，讲故事的语气，紧扣这张牌的实际含义',
          },
        },
        required: [
          'positionLabel',
          'cardNameZh',
          'keywordCore',
          'interpretation',
        ],
        additionalProperties: false,
      },
    },
    advice: {
      type: 'string',
      description: '结合整体牌面的简短、可执行建议',
    },
  },
  required: ['themeTitle', 'overview', 'cards', 'advice'],
  additionalProperties: false,
};

export default {
  async fetch(request, env) {
    if (request.method === 'OPTIONS') {
      return new Response(null, { headers: corsHeaders() });
    }

    if (request.method !== 'POST') {
      return jsonResponse({ error: 'Only POST is supported' }, 405);
    }

    const { pathname } = new URL(request.url);
    if (pathname === '/identify-card') {
      return handleIdentifyCard(request, env);
    }
    if (pathname === '/ziwei-chart') {
      return handleZiweiChart(request, env);
    }
    if (pathname === '/ziwei-reading') {
      return handleZiweiReading(request, env);
    }
    return handleGenerateReading(request, env);
  },
};

async function handleGenerateReading(request, env) {
  let body;
  try {
    body = await request.json();
  } catch (err) {
    return jsonResponse({ error: 'Invalid JSON body' }, 400);
  }

  const { question, background, spreadName, cards } = body ?? {};
  if (!Array.isArray(cards) || cards.length === 0) {
    return jsonResponse({ error: 'cards must be a non-empty array' }, 400);
  }

  const prompt = buildPrompt({ question, background, spreadName, cards });

  // 跟紫微那边遇到的是同一类问题：Sonnet 5 默认开自适应思考，有时会把
  // 大部分 token 预算耗在 thinking 上，导致正文 JSON 写到一半被截断；
  // 也可能在预算够用的情况下自己提前 end_turn。这里同样关闭 thinking、
  // 校验结果完整性，不完整就重试一次。
  let reading;
  let lastError;
  for (let attempt = 0; attempt < 2 && !reading; attempt++) {
    const { data, error } = await callAnthropic(env, {
      model: ANTHROPIC_MODEL,
      max_tokens: 3000,
      thinking: { type: 'disabled' },
      output_config: { format: { type: 'json_schema', schema: READING_SCHEMA } },
      messages: [{ role: 'user', content: prompt }],
    });
    if (error) {
      lastError = error;
      continue;
    }

    const text = firstTextBlock(data);
    let parsed;
    try {
      parsed = JSON.parse(text);
    } catch (err) {
      lastError = jsonResponse({ error: `Failed to parse structured reading: ${err}` }, 502);
      continue;
    }

    const isComplete =
      Array.isArray(parsed.cards) &&
      parsed.cards.length === cards.length &&
      parsed.cards.every((c) => c.interpretation?.trim() && c.keywordCore?.trim()) &&
      parsed.themeTitle?.trim() &&
      parsed.overview?.trim() &&
      parsed.advice?.trim();
    if (!isComplete) {
      lastError = jsonResponse({ error: '解读没有写完整，请重试' }, 502);
      continue;
    }

    reading = parsed;
  }
  if (!reading) return lastError;

  return jsonResponse({ reading });
}

async function handleIdentifyCard(request, env) {
  let body;
  try {
    body = await request.json();
  } catch (err) {
    return jsonResponse({ error: 'Invalid JSON body' }, 400);
  }

  const { imageBase64, mediaType } = body ?? {};
  if (!imageBase64 || typeof imageBase64 !== 'string') {
    return jsonResponse({ error: 'imageBase64 is required' }, 400);
  }
  const allowedMediaTypes = ['image/jpeg', 'image/png', 'image/webp'];
  const resolvedMediaType = allowedMediaTypes.includes(mediaType)
    ? mediaType
    : 'image/jpeg';

  const prompt = `你是一位塔罗牌图像识别助手。图片是用户拍的一张实体塔罗牌照片（韦特塔罗 Rider-Waite 牌组），请识别：
1. 这是牌组里的哪一张牌——只能从下面这个列表里选一个，不要自己编名字：
${CARD_NAMES.join('、')}
2. 正位还是逆位——看牌面图案本身是不是上下颠倒（倒着印刷/倒着抽出来），不是看拍照时手机拿正了没有。

如果照片模糊、光线太暗、构图问题看不清楚具体是哪张牌，或者这张照片根本不像塔罗牌，把 recognized 设为 false，并在 notes 里用一句话说明原因；cardNameZh 和 orientation 这两个字段依然要填一个你觉得最接近的猜测，不能留空。如果识别有把握，recognized 设为 true，notes 留空字符串即可。`;

  const { data, error } = await callAnthropic(env, {
    model: ANTHROPIC_MODEL,
    max_tokens: 500,
    thinking: { type: 'disabled' },
    output_config: {
      format: { type: 'json_schema', schema: IDENTIFY_CARD_SCHEMA },
    },
    messages: [
      {
        role: 'user',
        content: [
          {
            type: 'image',
            source: {
              type: 'base64',
              media_type: resolvedMediaType,
              data: imageBase64,
            },
          },
          { type: 'text', text: prompt },
        ],
      },
    ],
  });
  if (error) return error;

  const text = firstTextBlock(data);
  let result;
  try {
    result = JSON.parse(text);
  } catch (err) {
    return jsonResponse({ error: `Failed to parse identify result: ${err}` }, 502);
  }

  return jsonResponse({ result });
}

// 紫微斗数用 iztro 这个开源库排盘（星曜怎么落到哪个宫位是一套严格的
// 古法算法，不能交给 Claude 现场编——排盘必须是确定性的，Claude 只负责
// 基于排好的命盘写解读文字）。timeIndex 是传统十二时辰的下标：
// 0=早子时(23:00-01:00) 1=丑时 2=寅时 ... 11=亥时(21:00-23:00)。
function computeAstrolabe({ birthDate, timeIndex, gender }) {
  const astrolabe = astro.astrolabeBySolarDate(
    birthDate,
    timeIndex,
    gender === 'female' ? 'female' : 'male',
  );
  const horoscope = astrolabe.horoscope(new Date());

  const palaces = astrolabe.palaces.map((p) => ({
    name: p.name,
    heavenlyStem: p.heavenlyStem,
    earthlyBranch: p.earthlyBranch,
    isBodyPalace: p.isBodyPalace,
    isOriginalPalace: p.isOriginalPalace,
    majorStars: p.majorStars.map((s) => ({
      name: s.name,
      brightness: s.brightness,
      mutagen: s.mutagen,
    })),
    minorStars: p.minorStars.map((s) => ({ name: s.name })),
    decadalRange: p.decadal?.range ?? null,
  }));

  return {
    gender: astrolabe.gender,
    solarDate: astrolabe.solarDate,
    lunarDate: astrolabe.lunarDate,
    chineseDate: astrolabe.chineseDate,
    sign: astrolabe.sign,
    zodiac: astrolabe.zodiac,
    fiveElementsClass: astrolabe.fiveElementsClass,
    soul: astrolabe.soul,
    body: astrolabe.body,
    palaces,
    horoscope: {
      decadal: {
        heavenlyStem: horoscope.decadal.heavenlyStem,
        earthlyBranch: horoscope.decadal.earthlyBranch,
      },
      yearly: {
        heavenlyStem: horoscope.yearly.heavenlyStem,
        earthlyBranch: horoscope.yearly.earthlyBranch,
      },
      nominalAge: horoscope.age.nominalAge,
    },
  };
}

async function handleZiweiChart(request, env) {
  let body;
  try {
    body = await request.json();
  } catch (err) {
    return jsonResponse({ error: 'Invalid JSON body' }, 400);
  }

  const { birthDate, timeIndex, gender } = body ?? {};
  const validationError = validateBirthInfo({ birthDate, timeIndex, gender });
  if (validationError) return jsonResponse({ error: validationError }, 400);

  try {
    const chart = computeAstrolabe({ birthDate, timeIndex, gender });
    return jsonResponse({ chart });
  } catch (err) {
    return jsonResponse({ error: `排盘失败：${err}` }, 500);
  }
}

function validateBirthInfo({ birthDate, timeIndex, gender }) {
  if (typeof birthDate !== 'string' || !/^\d{4}-\d{1,2}-\d{1,2}$/.test(birthDate)) {
    return 'birthDate must be a YYYY-MM-DD string';
  }
  if (!Number.isInteger(timeIndex) || timeIndex < 0 || timeIndex > 11) {
    return 'timeIndex must be an integer between 0 and 11';
  }
  if (gender !== 'male' && gender !== 'female') {
    return "gender must be 'male' or 'female'";
  }
  return null;
}

const ZIWEI_READING_SCHEMA = {
  type: 'object',
  properties: {
    overview: {
      type: 'string',
      description: '整体性格/命格印象，2-4 句，点出命主的核心特质和命盘基调',
    },
    fourTransformations: {
      type: 'string',
      description: '找出命盘里带"化禄""化权""化科""化忌"标记的星曜分别落在哪些宫位，说清楚这四化具体会怎样影响命主（比如化权落在事业宫代表工作上有主导欲和话语权，化忌落在哪个宫要提醒命主注意什么），3-5 句，只根据命盘里实际标出的四化来写，不要自己另外推算',
    },
    palaces: {
      type: 'array',
      description: '挑命盘里最重要、最有信息量、跟命主问题最相关的宫位来解读，必须正好是 6 到 8 个，不用十二宫全部展开；命宫、夫妻宫、身宫所在的宫位必须都包含在内',
      items: {
        type: 'object',
        properties: {
          name: { type: 'string', description: '宫位名称，原样带回' },
          interpretation: {
            type: 'string',
            description: '这个宫位里的星曜组合具体意味着什么，结合命主的问题/背景展开，尽量给出具体、可辨认的画像或人生轨迹例子（而不是空泛描述），4-6 句',
          },
        },
        required: ['name', 'interpretation'],
        additionalProperties: false,
      },
    },
    lifeStages: {
      type: 'string',
      description: '依据命盘里每个宫位自带的大限年龄区间数据（不要自己推算天干阳男阴女顺逆行这些规则，直接用给到的数字），简要列出命主几岁到几岁分别行经哪个宫位的大限，说明这是命主人生阶段的整体脉络，2-3 句',
    },
    currentFortune: {
      type: 'string',
      description: '结合命主当前所在的大限宫位和流年，重点说说这个阶段的运势主题和意义，可以结合命主的问题让解读更贴合，3-5 句',
    },
    advice: {
      type: 'string',
      description: '结合整体命盘和当前运势，给一段简短、可执行的建议',
    },
    keySummary: {
      type: 'string',
      description: '把整个命盘浓缩成一两句总结性的人物画像（可以用"XX坐命，XX坐事业……"这种格式），然后各用一句话点出命主最大的优势和最大的风险/课题，2-4 句',
    },
  },
  required: [
    'overview',
    'fourTransformations',
    'palaces',
    'lifeStages',
    'currentFortune',
    'advice',
    'keySummary',
  ],
  additionalProperties: false,
};

async function handleZiweiReading(request, env) {
  let body;
  try {
    body = await request.json();
  } catch (err) {
    return jsonResponse({ error: 'Invalid JSON body' }, 400);
  }

  const { birthDate, timeIndex, gender, question, background } = body ?? {};
  const validationError = validateBirthInfo({ birthDate, timeIndex, gender });
  if (validationError) return jsonResponse({ error: validationError }, 400);

  let chart;
  try {
    chart = computeAstrolabe({ birthDate, timeIndex, gender });
  } catch (err) {
    return jsonResponse({ error: `排盘失败：${err}` }, 500);
  }

  const prompt = buildZiweiPrompt({ chart, question, background });

  // 模型偶尔会在写完 overview 后就提前 end_turn，留下空的
  // currentFortune/advice 或只写 1-2 个宫位——不是 token 预算问题（很多
  // token 没用完），是模型自己判断"够了"判断错了。这种情况重试一次通常
  // 就好，所以这里最多尝试 2 次，两次都不完整才把错误交给前端重试按钮。
  let reading;
  let lastError;
  for (let attempt = 0; attempt < 2 && !reading; attempt++) {
    const { data, error } = await callAnthropic(env, {
      model: ANTHROPIC_MODEL,
      max_tokens: 8000,
      thinking: { type: 'disabled' },
      output_config: {
        format: { type: 'json_schema', schema: ZIWEI_READING_SCHEMA },
      },
      messages: [{ role: 'user', content: prompt }],
    });
    if (error) {
      lastError = error;
      continue;
    }

    const text = firstTextBlock(data);
    let parsed;
    try {
      parsed = JSON.parse(text);
    } catch (err) {
      lastError = jsonResponse({ error: `Failed to parse structured reading: ${err}` }, 502);
      continue;
    }

    const isComplete =
      Array.isArray(parsed.palaces) &&
      parsed.palaces.length >= 5 &&
      parsed.fourTransformations?.trim() &&
      parsed.lifeStages?.trim() &&
      parsed.currentFortune?.trim() &&
      parsed.advice?.trim() &&
      parsed.keySummary?.trim();
    if (!isComplete) {
      lastError = jsonResponse({ error: '解读没有写完整，请重试' }, 502);
      continue;
    }

    reading = parsed;
  }
  if (!reading) return lastError;

  return jsonResponse({ chart, reading });
}

function buildZiweiPrompt({ chart, question, background }) {
  const palaceLines = chart.palaces
    .map((p) => {
      const majors = p.majorStars
        .map((s) => `${s.name}${s.brightness ? `(${s.brightness})` : ''}${s.mutagen ? `[化${s.mutagen}]` : ''}`)
        .join('、');
      const minors = p.minorStars.map((s) => s.name).join('、');
      const tags = [p.isBodyPalace ? '身宫' : null, p.isOriginalPalace ? '来因宫' : null]
        .filter(Boolean)
        .join('/');
      const decadal = p.decadalRange ? `，大限 ${p.decadalRange[0]}-${p.decadalRange[1]} 岁` : '';
      return `${p.name}宫（${p.earthlyBranch}）${tags ? `[${tags}]` : ''}：主星 ${majors || '无主星'}${minors ? `，辅星 ${minors}` : ''}${decadal}`;
    })
    .join('\n');

  return `你是一位专业、温暖但不故弄玄虚的紫微斗数命理师。命盘是用标准排盘算法算好的，你只负责基于这份命盘写解读，不要自己判断或调整星曜落宫。

命主：${chart.gender === '女' ? '女' : '男'}性，${chart.solarDate}（农历${chart.lunarDate}，${chart.chineseDate}）
命宫主星：${chart.soul}　身宫主星：${chart.body}　五行局：${chart.fiveElementsClass}　星座：${chart.sign}　生肖：${chart.zodiac}
${question ? `命主想问的问题：${question}` : ''}
${background ? `命主的背景/近况：${background}` : ''}

命盘十二宫：
${palaceLines}

当前运势：大限 ${chart.horoscope.decadal.heavenlyStem}${chart.horoscope.decadal.earthlyBranch}，流年 ${chart.horoscope.yearly.heavenlyStem}${chart.horoscope.yearly.earthlyBranch}，虚岁 ${chart.horoscope.nominalAge} 岁

请按给定的 JSON 结构返回，其中：
1. overview：先综合整体命盘给出性格/命格的整体印象
2. fourTransformations：命盘里每颗星后面标了 [化X] 的就是四化——找出命盘里的化禄、化权、化科、化忌分别落在哪个宫位，说清楚这对命主具体意味着什么。只根据命盘数据里实际出现的四化标记来写，如果某个化没有出现在命盘里就不用提
3. palaces：从十二宫里挑 6-8 个最有信息量、跟命主问题最相关的宫位解读，命宫、夫妻宫、身宫所在的宫位这三个必选（夫妻宫是感情婚姻的核心宫位，不管命主问的是不是感情问题都要包含，让ta始终能看到自己的感情面）。先按命主问题/背景锁定核心组合，再从关联宫位里补足到 6-8 个，让整体解读覆盖到不同的人生面向，不要挤在同一类宫位里重复：
   - 事业/学业相关 → 核心：命宫+官禄宫+财帛宫+迁移宫；再从 福德宫（工作状态与内心满足感）/交友宫（人脉、合作、贵人）/田宅宫（大环境稳定性）/父母宫（上级、长辈关系）里补充
   - 感情/婚姻相关 → 核心：命宫+夫妻宫+福德宫；再从 子女宫（亲密关系深化）/田宅宫（家庭生活）/交友宫（社交圈对姻缘的影响）/疾厄宫（情绪状态）里补充
   - 财务/理财相关 → 核心：命宫+财帛宫+田宅宫；再从 官禄宫（收入来源）/福德宫（金钱观、花钱心态）/迁移宫（外部财运机会）/子女宫（投资、副业）里补充
   - 健康/压力相关 → 核心：命宫+疾厄宫+福德宫；再从 父母宫（先天体质）/田宅宫（生活环境）/夫妻宫（情感状态对身心的影响）/迁移宫（环境变化）里补充
   - 人际/合作相关 → 核心：命宫+交友宫（仆役宫）+官禄宫；再从 兄弟宫（同辈合作）/父母宫（上级、长辈关系）/夫妻宫（亲密关系相处模式）/迁移宫（社交圈拓展）里补充
   如果问题不明确或比较综合，就按信息量选最值得展开的 6-8 个宫位，尽量覆盖不同面向。

   每个宫位的解读要落到具体、可辨认的画像上，不要只停留在"容易有摩擦""需要耐心"这种空泛描述，尽量给一个具体的人生轨迹或场景例子。先回答这个宫位对应的具体问题，再结合主星、亮度、化忌化禄说清楚具体到命主身上可能是什么样子：
   - 命宫：命主处理人生和挑战的核心方式、性格底色
   - 兄弟宫：跟兄弟姐妹/同辈相处的模式
   - 夫妻宫：命主容易被什么样的人吸引、什么样的伴侣特质会让ta认真考虑长期关系、两人相处时容易遇到的课题——要给出具体的人物画像（比如"容易欣赏独立、有主见、能力强的人"），不要只讲抽象的相处会有摩擦
   - 子女宫：跟子女的缘分，或延伸到创造力、表达欲
   - 财帛宫：具体的赚钱方式和财富获取模式（不是"有没有钱"，是"钱怎么来的"）
   - 疾厄宫：身体和压力倾向（不作医学诊断）
   - 迁移宫：换环境/外地/海外发展时的表现和机会，身宫如果落在这里，可以点出命主的人生重心会随年龄增长逐渐往哪个方向偏移
   - 交友宫（仆役宫）：人脉、合作伙伴、朋友圈的质量和相处模式
   - 官禄宫：适合的工作模式和大致的事业发展路线（比如是偏一步步稳定晋升，还是偏跨领域、转型、自己创业这种非线性路线）
   - 田宅宫：家庭环境、资产、居住状态
   - 福德宫：命主内心真正渴望和感到满足的方式
   - 父母宫：跟父母/长辈的关系，也可以延伸到跟上级的关系

   如果命主提供了问题/背景，让解读更贴合ta的具体处境
4. lifeStages：命盘每个宫位后面标的"大限 X-Y 岁"就是命主行经这个宫位大限的年龄区间，按年龄顺序简单串一遍命主从小到大依次行经哪些宫位的大限，帮ta看到自己人生阶段的整体脉络（这些区间是命盘直接算出来的，照抄数字就行，不要自己按天干阳男阴女顺逆行的规则重新推算，容易算错）
5. currentFortune：结合命主当前正处在的大限宫位（对照 lifeStages 里算出来的年龄区间和命主虚岁）和流年，重点说这个阶段的运势主题和意义，可以结合命主的问题让解读更贴合
6. advice：结合整体命盘和当前运势，给一段简短、可执行的建议
7. keySummary：用一两句话把整个命盘浓缩成一个总结性的人物画像（可以用"XX坐命，XX坐事业，XX坐财帛……"这种格式），然后各用一句话点出命主最大的优势和最大的风险/课题
8. 语气自然、有温度，避免空洞套话，避免过度宿命论的说法（不要说"注定""劫数难逃"这种），每个字段都是纯文本，不要用星号加粗或 markdown 语法
9. 每一句话都必须写完整，不能在句子中途截断；如果篇幅不够，宁可少写一两句、少解读一个宫位，也不要把已经开始的句子写一半就停下
10. 用中文回复`;
}

// 统一处理调 Anthropic API 的请求/错误分支，两个 handler 共用。
async function callAnthropic(env, requestBody) {
  let anthropicResponse;
  try {
    anthropicResponse = await fetch('https://api.anthropic.com/v1/messages', {
      method: 'POST',
      headers: {
        'content-type': 'application/json',
        'x-api-key': env.ANTHROPIC_API_KEY,
        'anthropic-version': ANTHROPIC_API_VERSION,
      },
      body: JSON.stringify(requestBody),
    });
  } catch (err) {
    return { error: jsonResponse({ error: `Failed to reach Anthropic API: ${err}` }, 502) };
  }

  if (!anthropicResponse.ok) {
    const errText = await anthropicResponse.text();
    return { error: jsonResponse({ error: `Claude API error: ${errText}` }, 502) };
  }

  return { data: await anthropicResponse.json() };
}

// 不能假设 content[0] 就是文本块——Sonnet 5 默认开自适应思考，思考过程
// 会作为一个 thinking 块排在文本块前面。
function firstTextBlock(data) {
  const textBlock = (data.content ?? []).find((block) => block.type === 'text');
  return textBlock?.text ?? '{}';
}

// 根据问题里的关键词粗略判断这次占卜属于哪个领域，好让解读的重点和
// 建议方向更贴合当事人的具体处境，而不是每次都给同一套泛泛的话术。
// 纯关键词匹配、不额外调用 Claude —— 快、免费、可预测。
const FOCUS_KEYWORDS = {
  love: [
    '感情', '恋爱', '爱情', '喜欢', '暗恋', '前任', '分手', '复合',
    '结婚', '婚姻', '伴侣', '男友', '女友', '老公', '老婆', '相亲',
  ],
  career: [
    '工作', '事业', '职场', '升职', '跳槽', '创业', '面试', '考试',
    '学业', '考研', '项目', '同事', '老板', 'offer',
  ],
  money: ['钱', '财运', '投资', '理财', '收入', '存款', '花销', '负债', '赚钱'],
  health: ['健康', '身体', '生病', '病情', '恢复', '睡眠', '压力大'],
};

const FOCUS_HINTS = {
  love: '这是一个和感情/关系有关的问题。解读和建议请围绕沟通方式、边界感、双方各自的状态展开，不要单方面断言对方的想法或感情走向。',
  career: '这是一个和工作/事业/学业有关的问题。解读和建议请围绕具体可执行的下一步、时机判断展开。',
  money: '这是一个和财务/金钱有关的问题。解读请偏向风险提示和稳健的实际建议，不要给出具体的投资操作指令。',
  health: '这是一个和健康/身心状态有关的问题。解读请偏向自我关照和情绪疏导，不要给医学诊断或替代医嘱的建议。',
};

function detectFocus(text) {
  if (!text) return null;
  for (const [focus, keywords] of Object.entries(FOCUS_KEYWORDS)) {
    if (keywords.some((kw) => text.includes(kw))) return focus;
  }
  return null;
}

function buildPrompt({ question, background, spreadName, cards }) {
  const cardLines = cards
    .map((c, i) => {
      const orientationLabel = c.orientation === 'reversed' ? '逆位' : '正位';
      const keywords = Array.isArray(c.keywords) ? c.keywords.join('、') : '';
      return `${i + 1}. 位置「${c.positionLabel ?? '未命名'}」：${c.nameZh}（${orientationLabel}）—— 关键词：${keywords}`;
    })
    .join('\n');

  const focus = detectFocus(`${question ?? ''} ${background ?? ''}`);
  const focusHint = focus ? FOCUS_HINTS[focus] : null;

  return `你是一位专业、温暖但不夸大其词的塔罗牌解读师。请根据以下信息给出一段针对性的塔罗解读。

牌阵：${spreadName ?? '未指定'}
${question ? `占卜者的问题：${question}` : '（占卜者没有提供具体问题，请给出通用性的整体解读）'}
${background ? `占卜者的背景/近况：${background}` : ''}
${focusHint ? `\n注意：${focusHint}` : ''}

抽到的牌（请按这个顺序逐张解读，不要遗漏也不要调换顺序）：
${cardLines}

请按给定的 JSON 结构返回，其中：
1. themeTitle：用 3-4 个词概括整个牌阵的核心主题（顿号分隔，比如"行动、规划、匮乏"），给分享卡片当标题用，不是完整句子
2. overview：先综合整体牌面给出一个简短的整体印象，点出这次牌阵传达的核心情绪或主题
3. cards：对每一张牌，先用 keywordCore 提炼 3-4 个词概括这张牌在这个位置的核心特质（顿号分隔，不是完整句子，比如"说话鲁莽、情绪急躁、缺乏条理"），再用 interpretation 说清楚这张牌本身画面里的意象/象征意义，具体展开它在这个位置上对应到占卜者的问题意味着什么；如果占卜者提供了背景/近况，结合这段背景让解读更贴合ta的具体处境。多张牌之间尽量讲成一段连贯的故事——比如上一张牌暗示的情况如何发展到这一张——而不是互相孤立地罗列
4. advice：结合整体牌面，给一段简短、可执行的建议
5. 语气自然、有温度，避免空洞的套话，避免使用"命运"这种过度宿命论的词；每个字段都是纯文本，不要用星号加粗或任何 markdown 语法
6. 用中文回复，overview 和 advice 各控制在 2-4 句，每张牌的 interpretation 控制在 3-5 句
7. 每一句话都必须写完整，不能在句子中途截断；如果篇幅不够，宁可少写一两句，也不要把已经开始的句子写一半就停下`;
}

function jsonResponse(obj, status = 200) {
  return new Response(JSON.stringify(obj), {
    status,
    headers: { 'content-type': 'application/json', ...corsHeaders() },
  });
}

function corsHeaders() {
  return {
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Methods': 'POST, OPTIONS',
    'Access-Control-Allow-Headers': 'Content-Type',
  };
}
