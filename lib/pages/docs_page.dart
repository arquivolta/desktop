import 'package:arquivolta/logging.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:url_launcher/url_launcher.dart';

class DocsPage extends HookWidget implements Loggable {
  const DocsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final style = FluentTheme.of(context);

    return ScaffoldPage(
      padding: const EdgeInsets.all(32),
      header: const PageHeader(
        title: Text('Documentation & Support'),
      ),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Documentation',
              style: style.typography.subtitle,
            ),
            const SizedBox(height: 8),
            Card(
              child: ListTile(
                leading: const Icon(FluentIcons.document),
                title: const Text('Documentation Site'),
                subtitle: const Text('Learn how to use Arquivolta'),
                trailing: const Icon(FluentIcons.link),
                onPressed: () =>
                    launchUrl(Uri.parse('https://docs.arquivolta.dev')),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Community & Support',
              style: style.typography.subtitle,
            ),
            const SizedBox(height: 8),
            Card(
              child: ListTile(
                leading: const Icon(FluentIcons.chat),
                title: const Text('Join Discord'),
                subtitle: const Text('Get help and chat with the community'),
                trailing: const Icon(FluentIcons.link),
                onPressed: () =>
                    launchUrl(Uri.parse('https://discord.gg/55mdue25qs')),
              ),
            ),
            /*
            const SizedBox(height: 8),
            Card(
              child: ListTile(
                leading: const Icon(FluentIcons.heart),
                title: const Text('Support Development'),
                subtitle: const Text('Support Arquivolta via GitHub Sponsors'),
                trailing: const Icon(FluentIcons.open),
                onPressed: () => launchUrl(
                    Uri.parse('https://github.com/sponsors/arquivolta')),
              ),
            ),
            */
            const SizedBox(height: 24),
            Text(
              'About',
              style: style.typography.subtitle,
            ),
            /*
            const SizedBox(height: 8),
            Card(
              child: ListTile(
                leading: const Icon(FluentIcons.history),
                title: const Text('Changelog'),
                subtitle: const Text("See what's new in Arquivolta"),
                trailing: const Icon(FluentIcons.open),
                onPressed: () => launchUrl(Uri.parse(
                    'https://github.com/arquivolta/desktop/releases')),
              ),
            ),
            */
            const SizedBox(height: 8),
            Card(
              child: ListTile(
                leading: const Icon(FluentIcons.code),
                title: const Text('Source Code'),
                subtitle: const Text('View the project on GitHub'),
                trailing: const Icon(FluentIcons.link),
                onPressed: () => launchUrl(
                    Uri.parse('https://github.com/arquivolta/desktop'),),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
