import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
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
    final primaryTextWithAlpha = context.theme.appColors.primaryText.withValues(alpha: 0.25);
    final shadow = [
      Shadow(
        offset: Offset(
          0.0.s,
          0.3.s,
        ),
        blurRadius: 1,
        color: primaryTextWithAlpha,
      ),
    ];

    return SizedBox.expand(
      child: Stack(
        children: [
          AppodealNativeAd(
            options: NativeAdOptions.appWallOptions(),
          ),
          const StoryHeaderGradient(),
          PositionedDirectional(
            top: 8.0.s,
            end: 16.0.s,
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
