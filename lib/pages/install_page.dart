import 'package:arquivolta/actions.dart';
import 'package:arquivolta/app.dart';
import 'package:arquivolta/interfaces.dart';
import 'package:arquivolta/logging.dart';
import 'package:arquivolta/pages/page_base.dart';
import 'package:arquivolta/services/arch_to_rootfs.dart';
import 'package:arquivolta/services/job.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

class InstallPage extends HookWidget
    with PageScaffolder
    implements RoutablePages, Loggable {
  InstallPage({required Key key}) : super(key: key);

  @override
  BeamerRouteList registerRoutes() => {};

  @override
  List<PageInfo> registerPages() {
    return [
      PageInfo(
        '/',
        'Install',
        () => FluentIcons.download,
        (ctx, _state, _) => buildScaffoldContent(
          ctx,
          InstallPage(key: const Key('install')),
        ),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final distroName = useRef('');
    final username = useRef('');
    final password = useRef('');

    final installResult = useAction(
      () async {
        await installArchLinuxJob(distroName.value).execute();

        i('We did it!');
      },
      [],
    );

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
            child: installResult.isPending
                ? const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: InProgressInstall(),
                  )
                : Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: InstallPrompt(onPressedInstall: (d, u, p) {
                      distroName.value = d;
                      username.value = u;
                      password.value = p;
                      installResult.invoke();
                    }),
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
    final password = useTextEditingController();
    final passwordHidden = useState(true);

    // Reevaluate shouldEnableButton whenever any of the text changes
    [distro, user, password].forEach(useValueListenable);

    final shouldEnableButton = distro.text.length > 1 &&
        user.text.length > 1 &&
        password.text.length > 1;

    final onPress = useCallback(
      () => onPressedInstall(
        distro.text,
        user.text,
        password.text,
      ),
      [distro, user, password],
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

class InProgressInstall extends HookWidget implements Loggable {
  const InProgressInstall({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final style = FluentTheme.of(context);
    final jobList = useState(<JobBase<dynamic>>[]);
    final selectedIndex = useState(-1);

    useEffect(
      () {
        final sub = JobBase.jobStream.listen((job) {
          d('Found a job!');
          jobList.value = [...jobList.value, job];
        });

        return sub.cancel;
      },
      [],
    );

    return Flex(
      direction: Axis.horizontal,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Scrollbar(
          child: Padding(
            padding: const EdgeInsets.only(right: 16),
            child: SizedBox(
              width: 600,
              height: 200,
              child: ListView.builder(
                itemCount: jobList.value.length,
                itemBuilder: (ctx, i) => TappableListTile(
                  key: Key(jobList.value[i].friendlyName),
                  tileColor: selectedIndex.value == i
                      ? ButtonState.all(style.accentColor)
                      : null,
                  title: Text(
                    jobList.value[i].friendlyName,
                    style: style.typography.bodyStrong,
                  ),
                  subtitle: Text(
                    jobList.value[i].friendlyDescription,
                    style: style.typography.body,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  onTap: () => selectedIndex.value = i,
                ),
              ),
            ),
          ),
        ),
        Expanded(
          child: Container(color: Colors.red, child: const Text('A box')),
        )
      ],
    );
  }
}
