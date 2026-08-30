import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/spread_preset.dart';
import '../widgets/app_bottom_nav_bar.dart';
import '../widgets/background_texture.dart';
import '../widgets/spread_preview_icon.dart';
import 'spread_detail_screen.dart';

/// "选择牌阵"目录页 —— 还原自 Figma node 340:117（"Расклады"）。
///
/// 牌阵示意图（那几个小卡片摆成的形状）用 [SpreadPreviewIcon] 直接画出来，
/// 没有导出任何图片资源。收藏（心形）目前只是页面内的临时状态，
/// 还没接本地存储——等做抽牌历史记录那块（Hive/SQLite）时可以一起做。
class SpreadSelectionScreen extends StatefulWidget {
  const SpreadSelectionScreen({super.key});

  @override
  State<SpreadSelectionScreen> createState() => _SpreadSelectionScreenState();
}

class _SpreadSelectionScreenState extends State<SpreadSelectionScreen> {
  static const _categories = [
    '全部',
    SpreadPreset.categoryRegular,
    SpreadPreset.categoryRelationship,
    SpreadPreset.categoryFuture,
    SpreadPreset.categoryLife,
    SpreadPreset.categoryMystic,
  ];

  String _selectedCategory = '全部';
  String _searchQuery = '';
  final Set<String> _favoriteIds = {};

  List<SpreadPreset> get _filteredPresets {
    return SpreadPreset.all.where((preset) {
      final matchesCategory =
          _selectedCategory == '全部' || preset.category == _selectedCategory;
      final matchesSearch =
          _searchQuery.isEmpty || preset.nameZh.contains(_searchQuery);
      return matchesCategory && matchesSearch;
    }).toList();
  }

  void _toggleFavorite(String spreadId) {
    setState(() {
      if (!_favoriteIds.remove(spreadId)) {
        _favoriteIds.add(spreadId);
      }
    });
  }

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
                  child: Column(
                    children: [
                      const SizedBox(height: 8),
                      Text(
                        '牌阵',
                        style: GoogleFonts.playfairDisplay(
                          fontSize: 20,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: _SearchField(
                          onChanged: (value) =>
                              setState(() => _searchQuery = value),
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (SpreadPreset.recommendedForNewUsers.isNotEmpty) ...[
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.auto_awesome,
                                size: 14,
                                color: Colors.amberAccent,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                '新手推荐',
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  color: Colors.white70,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          height: 100,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                            ),
                            itemCount:
                                SpreadPreset.recommendedForNewUsers.length,
                            separatorBuilder: (context, index) =>
                                const SizedBox(width: 10),
                            itemBuilder: (context, index) {
                              final preset =
                                  SpreadPreset.recommendedForNewUsers[index];
                              return _RecommendedCard(
                                preset: preset,
                                onTap: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          SpreadDetailScreen(preset: preset),
                                    ),
                                  );
                                },
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                      SizedBox(
                        height: 40,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: _categories.length,
                          separatorBuilder: (context, index) =>
                              const SizedBox(width: 8),
                          itemBuilder: (context, index) {
                            final category = _categories[index];
                            final selected = category == _selectedCategory;
                            return ChoiceChip(
                              label: Text(category),
                              selected: selected,
                              onSelected: (_) =>
                                  setState(() => _selectedCategory = category),
                              labelStyle: GoogleFonts.inter(
                                color: selected ? Colors.black : Colors.white,
                              ),
                              selectedColor: Colors.white,
                              backgroundColor: Colors.white.withValues(
                                alpha: 0.1,
                              ),
                              side: BorderSide.none,
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 8),
                      Expanded(
                        child: GridView.builder(
                          padding: const EdgeInsets.all(16),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                mainAxisSpacing: 12,
                                crossAxisSpacing: 12,
                                childAspectRatio: 0.85,
                              ),
                          itemCount: _filteredPresets.length,
                          itemBuilder: (context, index) {
                            final preset = _filteredPresets[index];
                            return _SpreadCard(
                              preset: preset,
                              isFavorite: _favoriteIds.contains(
                                preset.spread.id,
                              ),
                              onFavoriteToggle: () =>
                                  _toggleFavorite(preset.spread.id),
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        SpreadDetailScreen(preset: preset),
                                  ),
                                );
                              },
                            );
                          },
                        ),
                      ),
                      const AppBottomNavBar(currentIndex: 1),
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

class _SearchField extends StatelessWidget {
  const _SearchField({required this.onChanged});

  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
      ),
      child: TextField(
        onChanged: onChanged,
        style: GoogleFonts.inter(color: Colors.white),
        decoration: InputDecoration(
          hintText: '搜索牌阵',
          hintStyle: GoogleFonts.inter(color: Colors.white38),
          prefixIcon: const Icon(Icons.search, color: Colors.white38),
          suffixIcon: const Icon(Icons.mic_none, color: Colors.white38),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }
}

/// "新手推荐"横向条里的一张小卡片——比正式的牌阵卡片更紧凑，
/// 只给名字、张数和示意图，点了直接进详情页（跟主网格里点卡片的行为
/// 一致），方便第一次用的人不用先翻完全部 35 个牌阵再决定抽哪个。
class _RecommendedCard extends StatelessWidget {
  const _RecommendedCard({required this.preset, required this.onTap});

  final SpreadPreset preset;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 112,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF4B5580), Color(0xFF272B47)],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white24),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 40,
              child: Center(
                child: SpreadPreviewIcon(layout: preset.previewLayout),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              preset.nameZh,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(fontSize: 12, color: Colors.white),
            ),
            Text(
              '${preset.cardCount} 张',
              style: GoogleFonts.inter(fontSize: 10, color: Colors.white38),
            ),
          ],
        ),
      ),
    );
  }
}

class _SpreadCard extends StatelessWidget {
  const _SpreadCard({
    required this.preset,
    required this.isFavorite,
    required this.onFavoriteToggle,
    required this.onTap,
  });

  final SpreadPreset preset;
  final bool isFavorite;
  final VoidCallback onFavoriteToggle;
  final VoidCallback onTap;

  static const _cardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF4B5580), Color(0xFF272B47)],
  );

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: _cardGradient,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (preset.recommended)
                      const Padding(
                        padding: EdgeInsets.only(right: 4, top: 2),
                        child: Icon(
                          Icons.auto_awesome,
                          size: 12,
                          color: Colors.amberAccent,
                        ),
                      ),
                    Expanded(
                      child: Text(
                        preset.nameZh,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: onFavoriteToggle,
                      child: Icon(
                        isFavorite ? Icons.favorite : Icons.favorite_border,
                        size: 18,
                        color: isFavorite ? Colors.redAccent : Colors.white54,
                      ),
                    ),
                  ],
                ),
                Expanded(
                  child: Center(
                    child: SpreadPreviewIcon(layout: preset.previewLayout),
                  ),
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    '(${preset.cardCount})',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: Colors.white38,
                    ),
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
