import 'dart:async';

import 'package:arquivolta/app.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_acrylic/flutter_acrylic.dart' as flutter_acrylic;
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:window_manager/window_manager.dart';

// ignore: avoid_void_async
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Future.wait([App.setupRegistration(), initializeDesktopWindow()]);

  var isDebugMode = false;

  // NB: Assert statements are stripped from release mode. Clever!
  // ignore: prefer_asserts_with_message
  assert(isDebugMode = true);

  const defaultDsn =
      'https://e0fa7195269a44e682a2e01d21f8f32d@o1166384.ingest.sentry.io/6256841';
  const sentryDsn = String.fromEnvironment('SENTRY_DSN');

  if (isDebugMode) {
    runApp(MainWindow());
  } else {
    await SentryFlutter.init(
      (options) {
        options
          ..dsn = sentryDsn.length > 1 ? sentryDsn : defaultDsn
          ..environment =
              "${isDebugMode ? 'dev' : 'prod'} ${kIsWeb ? 'web' : 'desktop'}"
          ..tracesSampleRate = 1.0;
      },
      appRunner: () => runApp(MainWindow()),
    );
  }
}

Future<void> initializeDesktopWindow() async {
  if (kIsWeb) return;

  WidgetsFlutterBinding.ensureInitialized();

  await WindowManager.instance.ensureInitialized();

  unawaited(
    windowManager.waitUntilReadyToShow().then((_) async {
      await windowManager.setTitleBarStyle(
        TitleBarStyle.hidden,
        windowButtonVisibility: false,
      );
      await flutter_acrylic.Window.initialize();
      await flutter_acrylic.Window.hideWindowControls();
      await flutter_acrylic.Window.setWindowBackgroundColorToClear();
      await windowManager.setMinimumSize(const Size(600, 400));
      await windowManager.center();
      await windowManager.show();
      await windowManager.setSkipTaskbar(false);
    }),
  );
}
