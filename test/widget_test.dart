import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:job_for_all/pages/landing_page.dart';
import 'package:job_for_all/theme/app_theme.dart';

void main() {
  testWidgets('Landing page renders key sections', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.build(),
        home: const LandingPage(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Job For All'), findsWidgets);
    expect(find.text('Register'), findsOneWidget);
    expect(find.text('Search Jobs'), findsOneWidget);
  });
}
