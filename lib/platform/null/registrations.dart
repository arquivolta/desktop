import 'package:arquivolta/interfaces.dart';
import 'package:get_it/get_it.dart';
import 'package:logger/logger.dart';

GetIt setupPlatformRegistrations(GetIt locator) {
  locator
    ..registerSingleton(ApplicationMode.debug)
    ..registerSingleton(false, instanceName: 'isTestMode')
    ..registerFactory<Logger>(
      Logger.new,
    )
    ..registerSingleton<ArchLinuxInstaller>(NullArchLinuxInstaller());

  return locator;
}

class NullArchLinuxInstaller extends ArchLinuxInstaller {
  @override
  Future<DistroWorker> installArchLinux(String distroName) {
    throw UnimplementedError();
  }

  @override
  Future<void> runArchLinuxPostInstall(
    DistroWorker worker,
    String username,
    String password,
    String localeCode,
  ) {
    throw UnimplementedError();
  }

  @override
  String getDefaultUsername() {
    throw UnimplementedError();
  }

  @override
  Future<String> errorMessageForProposedDistroName(String proposedName) {
    throw UnimplementedError();
  }
}
