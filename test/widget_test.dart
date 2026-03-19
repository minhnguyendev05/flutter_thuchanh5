import 'package:flutter_test/flutter_test.dart';

import 'package:expense_tracker_app/main.dart';

void main() {
  testWidgets('App shell renders', (WidgetTester tester) async {
    await tester.pumpWidget(const ExpenseTrackerApp());
    await tester.pump();

    expect(find.byType(ExpenseTrackerApp), findsOneWidget);
  });
}
