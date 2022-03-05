import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:arquivolta/logging.dart';
import 'package:arquivolta/services/job.dart';
import 'package:arquivolta/services/util.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:rxdart/rxdart.dart';

Future<ProcessResult> startProcessWithOutput(
  String executable,
  List<String> arguments, {
  String? workingDirectory,
  StreamSink<String>? output,
}) async {
  final process = await Process.start(
    executable,
    arguments,
    workingDirectory: workingDirectory,
  );

  final sb = StringBuffer();
  Rx.merge([process.stderr, process.stdout])
      .map((buf) => utf8.decode(buf, allowMalformed: true))
      .transform(const LineSplitter())
      .listen((line) {
    sb.write(line);
    output?.add(line);
  });

  return ProcessResult(
    process.pid,
    await process.exitCode,
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
      name, "$executable ${arguments.join(' ')}", (progress, job) async {
    final out = PublishSubject<String>();
    out.stream.listen(job.i);

    try {
      progress.add(10);

      final ret = await startProcessWithOutput(
        executable,
        arguments,
        workingDirectory: workingDirectory,
        output: out.sink,
      );

      progress.add(90);

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

class DistroWorker {
  DistroWorker(this._distro);

  final String _distro;

  Future<ProcessResult> run(
    String executable,
    List<String> arguments, {
    String? workingDirectory,
    StreamSink<String>? output,
  }) {
    return startProcessWithOutput(
      'wsl.exe',
      ['-d', _distro, executable, ...arguments],
      workingDirectory: workingDirectory,
      output: output,
    );
  }

  Future<void> destroy() async {
    await Process.run('wsl.exe', ['--unregister', _distro])
        .throwOnError('Failed to destroy distro');
  }

  JobBase<ProcessResult> asJob(
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
}

class _DistroWorkerJob extends JobBase<ProcessResult> {
  final DistroWorker worker;
  final String exec;
  final String failureMessage;
  final List<String> args;
  final String? wd;

  _DistroWorkerJob(
    this.worker,
    String name,
    this.exec,
    this.args,
    this.failureMessage, {
    this.wd,
  }) : super(name, "$exec ${args.join(' ')}");

  @override
  Future<ProcessResult> execute(StreamSink<double> progress) async {
    i(friendlyDescription);
    progress.add(10);

    final out = StreamController<String>();
    out.stream.listen(i);
    final result =
        await worker.run(exec, args, workingDirectory: wd, output: out.sink);

    await out.close();

    progress.add(90);

    if (result.exitCode != 0) {
      e(failureMessage);
      e('Process $exec exited with code ${result.exitCode}');
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
      (progress, job) async {
    final arch = getArchitecturePrefix();

    final tempDir = (await getTemporaryDirectory()).path;
    final suffix = DateTime.now().toIso8601String().replaceAll(':', '-');
    final alpineImage = absolute(rootAppDir(), 'assets/alpine-$arch.tar.gz');
    final targetRootFs = join(tempDir, 'rootfs-$suffix.tar');

    job
      ..i('Decompressing Alpine Linux')
      ..d('$alpineImage => $targetRootFs');

    progress.add(20);
    await File(alpineImage)
        .openRead()
        .transform(gzip.decoder)
        .pipe(File(targetRootFs).openWrite());

    progress.add(30);

    final targetDir = join(tempDir, 'alpine-$suffix');
    await Directory(targetDir).create();

    final distroName = 'arquivolta-$suffix';

    // decompress the image to temp
    // sic WSL --import on it
    job.i('Creating distro $distroName');
    await Process.run('wsl.exe', [
      '--import',
      distroName,
      targetDir,
      targetRootFs,
    ]);

    progress.add(40);

    // NB: WSL2 has a race condition where if you create a distro then
    // immediately try to run a command on it, it will report that it doesn't
    // exist
    await Future<void>.delayed(const Duration(milliseconds: 2500));
    progress.add(10);

    return DistroWorker(distroName);
  });
}
