// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/widgets.dart';
import 'package:flutter_svg/svg.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/tokenized_communities/models/entities/community_token_definition.f.dart';
import 'package:ion/app/features/tokenized_communities/providers/token_first_buy_provider.r.dart';
import 'package:ion/app/utils/date.dart';
import 'package:ion/generated/assets.gen.dart';

class ProfileHODL extends ConsumerWidget {
  const ProfileHODL({
    required this.definitionEntity,
    super.key,
  });

  final CommunityTokenDefinitionEntity definitionEntity;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final firstBuy = ref.watch(tokenFirstBuyProvider(definitionEntity)).valueOrNull;

    if (firstBuy == null) {
      return const SizedBox.shrink();
    }
    return Row(
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
            formatCompactHodlSince(firstBuy.createdAt.toDateTime),
          ),
          style: context.theme.appTextThemes.caption2.copyWith(
            color: context.theme.appColors.secondaryBackground,
          ),
        ),
      ],
    );
  }
}
