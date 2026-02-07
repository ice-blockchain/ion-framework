// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:ion/app/extensions/build_context.dart';
import 'package:ion/app/features/feed/data/models/entities/article_data.f.dart';
import 'package:ion/app/features/feed/data/models/entities/modifiable_post_data.f.dart';
import 'package:ion/app/features/feed/data/models/entities/post_data.f.dart';
import 'package:ion/app/features/ion_connect/ion_connect.dart';
import 'package:ion/app/features/ion_connect/model/related_event.f.dart';
import 'package:ion/app/features/ion_connect/model/related_event_marker.dart';
import 'package:ion/app/features/ion_connect/model/search_extension.dart';
import 'package:ion/app/features/tokenized_communities/models/entities/community_token_action.f.dart';
import 'package:ion/app/features/tokenized_communities/models/entities/constants.dart';
import 'package:ion/generated/assets.gen.dart';

enum UserNotificationsType {
  none,
  tokenizedCommunitiesTransactions,
  stories,
  posts,
  videos,
  articles;

  factory UserNotificationsType.fromFilter(RequestFilter filter) {
    if (filter.kinds?.contains(ArticleEntity.kind) ?? false) {
      return UserNotificationsType.articles;
    } else if (filter.search?.contains(ExpirationSearchExtension(expiration: true).query) ??
        false) {
      return UserNotificationsType.stories;
    } else if (filter.search?.contains(VideosSearchExtension(contain: true).query) ?? false) {
      return UserNotificationsType.videos;
    } else {
      return UserNotificationsType.posts;
    }
  }

  String get iconAsset {
    return switch (this) {
      UserNotificationsType.none => Assets.svg.iconProfileNotificationMute,
      UserNotificationsType.tokenizedCommunitiesTransactions => Assets.svg.iconWorkPickcoin,
      UserNotificationsType.stories => Assets.svg.iconFeedStories,
      UserNotificationsType.posts => Assets.svg.iconFeedPost,
      UserNotificationsType.videos => Assets.svg.iconFeedVideos,
      UserNotificationsType.articles => Assets.svg.iconFeedArticles,
    };
  }

  String getTitle(BuildContext context) {
    return switch (this) {
      UserNotificationsType.none => context.i18n.profile_none,
      UserNotificationsType.tokenizedCommunitiesTransactions =>
        context.i18n.profile_tokenized_communities,
      UserNotificationsType.stories => context.i18n.profile_stories,
      UserNotificationsType.posts => context.i18n.profile_posts,
      UserNotificationsType.videos => context.i18n.profile_videos,
      UserNotificationsType.articles => context.i18n.profile_articles,
    };
  }

  RequestFilter toRequestFilter({required List<String> masterPubkeys, int? limit}) {
    return switch (this) {
      UserNotificationsType.tokenizedCommunitiesTransactions => RequestFilter(
          kinds: const [
            CommunityTokenActionEntity.kind,
          ],
          tags: {
            '#t': const [communityTokenActionTopic],
            '#p': masterPubkeys,
          },
          limit: limit,
        ),
      UserNotificationsType.videos => RequestFilter(
          kinds: const [
            PostEntity.kind,
            ModifiablePostEntity.kind,
          ],
          search: VideosSearchExtension(contain: true).query,
          authors: masterPubkeys,
          limit: limit,
        ),
      UserNotificationsType.stories => RequestFilter(
          kinds: const [
            PostEntity.kind,
            ModifiablePostEntity.kind,
          ],
          search: ExpirationSearchExtension(expiration: true).query,
          authors: masterPubkeys,
          limit: limit,
        ),
      UserNotificationsType.articles => RequestFilter(
          kinds: const [
            ArticleEntity.kind,
          ],
          authors: masterPubkeys,
          limit: limit,
        ),
      UserNotificationsType.posts => RequestFilter(
          kinds: const [
            PostEntity.kind,
            ModifiablePostEntity.kind,
          ],
          search: SearchExtensions([
            ExpirationSearchExtension(expiration: false),
            VideosSearchExtension(contain: false),
            TagMarkerSearchExtension(
              tagName: RelatedReplaceableEvent.tagName,
              marker: RelatedEventMarker.reply.name,
              negative: true,
            ),
            TagMarkerSearchExtension(
              tagName: RelatedImmutableEvent.tagName,
              marker: RelatedEventMarker.reply.name,
              negative: true,
            ),
          ]).toString(),
          authors: masterPubkeys,
          limit: limit,
        ),
      UserNotificationsType.none => throw ArgumentError('Cannot build filter for none type'),
    };
  }

  Set<UserNotificationsType> toggleNotificationType(
    Set<UserNotificationsType> currentSet,
    UserNotificationsType option,
  ) {
    final newSet = {...currentSet};
    if (option == UserNotificationsType.none) {
      newSet
        ..clear()
        ..add(UserNotificationsType.none);
    } else {
      if (newSet.contains(UserNotificationsType.none)) {
        newSet.remove(UserNotificationsType.none);
      }

      if (!newSet.add(option)) {
        newSet.remove(option);
        if (newSet.isEmpty) {
          newSet.add(UserNotificationsType.none);
        }
      }
    }
    return newSet;
  }
}
