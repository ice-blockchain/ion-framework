// SPDX-License-Identifier: ice License 1.0

import 'package:ion/app/features/core/model/feature_flags.dart';
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
      TokenizedCommunitiesFeatureFlag.tokenizedCommunitiesEnabled: false,

      /// Log flags
      LoggerFeatureFlag.logApp: true,
      LoggerFeatureFlag.logRouters: true,
      LoggerFeatureFlag.logIonConnect: true,
      LoggerFeatureFlag.logIonIdentityClient: true,
    };
  }

  bool get(FeatureFlag flag) => state[flag] ?? false;
}
