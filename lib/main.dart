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

  final desktopTasks = !kIsWeb
      ? [
          flutter_acrylic.Window.initialize(),
          WindowManager.instance.ensureInitialized()
        ]
      : <Future<void>>[];

  await Future.wait([App.setupRegistration(), ...desktopTasks]);

  if (!kIsWeb) {
    unawaited(
      windowManager.waitUntilReadyToShow().then((_) async {
        await windowManager.setTitleBarStyle(TitleBarStyle.hidden);
        await windowManager.setSkipTaskbar(false);
        await windowManager.setMinimumSize(const Size(600, 400));
        await windowManager.show();
      }),
    );
  }

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
