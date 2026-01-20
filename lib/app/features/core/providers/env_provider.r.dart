// SPDX-License-Identifier: ice License 1.0

// ignore_for_file: constant_identifier_names

import 'package:envied/envied.dart';
import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'env_provider.r.g.dart';

@Envied(path: '.app.env', obfuscate: true)
abstract class AppEnv {
  // Core app ids/origin
  @EnviedField(varName: 'ION_ANDROID_APP_ID')
  static final String ionAndroidAppId = _AppEnv.ionAndroidAppId;

  @EnviedField(varName: 'ION_IOS_APP_ID')
  static final String ionIosAppId = _AppEnv.ionIosAppId;

  @EnviedField(varName: 'ION_ORIGIN')
  static final String ionOrigin = _AppEnv.ionOrigin;

  @EnviedField(varName: 'ION_INTERNAL_DEEP_LINK_SCHEME', defaultValue: 'ionapp')
  static final String ionInternalDeepLinkScheme = _AppEnv.ionInternalDeepLinkScheme;

  // Debug / feature flags
  @EnviedField(varName: 'SHOW_DEBUG_INFO', defaultValue: 'false')
  static final String showDebugInfo = _AppEnv.showDebugInfo;

  @EnviedField(varName: 'OPTIMISTIC_UI_ENABLED', defaultValue: 'false')
  static final String optimisticUiEnabled = _AppEnv.optimisticUiEnabled;

  // Tokens / secrets
  @EnviedField(varName: 'BANUBA_TOKEN')
  static final String banubaToken = _AppEnv.banubaToken;

  @EnviedField(varName: 'SENTRY_DSN')
  static final String sentryDsn = _AppEnv.sentryDsn;

  @EnviedField(varName: 'FOUNDATION_APP_GROUP')
  static final String foundationAppGroup = _AppEnv.foundationAppGroup;

  @EnviedField(varName: 'ICLOUD_CONTAINER_ID')
  static final String icloudContainerId = _AppEnv.icloudContainerId;

  // Firebase configs (platform specific)
  @EnviedField(varName: 'FIREBASE_CONFIG_ANDROID')
  static final String firebaseConfigAndroid = _AppEnv.firebaseConfigAndroid;

  @EnviedField(varName: 'FIREBASE_CONFIG_IOS')
  static final String firebaseConfigIos = _AppEnv.firebaseConfigIos;

  // Durations / limits
  @EnviedField(varName: 'STORY_EXPIRATION_HOURS')
  static final String storyExpirationHours = _AppEnv.storyExpirationHours;

  @EnviedField(varName: 'EDIT_POST_ALLOWED_MINUTES')
  static final String editPostAllowedMinutes = _AppEnv.editPostAllowedMinutes;

  @EnviedField(varName: 'EDIT_MESSAGE_ALLOWED_MINUTES')
  static final String editMessageAllowedMinutes = _AppEnv.editMessageAllowedMinutes;

  @EnviedField(varName: 'USER_METADATA_CACHE_MINUTES', defaultValue: '2')
  static final String userMetadataCacheMinutes = _AppEnv.userMetadataCacheMinutes;

  @EnviedField(varName: 'COMMUNITY_CREATION_CACHE_MINUTES')
  static final String communityCreationCacheMinutes = _AppEnv.communityCreationCacheMinutes;

  @EnviedField(varName: 'COMMUNITY_MEMBERS_COUNT_CACHE_MINUTES')
  static final String communityMembersCountCacheMinutes = _AppEnv.communityMembersCountCacheMinutes;

  @EnviedField(varName: 'GIFT_WRAP_EXPIRATION_HOURS')
  static final String giftWrapExpirationHours = _AppEnv.giftWrapExpirationHours;

  @EnviedField(varName: 'MIN_APP_VERSION_CONFIG_CACHE_MINUTES', defaultValue: '480')
  static final String minAppVersionConfigCacheMinutes = _AppEnv.minAppVersionConfigCacheMinutes;

  @EnviedField(varName: 'GENERIC_CONFIG_CACHE_MINUTES', defaultValue: '480')
  static final String genericConfigCacheMinutes = _AppEnv.genericConfigCacheMinutes;

