import 'package:arquivolta/actions.dart';
import 'package:arquivolta/app.dart';
import 'package:arquivolta/interfaces.dart';
import 'package:arquivolta/logging.dart';
import 'package:arquivolta/pages/install_progress_page.dart';
import 'package:arquivolta/widgets/paged_view.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

class InstallPage extends HookWidget implements Loggable {
  const InstallPage({required Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final distroName = useRef('');
    final username = useRef('');
    final password = useRef('');

    final pageController = useMemoized(() => PagedViewController(2), []);

    final installResult = useAction(
      () async {
        n('Clicked Install: ${distroName.value}');
        final installer = App.find<ArchLinuxInstaller>();

        d('Starting Phase 1');
        final worker = await installer.installArchLinux(distroName.value);

        d('Starting Phase 2');
        await installer.runArchLinuxPostInstall(
          worker,
          username.value,
          password.value,
        );

        i('Completed install!');
      },
      [],
    );

    final content = PagedViewWidget(pageController, (ctx, ctrl) {
      if (ctrl.page.value == 0) {
        return InstallPrompt(
          onPressedInstall: (d, u, p) {
            distroName.value = d;
            username.value = u;
            password.value = p;

            pageController.next();
            installResult.invoke();
          },
        );
      }

      if (ctrl.page.value == 1) {
        return const InProgressInstallPage();
      }

      throw Exception('Wrong page?!?!');
    });

    final style = FluentTheme.of(context);
    final headerText = installResult.isPending
        ? 'Installing Arch Linux to ${distroName.value}'
        : 'Install Arch Linux';

    return Padding(
      padding: const EdgeInsets.all(32),
      child: Flex(
        direction: Axis.vertical,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(headerText, style: style.typography.titleLarge),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: content,
            ),
          ),
        ],
      ),
    );
  }
}

class InstallPrompt extends HookWidget implements Loggable {
  final void Function(String distro, String user, String password)
      onPressedInstall;

  const InstallPrompt({Key? key, required this.onPressedInstall})
      : super(key: key);

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
          header: 'WSL Distro Name',
        ),
        TextBox(
          controller: user,
          header: 'Linux Username',
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
