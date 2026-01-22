// SPDX-License-Identifier: ice License 1.0

import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:ion/app/services/logger/logger.dart';
import 'package:ion/app/services/storage/local_storage.r.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'ion_connect_media_failed_hosts_provider.m.g.dart';
part 'ion_connect_media_failed_hosts_provider.m.freezed.dart';

@immutable
@Freezed(equal: false)
class FailedMediaHost with _$FailedMediaHost {
  const factory FailedMediaHost({
    required String host,
    DateTime? expiresAt,
  }) = _FailedMediaHost;

  const FailedMediaHost._();

  factory FailedMediaHost.fromJson(Map<String, dynamic> json) => _$FailedMediaHostFromJson(json);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FailedMediaHost && runtimeType == other.runtimeType && host == other.host;

  @override
  int get hashCode => host.hashCode;
}

/// A provider that tracks failed media hosts to avoid retrying them.
///
/// Failed hosts are stored with expiration timestamps and automatically
/// filtered out when expired.
@Riverpod(keepAlive: true)
class FailedMediaHosts extends _$FailedMediaHosts {
  @override
  Set<FailedMediaHost> build() {
    return _loadFromStorage();
  }

  Set<FailedMediaHost> _loadFromStorage() {
    try {
      final localStorage = ref.read(localStorageProvider);
      final stored = localStorage.getStringList(_persistanceKey);

      if (stored != null) {
        final now = DateTime.now();

        final hosts = stored
            .map((item) => FailedMediaHost.fromJson(json.decode(item) as Map<String, dynamic>))
            .where((failedHost) => failedHost.expiresAt?.isAfter(now) ?? true)
            .toSet();

        return hosts;
      }
      return {};
    } catch (error, stackTrace) {
      Logger.error(
        error,
        stackTrace: stackTrace,
        message: 'Failed to load failed media hosts from storage',
      );
      return {};
    }
  }

  Future<void> _saveToStorage() async {
    try {
      final localStorage = ref.read(localStorageProvider);
      final failedHosts = state.map((host) => jsonEncode(host.toJson())).toList();
      await localStorage.setStringList(_persistanceKey, failedHosts);
    } catch (error, stackTrace) {
      Logger.error(
        error,
        stackTrace: stackTrace,
        message: 'Failed to save failed media hosts to storage',
      );
    }
  }

  void addFailedHost(String host) {
    final expiresAt = DateTime.now().add(_expirationDuration);
    final failedHost = FailedMediaHost(host: host, expiresAt: expiresAt);
    if (!state.contains(failedHost)) {
      state = {...state, failedHost};
      _saveToStorage();
    }
  }

  static const _expirationDuration = Duration(days: 3);

  static const _persistanceKey = 'failed_media_hosts_persistance_key';
}
