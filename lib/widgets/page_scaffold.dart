import 'package:arquivolta/pages/debug_page.dart';
import 'package:arquivolta/pages/install/install_page.dart';
import 'package:arquivolta/widgets/window_button.dart';
import 'package:bitsdojo_window/bitsdojo_window.dart'
    show MaximizeIcon, RestoreIcon, appWindow;
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:window_manager/window_manager.dart';

final List<Widget Function(Key key)> pageContentGenerator = [
  (k) => DebugPage(
        key: k,
      ),
  (k) => InstallPage(key: k),
];

class PageScaffold extends HookWidget {
  const PageScaffold({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final style = FluentTheme.of(context);

    final idx = useState(0);
    final Widget selectedWidget =
        pageContentGenerator[idx.value](Key('body_${idx.value}'));

    return NavigationView(
      appBar: NavigationAppBar(
        title: DragToMoveArea(
          child: Align(
            alignment: AlignmentDirectional.centerStart,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                'Arquivolta Manager',
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
        //displayMode: PaneDisplayMode.auto,
        selected: idx.value,
        /*
        size: const NavigationPaneSize(
          openMinWidth: 250,
          openMaxWidth: 320,
        ),
        */
        items: [
          PaneItemAction(
            icon: const Icon(FluentIcons.device_bug),
            title: const Text('Debug'),
            onTap: () => idx.value = 0,
          ),
          PaneItemAction(
            icon: const Icon(FluentIcons.download),
            title: const Text('Install'),
            onTap: () => idx.value = 1,
          ),
        ],
      ),
      content: selectedWidget,
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
