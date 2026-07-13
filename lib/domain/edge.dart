/// A weighted passage-to-passage link — the graph's edge unit. Built by
/// aggregating OpenBible.info's verse-level cross-references up to the
/// passage level (weight = sum of votes); self-edges and non-positive
/// (noise/downvoted) weights are dropped in the pipeline.
class Edge {
  final int fromPassageId;
  final int toPassageId;
  final int weight;

  const Edge({
    required this.fromPassageId,
    required this.toPassageId,
    required this.weight,
  });
}
