// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/components/modal_action_button/modal_action_button.dart';
import 'package:ion/app/components/screen_offset/screen_bottom_offset.dart';
import 'package:ion/app/components/screen_offset/screen_side_offset.dart';
import 'package:ion/app/components/separated/separated_column.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/feed/providers/counters/reposted_events_provider.r.dart';
import 'package:ion/app/features/feed/providers/repost_notifier.r.dart';
import 'package:ion/app/features/feed/reposts/providers/optimistic/post_repost_provider.r.dart';
import 'package:ion/app/features/feed/views/pages/repost_options_modal/repost_option_action.dart';
import 'package:ion/app/features/ion_connect/model/event_reference.f.dart';
import 'package:ion/app/router/components/navigation_app_bar/navigation_app_bar.dart';
import 'package:ion/app/router/components/navigation_app_bar/navigation_close_button.dart';
import 'package:ion/app/router/components/sheet_content/sheet_content.dart';
import 'package:ion/app/router/utils/quote_routing_utils.dart';

class RepostOptionsModal extends HookConsumerWidget {
  const RepostOptionsModal({
    required this.eventReference,
    super.key,
  });

  final EventReference eventReference;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.displayErrors(repostNotifierProvider);

    final isReposted = ref.watch(isRepostedProvider(eventReference));

    final actions = [
      if (isReposted) RepostOptionAction.undoRepost else RepostOptionAction.repost,
      RepostOptionAction.quotePost,
    ];

    return SheetContent(
      body: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            NavigationAppBar.modal(
              showBackButton: false,
              title: Text(context.i18n.feed_repost_type),
              actions: const [NavigationCloseButton()],
            ),
            SizedBox(height: 6.0.s),
            ScreenSideOffset.small(
              child: SeparatedColumn(
                separator: SizedBox(height: 9.0.s),
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (final option in actions)
                    ModalActionButton(
                      icon: option.getIcon(context),
                      label: option.getLabel(context),
                      labelStyle: context.theme.appTextThemes.subtitle2,
                      onTap: () async {
                        switch (option) {
                          case RepostOptionAction.repost:
                            await ref
                                .read(toggleRepostNotifierProvider.notifier)
                                .toggle(eventReference);
                            if (context.mounted) {
                              context.maybePop();
                            }

                          case RepostOptionAction.quotePost:
                            await QuoteRoutingUtils.pushCreateQuote(
                              context,
                              eventReference.encode(),
                            );
                            if (context.mounted) {
                              WidgetsBinding.instance.addPostFrameCallback((_) {
                                if (context.mounted) {
                                  context.maybePop();
                                }
                              });
                            }

                          case RepostOptionAction.undoRepost:
                            await ref
                                .read(toggleRepostNotifierProvider.notifier)
                                .toggle(eventReference);
                            if (context.mounted) {
                              context.maybePop();
                            }
                        }
                      },
                    ),
                ],
              ),
            ),
            SizedBox(height: 20.0.s),
            ScreenBottomOffset(),
          ],
        ),
      ),
    );
  }
}
