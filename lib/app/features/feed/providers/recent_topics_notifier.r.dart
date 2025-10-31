// SPDX-License-Identifier: ice License 1.0

import 'package:ion/app/features/feed/data/models/feed_type.dart';
import 'package:ion/app/features/feed/providers/feed_user_interests_provider.r.dart';
import 'package:ion/app/services/storage/user_preferences_service.r.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'recent_topics_notifier.r.g.dart';

/// Tracks recently selected subcategory keys (up to [_maxItems]) per [FeedType].
/// Persisted per-identity via [currentUserPreferencesServiceProvider].
@riverpod
class RecentTopicsNotifier extends _$RecentTopicsNotifier {
  static const int _maxItems = 3;

  @override
  Set<String> build(FeedType feedType) {
    // Load from prefs and filter against available subcategories.
    final prefs = ref.watch(currentUserPreferencesServiceProvider);
    final available = ref.watch(feedUserInterestsProvider(feedType)).valueOrNull;

    final stored = prefs?.getValue<List<String>>(_prefsKey(feedType)) ?? const <String>[];
    final subcategoryKeys = available?.subcategories.keys.toSet() ?? {};

    // Preserve insertion order, trim to max, and remove unknown keys.
    final initial = stored.where(subcategoryKeys.contains).take(_maxItems).toSet();

    return initial;
  }

  void appendAll(FeedType feedType, Set<String> subcategoryKeys) {
    // Iterate in reverse so that final state preserves the original insertion order.
    for (final subcategoryKey in subcategoryKeys.toList().reversed) {
      append(feedType, subcategoryKey);
    }
  }

  void append(FeedType feedType, String subcategoryKey) {
    // Move-to-front semantics while preserving order for the rest.
    final updated = <String>{
      subcategoryKey,
      ...state.where((e) => e != subcategoryKey),
    };
    final trimmed = updated.take(_maxItems).toSet();
    state = trimmed;
    _persist(feedType, trimmed);
  }

  void _persist(FeedType feedType, Set<String> value) {
    final prefs = ref.read(currentUserPreferencesServiceProvider);
    prefs?.setValue<List<String>>(
      _prefsKey(feedType),
      value.toList(growable: false),
    );
  }

  String _prefsKey(FeedType ft) => 'recent_topics_${ft.name}_v1';
}
