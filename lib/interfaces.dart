import 'dart:async';

import 'package:arquivolta/logging.dart';
import 'package:arquivolta/services/job.dart';

enum ApplicationMode { debug, production, test }

// NB: This is dart:io's ProcessResult copied verbatim, but so that we can use
// dummy versions of it in web environments
class ProcessOutput {
  /// Exit code for the process.
  ///
  /// See Process.exitCode for more information in the exit code
  /// value.
  final int exitCode;

  /// Standard output from the process. The value used for the
  /// `stdoutEncoding` argument to `Process.run` determines the type. If
  /// `null` was used, this value is of type `List<int>` otherwise it is
  /// of type `String`.
  final dynamic stdout;

  /// Standard error from the process. The value used for the
  /// `stderrEncoding` argument to `Process.run` determines the type. If
  /// `null` was used, this value is of type `List<int>`
  /// otherwise it is of type `String`.
  final dynamic stderr;

  /// Process id of the process.
  final int pid;

  ProcessOutput(this.pid, this.exitCode, this.stdout, this.stderr);
}

abstract class DistroWorker implements Loggable {
  String get distroName;

  Future<ProcessOutput> run(
    String executable,
    List<String> arguments, {
    String? workingDirectory,
    String? user,
    StreamSink<String>? output,
  });

  Future<void> terminate();

  Future<void> destroy();

  JobBase<ProcessOutput> asJob(
    String name,
    String executable,
    List<String> arguments,
    String failureMessage, {
    String? workingDirectory,
  });

  Future<JobBase<ProcessOutput>> runScriptInDistroAsJob(
    String friendlyName,
    String scriptCode,
    List<String> arguments,
    String failureMessage, {
    String? friendlyDescription,
    String? user,
  });
}

abstract class ArchLinuxInstaller {
  Future<DistroWorker> installArchLinux(String distroName);
  Future<void> runArchLinuxPostInstall(
    DistroWorker worker,
    String username,
    String password,
    String localeCode,
  );
}
