// [d3g] Debug tracker for post detail performance - delete before PR

import 'package:ion/app/features/ion_connect/ion_connect.dart';
import 'package:ion/app/services/logger/logger.dart';

class D3gPostDetailTracker {
  final _sw = Stopwatch();
  int? _postShownMs;
  int? _firstReplyMs;
  int _requestCount = 0;
  int _totalPayloadSymbols = 0;
  bool active = false;

  void start() {
    _sw.reset();
    _sw.start();
    _postShownMs = null;
    _firstReplyMs = null;
    _requestCount = 0;
    _totalPayloadSymbols = 0;
    active = true;
  }

  void markPostShown() {
    if (active && _postShownMs == null) {
      _postShownMs = _sw.elapsedMilliseconds;
    }
  }

  void markFirstReply() {
    if (active && _firstReplyMs == null) {
      _firstReplyMs = _sw.elapsedMilliseconds;
    }
  }

  void trackRequestStart() {
    if (!active) return;
    _requestCount++;
  }

  void trackEvent(EventMessage event) {
    if (!active) return;
    var symbols = event.content.length +
        event.id.length +
        event.pubkey.length +
        (event.sig?.length ?? 0);
    for (final tag in event.tags) {
      for (final v in tag) {
        symbols += v.length;
      }
    }
    _totalPayloadSymbols += symbols;
  }

  void finish() {
    if (!active) return;
    active = false;
    final totalMs = _sw.elapsedMilliseconds;
    _sw.stop();
    Logger.log('[d3g] === Post Detail Performance ===');
    Logger.log('[d3g] Total time: ${totalMs}ms');
    Logger.log('[d3g] Time to show post: ${_postShownMs ?? "N/A"}ms');
    Logger.log('[d3g] Time to first reply: ${_firstReplyMs ?? "N/A"}ms');
    Logger.log('[d3g] Total requests: $_requestCount');
    Logger.log('[d3g] Total payload symbols: $_totalPayloadSymbols');
    Logger.log('[d3g] ================================');
  }
}

final d3gTracker = D3gPostDetailTracker();
