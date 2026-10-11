import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:strength_tracker/main.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('Home screen shows empty state when no sessions exist', (WidgetTester tester) async {
    await tester.pumpWidget(const StrengthTrackerApp());
    await tester.pumpAndSettle();

    expect(find.text('Strength Tracker'), findsOneWidget);
    expect(find.text('No sessions yet'), findsOneWidget);
    expect(find.text('New Session'), findsOneWidget);
  });

  testWidgets('Starting a new session navigates to the session screen', (WidgetTester tester) async {
    await tester.pumpWidget(const StrengthTrackerApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('New Session'));
    await tester.pumpAndSettle();

    expect(find.text('Add Exercise'), findsOneWidget);
  });
}
