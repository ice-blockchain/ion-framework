// SPDX-License-Identifier: ice License 1.0

import 'package:ion_token_analytics/ion_token_analytics.dart';

typedef TimeProvider = DateTime Function();
typedef TokenInfoLoader = Future<CommunityToken?> Function(String externalAddress);
typedef TokenExistencePredicate = bool Function(CommunityToken? tokenInfo);

class TokenInfoCache {
  TokenInfoCache({
    required TokenInfoLoader loader,
    Duration negativeTtl = const Duration(seconds: 2),
    TimeProvider now = DateTime.now,
    TokenExistencePredicate isExistingToken = _defaultIsExistingToken,
  })  : _loader = loader,
        _negativeTtl = negativeTtl,
        _now = now,
        _isExistingToken = isExistingToken;

  final TokenInfoLoader _loader;
  final Duration _negativeTtl;
  final TimeProvider _now;
  final TokenExistencePredicate _isExistingToken;

  final Map<String, _Entry> _cache = <String, _Entry>{};

  Future<CommunityToken?> get(String externalAddress) async {
    final now = _now();
    final cached = _cache[externalAddress];

    if (cached != null) {
      if (_isExistingToken(cached.value)) {
        return cached.value;
      }

      if (now.difference(cached.updatedAt) < _negativeTtl) {
        return cached.value;
      }

      final inFlight = cached.inFlight;
      if (inFlight != null) {
        return inFlight;
      }
    }

    return _startLoad(externalAddress);
  }

  Future<CommunityToken?> refresh(String externalAddress) async {
    return _startLoad(externalAddress);
  }

  void clear(String externalAddress) {
    _cache.remove(externalAddress);
  }

  Future<CommunityToken?> _startLoad(String externalAddress) async {
    final inFlight = _loader(externalAddress);
    _cache[externalAddress] = _Entry.inFlight(
      updatedAt: _now(),
      inFlight: inFlight,
    );

    try {
      final value = await inFlight;
      final current = _cache[externalAddress];
      if (identical(current?.inFlight, inFlight)) {
        _cache[externalAddress] = _Entry.resolved(
          updatedAt: _now(),
          value: value,
        );
      }
      return value;
    } catch (_) {
      final current = _cache[externalAddress];
      if (identical(current?.inFlight, inFlight)) {
        _cache.remove(externalAddress);
      }
      rethrow;
    }
  }

  static bool _defaultIsExistingToken(CommunityToken? tokenInfo) {
    return tokenInfo?.addresses.blockchain != null;
  }
}

class _Entry {
  _Entry._({
    required this.updatedAt,
    required this.value,
    required this.inFlight,
  });

  factory _Entry.inFlight({
    required DateTime updatedAt,
    required Future<CommunityToken?> inFlight,
  }) {
    return _Entry._(
      updatedAt: updatedAt,
      value: null,
      inFlight: inFlight,
    );
  }

  factory _Entry.resolved({
    required DateTime updatedAt,
    required CommunityToken? value,
  }) {
    return _Entry._(
      updatedAt: updatedAt,
      value: value,
      inFlight: null,
    );
  }

  final DateTime updatedAt;
  final CommunityToken? value;
  final Future<CommunityToken?>? inFlight;
}
