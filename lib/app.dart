import 'dart:async';

import 'package:arquivolta/logging.dart';
import 'package:arquivolta/platform/registrations.dart';
import 'package:arquivolta/services/job.dart';
import 'package:arquivolta/widgets/page_scaffold.dart';
import 'package:beamer/beamer.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:get_it/get_it.dart';

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

  MainWindow({super.key}) {
    i('Starting Arquivolta!');
  }

  @override
  Widget build(BuildContext context) {
    final isDark = MediaQuery.of(context).platformBrightness == Brightness.dark;

    return FluentApp(
      theme: FluentThemeData(
        brightness: Brightness.light,
        visualDensity: VisualDensity.standard,
      ),
      darkTheme: FluentThemeData(
        brightness: Brightness.dark,
        visualDensity: VisualDensity.standard,
      ),
      themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
      home: const PageScaffold(),
    );
  }
}
