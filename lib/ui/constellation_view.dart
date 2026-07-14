import 'dart:math';

import 'package:flutter/material.dart';
import 'package:tapestry/domain/constellation.dart';

/// Node radius large enough that the full tappable circle (diameter) clears
/// the 44dp accessibility floor (M3-05).
const double kNodeRadius = 26;
const double kCenterNodeRadius = 34;

/// A deterministic radial-orbit graph: a center passage with its top-weighted
/// neighbours arranged evenly around it, edge thickness proportional to
/// weight. Pure function of its inputs — no animation, no physics — per
/// docs/ARCHITECTURE.md.
class ConstellationView extends StatelessWidget {
  final String centerLabel;
  final List<ConstellationNode> neighbours;
  final Map<int, String> neighbourLabels;
  final ValueChanged<int> onTapNeighbour;

  const ConstellationView({
    super.key,
    required this.centerLabel,
    required this.neighbours,
    required this.neighbourLabels,
    required this.onTapNeighbour,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);
        final positions = neighbourPositions(size, neighbours);

        return GestureDetector(
          onTapUp: (details) {
            final tapped = _hitTest(details.localPosition, positions);
            if (tapped != null) onTapNeighbour(tapped);
          },
          child: CustomPaint(
            size: size,
            painter: _ConstellationPainter(
              centerLabel: centerLabel,
              neighbours: neighbours,
              neighbourLabels: neighbourLabels,
              positions: positions,
              textDirection: Directionality.of(context),
            ),
          ),
        );
      },
    );
  }
}

/// Exposed (not just an implementation detail) so tests can compute the
/// exact same node positions the painter uses — e.g. to tap a specific
/// neighbour by coordinate.
double orbitRadius(Size size) {
  final maxRadius = (size.shortestSide / 2) - kNodeRadius - 24;
  return maxRadius.clamp(60, double.infinity);
}

Map<int, Offset> neighbourPositions(Size size, List<ConstellationNode> neighbours) {
  final center = size.center(Offset.zero);
  final radius = orbitRadius(size);
  return {
    for (final node in neighbours)
      node.passageId: center + Offset(radius * cos(node.angle), radius * sin(node.angle)),
  };
}

int? _hitTest(Offset tapPosition, Map<int, Offset> positions) {
  for (final entry in positions.entries) {
    if ((entry.value - tapPosition).distance <= kNodeRadius) {
      return entry.key;
    }
  }
  return null;
}

class _ConstellationPainter extends CustomPainter {
  final String centerLabel;
  final List<ConstellationNode> neighbours;
  final Map<int, String> neighbourLabels;
  final Map<int, Offset> positions;
  final TextDirection textDirection;

  _ConstellationPainter({
    required this.centerLabel,
    required this.neighbours,
    required this.neighbourLabels,
    required this.positions,
    required this.textDirection,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final maxWeight = neighbours.isEmpty
        ? 1
        : neighbours.map((n) => n.weight).reduce((a, b) => a > b ? a : b);

    // Edges first, so nodes and labels draw on top.
    for (final node in neighbours) {
      final position = positions[node.passageId]!;
      final strokeWidth = 1.5 + (4.5 * node.weight / maxWeight);
      canvas.drawLine(
        center,
        position,
        Paint()
          ..color = Colors.indigo.withValues(alpha: 0.45)
          ..strokeWidth = strokeWidth,
      );
    }

    // Center: circle + label inside — it's the one node with no "outward"
    // direction to place a label in, but it's also the biggest circle and
    // its label is a short reference like any other, so it fits.
    canvas.drawCircle(center, kCenterNodeRadius, Paint()..color = Colors.indigo);
    _paintLabel(
      canvas,
      anchor: center,
      label: centerLabel,
      color: Colors.white,
      maxWidth: kCenterNodeRadius * 3,
      centerOnAnchor: true,
    );

    // Neighbours: circle, then label offset radially outward (in the same
    // direction from center through the node) rather than always straight
    // down — with up to 12 nodes on the orbit, anchoring every label to the
    // same side crowds them far worse than spreading each one away from the
    // center in its own direction.
    for (final node in neighbours) {
      final position = positions[node.passageId]!;
      canvas.drawCircle(position, kNodeRadius, Paint()..color = Colors.indigo.shade300);

      final direction = Offset(cos(node.angle), sin(node.angle));
      final labelAnchor = position + direction * (kNodeRadius + 14);
      _paintLabel(
        canvas,
        anchor: labelAnchor,
        label: neighbourLabels[node.passageId] ?? '',
        color: Colors.black87,
        maxWidth: kNodeRadius * 3,
        centerOnAnchor: true,
      );
    }
  }

  void _paintLabel(
    Canvas canvas, {
    required Offset anchor,
    required String label,
    required Color color,
    required double maxWidth,
    required bool centerOnAnchor,
  }) {
    final painter = TextPainter(
      text: TextSpan(
        text: label,
        style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600),
      ),
      textDirection: textDirection,
      textAlign: TextAlign.center,
      maxLines: 1,
      ellipsis: '…',
    )..layout(maxWidth: maxWidth);
    final offset = centerOnAnchor
        ? anchor - Offset(painter.width / 2, painter.height / 2)
        : anchor;
    painter.paint(canvas, offset);
  }

  @override
  bool shouldRepaint(covariant _ConstellationPainter oldDelegate) =>
      oldDelegate.centerLabel != centerLabel ||
      oldDelegate.neighbours != neighbours ||
      oldDelegate.positions != positions;
}
