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
import 'package:ion/generated/assets.gen.dart';

enum UserNotificationsType {
  none,
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
      UserNotificationsType.stories => Assets.svg.iconFeedStories,
      UserNotificationsType.posts => Assets.svg.iconFeedPost,
      UserNotificationsType.videos => Assets.svg.iconFeedVideos,
      UserNotificationsType.articles => Assets.svg.iconFeedArticles,
    };
  }

  String getTitle(BuildContext context) {
    switch (this) {
      case UserNotificationsType.none:
        return context.i18n.profile_none;
      case UserNotificationsType.stories:
        return context.i18n.profile_stories;
      case UserNotificationsType.posts:
        return context.i18n.profile_posts;
      case UserNotificationsType.videos:
        return context.i18n.profile_videos;
      case UserNotificationsType.articles:
        return context.i18n.profile_articles;
    }
  }

  RequestFilter toRequestFilter({required List<String> authors, int? limit}) {
    return switch (this) {
      UserNotificationsType.videos => RequestFilter(
          kinds: const [
            PostEntity.kind,
            ModifiablePostEntity.kind,
          ],
          search: VideosSearchExtension(contain: true).query,
          authors: authors,
          limit: limit,
        ),
      UserNotificationsType.stories => RequestFilter(
          kinds: const [
            PostEntity.kind,
            ModifiablePostEntity.kind,
          ],
          search: ExpirationSearchExtension(expiration: true).query,
          authors: authors,
          limit: limit,
        ),
      UserNotificationsType.articles => RequestFilter(
          kinds: const [
            ArticleEntity.kind,
          ],
          authors: authors,
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
          authors: authors,
          limit: limit,
        ),
      UserNotificationsType.none => throw ArgumentError('Cannot build filter for none type'),
    };
  }

  static Set<UserNotificationsType> toggleNotificationType(
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
