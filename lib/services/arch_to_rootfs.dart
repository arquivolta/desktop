import 'dart:async';
import 'dart:io';

import 'package:arquivolta/actions.dart';
import 'package:arquivolta/app.dart';
import 'package:arquivolta/logging.dart';
import 'package:arquivolta/services/job.dart';
import 'package:arquivolta/services/util.dart';
import 'package:arquivolta/services/wsl.dart';
import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';
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
  final log = App.find<Logger>();

  if (getOSArchitecture() == OperatingSystemType.aarch64) {
    return downloadUrlToFileJob(
      'Downloading Arch Linux ARM',
      arm64ImageUri,
      targetFile,
    );
  }

  // NB: In Debug mode, try to find our local copy of the image so we're not
  // abusing Arch Linux mirrors all the time
  if (App.find<ApplicationMode>() == ApplicationMode.debug) {
    final dirents =
        await Directory(absolute(rootAppDir(), 'resources')).list().toList();
    try {
      final img =
          dirents.firstWhere((x) => x.path.contains('archlinux-bootstrap'));

      return JobBase.fromBlock<void>(
          'Using local Arch image', 'Copying ${img.path} into place',
          (job) async {
        job.i('Using local image ${img.path}');
        await File(img.path).openRead().pipe(File(targetFile).openWrite());
        job.i('Copying complete');
      });
    } catch (_ex) {
      log.d("Can't find local image, continuing to download...");
    }
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

Future<DistroWorker> installArchLinux(String distroName) async {
  final targetPath = join(getLocalAppDataPath(), distroName);
  final tmpDir = (await getTemporaryDirectory()).path;
  final archLinuxPath = join(tmpDir, 'archlinux.tar.gz');
  final rootfsPath = join(tmpDir, 'rootfs-arch.tar');

  await Directory(targetPath).create();

  final downloadJob = await downloadArchLinux(archLinuxPath);
  final convertJob =
      convertArchBootstrapToWSLRootFsJob(archLinuxPath, rootfsPath);

  await downloadJob.execute();
  await convertJob.execute();

  final importArgs = [
    '--import',
    distroName,
    targetPath,
    rootfsPath,
    '--version',
    '2'
  ];

  final importJob = JobBase.fromBlock(
    'Import into WSL2',
    'Import Arch Linux image into WSL2',
    (job) async {
      job
        ..i('Importing $distroName')
        ..i('wsl.exe ${importArgs.join(' ')}');

      try {
        final result = await Process.run(
          'wsl.exe',
          importArgs,
        );

        // NB: We mangle the encoding here because stdout is in UTF-16
        // but we don't actually have a supported decoder
        // https://github.com/dart-lang/convert/issues/30
        job
          ..i(result.stdout)
          ..i(result.stderr)
          ..i('Process wsl.exe exited with code ${result.exitCode}');

        if (result.exitCode != 0) throw Exception('wsl.exe failed');
      } catch (ex, st) {
        job.e('Failed to import', ex, st);
        rethrow;
      }
    },
  );

  await importJob.execute();
  return DistroWorker(distroName);
}
