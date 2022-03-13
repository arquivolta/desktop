import 'package:arquivolta/platform/null/registrations.dart'
    if (dart.library.io) 'package:arquivolta/platform/win32/registrations.dart'
    if (dart.library.html) 'package:arquivolta/platform/web/registrations.dart'
    as impl;

import 'package:get_it/get_it.dart';

GetIt setupPlatformRegistrations(GetIt locator) {
  return impl.setupPlatformRegistrations(locator);
}
