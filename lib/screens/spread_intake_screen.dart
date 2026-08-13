import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/spread_preset.dart';
import '../widgets/background_texture.dart';
import 'card_scan_screen.dart';
import 'card_selection_screen.dart';

/// 选好牌阵之后，抽牌前的最后一步——问几个针对这个牌阵的小问题
/// （[SpreadPreset.intakeQuestions]），取代原来"设置问题"页那个通用的
/// "想问什么"输入框。回答会拼成一段 background 文字，一路带到 AI 解读，
/// 让解读更贴合占卜者本人的实际处境。全部可选，都不填也能继续。
///
/// 跟其他页面一样套固定 414x896 画布 + FittedBox 整体缩放。
class SpreadIntakeScreen extends StatefulWidget {
  const SpreadIntakeScreen({
    super.key,
    required this.preset,
    required this.mode,
  });

  final SpreadPreset preset;

  /// 接下来走数字抽牌还是拍照扫描实体牌——决定回答完问题之后跳去哪个页面。
  final SpreadIntakeMode mode;

  @override
  State<SpreadIntakeScreen> createState() => _SpreadIntakeScreenState();
}

enum SpreadIntakeMode { select, scan }

class _SpreadIntakeScreenState extends State<SpreadIntakeScreen> {
  late final List<TextEditingController> _controllers = [
    for (final _ in widget.preset.intakeQuestions) TextEditingController(),
  ];

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _continue() {
    final answers = <String>[];
    final questions = widget.preset.intakeQuestions;
    for (var i = 0; i < questions.length; i++) {
      final answer = _controllers[i].text.trim();
      if (answer.isNotEmpty) {
        answers.add('${questions[i]}$answer');
      }
    }
    final background = answers.isEmpty ? null : answers.join('\n');

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => switch (widget.mode) {
          SpreadIntakeMode.select => CardSelectionScreen(
            preset: widget.preset,
            background: background,
          ),
          SpreadIntakeMode.scan => CardScanScreen(
            preset: widget.preset,
            background: background,
          ),
        },
      ),
    );
  }

  static const double _designWidth = 414;
  static const double _designHeight = 896;
  static const double _cardRadius = 24;

  @override
  Widget build(BuildContext context) {
    final questions = widget.preset.intakeQuestions;

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
                      _Header(title: widget.preset.nameZh),
                      const SizedBox(height: 8),
                      Expanded(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const SizedBox(height: 12),
                              Text(
                                '在抽牌之前，先回答几个小问题吧',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.playfairDisplay(
                                  fontSize: 20,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '都可以不填，但填一点会让解读更贴合你的处境',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  color: Colors.white.withValues(alpha: 0.5),
                                ),
                              ),
                              const SizedBox(height: 28),
                              for (var i = 0; i < questions.length; i++) ...[
                                _IntakeField(
                                  question: questions[i],
                                  controller: _controllers[i],
                                ),
                                const SizedBox(height: 16),
                              ],
                              const SizedBox(height: 12),
                              _ContinueButton(onTap: _continue),
                              const SizedBox(height: 24),
                            ],
                          ),
                        ),
                      ),
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

class _Header extends StatelessWidget {
  const _Header({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.of(context).maybePop(),
            icon: const Icon(Icons.arrow_back, color: Colors.white),
          ),
          Expanded(
            child: Text(
              title,
              textAlign: TextAlign.center,
              style: GoogleFonts.playfairDisplay(
                fontSize: 18,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }
}

class _IntakeField extends StatelessWidget {
  const _IntakeField({required this.question, required this.controller});

  final String question;
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          question,
          style: GoogleFonts.inter(fontSize: 14, color: Colors.white70),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(16),
          ),
          child: TextField(
            controller: controller,
            maxLines: 2,
            style: GoogleFonts.inter(color: Colors.white),
            decoration: InputDecoration(
              hintText: '可以不填',
              hintStyle: GoogleFonts.inter(color: Colors.white38),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ContinueButton extends StatelessWidget {
  const _ContinueButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(85),
          ),
        ),
        onPressed: onTap,
        child: Text('开始抽牌', style: GoogleFonts.inter(fontSize: 16)),
      ),
    );
  }
}
