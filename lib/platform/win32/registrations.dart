import 'dart:io';

import 'package:arquivolta/interfaces.dart';
import 'package:arquivolta/platform/win32/install_arch.dart';
import 'package:arquivolta/platform/win32/util.dart';
import 'package:get_it/get_it.dart';
import 'package:logger/logger.dart';

// ignore: implementation_imports
import 'package:logger/src/outputs/file_output.dart';

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

  locator
    ..registerSingleton(appMode)
    ..registerSingleton(isTestMode, instanceName: 'isTestMode')
    ..registerFactory<Logger>(() => _createLogger(appMode))
    ..registerSingleton<ArchLinuxInstaller>(WSL2ArchLinuxInstaller());

  return locator;
}

Logger _createLogger(ApplicationMode mode) {
  if (mode == ApplicationMode.production && Platform.isWindows) {
    final appData = getLocalAppDataPath();
    final ourAppDataDir = Directory('$appData/Arquivolta')
      ..createSync(recursive: true);

    return Logger(
      output: FileOutput(file: File('${ourAppDataDir.path}/log.txt')),
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
  }

  // NB: filter: ProductionFilter is not a typo :facepalm:
  return Logger(
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
  );
}
