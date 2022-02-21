import 'package:arquivolta/actions.dart';
import 'package:arquivolta/arch_to_rootfs.dart';
import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_acrylic/flutter_acrylic.dart' as flutter_acrylic;
import 'package:flutter_hooks/flutter_hooks.dart';

// ignore: avoid_void_async
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await flutter_acrylic.Window.initialize();

  runApp(const MyApp());

  doWhenWindowReady(() {
    appWindow
      ..minSize = const Size(410, 540)
      ..size = const Size(755, 545)
      ..alignment = Alignment.center
      ..title = 'Arquivolta Installer'
      ..show();
  });
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return FluentApp(
      title: 'Flutter Demo',
      color: Colors.blue,
      theme: ThemeData(
        visualDensity: VisualDensity.standard,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends HookWidget {
  final String title;

  const MyHomePage({Key? key, required this.title}) : super(key: key);

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

    return NavigationView(
      appBar: NavigationAppBar(
        title: Text(title),
      ),
      content: Center(
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
        ),
      ),
    );
  }
}
