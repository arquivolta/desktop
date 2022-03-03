import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:arquivolta/actions.dart';
import 'package:arquivolta/services/job.dart';
import 'package:arquivolta/services/util.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:rxdart/rxdart.dart';

/// Converts an Arch Linux image downloaded from the web into a format that
/// wsl --import can handle
///
/// Arch Linux bootstrap images can nearly be imported directly into WSL2 via
/// its --import command, except that:
///
/// * The Tarball is compressed, and WSL2 wants them uncompressed
/// * Arch prepends a useless ``` root.ARCH`  folder at the root.
///
/// So, decompress the image, and remove the folder in-line. We do this in quite
/// possibly the least sane method possible, by creating a temporary Alpine
/// Linux WSL2 distro, unarchiving and rearchiving the image, and then
/// importing that.
Future<void> convertArchBootstrapToWSLRootFs(
  String archImage,
  String targetRootfsFile,
) async {
  if (getOSArchitecture() == OperatingSystemType.aarch64) {
    // NB: Arch Linux ARM images aren't brain-damaged like x86_64, so we can
    // just unzip it and be done
    await File(archImage)
        .openRead()
        .transform(gzip.decoder)
        .pipe(File(targetRootfsFile).openWrite());

    return;
  }

  final worker = await _setupWorkWSLImage();
  final arch = _getArchitecturePrefix();

  // NB: We do this just to make sure the machine is actually working
  await retry(
    () => worker.run('uname', ['-a']),
    count: 5,
    delay: const Duration(seconds: 1),
  );

  await worker
      .run(
        'tar',
        ['-C', '/tmp', '-xzpf', basename(archImage)],
        workingDirectory: dirname(archImage),
      )
      .throwOnError('Failed to extract image');

  final rootfsName = basename(targetRootfsFile);
  await worker.run(
    'sh',
    ['-c', 'cd /tmp/root.$arch && tar -cpf ../$rootfsName *'],
  ).throwOnError('Failed to create rootfs image');

  await worker
      .run(
        'mv',
        ['/tmp/$rootfsName', '.'],
        workingDirectory: dirname(targetRootfsFile),
      )
      .throwOnError('Failed to move rootfs image');

  await Future<void>.delayed(const Duration(milliseconds: 1500));
  await worker.destroy();
}

final arm64ImageUri = Uri.parse(
  'http://os.archlinuxarm.org/os/ArchLinuxARM-aarch64-latest.tar.gz',
);

final shasumUri =
    Uri.parse('http://mirror.rackspace.com/archlinux/iso/latest/sha1sums.txt');

Future<JobBase> downloadArchLinux(String targetFile) async {
  if (getOSArchitecture() == OperatingSystemType.aarch64) {
    return DownloadUrlJob(
      arm64ImageUri,
      targetFile,
      'Downloading Arch Linux ARM',
    );
  }

  final shaText = (await http.get(shasumUri)).body;

  final imageLine =
      shaText.split('\n').firstWhere((l) => l.contains('bootstrap'));

  final imageName = imageLine.split(RegExp(r'\s+'))[1];

  return DownloadUrlJob(
    Uri.parse('http://mirror.rackspace.com/archlinux/iso/latest/$imageName'),
    targetFile,
    'Downloading Arch Linux x86_64',
  );
}

Future<DistroWorker> installArchLinux(String distroName) async {
  final targetPath = join(getLocalAppDataPath(), distroName);
  final tmpDir = (await getTemporaryDirectory()).path;
  final archLinuxPath = join(tmpDir, 'archlinux.tar.gz');
  final rootfsPath = join(tmpDir, 'rootfs-arch.tar');

  await Directory(targetPath).create();

  await downloadArchLinux(archLinuxPath);
  await convertArchBootstrapToWSLRootFs(archLinuxPath, rootfsPath);

  await Process.run(
    'wsl.exe',
    ['--import', distroName, targetPath, rootfsPath, '--version', '2'],
  ).throwOnError('Failed to create Arch distro');

  return DistroWorker(distroName);
}

class DistroWorker {
  DistroWorker(this._distro);

  final String _distro;

  Future<ProcessResult> run(
    String executable,
    List<String> arguments, {
    String? workingDirectory,
    StreamSink<String>? output,
  }) async {
    final process = await Process.start(
      'wsl.exe',
      ['-d', _distro, executable, ...arguments],
      workingDirectory: workingDirectory,
    );

    final sb = StringBuffer();
    Rx.merge([process.stderr, process.stdout])
        .map((buf) => utf8.decode(buf, allowMalformed: true))
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

  Future<void> destroy() async {
    await Process.run('wsl.exe', ['--unregister', _distro])
        .throwOnError('Failed to destroy distro');
  }

  JobBase asJob(
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

class _DistroWorkerJob extends JobBase {
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
  Future<void> execute(StreamSink<int> progress) async {
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
  }
}

String _getArchitecturePrefix() {
  return getOSArchitecture() == OperatingSystemType.amd64
      ? 'x86_64'
      : 'aarch64';
}

Future<DistroWorker> _setupWorkWSLImage() async {
  final arch = _getArchitecturePrefix();

  final tempDir = (await getTemporaryDirectory()).path;
  final suffix = DateTime.now().toIso8601String().replaceAll(':', '-');
  final alpineImage = absolute(rootAppDir(), 'assets/alpine-$arch.tar.gz');
  final targetRootFs = join(tempDir, 'rootfs-$suffix.tar');

  await File(alpineImage)
      .openRead()
      .transform(gzip.decoder)
      .pipe(File(targetRootFs).openWrite());

  final targetDir = join(tempDir, 'alpine-$suffix');
  await Directory(targetDir).create();

  final distroName = 'arquivolta-$suffix';

  // decompress the image to temp
  // sic WSL --import on it
  await Process.start('wsl.exe', [
    '--import',
    distroName,
    targetDir,
    targetRootFs,
  ]);

  // NB: WSL2 has a race condition where if you create a distro then immediately
  // try to run a command on it, it will report that it doesn't exist
  await Future<void>.delayed(const Duration(milliseconds: 2500));
  return DistroWorker(distroName);
}

Future<void> downloadUrlToFile(
  Uri url,
  String target,
  StreamSink<int> progress,
) async {
  final client = HttpClient();
  final rq = await client.getUrl(url);
  final resp = await rq.close();
  final bytes = PublishSubject<int>();

  int prev = 0;
  bytes.stream
      .scan<int>((acc, x, _) => acc + x, 0)
      .sampleTime(const Duration(seconds: 2))
      .listen((percent) {
    progress.add(percent - prev);
    prev = percent;
  });

  await resp
      .doOnData((buf) => bytes.add(buf.length))
      .pipe(File(target).openWrite());
}

class DownloadUrlJob extends JobBase {
  final Uri _uri;
  final String _target;

  DownloadUrlJob(
    this._uri,
    this._target,
    String friendlyName,
  ) : super(friendlyName, 'Downloading ${_uri.toString()} to $_target');

  @override
  Future<void> execute(StreamSink<int> progress) async {
    i(friendlyDescription);

    try {
      await downloadUrlToFile(_uri, _target, progress);
    } catch (ex, st) {
      e('Failed to download file', ex, st);
      rethrow;
    }
  }
}
