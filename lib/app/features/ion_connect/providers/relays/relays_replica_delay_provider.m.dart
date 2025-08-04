// SPDX-License-Identifier: ice License 1.0

import 'dart:convert';

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:ion/app/features/auth/providers/auth_provider.m.dart';
import 'package:ion/app/services/storage/user_preferences_service.r.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'relays_replica_delay_provider.m.g.dart';
part 'relays_replica_delay_provider.m.freezed.dart';

@Riverpod(keepAlive: true)
class RelaysReplicaDelay extends _$RelaysReplicaDelay {
  @override
  RelaysReplicaDelayState build() {
    listenSelf((_, next) => _saveState(next));
    return _loadSavedState();
  }

  void setDelay() {
    state = RelaysReplicaDelayState(delay: DateTime.now().add(const Duration(hours: 1)));
  }

  void _saveState(RelaysReplicaDelayState state) {
    final identityKeyName = ref.read(currentIdentityKeyNameSelectorProvider);
    if (identityKeyName == null) {
      return;
    }
    ref
        .read(userPreferencesServiceProvider(identityKeyName: identityKeyName))
        .setValue(_persistenceKey, json.encode(state.toJson()));
  }

  RelaysReplicaDelayState _loadSavedState() {
    final identityKeyName = ref.watch(currentIdentityKeyNameSelectorProvider);
    if (identityKeyName == null) {
      return const RelaysReplicaDelayState();
    }

    final userPreferencesService =
        ref.watch(userPreferencesServiceProvider(identityKeyName: identityKeyName));
    final savedState = userPreferencesService.getValue<String>(_persistenceKey);

    if (savedState == null) {
      return const RelaysReplicaDelayState();
    }

    return RelaysReplicaDelayState.fromJson(json.decode(savedState) as Map<String, dynamic>);
  }

  static const _persistenceKey = 'relays_replica_delay';
}

@freezed
class RelaysReplicaDelayState with _$RelaysReplicaDelayState {
  const factory RelaysReplicaDelayState({
    DateTime? delay,
  }) = _RelaysReplicaDelayState;

  factory RelaysReplicaDelayState.fromJson(Map<String, dynamic> json) =>
      _$RelaysReplicaDelayStateFromJson(json);

  const RelaysReplicaDelayState._();

  bool get isDelayed {
    return delay != null && delay!.isAfter(DateTime.now());
  }
}
