import 'package:arquivolta/interfaces.dart';
import 'package:get_it/get_it.dart';
import 'package:logger/logger.dart';

GetIt setupPlatformRegistrations(GetIt locator) {
  locator
    ..registerSingleton(ApplicationMode.debug)
    ..registerSingleton(false, instanceName: 'isTestMode')
    ..registerFactory<Logger>(
      Logger.new,
    );

  return locator;
}
