import 'package:arquivolta/util.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

VoidCallback useExplicitRedraw({bool delay = true}) {
  final redraw = useState(0);
  final context = useContext();

  void redrawNow() {
    if (context.mounted) redraw.value++;
  }

  return delay ? () => delayBeat(redrawNow) : redrawNow;
}
