// SPDX-License-Identifier: ice License 1.0

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/features/user/model/user_relays.f.dart';
import 'package:ion/app/features/user/providers/relays/relay_selectors.dart';
import 'package:ion/app/features/user/providers/relays/relevant_user_relays_provider.r.dart';
import 'package:ion/app/features/user/providers/relays/user_relays_manager.r.dart';
import 'package:ion/app/services/logger/logger.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'optimal_user_relays_provider.r.g.dart';

enum OptimalRelaysStrategy {
  /// Groups relays by the number of users using them.
  /// Returns the relays that are used by the most users.
  mostUsers,

  /// Groups relays by their latency.
  /// Returns the relays with the best latency.
  bestLatency
}

/// Finds the optimal relays for the given user pubkeys.
///
/// Use it when you need to find relays shared by multiple users.
/// Returns a map where each key is a relay URL
/// and the value is a list of pubkeys available on that relay
///
class OptimalUserRelaysService {
  OptimalUserRelaysService({
    required Future<List<UserRelaysEntity>> Function(List<String> pubkeys) getReachableUserRelays,
    required Future<List<String>> Function() getCurrentUserRankedRelevantRelays,
  })  : _getReachableUserRelays = getReachableUserRelays,
        _getCurrentUserRankedRelevantRelays = getCurrentUserRankedRelevantRelays;

  final Future<List<UserRelaysEntity>> Function(List<String> pubkeys) _getReachableUserRelays;

  final Future<List<String>> Function() _getCurrentUserRankedRelevantRelays;

  Future<Map<String, List<String>>> fetch({
    required List<String> masterPubkeys,
    required OptimalRelaysStrategy strategy,
    List<String>? failedRelayUrls,
  }) async {
    if (masterPubkeys.isEmpty) return {};

    final userToRelays =
        await _getUserRelays(masterPubkeys, failedRelayUrls: failedRelayUrls ?? []);

    return switch (strategy) {
      OptimalRelaysStrategy.mostUsers => _getSharedRelaysByMostUsers(userToRelays),
      OptimalRelaysStrategy.bestLatency => await _getSharedRelaysByBestLatency(userToRelays),
    };
  }

  Future<Map<String, List<String>>> _getUserRelays(
    List<String> masterPubkeys, {
    required List<String> failedRelayUrls,
  }) async {
    final reachableUserRelays = await _getReachableUserRelays(masterPubkeys);
    return {
      for (final userRelay in reachableUserRelays)
        userRelay.masterPubkey:
            userRelay.urls.where((url) => !failedRelayUrls.contains(url)).toList(),
    };
  }

  Map<String, List<String>> _getSharedRelaysByMostUsers(
    Map<String, List<String>> userToRelays,
  ) {
    Logger.log('[RELAY] userToRelays: $userToRelays');

    final bestOptions = findMostMatchingOptions(userToRelays);

    Logger.log('[RELAY] bestOptions: $bestOptions');

    return bestOptions;
  }

  Future<Map<String, List<String>>> _getSharedRelaysByBestLatency(
    Map<String, List<String>> userToRelays,
  ) async {
    final rankedRelevantRelays = await _getCurrentUserRankedRelevantRelays();

    final bestLatencyResults =
        findPriorityOptions(userToRelays, optionsPriority: rankedRelevantRelays);

    final handledUsers = bestLatencyResults.values.expand((urls) => urls).toSet();

    final unhandledUserToRelays = {...userToRelays}..removeWhere(
        (key, value) => handledUsers.contains(key),
      );

    // Fallback to the most matching options if we have users with relays
    // that are all not in ranked relevant relays of the current user.
    final mostUsersResults = findMostMatchingOptions(unhandledUserToRelays);

    return {
      ...bestLatencyResults,
      ...mostUsersResults,
    };
  }
}

@riverpod
OptimalUserRelaysService optimalUserRelaysService(Ref ref) {
  Future<List<UserRelaysEntity>> getReachableUserRelays(List<String> pubkeys) =>
      ref.read(userRelaysManagerProvider.notifier).fetchReachableRelays(pubkeys);
  Future<List<String>> getCurrentUserRankedRelevantRelays() =>
      ref.read(rankedRelevantCurrentUserRelaysUrlsProvider.future);
  return OptimalUserRelaysService(
    getReachableUserRelays: getReachableUserRelays,
    getCurrentUserRankedRelevantRelays: getCurrentUserRankedRelevantRelays,
  );
}
