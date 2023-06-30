import 'package:arquivolta/app.dart';
import 'package:arquivolta/interfaces.dart';
import 'package:arquivolta/logging.dart';
import 'package:arquivolta/platform/win32/util.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

class InstallPrompt extends HookWidget implements Loggable {
  final void Function(String distro, String user, String password)
      onPressedInstall;

  const InstallPrompt({required this.onPressedInstall, super.key});

  @override
  Widget build(BuildContext context) {
    final distro = useTextEditingController(
      text: App.find<ApplicationMode>() == ApplicationMode.production
          ? 'arquivolta'
          : 'arch-dev',
    );
    final user = useTextEditingController(text: getUsername());

    // Reevaluate shouldEnableButton whenever any of the text changes
    [
      distro,
      user,
    ].forEach(useValueListenable);

    final shouldEnableButton = distro.text.length > 1 && user.text.length > 1;

    final onPress = useCallback(
      () => onPressedInstall(
        distro.text,
        user.text,
        '',
      ),
      [
        distro,
        user,
      ],
    );

    return Flex(
      direction: Axis.vertical,
      children: [
        Flex(
          direction: Axis.horizontal,
          children: [
            SizedBox(
              width: 160,
              child: InfoLabel(label: 'WSL Distro Name'),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextBox(
                controller: distro,
              ),
            ),
          ],
        ),
        const SizedBox(
          height: 8,
        ),
        Flex(
          direction: Axis.horizontal,
          children: [
            SizedBox(
              width: 160,
              child: InfoLabel(label: 'Linux Username'),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextBox(
                controller: user,
              ),
            ),
          ],
        ),
        Align(
          alignment: Alignment.centerRight,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: FilledButton(
              onPressed: shouldEnableButton ? onPress : null,
              child: const Text('Install'),
            ),
          ),
        ),
      ],
    );
  }
}
