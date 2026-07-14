// Milestone 3 acceptance criteria, exercised through Flutter's own
// integration_test harness (see integration_test/app_test.dart's header for
// why this is the evidence method, not an ad hoc browser screenshot).
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:tapestry/data/db_connection.dart';
import 'package:tapestry/domain/book_index.dart';
import 'package:tapestry/domain/constellation.dart';
import 'package:tapestry/domain/verse_id.dart';
import 'package:tapestry/main.dart';
import 'package:tapestry/ui/constellation_view.dart';

Future<void> _screenshot(IntegrationTestWidgetsFlutterBinding binding, String name) async {
  await binding.convertFlutterSurfaceToImage();
  await binding.takeScreenshot(name);
}

Future<void> _tapAfterScrollingIntoView(WidgetTester tester, Finder finder) async {
  await tester.scrollUntilVisible(finder, 300, scrollable: find.byType(Scrollable));
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'M3-01/M3-03/M3-05: constellation for Isaiah 53, recenter, tap targets and labels',
    (tester) async {
      final store = await openLocalStore();
      addTearDown(store.close);

      final isaiah = booksByOrder.values.firstWhere((b) => b.name == 'Isaiah');
      final verseId = encodeVerseId(book: isaiah.order, chapter: 53, verse: 5);
      final centerPassage = await store.passageContainingVerse(isaiah.order, verseId);

      // M3-01, data-level: >=5 neighbours, at least one from the Gospels
      // (books 40-43: Matthew, Mark, Luke, John). The screenshot below is
      // the visual confirmation this milestone's criterion asks for; this
      // assertion is the automated proof behind it.
      final neighbourEdges = await store.topNeighbours(centerPassage.id);
      expect(neighbourEdges.length, greaterThanOrEqualTo(5));
      final neighbourBooks = await Future.wait(
        neighbourEdges.map((n) async => (await store.passageById(n.passageId)).book),
      );
      expect(
        neighbourBooks.any((book) => book >= 40 && book <= 43),
        isTrue,
        reason: 'expected at least one Gospel (Matthew-John) passage among the neighbours',
      );

      await tester.pumpWidget(TapestryApp(store: store, translationService: null));
      await tester.pumpAndSettle();

      await _tapAfterScrollingIntoView(tester, find.text('Isaiah'));
      await _tapAfterScrollingIntoView(tester, find.widgetWithText(OutlinedButton, '53'));

      await tester.tap(find.byIcon(Icons.hub_outlined));
      await tester.pumpAndSettle();

      expect(find.text('Constellation'), findsOneWidget);
      await _screenshot(binding, 'M3-01-isaiah-53-constellation');
      await _screenshot(binding, 'M3-05-tap-targets-and-labels');

      // M3-03: tap a neighbour, confirm both the graph and the reader pane
      // below it update to the new center passage.
      final size = tester.getSize(find.byType(ConstellationView));
      final topLeft = tester.getTopLeft(find.byType(ConstellationView));
      final layout = layoutConstellation(neighbourEdges);
      final firstNeighbourPosition = neighbourPositions(size, layout)[layout.first.passageId]!;
      final firstNeighbourPassage = await store.passageById(layout.first.passageId);

      await tester.tapAt(topLeft + firstNeighbourPosition);
      await tester.pumpAndSettle();

      expect(find.text(firstNeighbourPassage.heading), findsOneWidget);
      expect(find.text(centerPassage.heading), findsNothing);
      await _screenshot(binding, 'M3-03-after-recenter');
    },
  );
}
