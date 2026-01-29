// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/components/skeleton/container_skeleton.dart';
import 'package:ion/app/extensions/build_context.dart';
import 'package:ion/app/extensions/num.dart';
import 'package:ion/app/extensions/theme_data.dart';
import 'package:ion/app/features/components/ion_connect_avatar/ion_connect_avatar.dart';
import 'package:ion/app/features/user/providers/user_metadata_provider.r.dart';
import 'package:ion/app/utils/username.dart';

class FriendsListItem extends ConsumerWidget {
  const FriendsListItem({
    required this.pubkey,
    required this.onTap,
    super.key,
  });

  final String pubkey;
  final VoidCallback onTap;

  static double get width => 70.0.s;

  static double get imageWidth => 60.0.s;

  static double get height => 84.0.s;

  static double get iceLogoSize => 20.0.s;

  static double get iceLogoBorderRadius => 8.0.s;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userPreviewState = ref.watch(userPreviewDataProvider(pubkey));

    return userPreviewState.maybeWhen(
      orElse: () {
        final size = 54.0.s;
        return ContainerSkeleton(
          width: size,
          height: size,
          margin: EdgeInsets.symmetric(
            vertical: (FriendsListItem.height - size) / 2,
            horizontal: (FriendsListItem.width - size) / 2,
          ),
        );
      },
      data: (userPreviewData) {
        if (userPreviewData == null) {
          return const SizedBox.shrink();
        }

        return Padding(
          padding: EdgeInsetsDirectional.only(start: 12.0.s),
          child: GestureDetector(
            onTap: onTap,
            child: SizedBox(
              width: width,
              height: height,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IonConnectAvatar(
                    size: imageWidth,
                    masterPubkey: pubkey,
                    borderRadius: BorderRadius.circular(14.0.s),
                  ),
                  Text(
                    withPrefix(
                      input: userPreviewData.data.name,
                      textDirection: Directionality.of(context),
                    ),
                    style: context.theme.appTextThemes.caption.copyWith(
                      color: context.theme.appColors.secondaryText,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
