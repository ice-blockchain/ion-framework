// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/constants/ui.dart';
import 'package:ion/app/extensions/asset_gen_image.dart';
import 'package:ion/app/extensions/build_context.dart';
import 'package:ion/app/extensions/num.dart';
import 'package:ion/app/extensions/theme_data.dart';
import 'package:ion/app/features/wallets/model/network_data.f.dart';
import 'package:ion/app/features/wallets/views/pages/wallet_page/view_models/nft_networks_view_model.dart';
import 'package:ion/app/router/app_routes.gr.dart';
import 'package:ion/generated/assets.gen.dart';

class NftHeaderSelectAction extends ConsumerWidget {
  const NftHeaderSelectAction({
    super.key,
  });

  String joinSelectedNetworks(
    Set<NetworkData> selectedNftNetworks,
    BuildContext context,
  ) {
    if (selectedNftNetworks.isEmpty) {
      return context.i18n.core_all;
    }

    return selectedNftNetworks.map((e) => e.displayName).join(', ');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.theme.appColors;

    final viewModel = ref.watch(nftNetworksViewModelProvider);

    return ValueListenableBuilder(
      valueListenable: viewModel.selectedNetworks,
      builder: (context, selectedNftNetworks, _) {
        return TextButton(
          onPressed: () {
            ManageNftsRoute().go(context);
          },
          child: Padding(
            padding: EdgeInsets.all(UiConstants.hitSlop),
            child: Row(
              children: [
                Flexible(
                  child: Text(
                    '${context.i18n.core_networks}: ${joinSelectedNetworks(selectedNftNetworks, context)}',
                    style:
                        context.theme.appTextThemes.caption.copyWith(color: colors.secondaryText),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                SizedBox(
                  width: 5.0.s,
                ),
                Assets.svg.iconArrowDown.icon(size: 20.0.s, color: colors.secondaryText),
              ],
            ),
          ),
        );
      },
    );
  }
}
