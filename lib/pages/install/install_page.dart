import 'package:arquivolta/actions.dart';
import 'package:arquivolta/app.dart';
import 'package:arquivolta/interfaces.dart';
import 'package:arquivolta/logging.dart';
import 'package:arquivolta/pages/install/install_progress.dart';
import 'package:arquivolta/pages/install/install_prompt.dart';
import 'package:arquivolta/util.dart';
import 'package:arquivolta/widgets/paged_view.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

class InstallPage extends HookWidget implements Loggable {
  const InstallPage({super.key});

  @override
  Widget build(BuildContext context) {
    final distroName = useRef('');
    final username = useRef('');
    final password = useRef('');
    final installer = useState(App.find<ArchLinuxInstaller>());

    final pageController = usePagedViewController();
    final languageTag =
        View.of(context).platformDispatcher.locale.toLanguageTag();

    final installResult = useAction(
      () async {
        n('Clicked Install: ${distroName.value}');

        d('Starting Phase 1');
        final worker = await installer.value.installArchLinux(distroName.value);

        d('Starting Phase 2');
        await installer.value.runArchLinuxPostInstall(
          worker,
          username.value,
          password.value,
          languageTag,
        );

        i('Completed install!');
      },
      [],
    );

    final content = PagedViewWidget(pageController, (ctx, ctrl) {
      if (ctrl.page.value == 0) {
        return InstallPrompt(
          defaultUserName: installer.value.getDefaultUsername(),
          onPressedInstall: (d, u, p) {
            distroName.value = d;
            username.value = u;
            password.value = p;

            i('Next clicked, moving to install in-progress page');
            pageController.next();

            // NB: Without doing this, InProgressInstall will miss the first
            // job, which is important because it's usually a download
            delayBeat(installResult.invoke);
          },
        );
      }

      if (ctrl.page.value == 1) {
        return InProgressInstall(
          finished: !installResult.isPending,
          error: installResult.result.error,
        );
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
