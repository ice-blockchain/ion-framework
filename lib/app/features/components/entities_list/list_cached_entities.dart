// SPDX-License-Identifier: ice License 1.0

import 'package:collection/collection.dart';
import 'package:flutter/widgets.dart';
import 'package:ion/app/features/ion_connect/model/ion_connect_entity.dart';
import 'package:ion/app/features/user_block/optimistic_ui/model/blocked_user.f.dart';

class ListCachedObjects extends InheritedWidget {
  ListCachedObjects({required super.child, super.key}) : super();

  final objects = <Object>[];

  static I identifierSelector<T extends Object, I>(T object) {
    if (object is IonConnectEntity) {
      return object.toEventReference() as I;
    } else if (object is BlockedUser) {
      return object.masterPubkey as I;
    } else {
      throw ArgumentError('Unknown type for identifierSelector');
    }
  }

  static T? maybeObjectOf<T extends Object, I>(BuildContext context, I identifier) {
    final entity = context
        .dependOnInheritedWidgetOfExactType<ListCachedObjects>()
        ?.objects
        .whereType<T>()
        .firstWhereOrNull((object) => identifierSelector<T, I>(object) == identifier);

    return entity;
  }

  static List<T> maybeObjectsOf<T>(BuildContext context) {
    final objects = context.dependOnInheritedWidgetOfExactType<ListCachedObjects>()?.objects;
    if (objects == null) return [];
    return objects.whereType<T>().toList();
  }

  static void updateObject<T extends Object, I>(BuildContext context, T object) {
    final objects = context.dependOnInheritedWidgetOfExactType<ListCachedObjects>()?.objects;

    if (objects == null) return;

    final index = objects
        .whereType<T>()
        .toList()
        .indexWhere((o) => identifierSelector<T, I>(o) == identifierSelector<T, I>(object));

    if (index != -1) {
      final typedObjects = objects.whereType<T>().toList();
      if (typedObjects[index] != object) {
        final updatedObjects = List<T>.from(typedObjects);
        updatedObjects[index] = object;
        objects
          ..removeWhere((o) => o is T)
          ..addAll(updatedObjects);
      }
    } else {
      objects.add(object);
    }
  }

  static void updateObjects<T extends Object, I>(BuildContext context, List<T> newObjects) {
    final objects = context.dependOnInheritedWidgetOfExactType<ListCachedObjects>()?.objects;
    if (objects == null) return;

    final newIdentifiers = newObjects.map(identifierSelector<T, I>).toSet();
    objects
      ..removeWhere((o) => o is T && newIdentifiers.contains(identifierSelector(o)))
      ..addAll(newObjects);
  }

  @override
  bool updateShouldNotify(covariant InheritedWidget oldWidget) {
    return false;
  }
}
