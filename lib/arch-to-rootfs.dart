import 'dart:async';
import 'dart:io';

import 'package:arquivolta/tar/tar.dart';
import 'package:arquivolta/util.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

class DistroWorker {
  DistroWorker(this._distro);

  final String _distro;

  Future<ProcessResult> run(String executable, List<String> arguments,
      {String? workingDirectory}) async {
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

Future<DistroWorker> setupWorkWSLImage() async {
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

  return DistroWorker(distroName);
}

/// Converts an Arch Linux image downloaded from the web into a format that
/// wsl --import can handle
///
/// Arch Linux bootstrap images can nearly be imported directly into WSL2 via
/// its --import command, except that:
///
/// * The Tarball is compressed, and WSL2 wants them uncompressed
/// * Arch prepends a useless ``` root.ARCH`  folder at the root.
///
/// So, decompress the image, and remove the folder in-line. We do this directly
/// in Dart rather than shelling out, because if we try to unzip it and re-zip
/// it on Windows, we will corrupt the permissions
Future<void> convertArchBootstrapToWSLRootFs2(
  String archImage,
  String targetRootfsFile,
) async {
  final worker = await setupWorkWSLImage();

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

/// Converts an Arch Linux image downloaded from the web into a format that
/// wsl --import can handle
///
/// Arch Linux bootstrap images can nearly be imported directly into WSL2 via
/// its --import command, except that:
///
/// * The Tarball is compressed, and WSL2 wants them uncompressed
/// * Arch prepends a useless ``` root.ARCH`  folder at the root.
///
/// So, decompress the image, and remove the folder in-line. We do this directly
/// in Dart rather than shelling out, because if we try to unzip it and re-zip
/// it on Windows, we will corrupt the permissions
Future<void> convertArchBootstrapToWSLRootFs(
  String archImage,
  String targetRootfsFile,
) async {
  final inputStream = File(archImage).openRead().transform(gzip.decoder);
  final writer = tarWritingSink(File(targetRootfsFile).openWrite());
  final initialFolder = RegExp(r'^root\.(x86_64|aarch64)\/');
  final ignorePkgList = RegExp(r'^root.*\/pkglist.*\.txt$');

  await TarReader.forEach(inputStream, (entry) async {
    // NB: There is a useless file inside the root.ARCH folder, we'll ignore it
    if (ignorePkgList.hasMatch(entry.name)) {
      return;
    }

    final h = entry.header;
    final header = TarHeader(
      name: h.name.replaceFirst(initialFolder, './'),
      format: h.format,
      typeFlag: h.typeFlag,
      modified: h.modified,
      linkName: h.linkName?.replaceFirst(initialFolder, './'),
      mode: h.mode,
      size: h.size,
      userId: h.userId,
      groupId: h.groupId,
      accessed: h.accessed,
      changed: h.changed,
      devMajor: h.devMajor,
      devMinor: h.devMinor,
    );

    await writer.addStream(Stream.value(TarEntry(header, entry.contents)));
  });

  await writer.close();
  debugPrint('We Did It!');
}
