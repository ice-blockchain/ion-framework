// SPDX-License-Identifier: ice License 1.0

import 'dart:convert';
import 'dart:ui';

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/constants/client.dart';
import 'package:ion/app/exceptions/exceptions.dart';
import 'package:ion/app/features/config/data/models/app_config_cache_strategy.dart';
import 'package:ion/app/features/config/data/models/app_config_with_version.dart';
import 'package:ion/app/features/config/providers/config_repository.r.dart';
import 'package:ion/app/features/core/providers/app_locale_provider.r.dart';
import 'package:ion/app/services/logger/logger.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'app_translations_provider.m.freezed.dart';
part 'app_translations_provider.m.g.dart';

class Translator<T extends AppConfigWithVersion> {
  Translator({
    required ConfigRepository translationsRepository,
    required Locale locale,
  })  : _translationsRepository = translationsRepository,
        _locale = locale;

  final ConfigRepository _translationsRepository;

  final Locale _locale;

  final Map<Locale, PushNotificationTranslations> translations = {};

  Future<String?> translate(
    String? Function(PushNotificationTranslations) selector,
  ) async {
    return _translate(selector, locale: _locale);
  }

  Future<String?> _translate(
    String? Function(PushNotificationTranslations) selector, {
    required Locale locale,
  }) async {
    try {
      final translations = await _getTranslations(locale);
      final translation = selector(translations);
      if (translation == null) {
        throw TranslationNotFoundException(locale);
      }
      return translation;
    } catch (error, stackTrace) {
      Logger.error(
        error,
        stackTrace: stackTrace,
        message: 'Failed to translate for locale $locale',
      );
      if (locale != fallbackLocale) {
        return _translate(selector, locale: fallbackLocale);
      }
      return null;
    }
  }

  Future<PushNotificationTranslations> _getTranslations(Locale locale) async {
    if (translations.containsKey(locale)) {
      return translations[locale]!;
    }
    return translations[locale] =
        await _translationsRepository.getConfig<PushNotificationTranslations>(
      '${Client.id}_push-notifications_translations_${locale.languageCode}',
      cacheStrategy: AppConfigCacheStrategy.file,
      parser: (data) =>
          PushNotificationTranslations.fromJson(jsonDecode(data) as Map<String, dynamic>),
      checkVersion: true,
    );
  }

  static const Locale fallbackLocale = Locale('en', 'US');
}

@Riverpod(keepAlive: true)
Future<Translator<PushNotificationTranslations>> pushTranslator(Ref ref) async {
  final appLocale = ref.watch(appLocaleProvider);
  final translationsRepository = await ref.watch(configRepositoryProvider.future);

  return Translator(
    translationsRepository: translationsRepository,
    locale: appLocale,
  );
}

@freezed
class PushNotificationTranslations
    with _$PushNotificationTranslations
    implements AppConfigWithVersion {
  const factory PushNotificationTranslations({
    @JsonKey(name: '_version') required int version,
    NotificationTranslation? reply,
    NotificationTranslation? mention,
    NotificationTranslation? repost,
    NotificationTranslation? quote,
    NotificationTranslation? like,
    NotificationTranslation? follower,
    NotificationTranslation? paymentRequest,
    NotificationTranslation? paymentReceived,
    NotificationTranslation? chatDocumentMessage,
    NotificationTranslation? chatEmojiMessage,
    NotificationTranslation? chatPhotoMessage,
    NotificationTranslation? chatProfileMessage,
    NotificationTranslation? chatReaction,
    NotificationTranslation? chatSharePostMessage,
    NotificationTranslation? chatShareStoryMessage,
    NotificationTranslation? chatSharedStoryReplyMessage,
    NotificationTranslation? chatTextMessage,
    NotificationTranslation? chatVideoMessage,
    NotificationTranslation? chatVoiceMessage,
    NotificationTranslation? chatFirstContactMessage,
    NotificationTranslation? chatGifMessage,
    NotificationTranslation? chatMultiGifMessage,
    NotificationTranslation? chatMultiMediaMessage,
    NotificationTranslation? chatMultiPhotoMessage,
    NotificationTranslation? chatMultiVideoMessage,
    NotificationTranslation? chatPaymentRequestMessage,
    NotificationTranslation? chatPaymentReceivedMessage,
  }) = _PushNotificationTranslations;

  factory PushNotificationTranslations.fromJson(Map<String, dynamic> json) =>
      _$PushNotificationTranslationsFromJson(json);
}

@freezed
class NotificationTranslation with _$NotificationTranslation {
  const factory NotificationTranslation({
    String? title,
    String? body,
  }) = _NotificationTranslation;

  factory NotificationTranslation.fromJson(Map<String, dynamic> json) =>
      _$NotificationTranslationFromJson(json);
}
