import 'package:arquivolta/actions.dart';
import 'package:arquivolta/app.dart';
import 'package:arquivolta/interfaces.dart';
import 'package:arquivolta/pages/page_base.dart';
import 'package:arquivolta/services/arch_to_rootfs.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

class InstallPage extends HookWidget
    with PageScaffolder
    implements RoutablePages {
  const InstallPage({required Key key}) : super(key: key);

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
          const InstallPage(key: Key('install')),
        ),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final counter = useState(0);

    final installResult = useAction(
      () async {
        await installArchLinux('arch-foobar');
        counter.value++;
      },
      [
        counter,
      ],
    );

    return Center(
        child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        const Text(
          'You have pushed the button this many times:',
        ),
        Text(
          '${counter.value}',
        ),
        if (installResult.isPending)
          const ProgressRing()
        else
          Button(
            onPressed: installResult.invoke,
            child: const Text('Install Arch Linux'),
          ),
      ],
    ));
  }
}
