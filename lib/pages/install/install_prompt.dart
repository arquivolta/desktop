import 'package:arquivolta/logging.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

class InstallPrompt extends HookWidget implements Loggable {
  final void Function(String distro, String user, String password)
      onPressedInstall;

  const InstallPrompt({required this.onPressedInstall, super.key});

  @override
  Widget build(BuildContext context) {
    final distro = useTextEditingController(text: 'arch-foobar');
    final user = useTextEditingController();
    //final password = useTextEditingController();
    //final passwordHidden = useState(true);

    // Reevaluate shouldEnableButton whenever any of the text changes
    [
      distro,
      user, /*password*/
    ].forEach(useValueListenable);

    final shouldEnableButton = distro.text.length > 1 &&
        user.text.length > 1; //&& password.text.length > 1;

    final onPress = useCallback(
      () => onPressedInstall(
        distro.text,
        user.text,
        '', //password.text,
      ),
      [
        distro,
        user, /*password*/
      ],
    );

    return Flex(
      direction: Axis.vertical,
      children: [
        TextBox(
          controller: distro,
          //XXX: header: 'WSL Distro Name',
        ),
        TextBox(
          controller: user,
          //XXX: header: 'Linux Username',
        ),
        /*
        TextBox(
          controller: password,
          header: 'Password',
          obscureText: passwordHidden.value,
          suffix: IconButton(
            icon: Icon(
              passwordHidden.value ? FluentIcons.lock : FluentIcons.unlock,
            ),
            onPressed: () => passwordHidden.value = !passwordHidden.value,
          ),
        ),
        */
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
