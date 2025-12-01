// SPDX-License-Identifier: ice License 1.0

import 'package:ion/app/features/auth/providers/auth_provider.m.dart';
import 'package:ion/app/features/user/model/user_metadata_lite.f.dart';
import 'package:ion/app/features/user/model/user_preview_data.dart';
import 'package:ion/app/features/user/providers/global_accounts_provider.r.dart';
import 'package:ion/app/features/user/providers/user_metadata_provider.r.dart';
import 'package:ion/app/services/ion_identity/ion_identity_provider.r.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'switch_account_modal_provider.r.g.dart';

class SwitchAccountInfoModel {
  SwitchAccountInfoModel({
    required this.masterPubkey,
    required this.userPreview,
    required this.identityKeyName,
  });

  final String masterPubkey;
  final UserPreviewEntity userPreview;
  final String identityKeyName;
}

class SwitchAccountTileModel {
  SwitchAccountTileModel({
    required this.identityKeyName,
    required this.accountInfo,
    required this.isCurrentUser,
  });

  final String identityKeyName;
  final SwitchAccountInfoModel? accountInfo;
  final bool isCurrentUser;
}

class SwitchAccountModalState {
  SwitchAccountModalState({
    required this.accounts,
    required this.currentIdentityKeyName,
  });

  final List<SwitchAccountTileModel> accounts;
  final String? currentIdentityKeyName;

  SwitchAccountModalState copyWith({
    List<SwitchAccountTileModel>? accounts,
    String? currentIdentityKeyName,
    bool? isLoading,
  }) {
    return SwitchAccountModalState(
      accounts: accounts ?? this.accounts,
      currentIdentityKeyName: currentIdentityKeyName ?? this.currentIdentityKeyName,
    );
  }
}

@riverpod
class SwitchAccountModalNotifier extends _$SwitchAccountModalNotifier {
  @override
  Future<SwitchAccountModalState> build() async {
    final isUserSwitching = ref.read(userSwitchInProgressProvider).isSwitchingProgress;
    final authState = await ref.watch(authProvider.future);
    final authenticatedIdentityKeyNames = authState.authenticatedIdentityKeyNames;
    final currentIdentityKeyName = ref.read(currentIdentityKeyNameSelectorProvider);

    state = AsyncData(
      SwitchAccountModalState(
        accounts: authenticatedIdentityKeyNames
            .map(
              (identityKeyName) => SwitchAccountTileModel(
                identityKeyName: identityKeyName,
                accountInfo: null,
                isCurrentUser: !isUserSwitching && (identityKeyName == currentIdentityKeyName),
              ),
            )
            .toList(),
        currentIdentityKeyName: currentIdentityKeyName,
      ),
    );

    final accounts = <SwitchAccountTileModel>[];
    for (final identityKeyName in authenticatedIdentityKeyNames) {
      final accountInfo = await _getAccountInfo(identityKeyName);
      final isCurrentUser = !isUserSwitching && (identityKeyName == currentIdentityKeyName);
      accounts.add(
        SwitchAccountTileModel(
          identityKeyName: identityKeyName,
          accountInfo: accountInfo,
          isCurrentUser: isCurrentUser,
        ),
      );
    }

    return SwitchAccountModalState(
      accounts: accounts,
      currentIdentityKeyName: currentIdentityKeyName,
    );
  }

  Future<SwitchAccountInfoModel?> _getAccountInfo(String identityKeyName) async {
    final accountInfoFromIONIdentity = await _getAccountInfoFromIONIdentity(identityKeyName);
    if (accountInfoFromIONIdentity != null) {
      return accountInfoFromIONIdentity;
    }

    final accountInfoFromGlobalAccounts = await _getAccountInfoFromGlobalAccounts(identityKeyName);
    if (accountInfoFromGlobalAccounts != null) {
      return accountInfoFromGlobalAccounts;
    }

    return null;
  }

  Future<SwitchAccountInfoModel?> _getAccountInfoFromIONIdentity(String identityKeyName) async {
    try {
      final ionIdentity = await ref.watch(ionIdentityProvider.future);
      final ionIdentityClient = ionIdentity(username: identityKeyName);

      final userDetails = await ionIdentityClient.users.currentUserDetails();
      final masterPubkey = userDetails.masterPubKey;
      final userPreview = await ref.watch(userPreviewDataProvider(masterPubkey).future);

      return userPreview == null
          ? null
          : SwitchAccountInfoModel(
              masterPubkey: masterPubkey,
              userPreview: userPreview,
              identityKeyName: identityKeyName,
            );
    } catch (_) {
      return null;
    }
  }

  Future<SwitchAccountInfoModel?> _getAccountInfoFromGlobalAccounts(String identityKeyName) async {
    try {
      final globalAccounts = await ref.watch(globalAccountsProvider.future);
      final accountInfo = globalAccounts.list.firstWhere(
        (info) => info.username == identityKeyName,
        orElse: () => throw StateError('Account not found'),
      );

      final userPreview = UserMetadataLiteEntity(
        masterPubkey: accountInfo.masterPubKey,
        data: UserMetadataLite(
          name: accountInfo.username,
          displayName: accountInfo.displayName,
          picture: accountInfo.picture,
        ),
      );

      return SwitchAccountInfoModel(
        masterPubkey: accountInfo.masterPubKey,
        userPreview: userPreview,
        identityKeyName: identityKeyName,
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> setCurrentUser(String identityKeyName) async {
    final currentState = state.valueOrNull;
    if (currentState == null) return;

    if (currentState.currentIdentityKeyName == identityKeyName) {
      ref.read(userSwitchInProgressProvider.notifier).completeSwitching();
    } else {
      await ref.read(authProvider.notifier).setCurrentUser(identityKeyName);
    }

    state = AsyncData(currentState.copyWith(currentIdentityKeyName: identityKeyName));
  }

  Future<void> clearCurrentUserForAuthentication() async {
    ref.read(userSwitchInProgressProvider.notifier).startSwitching();
  }
}
