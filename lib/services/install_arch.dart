import 'dart:io';
import 'dart:ui' as ui;

import 'package:arquivolta/logging.dart';
import 'package:arquivolta/services/arch_to_rootfs.dart';
import 'package:arquivolta/services/job.dart';
import 'package:arquivolta/services/util.dart';
import 'package:arquivolta/services/wsl.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

// XXX: This Feels Bad?
const arquivoltaRepoKey = '8C23AC40F9AC3CD756ADBB240D3678F5DF8F474D';

String setUpPacman(String architecture) => '''
#!/bin/bash
set -eux

pacman-key --init
pacman-key --populate archlinux
pacman-key --recv-keys $arquivoltaRepoKey
pacman-key --lsign-key $arquivoltaRepoKey

## NB: The first few items are always the main repo
cat /etc/pacman.d/mirrorlist | sed -e 's/^#//g' | head -n 8 | grep -v 'http:' > /tmp/mirrorlist
mv /tmp/mirrorlist /etc/pacman.d/

echo '[arquivolta]' >> /etc/pacman.conf
echo 'Server = https://$architecture.repo.arquivolta.dev' >> /etc/pacman.conf
''';

String configureLocale(String locale) => '''
#!/bin/bash
set -eux

cat /etc/locale.gen | sed -e 's/^#\\($locale.*UTF-8\\)/\\1/g' > /tmp/locale.gen
mv /tmp/locale.gen /etc/locale.gen
''';

String installSystem = r'''
#!/bin/bash
set -eux

pacman --noconfirm -Syu
pacman --noconfirm -Sy base base-devel \
  git zsh sudo docker htop tmux go vim \
  wsl-use-windows-openssh
''';

String addUser(String userName, String password) => '''
#!/bin/bash
set -eux

useradd -m -G wheel -s /bin/zsh '$userName'
echo "$userName:$password" | chpasswd

## Set up sudo
echo '%wheel ALL=(ALL:ALL) ALL' > /etc/sudoers.d/sudo-group-allowed
chmod 600 /etc/sudoers.d/sudo-group-allowed

## Set our user
echo '[user]' > /etc/wsl.conf
echo 'default=$userName' >> /etc/wsl.conf
''';

String buildYay = '''
#!/bin/bash
set -eux

cd /tmp
git clone https://aur.archlinux.org/yay.git && cd yay
makepkg
''';

String installYay = r'''
#!/bin/bash
set -eux

cd /tmp/yay
pacman --noconfirm -U $(ls *.zst)
''';

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

  final importJob = JobBase.fromBlock<void>(
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

Future<void> runArchLinuxPostInstall(
  DistroWorker worker,
  String username,
  String password,
) async {
  final jobQueue = <JobBase<ProcessResult>>[
    await worker.runScriptInDistroAsJob(
      'Set up Pacman',
      setUpPacman(getLinuxArchitectureForOS().replaceAll('_', '-')),
      [],
      'Unable to configure Pacman updater',
    ),
    await worker.runScriptInDistroAsJob(
      'Set up locale',
      configureLocale(ui.window.locale.toLanguageTag().replaceAll('-', '_')),
      [],
      "Couldn't set up locale",
    ),
    await worker.runScriptInDistroAsJob(
      'Install base system',
      installSystem,
      [],
      'Failed to install base packages',
    ),
    await worker.runScriptInDistroAsJob(
      'Create user $username',
      addUser(username, password),
      [],
      "Couldn't create new user",
    ),
    await worker.runScriptInDistroAsJob(
      'Build Yay package',
      buildYay,
      [],
      "Couldn't build package for Yay",
      user: username,
    ),
    await worker.runScriptInDistroAsJob(
      'Install Yay package',
      installYay,
      [],
      "Couldn't install built package for Yay",
      user: 'root',
    ),
  ];

  for (final job in jobQueue) {
    await job.execute();
  }

  // NB: The user that we set up to run via /etc/wsl.conf won't apply until we
  // restart the distro, so terminate it off now
  await worker.terminate();
}
