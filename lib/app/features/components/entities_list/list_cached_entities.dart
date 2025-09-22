// SPDX-License-Identifier: ice License 1.0

import 'package:collection/collection.dart';
import 'package:flutter/widgets.dart';
import 'package:ion/app/features/ion_connect/model/ion_connect_entity.dart';
import 'package:ion/app/features/user/model/user_metadata.f.dart';
import 'package:ion/app/features/user_block/optimistic_ui/model/blocked_user.f.dart';

class ListCachedObjects extends InheritedWidget {
  ListCachedObjects({required super.child, super.key}) : super();

  final List<Object> _objects = <Object>[];
  List<Object> get objects => _objects;

  static const equality = DeepCollectionEquality();

  static dynamic identifierSelector<T extends Object>(T object) {
    return switch (object) {
      final UserMetadataEntity user => user.masterPubkey,
      final IonConnectEntity entity => entity.toEventReference(),
      final BlockedUser blocked => blocked.masterPubkey,
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

  static List<T> maybeObjectsOf<T extends Object>(BuildContext context) {
    final objects = context.dependOnInheritedWidgetOfExactType<ListCachedObjects>()?.objects;
    if (objects == null) return <T>[];
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

  static void updateObjects<T extends Object>(BuildContext context, List<T> newObjects) {
    final objects = context.dependOnInheritedWidgetOfExactType<ListCachedObjects>()?.objects;
    if (objects == null || newObjects.isEmpty) return;

    const equality = DeepCollectionEquality();

    final newObjectsMap = <dynamic, T>{
      for (final newObject in newObjects) identifierSelector<T>(newObject): newObject,
    };

    final updatedIdentifiers = <dynamic>{};
    for (var i = 0; i < objects.length; i++) {
      final object = objects[i];
      if (object is! T) continue;

      final identifier = identifierSelector<T>(object);
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
        (newObject) => !updatedIdentifiers.contains(identifierSelector<T>(newObject)),
      ),
    );
  }

  @override
  bool updateShouldNotify(covariant InheritedWidget oldWidget) {
    if (oldWidget is ListCachedObjects) {
      const equality = DeepCollectionEquality();
      return !equality.equals(objects, oldWidget.objects);
    }

    return false;
  }
}
