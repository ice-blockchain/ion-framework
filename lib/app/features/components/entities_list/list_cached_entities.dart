import 'package:collection/collection.dart';
import 'package:flutter/widgets.dart';
import 'package:ion/app/features/ion_connect/model/event_reference.f.dart';
import 'package:ion/app/features/ion_connect/model/ion_connect_entity.dart';

class ListCachedEntities extends InheritedWidget {
  ListCachedEntities({required super.child, super.key}) : super();

  final List<IonConnectEntity> entities = [];

  static IonConnectEntity? maybeEntityOf(BuildContext context, EventReference eventReference) {
    return context
        .dependOnInheritedWidgetOfExactType<ListCachedEntities>()
        ?.entities
        .firstWhereOrNull((entity) => entity.toEventReference() == eventReference);
  }

  static void updateEntity(BuildContext context, IonConnectEntity entity) {
    final entities = context.dependOnInheritedWidgetOfExactType<ListCachedEntities>()?.entities;

    if (entities == null) return;

    final index = entities.indexWhere((e) => e.id == entity.id);
    if (index != -1) {
      if (entities[index] != entity) {
        final updatedEntities = List<IonConnectEntity>.from(entities);
        updatedEntities[index] = entity;
        entities
          ..clear()
          ..addAll(updatedEntities);
      }
    } else {
      entities.add(entity);
    }
  }

  @override
  bool updateShouldNotify(covariant InheritedWidget oldWidget) {
    return false;
  }
}
