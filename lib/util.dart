import 'dart:async';

import 'package:arquivolta/app.dart';

// NB: Doing this inline introduces too much syntactic noise
void delayBeat(dynamic Function() block) {
  unawaited(
    Future<void>.delayed(const Duration(milliseconds: 20))
        .then((_v) => block()),
  );
}

Future<void> openLogFileInDefaultEditor() async {
  final fn = App.find.get<Future<void> Function()>(instanceName: 'openLog');
  await fn();
}
