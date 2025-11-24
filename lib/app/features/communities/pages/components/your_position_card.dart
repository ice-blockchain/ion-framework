import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/communities/providers/token_market_info_provider.r.dart';
import 'package:ion/app/features/user/pages/profile_page/components/profile_background.dart';
import 'package:ion/app/features/user/providers/user_metadata_provider.r.dart';
import 'package:ion/app/hooks/use_avatar_colors.dart';

class YourPositionCard extends HookConsumerWidget {
  const YourPositionCard({required this.masterPubkey, super.key});

  final String masterPubkey;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final position =
        ref.watch(tokenMarketInfoProvider(masterPubkey).select((value) => value.valueOrNull?.marketData.position));

    if (position == null) {
      return const SizedBox();
    }

    final avatarUrl =
        ref.watch(userMetadataProvider(masterPubkey).select((value) => value.valueOrNull?.data.avatarUrl));

    final avatarColors = useAvatarColors(avatarUrl);

    return ClipRRect(
      borderRadius: BorderRadius.circular(12.s),
      child: ProfileBackground(
        colors: avatarColors,
        disableDarkGradient: true,
        child: Padding(
          padding: EdgeInsetsDirectional.fromSTEB(12.s, 12.s, 14.s, 12.s),
          child: Column(
            children: [
              Text(position.amount.toString()),
            ],
          ),
        ),
      ),
    );
  }
}
