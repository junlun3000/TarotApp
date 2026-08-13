import 'package:flutter/material.dart';

import '../screens/mirror_stats_screen.dart';
import '../screens/spread_selection_screen.dart';
import '../screens/theory_home_screen.dart';
import '../screens/ziwei_intake_screen.dart';

/// 全 App 共用的底部导航栏（镜子/占卜/紫微/理论）。点未选中的 tab 会用
/// `pushReplacement` 换到对应页面，避免同一个顶层 tab 页面在导航栈里
/// 越叠越多。
class AppBottomNavBar extends StatelessWidget {
  const AppBottomNavBar({super.key, required this.currentIndex});

  final int currentIndex;

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      currentIndex: currentIndex,
      backgroundColor: Colors.black,
      selectedItemColor: Colors.white,
      unselectedItemColor: Colors.white38,
      onTap: (index) {
        if (index == currentIndex) return;
        switch (index) {
          case 0:
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (context) => const MirrorStatsScreen(),
              ),
            );
          case 1:
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (context) => const SpreadSelectionScreen(),
              ),
            );
          case 2:
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (context) => const ZiweiIntakeScreen(),
              ),
            );
          case 3:
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (context) => const TheoryHomeScreen()),
            );
        }
      },
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.center_focus_strong_outlined),
          label: '镜子',
        ),
        BottomNavigationBarItem(icon: Icon(Icons.auto_awesome), label: '占卜'),
        BottomNavigationBarItem(
          icon: Icon(Icons.stars_outlined),
          label: '紫微',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.menu_book_outlined),
          label: '理论',
        ),
      ],
    );
  }
}
