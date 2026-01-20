// SPDX-License-Identifier: ice License 1.0

import 'package:ion/app/features/core/model/feature_flags.dart';
import 'package:ion/app/features/core/providers/env_provider.r.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'feature_flags_provider.r.g.dart';

@Riverpod(keepAlive: true)
class FeatureFlags extends _$FeatureFlags {
  @override
  Map<FeatureFlag, bool> build() {
    return {
      /// Local flags
      WalletFeatureFlag.buyNftEnabled: false,
      WalletFeatureFlag.dappsEnabled: false,
      FeedFeatureFlag.showTrendingVideo: true,
      FeedFeatureFlag.showSuggestions: true,
      ChatFeatureFlag.hideCommunity: true,
      ChatFeatureFlag.hideChatBookmark: true,
      TokenizedCommunitiesFeatureFlag.tokenizedCommunitiesEnabled: true,
      DelegateAccessFeatureFlag.delegateAccessEnabled: false,
      MultiAccountsFeatureFlag.multiAccountsEnabled: false,

      /// Log flags
      // if (ref.watch(envProvider.notifier).get(EnvVariable.SHOW_DEBUG_INFO)) ...{
      LoggerFeatureFlag.logApp: true,
      LoggerFeatureFlag.logRouters: true,
      LoggerFeatureFlag.logIonConnect: true,
      LoggerFeatureFlag.logIonIdentityClient: true,
      // },
    };
  }

  void toggle(FeatureFlag flag) {
    state = {
      ...state,
      flag: !state[flag]!,
    };
  }

  bool get(FeatureFlag flag) => state[flag] ?? false;
}
