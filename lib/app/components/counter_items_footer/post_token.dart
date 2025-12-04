// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/ion_connect/model/event_reference.f.dart';
import 'package:ion/app/features/ion_connect/model/ion_connect_entity.dart';
import 'package:ion/app/features/ion_connect/providers/ion_connect_entity_provider.r.dart';
import 'package:ion/app/features/tokenized_communities/extensions/replaceable_entity.dart';
import 'package:ion/app/features/tokenized_communities/providers/token_market_info_provider.r.dart';
import 'package:ion/app/features/tokenized_communities/utils/position_formatters.dart';
import 'package:ion/app/router/app_routes.gr.dart';
import 'package:ion/generated/assets.gen.dart';

class PostToken extends ConsumerWidget {
  const PostToken({
    required this.eventReference,
    this.padding,
    super.key,
  });

  final EventReference eventReference;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entity = ref.watch(ionConnectEntityProvider(eventReference: eventReference)).valueOrNull;

    final externalAddress = entity is ReplaceableEntity ? entity.externalAddress : null;

    final tokenInfo = externalAddress != null
        ? ref.watch(tokenMarketInfoProvider(externalAddress)).valueOrNull
        : null;

    final hasToken = tokenInfo != null;

    return GestureDetector(
      onTap: () {
        hasToken
            ? TokenizedCommunityRoute(externalAddress: externalAddress!).push<void>(context)
            : SwapCoinsRoute().push<void>(context);
      },
      child: hasToken
          ? Container(
              constraints: BoxConstraints(minWidth: 50.0.s),
              padding: padding,
              alignment: AlignmentDirectional.center,
              child: Row(
                children: [
                  Assets.svg.iconMemeMarketcap.icon(
                    size: 16.0.s,
                    color: context.theme.appColors.onTertiaryBackground,
                  ),
                  Padding(
                    padding: EdgeInsetsDirectional.only(start: 4.0.s),
                    child: Text(
                      defaultUsdCompact(tokenInfo.marketData.marketCap),
                      style: context.theme.appTextThemes.caption2.copyWith(
                        color: context.theme.appColors.onTertiaryBackground,
                        height: 1.1,
                      ),
                    ),
                  ),
                ],
              ),
            )
          : Assets.svg.iconMessageMeme.icon(
              size: 16.0.s,
            ),
    );
  }
}
