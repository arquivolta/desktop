import 'dart:async';

import 'package:arquivolta/app.dart';
import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_acrylic/flutter_acrylic.dart' as flutter_acrylic;
import 'package:window_manager/window_manager.dart';

// ignore: avoid_void_async
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Future.wait([
    App.setupRegistration(),
    flutter_acrylic.Window.initialize(),
    WindowManager.instance.ensureInitialized(),
  ]);

  unawaited(
    windowManager.waitUntilReadyToShow().then((_) async {
      await windowManager.setTitleBarStyle('hidden');
      await windowManager.setSkipTaskbar(false);
      await windowManager.setMinimumSize(const Size(600, 400));
      await windowManager.show();
    }),
  );

  runApp(MainWindow());
}
