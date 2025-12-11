// SPDX-License-Identifier: ice License 1.0

import 'package:drift/drift.dart';
import 'package:ion/app/features/feed/data/models/feed_modifier.dart';

// Feed modifier is a part of the primary key, so it might not be null on db level.
// So we map null values to -1
class FeedModifierConverter extends TypeConverter<FeedModifier?, int> {
  const FeedModifierConverter();

  @override
  FeedModifier? fromSql(int fromDb) {
    return switch (fromDb) {
      -1 => null,
      0 => FeedModifier.top(),
      1 => FeedModifier.trending(),
      2 => FeedModifier.explore(ExploreModifierType.withAnyTopic),
      3 => FeedModifier.explore(ExploreModifierType.interests),
      4 => FeedModifier.explore(ExploreModifierType.any),
      5 => FeedModifier.tokenizedCommunity(),
      _ => throw UnsupportedError('Unknown FeedModifier value: $fromDb'),
    };
  }

  @override
  int toSql(FeedModifier? value) {
    return switch (value) {
      FeedModifierTop() => 0,
      FeedModifierTrending() => 1,
      final FeedModifierExplore explore => switch (explore.type) {
          ExploreModifierType.withAnyTopic => 2,
          ExploreModifierType.interests => 3,
          ExploreModifierType.any => 4,
        },
      FeedModifierTokenizedCommunity() => 5,
      null => -1
    };
  }
}
