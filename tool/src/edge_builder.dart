import 'package:tapestry/domain/edge.dart';

import 'bsb_source.dart';
import 'cross_ref_source.dart';

class EdgeBuildResult {
  final List<Edge> edges;
  final int unresolvedRowCount;
  final int selfEdgeRowCount;
  final int droppedNonPositiveCount;

  const EdgeBuildResult(
    this.edges, {
    required this.unresolvedRowCount,
    required this.selfEdgeRowCount,
    required this.droppedNonPositiveCount,
  });
}

/// Aggregates verse-level cross-references up to passage-level weighted
/// edges. Edges are undirected in storage (a cross-reference from A to B is
/// evidence of a link between A and B either way, and the constellation view
/// queries "neighbours of a passage" without caring which side of the
/// original reference it was) — canonicalized as (min id, max id) and summed.
/// Self-edges (both ends resolve to the same passage) and edges whose total
/// weight ends up <= 0 (net downvoted / noise) are dropped per
/// docs/ARCHITECTURE.md's Edge model.
EdgeBuildResult buildEdges(List<VerseRow> verses, List<CrossRefRow> crossRefs) {
  final verseIdToPassageId = {for (final v in verses) v.verseId: v.passageId};

  final weights = <int, Map<int, int>>{};
  var unresolved = 0;
  var selfEdges = 0;

  for (final row in crossRefs) {
    final fromPassage = verseIdToPassageId[row.fromVerseId];
    final toPassage = verseIdToPassageId[row.toVerseId];
    if (fromPassage == null || toPassage == null) {
      unresolved++;
      continue;
    }
    if (fromPassage == toPassage) {
      selfEdges++;
      continue;
    }
    final a = fromPassage < toPassage ? fromPassage : toPassage;
    final b = fromPassage < toPassage ? toPassage : fromPassage;
    final inner = weights.putIfAbsent(a, () => {});
    inner[b] = (inner[b] ?? 0) + row.votes;
  }

  final edges = <Edge>[];
  var droppedNonPositive = 0;
  weights.forEach((a, inner) {
    inner.forEach((b, weight) {
      if (weight > 0) {
        edges.add(Edge(fromPassageId: a, toPassageId: b, weight: weight));
      } else {
        droppedNonPositive++;
      }
    });
  });

  return EdgeBuildResult(
    edges,
    unresolvedRowCount: unresolved,
    selfEdgeRowCount: selfEdges,
    droppedNonPositiveCount: droppedNonPositive,
  );
}
