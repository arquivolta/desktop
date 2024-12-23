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

    _global!.d('$klass: $message');
    if (this is CustomLoggable) {
      final cl = this as CustomLoggable;
      if (cl.usePrefix) {
        (this as CustomLoggable)
            .logger
            .d('$klass: $message');
      } else {
        (this as CustomLoggable).logger.d('$message');
      }
    }
  }

  void i(dynamic message, [dynamic error, StackTrace? stackTrace]) {
    final klass = runtimeType.toString();
    _global ??= App.find<Logger>();

    _global!.i('$klass: $message');
    if (this is CustomLoggable) {
      final cl = this as CustomLoggable;
      if (cl.usePrefix) {
        (this as CustomLoggable)
            .logger
            .i('$klass: $message');
      } else {
        (this as CustomLoggable).logger.i('$message');
      }
    }
  }

  void w(dynamic message, [dynamic error, StackTrace? stackTrace]) {
    final klass = runtimeType.toString();
    _global ??= App.find<Logger>();

    _global!.w('⚠️ $klass: $message');

    if (this is CustomLoggable) {
      final cl = this as CustomLoggable;
      if (cl.usePrefix) {
        (this as CustomLoggable)
            .logger
            .w('⚠️ $klass: $message');
      } else {
        (this as CustomLoggable).logger.w('⚠️ $message');
      }
    }
  }

  void e(dynamic message, [dynamic error, StackTrace? stackTrace]) {
    final klass = runtimeType.toString();
    _global ??= App.find<Logger>();

    _global!.e('�� $klass: $message');
    if (this is CustomLoggable) {
      (this as CustomLoggable)
          .logger
          .e('�� $klass: $message');
    }
  }

  void f(dynamic message, [dynamic error, StackTrace? stackTrace]) {
    final klass = runtimeType.toString();
    _global ??= App.find<Logger>();

    _global!.f('�� $klass: $message');
    if (this is CustomLoggable) {
      (this as CustomLoggable)
          .logger
          .f('�� $klass: $message');
    }
  }

  void n(String message) {
    Sentry.addBreadcrumb(Breadcrumb(message: message, type: 'navigation'));
    i(message);
  }
}
