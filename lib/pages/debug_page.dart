import 'package:arquivolta/actions.dart';
import 'package:arquivolta/app.dart';
import 'package:arquivolta/interfaces.dart';
import 'package:arquivolta/logging.dart';
import 'package:arquivolta/widgets/page_scaffold.dart';
import 'package:arquivolta/services/job.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

class DebugPage extends HookWidget implements Loggable {
  const DebugPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const Text('hi');
  }
}