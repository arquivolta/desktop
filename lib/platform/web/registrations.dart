import 'dart:async';

import 'package:arquivolta/app.dart';
import 'package:arquivolta/interfaces.dart';
import 'package:arquivolta/logging.dart';
import 'package:arquivolta/services/job.dart';
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
    ..registerFactory<Logger>(() => _createLogger(appMode))
    ..registerSingleton<Future<void> Function()>(
      Future<void>.value,
      instanceName: 'openLog',
    )
    ..registerSingleton<ArchLinuxInstaller>(DemoArchLinuxInstaller());

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

class DemoArchLinuxInstaller extends ArchLinuxInstaller {
  @override
  Future<DistroWorker> installArchLinux(String distroName) async {
    final job = JobBase.fromBlock<void>(
        'Installing Arch Linux', 'This is just a demo!', (job) async {
      job.i('We would normally download a file here!');

      final progressLength =
          App.find<ApplicationMode>() == ApplicationMode.production ? 5 : 20;

      final progressFactor = 100 / progressLength;

      for (var i = 0; i < progressLength; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 500));
        job.i('Progress: ${i * progressFactor}%');
      }
    });

    await job.execute();
    return DemoDistroWorker();
  }

  @override
  Future<void> runArchLinuxPostInstall(
    DistroWorker worker,
    String username,
    String password,
    String localeCode,
  ) async {
    const messages = [
      ["We don't actually install anything", 'This is just a demo'],
      ['Go install the app', "It's Free!"]
    ];

    final jobs = messages
        .map(
          (e) => JobBase.fromBlock(
            e[0],
            e[1],
            (job) => Future<void>.delayed(const Duration(seconds: 3)),
          ),
        )
        .toList();

    for (final job in jobs) {
      await job.execute();
    }
  }
}

class DemoDistroWorker implements DistroWorker {
  @override
  JobBase<ProcessOutput> asJob(
    String name,
    String executable,
    List<String> arguments,
    String failureMessage, {
    String? workingDirectory,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<void> destroy() {
    throw UnimplementedError();
  }

  @override
  Future<ProcessOutput> run(
    String executable,
    List<String> arguments, {
    String? workingDirectory,
    String? user,
    StreamSink<String>? output,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<JobBase<ProcessOutput>> runScriptInDistroAsJob(
    String friendlyName,
    String scriptCode,
    List<String> arguments,
    String failureMessage, {
    String? friendlyDescription,
    String? user,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<void> terminate() {
    throw UnimplementedError();
  }
}
