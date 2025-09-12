// SPDX-License-Identifier: ice License 1.0

import 'package:ion/app/services/logger/logger.dart';

/// Runs [mapper] over [items] with a maximum number of concurrent tasks.
/// Preserves input order and throws on the first error. Default `concurrencyCap` is 3.
Future<List<R>> mapWithConcurrency<T, R>(
  List<T> items, {
  required Future<R> Function(T item) mapper,
  int concurrencyCap = 3,
}) async {
  if (items.isEmpty) return <R>[];
  if (concurrencyCap < 1) {
    throw ArgumentError.value(concurrencyCap, 'concurrencyCap', 'Must be >= 1');
  }

  final total = items.length;
  final workerCount = concurrencyCap > total ? total : concurrencyCap;

  final results = List<R?>.filled(total, null);
  var nextIndex = 0;

  int? claimNextIndex() {
    final current = nextIndex;
    if (current >= total) return null;
    nextIndex = current + 1;
    return current;
  }

  Future<void> worker() async {
    for (var i = claimNextIndex(); i != null; i = claimNextIndex()) {
      try {
        results[i] = await mapper(items[i]);
      } catch (e, st) {
        Logger.error(
          e,
          stackTrace: st,
          message: '[concurrency] Worker failed on index=$i',
        );
        rethrow;
      }
    }
  }

  final workers = List<Future<void>>.generate(workerCount, (_) => worker());
  await Future.wait(workers, eagerError: true);
  return results.cast<R>();
}
