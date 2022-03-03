import 'dart:async';
import 'dart:io';

import 'package:arquivolta/actions.dart';
import 'package:arquivolta/services/util.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

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

Future<void> downloadUrlToFile(Uri url, String target) async {
  final client = HttpClient();
  final rq = await client.getUrl(url);
  final resp = await rq.close();

  await resp.pipe(File(target).openWrite());
}

Future<void> downloadArchLinux(String targetFile) async {
  if (getOSArchitecture() == OperatingSystemType.aarch64) {
    await downloadUrlToFile(arm64ImageUri, targetFile);
    return;
  }

  final shaText = (await http.get(shasumUri)).body;

  final imageLine =
      shaText.split('\n').firstWhere((l) => l.contains('bootstrap'));

  final imageName = imageLine.split(RegExp(r'\s+'))[1];

  await downloadUrlToFile(
    Uri.parse('http://mirror.rackspace.com/archlinux/iso/latest/$imageName'),
    targetFile,
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
  }) async {
    return Process.run(
      'wsl.exe',
      ['-d', _distro, executable, ...arguments],
      workingDirectory: workingDirectory,
    );
  }

  Future<void> destroy() async {
    await Process.run('wsl.exe', ['--unregister', _distro])
        .throwOnError('Failed to destroy distro');
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
