import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tapestry/domain/constellation.dart';
import 'package:tapestry/ui/constellation_view.dart';

Future<Uint8List> _renderToPngBytes(WidgetTester tester, Widget child) async {
  final key = GlobalKey();
  await tester.pumpWidget(
    MaterialApp(
      home: RepaintBoundary(
        key: key,
        child: SizedBox(width: 400, height: 400, child: child),
      ),
    ),
  );
  await tester.pumpAndSettle();

  final boundary = key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
  return tester.runAsync(() async {
    final image = await boundary.toImage(pixelRatio: 1.0);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    return byteData!.buffer.asUint8List();
  }).then((bytes) => bytes!);
}

void main() {
  testWidgets(
    'M3-02: identical constellation input renders pixel-identical output across two runs',
    (tester) async {
      const neighbours = [
        NeighbourEdge(passageId: 100, weight: 714),
        NeighbourEdge(passageId: 200, weight: 220),
        NeighbourEdge(passageId: 300, weight: 173),
        NeighbourEdge(passageId: 400, weight: 165),
        NeighbourEdge(passageId: 500, weight: 126),
      ];
      final layout = layoutConstellation(neighbours);
      const labels = {
        100: '1 Peter 2',
        200: '1 Peter 3',
        300: 'Matthew 8',
        400: 'Romans 5',
        500: 'Acts 8',
      };

      Widget build() => ConstellationView(
        centerLabel: 'Isaiah 53',
        neighbours: layout,
        neighbourLabels: labels,
        onTapNeighbour: (_) {},
      );

      final first = await _renderToPngBytes(tester, build());
      final second = await _renderToPngBytes(tester, build());

      expect(first, equals(second));
    },
  );
}
