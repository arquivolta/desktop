class AsyncMemoize<T> {
  final Future<T> Function() _computation;
  final Duration? _ttl;

  Future<T>? _future;
  DateTime? _setAt;

  AsyncMemoize(this._computation, this._ttl);

  Future<T> get value {
    final ttl = _ttl;
    if (ttl != null && _setAt != null) {
      final now = DateTime.now();
      final diff = now.difference(_setAt!);

      if (diff > ttl) {
        _future = null;
      }
    }

    try {
      if (_future == null) {
        _future = _computation().catchError((Object e, StackTrace? st) {
          _future = null;
          return Future<T>.error(e, st);
        });
        _setAt = DateTime.now();
      }
    } catch (ex, st) {
      _future = null;
      return Future<T>.error(ex, st);
    }

    return _future!;
  }
}
