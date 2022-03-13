import 'package:arquivolta/actions.dart';
import 'package:arquivolta/app.dart';
import 'package:arquivolta/interfaces.dart';
import 'package:arquivolta/logging.dart';
import 'package:arquivolta/pages/page_base.dart';
import 'package:arquivolta/services/job.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

class DebugPage extends HookWidget
    with PageScaffolder
    implements RoutablePages, Loggable {
  DebugPage({required Key key}) : super(key: key);

  @override
  BeamerRouteList registerRoutes() => {};

  @override
  List<PageInfo> registerPages() {
    return [
      PageInfo(
        '/debug',
        'Debug',
        () => FluentIcons.device_bug,
        (ctx, _state, _) => buildScaffoldContent(
          ctx,
          DebugPage(key: const Key('debug')),
        ),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return const Text('hi');
  }
}
