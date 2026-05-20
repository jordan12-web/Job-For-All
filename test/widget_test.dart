import 'package:flutter_test/flutter_test.dart';

import 'package:job_for_all/main.dart';

void main() {
  testWidgets('Job For All app shows landing page', (WidgetTester tester) async {
    await tester.pumpWidget(const JobForAllApp());
    await tester.pumpAndSettle();

    expect(find.text('Job For All'), findsWidgets);
    expect(find.text('Register'), findsOneWidget);
    expect(find.text('Landing'), findsOneWidget);
    expect(find.text('Search Jobs'), findsOneWidget);
  });
}
