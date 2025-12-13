// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/components/list_item/list_item.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/components/ion_connect_avatar/ion_connect_avatar.dart';
import 'package:ion/app/features/user/pages/creator_tokens/views/creator_tokens_page/components/list/token_type_gradients.dart';
import 'package:ion_token_analytics/ion_token_analytics.dart';

class AvatarWithIndicator extends ConsumerWidget {
  const AvatarWithIndicator({
    required this.masterPubkey,
    required this.tokenType,
    super.key,
  });

  final String masterPubkey;
  final CommunityTokenType tokenType;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        IonConnectAvatar(
          size: ListItem.defaultAvatarSize,
          masterPubkey: masterPubkey,
        ),
        if (tokenType != CommunityTokenType.profile)
          PositionedDirectional(
            end: -5.0.s,
            bottom: -1.0.s,
            child: _GradientIndicator(tokenType: tokenType),
          ),
      ],
    );
  }
}

class _GradientIndicator extends StatelessWidget {
  const _GradientIndicator({
    required this.tokenType,
  });

  final CommunityTokenType tokenType;

  @override
  Widget build(BuildContext context) {
    final gradient = TokenTypeGradients.getGradientForType(tokenType);
    if (gradient == null) return const SizedBox.shrink();

    return Container(
      width: 12.0.s,
      height: 12.0.s,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: gradient,
      ),
    );
  }
}
