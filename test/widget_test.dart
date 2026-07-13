import 'package:flutter_test/flutter_test.dart';

import 'package:tapestry/main.dart';

void main() {
  testWidgets('App launches showing the Tapestry placeholder screen', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const TapestryApp());

    expect(find.text('Tapestry'), findsOneWidget);
  });
}
