import 'dart:io';

import 'package:arquivolta/interfaces.dart';
import 'package:arquivolta/logging.dart';
import 'package:arquivolta/pages/install_page.dart';
import 'package:arquivolta/services/job.dart';
import 'package:arquivolta/services/util.dart';
import 'package:beamer/beamer.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:get_it/get_it.dart';
import 'package:logger/logger.dart';

// ignore: implementation_imports
import 'package:logger/src/outputs/file_output.dart';

enum ApplicationMode { debug, production, test }

typedef BeamerRouteList
    = Map<Pattern, dynamic Function(BuildContext, BeamState, Object?)>;

typedef BeamerPageList = List<PageInfo>;

Logger createLogger(ApplicationMode mode) {
  if (mode == ApplicationMode.production) {
    final appData = getLocalAppDataPath();
    final ourAppDataDir = Directory('$appData/Arquivolta')
      ..createSync(recursive: true);

    return Logger(
      output: FileOutput(file: File('${ourAppDataDir.path}/log.txt')),
      printer: PrettyPrinter(
        methodCount: 0,
        errorMethodCount: 4,
        excludeBox: {
          Level.debug: true,
          Level.info: true,
          Level.verbose: true,
        },
        colors: false,
        printEmojis: false, // NB: We add these in later
      ),
      level: Level.info,
    );
  }

  return Logger(
    printer: PrettyPrinter(
      methodCount: 0,
      errorMethodCount: 4,
      excludeBox: {
        Level.debug: true,
        Level.info: true,
        Level.verbose: true,
      },
      colors: false,
      printEmojis: false, // NB: We add these in later
    ),
  );
}

class App {
  static GetIt find = GetIt.instance;

  static Future<GetIt> setupRegistration([GetIt? target]) async {
    var locator = target;
    if (locator == null) {
      locator = GetIt.instance;
      await locator.reset();
    }

    final isTestMode = Platform.resolvedExecutable.contains('_tester');
    var isDebugMode = false;

    // NB: Assert statements are stripped from release mode. Clever!
    // ignore: prefer_asserts_with_message
    assert(isDebugMode = true);

    final appMode = isTestMode
        ? ApplicationMode.test
        : isDebugMode
            ? ApplicationMode.debug
            : ApplicationMode.production;

    find
      ..registerSingleton(appMode)
      ..registerSingleton(createLogger(appMode));

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
    delegate = BeamerDelegate(locationBuilder: routesBuilder);

    d('Creating MainWindow!');
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
