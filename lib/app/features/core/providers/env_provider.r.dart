// SPDX-License-Identifier: ice License 1.0

// ignore_for_file: constant_identifier_names

import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'env_provider.r.g.dart';

enum EnvVariable {
  ION_ANDROID_APP_ID,
  ION_IOS_APP_ID,
  ION_ORIGIN,
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
  RELAY_PING_INTERVAL_SECONDS,
  CHECKSUM,
  FEED_MIN_VISIBLE_ARTICLE_CATEGORIES_NUMBER,
  ACCOUNT_NOTIFICATION_SETTINGS_SYNC_INTERVAL_MINUTES,
  AF_APP_ID,
  AF_ONE_LINK_TEMPLATE_ID,
  AF_DEV_KEY,
  AF_BRAND_DOMAIN,
  AF_BASE_HOST,
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
      EnvVariable.RELAY_PING_INTERVAL_SECONDS => const int.fromEnvironment(
          'RELAY_PING_INTERVAL_SECONDS',
          defaultValue: 3600,
        ) as T,
      EnvVariable.CHECKSUM => const String.fromEnvironment('CHECKSUM') as T,
      EnvVariable.FEED_MIN_VISIBLE_ARTICLE_CATEGORIES_NUMBER => const int.fromEnvironment(
          'FEED_MIN_VISIBLE_ARTICLE_CATEGORIES_NUMBER',
          defaultValue: 5,
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
    };
  }
}
