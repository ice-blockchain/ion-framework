// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/components/progress_bar/ion_loading_indicator.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/feed/stories/providers/story_image_loading_provider.r.dart';
import 'package:ion/app/features/feed/stories/views/components/story_viewer/components/header/story_header_gradient.dart';
import 'package:ion/app/hooks/use_on_init.dart';
import 'package:ion/generated/assets.gen.dart';
import 'package:ion_ads/ion_ads.dart';

class AdStoryViewer extends HookConsumerWidget {
  const AdStoryViewer({required this.storyId, super.key});

  final String storyId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    useOnInit(() {
      if (context.mounted) {
        ref.read(storyImageLoadStatusProvider(storyId).notifier).markLoaded();
      }
    });

    ref.watch(storyImageLoadStatusProvider(storyId));
    final iconMoreColor = context.theme.appColors.onPrimaryAccent;

    return SizedBox.expand(
      child: Stack(
        children: [
          const Center(
            child: IONLoadingIndicator(),
          ),
          IgnorePointer(
            child: AppodealNativeAd(
              options: NativeAdOptions.appWallOptions(
                adChoiceConfig: AdChoiceConfig(position: AdChoicePosition.startTop),
              ),
            ),
          ),
          const StoryHeaderGradient(),
          PositionedDirectional(
            top: 21.0.s,
            end: 28.0.s,
            child: GestureDetector(
              onTap: context.pop,
              child: Assets.svg.iconSheetClose.icon(color: iconMoreColor),
            ),
          ),
        ],
      ),
    );
  }
}
