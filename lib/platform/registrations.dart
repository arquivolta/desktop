import 'package:arquivolta/platform/null/registrations.dart'
    if (dart.library.io) 'package:arquivolta/platform/win32/logger.dart'
    if (dart.library.html) 'package:arquivolta/platform/web/logger.dart'
    as impl;

import 'package:get_it/get_it.dart';

GetIt setupPlatformRegistrations(GetIt locator) {
  return impl.setupPlatformRegistrations(locator);
}
