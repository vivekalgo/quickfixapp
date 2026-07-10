import 'package:flutter_riverpod/flutter_riverpod.dart';

class CachedAsyncValueNotifier<T> extends StateNotifier<AsyncValue<T>> {
  CachedAsyncValueNotifier(this._fetcher) : super(const AsyncLoading()) {
    refresh();
  }

  final Future<T> Function() _fetcher;
  bool _isFetching = false;

  Future<void> refresh() async {
    if (_isFetching) return;

    final hadValue = state.hasValue;
    if (!hadValue) {
      state = const AsyncLoading();
    }

    _isFetching = true;
    try {
      final value = await _fetcher();
      state = AsyncData(value);
    } catch (error, stackTrace) {
      if (!hadValue) {
        state = AsyncError(error, stackTrace);
      }
    } finally {
      _isFetching = false;
    }
  }
}