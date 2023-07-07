import 'package:arquivolta/logging.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

class InstallFinishedPage extends HookWidget implements Loggable {
  final VoidCallback onWindowsTerminalOpen;
  const InstallFinishedPage({required this.onWindowsTerminalOpen, super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Image.asset('finished.webp'),
          ),
        ),
        Center(
          child: FilledButton(
            onPressed: () => onWindowsTerminalOpen,
            child: const Text('Open Windows Terminal'),
          ),
        )
      ],
    );
  }
}
