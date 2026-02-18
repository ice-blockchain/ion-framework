// SPDX-License-Identifier: ice License 1.0

import 'package:ion_token_analytics/ion_token_analytics.dart';

typedef _TradeIdentityKey = ({
  String createdAt,
  String holderKey,
  TradeType type,
  String amount,
  String balance,
});

class LatestTradesAccumulator {
  final List<LatestTrade> _trades = <LatestTrade>[];
  final Set<_TradeIdentityKey> _tradeKeys = <_TradeIdentityKey>{};

  void reset() {
    _trades.clear();
    _tradeKeys.clear();
  }

  void appendUnique(Iterable<LatestTrade> trades) {
    for (final trade in trades) {
      final key = _tradeIdentityKey(trade);
      if (_tradeKeys.add(key)) {
        _trades.add(trade);
      }
    }
  }

  void prependUnique(Iterable<LatestTrade> trades) {
    for (final trade in trades) {
      final key = _tradeIdentityKey(trade);
      if (_tradeKeys.add(key)) {
        _trades.insert(0, trade);
      }
    }
  }

  bool applyPatch(LatestTradePatch patch) {
    if (patch.isEmpty()) {
      return false;
    }

    var changed = false;

    for (var index = 0; index < _trades.length; index++) {
      final current = _trades[index];
      if (!_matchesPatchTarget(current, patch)) {
        continue;
      }

      final merged = current.merge(patch);
      final currentKey = _tradeIdentityKey(current);
      final mergedKey = _tradeIdentityKey(merged);

      if (currentKey == mergedKey) {
        _trades[index] = merged;
        changed = true;
        continue;
      }

      if (_tradeKeys.contains(mergedKey)) {
        _trades.removeAt(index);
        index--;
        changed = true;
        continue;
      }

      _tradeKeys
        ..remove(currentKey)
        ..add(mergedKey);
      _trades[index] = merged;
      changed = true;
    }

    if (changed) {
      _rebuildTradeKeys();
    }

    return changed;
  }

  List<LatestTrade> snapshot() {
    _sortTrades();
    return List<LatestTrade>.unmodifiable(_trades);
  }

  bool _matchesPatchTarget(LatestTrade trade, LatestTradePatch patch) {
    final patchPosition = patch.position;
    if (patchPosition == null) {
      return false;
    }

    final tradePosition = trade.position;

    final patchCreatedAt = patchPosition.createdAt;
    if (patchCreatedAt != null && patchCreatedAt != tradePosition.createdAt) {
      return false;
    }

    final patchHolderAddresses = patchPosition.holder?.addresses;
    final tradeHolderAddresses = tradePosition.holder.addresses;

    final patchIonConnect = patchHolderAddresses?.ionConnect;
    if (patchIonConnect != null && patchIonConnect != tradeHolderAddresses?.ionConnect) {
      return false;
    }

    final patchTwitter = patchHolderAddresses?.twitter;
    if (patchTwitter != null && patchTwitter != tradeHolderAddresses?.twitter) {
      return false;
    }

    final patchBlockchain = patchHolderAddresses?.blockchain;
    if (patchBlockchain != null && patchBlockchain != tradeHolderAddresses?.blockchain) {
      return false;
    }

    return patchCreatedAt != null ||
        patchIonConnect != null ||
        patchTwitter != null ||
        patchBlockchain != null;
  }

  void _rebuildTradeKeys() {
    _tradeKeys
      ..clear()
      ..addAll(_trades.map(_tradeIdentityKey));
  }

  int _createdAtAsc(String a, String b) {
    final da = DateTime.tryParse(a);
    final db = DateTime.tryParse(b);
    if (da != null && db != null) {
      return da.compareTo(db);
    }
    return a.compareTo(b);
  }

  void _sortTrades() {
    _trades.sort(
      (a, b) => _createdAtAsc(b.position.createdAt, a.position.createdAt),
    );
  }

  _TradeIdentityKey _tradeIdentityKey(LatestTrade trade) {
    final position = trade.position;
    final holderAddresses = position.holder.addresses;

    final holderKey =
        (holderAddresses?.ionConnect ?? holderAddresses?.twitter ?? holderAddresses?.blockchain)
                ?.toLowerCase() ??
            '';

    return (
      createdAt: position.createdAt,
      holderKey: holderKey,
      type: position.type,
      amount: position.amount,
      balance: position.balance,
    );
  }
}
