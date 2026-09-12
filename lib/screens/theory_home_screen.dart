import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../data/theory_content.dart';
import '../widgets/app_bottom_nav_bar.dart';
import '../widgets/background_texture.dart';
import '../widgets/responsive_app_shell.dart';
import 'card_index_screen.dart';
import 'theory_article_screen.dart';

/// "理论"板块首页 —— 塔罗入门知识的目录：历史起源、准备工作、占卜流程、
/// 注意事项、牌组架构、完整牌意。对应底部导航栏第三个 tab。
class TheoryHomeScreen extends StatelessWidget {
  const TheoryHomeScreen({super.key});

  static const double _designWidth = 414;
  static const double _designHeight = 896;
  static const double _cardRadius = 24;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: ClipRRect(
        borderRadius: BorderRadius.circular(_cardRadius),
        child: FittedBox(
          fit: BoxFit.contain,
          clipBehavior: Clip.hardEdge,
          child: SizedBox(
            width: _designWidth,
            height: _designHeight,
            child: Stack(
              children: [
                const BackgroundTexture(),
                SafeArea(
                  minimum: EdgeInsets.only(
                    top: ResponsiveAppShell.topCropInset(context),
                  ),
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: Text(
                          '理论',
                          style: GoogleFonts.playfairDisplay(
                            fontSize: 20,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      Text(
                        '塔罗入门知识',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: Colors.white54,
                        ),
                      ),
                      Expanded(
                        child: ListView(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 16,
                          ),
                          children: [
                            for (final article in TheoryContent.all)
                              _TheoryMenuTile(
                                title: article.title,
                                subtitle: article.subtitle,
                                icon: Icons.menu_book_outlined,
                                onTap: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          TheoryArticleScreen(article: article),
                                    ),
                                  );
                                },
                              ),
                            _TheoryMenuTile(
                              title: '完整牌意',
                              subtitle: '浏览全部 78 张牌的正逆位含义',
                              icon: Icons.style_outlined,
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const CardIndexScreen(),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                      const AppBottomNavBar(currentIndex: 3),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TheoryMenuTile extends StatelessWidget {
  const _TheoryMenuTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(icon, color: Colors.white70),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: Colors.white54,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: Colors.white38),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
