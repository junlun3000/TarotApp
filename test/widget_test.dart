import 'package:flutter_test/flutter_test.dart';

import 'package:tarot_app/main.dart';
import 'package:tarot_app/screens/onboarding_screen.dart';

void main() {
  testWidgets('App boots into the onboarding screen', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const TarotApp());

    expect(find.byType(OnboardingScreen), findsOneWidget);
  });
}
