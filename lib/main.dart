import 'package:arquivolta/app.dart';
import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_acrylic/flutter_acrylic.dart' as flutter_acrylic;

// ignore: avoid_void_async
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  App.setupRegistration();

  await flutter_acrylic.Window.initialize();

  runApp(const MainWindow());

  doWhenWindowReady(() {
    appWindow
      ..minSize = const Size(410, 540)
      ..size = const Size(755, 545)
      ..alignment = Alignment.center
      ..title = 'Arquivolta Installer'
      ..show();
  });
}
