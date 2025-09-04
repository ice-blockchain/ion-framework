// SPDX-License-Identifier: ice License 1.0

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:ion/app/features/user/providers/relays/optimal_user_relays_provider.r.dart';

part 'action_source.f.freezed.dart';

@freezed
sealed class ActionSource with _$ActionSource {
  const factory ActionSource.currentUser({
    @Default(false) bool anonymous,
  }) = ActionSourceCurrentUser;

  const factory ActionSource.user(
    String pubkey, {
    @Default(false) bool anonymous,
  }) = ActionSourceUser;

  const factory ActionSource.relayUrl(
    String url, {
    @Default(false) bool anonymous,
  }) = ActionSourceRelayUrl;

  const factory ActionSource.indexers({
    @Default(false) bool anonymous,
  }) = ActionSourceIndexers;

  // optimal relays
  const factory ActionSource.optimalRelays({
    required List<String> masterPubkeys,
    required OptimalRelaysStrategy strategy,
    @Default(false) bool anonymous,
  }) = ActionSourceOptimalRelays;
}
