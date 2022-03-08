import 'dart:io';
import 'dart:ui' as ui;

import 'package:arquivolta/services/job.dart';
import 'package:arquivolta/services/wsl.dart';

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
  git zsh sudo docker htop tmux \
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
pacman --noconfirm -U ``$(ls *.zst`)
''';

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
      configureLocale(ui.window.locale.toLanguageTag()),
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
}
