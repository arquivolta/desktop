import 'dart:async';

import 'package:arquivolta/app.dart';
import 'package:arquivolta/interfaces.dart';
import 'package:arquivolta/pages/debug_page.dart';
import 'package:arquivolta/pages/install/install_page.dart';
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
  const PageScaffold({super.key});

  @override
  Widget build(BuildContext context) {
    final style = FluentTheme.of(context);
    final isDark = MediaQuery.of(context).platformBrightness == Brightness.dark;
    final platformUtils = App.find<PlatformUtilities>();
    final color = style.micaBackgroundColor.withAlpha(13);

    useEffect(
      () {
        unawaited(
          platformUtils.setupTransparentBackgroundWindow(
            isDark: isDark,
            color: color,
          ),
        );
        return null;
      },
      [isDark, color],
    );

    final idx = useState(0);

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
            children: const [Spacer(), if (!kIsWeb) WindowButtons()],
          ),
        ),
        automaticallyImplyLeading: false,
      ),
      pane: NavigationPane(
        // NB: Auto looks nicer here but it's broken at the moment
        // because when the pane is open the Title gets no padding
        selected: idx.value,
        items: [
          PaneItem(
            icon: const Icon(FluentIcons.download),
            title: const Text('Install'),
            onTap: () => idx.value = 0,
            body: const InstallPage(),
          ),
          if (App.find<ApplicationMode>() == ApplicationMode.debug)
            PaneItem(
              icon: const Icon(FluentIcons.device_bug),
              title: const Text('Debug'),
              onTap: () => idx.value = 1,
              body: const DebugPage(),
            ),
        ],
      ),
    );
  }
}

class WindowButtons extends StatelessWidget {
  const WindowButtons({super.key});

  @override
  Widget build(BuildContext context) {
    final FluentThemeData theme = FluentTheme.of(context);

    return SizedBox(
      width: 138,
      height: 50,
      child: WindowCaption(
        brightness: theme.brightness,
        backgroundColor: Colors.transparent,
      ),
    );
  }
}

/*
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
*/
