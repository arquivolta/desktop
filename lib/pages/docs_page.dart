import 'package:arquivolta/logging.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

class DocsPage extends HookWidget implements Loggable {
  const DocsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final style = FluentTheme.of(context);

    // Things that should be on this page
    //
    // * Link to main documentation site
    // * Maybe some helpful other pages like yay cheatsheet?
    // * Discord join link
    // * Patreon / GitHub Sponsors link
    // * Version Info / Link to Changelog

    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Learn More About Arquivolta',
            style: style.typography.titleLarge,
          ),
          const Text(
            '',
          ),
        ],
      ),
    );
  }
}
