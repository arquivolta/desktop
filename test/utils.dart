import 'package:arquivolta/app.dart';
import 'package:get_it/get_it.dart';

Future<void> setupForTest({
  required Future<void> Function() block,
  void Function(GetIt)? setup,
}) async {
  GetIt.instance.pushNewScope(
    init: (g) {
      App.setupRegistration(g);

      if (setup != null) {
        setup(g);
      }
    },
    scopeName: 'testScope',
  );

  try {
    await block();
  } finally {
    await GetIt.instance.popScope();
  }
}
