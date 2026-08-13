import 'package:flutter/material.dart';

import '../models/spread_preset.dart';

/// 牌阵预览图案：按 [GridPosition] 列表把几张发光小卡片摆成对应的形状
/// （十字形、菱形、一整行等），用于"选择牌阵"目录页的卡片缩略图。
///
/// 纯用 Flutter 图形元素画出来，不依赖任何导出的美术资源——这类图案
/// 本质是几何排布，代码画比截图更灵活，以后加新牌阵不用再导出新图。
class SpreadPreviewIcon extends StatelessWidget {
  const SpreadPreviewIcon({
    super.key,
    required this.layout,
    this.cellSize = 22,
    this.showNumbers = false,
  });

  final List<GridPosition> layout;

  /// 每张小卡片的宽度（高度按 1.4 倍比例）。详情页的大图会传更大的值。
  final double cellSize;

  /// 是否在每张卡片上叠加序号（1, 2, 3...），对应牌阵里的抽牌顺序/位置编号。
  final bool showNumbers;

  // 间距、模糊半径都按 cellSize 的比例走，这样不同行数的图案（比如十字形
  // 3 行 vs 一整行）缩放到同一个卡片空间里时，卡片之间不会被发光模糊糊在一起。
  static const double _cellSpacingRatio = 9 / 22;
  static const double _blurRadiusRatio = 5 / 22;

  @override
  Widget build(BuildContext context) {
    final maxRow = layout.map((p) => p.row).reduce((a, b) => a > b ? a : b);
    final maxCol = layout.map((p) => p.col).reduce((a, b) => a > b ? a : b);
    final cellHeight = cellSize * 1.4;
    final spacing = cellSize * _cellSpacingRatio;
    final blurRadius = cellSize * _blurRadiusRatio;
    // 水平方向按卡片宽度(cellSize)步进，垂直方向必须按卡片高度(cellHeight)
    // 步进——两者不一样，之前误用同一个 step 导致多行图案的行间距被
    // 算小、行与行挤在一起，单行图案的整体高度也被低估。
    final stepH = cellSize + spacing;
    final stepV = cellHeight + spacing;

    // 用 FittedBox 包一层：不管图案是 1 行还是 3 行，都会整体缩放去适配
    // 外部（比如目录卡片）给出的实际可用空间，不会溢出/被裁切。
    return FittedBox(
      fit: BoxFit.contain,
      child: SizedBox(
        width: (maxCol + 1) * stepH - spacing,
        height: (maxRow + 1) * stepV - spacing,
        child: Stack(
          children: [
            for (final (index, position) in layout.indexed)
              Positioned(
                left: position.col * stepH,
                top: position.row * stepV,
                child: Container(
                  width: cellSize,
                  height: cellHeight,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(4),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.white.withValues(alpha: 0.6),
                        blurRadius: blurRadius,
                      ),
                    ],
                  ),
                  child: showNumbers
                      ? Text(
                          '${index + 1}',
                          style: TextStyle(
                            color: Colors.black87,
                            fontSize: cellSize * 0.4,
                            fontWeight: FontWeight.w600,
                          ),
                        )
                      : null,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
