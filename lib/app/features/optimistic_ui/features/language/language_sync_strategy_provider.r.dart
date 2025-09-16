// SPDX-License-Identifier: ice License 1.0

import 'dart:async';

import 'package:collection/collection.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/features/auth/providers/auth_provider.m.dart';
import 'package:ion/app/features/core/providers/app_locale_provider.r.dart';
import 'package:ion/app/features/core/providers/env_provider.r.dart';
import 'package:ion/app/features/ion_connect/providers/ion_connect_notifier.r.dart';
import 'package:ion/app/features/optimistic_ui/core/operation_manager.dart';
import 'package:ion/app/features/optimistic_ui/core/optimistic_service.dart';
import 'package:ion/app/features/optimistic_ui/features/language/change_language_intent.dart';
import 'package:ion/app/features/optimistic_ui/features/language/language_sync_strategy.dart';
import 'package:ion/app/features/settings/model/content_lang_set.f.dart';
import 'package:ion/app/features/user/model/interest_set.f.dart';
import 'package:ion/app/features/user/providers/user_interests_set_provider.r.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'language_sync_strategy_provider.r.g.dart';

@riverpod
LanguageSyncStrategy languageSyncStrategy(Ref ref) {
  final notifier = ref.read(ionConnectNotifierProvider.notifier);
  return LanguageSyncStrategy(sendInterestSet: notifier.sendEntityData);
}

@Riverpod(keepAlive: true)
OptimisticOperationManager<ContentLangSet> contentLanguageManager(Ref ref) {
  final strategy = ref.watch(languageSyncStrategyProvider);
  final localEnabled = ref.watch(envProvider.notifier).get<bool>(EnvVariable.OPTIMISTIC_UI_ENABLED);

  final manager = OptimisticOperationManager<ContentLangSet>(
    syncCallback: strategy.send,
    onError: (_, err) async => err is TimeoutException,
    enableLocal: localEnabled,
  );

  ref.onDispose(manager.dispose);
  return manager;
}

@riverpod
OptimisticService<ContentLangSet> contentLanguageService(Ref ref) {
  final manager = ref.watch(contentLanguageManagerProvider);

  final initialLanguages = () async {
    final entity =
        await ref.read(currentUserInterestsSetProvider(InterestSetType.languages).future);
    final pubkey = ref.read(currentPubkeySelectorProvider);
    if (pubkey == null) return <ContentLangSet>[];

    return [
      if (entity != null)
        ContentLangSet(
          pubkey: pubkey,
          hashtags: entity.data.hashtags,
        ).sorted
      else
        _initialLangSet(ref),
    ];
  }();

  final service = OptimisticService<ContentLangSet>(manager: manager)..initialize(initialLanguages);
  return service;
}

@riverpod
Stream<ContentLangSet?> contentLanguageWatch(Ref ref) async* {
  final pubkey = ref.watch(currentPubkeySelectorProvider);
  if (pubkey == null) {
    yield null;
    return;
  }

  final service = ref.watch(contentLanguageServiceProvider);

  final first = ref
      .watch(contentLanguageManagerProvider)
      .snapshot
      .firstWhereOrNull((e) => e.optimisticId == pubkey);

  if (first != null) yield first;

  yield* service.watch(pubkey);
}

@riverpod
class ToggleLanguageNotifier extends _$ToggleLanguageNotifier {
  @override
  void build() {}

  Future<void> toggle(String iso) async {
    final pubkey = ref.read(currentPubkeySelectorProvider);
    if (pubkey == null) return;

    final current = ref.read(contentLanguageWatchProvider).valueOrNull;

    if (current == null) return;

    final service = ref.read(contentLanguageServiceProvider);
    await service.dispatch(ChangeLanguageIntent(iso), current);
  }
}

ContentLangSet _initialLangSet(Ref ref) {
  final pubkey = ref.read(currentPubkeySelectorProvider)!;
  final entity = ref.read(currentUserInterestsSetProvider(InterestSetType.languages)).value;
  final appIso = ref.read(localePreferredLanguagesProvider).first.isoCode;

  return ContentLangSet(
    pubkey: pubkey,
    hashtags: (entity?.data.hashtags ?? const []).isEmpty ? [appIso] : entity!.data.hashtags,
  ).sorted;
}
