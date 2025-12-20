// SPDX-License-Identifier: ice License 1.0

import 'dart:async';

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/features/auth/providers/auth_provider.m.dart';
import 'package:ion/app/services/storage/user_preferences_service.r.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'global_subscription_latest_event_timestamp_provider.r.g.dart';

enum EventType {
  regular,
  encrypted;

  String get localKey {
    return switch (this) {
      EventType.regular => 'global_subscription_latest_regular_event_timestamp',
      EventType.encrypted => 'global_subscription_latest_encrypted_event_timestamp_V3',
    };
  }
}

enum RegularFilterType {
  pFilter,
  qFilter,
  ugcFilter;

  String get localKey {
    return switch (this) {
      RegularFilterType.pFilter => EventType.regular.localKey,
      RegularFilterType.qFilter => 'global_subscription_latest_q_filter_event_timestamp',
      RegularFilterType.ugcFilter => 'global_subscription_latest_ugc_filter_event_timestamp',
    };
  }
}

class GlobalSubscriptionLatestEventTimestampService {
  GlobalSubscriptionLatestEventTimestampService({
    required this.userPreferenceService,
  });

  final UserPreferencesService userPreferenceService;

  int? _get(EventType eventType) {
    return _getTimestamp(eventType.localKey);
  }

  int? getRegularFilter(RegularFilterType filterType) {
    return _getTimestamp(filterType.localKey);
  }

  int? _getTimestamp(String key) {
    return userPreferenceService.getValue<int>(key);
  }

  Future<void> updateRegularFilter(int createdAt, RegularFilterType filterType) async {
    final existingValue = getRegularFilter(filterType);
    if (existingValue != null && existingValue >= createdAt) {
      return;
    }

    await _updateTimestampInStorage(filterType.localKey, createdAt);
  }

  Future<void> _updateTimestampInStorage(String key, int timestamp) async {
    await userPreferenceService.setValue(key, timestamp);
  }

  Future<void> updateAllRegularTimestamps(int createdAt) async {
    await Future.wait([
      updateRegularFilter(createdAt, RegularFilterType.pFilter),
      updateRegularFilter(createdAt, RegularFilterType.qFilter),
      updateRegularFilter(createdAt, RegularFilterType.ugcFilter),
    ]);
  }

  Map<RegularFilterType, int?> getAllRegularFilterTimestamps() {
    return {
      RegularFilterType.pFilter: _get(EventType.regular), // Use regular events timestamp directly
      RegularFilterType.qFilter: getRegularFilter(RegularFilterType.qFilter),
      RegularFilterType.ugcFilter: getRegularFilter(RegularFilterType.ugcFilter),
    };
  }

  bool hasNoRegularTimestamps() {
    final timestamps = getAllRegularFilterTimestamps();
    return timestamps.values.every((timestamp) => timestamp == null);
  }

  int? getEncryptedTimestamp() {
    return _get(EventType.encrypted);
  }

  Future<void> updateEncryptedTimestampInStorage() async {
    return _updateTimestampInStorage(
      EventType.encrypted.localKey,
      DateTime.now().microsecondsSinceEpoch,
    );
  }
}

@riverpod
GlobalSubscriptionLatestEventTimestampService? globalSubscriptionLatestEventTimestampService(
  Ref ref,
) {
  final identityKeyName = ref.watch(currentIdentityKeyNameSelectorProvider);
  if (identityKeyName == null) {
    return null;
  }

  return GlobalSubscriptionLatestEventTimestampService(
    userPreferenceService:
        ref.watch(userPreferencesServiceProvider(identityKeyName: identityKeyName)),
  );
}
