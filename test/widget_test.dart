import 'package:flutter_test/flutter_test.dart';
import 'package:tapestry/main.dart';

import 'support/test_store.dart';

void main() {
  testWidgets('App launches showing the book list, starting with Genesis', (
    WidgetTester tester,
  ) async {
    final store = await openTestStore();
    addTearDown(store.close);

    await tester.pumpWidget(TapestryApp(store: store, translationService: null));
    await tester.pumpAndSettle();

    expect(find.text('Tapestry'), findsOneWidget);
    expect(find.text('Genesis'), findsOneWidget);
  });
}
