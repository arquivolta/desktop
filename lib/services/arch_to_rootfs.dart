import 'dart:async';
import 'dart:io';

import 'package:arquivolta/actions.dart';
import 'package:arquivolta/logging.dart';
import 'package:arquivolta/services/job.dart';
import 'package:arquivolta/services/util.dart';
import 'package:arquivolta/services/wsl.dart';
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
JobBase<void> convertArchBootstrapToWSLRootFsJob(
  String archImage,
  String targetRootfsFile,
) {
  return JobBase.fromBlock('Converting Arch Linux image to WSL format',
      'Converting Arch Linux Bootstrap image to be importable via WSL2',
      (job) async {
    if (getOSArchitecture() == OperatingSystemType.aarch64) {
      // NB: Arch Linux ARM images aren't brain-damaged like x86_64, so we can
      // just unzip it and be done

      job.i('Decompressing $archImage to $targetRootfsFile');
      await File(archImage)
          .openRead()
          .transform(gzip.decoder)
          .pipe(File(targetRootfsFile).openWrite());

      return;
    }

    final worker = await setupWorkWSLImageJob().execute();

    // NB: We do this just to make sure the machine is actually working
    await retry(
      () => worker.run('uname', ['-a']),
      count: 5,
      delay: const Duration(seconds: 1),
    );

    await worker
        .asJob(
          'Extracting Arch Linux image',
          'tar',
          ['-C', '/tmp', '-xzpf', basename(archImage)],
          'Failed to extract image',
          workingDirectory: dirname(archImage),
        )
        .execute();

    final rootfsName = basename(targetRootfsFile);
    final arch = getArchitecturePrefix();

    await worker
        .asJob(
          'Recompressing Arch Linux image in WSL2 format',
          'sh',
          ['-c', 'cd /tmp/root.$arch && tar -cpf ../$rootfsName *'],
          'Failed to create rootfs image',
        )
        .execute();

    await worker
        .asJob(
          'Moving Image back into Windows',
          'mv',
          ['/tmp/$rootfsName', '.'],
          'Failed to move rootfs image',
          workingDirectory: dirname(targetRootfsFile),
        )
        .execute();

    job.i('Cleaning up');
    await Future<void>.delayed(const Duration(milliseconds: 1500));
    await worker.destroy();
  });
}

final arm64ImageUri = Uri.parse(
  'http://os.archlinuxarm.org/os/ArchLinuxARM-aarch64-latest.tar.gz',
);

final shasumUri =
    Uri.parse('http://mirror.rackspace.com/archlinux/iso/latest/sha1sums.txt');

Future<JobBase> downloadArchLinux(String targetFile) async {
  if (getOSArchitecture() == OperatingSystemType.aarch64) {
    return downloadUrlToFileJob(
      'Downloading Arch Linux ARM',
      arm64ImageUri,
      targetFile,
    );
  }

  final shaText = (await http.get(shasumUri)).body;

  final imageLine =
      shaText.split('\n').firstWhere((l) => l.contains('bootstrap'));

  final imageName = imageLine.split(RegExp(r'\s+'))[1];

  return downloadUrlToFileJob(
    'Downloading Arch Linux x86_64',
    Uri.parse('http://mirror.rackspace.com/archlinux/iso/latest/$imageName'),
    targetFile,
  );
}

JobBase<DistroWorker> installArchLinuxJob(String distroName) {
  return JobBase.fromBlock('Install Arch Linux', 'Install Arch Linux',
      (job) async {
    final targetPath = join(getLocalAppDataPath(), distroName);
    final tmpDir = (await getTemporaryDirectory()).path;
    final archLinuxPath = join(tmpDir, 'archlinux.tar.gz');
    final rootfsPath = join(tmpDir, 'rootfs-arch.tar');

    job.i('Creating $targetPath');
    await Directory(targetPath).create();

    final downloadJob = await downloadArchLinux(archLinuxPath);
    final convertJob =
        convertArchBootstrapToWSLRootFsJob(archLinuxPath, rootfsPath);

    await downloadJob.execute();
    await convertJob.execute();

    await Process.run(
      'wsl.exe',
      ['--import', distroName, targetPath, rootfsPath, '--version', '2'],
    ).throwOnError('Failed to create Arch distro');

    return DistroWorker(distroName);
  });
}
