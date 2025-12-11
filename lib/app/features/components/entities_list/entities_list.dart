// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/components/entities_list/components/article_list_item.dart';
import 'package:ion/app/features/components/entities_list/components/post_list_item.dart';
import 'package:ion/app/features/components/entities_list/components/repost_list_item.dart';
import 'package:ion/app/features/components/entities_list/entity_list_item.f.dart';
import 'package:ion/app/features/components/entities_list/list_cached_objects.dart';
import 'package:ion/app/features/components/entities_list/list_entity_helper.dart';
import 'package:ion/app/features/feed/data/models/entities/article_data.f.dart';
import 'package:ion/app/features/feed/data/models/entities/generic_repost.f.dart';
import 'package:ion/app/features/feed/data/models/entities/modifiable_post_data.f.dart';
import 'package:ion/app/features/feed/data/models/entities/post_data.f.dart';
import 'package:ion/app/features/feed/data/models/entities/repost_data.f.dart';
import 'package:ion/app/features/feed/providers/ion_connect_entity_with_counters_provider.r.dart';
import 'package:ion/app/features/ion_connect/model/event_reference.f.dart';
import 'package:ion/app/features/ion_connect/model/ion_connect_entity.dart';
import 'package:ion/app/typedefs/typedefs.dart';
import 'package:ion_ads/ion_ads.dart';

class EntitiesList extends HookWidget {
  const EntitiesList({
    required this.items,
    this.displayParent = false,
    this.separatorHeight,
    this.onVideoTap,
    this.showMuted = false,
    this.showNotInterested = true,
    this.plainInlineStyles = false,
    this.network = false,
    this.showAds = false,
    super.key,
  });

  final List<IonEntityListItem> items;
  final double? separatorHeight;
  final bool displayParent;
  final OnVideoTapCallback? onVideoTap;
  final bool showMuted;
  final bool showNotInterested;
  final bool plainInlineStyles;
  final bool network;
  final bool showAds;

  /// Loads ad after every 5th widget
  static const int showAdAfter = 6;

  @override
  Widget build(BuildContext context) {
    return ListCachedObjectsWrapper(
      child: SliverList.builder(
        itemCount: items.length,
        itemBuilder: (BuildContext context, int index) {
          if (index % showAdAfter == 0 && index != 0 && showAds) {
            return _CustomNativeAd(separatorHeight: separatorHeight);
          } else {
            final mainIndex = index - (index ~/ showAdAfter);
            final feedListItem = items[mainIndex];

            return switch (feedListItem) {
              CustomIonEntityListItem(child: final child) =>
                _CustomListItem(separatorHeight: separatorHeight, child: child),
              EventIonEntityListItem(eventReference: final eventReference) => _EntityListItem(
                  key: ValueKey(eventReference),
                  eventReference: eventReference,
                  displayParent: displayParent,
                  separatorHeight: separatorHeight,
                  onVideoTap: onVideoTap,
                  showMuted: showMuted,
                  network: network,
                  showNotInterested: showNotInterested,
                  plainInlineStyles: plainInlineStyles,
                ),
              IonEntityListItem() => const SizedBox.shrink()
            };
          }
        },
      ),
    );
  }
}

class _EntityListItem extends ConsumerWidget {
  _EntityListItem({
    required this.eventReference,
    required this.displayParent,
    required this.showMuted,
    required this.showNotInterested,
    required this.network,
    this.onVideoTap,
    this.plainInlineStyles = false,
    double? separatorHeight,
    super.key,
  }) : separatorHeight = separatorHeight ?? 4.0.s;

  final EventReference eventReference;
  final double separatorHeight;
  final bool displayParent;
  final OnVideoTapCallback? onVideoTap;
  final bool showMuted;
  final bool showNotInterested;
  final bool plainInlineStyles;
  final bool network;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entity = ref.watch(
          ionConnectEntityWithCountersProvider(eventReference: eventReference).select((value) {
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
        ListEntityHelper.isEntityOrRepostedEntityDeleted(context, ref, entity)) {
      return const SizedBox.shrink();
    }

    return _BottomSeparator(
      height: separatorHeight,
      child: switch (entity) {
        ModifiablePostEntity() || PostEntity() => PostListItem(
            showNotInterested: showNotInterested,
            eventReference: entity.toEventReference(),
            displayParent: displayParent,
            onVideoTap: onVideoTap,
            plainInlineStyles: plainInlineStyles,
            network: network,
          ),
        final ArticleEntity article => ArticleListItem(
            article: article,
            showNotInterested: showNotInterested,
            network: network,
          ),
        GenericRepostEntity() || RepostEntity() => RepostListItem(
            eventReference: entity.toEventReference(),
            onVideoTap: onVideoTap,
            showNotInterested: showNotInterested,
            plainInlineStyles: plainInlineStyles,
          ),
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

class _CustomNativeAd extends StatelessWidget {
  const _CustomNativeAd({double? separatorHeight}) : separatorHeight = separatorHeight ?? 4.0;

  final double separatorHeight;

  @override
  Widget build(BuildContext context) {
    return _BottomSeparator(
      height: separatorHeight,
      child: Container(
        height: 270,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: AppodealNativeAd(
          options: NativeAdOptions.contentStreamOptions(
            adChoicePosition: AdChoicePosition.endTop,
            adAttributionBackgroundColor: Colors.white,
            adAttributionTextColor: Colors.black,
            adActionButtonTextSize: 13,
            adDescriptionFontSize: 12,
            adTitleFontSize: 13,
          ),
        ),
      ),
    );
  }
}
