// SPDX-License-Identifier: ice License 1.0

import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/feed/providers/suggestions/cashtags/cashtag_suggestions_provider.r.dart';
import 'package:ion/app/features/feed/providers/suggestions/hashtags/hashtag_suggestions_provider.r.dart';
import 'package:ion/app/features/feed/providers/suggestions/mentions/mention_suggestions_provider.r.dart';
import 'package:ion/app/services/logger/logger.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'suggestions_notifier_provider.r.g.dart';

class SuggestionsState {
  const SuggestionsState({
    this.suggestions = const [],
    this.taggingCharacter = '',
    this.isVisible = false,
  });

  final List<String> suggestions;
  final String taggingCharacter;
  final bool isVisible;

  SuggestionsState copyWith({
    List<String>? suggestions,
    String? taggingCharacter,
    bool? isVisible,
  }) {
    return SuggestionsState(
      suggestions: suggestions ?? this.suggestions,
      taggingCharacter: taggingCharacter ?? this.taggingCharacter,
      isVisible: isVisible ?? this.isVisible,
    );
  }
}

@riverpod
class SuggestionsNotifier extends _$SuggestionsNotifier {
  String _currentQuery = '';

  @override
  SuggestionsState build() {
    return const SuggestionsState();
  }

  Future<void> updateSuggestions(String query, String taggingCharacter) async {
    //if previous suggestion was empty but the query was changed we want to show loading state rather then empty one
    if (state.isVisible && state.suggestions.isEmpty) {
      state = state.copyWith(isVisible: false);
    }

    if (query.isEmpty) {
      ref.invalidate(suggestionsNotifierProvider);
      return;
    }

    _currentQuery = query;
    await ref.debounce();
    if (_currentQuery != query) {
      return;
    }

    try {
      final suggestions = switch (taggingCharacter) {
        '#' => await ref.read(hashtagSuggestionsProvider(query).future),
        '@' => await ref.read(mentionSuggestionsProvider(query).future),
        r'$' => await ref.read(cashtagSuggestionsProvider(query).future),
        _ => <String>[],
      };

      state = SuggestionsState(
        suggestions: suggestions,
        taggingCharacter: taggingCharacter,
        isVisible: true,
      );
    } catch (error) {
      Logger.log('Error fetching suggestions: $error');
      state = const SuggestionsState();
    }
  }
}
