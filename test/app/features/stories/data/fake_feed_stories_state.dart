// SPDX-License-Identifier: ice License 1.0

import 'package:ion/app/features/feed/data/models/entities/modifiable_post_data.f.dart';
import 'package:ion/app/features/feed/stories/providers/feed_stories_provider.r.dart';

class FakeFeedStories extends FeedStories {
  FakeFeedStories(this._stories);

  final Iterable<ModifiablePostEntity> _stories;

  @override
  ({Iterable<ModifiablePostEntity> items, bool hasMore}) build() {
    return (items: _stories, hasMore: false);
  }
}
