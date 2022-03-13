import 'package:arquivolta/app.dart';
import 'package:arquivolta/interfaces.dart';
import 'package:arquivolta/widgets/window_button.dart';
import 'package:beamer/beamer.dart';
import 'package:bitsdojo_window/bitsdojo_window.dart'
    show MaximizeIcon, RestoreIcon, appWindow;
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/foundation.dart';
import 'package:window_manager/window_manager.dart';

mixin PageScaffolder implements RoutablePages {
  Widget buildScaffoldContent(BuildContext context, Widget body) {
    final beamState = Beamer.of(context).currentBeamLocation.state as BeamState;
    final pages = App.find<BeamerPageList>();

    final uri = beamState.uri.toString();
    final idx = pages.indexWhere((p) => p.route.matchAsPrefix(uri) != null);

    final style = FluentTheme.of(context);

    return NavigationView(
      appBar: NavigationAppBar(
        title: DragToMoveArea(
          child: Align(
            alignment: AlignmentDirectional.centerStart,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                'Arquivolta Installer',
                style: style.typography.bodyStrong,
              ),
            ),
          ),
        ),
        actions: DragToMoveArea(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: const [
              Spacer(),
              if (!kIsWeb)
                WindowButtons(
                  height: 50,
                )
            ],
          ),
        ),
        automaticallyImplyLeading: false,
      ),
      pane: NavigationPane(
        // NB: Auto looks nicer here but it's broken at the moment
        // because when the pane is open the Title gets no padding
        displayMode: PaneDisplayMode.open,
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
  final double? height;
  const WindowButtons({Key? key, this.height}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    var size = appWindow.titleBarButtonSize;

    if (height != null) {
      final ratio = height! / appWindow.titleBarButtonSize.height;

      size = Size(
        appWindow.titleBarButtonSize.width * ratio,
        appWindow.titleBarButtonSize.height * ratio,
      );
    }

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
          child: MinimizeWindowButton(
            colors: buttonColors,
            buttonSize: size,
          ),
        ),
        Tooltip(
          message: FluentLocalizations.of(context).restoreWindowTooltip,
          child: WindowButton(
            buttonSize: size,
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
          child: CloseWindowButton(buttonSize: size, colors: closeButtonColors),
        ),
      ],
    );
  }
}
