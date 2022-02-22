import 'package:arquivolta/app.dart';
import 'package:arquivolta/interfaces.dart';
import 'package:beamer/beamer.dart';
import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:window_manager/window_manager.dart';

mixin PageScaffolder implements RoutablePages {
  Widget buildScaffoldContent(BuildContext context, Widget body) {
    final beamState = Beamer.of(context).currentBeamLocation.state as BeamState;
    final pages = App.find<BeamerPageList>();

    final uri = beamState.uri.toString();
    final idx = pages.indexWhere((p) => p.route.matchAsPrefix(uri) != null);

    return NavigationView(
      appBar: NavigationAppBar(
        title: const DragToMoveArea(
          child: Align(
            alignment: AlignmentDirectional.centerStart,
            child: Text('Arquivolta Installer'),
          ),
        ),
        actions: DragToMoveArea(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [Spacer(), WindowButtons()],
          ),
        ),
        automaticallyImplyLeading: false,
      ),
      pane: NavigationPane(
        selected: idx,
        size: const NavigationPaneSize(
          openMinWidth: 250,
          openMaxWidth: 320,
        ),
        items: pages
            .map<NavigationPaneItem>(
              (e) => PaneItem(
                icon: Icon(
                  e.sidebarIcon(),
                ),
                title: Text(e.sidebarName),
              ),
            )
            .toList(),
      ),
      content: body,
    );
  }
}

class WindowButtons extends StatelessWidget {
  const WindowButtons({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = FluentTheme.of(context);
    final buttonColors = WindowButtonColors(
      iconNormal: theme.inactiveColor,
      iconMouseDown: theme.inactiveColor,
      iconMouseOver: theme.inactiveColor,
      mouseOver: ButtonThemeData.buttonColor(
        theme.brightness,
        {ButtonStates.hovering},
      ),
      mouseDown: ButtonThemeData.buttonColor(
        theme.brightness,
        {ButtonStates.pressing},
      ),
    );

    final closeButtonColors = WindowButtonColors(
      mouseOver: Colors.red,
      mouseDown: Colors.red.dark,
      iconNormal: theme.inactiveColor,
      iconMouseOver: Colors.red.basedOnLuminance(),
      iconMouseDown: Colors.red.dark.basedOnLuminance(),
    );

    return Row(
      children: [
        Tooltip(
          message: FluentLocalizations.of(context).minimizeWindowTooltip,
          child: MinimizeWindowButton(colors: buttonColors),
        ),
        Tooltip(
          message: FluentLocalizations.of(context).restoreWindowTooltip,
          child: WindowButton(
            colors: buttonColors,
            iconBuilder: (context) {
              if (appWindow.isMaximized) {
                return RestoreIcon(color: context.iconColor);
              }
              return MaximizeIcon(color: context.iconColor);
            },
            onPressed: appWindow.maximizeOrRestore,
          ),
        ),
        Tooltip(
          message: FluentLocalizations.of(context).closeWindowTooltip,
          child: CloseWindowButton(colors: closeButtonColors),
        ),
      ],
    );
  }
}
