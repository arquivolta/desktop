import 'dart:io';

import 'package:arquivolta/pages/install_page.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:get_it/get_it.dart';

enum ApplicationMode { debug, production, test }

class App {
  static GetIt find = GetIt.instance;

  static GetIt setupRegistration([GetIt? target]) {
    var locator = target;
    locator ??= GetIt.instance..reset();

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

    find.registerSingleton(appMode);
    return find;
  }
}

class MainWindow extends HookWidget {
  const MainWindow({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FluentApp(
      title: 'Flutter Demo',
      color: Colors.blue,
      theme: ThemeData(
        visualDensity: VisualDensity.standard,
      ),
      home: const InstallPage(title: 'Flutter Demo Home Page'),
    );
  }
}
