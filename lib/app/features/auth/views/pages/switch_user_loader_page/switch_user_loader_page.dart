// SPDX-License-Identifier: ice License 1.0

// lib/app/features/auth/views/pages/switch_user_loader_page/switch_user_loader_page.dart
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/core/providers/video_player_provider.m.dart';
import 'package:ion/app/hooks/use_auto_play_route_observer.dart';
import 'package:ion/app/router/app_route_observer.dart';
import 'package:ion/generated/assets.gen.dart';
import 'package:video_player/video_player.dart';

class SwitchUserLoaderPage extends HookConsumerWidget {
  const SwitchUserLoaderPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final splashVideoControllerState = ref.watch(
      videoControllerProvider(
        VideoControllerParams(
          sourcePath: Assets.videos.logoStatic,
        ),
      ),
    );

    useAutoPlayRouteObserver(
      splashVideoControllerState.valueOrNull,
      routeObserver: routeObserver,
    );

    final splashVideoController = splashVideoControllerState.valueOrNull;

    return Scaffold(
      backgroundColor: context.theme.appColors.secondaryBackground,
      body: Center(
        child: splashVideoController != null &&
                splashVideoController.value.isInitialized &&
                !splashVideoController.value.hasError
            ? AspectRatio(
                aspectRatio: splashVideoController.value.aspectRatio,
                child: VideoPlayer(splashVideoController),
              )
            : (splashVideoController != null && splashVideoController.value.hasError ||
                    splashVideoControllerState.hasError)
                ? Assets.svg.logo.logoCircle.icon(size: 148.0.s)
                : const SizedBox.shrink(),
      ),
    );
  }
}
