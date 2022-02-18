import 'dart:async';
import 'dart:io';

import 'package:arquivolta/util.dart';
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
  final worker = await _setupWorkWSLImage();

  final arch = _getArchitecturePrefix();
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
    ['-c', 'cd /tmp/root.$arch && tar -cpf ../rootfs.tar *'],
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

class _DistroWorker {
  _DistroWorker(this._distro);

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

Future<_DistroWorker> _setupWorkWSLImage() async {
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
  await Future<void>.delayed(const Duration(milliseconds: 1500));
  return _DistroWorker(distroName);
}
