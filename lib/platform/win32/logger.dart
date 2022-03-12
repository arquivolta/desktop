import 'dart:io';

import 'package:arquivolta/interfaces.dart';
import 'package:arquivolta/platform/win32/util.dart';
import 'package:logger/logger.dart';

// ignore: implementation_imports
import 'package:logger/src/outputs/file_output.dart';

Logger createLogger(ApplicationMode mode) {
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

bool isTestMode() {
  return Platform.resolvedExecutable.contains('_tester');
}
