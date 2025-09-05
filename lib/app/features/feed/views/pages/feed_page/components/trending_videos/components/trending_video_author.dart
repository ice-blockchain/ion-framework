// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/extensions/build_context.dart';
import 'package:ion/app/extensions/num.dart';
import 'package:ion/app/extensions/theme_data.dart';
import 'package:ion/app/features/components/ion_connect_avatar/ion_connect_avatar.dart';
import 'package:ion/app/features/user/providers/user_metadata_provider.r.dart';
import 'package:ion/app/router/app_routes.gr.dart';

class TrendingVideoAuthor extends ConsumerWidget {
  const TrendingVideoAuthor({
    required this.pubkey,
    super.key,
  });

  final String pubkey;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userMetadata = ref.watch(userMetadataSyncProvider(pubkey));

    if (userMetadata == null) {
      return const SizedBox.shrink();
    }

    return TextButton(
      onPressed: () {
        ProfileRoute(pubkey: pubkey).push<void>(context);
      },
      child: Padding(
        padding: EdgeInsets.all(12.0.s),
        child: Row(
          children: [
            IonConnectAvatar(
              size: 20.0.s,
              pubkey: pubkey,
            ),
            Flexible(
              child: Padding(
                padding: EdgeInsetsDirectional.only(start: 4.0.s),
                child: Text(
                  userMetadata.data.displayName,
                  overflow: TextOverflow.ellipsis,
                  style: context.theme.appTextThemes.caption3.copyWith(
                    color: context.theme.appColors.secondaryBackground,
                    shadows: [
                      BoxShadow(
                        offset: const Offset(0, 1),
                        blurRadius: 1,
                        color: Colors.black.withValues(alpha: 0.40),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
