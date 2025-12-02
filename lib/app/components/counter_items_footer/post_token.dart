// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/communities/providers/token_market_info_provider.r.dart';
import 'package:ion/app/features/communities/utils/position_formatters.dart';
import 'package:ion/app/features/ion_connect/model/event_reference.f.dart';
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
    final tokenInfo = ref.watch(tokenMarketInfoProvider(eventReference.masterPubkey));
    final hasToken = tokenInfo.valueOrNull != null;

    return hasToken
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
                    defaultUsdCompact(tokenInfo.valueOrNull!.marketData.marketCap),
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
          );
  }
}
