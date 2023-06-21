import 'dart:io' show Platform;

import 'package:bitsdojo_window/bitsdojo_window.dart';
// ignore: implementation_imports
import 'package:bitsdojo_window/src/widgets/mouse_state_builder.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

typedef WindowButtonIconBuilder = Widget Function(
  WindowButtonContext buttonContext,
);
typedef WindowButtonBuilder = Widget Function(
  WindowButtonContext buttonContext,
  Widget icon,
);

class WindowButtonContext {
  BuildContext context;
  MouseState mouseState;
  Color? backgroundColor;
  Color iconColor;
  WindowButtonContext({
    required this.context,
    required this.mouseState,
    required this.iconColor,
    this.backgroundColor,
  });
}

class WindowButtonColors {
  late Color normal;
  late Color mouseOver;
  late Color mouseDown;
  late Color iconNormal;
  late Color iconMouseOver;
  late Color iconMouseDown;
  WindowButtonColors({
    Color? normal,
    Color? mouseOver,
    Color? mouseDown,
    Color? iconNormal,
    Color? iconMouseOver,
    Color? iconMouseDown,
  }) {
    this.normal = normal ?? _defaultButtonColors.normal;
    this.mouseOver = mouseOver ?? _defaultButtonColors.mouseOver;
    this.mouseDown = mouseDown ?? _defaultButtonColors.mouseDown;
    this.iconNormal = iconNormal ?? _defaultButtonColors.iconNormal;
    this.iconMouseOver = iconMouseOver ?? _defaultButtonColors.iconMouseOver;
    this.iconMouseDown = iconMouseDown ?? _defaultButtonColors.iconMouseDown;
  }
}

final _defaultButtonColors = WindowButtonColors(
  normal: Colors.transparent,
  iconNormal: const Color(0xFF805306),
  mouseOver: const Color(0xFF404040),
  mouseDown: const Color(0xFF202020),
  iconMouseOver: const Color(0xFFFFFFFF),
  iconMouseDown: const Color(0xFFF0F0F0),
);

class WindowButton extends StatelessWidget {
  final Size? buttonSize;
  final WindowButtonBuilder? builder;
  final WindowButtonIconBuilder? iconBuilder;
  late final WindowButtonColors colors;
  final bool animate;
  final EdgeInsets? padding;
  final VoidCallback? onPressed;

  WindowButton({
    super.key,
    WindowButtonColors? colors,
    this.builder,
    @required this.iconBuilder,
    this.padding,
    this.onPressed,
    this.buttonSize,
    this.animate = false,
  }) {
    this.colors = colors ?? _defaultButtonColors;
  }

  Color getBackgroundColor(MouseState mouseState) {
    if (mouseState.isMouseDown) return colors.mouseDown;
    if (mouseState.isMouseOver) return colors.mouseOver;
    return colors.normal;
  }

  Color getIconColor(MouseState mouseState) {
    if (mouseState.isMouseDown) return colors.iconMouseDown;
    if (mouseState.isMouseOver) return colors.iconMouseOver;
    return colors.iconNormal;
  }

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      return Container();
    } else {
      // Don't show button on macOS
      if (Platform.isMacOS) {
        return Container();
      }
    }
    final buttonSize = this.buttonSize ?? appWindow.titleBarButtonSize;
    return MouseStateBuilder(
      builder: (context, mouseState) {
        final WindowButtonContext buttonContext = WindowButtonContext(
          mouseState: mouseState,
          context: context,
          backgroundColor: getBackgroundColor(mouseState),
          iconColor: getIconColor(mouseState),
        );

        final icon =
            (iconBuilder != null) ? iconBuilder!(buttonContext) : Container();
        final double borderSize = appWindow.borderSize;
        final double defaultPadding =
            (appWindow.titleBarHeight - borderSize) / 3 - (borderSize / 2);
        // Used when buttonContext.backgroundColor is null, allowing
        // the AnimatedContainer to fade-out smoothly.
        final fadeOutColor =
            getBackgroundColor(MouseState()..isMouseOver = true).withOpacity(0);
        final padding = this.padding ?? EdgeInsets.all(defaultPadding);
        final animationMs =
            mouseState.isMouseOver ? (animate ? 100 : 0) : (animate ? 200 : 0);
        Widget iconWithPadding = Padding(padding: padding, child: icon);
        iconWithPadding = AnimatedContainer(
          curve: Curves.easeOut,
          duration: Duration(milliseconds: animationMs),
          color: buttonContext.backgroundColor ?? fadeOutColor,
          child: iconWithPadding,
        );
        final button =
            (builder != null) ? builder!(buttonContext, icon) : iconWithPadding;
        return SizedBox(
          width: buttonSize.width,
          height: buttonSize.height,
          child: button,
        );
      },
      onPressed: () {
        onPressed?.call();
      },
    );
  }
}

class MinimizeWindowButton extends WindowButton {
  MinimizeWindowButton({
    super.key,
    super.colors,
    VoidCallback? onPressed,
    bool? animate,
    super.buttonSize,
  }) : super(
          animate: animate ?? false,
          iconBuilder: (buttonContext) =>
              MinimizeIcon(color: buttonContext.iconColor),
          onPressed: onPressed ?? () => appWindow.minimize(),
        );
}

class MaximizeWindowButton extends WindowButton {
  MaximizeWindowButton({
    super.key,
    super.colors,
    VoidCallback? onPressed,
    bool? animate,
    super.buttonSize,
  }) : super(
          animate: animate ?? false,
          iconBuilder: (buttonContext) =>
              MaximizeIcon(color: buttonContext.iconColor),
          onPressed: onPressed ?? () => appWindow.maximizeOrRestore(),
        );
}

final _defaultCloseButtonColors = WindowButtonColors(
  mouseOver: const Color(0xFFD32F2F),
  mouseDown: const Color(0xFFB71C1C),
  iconNormal: const Color(0xFF805306),
  iconMouseOver: const Color(0xFFFFFFFF),
);

class CloseWindowButton extends WindowButton {
  CloseWindowButton({
    super.key,
    WindowButtonColors? colors,
    VoidCallback? onPressed,
    bool? animate,
    super.buttonSize,
  }) : super(
          colors: colors ?? _defaultCloseButtonColors,
          animate: animate ?? false,
          iconBuilder: (buttonContext) =>
              CloseIcon(color: buttonContext.iconColor),
          onPressed: onPressed ?? () => appWindow.close(),
        );
}
