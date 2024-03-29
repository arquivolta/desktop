import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:arquivolta/interfaces.dart';
import 'package:arquivolta/logging.dart';
import 'package:arquivolta/platform/win32/util.dart';
import 'package:arquivolta/services/job.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:rxdart/rxdart.dart';

Future<ProcessResult> startProcessWithOutput(
  String executable,
  List<String> arguments, {
  String? workingDirectory,
  Encoding? encoding,
  StreamSink<String>? output,
}) async {
  final process = await Process.start(
    executable,
    arguments,
    environment: {'WSL_UTF8': '1'},
    workingDirectory: workingDirectory,
  );

  final sb = StringBuffer();
  final subj = PublishSubject<String>();
  final stream = Rx.merge([process.stderr, process.stdout])
      .map(
        (buf) => encoding != null
            ? encoding.decode(buf)
            : utf8.decode(buf, allowMalformed: true),
      )
      .transform(const LineSplitter());

  subj.listen(sb.writeln);
  unawaited(subj.sink.addStream(stream));
  unawaited(output?.addStream(subj));

  final ec = await process.exitCode;

  return ProcessResult(
    process.pid,
    ec,
    sb.toString(),
    '',
  );
}

JobBase<ProcessResult> startProcessAsJob(
  String name,
  String executable,
  List<String> arguments,
  String failureMessage, {
  String? workingDirectory,
}) {
  return JobBase.fromBlock<ProcessResult>(
      name, "$executable ${arguments.join(' ')}", (job) async {
    final out = PublishSubject<String>();
    out.stream.listen(job.i);

    try {
      final ret = await startProcessWithOutput(
        executable,
        arguments,
        workingDirectory: workingDirectory,
        output: out.sink,
      );

      if (ret.exitCode != 0) {
        job
          ..e(failureMessage)
          ..e('Process $executable exited with code ${ret.exitCode}');
      }

      return ret;
    } catch (ex, st) {
      job.e(failureMessage, ex, st);
      rethrow;
    }
  });
}

class Win32DistroWorker implements DistroWorker {
  Win32DistroWorker(this._distro);

  final String _distro;

  @override
  String get distroName => _distro;

  @override
  Future<ProcessOutput> run(
    String executable,
    List<String> arguments, {
    String? workingDirectory,
    String? user,
    StreamSink<String>? output,
  }) async {
    final userArgs = user != null ? ['-u', user] : <String>[];

    final ret = await startProcessWithOutput(
      'wsl.exe',
      ['-d', _distro, ...userArgs, '-e', executable, ...arguments],
      workingDirectory: workingDirectory,
      output: output,
    );

    return processResultToOutput(ret);
  }

  @override
  Future<void> terminate() async {
    await startProcessWithOutput('wsl.exe', ['--terminate', _distro])
        .throwOnError('Failed to terminate distro');
  }

  @override
  Future<void> destroy() async {
    await startProcessWithOutput('wsl.exe', ['--unregister', _distro])
        .throwOnError('Failed to destroy distro');
  }

  @override
  JobBase<ProcessOutput> asJob(
    String name,
    String executable,
    List<String> arguments,
    String failureMessage, {
    String? workingDirectory,
  }) {
    return _DistroWorkerJob(
      this,
      name,
      executable,
      arguments,
      failureMessage,
      wd: workingDirectory,
    );
  }

  @override
  Future<JobBase<ProcessOutput>> runScriptInDistroAsJob(
    String friendlyName,
    String scriptCode,
    List<String> arguments,
    String failureMessage, {
    String? friendlyDescription,
    String? user,
  }) async {
    final tempDir = (await getTemporaryDirectory()).path;
    final scriptFile = '${DateTime.now().millisecondsSinceEpoch}.sh';
    final target = '$tempDir\\$scriptFile';

    await File(target).writeAsString(scriptCode);

    d('Moving script $scriptFile into distro');
    await run('mv', [scriptFile, '/tmp/'], workingDirectory: tempDir);

    return _DistroWorkerJob(
      this,
      friendlyName,
      '/bin/bash',
      ['/tmp/$scriptFile'],
      failureMessage,
      user: user,
      desc: friendlyDescription,
    );
  }
}

class _DistroWorkerJob extends JobBase<ProcessOutput> {
  final DistroWorker worker;
  final String exec;
  final String failureMessage;
  final List<String> args;
  final String? wd;
  final String? user;
  final String? logPreExec;

  _DistroWorkerJob(
    this.worker,
    String name,
    this.exec,
    this.args,
    this.failureMessage, {
    String? desc,
    this.wd,
    this.user,
    // ignore: unused_element
    this.logPreExec,
  }) : super(name, desc ?? "$exec ${args.join(' ')}");

  @override
  Future<ProcessOutput> execute() async {
    i(friendlyDescription);
    jobStatus.value = JobStatus.running;

    final out = StreamController<String>();
    out.stream.listen(i);

    ProcessOutput result;
    try {
      if (logPreExec != null) i(logPreExec);

      result = await worker.run(
        exec,
        args,
        workingDirectory: wd,
        user: user,
        output: out.sink,
      );
    } catch (ex, st) {
      e('Failed to start $exec', ex, st);

      jobStatus.value = JobStatus.error;
      rethrow;
    }

    try {
      await out.close();
    } catch (_) {
      d('Failed to close output stream, but we dont care');
    }

    if (result.exitCode != 0) {
      e(failureMessage);
      e('Process $exec exited with code ${result.exitCode}');
      jobStatus.value = JobStatus.error;

      throw Exception(failureMessage);
    } else {
      i('Process $exec completed successfully');
      jobStatus.value = JobStatus.success;
    }

    return result;
  }
}

String getArchitecturePrefix() {
  return getOSArchitecture() == OperatingSystemType.amd64
      ? 'x86_64'
      : 'aarch64';
}

JobBase<DistroWorker> setupWorkWSLImageJob() {
  return JobBase.fromBlock('Setting up worker WSL installation',
      'Installing temporary Alpine Linux install to fixup Arch Linux tarball',
      (job) async {
    final arch = getArchitecturePrefix();

    final tempDir = (await getTemporaryDirectory()).path;
    final suffix = DateTime.now().toIso8601String().replaceAll(':', '-');
    final alpineImage = absolute(rootAppDir(), 'assets/alpine-$arch.tar.gz');
    final targetRootFs = join(tempDir, 'rootfs-$suffix.tar');

    job
      ..i('Decompressing Alpine Linux')
      ..d('$alpineImage => $targetRootFs');

    await File(alpineImage)
        .openRead()
        .transform(gzip.decoder)
        .pipe(File(targetRootFs).openWrite());

    final targetDir = join(tempDir, 'alpine-$suffix');
    await Directory(targetDir).create();

    final distroName = 'arquivolta-$suffix';

    // decompress the image to temp
    // sic WSL --import on it
    job.i('Creating distro $distroName');
    await startProcessWithOutput('wsl.exe', [
      '--import',
      distroName,
      targetDir,
      targetRootFs,
    ]).throwOnError('Failed to import work distro, is WSL installed?');

    // NB: WSL2 has a race condition where if you create a distro then
    // immediately try to run a command on it, it will report that it doesn't
    // exist
    await Future<void>.delayed(const Duration(milliseconds: 2500));
    return Win32DistroWorker(distroName);
  });
}

String getLinuxArchitectureForOS() {
  return getOSArchitecture() == OperatingSystemType.aarch64
      ? 'aarch64'
      : 'x86_64';
}
