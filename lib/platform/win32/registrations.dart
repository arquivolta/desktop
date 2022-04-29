import 'dart:convert';
import 'dart:io';

import 'package:arquivolta/interfaces.dart';
import 'package:arquivolta/platform/win32/install_arch.dart';
import 'package:arquivolta/platform/win32/util.dart';
import 'package:get_it/get_it.dart';
import 'package:logger/logger.dart';

// ignore: implementation_imports
import 'package:sentry_flutter/sentry_flutter.dart';

GetIt setupPlatformRegistrations(GetIt locator) {
  final isTestMode = Platform.resolvedExecutable.contains('_tester');
  var isDebugMode = false;

  // NB: Assert statements are stripped from release mode. Clever!
  // ignore: prefer_asserts_with_message
  assert(isDebugMode = true);

  final appMode = isTestMode
      ? ApplicationMode.test
      : isDebugMode
          ? ApplicationMode.debug
          : ApplicationMode.production;

  Logger logger;

  final appData = getLocalAppDataPath();
  final ourAppDataDir = Directory('$appData/Arquivolta')
    ..createSync(recursive: true);

  final logFile = File('${ourAppDataDir.path}/log.txt');
  final fileOut = BetterFileOutput(file: logFile);

  final List<LogOutput> sentryLogging = appMode == ApplicationMode.production
      ? [SentryOutput(), ConsoleOutput()]
      : [ConsoleOutput()];

  logger = Logger(
    output: MultiOutput([
      ...sentryLogging,
      fileOut,
    ]),
    filter: ProductionFilter(),
    printer: PrettyPrinter(
      methodCount: 0,
      errorMethodCount: 4,
      excludeBox: {
        Level.debug: true,
        Level.info: true,
        Level.verbose: true,
      },
      colors: false,
      printEmojis: false, // NB: We add these in later
    ),
    level: Level.info,
  );

  locator
    ..registerSingleton(appMode)
    ..registerSingleton(isTestMode, instanceName: 'isTestMode')
    ..registerSingleton<Logger>(logger)
    ..registerSingleton<Future<void> Function()>(
      () async {
        await fileOut.close();
        openFileViaShell(logFile.path);
      },
      instanceName: 'openLog',
    )
    ..registerSingleton<ArchLinuxInstaller>(WSL2ArchLinuxInstaller());

  return locator;
}

class SentryOutput implements LogOutput {
  @override
  void destroy() {}

  @override
  void init() {}

  @override
  void output(OutputEvent event) {
    final msg = event.lines.join('\n');
    if (event.level == Level.error || event.level == Level.wtf) {
      Sentry.captureEvent(
        SentryEvent(
          message: SentryMessage(msg),
          level: SentryLevel.error,
        ),
      );
    }

    if (event.level == Level.info || event.level == Level.warning) {
      Sentry.addBreadcrumb(
        Breadcrumb(
          message: msg,
          level: event.level == Level.info
              ? SentryLevel.info
              : SentryLevel.warning,
        ),
      );
    }

    // ignore: avoid_print
    print(msg);
  }
}

class BetterFileOutput extends LogOutput {
  final File file;
  final bool overrideExisting;
  final Encoding encoding;
  IOSink? _sink;

  BetterFileOutput({
    required this.file,
    this.overrideExisting = false,
    this.encoding = utf8,
  });

  @override
  void init() {
    if (_sink != null) {
      destroy();
    }

    _sink = file.openWrite(
      mode: overrideExisting ? FileMode.writeOnly : FileMode.writeOnlyAppend,
      encoding: encoding,
    );
  }

  @override
  void output(OutputEvent event) {
    if (_sink == null) {
      init();
    }

    _sink?.writeAll(event.lines, '\n');
    _sink?.writeln();
  }

  @override
  // ignore: avoid_void_async
  void destroy() {
    close();
  }

  Future<void> close() async {
    await _sink?.flush();
    await _sink?.close();
    _sink = null;
  }
}
