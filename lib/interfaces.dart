import 'package:arquivolta/app.dart';
import 'package:beamer/beamer.dart';
import 'package:logger/logger.dart';
import 'package:flutter/widgets.dart';

// ignore: one_member_abstracts
// ignore: use_key_in_widget_constructors
abstract class Routable extends Widget {
  BeamerRouteList registerRoutes();
}

class PageInfo {
  final String sidebarName;
  final IconData Function() sidebarIcon;
  final dynamic Function(BuildContext, BeamState, Object?) builder;
  final Pattern route;

  PageInfo(this.route, this.sidebarName, this.sidebarIcon, this.builder);
}

// ignore: use_key_in_widget_constructors
abstract class RoutablePages extends Routable {
  List<PageInfo> registerPages();
}

abstract class Loggable {}

mixin LoggableMixin implements Loggable {
  String? _klass;
  Logger? _global;

  void d(dynamic message, [dynamic error, StackTrace? stackTrace]) {
    _klass ??= runtimeType.toString();
    _global ??= App.find<Logger>();

    _global!.d('$_klass: $message', error, stackTrace);
  }

  void i(dynamic message, [dynamic error, StackTrace? stackTrace]) {
    _klass ??= runtimeType.toString();
    _global ??= App.find<Logger>();

    _global!.i('$_klass: $message', error, stackTrace);
  }

  void w(dynamic message, [dynamic error, StackTrace? stackTrace]) {
    _klass ??= runtimeType.toString();
    _global ??= App.find<Logger>();

    _global!.w('⚠️ $_klass: $message', error, stackTrace);
  }

  void e(dynamic message, [dynamic error, StackTrace? stackTrace]) {
    _klass ??= runtimeType.toString();
    _global ??= App.find<Logger>();

    _global!.e('�� $_klass: $message', error, stackTrace);
  }

  void wtf(dynamic message, [dynamic error, StackTrace? stackTrace]) {
    _klass ??= runtimeType.toString();
    _global ??= App.find<Logger>();

    _global!.wtf('�� _klass: $message', error, stackTrace);
  }
}
