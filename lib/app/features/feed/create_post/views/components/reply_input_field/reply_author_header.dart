// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/components/list_item/badges_user_list_item.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/feed/views/components/replying_to/replying_to.dart';
import 'package:ion/app/features/user/providers/user_metadata_provider.r.dart';
import 'package:ion/app/utils/username.dart';

class ReplyAuthorHeader extends ConsumerWidget {
  const ReplyAuthorHeader({
    required this.pubkey,
    super.key,
  });

  final String pubkey;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUserMetadata = ref.watch(currentUserMetadataProvider).valueOrNull;
    final name = ref.watch(userPreviewDataProvider(pubkey).select(userPreviewNameSelector));

    if (currentUserMetadata == null) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        BadgesUserListItem(
          title: Text(currentUserMetadata.data.trimmedDisplayName),
          subtitle: Text(prefixUsername(input: currentUserMetadata.data.name,       textDirection: Directionality.of(context),)),
          masterPubkey: currentUserMetadata.masterPubkey,
        ),
        SizedBox(height: 6.0.s),
        ReplyingTo(name: name),
      ],
    );
  }
}
