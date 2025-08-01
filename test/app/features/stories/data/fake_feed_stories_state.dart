// SPDX-License-Identifier: ice License 1.0

import 'package:ion/app/features/feed/stories/data/models/user_story.f.dart';
import 'package:ion/app/features/feed/stories/providers/feed_stories_provider.r.dart';

class FakeFeedStories extends FeedStories {
  FakeFeedStories(this._stories);

  final Iterable<UserStory> _stories;

  @override
  ({Iterable<UserStory>? items, bool hasMore}) build() {
    return (items: _stories, hasMore: false);
  }
}
