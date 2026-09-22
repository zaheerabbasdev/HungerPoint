// Basic smoke test: the app should build and show the splash screen
// without throwing.

import 'package:flutter_test/flutter_test.dart';

import 'package:hpwaiter/main.dart';

void main() {
  testWidgets('App builds and shows splash screen', (WidgetTester tester) async {
    await tester.pumpWidget(const HungerPointWaiterApp());
    expect(find.text('HungerPoint Waiter'), findsOneWidget);
  });
}
