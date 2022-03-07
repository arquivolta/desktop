import 'package:arquivolta/app.dart';
import 'package:logger/logger.dart';

abstract class Loggable {}

abstract class CustomLoggable {
  Logger get logger;
}

extension LoggableMixin on Loggable {
  static Logger? _global;

  void d(dynamic message, [dynamic error, StackTrace? stackTrace]) {
    final _klass = runtimeType.toString();
    _global ??= App.find<Logger>();

    _global!.d('$_klass: $message', error, stackTrace);
    if (this is CustomLoggable) {
      (this as CustomLoggable).logger.d('$_klass: $message', error, stackTrace);
    }
  }

  void i(dynamic message, [dynamic error, StackTrace? stackTrace]) {
    final _klass = runtimeType.toString();
    _global ??= App.find<Logger>();

    _global!.i('$_klass: $message', error, stackTrace);
    if (this is CustomLoggable) {
      (this as CustomLoggable).logger.i('$_klass: $message', error, stackTrace);
    }
  }

  void w(dynamic message, [dynamic error, StackTrace? stackTrace]) {
    final _klass = runtimeType.toString();
    _global ??= App.find<Logger>();

    _global!.w('⚠️ $_klass: $message', error, stackTrace);
    if (this is CustomLoggable) {
      (this as CustomLoggable)
          .logger
          .w('⚠️ $_klass: $message', error, stackTrace);
    }
  }

  void e(dynamic message, [dynamic error, StackTrace? stackTrace]) {
    final _klass = runtimeType.toString();
    _global ??= App.find<Logger>();

    _global!.e('�� $_klass: $message', error, stackTrace);
    if (this is CustomLoggable) {
      (this as CustomLoggable)
          .logger
          .e('�� $_klass: $message', error, stackTrace);
    }
  }

  void wtf(dynamic message, [dynamic error, StackTrace? stackTrace]) {
    final _klass = runtimeType.toString();
    _global ??= App.find<Logger>();

    _global!.wtf('�� _klass: $message', error, stackTrace);
    if (this is CustomLoggable) {
      (this as CustomLoggable)
          .logger
          .wtf('�� $_klass: $message', error, stackTrace);
    }
  }
}
