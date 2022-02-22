import 'package:arquivolta/actions.dart';
import 'package:arquivolta/arch_to_rootfs.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

class InstallPage extends HookWidget {
  final String title;

  const InstallPage({Key? key, required this.title}) : super(key: key);

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
