import 'package:arquivolta/interfaces.dart';
import 'package:get_it/get_it.dart';
import 'package:logger/logger.dart';

GetIt setupPlatformRegistrations(GetIt locator) {
  var isDebugMode = false;

  // NB: Assert statements are stripped from release mode. Clever!
  // ignore: prefer_asserts_with_message
  assert(isDebugMode = true);

  final appMode =
      isDebugMode ? ApplicationMode.debug : ApplicationMode.production;

  locator
    ..registerSingleton(appMode)
    ..registerSingleton(false, instanceName: 'isTestMode')
    ..registerFactory<Logger>(() => _createLogger(appMode));

  return locator;
}

Logger _createLogger(ApplicationMode mode) {
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
