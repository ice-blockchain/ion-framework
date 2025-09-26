// SPDX-License-Identifier: ice License 1.0

import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/features/core/model/media_type.dart';
import 'package:ion/app/features/feed/data/models/entities/modifiable_post_data.f.dart';
import 'package:ion/app/features/feed/data/models/feed_modifier.dart';
import 'package:ion/app/features/feed/data/models/feed_type.dart';
import 'package:ion/app/features/feed/providers/feed_for_you_content_provider.m.dart';
import 'package:ion/app/features/feed/stories/providers/current_user_feed_story_provider.r.dart';
import 'package:ion/app/features/feed/stories/providers/feed_stories_provider.r.dart';
import 'package:ion/app/features/feed/stories/providers/stories_count_provider.r.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../fixtures/posts/post_fixtures.dart';
import '../../../../fixtures/stories/story_fixtures.dart';
import '../../../../test_utils.dart';
import '../data/fake_feed_stories_state.dart';

class _FakeFeedForYouContent extends FeedForYouContent {
  _FakeFeedForYouContent(this._state);
  final FeedForYouContentState _state;

  @override
  FeedForYouContentState build(
    FeedType feedType, {
    FeedModifier? feedModifier,
    bool showSeen = true,
  }) =>
      _state;
}

class _FakeCurrentUserStory extends CurrentUserFeedStory {
  _FakeCurrentUserStory(this._story);
  final ModifiablePostEntity? _story;

  @override
  ModifiablePostEntity? build() => _story;
}

ModifiablePostEntity _post({
  required String id,
  required String author,
  required MediaType mediaType,
  required DateTime createdAt,
  DateTime? expiration,
}) {
  final post = buildPost(id, author: author, mediaType: mediaType, expiration: expiration);
  when(() => post.createdAt).thenReturn(createdAt.microsecondsSinceEpoch);
  return post;
}

FeedForYouContentState _stateWith(List<ModifiablePostEntity> posts) => FeedForYouContentState(
      items: posts.toSet(),
      modifiersPagination: {},
      forYouRetryLimitReached: false,
      hasMoreFollowing: false,
      isLoading: false,
    );

ProviderContainer _containerWith(List<ModifiablePostEntity> posts) {
  return createContainer(
    overrides: [
      feedForYouContentProvider(FeedType.story).overrideWith(
        () => _FakeFeedForYouContent(_stateWith(posts)),
      ),
      currentUserFeedStoryProvider.overrideWith(
        () => _FakeCurrentUserStory(null),
      ),
      for (final post in posts) storiesCountProvider(post.masterPubkey).overrideWith((_) => 1),
    ],
  );
}

void main() {
  group('storiesProvider – transformation logic', () {
    test('returns N stories for N distinct authors', () async {
      final posts = [
        _post(
          id: 'p1',
          author: 'alice',
          mediaType: MediaType.image,
          createdAt: DateTime(2024),
          expiration: DateTime(2025),
        ),
        _post(
          id: 'p2',
          author: 'bob',
          mediaType: MediaType.video,
          createdAt: DateTime(2024),
          expiration: DateTime(2025),
        ),
        _post(
          id: 'p3',
          author: 'carol',
          mediaType: MediaType.image,
          createdAt: DateTime(2024),
          expiration: DateTime(2025),
        ),
      ];

      final container = _containerWith(posts);
      final result = container.read(feedStoriesProvider);

      expect(result.items.length, 3);
      expect(result.items.map((u) => u.masterPubkey).toSet(), equals({'alice', 'bob', 'carol'}));
    });

    test('filters stories that were soft-deleted', () {
      final deletedStory = _post(
        id: 'deleted',
        author: 'alice',
        mediaType: MediaType.image,
        createdAt: DateTime(2024),
        expiration: DateTime(2025),
      );
      when(() => deletedStory.isDeleted).thenReturn(true);

      final activeStory = _post(
        id: 'active',
        author: 'bob',
        mediaType: MediaType.image,
        createdAt: DateTime(2024),
        expiration: DateTime(2025),
      );
      when(() => activeStory.isDeleted).thenReturn(false);

      final container = createContainer(
        overrides: [
          feedForYouContentProvider(FeedType.story).overrideWith(
            () => _FakeFeedForYouContent(_stateWith([deletedStory, activeStory])),
          ),
          currentUserFeedStoryProvider.overrideWith(
            () => _FakeCurrentUserStory(deletedStory),
          ),
        ],
      );

      final result = container.read(feedStoriesProvider);

      expect(result.items.length, 1);
      expect(result.items.map((story) => story.id).toSet(), equals({'active'}));
    });
  });

  group('filteredStoriesByPubkeyProvider', () {
    const alice = 'alice_pub';
    const bob = 'bob_pub';
    const carol = 'carol_pub';

    final dummyStories = [
      StoryFixtures.userStory(pubkey: alice),
      StoryFixtures.userStory(pubkey: bob),
      StoryFixtures.userStory(pubkey: carol),
    ];

    test('returns a list starting with the selected user', () {
      final container = createContainer(
        overrides: [
          feedStoriesProvider.overrideWith(() => FakeFeedStories(dummyStories)),
        ],
      );

      final result = container.read(feedStoriesByPubkeyProvider(bob));

      expect(result.first.masterPubkey, equals(bob));
      expect(result.length, equals(2));
    });

    test('returns an empty list if pubkey is not found', () {
      final container = createContainer(
        overrides: [
          feedStoriesProvider.overrideWith(() => FakeFeedStories(dummyStories)),
        ],
      );

      final result = container.read(feedStoriesByPubkeyProvider('unknown_pubkey'));

      expect(result, isEmpty);
    });
  });
}
