// SPDX-License-Identifier: ice License 1.0

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/features/auth/providers/auth_provider.m.dart';
import 'package:ion/app/features/feed/data/models/entities/article_data.f.dart';
import 'package:ion/app/features/feed/data/models/entities/modifiable_post_data.f.dart';
import 'package:ion/app/features/feed/data/models/who_can_reply_settings_option.f.dart';
import 'package:ion/app/features/feed/providers/post_mentions_provider.r.dart';
import 'package:ion/app/features/feed/providers/root_post_provider.r.dart';
import 'package:ion/app/features/ion_connect/model/event_reference.f.dart';
import 'package:ion/app/features/user/model/badges/badge_definition.f.dart';
import 'package:ion/app/features/user/providers/badges_notifier.r.dart';
import 'package:ion/app/features/user/providers/follow_list_provider.r.dart';
import 'package:ion/app/features/user/providers/service_pubkeys_provider.r.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'can_reply_notifier.r.g.dart';

const _maxCacheAge = Duration(minutes: 1);

@riverpod
class CanReply extends _$CanReply {
  DateTime _lastFetchDate = DateTime.now();
  bool _skipCache = false;

  @override
  Future<bool> build(EventReference eventReference) async {
    final currentPubkey = ref.watch(currentPubkeySelectorProvider);
    if (currentPubkey == null) {
      return true;
    }

    final entity = ref.watch(
      rootPostEntityProvider(eventReference: eventReference, cache: !_skipCache),
    );
    if (entity == null) {
      return false;
    }

    if ((entity is ModifiablePostEntity && entity.isDeleted) ||
        (entity is ArticleEntity && entity.isDeleted)) {
      return false;
    }

    final authorPubkey = entity.masterPubkey;
    if (authorPubkey == currentPubkey) {
      return true;
    }

    final whoCanReplySetting = switch (entity) {
      ModifiablePostEntity() => entity.data.whoCanReplySetting,
      ArticleEntity() => entity.data.whoCanReplySetting,
      _ => null,
    };
    final effectiveSetting = whoCanReplySetting ?? const WhoCanReplySettingsOption.everyone();

    return await effectiveSetting.when(
      everyone: () async => true,
      followedAccounts: () async {
        final followers = await ref.watch(
          followListProvider(authorPubkey, cache: !_skipCache).future,
        );
        if (followers == null) {
          return false;
        }
        return followers.data.list.any((followee) => followee.pubkey == currentPubkey);
      },
      accountsWithBadge: (badgeRef) async {
        final pubkeys = await ref.watch(servicePubkeysProvider.future);
        final isBadgeDefinitionValid =
            ref.watch(isValidVerifiedBadgeDefinitionProvider(badgeRef, pubkeys));
        if (!isBadgeDefinitionValid) {
          return false;
        }
        return ref.watch(isUserVerifiedProvider(currentPubkey));
      },
      mentionedAccounts: () async {
        final mentions = ref.read(postMentionsPubkeysProvider(entity: entity));
        if (mentions.isEmpty) {
          return false;
        }
        return mentions.any((pubKey) => pubKey == currentPubkey);
      },
    );
  }

  void refreshIfNeeded(EventReference eventReference) {
    final now = DateTime.now();
    if (now.difference(_lastFetchDate) > _maxCacheAge) {
      _lastFetchDate = now;
      _skipCache = true;
      ref.invalidateSelf();
    }
  }
}

@riverpod
Future<List<WhoCanReplySettingsOption>> whoCanReplySettingsOptions(Ref ref) async {
  final pubkeys = await ref.watch(servicePubkeysProvider.future);
  final badgeDefinitionEntity = await ref.watch(
    badgeDefinitionEntityProvider(BadgeDefinitionEntity.verifiedBadgeDTag, pubkeys).future,
  );
  return [
    const WhoCanReplySettingsOption.everyone(),
    const WhoCanReplySettingsOption.followedAccounts(),
    if (badgeDefinitionEntity != null)
      WhoCanReplySettingsOption.accountsWithBadge(badge: badgeDefinitionEntity.toEventReference()),
    const WhoCanReplySettingsOption.mentionedAccounts(),
  ];
}
