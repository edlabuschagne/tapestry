// M3-04: every rendered node resolves to a readable passage — swept over the
// 50 highest-degree passages (the ones most likely to expose a bad edge,
// since they have the most neighbours to go wrong).
import 'package:flutter_test/flutter_test.dart';

import '../support/test_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('every neighbour of the 50 highest-degree passages resolves to a readable passage', () async {
    final store = await openTestStore();
    addTearDown(store.close);

    final topDegreePassageIds = await store.highestDegreePassageIds(50);
    expect(topDegreePassageIds, hasLength(50));

    var checkedEdges = 0;
    for (final passageId in topDegreePassageIds) {
      final neighbours = await store.topNeighbours(passageId);
      expect(neighbours, isNotEmpty, reason: 'passage $passageId is high-degree but has no neighbours');

      for (final neighbour in neighbours) {
        final resolved = await store.passageById(neighbour.passageId);
        expect(resolved.heading, isNotEmpty, reason: 'neighbour ${neighbour.passageId} of $passageId has no heading');
        final verses = await store.versesForPassage(neighbour.passageId);
        expect(
          verses,
          isNotEmpty,
          reason: 'neighbour ${neighbour.passageId} of $passageId has no verse text — a dead tap',
        );
        checkedEdges++;
      }
    }

    // Sanity check that this test actually exercised a meaningful number of
    // taps, not just 50 empty passages.
    expect(checkedEdges, greaterThan(400));
  });
}
