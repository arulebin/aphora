import 'dart:io';

import 'package:integration_test/integration_test_driver_extended.dart';

/// Runs on the PC during `flutter drive`; saves every screenshot the
/// on-device test takes to `build/e2e_screens/<name>.png`.
Future<void> main() => integrationDriver(
      onScreenshot: (name, bytes, [args]) async {
        final file = File('build/e2e_screens/$name.png');
        await file.create(recursive: true);
        await file.writeAsBytes(bytes);
        return true;
      },
    );
