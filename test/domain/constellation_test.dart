import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:tapestry/domain/constellation.dart';

void main() {
  group('layoutConstellation', () {
    test('empty input produces no nodes', () {
      expect(layoutConstellation(const []), isEmpty);
    });

    test('a single neighbour is placed at the top (12 o\'clock)', () {
      final nodes = layoutConstellation(const [NeighbourEdge(passageId: 1, weight: 10)]);
      expect(nodes, hasLength(1));
      expect(nodes.single.angle, closeTo(-pi / 2, 1e-9));
    });

    test('neighbours are spaced evenly around the full circle, in input order', () {
      final nodes = layoutConstellation(const [
        NeighbourEdge(passageId: 10, weight: 40),
        NeighbourEdge(passageId: 20, weight: 30),
        NeighbourEdge(passageId: 30, weight: 20),
        NeighbourEdge(passageId: 40, weight: 10),
      ]);

      expect(nodes.map((n) => n.passageId), [10, 20, 30, 40]);
      expect(nodes[0].angle, closeTo(-pi / 2, 1e-9)); // top
      expect(nodes[1].angle, closeTo(0, 1e-9)); // right
      expect(nodes[2].angle, closeTo(pi / 2, 1e-9)); // bottom
      expect(nodes[3].angle, closeTo(pi, 1e-9)); // left
    });

    test('weight is carried through unchanged', () {
      final nodes = layoutConstellation(const [NeighbourEdge(passageId: 1, weight: 714)]);
      expect(nodes.single.weight, 714);
    });

    test('deterministic: identical input always produces identical output', () {
      NeighbourEdge edge(int id, int w) => NeighbourEdge(passageId: id, weight: w);
      final input = [edge(5, 100), edge(3, 90), edge(9, 80), edge(1, 70), edge(7, 60)];

      final first = layoutConstellation(input);
      final second = layoutConstellation(input);

      expect(first.length, second.length);
      for (var i = 0; i < first.length; i++) {
        expect(first[i].passageId, second[i].passageId);
        expect(first[i].weight, second[i].weight);
        expect(first[i].angle, second[i].angle);
      }
    });
  });
}
