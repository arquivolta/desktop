import 'package:arquivolta/interfaces.dart';
import 'package:arquivolta/logging.dart';
import 'package:arquivolta/pages/install_page.dart';
import 'package:arquivolta/platform/registrations.dart';
import 'package:arquivolta/services/job.dart';
import 'package:beamer/beamer.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:get_it/get_it.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

typedef BeamerRouteList
    = Map<Pattern, dynamic Function(BuildContext, BeamState, Object?)>;

typedef BeamerPageList = List<PageInfo>;

class App {
  static GetIt find = GetIt.instance;

  static Future<GetIt> setupRegistration([GetIt? target]) async {
    var locator = target;
    if (locator == null) {
      locator = GetIt.instance;
      await locator.reset();
    }

    setupPlatformRegistrations(find);
    JobBase.setupRegistration(find);

    _setupRoutes(find);
    return find;
  }

  static GetIt _setupRoutes(GetIt locator) {
    final pageList = [
      (InstallPage(key: const Key('dontcare')).registerPages()),
    ].reduce((acc, x) => [...acc, ...x]);

    locator
      ..registerSingleton<BeamerRouteList>(
        pageList.fold({}, (acc, p) => {...acc, p.route: p.builder}),
      )
      ..registerSingleton<BeamerPageList>(pageList);

    return locator;
  }
}

class MainWindow extends StatelessWidget implements Loggable {
  late final RoutesLocationBuilder routesBuilder;
  late final BeamerDelegate delegate;

  MainWindow({Key? key}) : super(key: key) {
    // NB: If we don't do this here we get a crash on hot reload.
    routesBuilder = RoutesLocationBuilder(routes: App.find<BeamerRouteList>());
    delegate = BeamerDelegate(
      locationBuilder: routesBuilder,
      navigatorObservers: [SentryNavigatorObserver()],
    );

    i('Starting Arquivolta!');
  }

  @override
  Widget build(BuildContext context) {
    return FluentApp.router(
      color: Colors.blue,
      theme: ThemeData(
        visualDensity: VisualDensity.standard,
      ),
      routeInformationParser: BeamerParser(),
      routerDelegate: delegate,
    );
  }
}
