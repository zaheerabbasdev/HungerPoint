import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:hpwaiter/main.dart';

void main() {
  testWidgets('Signed-out waiter lands on the email + password login', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(const HungerPointWaiterApp());
    await tester.pumpAndSettle(const Duration(seconds: 3));

    expect(find.text('HungerPoint Waiter'), findsOneWidget);
    expect(find.text('Email'), findsOneWidget);
    expect(find.text('Password'), findsOneWidget);
    expect(find.text('Phone Number'), findsNothing);
  });
}
