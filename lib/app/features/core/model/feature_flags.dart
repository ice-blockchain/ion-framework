// SPDX-License-Identifier: ice License 1.0

sealed class FeatureFlag {
  const FeatureFlag({required this.key});

  final String key;
}

final class WalletFeatureFlag extends FeatureFlag {
  const WalletFeatureFlag._({required super.key});

  static const buyNftEnabled = WalletFeatureFlag._(key: 'buyNftEnabled');
  static const dappsEnabled = WalletFeatureFlag._(key: 'dappsEnabled');
}

final class FeedFeatureFlag extends FeatureFlag {
  const FeedFeatureFlag._({required super.key});

  static const showTrendingVideo = FeedFeatureFlag._(key: 'showTrendingVideo');
  static const showSuggestions = FeedFeatureFlag._(key: 'showSuggestions');
}

final class LoggerFeatureFlag extends FeatureFlag {
  const LoggerFeatureFlag._({required super.key});

  static const logApp = LoggerFeatureFlag._(key: 'logApp');
  static const logRouters = LoggerFeatureFlag._(key: 'logRouters');
  static const logIonConnect = LoggerFeatureFlag._(key: 'logIonConnect');
  static const logIonIdentityClient = LoggerFeatureFlag._(key: 'logIonIdentityClient');
}

final class ChatFeatureFlag extends FeatureFlag {
  const ChatFeatureFlag._({required super.key});

  static const hideCommunity = ChatFeatureFlag._(key: 'hideCommunity');
  static const hideChatBookmark = ChatFeatureFlag._(key: 'hideChatBookmark');
}

final class TokenizedCommunitiesFeatureFlag extends FeatureFlag {
  const TokenizedCommunitiesFeatureFlag._({required super.key});

  static const tokenizedCommunitiesEnabled =
      TokenizedCommunitiesFeatureFlag._(key: 'tokenizedCommunitiesEnabled');
}

final class PinnedContentFeatureFlag extends FeatureFlag {
  const PinnedContentFeatureFlag._({required super.key});

  static const pinnedContentEnabled = PinnedContentFeatureFlag._(key: 'pinnedContentEnabled');
}
