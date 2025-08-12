// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/widgets.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/components/icons/network_icon_widget.dart';
import 'package:ion/app/components/icons/wallet_item_icon_type.dart';
import 'package:ion/app/components/list_item/list_item.dart';
import 'package:ion/app/components/list_items_loading_state/list_items_loading_state.dart';
import 'package:ion/app/components/screen_offset/screen_side_offset.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/wallets/model/network_data.f.dart';
import 'package:ion/app/router/components/navigation_app_bar/navigation_app_bar.dart';
import 'package:ion/app/router/components/navigation_app_bar/navigation_close_button.dart';
import 'package:ion/app/router/components/sheet_content/sheet_content.dart';

class SelectNetworkListSheet extends StatelessWidget {
  const SelectNetworkListSheet({
    required this.networks,
    required this.onNetworkSelected,
    super.key,
  });

  final AsyncValue<List<NetworkData>> networks;
  final void Function(NetworkData) onNetworkSelected;

  @override
  Widget build(BuildContext context) {
    return SheetContent(
      body: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: EdgeInsets.symmetric(vertical: 8.0.s),
            child: NavigationAppBar.screen(
              title: Text(context.i18n.wallet_choose_network),
              actions: const [
                NavigationCloseButton(),
              ],
            ),
          ),
          Expanded(
            child: ScreenSideOffset.small(
              child: networks.maybeWhen(
                data: (networks) => ListView.separated(
                  itemCount: networks.length,
                  itemBuilder: (context, index) {
                    final network = networks[index];
                    return ListItem(
                      leading: NetworkIconWidget(
                        type: WalletItemIconType.big(),
                        imageUrl: network.image,
                      ),
                      title: Text(network.displayName),
                      backgroundColor: context.theme.appColors.tertiaryBackground,
                      onTap: () => onNetworkSelected(network),
                    );
                  },
                  separatorBuilder: (context, index) => SizedBox(height: 12.0.s),
                ),
                orElse: () => ListItemsLoadingState(
                  listItemsLoadingStateType: ListItemsLoadingStateType.listView,
                  itemHeight: 36.0.s,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
