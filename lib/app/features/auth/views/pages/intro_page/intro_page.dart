// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/components/button/button.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/auth/providers/auth_provider.m.dart';
import 'package:ion/app/features/core/model/feature_flags.dart';
import 'package:ion/app/features/core/providers/feature_flags_provider.r.dart';
import 'package:ion/app/features/core/providers/video_player_provider.m.dart';
import 'package:ion/app/hooks/use_auto_play_route_observer.dart';
import 'package:ion/app/router/app_route_observer.dart';
import 'package:ion/app/router/app_routes.gr.dart';
import 'package:ion/generated/assets.gen.dart';
import 'package:video_player/video_player.dart';

class IntroPage extends HookConsumerWidget {
  const IntroPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // We watch the intro page video controller here and ensure we pass the same parameters
    // (looping: true) to get the same instance of the already initialized provider from SplashPage.
    final videoControllerProviderState = ref.watch(
      videoControllerProvider(
        VideoControllerParams(
          sourcePath: Assets.videos.intro,
          looping: true,
        ),
      ),
    );
    useAutoPlayRouteObserver(
      videoControllerProviderState.valueOrNull,
      routeObserver: routeObserver,
    );

    final videoController = videoControllerProviderState.valueOrNull;

    final isMultiAccountsEnabled =
        ref.watch(featureFlagsProvider.notifier).get(MultiAccountsFeatureFlag.multiAccountsEnabled);

    final isSwitchAccountEnabled = ref.watch(
      authProvider
          .select((state) => state.valueOrNull?.authenticatedIdentityKeyNames.isNotEmpty ?? false),
    );

    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          // Fallback white background if the video isn't initialized or an error occurs.
          if (videoController == null ||
              !videoController.value.isInitialized ||
              videoController.value.hasError ||
              videoControllerProviderState.hasError)
            ColoredBox(
              color: Colors.white,
              child: Center(
                child: Assets.svg.logo.logoCircle.icon(size: 148.0.s),
              ),
            )
          else
            Center(
              child: AspectRatio(
                aspectRatio: videoController.value.aspectRatio,
                child: VideoPlayer(videoController),
              ),
            ),
          if (isMultiAccountsEnabled && isSwitchAccountEnabled)
            PositionedDirectional(
              top: MediaQuery.paddingOf(context).top + 16.0.s,
              end: 16.0.s,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => SwitchAccountAuthRoute().go(context),
                child: Container(
                  padding: EdgeInsets.all(8.0.s),
                  child: Assets.svg.iconSwitchProfile.icon(
                    size: 24.0.s,
                  ),
                ),
              ),
            ),
          PositionedDirectional(
            start: 40.0.s,
            end: 40.0.s,
            bottom: MediaQuery.paddingOf(context).bottom + 46.0.s,
            child: Animate(
              effects: [
                ScaleEffect(
                  duration: 500.ms,
                  curve: Curves.easeOutBack,
                  delay: 2.0.seconds,
                ),
              ],
              child: Button(
                onPressed: () => GetStartedRoute().go(context),
                label: Text(context.i18n.button_log_in),
                trailingIcon: Assets.svg.iconButtonNext.icon(
                  color: context.theme.appColors.secondaryBackground,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