  @EnviedField(varName: 'RELAY_PING_INTERVAL_SECONDS', defaultValue: '3600')
  static final String relayPingIntervalSeconds = _AppEnv.relayPingIntervalSeconds;

  @EnviedField(varName: 'FEED_MIN_VISIBLE_ARTICLE_CATEGORIES_NUMBER', defaultValue: '5')
  static final String feedMinVisibleArticleCategoriesNumber =
      _AppEnv.feedMinVisibleArticleCategoriesNumber;

  @EnviedField(varName: 'ENFORCE_ACCOUNT_SECURITY_DELAY_IN_MINUTES', defaultValue: '1440')
  static final String enforceAccountSecurityDelayInMinutes =
      _AppEnv.enforceAccountSecurityDelayInMinutes;

  @EnviedField(varName: 'ACCOUNT_NOTIFICATION_SETTINGS_SYNC_INTERVAL_MINUTES', defaultValue: '60')
  static final String accountNotificationSettingsSyncIntervalMinutes =
      _AppEnv.accountNotificationSettingsSyncIntervalMinutes;

  // AppsFlyer
  @EnviedField(varName: 'AF_ANDROID_APP_ID')
  static final String afAndroidAppId = _AppEnv.afAndroidAppId;

  @EnviedField(varName: 'AF_IOS_APP_ID')
  static final String afIosAppId = _AppEnv.afIosAppId;

  @EnviedField(varName: 'AF_ONE_LINK_TEMPLATE_ID')
  static final String afOneLinkTemplateId = _AppEnv.afOneLinkTemplateId;

  @EnviedField(varName: 'AF_DEV_KEY')
  static final String afDevKey = _AppEnv.afDevKey;

  @EnviedField(varName: 'AF_BRAND_DOMAIN')
  static final String afBrandDomain = _AppEnv.afBrandDomain;

  @EnviedField(varName: 'AF_BASE_HOST')
  static final String afBaseHost = _AppEnv.afBaseHost;

  // Misc
  @EnviedField(varName: 'CHECKSUM')
  static final String checksum = _AppEnv.checksum;

  @EnviedField(varName: 'INDEXER_BASE_URL')
  static final String indexerBaseUrl = _AppEnv.indexerBaseUrl;

  @EnviedField(varName: 'NFT_IDENTITY_BASE_URL')
  static final String nftIdentityBaseUrl = _AppEnv.nftIdentityBaseUrl;

  @EnviedField(varName: 'SHARE_APP_NAME')
  static final String shareAppName = _AppEnv.shareAppName;

  @EnviedField(varName: 'ION_TOKEN_ANALYTICS_BASE_URL')
  static final String ionTokenAnalyticsBaseUrl = _AppEnv.ionTokenAnalyticsBaseUrl;

  // Crypto / swaps
  @EnviedField(varName: 'CRYPTOCURRENCIES_SWAP_OKX_API_KEY')
  static final String cryptocurrenciesSwapOkxApiKey = _AppEnv.cryptocurrenciesSwapOkxApiKey;

  @EnviedField(varName: 'CRYPTOCURRENCIES_SWAP_OKX_SIGN_KEY')
  static final String cryptocurrenciesSwapOkxSignKey = _AppEnv.cryptocurrenciesSwapOkxSignKey;

  @EnviedField(varName: 'CRYPTOCURRENCIES_SWAP_OKX_PASSPHRASE')
  static final String cryptocurrenciesSwapOkxPassphrase = _AppEnv.cryptocurrenciesSwapOkxPassphrase;

  @EnviedField(varName: 'CRYPTOCURRENCIES_SWAP_OKX_API_URL')
  static final String cryptocurrenciesSwapOkxApiUrl = _AppEnv.cryptocurrenciesSwapOkxApiUrl;

  @EnviedField(varName: 'CRYPTOCURRENCIES_BRIDGE_RELAY_BASE_URL')
  static final String cryptocurrenciesBridgeRelayBaseUrl =
      _AppEnv.cryptocurrenciesBridgeRelayBaseUrl;

