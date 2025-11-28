// SPDX-License-Identifier: ice License 1.0

import 'package:collection/collection.dart';
import 'package:ion/app/features/ion_connect/model/related_event.f.dart';
import 'package:ion/app/features/ion_connect/model/related_event_marker.dart';
import 'package:ion/app/services/logger/logger.dart';

mixin EntityDataWithRelatedEvents<T extends RelatedEvent> {
  List<T>? get relatedEvents;

  T? get parentEvent {
    if (relatedEvents == null) return null;

    T? rootParent;
    T? replyParent;
    for (final relatedEvent in relatedEvents!) {
      if (relatedEvent.marker == RelatedEventMarker.reply) {
        replyParent = relatedEvent;
        break;
      } else if (relatedEvent.marker == RelatedEventMarker.root) {
        rootParent = relatedEvent;
      }
    }
    return replyParent ?? rootParent;

    //TODO: Remove code above and uncomment bottom line after release.
    // We need to support looking for a `root` reference modifiers for backward compatibility with already created posts.
    // return relatedEvents?.firstWhereOrNull((event) => event.marker == RelatedEventMarker.reply);
  }

  bool get isReply {
    return relatedEvents?.firstWhereOrNull((event) => event.marker == RelatedEventMarker.reply) !=
        null;
  }

  T? get rootRelatedEvent {
    return relatedEvents?.firstWhereOrNull((tag) => tag.marker == RelatedEventMarker.root);
  }

  static List<RelatedEvent>? fromTags(Map<String, List<List<String>>> tags) {
    final relatedEvents = <RelatedEvent>[
      ...(tags[RelatedImmutableEvent.tagName]?.map(RelatedImmutableEvent.fromTag) ?? []),
    ];

    // Filter out "a" tags with "mention" marker
    final aTags = tags[RelatedReplaceableEvent.tagName];
    if (aTags != null) {
      for (final tag in aTags) {
        // Skip if it's a source post reference tag
        if (tag.length >= 4 && tag[3] == 'mention') {
          continue;
        }

        try {
          relatedEvents.add(RelatedReplaceableEvent.fromTag(tag));
        } catch (_) {
          Logger.warning('Failed to parse tag as RelatedReplaceableEvent: $tag');
        }
      }
    }

    return relatedEvents.isEmpty ? null : relatedEvents;
  }
}
