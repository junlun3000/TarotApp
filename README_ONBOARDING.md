# Onboarding 页面还原说明

## 用到的图片资源（需要你从 Figma 手动导出）

原设计里有 6 张图/矢量图，我给它们起了更好懂的名字，你需要在 Figma 里：
1. 找到对应图层（node id 见下表）
2. 右键 -> Export -> PNG（2x 或 3x，保证清晰度）
3. 存到 assets/images/ 对应文件名

| 用途 | Figma node id | 建议文件名 |
|---|---|---|
| 背景纹理（soft-light 混合） | 315:110 (Rectangle282) | bg_texture.png |
| 装饰矢量 1 (旋转弧线) | 298:151 (Vector323) | vector_swirl_1.png |
| 装饰矢量 2 | 298:127 (Vector324) | vector_swirl_2.png |
| 顶部 Intersect 形状 | 294:109 | intersect_shape.png |
| 小装饰 line | 513:1 | line_deco.png (可选，暂未在代码中使用) |
| 小装饰 group | 294:123 | group_deco.png (可选，暂未在代码中使用) |

## 字体

原设计用了自定义字体 "TT Alientz Edu"，分两个变体：
- Serif（标题用）
- Grotesque（正文用）

这是付费商用字体，如果你没有授权，建议换成视觉相近的免费字体，比如：
- 标题：Playfair Display / Cormorant（衬线，有神秘感）
- 正文：Inter / Manrope（无衬线，好读）

记得在 pubspec.yaml 里注册字体：

```yaml
flutter:
  fonts:
    - family: AlientzSerif
      fonts:
        - asset: assets/fonts/YourSerifFont-Regular.ttf
    - family: AlientzGrotesque
      fonts:
        - asset: assets/fonts/YourSansFont-Regular.ttf
```

## soft-light 混合模式

Flutter 原生不直接支持 CSS 的 mix-blend-mode: soft-light，如果想要 100% 还原这个效果，
需要用 ShaderMask 或者 BackdropFilter 自己实现，目前代码里先用简单的 Opacity 近似。
如果这个细节对你重要，之后可以再帮你做精确还原。

## 文字内容

现在代码里的中文是我暂时翻译的占位文案，原文是俄文（这个模板作者是俄语区设计师）。
把 Text widget 里的字符串换成你最终想要的文案（中文/英文都行）即可。
