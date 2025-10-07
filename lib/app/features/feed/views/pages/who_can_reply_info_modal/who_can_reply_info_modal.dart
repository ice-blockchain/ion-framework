// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/components/card/info_card.dart';
import 'package:ion/app/components/screen_offset/screen_bottom_offset.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/feed/data/models/entities/article_data.f.dart';
import 'package:ion/app/features/feed/data/models/entities/modifiable_post_data.f.dart';
import 'package:ion/app/features/feed/data/models/who_can_reply_settings_option.f.dart';
import 'package:ion/app/features/feed/providers/root_post_provider.r.dart';
import 'package:ion/app/features/ion_connect/model/event_reference.f.dart';
import 'package:ion/app/features/user/providers/user_metadata_provider.r.dart';
import 'package:ion/app/hooks/use_on_init.dart';
import 'package:ion/generated/assets.gen.dart';

class WhoCanReplyInfoModal extends HookConsumerWidget {
  const WhoCanReplyInfoModal({required this.eventReference, super.key});

  final EventReference eventReference;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final description = _getDescription(context, ref);

    useOnInit(
      () {
        if (description.isEmpty) {
          context.pop();
        }
      },
      [description],
    );

    return Column(
      children: [
        Center(
          child: Padding(
            padding: EdgeInsetsDirectional.only(start: 30.0.s, end: 30.0.s, top: 30.0.s),
            child: InfoCard(
              iconAsset: Assets.svg.actionProfileFollow,
              title: context.i18n.who_can_reply_info_modal_title,
              description: description,
            ),
          ),
        ),
        ScreenBottomOffset(),
      ],
    );
  }

  String _getDescription(BuildContext context, WidgetRef ref) {
    final entity = ref.watch(rootPostEntityProvider(eventReference: eventReference));
    if (entity == null) {
      return '';
    }

    final whoCanReplySetting = switch (entity) {
      ModifiablePostEntity() => entity.data.whoCanReplySetting,
      ArticleEntity() => entity.data.whoCanReplySetting,
      _ => null,
    };
    if (whoCanReplySetting == null) return '';

    final userMetadata = ref.watch(userMetadataProvider(eventReference.masterPubkey)).valueOrNull;
    String commonDescription() => context.i18n.who_can_reply_info_modal_description(
          userMetadata?.data.trimmedDisplayName ?? '',
          context.i18n.who_can_reply_info_modal_setting(whoCanReplySetting.tagValue),
        );

    return whoCanReplySetting.when(
      everyone: () => '',
      followedAccounts: commonDescription,
      mentionedAccounts: commonDescription,
      accountsWithBadge: (_) => context.i18n.who_can_reply_info_modal_only_verified_description,
    );
  }
}
