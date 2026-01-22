// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/tokenized_communities/providers/suggested_token_icon_availability_provider.r.dart';
import 'package:ion/app/features/wallets/model/network_data.f.dart';
import 'package:ion/app/features/wallets/views/components/coin_icon_with_network.dart';
import 'package:ion/generated/assets.gen.dart';

class SuggestedCommunityAvatar extends HookConsumerWidget {
  const SuggestedCommunityAvatar({
    required this.pictureUrl,
    required this.network,
    super.key,
  });

  final String pictureUrl;
  final NetworkData? network;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final availability = ref.watch(suggestedTokenIconAvailabilityProvider(pictureUrl));
    final isAvailable = availability.valueOrNull ?? false;
    final targetNetwork = network;
    if (targetNetwork == null) {
      return const _SuggestedTokenIconPlaceholder();
    }
    return CoinIconWithNetwork.small(
      isAvailable ? pictureUrl : '',
      network: targetNetwork,
      showPlaceholder: true,
      placeholder: const _SuggestedTokenIconPlaceholder(),
    );
  }
}

class _SuggestedTokenIconPlaceholder extends StatelessWidget {
  const _SuggestedTokenIconPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Assets.svg.iconEmptyiconswap.icon(
      size: 36.0.s,
    );
  }
}
