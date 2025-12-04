// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/ion_connect/model/event_reference.f.dart';
import 'package:ion/app/features/user/model/profile_mode.dart';
import 'package:ion/app/features/user/pages/components/profile_avatar/profile_avatar.dart';
import 'package:ion/app/features/user/pages/profile_page/components/profile_background.dart';
import 'package:ion/app/features/user/pages/profile_page/components/profile_details/profile_details.dart';
import 'package:ion/app/features/user/pages/profile_page/components/profile_main_action.dart';
import 'package:ion/app/features/user/providers/user_metadata_provider.r.dart';
import 'package:ion/app/hooks/use_avatar_colors.dart';

class ShareProfileToStoryContent extends HookConsumerWidget {
  const ShareProfileToStoryContent({
    required this.eventReference,
    super.key,
  });

  final EventReference eventReference;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pubkey = eventReference.masterPubkey;
    final userMetadata = ref.watch(userPreviewDataProvider(pubkey)).valueOrNull;
    final avatarUrl = userMetadata?.data.avatarUrl;
    final avatarColors = useAvatarColors(avatarUrl);

    if (userMetadata == null) {
      return const SizedBox.shrink();
    }

    return Stack(
      children: [
        Positioned.fill(
          child: ProfileBackground(
            colors: avatarColors,
          ),
        ),
        Positioned.fill(
          child: Material(
            color: Colors.transparent,
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      ProfileAvatar(
                        profileMode: ProfileMode.dark,
                        pubkey: pubkey,
                        size: 110.0.s,
                      ),
                      PositionedDirectional(
                        bottom: -6,
                        end: -6,
                        child: ProfileMainAction(
                          pubkey: pubkey,
                          profileMode: ProfileMode.dark,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 20.0.s),
                  ProfileDetails(
                    pubkey: pubkey,
                    profileMode: ProfileMode.dark,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
