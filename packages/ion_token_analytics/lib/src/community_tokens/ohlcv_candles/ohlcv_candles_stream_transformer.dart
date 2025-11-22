// SPDX-License-Identifier: ice License 1.0

import 'dart:async';

import 'package:ion_token_analytics/src/community_tokens/ohlcv_candles/models/ohlcv_candle.f.dart';

/// Transforms a stream of raw JSON events into a stream of List<OhlcvCandle>.
///
/// Protocol:
/// 1. Initial JSONs are individual candles (snapshot).
/// 2. A "marker" event (empty JSON or specific structure) signals end of snapshot.
/// 3. Subsequent JSONs are updates (new candle or update to existing).
class OhlcvCandlesStreamTransformer extends StreamTransformerBase<dynamic, List<OhlcvCandle>> {
  @override
  Stream<List<OhlcvCandle>> bind(Stream<dynamic> stream) {
    final controller = StreamController<List<OhlcvCandle>>();
    final currentCandles = <OhlcvCandle>[];
    var snapshotComplete = false;

    final subscription = stream.listen(
      (event) {
        if (event is! Map<String, dynamic>) return;

        // Check for marker (e.g., empty JSON or specific field)
        // Assuming empty JSON {} or specific field 'eose' based on typical patterns.
        // For this implementation, we'll assume an empty map is the marker.
        // Adjust logic if protocol differs.
        final isMarker = event.isEmpty;

        if (!snapshotComplete) {
          if (isMarker) {
            snapshotComplete = true;
            // Sort candles by timestamp before emitting
            currentCandles.sort((a, b) => a.timestamp.compareTo(b.timestamp));
            controller.add(List.unmodifiable(currentCandles));
          } else {
            // Accumulate snapshot candle
            try {
              final candle = OhlcvCandle.fromJson(event);
              currentCandles.add(candle);
            } catch (e) {
              // Ignore malformed candles
            }
          }
        } else {
          // Real-time update
          if (!isMarker) {
            try {
              final candle = OhlcvCandle.fromJson(event);
              _applyUpdate(currentCandles, candle);
              controller.add(List.unmodifiable(currentCandles));
            } catch (e) {
              // Ignore malformed updates
            }
          }
        }
      },
      onError: controller.addError,
      onDone: controller.close,
    );

    controller.onCancel = subscription.cancel;

    return controller.stream;
  }

  void _applyUpdate(List<OhlcvCandle> candles, OhlcvCandle update) {
    // If list is empty, just add
    if (candles.isEmpty) {
      candles.add(update);
      return;
    }

    final last = candles.last;
    if (update.timestamp == last.timestamp) {
      // Update existing candle
      candles[candles.length - 1] = update;
    } else if (update.timestamp > last.timestamp) {
      // New candle
      candles.add(update);
      // Optionally limit list size if needed (e.g., keep last 1000)
      if (candles.length > 1000) {
        candles.removeAt(0);
      }
    } else {
      // Update to an older candle (unlikely for OHLCV but possible)
      final index = candles.indexWhere((c) => c.timestamp == update.timestamp);
      if (index != -1) {
        candles[index] = update;
      } else {
        // Insert in correct position
        candles
          ..add(update)
          ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
      }
    }
  }
}
