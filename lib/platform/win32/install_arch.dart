import 'dart:io';

import 'package:arquivolta/interfaces.dart';
import 'package:arquivolta/logging.dart';
import 'package:arquivolta/platform/win32/arch_to_rootfs.dart';
import 'package:arquivolta/platform/win32/util.dart';
import 'package:arquivolta/platform/win32/wsl.dart';
import 'package:arquivolta/services/job.dart';
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

# NB: The first few items are always the main repo
cat /etc/pacman.d/mirrorlist | sed -e 's/^#//g' | head -n 8 | grep -v 'http:' > /tmp/mirrorlist
mv /tmp/mirrorlist /etc/pacman.d/

echo '[arquivolta]' >> /etc/pacman.conf
echo 'Server = https://$architecture.repo.arquivolta.dev' >> /etc/pacman.conf
echo '[arquivolta-extras]' >> /etc/pacman.conf
echo 'Server = https://$architecture.repo-extras.arquivolta.dev' >> /etc/pacman.conf
''';

String configureLocale(String locale) => '''
#!/bin/bash
set -eux

cat /etc/locale.gen | sed -e 's/^#\\($locale.*UTF-8\\)/\\1/g' > /tmp/locale.gen
mv /tmp/locale.gen /etc/locale.gen
locale-gen
echo "LANG=$locale.UTF-8" > /etc/locale.conf
''';

// There's no non-crazy way for us to create an optional dependency
// that gets installed by default. Normally this would be a group, but
// in order to add stuff to a group, we'd have to fork Arch's repos, and
// optdepends basically just prints stuff so it's useless
String optionalDefaultDependencies = 'docker tmux htop vim yay man-db';

String installSystem = '''
#!/bin/bash
set -euxo pipefail

# NB: We hard-require zenity to be installed in order 
# to prompt for a password, but if a user wants to uninstall
# it later, that's fine 
pacman --noconfirm -Syu
pacman --noconfirm -Sy base base-devel $optionalDefaultDependencies zenity arquivolta-base

# NB: This also runs on initial boot, 
# but we need to manually invoke it here
wsl-enable-systemd

# Disable systemd services that don't make sense under WSL
systemctl mask systemd-homed systemd-homed-activate systemd-resolved systemd-firstboot
systemctl enable systemd-tmpfiles-clean.timer docker
''';

String addUser(String userName, String password) => '''
#!/bin/bash
set -euxo pipefail

useradd -m -G wheel -s /bin/zsh '$userName'

echo "$userName:\$(zenity --password --title 'Enter a new password for $userName')" | chpasswd

# Set up sudo
echo '%wheel ALL=(ALL:ALL) ALL' > /etc/sudoers.d/00-enable-wheel
echo '' >> /etc/sudoers.d/00-enable-wheel
chmod 644 /etc/sudoers.d/00-enable-wheel

# Set our user
echo '' >> /etc/wsl.conf
echo '[user]' >> /etc/wsl.conf
echo 'default=$userName' >> /etc/wsl.conf
''';

String installWinSymlink = '''
#!/bin/bash
set -euxo pipefail

ln -sf ${win32PathToWslPath(getHomeDirectory())} "\$HOME/win"
''';

String rebootDistro(String distroName) => '''
#!/bin/bash
set -euxo pipefail

# NB: We need to reboot our distro to start systemd
wsl.exe -t '$distroName'
''';

class WSL2ArchLinuxInstaller implements ArchLinuxInstaller {
  @override
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
    return Win32DistroWorker(distroName);
  }

  @override
  Future<void> runArchLinuxPostInstall(
    DistroWorker worker,
    String username,
    String password,
    String localeCode,
  ) async {
    final jobQueue = <JobBase<ProcessOutput>>[
      await worker.runScriptInDistroAsJob(
        'Set up Pacman',
        setUpPacman(getLinuxArchitectureForOS().replaceAll('_', '-')),
        [],
        'Unable to configure Pacman updater',
        friendlyDescription: 'Setup Pacman keychain and add Arquivolta repos',
      ),
      await worker.runScriptInDistroAsJob(
        'Set up locale',
        configureLocale(localeCode.replaceAll('-', '_')),
        [],
        "Couldn't set up locale",
        friendlyDescription: 'Set Arch locale to $localeCode',
      ),
      await worker.runScriptInDistroAsJob(
        'Install base system',
        installSystem,
        [],
        'Failed to install base packages',
        friendlyDescription: 'Install developer tools and base packages',
      ),
      await worker.runScriptInDistroAsJob(
        'Create user $username',
        addUser(escapeStringForBash(username), escapeStringForBash(password)),
        [],
        "Couldn't create new user",
        friendlyDescription: 'Setting up user and sudo access',
      ),
      await worker.runScriptInDistroAsJob(
        'Set up symlink to Windows home directory',
        installWinSymlink,
        [],
        "Couldn't set up symlink to Windows home directory",
        user: username,
        friendlyDescription: 'Setting up ~/win => /mnt/c/Users/$username',
      ),
      await worker.runScriptInDistroAsJob(
        'Restart Arquivolta',
        rebootDistro(worker.distroName),
        [],
        "Couldn't restart Arch Linux",
        user: 'root',
        friendlyDescription: 'Restart Arquivolta in order to kick off systemd',
      ),
    ];

    for (final job in jobQueue) {
      await job.execute();
    }

    // NB: The user that we set up to run via /etc/wsl.conf won't apply until we
    // restart the distro, so terminate it off now
    await worker.terminate();
  }

  @override
  String getDefaultUsername() => getUsername();

  @override
  Future<String?> errorMessageForProposedDistroName(String proposedName) async {
    final re = RegExp(r'^[a-zA-Z0-9_-]+$');

    if (!re.hasMatch(proposedName)) {
      return 'Distro name has invalid characters';
    }

    return null;
  }
}
