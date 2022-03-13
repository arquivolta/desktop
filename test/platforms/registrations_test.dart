// ignore_for_file: library_prefixes

import 'package:arquivolta/interfaces.dart';
import 'package:arquivolta/platform/null/registrations.dart' as nullImpl;
import 'package:arquivolta/platform/registrations.dart' as platImpl;
import 'package:get_it/get_it.dart';
import 'package:logger/logger.dart';
import 'package:test/test.dart';

void main() {
  test('null registrations should have the same types as platform ones', () {
    final nullLoc = GetIt.asNewInstance();
    final platLoc = GetIt.asNewInstance();

    nullImpl.setupPlatformRegistrations(nullLoc);
    platImpl.setupPlatformRegistrations(platLoc);

    for (final loc in [nullLoc, platLoc]) {
      expect(loc.get<ApplicationMode>(), isNotNull);
      expect(loc.get<Logger>(), isNotNull);
    }
  });
}
