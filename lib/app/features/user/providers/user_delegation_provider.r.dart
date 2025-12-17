// SPDX-License-Identifier: ice License 1.0

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/exceptions/exceptions.dart';
import 'package:ion/app/features/auth/providers/auth_provider.m.dart';
import 'package:ion/app/features/core/providers/main_wallet_provider.r.dart';
import 'package:ion/app/features/ion_connect/ion_connect.dart';
import 'package:ion/app/features/ion_connect/model/action_source.f.dart';
import 'package:ion/app/features/ion_connect/model/event_reference.f.dart';
import 'package:ion/app/features/ion_connect/providers/ion_connect_database_cache_notifier.r.dart';
import 'package:ion/app/features/ion_connect/providers/ion_connect_notifier.r.dart';
import 'package:ion/app/features/user/model/user_delegation.f.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'user_delegation_provider.r.g.dart';

@riverpod
Future<UserDelegationEntity?> userDelegation(Ref ref, String masterPubkey,
    {bool cache = true}) async {
  keepAliveWhenAuthenticated(ref);
  if (cache) {
    final userDelegation = await ref.watch(
      cachedUserDelegationProvider(masterPubkey).future,
    );

    if (userDelegation != null) {
      return userDelegation;
    }
  }

  // Added an authentication check to prevent the provider from getting stuck in an error state
  // when user delegation is missing and a network request is attempted while logged out.
  final authState = await ref.watch(authProvider.future);
  if (!authState.isAuthenticated) {
    return null;
  }

  final requestMessage = RequestMessage()
    ..addFilter(
      RequestFilter(kinds: const [UserDelegationEntity.kind], limit: 1, authors: [masterPubkey]),
    );

  return ref.read(ionConnectNotifierProvider.notifier).requestEntity<UserDelegationEntity>(
      requestMessage,
      actionSource: ActionSourceUser(masterPubkey));
}

@riverpod
Future<UserDelegationEntity?> cachedUserDelegation(Ref ref, String masterPubkey) async {
  final userDelegation = await ref.read(ionConnectDatabaseCacheProvider.notifier).get(
        ReplaceableEventReference(masterPubkey: masterPubkey, kind: UserDelegationEntity.kind)
            .toString(),
      ) as UserDelegationEntity?;

  return userDelegation;
}

@riverpod
Future<UserDelegationEntity?> currentUserDelegation(Ref ref) async {
  final mainWallet = await ref.watch(mainWalletProvider.future);
  if (mainWallet == null) {
    return null;
  }

  try {
    return await ref.watch(userDelegationProvider(mainWallet.signingKey.publicKey).future);
  } on UserRelaysNotFoundException catch (_) {
    return null;
  }
}

@riverpod
Future<UserDelegationEntity?> currentUserCachedDelegation(Ref ref) async {
  final mainWallet = await ref.watch(mainWalletProvider.future);
  if (mainWallet == null) {
    return null;
  }

  try {
    return await ref.watch(cachedUserDelegationProvider(mainWallet.signingKey.publicKey).future);
  } on UserRelaysNotFoundException catch (_) {
    return null;
  }
}

@riverpod
class UserDelegationManager extends _$UserDelegationManager {
  @override
  FutureOr<void> build() {}

  Future<UserDelegationData> buildCurrentUserDelegationDataWith({required String pubkey}) async {
    final delegation = (await ref.read(currentUserDelegationProvider.future))?.data ??
        const UserDelegationData(delegates: []);

    return delegation.copyWith(
      delegates: [
        ...delegation.delegates,
        UserDelegate(
          pubkey: pubkey,
          time: DateTime.now(),
          status: DelegationStatus.active,
        ),
      ],
    );
  }
}
