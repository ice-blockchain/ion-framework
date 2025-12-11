// SPDX-License-Identifier: ice License 1.0

import 'package:ion/app/features/feed/data/models/feed_interests.f.dart';
import 'package:ion/app/features/ion_connect/model/related_hashtag.f.dart';
import 'package:ion/app/features/ion_connect/model/search_extension.dart';
import 'package:ion/app/features/tokenized_communities/models/entities/constants.dart';
import 'package:meta/meta.dart';

typedef FeedFilterData = ({List<SearchExtension> search, Map<String, List<String>> tags});

sealed class FeedModifier {
  const FeedModifier({required this.name});

  factory FeedModifier.top() = FeedModifierTop;
  factory FeedModifier.trending() = FeedModifierTrending;
  factory FeedModifier.explore(ExploreModifierType type) = FeedModifierExplore;
  factory FeedModifier.tokenizedCommunity() = FeedModifierTokenizedCommunity;

  final String name;

  FeedFilterData filter({String? interest});
}

@immutable
class FeedModifierTop extends FeedModifier {
  const FeedModifierTop() : super(name: 'top');

  @override
  FeedFilterData filter({String? interest}) {
    return (
      search: [TopSearchExtension()],
      tags: {
        if (interest != null) '#${RelatedHashtag.tagName}': [interest],
      }
    );
  }

  @override
  bool operator ==(Object other) => identical(this, other) || other is FeedModifierTop;

  @override
  int get hashCode => name.hashCode;
}

@immutable
class FeedModifierTrending extends FeedModifier {
  const FeedModifierTrending() : super(name: 'trending');

  @override
  FeedFilterData filter({String? interest}) {
    return (
      search: [TrendingSearchExtension()],
      tags: {
        if (interest != null) '#${RelatedHashtag.tagName}': [interest],
      }
    );
  }

  @override
  bool operator ==(Object other) => identical(this, other) || other is FeedModifierTrending;

  @override
  int get hashCode => name.hashCode;
}

@immutable
class FeedModifierExplore extends FeedModifier {
  FeedModifierExplore(this.type) : super(name: 'explore-${type.name}');

  final ExploreModifierType type;

  @override
  FeedFilterData filter({String? interest}) {
    return (
      search: [],
      tags: switch (type) {
        /// Fetch events with any topic specified.
        ///
        /// When a content is created and user does not select any topics,
        /// we add the `unclassified` tag.
        ExploreModifierType.withAnyTopic => {
            '#!${RelatedHashtag.tagName}': [FeedInterests.unclassified],
          },

        /// Fetch events for the provided tag.
        ExploreModifierType.interests => {
            if (interest != null) '#${RelatedHashtag.tagName}': [interest],
          },

        /// Fetch all events, with or without tags.
        ExploreModifierType.any => {},
      }
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is FeedModifierExplore && type == other.type;

  @override
  int get hashCode => type.hashCode;
}

enum ExploreModifierType { withAnyTopic, interests, any }

@immutable
class FeedModifierTokenizedCommunity extends FeedModifier {
  const FeedModifierTokenizedCommunity() : super(name: 'tokenizedCommunity');

  @override
  FeedFilterData filter({String? interest}) {
    return (
      search: [],
      tags: {
        '#${RelatedHashtag.tagName}': [communityTokenActionTopic],
      }
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is FeedModifierTokenizedCommunity;

  @override
  int get hashCode => name.hashCode;
}
