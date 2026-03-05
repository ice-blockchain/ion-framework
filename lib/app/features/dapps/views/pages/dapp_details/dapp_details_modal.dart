// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/components/button/button.dart';
import 'package:ion/app/components/read_more_text/read_more_text.dart';
import 'package:ion/app/components/screen_offset/screen_side_offset.dart';
import 'package:ion/app/components/separated/separator.dart';
import 'package:ion/app/extensions/asset_gen_image.dart';
import 'package:ion/app/extensions/build_context.dart';
import 'package:ion/app/extensions/num.dart';
import 'package:ion/app/extensions/theme_data.dart';
import 'package:ion/app/features/dapps/providers/dapps_provider.r.dart';
import 'package:ion/app/features/dapps/views/components/grid_item/grid_item.dart';
import 'package:ion/app/features/dapps/views/pages/dapp_details/components/dapp_details_info_block/dapp_details_info_block.dart';
import 'package:ion/app/features/dapps/views/pages/dapp_details/components/launch_dapp_button/launch_dapp_button.dart';
import 'package:ion/app/router/components/navigation_app_bar/navigation_app_bar.dart';
import 'package:ion/app/router/components/navigation_app_bar/navigation_close_button.dart';
import 'package:ion/app/router/components/sheet_content/sheet_content.dart';
import 'package:ion/app/services/browser/browser.dart';
import 'package:ion/app/utils/num.dart';
import 'package:ion/generated/assets.gen.dart';

class DAppDetailsModal extends HookConsumerWidget {
  const DAppDetailsModal({
    required this.dappId,
    super.key,
  });

  final int dappId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final app = ref.watch(dappByIdProvider(dappId: dappId)).valueOrNull;

    final isVoted = useState(false);

    if (app == null) {
      return const SizedBox.shrink();
    }

    return SheetContent(
      body: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          NavigationAppBar.modal(
            showBackButton: false,
            title: Text(app.title),
            actions: const [NavigationCloseButton()],
          ),
          Flexible(
            child: ScreenSideOffset.small(
              child: SingleChildScrollView(
                restorationId: 'dapp_details_modal_scroll',
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (app.backgroundImage != null)
                      AspectRatio(
                        aspectRatio: 343 / 200,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16.0.s),
                          child: Image.asset(
                            app.backgroundImage!,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    Padding(
                      padding: EdgeInsetsDirectional.only(top: 14.0.s, bottom: 18.0.s),
                      child: GridItem(
                        dAppData: app,
                        showIsFavourite: true,
                        showTips: false,
                      ),
                    ),
                    if (app.fullDescription != null)
                      Padding(
                        padding: EdgeInsetsDirectional.only(bottom: 6.0.s),
                        child: ReadMoreText(
                          app.fullDescription!,
                        ),
                      ),
                    if (app.link != null)
                      DappDetailsInfoBlock(
                        iconPath: Assets.svg.iconWalletLink,
                        value: InkWell(
                          onTap: () async {
                            if (app.link != null) {
                              await openUrl(app.link!);
                            }
                          },
                          child: Text(
                            app.link!,
                            style: context.theme.appTextThemes.caption2.copyWith(
                              color: context.theme.appColors.primaryAccent,
                            ),
                          ),
                        ),
                      ),
                    if (app.value != null)
                      DappDetailsInfoBlock(
                        title: Text(
                          context.i18n.dapp_details_tips,
                          style: context.theme.appTextThemes.caption2.copyWith(
                            color: context.theme.appColors.secondaryText,
                          ),
                        ),
                        value: Text(
                          formatDouble(app.value!),
                          style: context.theme.appTextThemes.subtitle.copyWith(
                            color: context.theme.appColors.primaryText,
                          ),
                        ),
                        iconPath: Assets.svg.iconButtonIceStroke,
                        trailing: Button.compact(
                          label: Text(
                            isVoted.value
                                ? context.i18n.dapp_details_tips_voted
                                : context.i18n.dapp_details_tips_vote,
                            style: context.theme.appTextThemes.body,
                          ),
                          minimumSize: Size(55.0.s, 28.0.s),
                          style: ButtonStyle(
                            shape: WidgetStateProperty.all<RoundedRectangleBorder>(
                              RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14.0.s),
                              ),
                            ),
                            padding: WidgetStateProperty.all<EdgeInsets>(
                              EdgeInsets.symmetric(horizontal: 10.0.s),
                            ),
                            backgroundColor: WidgetStateProperty.all<Color>(
                              isVoted.value
                                  ? context.theme.appColors.success
                                  : context.theme.appColors.primaryAccent,
                            ),
                          ),
                          onPressed: () {
                            isVoted.value = !isVoted.value;
                          },
                          leadingIcon:
                              isVoted.value ? Assets.svg.iconDappCheck.icon(size: 16.0.s) : null,
                          leadingIconOffset: 4.0.s,
                        ),
                      ),
                    Row(
                      children: [
                        Expanded(
                          child: DappDetailsInfoBlock(
                            title: Text(
                              context.i18n.dapp_details_tips_games,
                              style: context.theme.appTextThemes.caption2.copyWith(
                                color: context.theme.appColors.secondaryText,
                              ),
                            ),
                            value: Text(
                              '№1',
                              style: context.theme.appTextThemes.title.copyWith(
                                color: context.theme.appColors.primaryText,
                              ),
                            ),
                            iconPath: Assets.svg.iconDappGames,
                          ),
                        ),
                        SizedBox(
                          width: 10.0.s,
                        ),
                        Expanded(
                          child: DappDetailsInfoBlock(
                            title: Text(
                              context.i18n.dapp_details_tips_global_rank,
                              style: context.theme.appTextThemes.caption2.copyWith(
                                color: context.theme.appColors.secondaryText,
                              ),
                            ),
                            value: Text(
                              '№3',
                              style: context.theme.appTextThemes.title.copyWith(
                                color: context.theme.appColors.primaryText,
                              ),
                            ),
                            iconPath: Assets.svg.iconDappGames,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 9.0.s),
                  ],
                ),
              ),
            ),
          ),
          const HorizontalSeparator(),
          const LaunchDappButton(),
        ],
      ),
    );
  }
}
