import 'dart:math';

/// A neighbour passage and the edge weight linking it to the center passage.
class NeighbourEdge {
  final int passageId;
  final int weight;

  const NeighbourEdge({required this.passageId, required this.weight});
}

/// One node's position on the constellation's radial orbit.
class ConstellationNode {
  final int passageId;
  final int weight;

  /// Radians, measured clockwise from the top (12 o'clock).
  final double angle;

  const ConstellationNode({required this.passageId, required this.weight, required this.angle});
}

/// Pure, deterministic layout: the same ordered [neighbours] always produce
/// the same angles. No randomness, no physics, no iteration to a fixed
/// point — per docs/ARCHITECTURE.md, this is the whole reason radial-orbit
/// was chosen over force-directed layout (screenshots must be reproducible).
///
/// Callers are responsible for [neighbours] already being in the intended
/// display order (e.g. weight descending, tie-broken by passage id) — this
/// function only turns "the Nth neighbour in the list" into "the Nth
/// position around the circle," evenly spaced.
List<ConstellationNode> layoutConstellation(List<NeighbourEdge> neighbours) {
  final n = neighbours.length;
  if (n == 0) return const [];

  return [
    for (var i = 0; i < n; i++)
      ConstellationNode(
        passageId: neighbours[i].passageId,
        weight: neighbours[i].weight,
        angle: (2 * pi * i / n) - (pi / 2),
      ),
  ];
}
