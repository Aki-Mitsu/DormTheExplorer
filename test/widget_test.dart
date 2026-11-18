// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';
import 'package:dorm_the_explorer/main.dart';

void main() {
  testWidgets('DormApp smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const DormApp());

    // Verify that the Browse page header is displayed.
    expect(find.text('Find your dorm'), findsOneWidget);

    // Verify that bottom navigation bar destinations exist.
    expect(find.text('Browse'), findsOneWidget);
    expect(find.text('My listings'), findsOneWidget);
    expect(find.text('Review'), findsOneWidget);
  });
}