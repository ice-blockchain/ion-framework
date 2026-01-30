// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/features/tokenized_communities/providers/token_market_info_provider.r.dart';
import 'package:ion/app/utils/username.dart';
import 'package:ion_token_analytics/ion_token_analytics.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'chart_title_provider.r.g.dart';

// For profile/creator tokens: Returns ticker with @ prefix (e.g. "@ticker")
// For Twitter & contenttokens: Returns ticker with $ prefix

@riverpod
Future<String?> chartTitle(
  Ref ref, {
  required String externalAddress,
  required TextDirection textDirection,
}) async {
  final tokenInfo = await ref.watch(tokenMarketInfoProvider(externalAddress).future);
  if (tokenInfo == null) {
    return null;
  }

  final ticker = tokenInfo.marketData.ticker ?? '';

  if (tokenInfo.source.isTwitter) {
    return withPrefix(
      input: ticker,
      prefix: r'$',
      textDirection: textDirection,
    );
  }

  if (tokenInfo.type == CommunityTokenType.profile) {
    return withPrefix(input: ticker, textDirection: textDirection);
  }

  // Content token with $ prefix
  return withPrefix(
    input: ticker,
    prefix: r'$',
    textDirection: textDirection,
  );
}
