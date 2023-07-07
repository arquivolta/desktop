import 'package:arquivolta/logging.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

class InstallFinishedPage extends HookWidget implements Loggable {
  final VoidCallback onWindowsTerminalOpen;
  const InstallFinishedPage({required this.onWindowsTerminalOpen, super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Installation Complete! Open Windows Terminal to start using Arquivolta',
        ),
        const Expanded(
          child: Center(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Image(
                image: AssetImage('assets/finished.webp'),
              ),
            ),
          ),
        ),
        Center(
          child: FilledButton(
            onPressed: onWindowsTerminalOpen,
            child: const Text('Open Windows Terminal'),
          ),
        )
      ],
    );
  }
}
