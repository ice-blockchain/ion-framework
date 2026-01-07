// SPDX-License-Identifier: ice License 1.0

import 'package:flutter_test/flutter_test.dart';
import 'package:ion/app/features/optimistic_ui/features/language/language_sync_strategy.dart';
import 'package:ion/app/features/optimistic_ui/features/language/update_languages_intent.dart';
import 'package:ion/app/features/settings/model/content_lang_set.f.dart';
import 'package:ion/app/features/user/model/interest_set.f.dart';

void main() {
  group('UpdateLanguagesIntent', () {
    const base = ContentLangSet(pubkey: 'pubkey1', hashtags: ['en']);

    test('replaces all languages with provided list, keeps sorted order', () {
      final intent = UpdateLanguagesIntent(['fr', 'de', 'en']);
      final optimistic = intent.optimistic(base);

      expect(optimistic.hashtags, equals(['de', 'en', 'fr']));
    });

    test('replaces with empty list', () {
      final intent = UpdateLanguagesIntent([]);
      final optimistic = intent.optimistic(base);

      expect(optimistic.hashtags, isEmpty);
    });

    test('replaces with single language', () {
      final intent = UpdateLanguagesIntent(['fr']);
      final optimistic = intent.optimistic(base);

      expect(optimistic.hashtags, equals(['fr']));
    });

    test('replaces with multiple languages, maintains sorted order', () {
      final intent = UpdateLanguagesIntent(['zh', 'ja', 'ko', 'en']);
      final optimistic = intent.optimistic(base);

      expect(optimistic.hashtags, equals(['en', 'ja', 'ko', 'zh']));
    });
  });

  group('LanguageSyncStrategy', () {
    test('sends InterestSetData with correct hashtags', () async {
      late InterestSetData captured;
      final strategy = LanguageSyncStrategy(
        sendInterestSet: (data) async => captured = data,
      );

      const prev = ContentLangSet(pubkey: 'pubkey1', hashtags: ['en']);
      const next = ContentLangSet(pubkey: 'pubkey1', hashtags: ['en', 'fr']);

      final result = await strategy.send(prev, next);

      expect(result, same(next), reason: 'Should return optimistic state');
      expect(captured.type, InterestSetType.languages);
      expect(captured.hashtags, equals(['en', 'fr']));
    });
  });
}
