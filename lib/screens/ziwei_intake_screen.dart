import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../widgets/app_bottom_nav_bar.dart';
import '../widgets/background_texture.dart';
import 'ziwei_chart_screen.dart';

/// 紫微斗数的出生信息填写页——排盘需要阳历生日、时辰（十二时辰，不是
/// 精确到分钟）、性别。填完之后进 [ZiweiChartScreen] 排盘。
///
/// 跟其他页面一样套固定 414x896 画布 + FittedBox 整体缩放。
class ZiweiIntakeScreen extends StatefulWidget {
  const ZiweiIntakeScreen({super.key});

  @override
  State<ZiweiIntakeScreen> createState() => _ZiweiIntakeScreenState();
}

/// 传统十二时辰，跟后端 iztro 库的 timeIndex（0-11）一一对应。
const List<(String, String)> kShichenOptions = [
  ('子时', '23:00 - 01:00'),
  ('丑时', '01:00 - 03:00'),
  ('寅时', '03:00 - 05:00'),
  ('卯时', '05:00 - 07:00'),
  ('辰时', '07:00 - 09:00'),
  ('巳时', '09:00 - 11:00'),
  ('午时', '11:00 - 13:00'),
  ('未时', '13:00 - 15:00'),
  ('申时', '15:00 - 17:00'),
  ('酉时', '17:00 - 19:00'),
  ('戌时', '19:00 - 21:00'),
  ('亥时', '21:00 - 23:00'),
];

class _ZiweiIntakeScreenState extends State<ZiweiIntakeScreen> {
  DateTime? _birthDate;
  int? _timeIndex;
  String _gender = 'female';
  final _questionController = TextEditingController();

  @override
  void dispose() {
    _questionController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _birthDate ?? DateTime(now.year - 25, 1, 1),
      firstDate: DateTime(1900),
      lastDate: now,
      helpText: '选择阳历出生日期',
    );
    if (picked != null) setState(() => _birthDate = picked);
  }

  Future<void> _pickTime() async {
    final selected = await showModalBottomSheet<int>(
      context: context,
      backgroundColor: const Color(0xFF1A1A1F),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Text(
                '选择出生时辰',
                style: GoogleFonts.playfairDisplay(
                  fontSize: 16,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: kShichenOptions.length,
                  itemBuilder: (context, index) {
                    final (name, range) = kShichenOptions[index];
                    return ListTile(
                      title: Text(
                        name,
                        style: GoogleFonts.inter(color: Colors.white),
                      ),
                      trailing: Text(
                        range,
                        style: GoogleFonts.inter(color: Colors.white38),
                      ),
                      onTap: () => Navigator.of(context).pop(index),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
    if (selected != null) setState(() => _timeIndex = selected);
  }

  bool get _canContinue => _birthDate != null && _timeIndex != null;

  void _continue() {
    final question = _questionController.text.trim();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ZiweiChartScreen(
          birthDate: _birthDate!,
          timeIndex: _timeIndex!,
          gender: _gender,
          question: question.isEmpty ? null : question,
        ),
      ),
    );
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
                        '紫微斗数',
                        style: GoogleFonts.playfairDisplay(
                          fontSize: 20,
                          color: Colors.white,
                        ),
                      ),
                      Expanded(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const SizedBox(height: 16),
                              Text(
                                '排一张属于你的命盘',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.playfairDisplay(
                                  fontSize: 22,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '需要准确的阳历出生日期和时辰——时辰会影响排盘结果，不知道的话可以问问家人',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  color: Colors.white.withValues(alpha: 0.5),
                                ),
                              ),
                              const SizedBox(height: 32),
                              _FieldLabel('性别'),
                              const SizedBox(height: 8),
                              _GenderPicker(
                                gender: _gender,
                                onChanged: (g) => setState(() => _gender = g),
                              ),
                              const SizedBox(height: 20),
                              _FieldLabel('阳历出生日期'),
                              const SizedBox(height: 8),
                              _PickerField(
                                value: _birthDate == null
                                    ? '点击选择日期'
                                    : '${_birthDate!.year} 年 ${_birthDate!.month} 月 ${_birthDate!.day} 日',
                                onTap: _pickDate,
                              ),
                              const SizedBox(height: 20),
                              _FieldLabel('出生时辰'),
                              const SizedBox(height: 8),
                              _PickerField(
                                value: _timeIndex == null
                                    ? '点击选择时辰'
                                    : '${kShichenOptions[_timeIndex!].$1}（${kShichenOptions[_timeIndex!].$2}）',
                                onTap: _pickTime,
                              ),
                              const SizedBox(height: 20),
                              _FieldLabel('有什么特别想问的吗？（可以不填）'),
                              const SizedBox(height: 8),
                              Container(
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: TextField(
                                  controller: _questionController,
                                  maxLines: 2,
                                  style: GoogleFonts.inter(
                                    color: Colors.white,
                                  ),
                                  decoration: InputDecoration(
                                    hintText: '比如：我今年的事业运势如何？',
                                    hintStyle: GoogleFonts.inter(
                                      color: Colors.white38,
                                    ),
                                    border: InputBorder.none,
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 14,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 28),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.white,
                                    foregroundColor: Colors.black,
                                    disabledBackgroundColor: Colors.white24,
                                    disabledForegroundColor: Colors.white38,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 14,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(85),
                                    ),
                                  ),
                                  onPressed: _canContinue ? _continue : null,
                                  child: Text(
                                    '开始排盘',
                                    style: GoogleFonts.inter(fontSize: 16),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 24),
                            ],
                          ),
                        ),
                      ),
                      const AppBottomNavBar(currentIndex: 2),
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

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: GoogleFonts.inter(fontSize: 13, color: Colors.white70),
    );
  }
}

class _PickerField extends StatelessWidget {
  const _PickerField({required this.value, required this.onTap});

  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Expanded(
              child: Text(
                value,
                style: GoogleFonts.inter(color: Colors.white),
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.white38),
          ],
        ),
      ),
    );
  }
}

class _GenderPicker extends StatelessWidget {
  const _GenderPicker({required this.gender, required this.onChanged});

  final String gender;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _GenderChip(
          label: '女',
          selected: gender == 'female',
          onTap: () => onChanged('female'),
        )),
        const SizedBox(width: 12),
        Expanded(child: _GenderChip(
          label: '男',
          selected: gender == 'male',
          onTap: () => onChanged('male'),
        )),
      ],
    );
  }
}

class _GenderChip extends StatelessWidget {
  const _GenderChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: selected
              ? Colors.white
              : Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            color: selected ? Colors.black : Colors.white70,
            fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}
