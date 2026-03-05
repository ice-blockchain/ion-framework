// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/components/screen_offset/screen_side_offset.dart';
import 'package:ion/app/components/screen_offset/screen_top_offset.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/chat/community/channel/views/components/channel_detail_app_bar.dart';
import 'package:ion/app/features/chat/community/channel/views/components/channel_form.dart';
import 'package:ion/app/features/chat/community/channel/views/pages/channel_detail_page/components/channel_summary.dart';
import 'package:ion/app/features/chat/community/providers/community_admins_provider.r.dart';
import 'package:ion/app/features/chat/community/providers/community_metadata_provider.r.dart';
import 'package:ion/app/features/chat/community/providers/update_community_provider.r.dart';
import 'package:ion/app/hooks/use_on_init.dart';

class EditChannelPage extends HookConsumerWidget {
  const EditChannelPage({
    required this.uuid,
    super.key,
  });

  final String uuid;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final channel = ref.watch(communityMetadataProvider(uuid)).valueOrNull;

    useOnInit(
      () {
        if (channel == null) return;
        ref.read(communityAdminsProvider.notifier).init(channel);
      },
      [channel],
    );

    if (channel == null) {
      return const SizedBox.shrink();
    }

    final updateCommunityProvider = updateCommunityNotifierProvider(channel.data);
    final updateCommunityNotifier = ref.watch(updateCommunityProvider);

    ref
      ..listenSuccess(updateCommunityProvider, (data) {
        context.pop();
      })
      ..displayErrors(updateCommunityProvider);

    return Scaffold(
      body: ScreenTopOffset(
        child: Stack(
          alignment: Alignment.topCenter,
          children: [
            SingleChildScrollView(
              restorationId: 'edit_channel_scroll',
              child: Column(
                children: <Widget>[
                  ScreenSideOffset.large(
                    child: Column(
                      children: <Widget>[
                        ChannelSummary(
                          channel: channel,
                          basicMode: true,
                        ),
                      ],
                    ),
                  ),
                  ChannelForm(
                    channel: channel,
                    isLoading: updateCommunityNotifier.isLoading,
                    onSubmit: (name, description, channelType) {
                      ref.read(updateCommunityProvider.notifier).updateCommunity(
                            name,
                            description,
                            channelType,
                          );
                    },
                  ),
                ],
              ),
            ),
            ChannelDetailAppBar(channel: channel.data),
          ],
        ),
      ),
    );
  }
}
