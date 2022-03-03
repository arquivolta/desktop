import 'package:arquivolta/app.dart';
import 'package:beamer/beamer.dart';
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
