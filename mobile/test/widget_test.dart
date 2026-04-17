import 'package:emobot_mobile/core/widgets/momo_orb.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('momo orb renders without timers when animation is off', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(
            child: MomoOrb(animate: false),
          ),
        ),
      ),
    );

    expect(find.byType(MomoOrb), findsOneWidget);
    expect(find.byType(Container), findsWidgets);
  });
}
