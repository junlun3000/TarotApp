/// "理论"板块里一篇文章的一个小节：一个小标题 + 一段正文。
class TheorySection {
  const TheorySection({required this.heading, required this.body});

  final String heading;
  final String body;
}

/// "理论"板块里的一篇静态文章（历史起源/准备工作/占卜流程/注意事项/牌组架构）。
class TheoryArticle {
  const TheoryArticle({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.sections,
  });

  final String id;
  final String title;
  final String subtitle;
  final List<TheorySection> sections;
}
