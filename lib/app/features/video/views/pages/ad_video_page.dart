// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:ion/app/components/progress_bar/centered_loading_indicator.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/feed/stories/views/components/story_viewer/components/progress/story_progress_fill.dart';
import 'package:ion/app/services/ion_ad/ion_ad_provider.r.dart';
import 'package:ion/app/services/media_service/aspect_ratio.dart';

class AdVideoViewer extends StatelessWidget {
  const AdVideoViewer(this.videoId, {super.key});

  final String videoId;

  @override
  Widget build(BuildContext context) {
    final topMargin = (MediaQuery.paddingOf(context).top + kToolbarHeight + 8) /
        MediaQuery.devicePixelRatioOf(context);

    return Column(
      children: [
        Expanded(
          child: AspectRatio(
            aspectRatio: MediaAspectRatio.portrait,
            child: Stack(
              children: [
                CenteredLoadingIndicator(size: Size.square(30.s)),
                AppodealNativeAd(
                  options: NativeAdOptions.appWallOptions(
                    adChoiceConfig: AdChoiceConfig(
                      margin: topMargin,
                    ),
                  ),
                ),
                Column(
                  children: [
                    const Spacer(),
                    _AdVideoProgress(videoId),
                  ],
                ),
              ],
            ),
          ),
        ),
        SizedBox(
          height: MediaQuery.paddingOf(context).bottom + 60,
        ),
      ],
    );
  }
}

class _AdVideoProgress extends HookWidget {
  const _AdVideoProgress(this.videoId);

  final String videoId;

  @override
  Widget build(BuildContext context) {
    final animationController = useAnimationController(
      duration: const Duration(seconds: 5),
      animationBehavior: AnimationBehavior.preserve,
      keys: [videoId],
    );

    useEffect(
      () {
        animationController.forward(from: 0);
        return null;
      },
      [videoId],
    );

    return Container(
      height: 3.0.s,
      width: double.maxFinite,
      clipBehavior: Clip.hardEdge,
      decoration: BoxDecoration(
        color: context.theme.appColors.onPrimaryAccent.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(1.0.s),
      ),
      child: AnimatedBuilder(
        animation: animationController,
        builder: (context, child) {
          final progressValue = animationController.value.clamp(0.0, 1.0);
          return StoryProgressFill(
            isActive: true,
            storyProgress: progressValue,
          );
        },
      ),
    );
  }
}
