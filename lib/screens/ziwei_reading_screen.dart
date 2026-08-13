import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../data/ziwei_palace_meta.dart';
import '../data/ziwei_service.dart';
import '../models/ziwei_reading.dart';
import '../widgets/background_texture.dart';

/// 紫微斗数 AI 解读页——整体印象 + 挑几个宫位解读 + 当前运势 + 建议，
/// 排版思路跟塔罗那边的 AiReadingScreen 是同一套（卡片堆叠），只是内容
/// 换成命盘。这一步会重新调一次 Worker 排盘 + Claude 解读，比单纯排盘
/// 慢很多（实测能到 60-90 秒，Claude 那边思考量比较大），所以有独立的
/// loading 态，不跟排盘页共用 Future。
///
/// 跟其他页面一样套固定 414x896 画布 + FittedBox 整体缩放。
class ZiweiReadingScreen extends StatefulWidget {
  const ZiweiReadingScreen({
    super.key,
    required this.birthDate,
    required this.timeIndex,
    required this.gender,
    this.question,
  });

  final DateTime birthDate;
  final int timeIndex;
  final String gender;
  final String? question;

  @override
  State<ZiweiReadingScreen> createState() => _ZiweiReadingScreenState();
}

class _ZiweiReadingScreenState extends State<ZiweiReadingScreen> {
  static const _service = ZiweiService();
  late Future<ZiweiReadingResult> _resultFuture;

  @override
  void initState() {
    super.initState();
    _resultFuture = _requestReading();
  }

  Future<ZiweiReadingResult> _requestReading() {
    return _service.generateReading(
      birthDate: widget.birthDate,
      timeIndex: widget.timeIndex,
      gender: widget.gender,
      question: widget.question,
    );
  }

  void _retry() {
    setState(() => _resultFuture = _requestReading());
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
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Row(
                          children: [
                            IconButton(
                              onPressed: () => Navigator.of(context).maybePop(),
                              icon: const Icon(
                                Icons.arrow_back,
                                color: Colors.white,
                              ),
                            ),
                            Expanded(
                              child: Text(
                                'AI 命盘解读',
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
                      ),
                      Expanded(
                        child: FutureBuilder<ZiweiReadingResult>(
                          future: _resultFuture,
                          builder: (context, snapshot) {
                            if (snapshot.connectionState !=
                                ConnectionState.done) {
                              return const _LoadingBody();
                            }
                            if (snapshot.hasError) {
                              return _ErrorBody(
                                message: snapshot.error.toString(),
                                onRetry: _retry,
                              );
                            }
                            return _ReadingBody(
                              reading: snapshot.data!.reading,
                            );
                          },
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

class _LoadingBody extends StatelessWidget {
  const _LoadingBody();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(color: Colors.white),
            const SizedBox(height: 16),
            Text(
              '正在为你解读命盘……',
              style: GoogleFonts.inter(fontSize: 13, color: Colors.white54),
            ),
            const SizedBox(height: 8),
            Text(
              '紫微斗数信息量比较大，这一步可能要一分钟左右，别关掉页面',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(fontSize: 12, color: Colors.white38),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorBody extends StatelessWidget {
  const _ErrorBody({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: Colors.redAccent, size: 32),
            const SizedBox(height: 12),
            Text(
              '解读失败：$message',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(fontSize: 13, color: Colors.white70),
            ),
            const SizedBox(height: 16),
            OutlinedButton(
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: const BorderSide(color: Colors.white30),
              ),
              onPressed: onRetry,
              child: const Text('重试'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReadingBody extends StatelessWidget {
  const _ReadingBody({required this.reading});

  final ZiweiReading reading;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (reading.overview.isNotEmpty) ...[
            _ReadingCard(
              icon: Icons.auto_awesome,
              child: Text(
                reading.overview,
                style: GoogleFonts.inter(
                  fontSize: 15,
                  height: 1.7,
                  fontStyle: FontStyle.italic,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
          if (reading.fourTransformations.isNotEmpty) ...[
            _ReadingCard(
              icon: Icons.change_history,
              title: '四化解读',
              child: Text(
                reading.fourTransformations,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  height: 1.6,
                  color: Colors.white.withValues(alpha: 0.85),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
          for (final palace in reading.palaces)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: _ReadingCard(
                icon: Icons.stars_outlined,
                title: lookupZiweiPalaceMeta(palace.name)?.title ?? palace.name,
                subtitle: palace.name,
                child: Text(
                  palace.interpretation,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    height: 1.6,
                    color: Colors.white.withValues(alpha: 0.85),
                  ),
                ),
              ),
            ),
          if (reading.lifeStages.isNotEmpty) ...[
            _ReadingCard(
              icon: Icons.route_outlined,
              title: '人生阶段脉络',
              child: Text(
                reading.lifeStages,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  height: 1.6,
                  color: Colors.white.withValues(alpha: 0.85),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
          if (reading.currentFortune.isNotEmpty) ...[
            _ReadingCard(
              icon: Icons.timeline,
              title: '当前运势',
              child: Text(
                reading.currentFortune,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  height: 1.6,
                  color: Colors.white.withValues(alpha: 0.85),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
          if (reading.advice.isNotEmpty) ...[
            _ReadingCard(
              icon: Icons.tips_and_updates_outlined,
              title: '给你的建议',
              child: Text(
                reading.advice,
                style: GoogleFonts.inter(
                  fontSize: 15,
                  height: 1.7,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
          if (reading.keySummary.isNotEmpty)
            _ReadingCard(
              icon: Icons.auto_awesome_outlined,
              title: '一句话总结',
              child: Text(
                reading.keySummary,
                style: GoogleFonts.inter(
                  fontSize: 15,
                  height: 1.7,
                  fontStyle: FontStyle.italic,
                  color: Colors.white,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ReadingCard extends StatelessWidget {
  const _ReadingCard({
    required this.icon,
    this.title,
    this.subtitle,
    required this.child,
  });

  final IconData icon;
  final String? title;
  final String? subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.white.withValues(alpha: 0.15),
            blurRadius: 20,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: Colors.white70, size: 18),
              if (title != null) ...[
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title!,
                        style: GoogleFonts.playfairDisplay(
                          fontSize: 15,
                          color: Colors.white,
                        ),
                      ),
                      if (subtitle != null && subtitle != title) ...[
                        const SizedBox(height: 2),
                        Text(
                          subtitle!,
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color: Colors.white38,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}
