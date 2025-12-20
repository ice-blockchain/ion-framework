// SPDX-License-Identifier: ice License 1.0

import 'dart:math';

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/features/auth/providers/auth_provider.m.dart';
import 'package:ion/app/features/ion_connect/model/entity_label.f.dart';
import 'package:ion/app/features/user/providers/ugc_counter_provider.r.dart';
import 'package:ion/app/services/storage/user_preferences_service.r.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'ugc_serial_service.r.g.dart';

const _ugcSerialCounterKey = 'ugc_serial_counter';

class UgcSerialService {
  UgcSerialService({
    required this.identityKeyName,
    required this.userPreferencesService,
    required this.ref,
  });

  final Ref ref;
  final String identityKeyName;
  final UserPreferencesService userPreferencesService;

  int? _latestCounter;

  Future<EntityLabel?> getNextLabel({
    bool cache = true,
    bool network = true,
  }) async {
    final currentCount = await _syncCounter(cache: cache, network: network);
    final nextValue = currentCount + 1;

    await _updateCounter(nextValue);

    return EntityLabel(
      values: [nextValue.toString()],
      namespace: EntityLabelNamespace.ugcSerial,
    );
  }

  Future<void> updateFromLabel(EntityLabel? label) async {
    if (label == null) return;

    final parsedValues = label.values.map(int.tryParse).whereType<int>();
    if (parsedValues.isEmpty) return;

    final maxValue = parsedValues.reduce(max);
    await _updateCounter(maxValue);
  }

  Future<int> _syncCounter({required bool cache, required bool network}) async {
    final storedCounter = await _loadStoredCounter();

    if (!network && !cache) {
      return storedCounter;
    }

    final currentCount = await ref.read(
      ugcCounterProvider(cache: cache, network: network).future,
    );

    return _updateCounter(max(storedCounter, currentCount));
  }

  Future<int> _loadStoredCounter() async {
    _latestCounter ??= userPreferencesService.getValue<int>(_ugcSerialCounterKey) ?? 0;
    return _latestCounter!;
  }

  Future<int> _updateCounter(int value) async {
    final storedCounter = await _loadStoredCounter();
    final updatedCounter = max(storedCounter, value);

    if (updatedCounter != _latestCounter) {
      _latestCounter = updatedCounter;
      await userPreferencesService.setValue<int>(_ugcSerialCounterKey, updatedCounter);
    }

    return updatedCounter;
  }
}

/// Service for managing the UGC (User Generated Content) serial counter.
/// This counter increments with each root event (kind 1, 30175 or 30023) created by the user.
@Riverpod(keepAlive: true)
UgcSerialService ugcSerialService(
  Ref ref, {
  required String identityKeyName,
}) {
  final userPreferences =
      ref.watch(userPreferencesServiceProvider(identityKeyName: identityKeyName));

  return UgcSerialService(
    ref: ref,
    identityKeyName: identityKeyName,
    userPreferencesService: userPreferences,
  );
}

@Riverpod(keepAlive: true)
UgcSerialService? currentUserUgcSerialService(Ref ref) {
  final identityKeyName = ref.watch(currentIdentityKeyNameSelectorProvider);

  if (identityKeyName == null) {
    return null;
  }

  return ref.watch(ugcSerialServiceProvider(identityKeyName: identityKeyName));
}
