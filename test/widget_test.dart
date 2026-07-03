import 'package:flutter_test/flutter_test.dart';

import 'package:huddle/main.dart';

void main() {
  testWidgets('Launch screen shows Sign In and Join with Event Code', (WidgetTester tester) async {
    await tester.pumpWidget(const HuddleApp());

    expect(find.text('Huddle'), findsOneWidget);
    expect(find.text('Sign In'), findsOneWidget);
    expect(find.text('Join with Event Code'), findsOneWidget);
  });
}
