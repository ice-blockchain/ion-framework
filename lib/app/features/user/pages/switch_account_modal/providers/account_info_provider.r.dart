// SPDX-License-Identifier: ice License 1.0

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/features/user/model/user_metadata_lite.f.dart';
import 'package:ion/app/features/user/model/user_preview_data.dart';
import 'package:ion/app/features/user/pages/switch_account_modal/providers/main_wallet_for_account_provider.r.dart';
import 'package:ion/app/features/user/pages/switch_account_modal/providers/user_details_for_account_provider.r.dart';
import 'package:ion/app/features/user/providers/global_accounts_provider.r.dart';
import 'package:ion/app/features/user/providers/user_metadata_provider.r.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'account_info_provider.r.g.dart';

@riverpod
Future<AccountInfo?> accountInfo(
  Ref ref,
  String identityKeyName,
) async {
  // Сначала пытаемся получить данные через ionIdentity (если есть токен)
  try {
    final userDetails = await ref.watch(userDetailsForAccountProvider(identityKeyName).future);
    if (userDetails != null) {
      // Пытаемся получить mainWallet для получения masterPubkey
      final mainWallet = await ref.watch(mainWalletForAccountProvider(identityKeyName).future);
      if (mainWallet != null) {
        final masterPubkey = mainWallet.signingKey.publicKey;
        // Пытаемся получить userPreviewData из кеша
        final cachedPreview = await ref.watch(
          userPreviewDataProvider(
            masterPubkey,
            network: false,
          ).future,
        );

        if (cachedPreview != null) {
          return AccountInfo(
            masterPubkey: masterPubkey,
            userPreview: cachedPreview,
            identityKeyName: identityKeyName,
          );
        }
      }
    }
  } catch (_) {
    // Игнорируем ошибки, пробуем другие источники
  }

  // Если не получилось через ionIdentity, пытаемся найти в GlobalAccounts
  try {
    final globalAccounts = await ref.watch(globalAccountsProvider.future);
    final accountInfo = globalAccounts.list.firstWhere(
      (info) => info.username == identityKeyName,
      orElse: () => throw StateError('Account not found'),
    );

    // Создаем UserPreviewEntity из IdentityUserInfo
    final userPreview = UserMetadataLiteEntity(
      masterPubkey: accountInfo.masterPubKey,
      data: UserMetadataLite(
        name: accountInfo.username,
        displayName: accountInfo.displayName,
        picture: accountInfo.picture,
      ),
    );

    return AccountInfo(
      masterPubkey: accountInfo.masterPubKey,
      userPreview: userPreview,
      identityKeyName: identityKeyName,
    );
  } catch (_) {
    // Если ничего не получилось, возвращаем null
    return null;
  }
}

class AccountInfo {
  AccountInfo({
    required this.masterPubkey,
    required this.userPreview,
    required this.identityKeyName,
  });

  final String masterPubkey;
  final UserPreviewEntity userPreview;
  final String identityKeyName;
}
