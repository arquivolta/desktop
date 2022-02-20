library actions;

import 'dart:async';
import 'dart:core';

import 'package:flutter/widgets.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

class ActionResult<T> {
  final Function invoke;
  final AsyncSnapshot<T> result;
  final Function reset;

  ActionResult._(this.invoke, this.result, this.reset);
}

ActionResult<T> useAction<T>(
  Future<T> Function() block,
  List<Object?> keys, {
  bool runOnStart = false,
}) {
  final mounted = useIsMounted();
  final current = useState(AsyncSnapshot<T>.waiting());

  final reset = useCallback(
    () {
      if (mounted()) {
        current.value = const AsyncSnapshot.waiting();
      }
    },
    [mounted],
  );

  final invokeCommand = useAsyncCallbackDedup(
    () async {
      try {
        if (mounted()) current.value = const AsyncSnapshot.waiting();
        final ret = await block();
        if (mounted()) {
          current.value = AsyncSnapshot.withData(ConnectionState.done, ret);
        }

        return ret;
      } catch (e) {
        if (mounted()) {
          current.value = AsyncSnapshot.withError(ConnectionState.done, e);
        }

        rethrow;
      }
    },
    keys,
  );

  useFutureEffect(
    () async {
      if (runOnStart) {
        await invokeCommand();
      }
    },
    [
      invokeCommand,
    ],
  );

  return useMemoized(
    () => ActionResult._(invokeCommand, current.value, reset),
    [invokeCommand, current.value, reset],
  );
}

AsyncSnapshot<T?> useStreamEffect<T>(
  Stream<T> Function() block,
  List<Object?> keys,
) {
  final ret = useState(AsyncSnapshot<T?>.waiting());

  useEffect(
    () {
      StreamSubscription<T> sub;

      try {
        sub = block().listen(
          (x) => ret.value = AsyncSnapshot.withData(ConnectionState.active, x),
          onError: (Object e) =>
              ret.value = AsyncSnapshot.withError(ConnectionState.active, e),
          onDone: () => ret.value =
              const AsyncSnapshot.withData(ConnectionState.done, null),
        );
      } catch (e) {
        ret.value = AsyncSnapshot.withError(ConnectionState.active, e);
        rethrow;
      }

      return sub.cancel;
    },
    [block, ...keys],
  );

  return ret.value;
}

AsyncSnapshot<T> useFutureEffect<T>(
  Future<T> Function() block,
  List<Object?> keys,
) {
  final ret = useState(AsyncSnapshot<T>.waiting());

  useEffect(
    () {
      var cancelled = false;

      try {
        block().then(
          (x) {
            if (!cancelled) {
              ret.value = AsyncSnapshot.withData(ConnectionState.done, x);
            }
          },
          onError: (Object e) {
            if (!cancelled) {
              ret.value = AsyncSnapshot.withError(ConnectionState.done, e);
            }
          },
        );
      } catch (e) {
        ret.value = AsyncSnapshot.withError(ConnectionState.active, e);
        rethrow;
      }

      return () => cancelled = true;
    },
    [
      block,
      ...keys,
    ],
  );

  return ret.value;
}

Future<T?> Function() useAsyncCallbackDedup<T>(
  Future<T> Function() block,
  List<Object?> keys,
) {
  final cur = useRef<Future<T>?>(null);

  final cb = useCallback(
    () {
      if (cur.value != null) {
        return Future<T?>.value();
      }

      cur.value = block();
      return cur.value!.whenComplete(() => cur.value = null);
    },
    keys,
  );

  return cb;
}
