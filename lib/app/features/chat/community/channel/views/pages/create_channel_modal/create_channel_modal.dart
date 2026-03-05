// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/chat/community/channel/views/components/channel_form.dart';
import 'package:ion/app/features/chat/community/channel/views/pages/create_channel_modal/components/channel_photo.dart';
import 'package:ion/app/features/chat/community/providers/create_community_provider.r.dart';
import 'package:ion/app/features/ion_connect/model/event_setting.f.dart';
import 'package:ion/app/router/app_routes.gr.dart';
import 'package:ion/app/router/components/navigation_app_bar/navigation_app_bar.dart';
import 'package:ion/app/router/components/navigation_app_bar/navigation_close_button.dart';
import 'package:ion/app/router/components/sheet_content/sheet_content.dart';

class CreateChannelModal extends ConsumerWidget {
  const CreateChannelModal({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref
      ..listenSuccess(createCommunityNotifierProvider, (data) {
        if (data != null) {
          ConversationRoute(conversationId: data.id).pushReplacement(context);
        }
      })
      ..displayErrors(createCommunityNotifierProvider);

    final createCommunityNotifier = ref.watch(createCommunityNotifierProvider);

    return SheetContent(
      topPadding: 0,
      body: Column(
        children: [
          NavigationAppBar.modal(
            showBackButton: false,
            title: Text(context.i18n.channel_create_title),
            actions: const [NavigationCloseButton()],
          ),
          Flexible(
            child: SingleChildScrollView(
              restorationId: 'create_channel_scroll',
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: 30.0.s),
                    child: const ChannelPhoto(),
                  ),
                  Flexible(
                    child: ChannelForm(
                      isLoading: createCommunityNotifier.isLoading,
                      onSubmit: (name, description, channelType) {
                        ref.read(createCommunityNotifierProvider.notifier).createCommunity(
                              name,
                              description,
                              channelType,
                              RoleRequiredForPosting.moderator,
                            );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
