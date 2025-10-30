// SPDX-License-Identifier: ice License 1.0

import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/features/chat/services/shared_chat_isolate.dart';
import 'package:ion/app/features/core/model/emoji/emoji_group.f.dart';
import 'package:ion/generated/assets.gen.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'emoji_set_provider.r.g.dart';

@Riverpod(keepAlive: true)
Future<List<EmojiGroup>> emojiGroups(Ref ref) async {
  final data = await rootBundle.loadString(Assets.emojiDataSets.emojisByGroup);

  return sharedChatIsolate(
    (data) {
      final jsonData = jsonDecode(data) as List<dynamic>;
      return jsonData.map((group) => EmojiGroup.fromJson(group as Map<String, dynamic>)).toList();
    },
    data,
  );
}

@Riverpod(keepAlive: true)
Future<Map<String, List<String>>> emojiKeywords(Ref ref) async {
  final data = await rootBundle.loadString(Assets.emojiDataSets.emojiKeywords);
  final jsonData = jsonDecode(data) as Map<String, dynamic>;
  return jsonData.map(
    (key, value) => MapEntry(
      key,
      (value as List<dynamic>).map((e) => e as String).toList(),
    ),
  );
}

@riverpod
class EmojiSearchQuery extends _$EmojiSearchQuery {
  @override
  String build() {
    return '';
  }

  set query(String value) {
    state = value;
  }
}

@riverpod
Future<List<EmojiGroup>> emojisFilteredByQuery(Ref ref) async {
  final emojiGroups = ref.watch(emojiGroupsProvider).valueOrNull;
  final keywords = ref.watch(emojiKeywordsProvider).valueOrNull;
  final searchQuery = ref.watch(emojiSearchQueryProvider);

  if (searchQuery.isEmpty || emojiGroups == null || keywords == null) {
    return emojiGroups ?? [];
  }

  final foundedEmojis = keywords.keys
      .where((key) => keywords[key]!.any((keyword) => keyword.contains(searchQuery)))
      .toList();

  return emojiGroups
      .map((group) {
        final result = group.copyWith(
          emojis: group.emojis.where((emoji) => foundedEmojis.contains(emoji.emoji)).toList(),
        );
        return result;
      })
      .where((group) => group.emojis.isNotEmpty)
      .toList();
}
