// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/components/entities_list/components/article_list_item.dart';
import 'package:ion/app/features/components/entities_list/components/post_list_item.dart';
import 'package:ion/app/features/components/entities_list/components/repost_list_item.dart';
import 'package:ion/app/features/components/entities_list/entity_list_item.f.dart';
import 'package:ion/app/features/components/entities_list/list_cached_entities.dart';
import 'package:ion/app/features/components/entities_list/list_entity_helper.dart';
import 'package:ion/app/features/feed/data/models/entities/article_data.f.dart';
import 'package:ion/app/features/feed/data/models/entities/generic_repost.f.dart';
import 'package:ion/app/features/feed/data/models/entities/modifiable_post_data.f.dart';
import 'package:ion/app/features/feed/data/models/entities/post_data.f.dart';
import 'package:ion/app/features/feed/data/models/entities/repost_data.f.dart';
import 'package:ion/app/features/ion_connect/model/event_reference.f.dart';
import 'package:ion/app/features/ion_connect/model/ion_connect_entity.dart';
import 'package:ion/app/features/ion_connect/providers/ion_connect_entity_provider.r.dart';
import 'package:ion/app/typedefs/typedefs.dart';

class EntitiesList extends HookWidget {
  const EntitiesList({
    required this.items,
    this.displayParent = false,
    this.separatorHeight,
    this.onVideoTap,
    this.readFromDB = false,
    this.showMuted = false,
    super.key,
  });

  final List<IonEntityListItem> items;
  final double? separatorHeight;
  final bool displayParent;
  final OnVideoTapCallback? onVideoTap;
  final bool readFromDB;
  final bool showMuted;

  @override
  Widget build(BuildContext context) {
    return SliverList.builder(
      itemCount: items.length,
      itemBuilder: (BuildContext context, int index) {
        final feedListItem = items[index];
        return switch (feedListItem) {
          CustomIonEntityListItem(child: final child) =>
            _CustomListItem(separatorHeight: separatorHeight, child: child),
          EventIonEntityListItem(eventReference: final eventReference) => _EntityListItem(
              key: ValueKey(eventReference),
              eventReference: eventReference,
              displayParent: displayParent,
              separatorHeight: separatorHeight,
              onVideoTap: onVideoTap,
              readFromDB: readFromDB,
              showMuted: showMuted,
            ),
          IonEntityListItem() => const SizedBox.shrink()
        };
      },
    );
  }
}

class _EntityListItem extends HookConsumerWidget {
  _EntityListItem({
    required this.eventReference,
    required this.displayParent,
    required this.readFromDB,
    required this.showMuted,
    this.onVideoTap,
    double? separatorHeight,
    super.key,
  }) : separatorHeight = separatorHeight ?? 4.0.s;

  final EventReference eventReference;
  final double separatorHeight;
  final bool displayParent;
  final bool readFromDB;
  final OnVideoTapCallback? onVideoTap;
  final bool showMuted;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entity = ref.watch(
          ionConnectEntityProvider(eventReference: eventReference).select((value) {
            final entity = value.valueOrNull;
            if (entity != null) {
              ListCachedObjects.updateObject<IonConnectEntity>(context, entity);
            }
            return entity;
          }),
        ) ??
        ListCachedObjects.maybeObjectOf<IonConnectEntity>(context, eventReference);

    if (entity == null ||
        ListEntityHelper.isUserMuted(ref, entity.masterPubkey, showMuted: showMuted) ||
        ListEntityHelper.isUserBlockedOrBlocking(context, ref, entity) ||
        ListEntityHelper.isEntityOrRepostedEntityDeleted(context, ref, entity) ||
        !ListEntityHelper.hasMetadata(context, ref, entity)) {
      return const SizedBox.shrink();
    }

    return _BottomSeparator(
      height: separatorHeight,
      child: switch (entity) {
        ModifiablePostEntity() || PostEntity() => PostListItem(
            eventReference: entity.toEventReference(),
            displayParent: displayParent,
            onVideoTap: onVideoTap,
          ),
        final ArticleEntity article => ArticleListItem(article: article),
        GenericRepostEntity() ||
        RepostEntity() =>
          RepostListItem(eventReference: entity.toEventReference(), onVideoTap: onVideoTap),
        _ => const SizedBox.shrink()
      },
    );
  }
}

class _BottomSeparator extends StatelessWidget {
  const _BottomSeparator({required this.height, required this.child});

  final double height;

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        border: BorderDirectional(
          bottom: BorderSide(
            width: height,
            color: context.theme.appColors.primaryBackground,
          ),
        ),
      ),
      child: Padding(
        padding: EdgeInsetsDirectional.only(bottom: height),
        child: child,
      ),
    );
  }
}

class _CustomListItem extends ConsumerWidget {
  _CustomListItem({
    required this.child,
    double? separatorHeight,
  }) : separatorHeight = separatorHeight ?? 4.0.s;

  final double separatorHeight;
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return _BottomSeparator(height: separatorHeight, child: child);
  }
}
