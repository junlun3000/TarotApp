import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'data/reading_history_repository.dart';
import 'screens/onboarding_screen.dart';
import 'widgets/responsive_app_shell.dart';

/// Flutter 默认的 [MaterialScrollBehavior] 不把鼠标算进"可拖拽滚动"的设备
/// 里——触屏滑动没问题，但网页版/桌面版用鼠标点住拖拽是拖不动的（比如
/// 选牌页那一排横向展开的牌）。加上 [PointerDeviceKind.mouse] 之后鼠标
/// 拖拽也能滚动，不影响触屏原本的手势。
class _AppScrollBehavior extends MaterialScrollBehavior {
  @override
  Set<PointerDeviceKind> get dragDevices => {
    ...super.dragDevices,
    PointerDeviceKind.mouse,
  };
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  await ReadingHistoryRepository.instance.init();
  runApp(const TarotApp());
}

class TarotApp extends StatelessWidget {
  const TarotApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tarot',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: Brightness.dark,
        ),
      ),
      scrollBehavior: _AppScrollBehavior(),
      builder: (context, child) => ResponsiveAppShell(child: child!),
      home: const OnboardingScreen(),
    );
  }
}
