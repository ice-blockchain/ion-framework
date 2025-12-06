// SPDX-License-Identifier: ice License 1.0

import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/components/avatar/avatar.dart';
import 'package:ion/app/components/avatar/outlined_avatar.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/components/ion_connect_avatar/ion_connect_avatar.dart';
import 'package:ion/app/features/feed/stories/providers/feed_stories_provider.r.dart';
import 'package:ion/app/features/feed/stories/providers/viewed_stories_provider.r.dart';
import 'package:ion/app/features/feed/views/pages/feed_page/components/stories/components/story_colored_border.dart';
import 'package:ion/app/features/feed/views/pages/feed_page/components/stories/mock.dart';
import 'package:ion/app/features/user/model/profile_mode.dart';
import 'package:ion/app/router/app_routes.gr.dart';

final _storyStatusProvider =
    Provider.family<({bool hasStories, bool allStoriesViewed}), String>((ref, pubkey) {
  final userStories = ref.watch(feedStoriesByPubkeyProvider(pubkey, showOnlySelectedUser: true));
  final allStoriesViewed = ref.watch(
    viewedStoriesProvider.select((viewedStories) {
      final storyReferences = userStories.map((story) => story.toEventReference());
      return viewedStories?.containsAll(storyReferences) ?? false;
    }),
  );

  final hasStories = userStories.isNotEmpty;

  return (hasStories: hasStories, allStoriesViewed: allStoriesViewed);
});

class StoryColoredProfileAvatar extends HookConsumerWidget {
  const StoryColoredProfileAvatar({
    required this.pubkey,
    required this.size,
    this.borderRadius,
    this.fit,
    this.imageUrl,
    this.imageWidget,
    this.defaultAvatar,
    this.useRandomGradient = false,
    this.profileMode = ProfileMode.light,
    super.key,
  });

  final String pubkey;
  final double size;
  final BorderRadiusGeometry? borderRadius;
  final BoxFit? fit;
  final String? imageUrl;
  final Widget? imageWidget;
  final Widget? defaultAvatar;
  final bool useRandomGradient;
  final ProfileMode profileMode;

  static double get _storyBorderSize => 2.0.s;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final storyStatus = ref.watch(_storyStatusProvider(pubkey));
    final hasStories = storyStatus.hasStories;
    final allStoriesViewed = storyStatus.allStoriesViewed;
    final isDarkMode = profileMode == ProfileMode.dark;

    final shouldShowGradientBorder = isDarkMode || hasStories;

    final gradient = useMemoized(
      () {
        if (!shouldShowGradientBorder) {
          return null;
        }

        // For Dark mode outline use 4th gradient (teal/blue)
        if (isDarkMode) {
          return storyBorderGradients[3];
        }

        return useRandomGradient
            ? storyBorderGradients[Random().nextInt(storyBorderGradients.length)]
            : storyBorderGradients.first;
      },
      [shouldShowGradientBorder, isDarkMode, useRandomGradient],
    );

    Widget avatarWidget;
    if (!shouldShowGradientBorder) {
      if (imageUrl != null || imageWidget != null || defaultAvatar != null) {
        avatarWidget = Avatar(
          size: size,
          imageUrl: imageUrl,
          imageWidget: imageWidget,
          defaultAvatar: defaultAvatar,
          borderRadius: borderRadius,
          fit: fit,
        );
      } else {
        avatarWidget = IonConnectAvatar(
          size: size,
          fit: fit,
          masterPubkey: pubkey,
          borderRadius: borderRadius,
        );
      }
    } else if (isDarkMode) {
      avatarWidget = OutlinedAvatar(
        pubkey: pubkey,
        size: size,
        borderRadius: borderRadius,
        gradient: gradient!,
        imageUrl: imageUrl,
        imageWidget: imageWidget,
        defaultAvatar: defaultAvatar,
        fit: fit,
      );
    } else {
      avatarWidget = StoryColoredBorder(
        size: size,
        color: context.theme.appColors.strokeElements,
        gradient: gradient,
        isViewed: allStoriesViewed,
        child: StoryColoredBorder(
          size: size - _storyBorderSize * 2,
          color: context.theme.appColors.secondaryBackground,
          child: imageUrl != null || imageWidget != null || defaultAvatar != null
              ? Avatar(
                  size: size - _storyBorderSize * 4,
                  imageUrl: imageUrl,
                  imageWidget: imageWidget,
                  defaultAvatar: defaultAvatar,
                  borderRadius: borderRadius,
                  fit: fit,
                )
              : IonConnectAvatar(
                  size: size - _storyBorderSize * 4,
                  fit: fit,
                  masterPubkey: pubkey,
                  borderRadius: borderRadius,
                ),
        ),
      );
    }

    if (hasStories) {
      return GestureDetector(
        onTap: () =>
            StoryViewerRoute(pubkey: pubkey, showOnlySelectedUser: true).push<void>(context),
        child: avatarWidget,
      );
    }

    return avatarWidget;
  }
}
