import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/spread_preset.dart';
import '../widgets/background_texture.dart';
import 'card_scan_screen.dart';
import 'card_selection_screen.dart';

/// 选好牌阵之后，抽牌前的最后一步——问几个针对这个牌阵的小问题
/// （[SpreadPreset.intakeQuestions]），取代原来"设置问题"页那个通用的
/// "想问什么"输入框。每道题都是"选一个预设选项，或者选'其他'自己填"，
/// 必须选完才能继续——比空白输入框更容易让用户至少给出一点具体信息，
/// 回答会拼成一段 background 文字，一路带到 AI 解读，让解读更贴合
/// 占卜者本人的实际处境。
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
  late final List<TextEditingController> _otherControllers = [
    for (final _ in widget.preset.intakeQuestions) TextEditingController(),
  ];

  /// 每道题选中的选项下标；等于该题 options.length 表示选中了"其他"；
  /// null 表示还没选。
  late final List<int?> _selectedIndex = List<int?>.filled(
    widget.preset.intakeQuestions.length,
    null,
  );

  @override
  void initState() {
    super.initState();
    for (final controller in _otherControllers) {
      controller.addListener(_onOtherTextChanged);
    }
  }

  void _onOtherTextChanged() => setState(() {});

  @override
  void dispose() {
    for (final controller in _otherControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  bool get _allAnswered {
    final questions = widget.preset.intakeQuestions;
    for (var i = 0; i < questions.length; i++) {
      final selected = _selectedIndex[i];
      if (selected == null) return false;
      final isOther = selected == questions[i].options.length;
      if (isOther && _otherControllers[i].text.trim().isEmpty) return false;
    }
    return true;
  }

  void _selectOption(int questionIndex, int optionIndex) {
    setState(() => _selectedIndex[questionIndex] = optionIndex);
  }

  void _continue() {
    if (!_allAnswered) return;

    final questions = widget.preset.intakeQuestions;
    final answers = <String>[
      for (var i = 0; i < questions.length; i++)
        '${questions[i].prompt}：${_answerText(i)}',
    ];
    final background = answers.join('\n');

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

  String _answerText(int questionIndex) {
    final options = widget.preset.intakeQuestions[questionIndex].options;
    final selected = _selectedIndex[questionIndex]!;
    return selected == options.length
        ? _otherControllers[questionIndex].text.trim()
        : options[selected];
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
                                '选一个最贴近的选项，让解读更贴合你的处境',
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
                                  selectedIndex: _selectedIndex[i],
                                  otherController: _otherControllers[i],
                                  onSelect: (optionIndex) =>
                                      _selectOption(i, optionIndex),
                                ),
                                const SizedBox(height: 20),
                              ],
                              const SizedBox(height: 8),
                              _ContinueButton(
                                enabled: _allAnswered,
                                onTap: _continue,
                              ),
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

/// 一道小问题：预设选项用 [_OptionChip] 平铺展示，选中"其他"才展开一个
/// 文本框；必须选中一项（选"其他"还要填字）才算这道题回答完。
class _IntakeField extends StatelessWidget {
  const _IntakeField({
    required this.question,
    required this.selectedIndex,
    required this.otherController,
    required this.onSelect,
  });

  final IntakeQuestion question;
  final int? selectedIndex;
  final TextEditingController otherController;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final otherIndex = question.options.length;
    final isOtherSelected = selectedIndex == otherIndex;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          question.prompt,
          style: GoogleFonts.inter(fontSize: 14, color: Colors.white70),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (var i = 0; i < question.options.length; i++)
              _OptionChip(
                label: question.options[i],
                selected: selectedIndex == i,
                onTap: () => onSelect(i),
              ),
            _OptionChip(
              label: '其他',
              selected: isOtherSelected,
              onTap: () => onSelect(otherIndex),
            ),
          ],
        ),
        if (isOtherSelected) ...[
          const SizedBox(height: 10),
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(16),
            ),
            child: TextField(
              controller: otherController,
              autofocus: true,
              maxLines: 2,
              style: GoogleFonts.inter(color: Colors.white),
              decoration: InputDecoration(
                hintText: '说说具体是什么',
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
      ],
    );
  }
}

class _OptionChip extends StatelessWidget {
  const _OptionChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: selected ? Colors.white : Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? Colors.white : Colors.white24,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 13,
            color: selected ? Colors.black : Colors.white70,
          ),
        ),
      ),
    );
  }
}

class _ContinueButton extends StatelessWidget {
  const _ContinueButton({required this.enabled, required this.onTap});

  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          disabledBackgroundColor: Colors.white24,
          disabledForegroundColor: Colors.white38,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(85),
          ),
        ),
        onPressed: enabled ? onTap : null,
        child: Text('开始抽牌', style: GoogleFonts.inter(fontSize: 16)),
      ),
    );
  }
}
