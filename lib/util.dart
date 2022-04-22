import 'dart:async';

// NB: Doing this inline introduces too much syntactic noise
void delayBeat(dynamic Function() block) {
  unawaited(
    Future<void>.delayed(const Duration(milliseconds: 20))
        .then((_v) => block()),
  );
}
