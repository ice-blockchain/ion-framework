// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/components/list_item/list_item.dart';
import 'package:ion/app/components/screen_offset/screen_bottom_offset.dart';
import 'package:ion/app/components/screen_offset/screen_side_offset.dart';
import 'package:ion/app/components/separated/separated_column.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/settings/model/available_relays.dart';
import 'package:ion/app/features/settings/providers/selected_relay_provider.r.dart';
import 'package:ion/app/router/components/navigation_app_bar/navigation_app_bar.dart';
import 'package:ion/app/router/components/navigation_app_bar/navigation_close_button.dart';
import 'package:ion/app/router/components/sheet_content/sheet_content.dart';
import 'package:ion/generated/assets.gen.dart';

class RelaySelectionModal extends HookConsumerWidget {
  const RelaySelectionModal({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedRelay = ref.watch(selectedRelayProvider);
    final relayUrlController = useTextEditingController();
    final showCustomInput = useState(false);

    final primaryColor = context.theme.appColors.primaryAccent;
    final colors = context.theme.appColors;
    final textStyles = context.theme.appTextThemes;

    return SheetContent(
      body: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          NavigationAppBar.modal(
            onBackPress: () => context.pop(true),
            title: const Text('Relay Selection'),
            actions: const [NavigationCloseButton()],
          ),
          Expanded(
            child: SingleChildScrollView(
              child: ScreenSideOffset.small(
                child: SeparatedColumn(
                  separator: SizedBox(height: 9.0.s),
                  mainAxisSize: MainAxisSize.min,
                  children: [
                  // Default option (use standard ion relay)
                  ListItem(
                    onTap: () {
                      ref.read(selectedRelayProvider.notifier).clearSelectedRelay();
                      context.pop(true);
                    },
                    title: Text(
                      'Use Default Relay',
                      style: textStyles.body,
                    ),
                    backgroundColor: colors.secondaryBackground,
                    leading: Container(
                      width: 36.0.s,
                      height: 36.0.s,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: colors.tertiaryBackground,
                        borderRadius: BorderRadius.all(Radius.circular(10.0.s)),
                        border: Border.all(
                          width: 1.0.s,
                          color: colors.onTertiaryFill,
                        ),
                      ),
                      child: Assets.svg.iconSettingsAutoplay.icon(
                        size: 24.0.s,
                        color: primaryColor,
                      ),
                    ),
                    trailing: selectedRelay == null
                        ? Assets.svg.iconBlockCheckboxOnblue.icon(
                            color: colors.success,
                          )
                        : Assets.svg.iconBlockCheckboxOff.icon(
                            color: colors.tertiaryText,
                          ),
                  ),
                  // Popular public relays
                  ...AvailableRelays.popularRelays.map((relayUrl) {
                    final isSelected = selectedRelay == relayUrl;
                    return ListItem(
                      onTap: () {
                        ref.read(selectedRelayProvider.notifier).setSelectedRelay(relayUrl);
                        context.pop(true);
                      },
                      title: Text(
                        relayUrl.replaceFirst('wss://', ''),
                        style: textStyles.body,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      backgroundColor: colors.secondaryBackground,
                      leading: Container(
                        width: 36.0.s,
                        height: 36.0.s,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: colors.tertiaryBackground,
                          borderRadius: BorderRadius.all(Radius.circular(10.0.s)),
                          border: Border.all(
                            width: 1.0.s,
                            color: colors.onTertiaryFill,
                          ),
                        ),
                        child: Assets.svg.iconSettingsAutoplay.icon(
                          size: 24.0.s,
                          color: primaryColor,
                        ),
                      ),
                      trailing: isSelected
                          ? Assets.svg.iconBlockCheckboxOnblue.icon(
                              color: colors.success,
                            )
                          : Assets.svg.iconBlockCheckboxOff.icon(
                              color: colors.tertiaryText,
                            ),
                    );
                  }).toList(),
                  // Custom relay input
                  ListItem(
                    onTap: () {
                      showCustomInput.value = !showCustomInput.value;
                    },
                    title: Text(
                      'Custom Relay',
                      style: textStyles.body,
                    ),
                    backgroundColor: colors.secondaryBackground,
                    leading: Container(
                      width: 36.0.s,
                      height: 36.0.s,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: colors.tertiaryBackground,
                        borderRadius: BorderRadius.all(Radius.circular(10.0.s)),
                        border: Border.all(
                          width: 1.0.s,
                          color: colors.onTertiaryFill,
                        ),
                      ),
                      child: Assets.svg.iconSettingsAutoplay.icon(
                        size: 24.0.s,
                        color: primaryColor,
                      ),
                    ),
                    trailing: showCustomInput.value
                        ? Assets.svg.iconBlockCheckboxOnblue.icon(
                            color: colors.success,
                          )
                        : Assets.svg.iconBlockCheckboxOff.icon(
                            color: colors.tertiaryText,
                          ),
                  ),
                  if (showCustomInput.value)
                    Padding(
                      padding: EdgeInsets.only(top: 8.0.s),
                      child: Column(
                        children: [
                          TextField(
                            controller: relayUrlController,
                            decoration: InputDecoration(
                              hintText: 'Enter relay URL (e.g., wss://relay.example.com)',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8.0.s),
                              ),
                            ),
                            style: textStyles.body,
                          ),
                          SizedBox(height: 12.0.s),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: () {
                                final url = relayUrlController.text.trim();
                                if (url.isNotEmpty) {
                                  ref.read(selectedRelayProvider.notifier).setSelectedRelay(url);
                                  context.pop(true);
                                }
                              },
                              child: const Text('Save'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          ScreenBottomOffset(margin: 12.0.s),
        ],
      ),
    );
  }
}

