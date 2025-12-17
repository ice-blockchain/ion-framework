// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/widgets.dart';
import 'package:flutter_svg/svg.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/tokenized_communities/models/entities/community_token_action.f.dart';
import 'package:ion/app/features/tokenized_communities/providers/token_action_first_buy_provider.r.dart';
import 'package:ion/app/utils/date.dart';
import 'package:ion/generated/assets.gen.dart';

class ProfileHODL extends ConsumerWidget {
  const ProfileHODL({
    required this.actionEntity,
    super.key,
  });

  final CommunityTokenActionEntity actionEntity;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final firstBuyAction = ref
        .watch(
          cachedTokenActionFirstBuyProvider(
            masterPubkey: actionEntity.masterPubkey,
            tokenDefinitionReference: actionEntity.data.definitionReference,
          ),
        )
        .valueOrNull;

    if (firstBuyAction == null) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: EdgeInsetsDirectional.only(top: 8.s),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SvgPicture.asset(
            Assets.svg.iconCreatecoinHold,
            width: 14.0.s,
            height: 14.0.s,
          ),
          SizedBox(width: 4.0.s),
          Text(
            context.i18n.hodl_for(
              formatCompactHodlSince(
                firstBuyAction.createdAt.toDateTime,
              ),
            ),
            style: context.theme.appTextThemes.caption2.copyWith(
              color: context.theme.appColors.secondaryBackground,
            ),
          ),
        ],
      ),
    );
  }
}