  @EnviedField(varName: 'CRYPTOCURRENCIES_CEX_LETS_EXCHANGE_API_KEY')
  static final String cryptocurrenciesCexLetsExchangeApiKey =
      _AppEnv.cryptocurrenciesCexLetsExchangeApiKey;

  @EnviedField(varName: 'CRYPTOCURRENCIES_CEX_LETS_EXCHANGE_API_URL')
  static final String cryptocurrenciesCexLetsExchangeApiUrl =
      _AppEnv.cryptocurrenciesCexLetsExchangeApiUrl;

  @EnviedField(varName: 'CRYPTOCURRENCIES_CEX_LETS_EXCHANGE_API_AFFILIATE_ID')
  static final String cryptocurrenciesCexLetsExchangeApiAffiliateId =
      _AppEnv.cryptocurrenciesCexLetsExchangeApiAffiliateId;

  @EnviedField(varName: 'CRYPTOCURRENCIES_CEX_EXOLIX_API_KEY')
  static final String cryptocurrenciesCexExolixApiKey = _AppEnv.cryptocurrenciesCexExolixApiKey;

  @EnviedField(varName: 'CRYPTOCURRENCIES_CEX_EXOLIX_API_URL')
  static final String cryptocurrenciesCexExolixApiUrl = _AppEnv.cryptocurrenciesCexExolixApiUrl;

  @EnviedField(varName: 'CRYPTOCURRENCIES_BSC_RPC_URL')
  static final String cryptocurrenciesBscRpcUrl = _AppEnv.cryptocurrenciesBscRpcUrl;

  @EnviedField(varName: 'CRYPTOCURRENCIES_BSC_RPC_URLS')
  static final String cryptocurrenciesBscRpcUrls = _AppEnv.cryptocurrenciesBscRpcUrls;

  @EnviedField(varName: 'CRYPTOCURRENCIES_ION_SWAP_CONTRACT_ADDRESS')
  static final String cryptocurrenciesIonSwapContractAddress =
      _AppEnv.cryptocurrenciesIonSwapContractAddress;

  @EnviedField(varName: 'CRYPTOCURRENCIES_ICE_BSC_TOKEN_ADDRESS')
  static final String cryptocurrenciesIceBscTokenAddress =
      _AppEnv.cryptocurrenciesIceBscTokenAddress;

  @EnviedField(varName: 'CRYPTOCURRENCIES_ION_BSC_TOKEN_ADDRESS')
  static final String cryptocurrenciesIonBscTokenAddress =
      _AppEnv.cryptocurrenciesIonBscTokenAddress;

  @EnviedField(varName: 'CRYPTOCURRENCIES_ION_BRIDGE_ROUTER_CONTRACT_ADDRESS')
  static final String cryptocurrenciesIonBridgeRouterContractAddress =
      _AppEnv.cryptocurrenciesIonBridgeRouterContractAddress;

  @EnviedField(varName: 'CRYPTOCURRENCIES_ION_BRIDGE_CONTRACT_ADDRESS')
  static final String cryptocurrenciesIonBridgeContractAddress =
      _AppEnv.cryptocurrenciesIonBridgeContractAddress;

  @EnviedField(varName: 'CRYPTOCURRENCIES_ION_TRADE_URL')
  static final String cryptocurrenciesIonTradeUrl = _AppEnv.cryptocurrenciesIonTradeUrl;

  @EnviedField(varName: 'CRYPTOCURRENCIES_ION_JRPC_URL')
  static final String cryptocurrenciesIonJrpcUrl = _AppEnv.cryptocurrenciesIonJrpcUrl;

  @EnviedField(varName: 'RELAY_PROXY_DOMAINS')
  static final String relayProxyDomains = _AppEnv.relayProxyDomains;

  @EnviedField(varName: 'RPC_PROXY_DOMAINS')
  static final String rpcProxyDomains = _AppEnv.rpcProxyDomains;
}

