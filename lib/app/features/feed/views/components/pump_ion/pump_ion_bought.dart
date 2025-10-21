import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:gradient_borders/box_borders/gradient_box_border.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/components/avatar/avatar.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/feed/views/pages/feed_page/components/stories/mock.dart';
import 'package:ion/app/features/user/model/profile_mode.dart';
import 'package:ion/app/features/user/pages/profile_page/components/profile_background.dart';
import 'package:ion/app/features/user/pages/profile_page/components/profile_details/user_name_tile/user_name_tile.dart';
import 'package:ion/app/features/user/providers/user_metadata_provider.r.dart';
import 'package:ion/app/hooks/use_avatar_colors.dart';

class PumpIonBought extends HookConsumerWidget {
  const PumpIonBought({
    required this.masterPubkey,
    super.key,
  });

  final String masterPubkey;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userMetadata = ref.watch(userMetadataProvider(masterPubkey));
    final avatarUrl = userMetadata.valueOrNull?.data.avatarUrl;

    final avatarColors = useAvatarColors(avatarUrl);

    final gradient = useMemoized(
      () {
        return storyBorderGradients[Random().nextInt(storyBorderGradients.length)];
      },
      [avatarUrl],
    );

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.0.s),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12.0.s),
        child: ProfileBackground(
          color1: avatarColors.$1,
          color2: avatarColors.$2,
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 24.0.s, horizontal: 16.0.s),
            child: Row(
              children: [
                Container(
                  width: 65.0.s,
                  height: 65.0.s,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24.0.s),
                    border: GradientBoxBorder(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: gradient.colors,
                        stops: gradient.stops,
                      ),
                      width: 1.5.s,
                    ),
                  ),
                  child: Center(
                    child: Avatar(
                      size: 54.s,
                      imageUrl: avatarUrl,
                      borderRadius: BorderRadius.circular(18.0.s),
                    ),
                  ),
                ),
                SizedBox(width: 12.0.s),
                Expanded(
                  child: UserNameTile(
                    pubkey: masterPubkey,
                    profileMode: ProfileMode.dark,
                    textAlign: TextAlign.left,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
