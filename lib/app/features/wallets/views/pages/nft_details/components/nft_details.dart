// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/components/avatar/avatar.dart';
import 'package:ion/app/components/button/button.dart';
import 'package:ion/app/components/card/rounded_card.dart';
import 'package:ion/app/components/icons/network_icon_widget.dart';
import 'package:ion/app/components/icons/wallet_item_icon_type.dart';
import 'package:ion/app/components/list_item/list_item.dart';
import 'package:ion/app/components/read_more_text/read_more_text.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/wallets/model/nft_identifier.f.dart';
import 'package:ion/app/features/wallets/providers/send_nft_form_provider.r.dart';
import 'package:ion/app/features/wallets/providers/send_nft_notifier_provider.r.dart';
import 'package:ion/app/features/wallets/views/components/nft_name.dart';
import 'package:ion/app/features/wallets/views/components/nft_picture.dart';
import 'package:ion/app/features/wallets/views/pages/nft_details/components/nft_details_loading.dart';
import 'package:ion/app/features/wallets/views/pages/nft_details/providers/nft_details_provider.r.dart';
import 'package:ion/app/router/app_routes.gr.dart';
import 'package:ion/generated/assets.gen.dart';

class NftDetails extends HookConsumerWidget {
  const NftDetails({
    required this.nftIdentifier,
    super.key,
  });

  final NftIdentifier nftIdentifier;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nftData = ref.watch(nftDetailsProvider(nftIdentifier)).value;

    if (nftData == null) {
      return const NftDetailsLoading();
    }

    final isConfirmEnabled = useState(false);

    useEffect(
      () {
        ref.watch(sendNftNotifierProvider.notifier).isSendable(nftData).then((result) {
          isConfirmEnabled.value = result;
        });
        return null;
      },
      [],
    );

    final overlayEntry = useRef<OverlayEntry?>(null);
    final buttonKey = useRef(GlobalKey());
    final animationController = useAnimationController(
      duration: const Duration(milliseconds: 300),
    );
    final opacityAnimation = useRef(
      Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(parent: animationController, curve: Curves.easeInOut),
      ),
    );

    void showOverlay() {
      if (overlayEntry.value != null) {
        return;
      }

      final renderBox = buttonKey.value.currentContext!.findRenderObject()! as RenderBox;
      final offset = renderBox.localToGlobal(Offset.zero);
      final size = renderBox.size;
      final overlayHeight = 40.s;
      final topPosition = offset.dy - size.height - overlayHeight;

      overlayEntry.value = OverlayEntry(
        builder: (context) {
          return PositionedDirectional(
            width: MediaQuery.sizeOf(context).width,
            top: topPosition,
            height: overlayHeight,
            child: AnimatedBuilder(
              animation: opacityAnimation.value,
              builder: (context, child) {
                return Opacity(
                  opacity: opacityAnimation.value.value,
                  child: Material(
                    color: Colors.transparent,
                    child: Center(
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 32.s, vertical: 12.s),
                        decoration: BoxDecoration(
                          color: context.theme.appColors.onPrimaryAccent,
                          borderRadius: BorderRadius.circular(16.s),
                          border: Border.all(
                            color: context.theme.appColors.onPrimaryAccent,
                            width: 1.s,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.10),
                              blurRadius: 8.s,
                              offset: Offset(0, 4.s),
                            ),
                          ],
                        ),
                        child: Text(
                          context.i18n.send_nft_sending_nft_will_be_available_later,
                          style: context.theme.appTextThemes.body2,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          );
        },
      );

      Overlay.of(context).insert(overlayEntry.value!);
      animationController.forward();

      // Auto remove after 3s
      Future.delayed(const Duration(seconds: 3), () async {
        await animationController.reverse();
        overlayEntry.value?.remove();
        overlayEntry.value = null;
      });
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        NftPicture(
          imageUrl: nftData.imageUrl,
          size: Size(180.0.s, 170.0.s),
        ),
        SizedBox(height: 15.0.s),
        NftName(
          rank: nftData.tokenId,
          name: nftData.name,
        ),
        SizedBox(height: 12.0.s),
        RoundedCard.filled(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                context.i18n.common_desc,
                style: context.theme.appTextThemes.caption3.copyWith(
                  color: context.theme.appColors.tertiaryText,
                ),
              ),
              SizedBox(height: 4.0.s),
              ReadMoreText(nftData.description),
            ],
          ),
        ),
        SizedBox(height: 12.0.s),
        ListItem.textWithIcon(
          title: Text(context.i18n.send_nft_token_network),
          value: nftData.network.displayName,
          icon: Avatar(
            size: 12.0.s,
            imageWidget: NetworkIconWidget(
              type: WalletItemIconType.tiny(),
              imageUrl: nftData.network.image,
            ),
          ),
        ),
        SizedBox(height: 12.0.s),
        ListItem.text(
          title: Text(context.i18n.send_nft_token_standard),
          value: nftData.kind,
        ),
        SizedBox(height: 12.0.s),
        ListItem.text(
          title: Text(
            context.i18n.send_nft_token_contract_address,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          value: nftData.contract,
        ),
        SizedBox(height: 12.0.s),
        GestureDetector(
          key: buttonKey.value,
          onTap: () {
            if (!isConfirmEnabled.value) {
              showOverlay();
            }
          },
          behavior: HitTestBehavior.translucent,
          child: Button(
            type: isConfirmEnabled.value ? ButtonType.primary : ButtonType.disabled,
            mainAxisSize: MainAxisSize.max,
            minimumSize: Size(56.0.s, 56.0.s),
            leadingIcon: Assets.svg.iconButtonSend.icon(
              color: context.theme.appColors.onPrimaryAccent,
            ),
            label: Text(context.i18n.feed_send),
            onPressed: () {
              ref.invalidate(sendNftFormControllerProvider);
              ref.read(sendNftFormControllerProvider.notifier).setNft(nftData);
              NftSendFormRoute().push<void>(context);
            },
          ),
        ),
      ],
    );
  }
}