enum EnvVariable {
  ION_ANDROID_APP_ID,
  ION_IOS_APP_ID,
  ION_ORIGIN,
  ION_INTERNAL_DEEP_LINK_SCHEME,
  SHOW_DEBUG_INFO,
  BANUBA_TOKEN,
  STORY_EXPIRATION_HOURS,
  EDIT_POST_ALLOWED_MINUTES,
  USER_METADATA_CACHE_DURATION,
  EDIT_MESSAGE_ALLOWED_MINUTES,
  COMMUNITY_CREATION_CACHE_MINUTES,
  COMMUNITY_MEMBERS_COUNT_CACHE_MINUTES,
  GIFT_WRAP_EXPIRATION_HOURS,
  MIN_APP_VERSION_CONFIG_CACHE_DURATION,
  GENERIC_CONFIG_CACHE_DURATION,
  ICLOUD_CONTAINER_ID,
  SENTRY_DSN,
  FOUNDATION_APP_GROUP,
  FIREBASE_CONFIG,
  RELAY_PING_INTERVAL_DURATION,
  CHECKSUM,
  FEED_MIN_VISIBLE_ARTICLE_CATEGORIES_NUMBER,
  ENFORCE_ACCOUNT_SECURITY_DELAY_IN_MINUTES,
  ACCOUNT_NOTIFICATION_SETTINGS_SYNC_INTERVAL_MINUTES,
  AF_APP_ID,
  AF_ONE_LINK_TEMPLATE_ID,
  AF_DEV_KEY,
  AF_BRAND_DOMAIN,
  AF_BASE_HOST,
  OPTIMISTIC_UI_ENABLED,
  INDEXER_BASE_URL,
  NFT_IDENTITY_BASE_URL,
  SHARE_APP_NAME,
  CRYPTOCURRENCIES_SWAP_OKX_API_KEY,
  CRYPTOCURRENCIES_SWAP_OKX_SIGN_KEY,
  CRYPTOCURRENCIES_SWAP_OKX_PASSPHRASE,
  CRYPTOCURRENCIES_SWAP_OKX_API_URL,
  CRYPTOCURRENCIES_BRIDGE_RELAY_BASE_URL,
  CRYPTOCURRENCIES_CEX_LETS_EXCHANGE_API_KEY,
  CRYPTOCURRENCIES_CEX_LETS_EXCHANGE_API_URL,
  CRYPTOCURRENCIES_CEX_LETS_EXCHANGE_API_AFFILIATE_ID,
  CRYPTOCURRENCIES_CEX_EXOLIX_API_KEY,
  CRYPTOCURRENCIES_CEX_EXOLIX_API_URL,
  ION_TOKEN_ANALYTICS_BASE_URL,
  CRYPTOCURRENCIES_BSC_RPC_URL,
  CRYPTOCURRENCIES_BSC_RPC_URLS,
  CRYPTOCURRENCIES_ION_SWAP_CONTRACT_ADDRESS,
  CRYPTOCURRENCIES_ICE_BSC_TOKEN_ADDRESS,
  CRYPTOCURRENCIES_ION_BSC_TOKEN_ADDRESS,
  CRYPTOCURRENCIES_ION_BRIDGE_ROUTER_CONTRACT_ADDRESS,
  CRYPTOCURRENCIES_ION_BRIDGE_CONTRACT_ADDRESS,
  CRYPTOCURRENCIES_ION_TRADE_URL,
  CRYPTOCURRENCIES_ION_JRPC_URL,
  RELAY_PROXY_DOMAINS,
  RPC_PROXY_DOMAINS
}

@Riverpod(keepAlive: true)
class Env extends _$Env {
  @override
  void build() {}

  static String _norm(String v) => v.trim();

  static int _toInt(String v) => int.parse(_norm(v));

  static bool _toBool(String v) {
    final s = _norm(v).toLowerCase();
    return s == 'true' || s == '1' || s == 'yes' || s == 'y';
  }

