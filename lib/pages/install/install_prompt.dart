import 'package:arquivolta/actions.dart';
import 'package:arquivolta/app.dart';
import 'package:arquivolta/interfaces.dart';
import 'package:arquivolta/logging.dart';
import 'package:arquivolta/widgets/hooks.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

final RegExp userRegex = RegExp(r'^[a-z_][a-z0-9_-]*[$]?$');

class InstallPrompt extends HookWidget implements Loggable {
  final void Function(String distro, String user, String password)
      onPressedInstall;

  final String defaultUserName;
  final ArchLinuxInstaller installer;

  const InstallPrompt({
    required this.onPressedInstall,
    required this.defaultUserName,
    required this.installer,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final distro = useTextEditingController(
      text: App.find<ApplicationMode>() == ApplicationMode.production
          ? 'arquivolta'
          : 'arch-dev',
    );

    final user = useTextEditingController(text: defaultUserName);
    final queueRedraw = useExplicitRedraw();
    final distroError = useFutureEffect(
      () async {
        final ret =
            await installer.errorMessageForProposedDistroName(distro.text);

        // NB: If we don't do this insanely gross hack, the form error message
        // will always be one character behind
        queueRedraw();
        return ret;
      },
      [distro.text],
    );

    // Reevaluate shouldEnableButton whenever any of the text changes
    [
      distro,
      user,
    ].forEach(useValueListenable);

    final shouldEnableButton = distro.text.length > 1 &&
        user.text.length > 1 &&
        distroError.data == null;

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

    final distroPrompt = InfoLabel(
      label: 'WSL Distro Name',
      child: TextFormBox(
        controller: distro,
        validator: (_) => distroError.data,
      ),
    );

    final userPrompt = InfoLabel(
      label: 'Linux Username',
      child: TextFormBox(
        controller: user,
        validator: (s) =>
            userRegex.hasMatch(s ?? '') ? null : 'Invalid username',
      ),
    );

    return Form(
      autovalidateMode: AutovalidateMode.always,
      child: Flex(
        direction: Axis.vertical,
        children: [
          distroPrompt,
          const SizedBox(
            height: 8,
          ),
          userPrompt,
          const Expanded(
            child: SizedBox(),
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
      ),
    );
  }
}
