// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/components/separated/separator.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/chat/views/pages/share_via_message_modal/components/share_options.dart';
import 'package:ion/app/features/chat/views/pages/share_via_message_modal/components/share_send_button.dart';
import 'package:ion/app/features/core/providers/env_provider.r.dart';
import 'package:ion/app/features/ion_connect/model/event_reference.f.dart';
import 'package:ion/app/features/user/pages/user_picker_sheet/user_picker_sheet.dart';
import 'package:ion/app/hooks/use_selected_state.dart';
import 'package:ion/app/router/components/navigation_app_bar/navigation_app_bar.dart';
import 'package:ion/app/router/components/navigation_app_bar/navigation_close_button.dart';
import 'package:ion/app/router/components/sheet_content/sheet_content.dart';
import 'package:ion_connect_cache/ion_connect_cache.dart';

class ShareViaMessageModal extends HookConsumerWidget {
  const ShareViaMessageModal({
    required this.eventReference,
    super.key,
  });

  final EventReference eventReference;

  @override
  Widget build(
    BuildContext context,
    WidgetRef ref,
  ) {
    final (selectedPubkeys, togglePubkeySelection) = useSelectedState<String>();

    final env = ref.read(envProvider.notifier);
    final expirationDuration = Duration(
      minutes: env.get<int>(EnvVariable.CHAT_PRIVACY_CACHE_MINUTES),
    );

    return SheetContent(
      body: Column(
        children: [
          Flexible(
            child: UserPickerSheet(
              selectable: true,
              controlPrivacy: true,
              selectedPubkeys: selectedPubkeys,
              expirationDuration: expirationDuration,
              cacheStrategy: DatabaseCacheStrategy.returnIfNotExpired,
              navigationBar: NavigationAppBar.modal(
                title: Text(context.i18n.feed_share_via),
                actions: const [NavigationCloseButton()],
                showBackButton: false,
              ),
              onUserSelected: togglePubkeySelection,
            ),
          ),
          const HorizontalSeparator(),
          SizedBox(
            height: 110.0.s,
            child: selectedPubkeys.isEmpty
                ? ShareOptions(eventReference: eventReference)
                : ShareSendButton(
                    masterPubkeys: selectedPubkeys,
                    eventReference: eventReference,
                  ),
          ),
        ],
      ),
    );
  }
}
