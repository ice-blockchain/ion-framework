// SPDX-License-Identifier: ice License 1.0

import 'package:collection/collection.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_quill/quill_delta.dart';
import 'package:ion/app/features/chat/e2ee/model/entities/private_direct_message_data.f.dart';
import 'package:ion/app/features/chat/model/database/chat_database.m.dart';
import 'package:ion/app/features/ion_connect/ion_connect.dart';
import 'package:ion/app/features/ion_connect/model/ion_connect_entity.dart';
import 'package:ion/app/features/ion_connect/model/media_attachment.dart';
import 'package:ion/app/features/user/model/user_metadata.f.dart';
import 'package:ion/app/features/user/model/user_preview_data.dart';
import 'package:ion/app/features/user_block/optimistic_ui/model/blocked_user.f.dart';
import 'package:ion_token_analytics/ion_token_analytics.dart';

typedef PathWithKey = ({String key, String filePath});
typedef MediaContentWithKey = ({
  String key,
  ({Delta content, List<MediaAttachment> media}) mediaWithContent
});
// In rare cases we might want to store an entity along with custom key
// for example shared post messages: kind 30014 -> kind 16 -> kind 30175
// we want to cache kind 30175 with key of kind 16 event reference
typedef EntityWithKey = ({String key, IonConnectEntity entity});
typedef MessageStatusWithKey = ({String key, MessageDeliveryStatus status});
typedef ValueWithKey = ({String key, String value});

class ListCachedObjectsWrapper extends StatefulWidget {
  const ListCachedObjectsWrapper({required this.child, super.key});

  final Widget child;

  @override
  State<ListCachedObjectsWrapper> createState() => _ListCachedObjectsWrapperState();
}

class _ListCachedObjectsWrapperState extends State<ListCachedObjectsWrapper> {
  final List<Object> objects = <Object>[];

  @override
  Widget build(BuildContext context) {
    return ListCachedObjects(objects: objects, child: widget.child);
  }
}

class ListCachedObjects extends InheritedWidget {
  const ListCachedObjects({required super.child, required this.objects, super.key}) : super();

  final List<Object> objects;

  static const equality = DeepCollectionEquality();

  static Object identifierSelector<T extends Object>(T object) {
    return switch (object) {
      final PathWithKey fileMap => fileMap.key,
      final EntityWithKey entityMap => entityMap.key,
      final MessageStatusWithKey statusMap => statusMap.key,
      final MediaContentWithKey mediaContentMap => mediaContentMap.key,
      final ValueWithKey valueWithKey => valueWithKey.key,
      final EventMessage event => event.sharedId ?? event.id,
      final MessageMediaTableData media => media.messageEventReference,
      final UserMetadataEntity user => user.masterPubkey,
      final UserPreviewEntity userPreviewEntity => userPreviewEntity.masterPubkey,
      final IonConnectEntity entity => entity.toEventReference(),
      final BlockedUser blocked => blocked.masterPubkey,
      final CommunityToken token => token.externalAddress,
      _ => throw ArgumentError('Unknown type for identifierSelector: ${object.runtimeType}'),
    };
  }

  static T? maybeObjectOf<T extends Object>(BuildContext context, dynamic identifier) {
    final objects = context.dependOnInheritedWidgetOfExactType<ListCachedObjects>()?.objects;

    if (objects == null || identifier == null) return null;

    return objects.whereType<T>().firstWhereOrNull(
          (object) => identifierSelector<T>(object) == identifier,
        );
  }

  static List<T> maybeObjectsOf<T extends Object>(BuildContext context, [dynamic identifier]) {
    final objects = context.dependOnInheritedWidgetOfExactType<ListCachedObjects>()?.objects;
    if (objects == null) return <T>[];
    if (identifier != null) {
      return objects
          .whereType<T>()
          .where(
            (object) => identifierSelector<T>(object) == identifier,
          )
          .toList();
    }
    return objects.whereType<T>().toList();
  }

  static void updateObject<T extends Object>(BuildContext context, T object) {
    final objects = context.dependOnInheritedWidgetOfExactType<ListCachedObjects>()?.objects;

    if (objects == null) return;

    final identifier = identifierSelector<T>(object);

    for (var i = 0; i < objects.length; i++) {
      final existingObject = objects[i];
      if (existingObject is T && identifierSelector<T>(existingObject) == identifier) {
        if (!equality.equals(existingObject, object)) {
          objects[i] = object;
        }
        return;
      }
    }

    objects.add(object);
  }

  static void updateObjects<T extends Object>(
    BuildContext context,
    List<T> newObjects, {
    dynamic Function(T object)? identifierSelectorOverride,
  }) {
    final objects = context.dependOnInheritedWidgetOfExactType<ListCachedObjects>()?.objects;
    if (objects == null || newObjects.isEmpty) return;

    final identifierSelectorFn = identifierSelectorOverride ?? identifierSelector<T>;

    final newObjectsMap = <dynamic, T>{
      for (final newObject in newObjects) identifierSelectorFn(newObject): newObject,
    };

    final updatedIdentifiers = <dynamic>{};
    for (var i = 0; i < objects.length; i++) {
      final object = objects[i];
      if (object is! T) continue;

      final identifier = identifierSelectorFn(object);
      final newObject = newObjectsMap[identifier];
      if (newObject != null) {
        if (!equality.equals(object, newObject)) {
          objects[i] = newObject;
        }
        updatedIdentifiers.add(identifier);
      }
    }

    objects.addAll(
      newObjectsMap.values.where(
        (newObject) => !updatedIdentifiers.contains(identifierSelectorFn(newObject)),
      ),
    );
  }

  @override
  bool updateShouldNotify(covariant InheritedWidget oldWidget) {
    if (oldWidget is ListCachedObjects) {
      return !equality.equals(objects, oldWidget.objects);
    }

    return false;
  }
}
