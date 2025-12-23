// SPDX-License-Identifier: ice License 1.0

// ignore_for_file: constant_identifier_names

import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'env_provider.r.g.dart';

enum EnvVariable {
  ION_ANDROID_APP_ID,
  ION_IOS_APP_ID,
  ION_ORIGIN,
  ION_INTERNAL_DEEP_LINK_SCHEME,
  SHOW_DEBUG_INFO,
  BANUBA_TOKEN,
  STORY_EXPIRATION_HOURS,
  EDIT_POST_ALLOWED_MINUTES,
  USER_METADATA_SYNC_MINUTES,
  CHAT_PRIVACY_CACHE_MINUTES,
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
}

@Riverpod(keepAlive: true)
class Env extends _$Env {
  @override
  void build() {}

  /// Gets a typed environment variable value.
  /// Throws if the variable is not found or cannot be converted to type [T].
  T get<T>(EnvVariable variable) {
    return switch (variable) {
      EnvVariable.ION_ANDROID_APP_ID => const String.fromEnvironment('ION_ANDROID_APP_ID') as T,
      EnvVariable.ION_IOS_APP_ID => const String.fromEnvironment('ION_IOS_APP_ID') as T,
      EnvVariable.ION_ORIGIN => const String.fromEnvironment('ION_ORIGIN') as T,
      EnvVariable.ION_INTERNAL_DEEP_LINK_SCHEME =>
        const String.fromEnvironment('ION_INTERNAL_DEEP_LINK_SCHEME', defaultValue: 'ionapp') as T,
      EnvVariable.SHOW_DEBUG_INFO => const bool.fromEnvironment('SHOW_DEBUG_INFO') as T,
      EnvVariable.BANUBA_TOKEN => const String.fromEnvironment('BANUBA_TOKEN') as T,
      EnvVariable.STORY_EXPIRATION_HOURS =>
        const int.fromEnvironment('STORY_EXPIRATION_HOURS') as T,
      EnvVariable.USER_METADATA_SYNC_MINUTES =>
        const int.fromEnvironment('USER_METADATA_SYNC_MINUTES') as T,
      EnvVariable.CHAT_PRIVACY_CACHE_MINUTES =>
        const int.fromEnvironment('CHAT_PRIVACY_CACHE_MINUTES') as T,
      EnvVariable.EDIT_POST_ALLOWED_MINUTES =>
        const int.fromEnvironment('EDIT_POST_ALLOWED_MINUTES') as T,
      EnvVariable.EDIT_MESSAGE_ALLOWED_MINUTES =>
        const int.fromEnvironment('EDIT_MESSAGE_ALLOWED_MINUTES') as T,
      EnvVariable.COMMUNITY_CREATION_CACHE_MINUTES =>
        const int.fromEnvironment('COMMUNITY_CREATION_CACHE_MINUTES') as T,
      EnvVariable.COMMUNITY_MEMBERS_COUNT_CACHE_MINUTES =>
        const int.fromEnvironment('COMMUNITY_MEMBERS_COUNT_CACHE_MINUTES') as T,
      EnvVariable.GIFT_WRAP_EXPIRATION_HOURS =>
        const int.fromEnvironment('GIFT_WRAP_EXPIRATION_HOURS') as T,
      EnvVariable.MIN_APP_VERSION_CONFIG_CACHE_DURATION => const Duration(
          minutes: int.fromEnvironment('MIN_APP_VERSION_CONFIG_CACHE_MINUTES', defaultValue: 480),
        ) as T,
      EnvVariable.GENERIC_CONFIG_CACHE_DURATION => const Duration(
          minutes: int.fromEnvironment('GENERIC_CONFIG_CACHE_MINUTES', defaultValue: 480),
        ) as T,
      EnvVariable.ICLOUD_CONTAINER_ID => const String.fromEnvironment('ICLOUD_CONTAINER_ID') as T,
      EnvVariable.SENTRY_DSN => const String.fromEnvironment('SENTRY_DSN') as T,
      EnvVariable.FOUNDATION_APP_GROUP => const String.fromEnvironment('FOUNDATION_APP_GROUP') as T,
      EnvVariable.FIREBASE_CONFIG => switch (defaultTargetPlatform) {
          TargetPlatform.android => const String.fromEnvironment('FIREBASE_CONFIG_ANDROID') as T,
          TargetPlatform.iOS => const String.fromEnvironment('FIREBASE_CONFIG_IOS') as T,
          _ => throw UnsupportedError('Unsupported platform'),
        },
      EnvVariable.RELAY_PING_INTERVAL_DURATION => const Duration(
          seconds: int.fromEnvironment(
            'RELAY_PING_INTERVAL_SECONDS',
            defaultValue: 3600,
          ),
        ) as T,
      EnvVariable.CHECKSUM => const String.fromEnvironment('CHECKSUM') as T,
      EnvVariable.FEED_MIN_VISIBLE_ARTICLE_CATEGORIES_NUMBER => const int.fromEnvironment(
          'FEED_MIN_VISIBLE_ARTICLE_CATEGORIES_NUMBER',
          defaultValue: 5,
        ) as T,
      EnvVariable.ENFORCE_ACCOUNT_SECURITY_DELAY_IN_MINUTES => const Duration(
          minutes: int.fromEnvironment(
            'ENFORCE_ACCOUNT_SECURITY_DELAY_IN_MINUTES',
            defaultValue: 1440,
          ),
        ) as T,
      EnvVariable.ACCOUNT_NOTIFICATION_SETTINGS_SYNC_INTERVAL_MINUTES => const Duration(
          minutes: int.fromEnvironment(
            'ACCOUNT_NOTIFICATION_SETTINGS_SYNC_INTERVAL_MINUTES',
            defaultValue: 60,
          ),
        ) as T,
      EnvVariable.AF_APP_ID => switch (defaultTargetPlatform) {
          TargetPlatform.iOS => const String.fromEnvironment('AF_IOS_APP_ID') as T,
          TargetPlatform.android => const String.fromEnvironment('AF_ANDROID_APP_ID') as T,
          _ => throw UnsupportedError('Unsupported platform'),
        },
      EnvVariable.AF_ONE_LINK_TEMPLATE_ID =>
        const String.fromEnvironment('AF_ONE_LINK_TEMPLATE_ID') as T,
      EnvVariable.AF_DEV_KEY => const String.fromEnvironment('AF_DEV_KEY') as T,
      EnvVariable.AF_BRAND_DOMAIN => const String.fromEnvironment('AF_BRAND_DOMAIN') as T,
      EnvVariable.AF_BASE_HOST => const String.fromEnvironment('AF_BASE_HOST') as T,
      EnvVariable.OPTIMISTIC_UI_ENABLED => const bool.fromEnvironment('OPTIMISTIC_UI_ENABLED') as T,
      EnvVariable.INDEXER_BASE_URL => const String.fromEnvironment('INDEXER_BASE_URL') as T,
      EnvVariable.NFT_IDENTITY_BASE_URL =>
        const String.fromEnvironment('NFT_IDENTITY_BASE_URL') as T,
      EnvVariable.SHARE_APP_NAME => const String.fromEnvironment('SHARE_APP_NAME') as T,
      EnvVariable.CRYPTOCURRENCIES_SWAP_OKX_API_KEY =>
        const String.fromEnvironment('CRYPTOCURRENCIES_SWAP_OKX_API_KEY') as T,
      EnvVariable.CRYPTOCURRENCIES_SWAP_OKX_SIGN_KEY =>
        const String.fromEnvironment('CRYPTOCURRENCIES_SWAP_OKX_SIGN_KEY') as T,
      EnvVariable.CRYPTOCURRENCIES_SWAP_OKX_API_URL =>
        const String.fromEnvironment('CRYPTOCURRENCIES_SWAP_OKX_API_URL') as T,
      EnvVariable.CRYPTOCURRENCIES_SWAP_OKX_PASSPHRASE =>
        const String.fromEnvironment('CRYPTOCURRENCIES_SWAP_OKX_PASSPHRASE') as T,
      EnvVariable.CRYPTOCURRENCIES_BRIDGE_RELAY_BASE_URL =>
        const String.fromEnvironment('CRYPTOCURRENCIES_BRIDGE_RELAY_BASE_URL') as T,
      EnvVariable.CRYPTOCURRENCIES_CEX_LETS_EXCHANGE_API_KEY =>
        const String.fromEnvironment('CRYPTOCURRENCIES_CEX_LETS_EXCHANGE_API_KEY') as T,
      EnvVariable.CRYPTOCURRENCIES_CEX_LETS_EXCHANGE_API_URL =>
        const String.fromEnvironment('CRYPTOCURRENCIES_CEX_LETS_EXCHANGE_API_URL') as T,
      EnvVariable.CRYPTOCURRENCIES_CEX_LETS_EXCHANGE_API_AFFILIATE_ID =>
        const String.fromEnvironment('CRYPTOCURRENCIES_CEX_LETS_EXCHANGE_API_AFFILIATE_ID') as T,
      EnvVariable.CRYPTOCURRENCIES_CEX_EXOLIX_API_KEY =>
        const String.fromEnvironment('CRYPTOCURRENCIES_CEX_EXOLIX_API_KEY') as T,
      EnvVariable.CRYPTOCURRENCIES_CEX_EXOLIX_API_URL =>
        const String.fromEnvironment('CRYPTOCURRENCIES_CEX_EXOLIX_API_URL') as T,
      EnvVariable.ION_TOKEN_ANALYTICS_BASE_URL =>
        const String.fromEnvironment('ION_TOKEN_ANALYTICS_BASE_URL') as T,
      EnvVariable.CRYPTOCURRENCIES_BSC_RPC_URL =>
        const String.fromEnvironment('CRYPTOCURRENCIES_BSC_RPC_URL') as T,
      EnvVariable.CRYPTOCURRENCIES_BSC_RPC_URLS =>
        const String.fromEnvironment('CRYPTOCURRENCIES_BSC_RPC_URLS') as T,
      EnvVariable.CRYPTOCURRENCIES_ION_SWAP_CONTRACT_ADDRESS =>
        const String.fromEnvironment('CRYPTOCURRENCIES_ION_SWAP_CONTRACT_ADDRESS') as T,
      EnvVariable.CRYPTOCURRENCIES_ICE_BSC_TOKEN_ADDRESS =>
        const String.fromEnvironment('CRYPTOCURRENCIES_ICE_BSC_TOKEN_ADDRESS') as T,
      EnvVariable.CRYPTOCURRENCIES_ION_BSC_TOKEN_ADDRESS =>
        const String.fromEnvironment('CRYPTOCURRENCIES_ION_BSC_TOKEN_ADDRESS') as T,
      EnvVariable.CRYPTOCURRENCIES_ION_BRIDGE_ROUTER_CONTRACT_ADDRESS =>
        const String.fromEnvironment('CRYPTOCURRENCIES_ION_BRIDGE_ROUTER_CONTRACT_ADDRESS') as T,
      EnvVariable.CRYPTOCURRENCIES_ION_BRIDGE_CONTRACT_ADDRESS =>
        const String.fromEnvironment('CRYPTOCURRENCIES_ION_BRIDGE_CONTRACT_ADDRESS') as T,
      EnvVariable.CRYPTOCURRENCIES_ION_TRADE_URL =>
        const String.fromEnvironment('CRYPTOCURRENCIES_ION_TRADE_URL') as T,
      EnvVariable.CRYPTOCURRENCIES_ION_JRPC_URL =>
        const String.fromEnvironment('CRYPTOCURRENCIES_ION_JRPC_URL') as T,
    };
  }
}
