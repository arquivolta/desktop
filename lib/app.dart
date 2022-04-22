import 'package:arquivolta/interfaces.dart';
import 'package:arquivolta/logging.dart';
import 'package:arquivolta/pages/debug_page.dart';
import 'package:arquivolta/pages/install_begin_page.dart';
import 'package:arquivolta/pages/install_progress_page.dart';
import 'package:arquivolta/platform/registrations.dart';
import 'package:arquivolta/services/job.dart';
import 'package:arquivolta/widgets/page_scaffold.dart';
import 'package:beamer/beamer.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:get_it/get_it.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

class App {
  static GetIt find = GetIt.instance;

  static Future<GetIt> setupRegistration([GetIt? target]) async {
    var locator = target;
    if (locator == null) {
      locator = GetIt.instance;
      await locator.reset();
    }

    setupPlatformRegistrations(locator);
    JobBase.setupRegistration(locator);

    return find;
  }
}

class MainWindow extends StatelessWidget implements Loggable {
  late final RoutesLocationBuilder routesBuilder;
  late final BeamerDelegate delegate;

  MainWindow({Key? key}) : super(key: key) {
    i('Starting Arquivolta!');
  }

  @override
  Widget build(BuildContext context) {
    return FluentApp(
      color: Colors.blue,
      theme: ThemeData(
        visualDensity: VisualDensity.standard,
      ),
      home: PageScaffold(),
    );
  }
}
