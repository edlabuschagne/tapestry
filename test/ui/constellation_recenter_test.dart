// M3-03: tapping a neighbour recenters the graph AND updates the reader pane.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tapestry/domain/book_index.dart';
import 'package:tapestry/domain/constellation.dart';
import 'package:tapestry/domain/verse_id.dart';
import 'package:tapestry/ui/constellation_screen.dart';
import 'package:tapestry/ui/constellation_view.dart';

import '../support/test_store.dart';

void main() {
  testWidgets('tapping a neighbour updates the reader pane, and the graph itself recenters', (
    tester,
  ) async {
    final store = await openTestStore();
    addTearDown(store.close);

    final isaiah = booksByOrder.values.firstWhere((b) => b.name == 'Isaiah');
    final verseId = encodeVerseId(book: isaiah.order, chapter: 53, verse: 5);
    final centerPassage = await store.passageContainingVerse(isaiah.order, verseId);

    await tester.pumpWidget(
      MaterialApp(home: ConstellationScreen(store: store, passageId: centerPassage.id)),
    );
    await tester.pumpAndSettle();

    // Reader pane starts on the center passage.
    expect(find.text(centerPassage.heading), findsOneWidget);

    final size = tester.getSize(find.byType(ConstellationView));
    final topLeft = tester.getTopLeft(find.byType(ConstellationView));

    final firstNeighbours = await store.topNeighbours(centerPassage.id);
    final firstLayout = layoutConstellation(firstNeighbours);
    final firstTapTarget = neighbourPositions(size, firstLayout)[firstLayout.first.passageId]!;
    final firstNeighbourPassage = await store.passageById(firstLayout.first.passageId);

    await tester.tapAt(topLeft + firstTapTarget);
    await tester.pumpAndSettle();

    // The reader pane now shows the tapped neighbour's passage, not the
    // original center's.
    expect(find.text(firstNeighbourPassage.heading), findsOneWidget);
    expect(find.text(centerPassage.heading), findsNothing);

    // Tapping the exact same screen coordinate again lands on a DIFFERENT
    // passage than the first tap did — proof the graph really recentered
    // around the new passage (if it hadn't, this coordinate would still mean
    // "the same first neighbour of the original center" and be a no-op).
    final secondNeighbours = await store.topNeighbours(firstNeighbourPassage.id);
    final secondLayout = layoutConstellation(secondNeighbours);
    final secondExpectedPassage = await store.passageById(secondLayout.first.passageId);

    await tester.tapAt(topLeft + firstTapTarget);
    await tester.pumpAndSettle();

    expect(find.text(secondExpectedPassage.heading), findsOneWidget);
    expect(find.text(firstNeighbourPassage.heading), findsNothing);
  });
}