  /// New env getter backed by `envied`-generated `AppEnv`.
  ///
  /// NOTE: We keep the old `Env.get()` (fromEnvironment) for now and can
  /// switch call sites incrementally.
  T get<T>(EnvVariable variable) {
    return switch (variable) {
      EnvVariable.ION_ANDROID_APP_ID => AppEnv.ionAndroidAppId as T,
      EnvVariable.ION_IOS_APP_ID => AppEnv.ionIosAppId as T,
      EnvVariable.ION_ORIGIN => AppEnv.ionOrigin as T,
      EnvVariable.ION_INTERNAL_DEEP_LINK_SCHEME => AppEnv.ionInternalDeepLinkScheme as T,
      EnvVariable.SHOW_DEBUG_INFO => _toBool(AppEnv.showDebugInfo) as T,
      EnvVariable.BANUBA_TOKEN => AppEnv.banubaToken as T,
      EnvVariable.STORY_EXPIRATION_HOURS => _toInt(AppEnv.storyExpirationHours) as T,
      EnvVariable.EDIT_POST_ALLOWED_MINUTES => _toInt(AppEnv.editPostAllowedMinutes) as T,
      EnvVariable.USER_METADATA_CACHE_DURATION => Duration(
          minutes: _toInt(AppEnv.userMetadataCacheMinutes),
        ) as T,
      EnvVariable.EDIT_MESSAGE_ALLOWED_MINUTES => _toInt(AppEnv.editMessageAllowedMinutes) as T,
      EnvVariable.COMMUNITY_CREATION_CACHE_MINUTES =>
        _toInt(AppEnv.communityCreationCacheMinutes) as T,
      EnvVariable.COMMUNITY_MEMBERS_COUNT_CACHE_MINUTES =>
        _toInt(AppEnv.communityMembersCountCacheMinutes) as T,
      EnvVariable.GIFT_WRAP_EXPIRATION_HOURS => _toInt(AppEnv.giftWrapExpirationHours) as T,
      EnvVariable.MIN_APP_VERSION_CONFIG_CACHE_DURATION => Duration(
          minutes: _toInt(AppEnv.minAppVersionConfigCacheMinutes),
        ) as T,
      EnvVariable.GENERIC_CONFIG_CACHE_DURATION => Duration(
          minutes: _toInt(AppEnv.genericConfigCacheMinutes),
        ) as T,
      EnvVariable.ICLOUD_CONTAINER_ID => AppEnv.icloudContainerId as T,
      EnvVariable.SENTRY_DSN => AppEnv.sentryDsn as T,
      EnvVariable.FOUNDATION_APP_GROUP => AppEnv.foundationAppGroup as T,
      EnvVariable.FIREBASE_CONFIG => switch (defaultTargetPlatform) {
          TargetPlatform.android => AppEnv.firebaseConfigAndroid as T,
          TargetPlatform.iOS => AppEnv.firebaseConfigIos as T,
          _ => throw UnsupportedError('Unsupported platform'),
        },
      EnvVariable.RELAY_PING_INTERVAL_DURATION => Duration(
          seconds: _toInt(AppEnv.relayPingIntervalSeconds),
        ) as T,
      EnvVariable.CHECKSUM => AppEnv.checksum as T,
      EnvVariable.FEED_MIN_VISIBLE_ARTICLE_CATEGORIES_NUMBER =>
        _toInt(AppEnv.feedMinVisibleArticleCategoriesNumber) as T,
      EnvVariable.ENFORCE_ACCOUNT_SECURITY_DELAY_IN_MINUTES => Duration(
          minutes: _toInt(AppEnv.enforceAccountSecurityDelayInMinutes),
        ) as T,
      EnvVariable.ACCOUNT_NOTIFICATION_SETTINGS_SYNC_INTERVAL_MINUTES => Duration(
          minutes: _toInt(AppEnv.accountNotificationSettingsSyncIntervalMinutes),
        ) as T,
      EnvVariable.AF_APP_ID => switch (defaultTargetPlatform) {
          TargetPlatform.iOS => AppEnv.afIosAppId as T,
          TargetPlatform.android => AppEnv.afAndroidAppId as T,
          _ => throw UnsupportedError('Unsupported platform'),
        },
      EnvVariable.AF_ONE_LINK_TEMPLATE_ID => AppEnv.afOneLinkTemplateId as T,
      EnvVariable.AF_DEV_KEY => AppEnv.afDevKey as T,
      EnvVariable.AF_BRAND_DOMAIN => AppEnv.afBrandDomain as T,
      EnvVariable.AF_BASE_HOST => AppEnv.afBaseHost as T,
      EnvVariable.OPTIMISTIC_UI_ENABLED => _toBool(AppEnv.optimisticUiEnabled) as T,
      EnvVariable.INDEXER_BASE_URL => AppEnv.indexerBaseUrl as T,
      EnvVariable.NFT_IDENTITY_BASE_URL => AppEnv.nftIdentityBaseUrl as T,
      EnvVariable.SHARE_APP_NAME => AppEnv.shareAppName as T,
      EnvVariable.CRYPTOCURRENCIES_SWAP_OKX_API_KEY => AppEnv.cryptocurrenciesSwapOkxApiKey as T,
      EnvVariable.CRYPTOCURRENCIES_SWAP_OKX_SIGN_KEY => AppEnv.cryptocurrenciesSwapOkxSignKey as T,
      EnvVariable.CRYPTOCURRENCIES_SWAP_OKX_PASSPHRASE =>
        AppEnv.cryptocurrenciesSwapOkxPassphrase as T,
      EnvVariable.CRYPTOCURRENCIES_SWAP_OKX_API_URL => AppEnv.cryptocurrenciesSwapOkxApiUrl as T,
      EnvVariable.CRYPTOCURRENCIES_BRIDGE_RELAY_BASE_URL =>
        AppEnv.cryptocurrenciesBridgeRelayBaseUrl as T,
      EnvVariable.CRYPTOCURRENCIES_CEX_LETS_EXCHANGE_API_KEY =>
        AppEnv.cryptocurrenciesCexLetsExchangeApiKey as T,
      EnvVariable.CRYPTOCURRENCIES_CEX_LETS_EXCHANGE_API_URL =>
        AppEnv.cryptocurrenciesCexLetsExchangeApiUrl as T,
      EnvVariable.CRYPTOCURRENCIES_CEX_LETS_EXCHANGE_API_AFFILIATE_ID =>
        AppEnv.cryptocurrenciesCexLetsExchangeApiAffiliateId as T,
      EnvVariable.CRYPTOCURRENCIES_CEX_EXOLIX_API_KEY =>
        AppEnv.cryptocurrenciesCexExolixApiKey as T,
      EnvVariable.CRYPTOCURRENCIES_CEX_EXOLIX_API_URL =>
        AppEnv.cryptocurrenciesCexExolixApiUrl as T,
      EnvVariable.ION_TOKEN_ANALYTICS_BASE_URL => AppEnv.ionTokenAnalyticsBaseUrl as T,
      EnvVariable.CRYPTOCURRENCIES_BSC_RPC_URL => AppEnv.cryptocurrenciesBscRpcUrl as T,
      EnvVariable.CRYPTOCURRENCIES_BSC_RPC_URLS => AppEnv.cryptocurrenciesBscRpcUrls as T,
      EnvVariable.CRYPTOCURRENCIES_ION_SWAP_CONTRACT_ADDRESS =>
        AppEnv.cryptocurrenciesIonSwapContractAddress as T,
      EnvVariable.CRYPTOCURRENCIES_ICE_BSC_TOKEN_ADDRESS =>
        AppEnv.cryptocurrenciesIceBscTokenAddress as T,
      EnvVariable.CRYPTOCURRENCIES_ION_BSC_TOKEN_ADDRESS =>
        AppEnv.cryptocurrenciesIonBscTokenAddress as T,
      EnvVariable.CRYPTOCURRENCIES_ION_BRIDGE_ROUTER_CONTRACT_ADDRESS =>
        AppEnv.cryptocurrenciesIonBridgeRouterContractAddress as T,
      EnvVariable.CRYPTOCURRENCIES_ION_BRIDGE_CONTRACT_ADDRESS =>
        AppEnv.cryptocurrenciesIonBridgeContractAddress as T,
      EnvVariable.CRYPTOCURRENCIES_ION_TRADE_URL => AppEnv.cryptocurrenciesIonTradeUrl as T,
      EnvVariable.CRYPTOCURRENCIES_ION_JRPC_URL => AppEnv.cryptocurrenciesIonJrpcUrl as T,
      EnvVariable.RELAY_PROXY_DOMAINS => AppEnv.relayProxyDomains as T,
      EnvVariable.RPC_PROXY_DOMAINS => AppEnv.rpcProxyDomains as T,
    };
  }
}
