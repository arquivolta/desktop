import 'package:arquivolta/interfaces.dart';
import 'package:arquivolta/platform/null/logger.dart'
    if (dart.library.io) 'package:arquivolta/platform/win32/logger.dart'
    if (dart.library.html) 'package:arquivolta/platform/web/logger.dart'
    as impl;
import 'package:logger/logger.dart';

Logger createLogger(ApplicationMode mode) {
  return impl.createLogger(mode);
}

bool isTestMode() {
  return impl.isTestMode();
}
