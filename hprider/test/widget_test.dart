import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:hprider/main.dart';

void main() {
  testWidgets('Signed-out rider lands on the email + password login', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(const HungerPointRiderApp());
    await tester.pumpAndSettle();

    expect(find.text('HungerPoint Rider'), findsOneWidget);
    expect(find.text('Email'), findsOneWidget);
    expect(find.text('Password'), findsOneWidget);
    expect(find.text('Phone Number'), findsNothing);
  });
}
