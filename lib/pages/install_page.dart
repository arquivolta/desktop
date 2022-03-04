import 'package:arquivolta/actions.dart';
import 'package:arquivolta/app.dart';
import 'package:arquivolta/interfaces.dart';
import 'package:arquivolta/logging.dart';
import 'package:arquivolta/pages/page_base.dart';
import 'package:arquivolta/services/arch_to_rootfs.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:rxdart/rxdart.dart';

class InstallPage extends HookWidget
    with PageScaffolder, LoggableMixin
    implements RoutablePages {
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
    final counter = useState(0);
    final progress = useState<double>(0);

    final installResult = useAction(
      () async {
        final progressSubj = PublishSubject<double>();
        progressSubj
            .sampleTime(const Duration(milliseconds: 250))
            .doOnData((p) => d('Progress: $p'))
            .listen((x) => progress.value = x);

        await installArchLinuxJob('arch-foobar').execute(progressSubj.sink);
        i('We did it!');
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
            ProgressRing(
              value: progress.value,
            )
          else
            Button(
              onPressed: installResult.invoke,
              child: const Text('Install Arch Linux'),
            ),
        ],
      ),
    );
  }
}
