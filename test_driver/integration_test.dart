import 'dart:io';

import 'package:integration_test/integration_test_driver_extended.dart';

Future<void> main() async {
  await integrationDriver(
    onScreenshot: (String screenshotName, List<int> screenshotBytes, [Map<String, Object?>? args]) async {
      // Screenshot names are always "M<milestone>-..." (e.g. "M3-01-...") —
      // derive the milestone folder from that prefix instead of hardcoding
      // one, so this driver works for every milestone's screenshots.
      final milestone = screenshotName.split('-').first;
      final file = File('verification-shots/$milestone/$screenshotName.png');
      await file.create(recursive: true);
      await file.writeAsBytes(screenshotBytes);
      return true;
    },
  );
}
