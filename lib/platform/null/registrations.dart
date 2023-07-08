import 'dart:ui';

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
    ..registerSingleton<ArchLinuxInstaller>(_NullArchLinuxInstaller())
    ..registerSingleton<PlatformUtilities>(_NullPlatformUtilities());

  return locator;
}

class _NullArchLinuxInstaller extends ArchLinuxInstaller {
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

class _NullPlatformUtilities extends PlatformUtilities {
  @override
  void openTerminalWindow() {
    throw UnimplementedError();
  }

  @override
  Future<void> setupTransparentBackgroundWindow({
    required bool isDark,
    Color? color,
  }) {
    throw UnimplementedError();
  }
}
