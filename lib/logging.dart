import 'package:arquivolta/app.dart';
import 'package:logger/logger.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

abstract class Loggable {}

abstract class CustomLoggable {
  Logger get logger;
  bool usePrefix = false;
}

extension LoggableMixin on Loggable {
  static Logger? _global;

  void d(dynamic message, [dynamic error, StackTrace? stackTrace]) {
    final klass = runtimeType.toString();
    _global ??= App.find<Logger>();

    _global!.d('$klass: $message', error, stackTrace);
    if (this is CustomLoggable) {
      final cl = this as CustomLoggable;
      if (cl.usePrefix) {
        (this as CustomLoggable)
            .logger
            .d('$klass: $message', error, stackTrace);
      } else {
        (this as CustomLoggable).logger.d('$message', error, stackTrace);
      }
    }
  }

  void i(dynamic message, [dynamic error, StackTrace? stackTrace]) {
    final klass = runtimeType.toString();
    _global ??= App.find<Logger>();

    _global!.i('$klass: $message', error, stackTrace);
    if (this is CustomLoggable) {
      final cl = this as CustomLoggable;
      if (cl.usePrefix) {
        (this as CustomLoggable)
            .logger
            .i('$klass: $message', error, stackTrace);
      } else {
        (this as CustomLoggable).logger.i('$message', error, stackTrace);
      }
    }
  }

  void w(dynamic message, [dynamic error, StackTrace? stackTrace]) {
    final klass = runtimeType.toString();
    _global ??= App.find<Logger>();

    _global!.w('⚠️ $klass: $message', error, stackTrace);

    if (this is CustomLoggable) {
      final cl = this as CustomLoggable;
      if (cl.usePrefix) {
        (this as CustomLoggable)
            .logger
            .i('⚠️ $klass: $message', error, stackTrace);
      } else {
        (this as CustomLoggable).logger.i('⚠️ $message', error, stackTrace);
      }
    }
  }

  void e(dynamic message, [dynamic error, StackTrace? stackTrace]) {
    final klass = runtimeType.toString();
    _global ??= App.find<Logger>();

    _global!.e('�� $klass: $message', error, stackTrace);
    if (this is CustomLoggable) {
      (this as CustomLoggable)
          .logger
          .e('�� $klass: $message', error, stackTrace);
    }
  }

  void wtf(dynamic message, [dynamic error, StackTrace? stackTrace]) {
    final klass = runtimeType.toString();
    _global ??= App.find<Logger>();

    _global!.wtf('�� _klass: $message', error, stackTrace);
    if (this is CustomLoggable) {
      (this as CustomLoggable)
          .logger
          .wtf('�� $klass: $message', error, stackTrace);
    }
  }

  void n(String message) {
    Sentry.addBreadcrumb(Breadcrumb(message: message, type: 'navigation'));
    i(message);
  }
}
