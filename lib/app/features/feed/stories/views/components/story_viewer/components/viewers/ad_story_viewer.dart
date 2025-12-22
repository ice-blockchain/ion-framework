import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/features/feed/stories/providers/story_image_loading_provider.r.dart';
import 'package:ion/app/hooks/use_on_init.dart';
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

    return SizedBox.expand(
      child: AppodealNativeAd(
        options: NativeAdOptions.appWallOptions(),
      ),
    );
  }
}
